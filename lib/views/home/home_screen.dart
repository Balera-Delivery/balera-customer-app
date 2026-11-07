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
import '../../models/food_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/restaurant_provider.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final text = _searchController.text.trim();
      if (text != _searchQuery) {
        setState(() {
          _searchQuery = text;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().fetchDeliveries();
      context.read<NotificationProvider>().fetchNotifications();
      context.read<RestaurantProvider>().fetchRestaurants();
      context.read<RestaurantProvider>().fetchFoods();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        context.read<DeliveryProvider>().fetchDeliveries();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // ========================================================
            // 1. FIXED TOP BAR (Curved, Medium Size)
            // ========================================================
            _buildTopHeroSection(
              context: context,
              userName: userName,
              unreadCount: notificationProvider.unreadCount,
              activeDelivery: activeDelivery,
              hasActiveDelivery: hasActiveDelivery,
            ),

            // ========================================================
            // 2. SCROLLABLE BODY CONTENT
            // ========================================================
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      await Future.wait([
                        deliveryProvider.fetchDeliveries(),
                        notificationProvider.fetchNotifications(),
                        context.read<RestaurantProvider>().fetchRestaurants(),
                        context.read<RestaurantProvider>().fetchFoods(),
                      ]);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18.0, 14.0, 18.0, 110.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Retained Special Promotional Voucher Banner
                          _buildPromoBannerCard(context),

                          // Active Ongoing Order Tracker Card (if active order exists)
                          if (hasActiveDelivery) ...[
                            _buildActiveOngoingTrackerCard(context, activeDelivery),
                            const SizedBox(height: 18),
                          ],

                          // OTP Verification Box if Rider has Arrived
                          if (isArrived) ...[
                            _buildRiderArrivedOtpBox(context, activeDelivery),
                            const SizedBox(height: 18),
                          ],

                          // Services Section (6 colorful rounded cards matching screenshot)
                          _buildServicesSection(context),
                          const SizedBox(height: 22),

                          // Popular Food Section (Dynamic from Partner Hotels / Admin Dashboard)
                          _buildPopularFoodSection(context),
                          const SizedBox(height: 22),

                          // Recent Deliveries History Preview
                          _buildRecentDeliveriesSection(context, recentDeliveries),
                        ],
                      ),
                    ),
                  ),

                  // Floating Multi-Order Cart Bar (appears when 1 or more items are selected)
                  Consumer<RestaurantProvider>(
                    builder: (context, restProv, _) {
                      if (restProv.totalCartCount == 0) return const SizedBox.shrink();

                      final count = restProv.totalCartCount;
                      final totalPrice = restProv.totalCartPrice;

                      return Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateDeliveryScreen(
                                    initialCategory: DeliveryCategory.food,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF004BE4), Color(0xFF005BF6), Color(0xFF1E67FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0052EA).withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 17),
                                        const SizedBox(width: 5),
                                        Text(
                                          '$count',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$count ${count == 1 ? "dish" : "dishes"} selected',
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          '${totalPrice.toStringAsFixed(0)} Birr total',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withValues(alpha: 0.85),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: const [
                                      Text(
                                        'Checkout',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Hero Curved Section (Fixed in place, Medium size)
  // ---------------------------------------------------------------------------
  Widget _buildTopHeroSection({
    required BuildContext context,
    required String userName,
    required int unreadCount,
    required DeliveryModel? activeDelivery,
    required bool hasActiveDelivery,
  }) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0052EA), Color(0xFF0D5BFF), Color(0xFF1E67FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x350D50DB),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.0, topPadding + 6.0, 16.0, 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Circular Avatar 'B' + Greeting & Name + Bell Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Circular Avatar with official Balera Logo
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Image.asset(
                            'assets/logo/balera_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF0A2668),
                              child: const Center(
                                child: Text(
                                  'B',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                        Text(
                          userName.isNotEmpty ? userName : 'Faisa',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Translucent Circular Notification Bell Button
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Badge(
                        isLabelVisible: unreadCount > 0,
                        label: Text(
                          '$unreadCount',
                          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: AppColors.error,
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Hero Card: Balera Delivery, 24/7 pill, compact stepper
            _buildBaleraDeliveryHeroCard(context, activeDelivery, hasActiveDelivery),

            const SizedBox(height: 10),

            // Search Bar matching screenshot
            _buildSearchBar(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hero Card matching Screenshot (Interactive with Order Tracking)
  // ---------------------------------------------------------------------------
  Widget _buildBaleraDeliveryHeroCard(
    BuildContext context,
    DeliveryModel? delivery,
    bool hasActive,
  ) {
    final statusColor = hasActive ? const Color(0xFF00E5FF) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openTrackOrder(context, delivery);
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFF0038A8).withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasActive
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.20),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF002B82).withValues(alpha: 0.20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Pill Badge "Express Courier ● Active 24/7" (or Tracking #) + Arrow Button ↗
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: hasActive
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.20)
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasActive
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.50)
                            : Colors.white.withValues(alpha: 0.20),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasActive
                              ? 'Live Order ${delivery?.trackingCode != null ? "#${delivery!.trackingCode}" : "Active"}'
                              : 'Express Courier',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: hasActive ? const Color(0xFF00E5FF) : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: hasActive ? const Color(0xFF00E5FF) : const Color(0xFF00E5FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasActive
                              ? AppConstants.formatStatus(delivery?.status ?? 'ONGOING')
                              : 'Active 24/7',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow / Track Action Button ↗
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: hasActive ? const Color(0xFF00E5FF) : const Color(0xFF0D5BFF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.north_east_rounded,
                        color: hasActive ? const Color(0xFF0A2668) : Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),

              // Title "Balera Delivery" + Status subtitle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Balera Delivery',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (hasActive)
                    Row(
                      children: [
                        const Icon(Icons.my_location_rounded, size: 12, color: Color(0xFF00E5FF)),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to track',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 7),

              // Sub-row: "Instant Pickup" on left, "Doorstep Dropoff" on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 7,
                          color: hasActive ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            hasActive && delivery?.pickupLocation.isNotEmpty == true
                                ? delivery!.pickupLocation
                                : 'Instant Pickup',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.90),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            hasActive && delivery?.destination.isNotEmpty == true
                                ? delivery!.destination
                                : 'Doorstep Dropoff',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.90),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          Icons.location_on,
                          size: 11,
                          color: hasActive ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),

              // Dynamic Stepper matching order progress
              _buildHeroStepper(delivery, hasActive),
            ],
          ),
        ),
      ),
    );
  }

  // Stepper Line dynamically reflecting real delivery state or default progression
  Widget _buildHeroStepper([DeliveryModel? delivery, bool hasActive = false]) {
    // Stage indexes:
    // 0 = Order Placed / Pending
    // 1 = Accepted / Assigned to Rider
    // 2 = Picked Up / On The Way
    // 3 = Arrived / Delivered
    int currentStage = 0;
    if (hasActive && delivery != null) {
      final status = delivery.status.toUpperCase();
      if (status == AppConstants.statusDelivered || status == 'COMPLETED') {
        currentStage = 3;
      } else if (status == AppConstants.statusOnTheWay || status == AppConstants.statusPickedUp) {
        currentStage = 2;
      } else if (status == AppConstants.statusAssigned || status == AppConstants.statusArrivedAtPickup) {
        currentStage = 1;
      } else {
        currentStage = 0;
      }
    } else {
      // Default idle illustration matching screenshot (stage 2 active on bike)
      currentStage = 2;
    }

    final isStep1Active = currentStage >= 0;
    final isStep2Active = currentStage >= 1;
    final isStep3Active = currentStage >= 2;
    final isStep4Active = currentStage >= 3;

    return Row(
      children: [
        // 1. Order Placed / Instant Pickup
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isStep1Active ? const Color(0xFF0D5BFF) : Colors.white.withValues(alpha: 0.20),
            shape: BoxShape.circle,
            border: Border.all(
              color: isStep1Active ? const Color(0xFF00E5FF) : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, color: Colors.white, size: 13),
          ),
        ),

        // Dotted connector 1
        Expanded(child: _buildDottedLine(isStep2Active)),

        // 2. Rider Assigned / Confirmed
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isStep2Active ? const Color(0xFF0D5BFF) : Colors.white.withValues(alpha: 0.20),
            shape: BoxShape.circle,
            border: Border.all(
              color: isStep2Active ? const Color(0xFF00E5FF) : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Center(
            child: Icon(
              isStep2Active ? Icons.check_rounded : Icons.circle,
              color: Colors.white,
              size: isStep2Active ? 13 : 6,
            ),
          ),
        ),

        // Dotted connector 2
        Expanded(child: _buildDottedLine(isStep3Active)),

        // 3. Motorcycle Rider circle (Cyan when on the way)
        Container(
          width: 23,
          height: 23,
          decoration: BoxDecoration(
            color: isStep3Active ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.20),
            shape: BoxShape.circle,
            boxShadow: isStep3Active
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              Icons.two_wheeler_rounded,
              color: isStep3Active ? const Color(0xFF0A2668) : Colors.white.withValues(alpha: 0.7),
              size: 15,
            ),
          ),
        ),

        // Dotted connector 3
        Expanded(child: _buildDottedLine(isStep4Active)),

        // 4. Target Destination / Doorstep Dropoff
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isStep4Active ? const Color(0xFF00E5FF) : Colors.transparent,
            border: Border.all(
              color: isStep4Active ? const Color(0xFF00E5FF) : Colors.white,
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isStep4Active ? const Color(0xFF0A2668) : Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDottedLine([bool isActive = false]) {
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
                  color: isActive
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF64748B),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: _selectedCategoryFilter == 'All'
                    ? 'Search food or restaurant...'
                    : 'Search $_selectedCategoryFilter...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            InkWell(
              onTap: () {
                _searchController.clear();
              },
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close_rounded,
                  color: Color(0xFF94A3B8),
                  size: 17,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          InkWell(
            onTap: () {
              _showFilterModal(context);
            },
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _selectedCategoryFilter != 'All'
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFF0D5BFF),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.tune_rounded,
                  color: _selectedCategoryFilter != 'All'
                      ? const Color(0xFF0A2668)
                      : Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal(BuildContext context) {
    final categories = [
      'All',
      'Haniid & Roasts',
      'Tibs & Grills',
      'Traditional & Stews',
      'Breakfast (Ciree)',
      'Rice Dishes',
      'Pizzas',
      'Burgers & Sandwiches',
      'Fast Foods',
      'Drinks & Juices',
      'Hot Drinks & Coffee',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Menu by Category',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (_selectedCategoryFilter != 'All')
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedCategoryFilter = 'All';
                            });
                            setState(() {
                              _selectedCategoryFilter = 'All';
                            });
                          },
                          child: const Text('Reset'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = _selectedCategoryFilter == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: const Color(0xFF0D5BFF),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        backgroundColor: const Color(0xFFF1F5F9),
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedCategoryFilter = selected ? cat : 'All';
                          });
                          setState(() {
                            _selectedCategoryFilter = selected ? cat : 'All';
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Active Ongoing Order Tracker Card (Matches Page 1 & 2 design)
  // ---------------------------------------------------------------------------
  Widget _buildActiveOngoingTrackerCard(BuildContext context, DeliveryModel? delivery) {
    if (delivery == null) return const SizedBox.shrink();

    final tracking = (delivery.trackingCode != null && delivery.trackingCode!.trim().isNotEmpty)
        ? (delivery.trackingCode!.startsWith('#') ? delivery.trackingCode! : '#${delivery.trackingCode}')
        : (delivery.id.length >= 8 ? '#${delivery.id.substring(0, 8)}' : '#${delivery.id}');
    final statusText = AppConstants.formatStatus(delivery.status);

    return InkWell(
      onTap: () => _openTrackOrder(context, delivery),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D64EC).withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF1D64EC),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D64EC).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 24),
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
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1D64EC),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D64EC),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Order $tracking',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${delivery.pickupLocation} → ${delivery.destination}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1D64EC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Track ›',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // "Services" Section (6 Colorful Rounded Cards matching Screenshot)
  // ---------------------------------------------------------------------------
  Widget _buildServicesSection(BuildContext context) {
    final services = [
      {
        'title': 'Food',
        'icon': Icons.room_service_outlined,
        'color': const Color(0xFFFEF3C7),
        'iconColor': const Color(0xFFD97706),
        'category': DeliveryCategory.food,
        'itemType': 'Food & Restaurant',
      },
      {
        'title': 'Parcel',
        'icon': Icons.all_inbox_rounded,
        'color': const Color(0xFFDBEAFE),
        'iconColor': const Color(0xFF2563EB),
        'category': DeliveryCategory.other,
        'itemType': 'Parcel / Box',
      },
      {
        'title': 'Ecommerce',
        'icon': Icons.shopping_bag_outlined,
        'color': const Color(0xFFFCE7F3),
        'iconColor': const Color(0xFFDB2777),
        'category': DeliveryCategory.other,
        'itemType': 'Online Orders',
      },
      {
        'title': 'Document',
        'icon': Icons.description_outlined,
        'color': const Color(0xFFDCFCE7),
        'iconColor': const Color(0xFF16A34A),
        'category': DeliveryCategory.other,
        'itemType': 'Documents & Letters',
      },
      {
        'title': 'Electronics',
        'icon': Icons.headphones_outlined,
        'color': const Color(0xFFEDE9FE),
        'iconColor': const Color(0xFF7C3AED),
        'category': DeliveryCategory.other,
        'itemType': 'Electronics & Gadgets',
      },
      {
        'title': 'Anything',
        'icon': Icons.auto_awesome_rounded,
        'color': const Color(0xFFFFE4D6),
        'iconColor': const Color(0xFFEA580C),
        'category': DeliveryCategory.other,
        'itemType': 'Custom Delivery',
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
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: _buildServiceItem(
                  title: s['title'] as String,
                  icon: s['icon'] as IconData,
                  bgColor: s['color'] as Color,
                  iconColor: s['iconColor'] as Color,
                  onTap: () => _openCategory(
                    context,
                    category: s['category'] as DeliveryCategory,
                    itemType: s['itemType'] as String,
                  ),
                ),
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
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 52),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 23),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // "Popular food" Section (Dynamic from Partner Hotels / Admin Dashboard)
  // ---------------------------------------------------------------------------
  Widget _buildPopularFoodSection(BuildContext context) {
    final restaurantProvider = context.watch<RestaurantProvider>();
    final allFoods = restaurantProvider.foods;
    final isLoading = restaurantProvider.isLoadingFoods && allFoods.isEmpty;

    // Filter foods by instant search query and selected category
    final foods = allFoods.where((f) {
      final rName = (f.restaurantName != null && f.restaurantName!.isNotEmpty)
          ? f.restaurantName!
          : restaurantProvider.getRestaurantName(f.restaurantId);

      final matchesQuery = _searchQuery.isEmpty ||
          f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          rName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (f.category != null && f.category!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          (f.description != null && f.description!.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesCategory = _selectedCategoryFilter == 'All' ||
          (f.category != null &&
              f.category!.toLowerCase().contains(_selectedCategoryFilter.toLowerCase()));

      return matchesQuery && matchesCategory;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row: "Popular food" + "View all ›"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Search results (${foods.length})'
                      : (_selectedCategoryFilter != 'All'
                          ? '$_selectedCategoryFilter (${foods.length})'
                          : 'Popular food'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
                if (_searchQuery.isNotEmpty || _selectedCategoryFilter != 'All')
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _selectedCategoryFilter = 'All';
                        });
                      },
                      child: const Text(
                        'Clear filters',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D5BFF),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            InkWell(
              onTap: () => _openCategory(context, category: DeliveryCategory.food, itemType: 'Food & Groceries'),
              child: const Row(
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D5BFF),
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF0D5BFF)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF0D5BFF),
              ),
            ),
          )
        else if (foods.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 36,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No dishes matching "$_searchQuery"'
                        : 'No dishes available in $_selectedCategoryFilter right now.',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: foods.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.64,
            ),
            itemBuilder: (context, index) {
              final food = foods[index];
              final restaurantName = (food.restaurantName != null && food.restaurantName!.isNotEmpty)
                  ? food.restaurantName!
                  : restaurantProvider.getRestaurantName(food.restaurantId);
              final time = (food.restaurantDeliveryTime != null && food.restaurantDeliveryTime!.isNotEmpty)
                  ? food.restaurantDeliveryTime!
                  : restaurantProvider.getRestaurantDeliveryTime(food.restaurantId);
              final rating = (food.restaurantRating != null)
                  ? food.restaurantRating!.toStringAsFixed(1)
                  : restaurantProvider.getRestaurantRating(food.restaurantId).toStringAsFixed(1);

              return _buildPopularFoodCard(
                context: context,
                food: food,
                title: food.name,
                restaurant: restaurantName,
                price: food.price.toInt(),
                rating: rating,
                time: time,
              );
            },
          ),
      ],
    );
  }

  Widget _buildPopularFoodCard({
    required BuildContext context,
    required FoodItemModel food,
    required String title,
    required String restaurant,
    required int price,
    required String rating,
    required String time,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upper Half: Soft light-blue image container with Heart button & White Pill Price Badge
          Stack(
            children: [
              Container(
                height: 110,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(19),
                    topRight: Radius.circular(19),
                  ),
                ),
                child: food.image != null && food.image!.startsWith('http')
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(19),
                          topRight: Radius.circular(19),
                        ),
                        child: Image.network(
                          food.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: Color(0xFF93B4F5),
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: Color(0xFF93B4F5),
                        ),
                      ),
              ),

              // Heart / Favorite circular button
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.favorite_border_rounded,
                      size: 15,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),

              // White Pill Price Badge with bold blue text (matching screenshot)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'ETB $price',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D5BFF),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Lower Half: Food details, Restaurant storefront, Rating & Blue '+' button
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 13,
                      color: Color(0xFF0D5BFF),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        restaurant,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              '$rating · $time',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Consumer<RestaurantProvider>(
                      builder: (context, restProv, _) {
                        final inCart = restProv.isFoodInCart(food.id);
                        final qty = restProv.getFoodQuantityInCart(food.id);

                        if (inCart && qty > 0) {
                          return Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF0D5BFF), width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    restProv.removeFromCart(food.id);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: const Icon(
                                    Icons.remove_rounded,
                                    size: 15,
                                    color: Color(0xFF0D5BFF),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    '$qty',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0D5BFF),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    restProv.addToCart(food);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    size: 15,
                                    color: Color(0xFF0D5BFF),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            restProv.addToCart(food);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added ${food.name} to order'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                action: SnackBarAction(
                                  label: 'View',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const CreateDeliveryScreen(
                                          initialCategory: DeliveryCategory.food,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0D5BFF),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
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
