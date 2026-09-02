import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Privacy & Terms',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Last updated: August 2026',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'Balerra Delivery values your privacy and is committed to protecting your personal information. This Privacy Policy explains how we collect, use, and protect your information when you use our Customer Mobile Application.\n\n'
              '1. Information We Collect:\n'
              '• Account Information: Full name, phone number, optional email address.\n'
              '• Location Data: Pickup and destination addresses, GPS coordinates for accurate dispatch and tracking.\n'
              '• Delivery Details: Receiver contact info, package categories, and handling instructions.\n\n'
              '2. How We Use Information:\n'
              '• To process, dispatch, and track your delivery requests.\n'
              '• To authenticate users and maintain account security.\n'
              '• To send critical updates regarding rider assignment and delivery status.\n\n'
              '3. Security:\n'
              'We employ industry-standard encryption techniques (JWT, HTTPS, hashed passwords) to protect all customer and operational data.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Terms of Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'By using the Balerra Delivery app, you agree not to submit prohibited items, illegal substances, or hazardous materials. All deliveries require an OTP verification before handover completion.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
