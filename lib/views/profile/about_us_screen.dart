import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/balera_logo.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              const BaleraLogo(size: 150),
              const SizedBox(height: 24),
              const Text(
                'Balerra Delivery Management Platform',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Version 1.0.0 (August 2026)',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              const Text(
                'Balerra Delivery provides fast, reliable, and secure point-to-point courier delivery services. Our platform connects customers, dedicated riders, and dispatch controllers to ensure timely pickups, live tracking, and verified handovers with OTP security.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: const [
                    Text('From Bale. Delivered Smart.', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    SizedBox(height: 4),
                    Text('Balee Irraa. Sirnaan Geessina.', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E40AF))),
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
