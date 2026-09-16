import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().fetchDeliveries();
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  void _openTrackOrder(BuildContext context, [DeliveryModel? specificDelivery]) {
    final deliveryProvider = context.read<DeliveryProvider>();
    final activeDelivery = specificDelivery ?? deliveryProvider.activeDelivery;

    if (activeDelivery != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryTrackingScreen(
            deliveryId: activeDelivery.id,
            initialDelivery: activeDelivery,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DeliveryHistoryScreen()),
      );
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

  Widget _buildHeroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context, DeliveryModel item, {bool isCurrent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: () {
          if (isCurrent && AppConstants.isOngoing(item.status)) {
            _openTrackOrder(context, item);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DeliveryDetailsScreen(delivery: item)),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
              width: isCurrent ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isCurrent ? Colors.blue.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getItemIcon(item.itemType),
                          size: 16,
                          color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#${item.trackingCode ?? item.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(status: item.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.pickupLocation} → ${item.destination}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ],
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 64,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 6.0, bottom: 6.0),
          child: BaleraLogo(size: 40),
        ),
        actions: [
          // Notification Bell
          IconButton(
            icon: Badge(
              isLabelVisible: notificationProvider.unreadCount > 0,
              label: Text(
                '${notificationProvider.unreadCount}',
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.error,
              child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 24),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              accountName: Text(authProvider.currentUser?.fullName ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.w700)),
              accountEmail: Text(authProvider.currentUser?.phoneNumber ?? authProvider.currentUser?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: AppColors.primary, size: 36),
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
      ),
      body: RefreshIndicator(
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
              // 1. Big Blue Hero Welcome Card (Edge-to-Edge with Left & Right = 0)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF003893), // Deep royal navy
                      Color(0xFF0047BA), // Balera primary blue
                      Color(0xFF0D6EFD), // Electric blue accent
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0047BA).withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  child: Stack(
                    children: [
                      // Decorative background spheres
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -35,
                        left: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),

                      // Hero Card Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22.0, 16.0, 22.0, 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logistics tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFFDE047)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Fast & Secure Logistics',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Hello Name Greeting
                            Row(
                              children: [
                                Text(
                                  'Hello, $userName',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.95),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('👋', style: TextStyle(fontSize: 15)),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // Welcome to Balera Delivery (Hero Headline - High Impact & Professional)
                            const Text(
                              'Welcome to Balera Delivery',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.6,
                                height: 1.18,
                                shadows: [
                                  Shadow(
                                    color: Color(0x38000000),
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Warm Welcome Text (Clear, Crisp & Professional)
                            Text(
                              'Fast, reliable courier & package delivery across Bale with live GPS tracking and secure OTP handover.',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.90),
                                height: 1.45,
                                letterSpacing: 0.1,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Micro Feature Pills
                            Row(
                              children: [
                                _buildHeroChip(Icons.verified_user_rounded, 'OTP Verified'),
                                const SizedBox(width: 8),
                                _buildHeroChip(Icons.location_on_rounded, 'Live GPS'),
                                const SizedBox(width: 8),
                                _buildHeroChip(Icons.speed_rounded, 'Fast Pickup'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Padded Body Sections
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Rider Arrived & Delivery OTP Box (If rider is active & arrived)
                    if (isArrived) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(18),
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
                                Row(
                                  children: [
                                    Icon(Icons.directions_bike_rounded, color: AppColors.success, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Rider Has Arrived!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
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
                                  Text(
                                    activeDelivery.otpCode ?? '482913',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 5,
                                      color: AppColors.primary,
                                    ),
                                  ),
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
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 3. Active Deliveries Section (On Top of Recent Deliveries)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: currentDeliveries.isNotEmpty
                                    ? const Color(0xFF16A34A)
                                    : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Active Deliveries',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        if (currentDeliveries.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Text(
                              '${currentDeliveries.length} active',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (currentDeliveries.isNotEmpty) ...[
                      Column(
                        children: currentDeliveries.map((item) {
                          return _buildDeliveryCard(context, item, isCurrent: true);
                        }).toList(),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: AppColors.primary,
                                size: 22,
                              ),
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
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'No active deliveries right now. Please start ordering anytime below!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // 4. Recent Deliveries Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Deliveries',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DeliveryHistoryScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 5. Recent Deliveries Cards List
                    if (recentDeliveries.isNotEmpty) ...[
                      Column(
                        children: recentDeliveries.map((item) {
                          return _buildDeliveryCard(context, item, isCurrent: false);
                        }).toList(),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Text(
                          'No past deliveries yet.',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
