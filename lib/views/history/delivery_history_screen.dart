import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import '../delivery/delivery_details_screen.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  String _selectedFilter = 'All'; // All, Completed, In Progress, Cancelled

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().fetchDeliveries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = context.watch<DeliveryProvider>();

    List<DeliveryModel> getFilteredList() {
      if (_selectedFilter == 'Completed') {
        return deliveryProvider.completedDeliveries;
      } else if (_selectedFilter == 'In Progress') {
        return deliveryProvider.ongoingDeliveries;
      } else if (_selectedFilter == 'Cancelled') {
        return deliveryProvider.cancelledDeliveries;
      }
      return deliveryProvider.deliveries;
    }

    final list = getFilteredList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Fixed Top Curved Royal Blue Header
            _buildCurvedHeader(
              context,
              list.length,
              deliveryProvider.deliveries.length,
              deliveryProvider.completedDeliveries.length,
              deliveryProvider.ongoingDeliveries.length,
              deliveryProvider.cancelledDeliveries.length,
            ),

            // Scrollable Delivery Cards List with Pull-to-refresh
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF0052EA),
                onRefresh: () => deliveryProvider.fetchDeliveries(),
                child: list.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          EmptyStateView(
                            icon: Icons.inventory_2_outlined,
                            title: 'No Deliveries Found',
                            message: 'No delivery records match "$_selectedFilter" category.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return _buildDeliveryCard(context, item);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Royal Blue Curved Header with Professional Segmented Filter Buttons
  // ---------------------------------------------------------------------------
  Widget _buildCurvedHeader(
    BuildContext context,
    int count,
    int allCount,
    int completedCount,
    int inProgressCount,
    int cancelledCount,
  ) {
    final topPadding = MediaQuery.of(context).padding.top;
    final filters = [
      {'name': 'All', 'count': allCount},
      {'name': 'Completed', 'count': completedCount},
      {'name': 'In Progress', 'count': inProgressCount},
      {'name': 'Cancelled', 'count': cancelledCount},
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 14,
        bottom: 22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF004BE4),
            Color(0xFF005BF6),
            Color(0xFF1E67FF),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33005BF6),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Count in Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Deliveries',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 23,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count ${count == 1 ? 'delivery' : 'deliveries'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
                // Quick Filter Tag badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedFilter,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Professional Filter Buttons row inside the Blue Header
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: filters.map((filter) {
                final filterName = filter['name'] as String;
                final filterCount = filter['count'] as int;
                final isSelected = _selectedFilter == filterName;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedFilter = filterName;
                        });
                      },
                      borderRadius: BorderRadius.circular(26),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.32),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.14),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              Container(
                                width: 17,
                                height: 17,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF0052EA),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              filterName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? const Color(0xFF0052EA) : Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (filterCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF0052EA).withValues(alpha: 0.12)
                                      : Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$filterCount',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? const Color(0xFF0052EA)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delivery Card (Screen 17 redesign matching the screenshot)
  // ---------------------------------------------------------------------------
  Widget _buildDeliveryCard(BuildContext context, DeliveryModel item) {
    final status = (item.status).toUpperCase().replaceAll('-', '_');
    final isCancelled = AppConstants.isCancelled(item.status);
    final isCompleted = status == 'DELIVERED' || status == 'COMPLETED';

    // Status pill theme
    Color badgeBg;
    Color badgeColor;
    Color iconBg;
    Color iconColor;

    if (isCancelled) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeColor = const Color(0xFFDC2626);
      iconBg = const Color(0xFFFEE2E2);
      iconColor = const Color(0xFFDC2626);
    } else if (isCompleted) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeColor = const Color(0xFF16A34A);
      iconBg = const Color(0xFFDBEAFE);
      iconColor = const Color(0xFF0052EA);
    } else {
      // In progress / On the way / Assigned / Pending
      badgeBg = const Color(0xFFDBEAFE);
      badgeColor = const Color(0xFF0052EA);
      iconBg = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFD97706);
    }

    // Format display tracking code
    final rawCode = item.trackingCode ?? item.id;
    final displayCode = rawCode.startsWith('#') ? rawCode : '#$rawCode';

    // Formatted date and time
    final dateStr = item.createdAt != null
        ? Formatters.date(item.createdAt)
        : 'Nov 04, 2026';
    final timeStr = item.createdAt != null
        ? Formatters.time(item.createdAt)
        : '08:30 AM';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeliveryDetailsScreen(delivery: item),
              ),
            );
          },
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Soft Pastel Rounded Icon Box
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.local_shipping_outlined,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Order Code & Date/Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayCode,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$dateStr • $timeStr',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge Pill with Dot
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppConstants.formatStatus(item.status),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Forward Arrow
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

