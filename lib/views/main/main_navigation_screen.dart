import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/storage_service.dart';
import '../delivery/create_delivery_screen.dart';
import '../history/delivery_history_screen.dart';
import '../home/home_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int? initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  final List<Widget> _screens = const [
    HomeScreen(),
    DeliveryHistoryScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Continuous subtle breathing pulse & glowing animation for center action button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 6.0, end: 16.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    final savedIndex = StorageService.getLastNavIndex();
    _currentIndex = widget.initialIndex ?? savedIndex;
    if (_currentIndex < 0 || _currentIndex >= _screens.length) {
      _currentIndex = 0;
    }
    StorageService.saveLastNavIndex(_currentIndex);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
      StorageService.saveLastNavIndex(index);
      if (index == 0) {
        context.read<DeliveryProvider>().fetchDeliveries();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final unreadCount = notificationProvider.unreadCount;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 10.0),
          child: SizedBox(
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // 1. Bottom Capsule Bar with 4 Navigation Items
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 58,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF030D26).withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Home Tab
                        _buildCapsuleNavItem(
                          index: 0,
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          label: 'Home',
                          isSelected: _currentIndex == 0,
                          onTap: () => _onTabSelected(0),
                        ),

                        // 2. Orders Tab
                        _buildCapsuleNavItem(
                          index: 1,
                          icon: Icons.inventory_2_outlined,
                          activeIcon: Icons.inventory_2_rounded,
                          label: 'Orders',
                          isSelected: _currentIndex == 1,
                          onTap: () => _onTabSelected(1),
                        ),

                        // Center Gap reserved for elevated button
                        const SizedBox(width: 54),

                        // 3. Alerts Tab
                        _buildCapsuleNavItem(
                          index: 2,
                          icon: Icons.notifications_outlined,
                          activeIcon: Icons.notifications_rounded,
                          label: 'Alerts',
                          isSelected: _currentIndex == 2,
                          badgeCount: unreadCount,
                          onTap: () => _onTabSelected(2),
                        ),

                        // 4. Account Tab
                        _buildCapsuleNavItem(
                          index: 3,
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          label: 'Account',
                          isSelected: _currentIndex == 3,
                          onTap: () => _onTabSelected(3),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Elevated, Bold, Animated "Request Delivery" Center Button
                Positioned(
                  bottom: 12,
                  child: _buildCenterRequestDeliveryButton(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Elevated Bold Center "Request Delivery" Button with Breathing Pulse Glow
  // ---------------------------------------------------------------------------
  Widget _buildCenterRequestDeliveryButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Tooltip(
            message: 'Request Delivery',
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1D64EC),
                    Color(0xFF0D50DB),
                  ],
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 3.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D64EC).withValues(alpha: 0.38),
                    blurRadius: _glowAnimation.value,
                    spreadRadius: 1.5,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateDeliveryScreen(),
                      ),
                    );
                    if (context.mounted) {
                      context.read<DeliveryProvider>().fetchDeliveries();
                    }
                  },
                  borderRadius: BorderRadius.circular(27),
                  splashColor: Colors.white.withValues(alpha: 0.3),
                  highlightColor: Colors.white.withValues(alpha: 0.15),
                  child: const Center(
                    child: Icon(
                      Icons.local_shipping_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCapsuleNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              label: Text(
                '$badgeCount',
                style: const TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.error,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
