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
            // Fixed Top Curved Royal Blue Header with fitted filter buttons
            _buildCurvedHeader(context, list.length),

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
  // Top Royal Blue Curved Header with Fixed-in-place Filter Buttons
  // ---------------------------------------------------------------------------
  Widget _buildCurvedHeader(BuildContext context, int count) {
    final topPadding = MediaQuery.of(context).padding.top;
    final filters = ['All', 'Completed', 'In Progress', 'Cancelled'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 14,
        left: 18,
        right: 18,
        bottom: 18,
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
          bottom: Radius.circular(30),
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
          // Title & Count in Header (clean and simple like the reference image)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Deliveries',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count ${count == 1 ? 'delivery' : 'deliveries'}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Exact 4 Buttons Fitted Perfectly in One Fixed Row (No overflow, no horizontal scroll needed)
          Row(
            children: filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 6.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: Color(0xFF0052EA),
                              ),
                              const SizedBox(width: 2.5),
                            ],
                            Flexible(
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? const Color(0xFF0052EA) : Colors.white,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
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

