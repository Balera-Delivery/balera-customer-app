import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _deliveryUpdates = true;
  bool _riderArrival = true;
  bool _soundEnabled = true;
  bool _promotions = false;
  bool _smsUpdates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            // Section 1: Order & Delivery Tracking
            _buildSectionHeader('ORDER & DISPATCH ALERTS'),
            _buildCardGroup([
              _buildSettingTile(
                icon: Icons.local_shipping_outlined,
                iconColor: AppColors.primary,
                iconBg: const Color(0xFFEFF6FF),
                title: 'Delivery Status Updates',
                subtitle: 'Real-time alerts when your order status changes (Picked up, On the way)',
                value: _deliveryUpdates,
                onChanged: (val) => setState(() => _deliveryUpdates = val),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),
              _buildSettingTile(
                icon: Icons.two_wheeler_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBg: const Color(0xFFDCFCE7),
                title: 'Rider Arrival Alerts',
                subtitle: 'Immediate alert and OTP reminder when rider arrives at your doorstep',
                value: _riderArrival,
                onChanged: (val) => setState(() => _riderArrival = val),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),
              _buildSettingTile(
                icon: Icons.sms_outlined,
                iconColor: const Color(0xFF0284C7),
                iconBg: const Color(0xFFE0F2FE),
                title: 'SMS Backup Notifications',
                subtitle: 'Receive delivery updates and OTP via SMS if app is closed or offline',
                value: _smsUpdates,
                onChanged: (val) => setState(() => _smsUpdates = val),
              ),
            ]),

            const SizedBox(height: 24),

            // Section 2: Sound & Vibration
            _buildSectionHeader('DEVICE & SOUND PREFERENCES'),
            _buildCardGroup([
              _buildSettingTile(
                icon: Icons.volume_up_outlined,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
                title: 'Alert Sounds & Vibration',
                subtitle: 'Play distinctive audio tones for critical order arrival and OTP alerts',
                value: _soundEnabled,
                onChanged: (val) => setState(() => _soundEnabled = val),
              ),
            ]),

            const SizedBox(height: 24),

            // Section 3: Promotions & Marketing
            _buildSectionHeader('SPECIAL OFFERS & ANNOUNCEMENTS'),
            _buildCardGroup([
              _buildSettingTile(
                icon: Icons.local_offer_outlined,
                iconColor: const Color(0xFF9333EA),
                iconBg: const Color(0xFFF3E8FF),
                title: 'Discounts & Promotions',
                subtitle: 'Exclusive restaurant coupons, holiday offers, and seasonal discounts',
                value: _promotions,
                onChanged: (val) => setState(() => _promotions = val),
              ),
            ]),

            const SizedBox(height: 32),

            // Info note card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Settings are saved automatically. You can also customize system permissions directly in Android App Settings.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
