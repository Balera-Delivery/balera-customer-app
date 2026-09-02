import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/status_badge.dart';
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

  void _openTrackOrder(BuildContext context) {
    final deliveryProvider = context.read<DeliveryProvider>();
    final activeDelivery = deliveryProvider.activeDelivery;

    if (activeDelivery != null && AppConstants.isOngoing(activeDelivery.status)) {
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
      _showTrackByCodeDialog(context);
    }
  }

  void _showTrackByCodeDialog(BuildContext context) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.track_changes_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Track Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your tracking code or delivery ID to check live status:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: 'e.g. BAL-00126 or delivery ID',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeliveryTrackingScreen(deliveryId: code),
                ),
              );
            },
            child: const Text('Track', style: TextStyle(color: Colors.white)),
          ),
        ],
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

    final isArrived = activeDelivery != null &&
        (activeDelivery.status == AppConstants.statusArrivedAtPickup ||
            activeDelivery.status == 'ARRIVED' ||
            activeDelivery.status == AppConstants.statusPickedUp ||
            activeDelivery.status == AppConstants.statusOnTheWay);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 26),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // Track Order Button beside Notification (Clean & Accessible)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: InkWell(
              onTap: () => _openTrackOrder(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.track_changes_rounded, size: 16, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Track Order',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clean Header Greeting
              Text(
                'Hello, $userName 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Where would you like to send your package today?',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 18),

              // Simple Primary Action: Request a Delivery
              CustomButton(
                text: 'Request a Delivery',
                height: 50,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateDeliveryScreen()),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Rider Arrived & Delivery OTP Box (Direct, simple, and prominent)
              if (isArrived) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
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

              // Current Order Section
              const Text(
                'Current Order',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              if (activeDelivery != null && AppConstants.isOngoing(activeDelivery.status)) ...[
                // Clean Active Delivery Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${activeDelivery.trackingCode ?? activeDelivery.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          StatusBadge(status: activeDelivery.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        activeDelivery.pickupLocation,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeDelivery.destination,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      CustomButton(
                        text: activeDelivery.status == AppConstants.statusPending
                            ? 'Waiting for Rider Assignment'
                            : 'Track Live Status',
                        height: 42,
                        onPressed: () => _openTrackOrder(context),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Clean Empty State
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No active order',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Your ongoing delivery will appear here.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 24),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Recent Deliveries Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Deliveries',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DeliveryHistoryScreen()),
                      );
                    },
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Simple Recent Delivery Card
              if (deliveryProvider.deliveries.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final recentItem = deliveryProvider.completedDeliveries.isNotEmpty
                        ? deliveryProvider.completedDeliveries.first
                        : deliveryProvider.deliveries.first;
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DeliveryDetailsScreen(delivery: recentItem)),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '#${recentItem.trackingCode ?? recentItem.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                StatusBadge(status: recentItem.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              recentItem.pickupLocation,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              recentItem.destination,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }
}
