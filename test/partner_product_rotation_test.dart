import 'package:flutter_test/flutter_test.dart';
import 'package:balera_customer_app/core/utils/partner_product_rotation_util.dart';
import 'package:balera_customer_app/models/food_item_model.dart';
import 'package:balera_customer_app/models/restaurant_model.dart';
import 'package:balera_customer_app/data/fallback_hotel_data.dart';

void main() {
  group('Fair Partner Product Rotation Algorithm Tests', () {
    final restaurants = [
      const RestaurantModel(
        id: 'HTL-001',
        name: 'Green Cafe',
        address: 'Bale Robe',
        status: 'Active',
        isPartner: true,
      ),
      const RestaurantModel(
        id: 'HTL-002',
        name: 'Filebebar Restaurant',
        address: 'Bale Robe',
        status: 'Active',
        isPartner: true,
      ),
      const RestaurantModel(
        id: 'HTL-003',
        name: 'Dimaa Restaurant',
        address: 'Bale Robe',
        status: 'Active',
        isPartner: true,
      ),
      const RestaurantModel(
        id: 'HTL-004',
        name: 'Inactive Partner',
        address: 'Bale Robe',
        status: 'Inactive',
        isPartner: true,
      ),
    ];

    final sampleFoods = [
      // 3 items from HTL-001
      const FoodItemModel(id: 'F-001', restaurantId: 'HTL-001', name: 'G-Dish 1', price: 100),
      const FoodItemModel(id: 'F-002', restaurantId: 'HTL-001', name: 'G-Dish 2', price: 120),
      const FoodItemModel(id: 'F-003', restaurantId: 'HTL-001', name: 'G-Dish 3', price: 150),

      // 2 items from HTL-002
      const FoodItemModel(id: 'F-004', restaurantId: 'HTL-002', name: 'F-Dish 1', price: 200),
      const FoodItemModel(id: 'F-005', restaurantId: 'HTL-002', name: 'F-Dish 2', price: 220),

      // 1 item from HTL-003 (partner with fewer products)
      const FoodItemModel(id: 'F-006', restaurantId: 'HTL-003', name: 'D-Dish 1', price: 300),

      // Item from inactive partner HTL-004
      const FoodItemModel(id: 'F-007', restaurantId: 'HTL-004', name: 'Inactive Dish', price: 50),

      // Unavailable item
      const FoodItemModel(id: 'F-008', restaurantId: 'HTL-001', name: 'Sold Out', price: 50, isAvailable: false),

      // Duplicate item ID
      const FoodItemModel(id: 'F-001', restaurantId: 'HTL-001', name: 'Duplicate G-Dish 1', price: 100),
    ];

    test('1. Excludes inactive partners and unavailable/duplicate products', () {
      final rotated = PartnerProductRotationUtil.rotateProducts(
        foods: sampleFoods,
        restaurants: restaurants,
      );

      final ids = rotated.map((f) => f.id).toList();
      // Should exclude F-007 (inactive partner)
      expect(ids.contains('F-007'), isFalse);
      // Should exclude F-008 (isAvailable: false)
      expect(ids.contains('F-008'), isFalse);
      // Should have exactly 6 valid unique dishes
      expect(rotated.length, 6);
      expect(ids.toSet().length, 6);
    });

    test('2. Avoids consecutive products from the same partner when other partners have products', () {
      final rotated = PartnerProductRotationUtil.rotateProducts(
        foods: sampleFoods,
        restaurants: restaurants,
      );

      // Verify no consecutive identical partners while multiple partners are in the round
      for (int i = 0; i < rotated.length - 1; i++) {
        final currentPartner = rotated[i].restaurantId;
        final nextPartner = rotated[i + 1].restaurantId;

        // If they are from the same partner, verify no OTHER partners had unexhausted items
        if (currentPartner == nextPartner) {
          // This should only happen at the very tail of the feed when only 1 partner has remaining items
          final remaining = rotated.sublist(i);
          final partnerIds = remaining.map((f) => f.restaurantId).toSet();
          expect(partnerIds.length, 1, reason: 'Consecutive items must only appear if no other partner has items');
        }
      }
    });

    test('3. Prioritizes partner diversity in the first visible rows (first round)', () {
      final rotated = PartnerProductRotationUtil.rotateProducts(
        foods: sampleFoods,
        restaurants: restaurants,
      );

      // First 3 items should come from 3 distinct partners (HTL-001, HTL-002, HTL-003)
      final firstRowPartnerIds = rotated.take(3).map((f) => f.restaurantId).toSet();
      expect(firstRowPartnerIds.length, 3);
      expect(firstRowPartnerIds, containsAll(['HTL-001', 'HTL-002', 'HTL-003']));
    });

    test('4. Deterministic daily rotation alters starting partner across days', () {
      final monday = DateTime.utc(2026, 11, 2);
      final tuesday = DateTime.utc(2026, 11, 3);
      final wednesday = DateTime.utc(2026, 11, 4);

      final rotMonday = PartnerProductRotationUtil.rotateProducts(
        foods: sampleFoods,
        restaurants: restaurants,
        dateOverride: monday,
      );

      final rotTuesday = PartnerProductRotationUtil.rotateProducts(
        foods: sampleFoods,
        restaurants: restaurants,
        dateOverride: tuesday,
      );

      final rotWednesday = PartnerProductRotationUtil.rotateProducts(
        foods: sampleFoods,
        restaurants: restaurants,
        dateOverride: wednesday,
      );

      final partner1 = rotMonday.first.restaurantId;
      final partner2 = rotTuesday.first.restaurantId;
      final partner3 = rotWednesday.first.restaurantId;

      // Ensure rotation shifts daily across active partners
      expect(partner1 != partner2 || partner2 != partner3, isTrue);

      // Determinism test: Calling again with same date produces exact same order
      final rotMondayAgain = PartnerProductRotationUtil.rotateProducts(
        foods: sampleFoods,
        restaurants: restaurants,
        dateOverride: monday,
      );
      expect(rotMonday.map((f) => f.id).toList(), rotMondayAgain.map((f) => f.id).toList());
    });

    test('5. Consistency across pagination and scrolling slices', () {
      final rotated = PartnerProductRotationUtil.rotateProducts(
        foods: sampleFoods,
        restaurants: restaurants,
      );

      // Simulate Page 1 (items 0..3) and Page 2 (items 3..6)
      const pageSize = 3;
      final page1 = rotated.take(pageSize).toList();
      final page2 = rotated.skip(pageSize).take(pageSize).toList();

      expect(page1.length, 3);
      expect(page2.length, 3);

      final combined = [...page1, ...page2];
      expect(combined.map((f) => f.id).toList(), rotated.map((f) => f.id).toList());
    });

    test('6. Scales smoothly with master FallbackHotelData catalog', () {
      final allFoods = <FoodItemModel>[];
      for (final r in FallbackHotelData.restaurants) {
        allFoods.addAll(r.foods);
      }

      final rotated = PartnerProductRotationUtil.rotateProducts(
        foods: allFoods,
        restaurants: FallbackHotelData.restaurants,
      );

      expect(rotated.isNotEmpty, isTrue);
      // First 10 items should have high partner diversity
      final initialPartners = rotated.take(FallbackHotelData.restaurants.length).map((f) => f.restaurantId).toSet();
      expect(initialPartners.length, FallbackHotelData.restaurants.length);
    });
  });
}
