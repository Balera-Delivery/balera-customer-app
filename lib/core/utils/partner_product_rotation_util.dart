import '../../models/food_item_model.dart';
import '../../models/restaurant_model.dart';

/// Fair Partner Product Rotation Utility
///
/// Ensures all active food partners receive fair, balanced visibility
/// in the unified product catalog:
/// 1. Distributes products from different partners evenly throughout the feed.
/// 2. Avoids displaying consecutive products from the same partner when other partners have items available.
/// 3. Periodically rotates starting partner deterministically (e.g., daily cycle).
/// 4. Ensures partners with fewer dishes still receive early visibility in the initial rows.
/// 5. Excludes inactive partners and unavailable products.
/// 6. Prevents duplicate products.
/// 7. Preserves search, category filtering, and stable ordering across pagination/scrolling.
class PartnerProductRotationUtil {
  /// Rotates a list of foods using a deterministic, fair partner round-robin algorithm.
  ///
  /// [foods]: Candidate list of food items (already filtered by search/category if desired,
  /// or raw catalog).
  /// [restaurants]: List of partner restaurants to determine active partner status and attributes.
  /// [dateOverride]: Optional reference date for deterministic daily rotation (defaults to now).
  static List<FoodItemModel> rotateProducts({
    required List<FoodItemModel> foods,
    required List<RestaurantModel> restaurants,
    DateTime? dateOverride,
  }) {
    if (foods.isEmpty) return const [];

    // 1. Build lookup for active partner restaurants
    // If restaurants list is empty, treat all partners with items as active.
    final Map<String, RestaurantModel> activePartnerMap = {};
    for (final r in restaurants) {
      final isStatusActive = r.status.trim().isEmpty ||
          r.status.trim().toLowerCase() == 'active' ||
          r.status.trim().toLowerCase() == 'open';
      if (isStatusActive && r.isPartner) {
        activePartnerMap[r.id] = r;
        if (r.code != null && r.code!.trim().isNotEmpty) {
          activePartnerMap[r.code!] = r;
        }
      }
    }

    // 2. Filter available products, exclude inactive partners, deduplicate by ID
    final Set<String> seenFoodIds = <String>{};
    final Map<String, List<FoodItemModel>> partnerQueues = {};

    for (final f in foods) {
      // Must be available
      if (!f.isAvailable) continue;

      // Deduplicate by food ID
      if (seenFoodIds.contains(f.id)) continue;
      seenFoodIds.add(f.id);

      // Verify partner restaurant is active (if restaurants metadata is available)
      if (activePartnerMap.isNotEmpty) {
        final r = activePartnerMap[f.restaurantId];
        if (r == null) {
          // If not directly found by id/code, check if name matches any active partner
          final matchByName = activePartnerMap.values.any((item) =>
              item.name.trim().toLowerCase() == (f.restaurantName ?? '').trim().toLowerCase());
          if (!matchByName) {
            continue; // Inactive or non-partner restaurant
          }
        }
      }

      partnerQueues.putIfAbsent(f.restaurantId, () => []).add(f);
    }

    if (partnerQueues.isEmpty) return const [];

    // 3. Deterministic Partner Ordering & Daily Rotation
    // Sort partner IDs alphabetically for initial deterministic ordering
    final List<String> sortedPartnerIds = partnerQueues.keys.toList()..sort();

    // Calculate daily rotation offset (days since Unix epoch)
    final now = dateOverride ?? DateTime.now();
    // Use UTC date to avoid timezone shift inconsistencies
    final epoch = DateTime.utc(1970, 1, 1);
    final daysSinceEpoch = now.toUtc().difference(epoch).inDays;

    final rotationOffset = daysSinceEpoch % sortedPartnerIds.length;
    final List<String> rotatedPartnerIds = [
      ...sortedPartnerIds.sublist(rotationOffset),
      ...sortedPartnerIds.sublist(0, rotationOffset),
    ];

    // 4. Stable sort foods within each partner queue to maintain deterministic order
    for (final pid in rotatedPartnerIds) {
      partnerQueues[pid]!.sort((a, b) {
        // Tag priority (Popular / House Special first)
        final aTag = a.tag?.trim().isNotEmpty == true ? 1 : 0;
        final bTag = b.tag?.trim().isNotEmpty == true ? 1 : 0;
        if (aTag != bTag) return bTag.compareTo(aTag);

        // Then by ID or Name
        final idComp = a.id.compareTo(b.id);
        if (idComp != 0) return idComp;
        return a.name.compareTo(b.name);
      });
    }

    // 5. Fair Round-Robin Interleaving
    // Ensures:
    // - Every partner with products gets 1 product in round 1, round 2, etc.
    // - Prevents consecutive products from the same partner whenever other partners have products available.
    // - Partners with fewer dishes get visibility in row 1 alongside larger partners.
    final List<FoodItemModel> rotatedResult = [];
    final Map<String, int> queueIndices = {for (final pid in rotatedPartnerIds) pid: 0};
    List<String> activeQueues = rotatedPartnerIds
        .where((pid) => (partnerQueues[pid]?.isNotEmpty ?? false))
        .toList();

    while (activeQueues.isNotEmpty) {
      final List<String> nextActiveQueues = [];

      for (final pid in activeQueues) {
        final queue = partnerQueues[pid]!;
        final idx = queueIndices[pid]!;

        if (idx < queue.length) {
          rotatedResult.add(queue[idx]);
          queueIndices[pid] = idx + 1;
        }

        if (queueIndices[pid]! < queue.length) {
          nextActiveQueues.add(pid);
        }
      }

      // If only 1 partner remains, consecutive items are unavoidable, but for the entire
      // prior rounds every partner is perfectly interleaved.
      activeQueues = nextActiveQueues;
    }

    return rotatedResult;
  }
}
