import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/balera_logo.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/notification_provider.dart';
import '../delivery/create_delivery_screen.dart';
import '../delivery/delivery_details_screen.dart';
import '../delivery/delivery_otp_screen.dart';
import '../delivery/delivery_tracking_screen.dart';
import '../history/delivery_history_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().fetchDeliveries();
      context.read<NotificationProvider>().fetchNotifications();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        context.read<DeliveryProvider>().fetchDeliveries();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  void _openTrackOrder(BuildContext context, [DeliveryModel? specificDelivery]) async {
    final deliveryProvider = context.read<DeliveryProvider>();
    final activeDelivery = specificDelivery ?? deliveryProvider.activeDelivery;

    if (activeDelivery != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryTrackingScreen(
            deliveryId: activeDelivery.id,
            initialDelivery: activeDelivery,
          ),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DeliveryHistoryScreen()),
      );
    }
    if (context.mounted) {
      context.read<DeliveryProvider>().fetchDeliveries();
    }
  }

  IconData _getItemIcon(String? itemType) {
    if (itemType == null) return Icons.inventory_2_rounded;
    final lower = itemType.toLowerCase();
    if (lower.contains('food') || lower.contains('restaurant') || lower.contains('dish')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('document') || lower.contains('file')) {
      return Icons.description_rounded;
    }
    if (lower.contains('electronic') || lower.contains('phone')) {
      return Icons.devices_rounded;
    }
    if (lower.contains('cloth') || lower.contains('wear')) {
      return Icons.shopping_bag_rounded;
    }
    return Icons.inventory_2_rounded;
  }

  void _openCategory(BuildContext context, {DeliveryCategory? category, String? itemType}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateDeliveryScreen(
          initialCategory: category,
          initialItemType: itemType,
        ),
      ),
    );
  }

  Widget _buildPromoBannerCard(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: AppColors.logoGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateDeliveryScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SPECIAL PROMO',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Save on Orders',
                            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Apply promo codes at checkout for instant discounts & free delivery!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final deliveryProvider = context.watch<DeliveryProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final activeDelivery = deliveryProvider.activeDelivery;
    final userName = authProvider.currentUser?.fullName.split(' ').first ?? 'Customer';

    final hasActiveDelivery = activeDelivery != null && AppConstants.isOngoing(activeDelivery.status);

    final isArrived = hasActiveDelivery &&
        (activeDelivery.status == AppConstants.statusArrivedAtPickup ||
            activeDelivery.status == 'ARRIVED' ||
            activeDelivery.status == AppConstants.statusPickedUp ||
            activeDelivery.status == AppConstants.statusOnTheWay);

    // Current / Ongoing deliveries
    final List<DeliveryModel> currentDeliveries = deliveryProvider.deliveries
        .where((d) => AppConstants.isOngoing(d.status))
        .toList();

    // Recent / Past completed deliveries
    final List<DeliveryModel> recentDeliveries = deliveryProvider.deliveries
        .where((d) => !AppConstants.isOngoing(d.status))
        .take(5)
        .toList();

    // Delivered deliveries this week only (for analytics counting)
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final int deliveredThisWeekCount = deliveryProvider.deliveries.where((d) {
      final isDelivered = d.status.toUpperCase() == 'DELIVERED' || d.status.toUpperCase() == 'COMPLETED';
      if (!isDelivered) return false;
      if (d.createdAt != null) {
        return d.createdAt!.isAfter(startOfWeek) || d.createdAt!.isAtSameMomentAs(startOfWeek);
      }
      return true;
    }).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: true,
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await deliveryProvider.fetchDeliveries();
              await notificationProvider.fetchNotifications();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========================================================
                  // 1. TOP CURVED HERO SECTION (Matching reference design)
                  // ========================================================
                  _buildTopHeroSection(
                    context: context,
                    userName: userName,
                    unreadCount: notificationProvider.unreadCount,
                    activeDelivery: activeDelivery,
                    hasActiveDelivery: hasActiveDelivery,
                  ),

                  const SizedBox(height: 20),

                  // ========================================================
                  // 2. MAIN BODY CONTENT
                  // ========================================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Special Promotional Banner
                        _buildPromoBannerCard(context),

                        // OTP Verification Box if Rider has Arrived
                        if (isArrived) ...[
                          _buildRiderArrivedOtpBox(context, activeDelivery),
                          const SizedBox(height: 20),
                        ],

                        // Services / Quick Categories
                        _buildServicesSection(context),
                        const SizedBox(height: 24),

                        // Active Deliveries Section (Horizontal scrollable cards)
                        _buildActiveDeliveriesSection(
                          context: context,
                          deliveries: currentDeliveries,
                          hasDeliveries: currentDeliveries.isNotEmpty,
                        ),
                        const SizedBox(height: 24),

                        // "This Week" Bento Stats Section (Count ONLY delivered deliveries)
                        _buildThisWeekStats(deliveredThisWeekCount),
                        const SizedBox(height: 24),

                        // Recent Deliveries History Preview
                        _buildRecentDeliveriesSection(context, recentDeliveries),
                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Hero Curved Section (Greeting, Current Delivery Card, Stepper)
  // ---------------------------------------------------------------------------
  Widget _buildTopHeroSection({
    required BuildContext context,
    required String userName,
    required int unreadCount,
    required DeliveryModel? activeDelivery,
    required bool hasActiveDelivery,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.logoDarkGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x350038A8),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: User Avatar & Greeting + Notification Bell
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // User Avatar + Greeting Text
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const ClipOval(
                        child: BaleraLogo(size: 40, showShadow: false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Notification Bell Icon Button
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Badge(
                        isLabelVisible: unreadCount > 0,
                        label: Text(
                          '$unreadCount',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: AppColors.error,
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ========================================================
            // Current Delivery Card (Exact match to reference design)
            // ========================================================
            _buildCurrentDeliveryCard(context, activeDelivery, hasActiveDelivery),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Current Delivery Card with Timeline Stepper & Tracking Code
  // ---------------------------------------------------------------------------
  Widget _buildCurrentDeliveryCard(
    BuildContext context,
    DeliveryModel? delivery,
    bool hasActive,
  ) {
    final trackingCode = delivery?.trackingCode != null && delivery!.trackingCode!.trim().isNotEmpty
        ? (delivery.trackingCode!.startsWith('#') ? delivery.trackingCode! : '#${delivery.trackingCode}')
        : (delivery != null
            ? (delivery.id.length >= 8 ? '#${delivery.id.substring(0, 8)}' : '#${delivery.id}')
            : 'BLR-889641');
    final statusText = delivery?.status != null ? AppConstants.formatStatus(delivery!.status) : 'In Transit';

    final now = DateTime.now();
    final pickupDateStr = delivery?.createdAt != null
        ? Formatters.date(delivery!.createdAt)
        : Formatters.date(now);
    final estDeliveryDate = (delivery?.createdAt ?? now).add(const Duration(hours: 2));
    final estDeliveryStr = 'Est. ${Formatters.date(estDeliveryDate)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002B82).withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-header Row: "Current Delivery" + Pill Badge + Angled Arrow Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        hasActive ? 'Current Delivery' : 'Express Courier',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.90),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            hasActive ? statusText : 'Active 24/7',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Angled Arrow Button ↗
              InkWell(
                onTap: () {
                  if (hasActive) {
                    _openTrackOrder(context, delivery);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateDeliveryScreen()),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Tracking Number or Balera Delivery in Prominent Bold Display Font
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              hasActive ? trackingCode : 'Balera Delivery',
              style: TextStyle(
                fontSize: hasActive ? 24 : 25,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: hasActive ? 0.5 : -0.3,
                height: 1.15,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                  Shadow(
                    color: AppColors.accent.withValues(alpha: 0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stepper: Date row on top
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  hasActive
                      ? (delivery?.pickupLocation.isNotEmpty == true ? delivery!.pickupLocation : 'Pickup')
                      : 'Instant Pickup',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasActive
                      ? (delivery?.destination.isNotEmpty == true ? delivery!.destination : 'Dropoff')
                      : 'Doorstep Dropoff',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Visual Stepper Progress Line with Dotted Track & Vehicle Icon
          _buildTimelineStepper(hasActive, delivery?.status),

          const SizedBox(height: 8),

          // Pickup and Estimate Subtitle Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pickupDateStr,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
              Text(
                estDeliveryStr,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Timeline Stepper (Checkmark -> Dotted -> Vehicle Pill -> Dotted -> Pin)
  // ---------------------------------------------------------------------------
  Widget _buildTimelineStepper(bool hasActive, String? status) {
    return Row(
      children: [
        // 1. Pickup Checkpoint (Completed)
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, color: Colors.white, size: 14),
          ),
        ),

        // Dotted connector
        Expanded(
          child: _buildDottedLine(),
        ),

        // 2. Middle In-Transit Checkpoint
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, color: Colors.white, size: 14),
          ),
        ),

        // Dotted connector
        Expanded(
          child: _buildDottedLine(),
        ),

        // 3. Active Vehicle Indicator (Glowing Courier Pill)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.two_wheeler_rounded,
                color: Color(0xFF0038A8),
                size: 16,
              ),
            ],
          ),
        ),

        // Dotted connector
        Expanded(
          child: _buildDottedLine(),
        ),

        // 4. Destination Target Point
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDottedLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxWidth / 6).floor().clamp(2, 10);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(count, (_) {
              return Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // "Services" Section (5 Rounded Icon Cards from the screenshot)
  // ---------------------------------------------------------------------------
  Widget _buildServicesSection(BuildContext context) {
    final services = [
      {
        'title': 'Food',
        'icon': Icons.restaurant_rounded,
        'color': const Color(0xFFFEF3C7),
        'iconColor': const Color(0xFFD97706),
        'category': DeliveryCategory.food,
        'itemType': 'Food & Groceries',
      },
      {
        'title': 'Parcel',
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFFEFF6FF),
        'iconColor': AppColors.primary,
        'category': DeliveryCategory.other,
        'itemType': 'Parcel / Box',
      },
      {
        'title': 'Document',
        'icon': Icons.description_rounded,
        'color': const Color(0xFFDCFCE7),
        'iconColor': const Color(0xFF16A34A),
        'category': DeliveryCategory.other,
        'itemType': 'Documents & Letters',
      },
      {
        'title': 'Electronics',
        'icon': Icons.devices_rounded,
        'color': const Color(0xFFF3E8FF),
        'iconColor': const Color(0xFF9333EA),
        'category': DeliveryCategory.other,
        'itemType': 'Electronics & Gadgets',
      },
      {
        'title': 'Anything',
        'icon': Icons.all_inbox_rounded,
        'color': const Color(0xFFFEE2E2),
        'iconColor': const Color(0xFFDC2626),
        'category': DeliveryCategory.other,
        'itemType': 'Other',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: services.map((s) {
            return _buildServiceItem(
              title: s['title'] as String,
              icon: s['icon'] as IconData,
              bgColor: s['color'] as Color,
              iconColor: s['iconColor'] as Color,
              onTap: () => _openCategory(
                context,
                category: s['category'] as DeliveryCategory,
                itemType: s['itemType'] as String,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildServiceItem({
    required String title,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 26),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // "Active Deliveries" (Horizontal Cards matching reference layout)
  // ---------------------------------------------------------------------------
  Widget _buildActiveDeliveriesSection({
    required BuildContext context,
    required List<DeliveryModel> deliveries,
    required bool hasDeliveries,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Deliveries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeliveryHistoryScreen()),
                );
              },
              child: const Row(
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (deliveries.isNotEmpty)
          SizedBox(
            height: 134,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: deliveries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = deliveries[index];
                return _buildDeliveryHorizontalCard(context, item);
              },
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Active Deliveries',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tap a service above to send or request a delivery.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDeliveryHorizontalCard(BuildContext context, DeliveryModel item) {
    final tracking = (item.trackingCode != null && item.trackingCode!.trim().isNotEmpty)
        ? (item.trackingCode!.startsWith('#') ? item.trackingCode!.substring(1) : item.trackingCode!)
        : (item.id.length >= 8 ? item.id.substring(0, 8) : item.id);
    final pickup = item.pickupLocation.trim().isNotEmpty ? item.pickupLocation.trim() : 'Pickup';
    final destination = item.destination.trim().isNotEmpty ? item.destination.trim() : 'Destination';
    final itemType = item.itemType.trim().isNotEmpty ? item.itemType.trim() : 'Package';

    return InkWell(
      onTap: () async {
        if (AppConstants.isOngoing(item.status)) {
          _openTrackOrder(context, item);
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DeliveryDetailsScreen(delivery: item)),
          );
          if (context.mounted) {
            context.read<DeliveryProvider>().fetchDeliveries();
          }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF030D26).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Pin / Route icons + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.circle, size: 8, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF16A34A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: StatusBadge(
                    status: item.status,
                    fontSize: 10.5,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  ),
                ),
              ],
            ),

            // Route Name: Pickup -> Destination
            Text(
              '$pickup → $destination',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Order Tracking Label + Item Type Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #$tracking',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(maxWidth: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
                  ),
                  child: Text(
                    itemType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // "This Week" Bento Section (Parcels Sent + Mini Chart, On-time Rate)
  // ---------------------------------------------------------------------------
  Widget _buildThisWeekStats(int parcelsSent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This Week',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            // Card 1: Parcels Sent + Mini Bar Chart
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF030D26).withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Delivered',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$parcelsSent',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            height: 1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.trending_up_rounded, size: 12, color: Color(0xFF16A34A)),
                              SizedBox(width: 2),
                              Text(
                                '+18%',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Mini Bar Chart Visualization
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildMiniBar(0.4),
                        _buildMiniBar(0.7),
                        _buildMiniBar(0.55),
                        _buildMiniBar(0.9, isHighlight: true),
                        _buildMiniBar(0.6),
                        _buildMiniBar(0.3),
                        _buildMiniBar(0.5),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Card 2: On-time Delivery Rate
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF030D26).withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFD97706)),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Rating',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '98%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'On-time dispatch with verified OTP delivery',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniBar(double fraction, {bool isHighlight = false}) {
    return Container(
      width: 10,
      height: 32 * fraction,
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.primary : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Rider Arrived 6-digit OTP Box
  // ---------------------------------------------------------------------------
  Widget _buildRiderArrivedOtpBox(BuildContext context, DeliveryModel activeDelivery) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.directions_bike_rounded, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Rider Has Arrived!',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF15803D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Active',
                style: TextStyle(
                  color: Color(0xFF15803D),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Give this 6-digit OTP code to the rider to confirm handover:',
            style: TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.3),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      activeDelivery.otpCode ?? '482913',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeliveryOtpScreen(
                          deliveryId: activeDelivery.trackingCode ?? activeDelivery.id,
                          otpCode: activeDelivery.otpCode,
                        ),
                      ),
                    );
                  },
                  child: const Text('View & Complete', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Recent Deliveries List
  // ---------------------------------------------------------------------------
  Widget _buildRecentDeliveriesSection(BuildContext context, List<DeliveryModel> recentDeliveries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Deliveries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeliveryHistoryScreen()),
                );
              },
              child: const Row(
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (recentDeliveries.isNotEmpty)
          Column(
            children: recentDeliveries.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DeliveryDetailsScreen(delivery: item)),
                    );
                    if (context.mounted) {
                      context.read<DeliveryProvider>().fetchDeliveries();
                    }
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                          ),
                          child: Icon(_getItemIcon(item.itemType), size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (item.trackingCode != null && item.trackingCode!.trim().isNotEmpty)
                                    ? (item.trackingCode!.startsWith('#') ? item.trackingCode! : '#${item.trackingCode}')
                                    : (item.id.length >= 8 ? '#${item.id.substring(0, 8)}' : '#${item.id}'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${item.pickupLocation} → ${item.destination}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: StatusBadge(
                            status: item.status,
                            fontSize: 11,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: const Text(
              'No past deliveries yet.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Drawer
  // ---------------------------------------------------------------------------
  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: AppColors.logoDarkGradient,
            ),
            accountName: Text(
              authProvider.currentUser?.fullName ?? 'Customer',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            accountEmail: Text(
              authProvider.currentUser?.phoneNumber ?? authProvider.currentUser?.email ?? '',
            ),
            currentAccountPicture: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const ClipOval(
                child: BaleraLogo(size: 50, showShadow: false),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
            title: const Text('Request a Delivery'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateDeliveryScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.track_changes_rounded, color: AppColors.primary),
            title: const Text('Track Order'),
            onTap: () {
              Navigator.pop(context);
              _openTrackOrder(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded, color: AppColors.primary),
            title: const Text('My Deliveries'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryHistoryScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
        ],
      ),
    );
  }
}
