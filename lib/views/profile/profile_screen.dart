import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../splash/splash_screen.dart';
import 'about_us_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

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
            // Fixed in place top header
            _buildTopHeader(context, user),

            // Scrollable body content below fixed header
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group 1: Account Settings Card
                    _buildSectionTitle('ACCOUNT SETTINGS'),
                    const SizedBox(height: 8),
                    _buildCardContainer([
                      _buildCardMenuItem(
                        icon: Icons.person_outline_rounded,
                        iconColor: const Color(0xFF0052EA),
                        iconBg: const Color(0xFFEFF6FF),
                        title: 'Edit Profile',
                        subtitle: 'Update your name, phone and address',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 72),
                      _buildCardMenuItem(
                        icon: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFFD97706),
                        iconBg: const Color(0xFFFEF3C7),
                        title: 'Change Password',
                        subtitle: 'Manage and update your account password',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 72),
                      _buildCardMenuItem(
                        icon: Icons.notifications_none_rounded,
                        iconColor: const Color(0xFF16A34A),
                        iconBg: const Color(0xFFDCFCE7),
                        title: 'Notification Settings',
                        subtitle: 'Order updates, rider arrival and sound alerts',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                          );
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Group 2: Support & Information Card
                    _buildSectionTitle('SUPPORT & INFORMATION'),
                    const SizedBox(height: 8),
                    _buildCardContainer([
                      _buildCardMenuItem(
                        icon: Icons.headset_mic_outlined,
                        iconColor: const Color(0xFF0284C7),
                        iconBg: const Color(0xFFE0F2FE),
                        title: 'Help & Customer Support',
                        subtitle: 'Contact the Balera hotline and read the FAQ',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 72),
                      _buildCardMenuItem(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFF7C3AED),
                        iconBg: const Color(0xFFEDE9FE),
                        title: 'About Balera Delivery',
                        subtitle: 'Our services across Bale Robe and beyond',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                          );
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Group 3: Logout Card
                    _buildCardContainer([
                      InkWell(
                        onTap: () => _confirmLogout(context, authProvider),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.logout_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Log Out',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Sign out of this device safely',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Color(0xFFDC2626),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 28),

                    // App Version Footer
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'Balera Delivery v1.0.0',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'From Bale. Delivered Smart.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom clearance for floating bottom bar
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, dynamic user) {
    final topPadding = MediaQuery.of(context).padding.top;
    final displayName = (user?.fullName != null && user!.fullName.toString().trim().isNotEmpty)
        ? user!.fullName.toString().trim()
        : 'fayo';
    final displayPhone = (user?.phoneNumber != null && user!.phoneNumber.toString().trim().isNotEmpty)
        ? user!.phoneNumber.toString().trim()
        : '09XX XXX XXX';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 14,
        left: 20,
        right: 20,
        bottom: 26,
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
          const Text(
            'Settings & Profile',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with solid white ring
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E67FF),
                  border: Border.all(color: Colors.white, width: 2.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 38,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          size: 19,
                          color: Color(0xFF00E5FF),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      displayPhone,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Verified Customer',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildCardMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: const Text('Are you sure you want to log out of Balera Delivery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

