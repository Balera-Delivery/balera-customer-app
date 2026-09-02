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
  bool _promotions = false;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SwitchListTile(
              title: const Text('Delivery Status Updates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Receive notifications when your order progress changes', style: TextStyle(fontSize: 12)),
              value: _deliveryUpdates,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _deliveryUpdates = val),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Rider Arrival Alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Get notified immediately when your rider arrives', style: TextStyle(fontSize: 12)),
              value: _riderArrival,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _riderArrival = val),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Notification Sound & Vibrate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Play sound for high priority OTP and arrival alerts', style: TextStyle(fontSize: 12)),
              value: _soundEnabled,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _soundEnabled = val),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Promotions & Announcements', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Receive special discounts and platform updates', style: TextStyle(fontSize: 12)),
              value: _promotions,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _promotions = val),
            ),
          ],
        ),
      ),
    );
  }
}
