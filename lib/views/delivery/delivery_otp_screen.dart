import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/delivery_provider.dart';
import 'delivery_completed_screen.dart';

class DeliveryOtpScreen extends StatefulWidget {
  final String deliveryId;
  final String? otpCode;

  const DeliveryOtpScreen({
    super.key,
    this.deliveryId = 'DLV-00126',
    this.otpCode,
  });

  @override
  State<DeliveryOtpScreen> createState() => _DeliveryOtpScreenState();
}

class _DeliveryOtpScreenState extends State<DeliveryOtpScreen> {
  String? _loadedOtp;

  @override
  void initState() {
    super.initState();
    _loadedOtp = widget.otpCode;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<DeliveryProvider>();
      final otp = await provider.fetchDeliveryOtp(widget.deliveryId);
      if (mounted && otp != null && otp.isNotEmpty) {
        setState(() {
          _loadedOtp = otp;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();
    final displayOtp = _loadedOtp ?? provider.currentOtp ?? provider.activeDelivery?.otpCode ?? '482913';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '#${widget.deliveryId}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Shield Icon (Screen 15)
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 46,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Delivery Verification Code',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 32),

              // Giant OTP Code Display (Screen 15)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  displayOtp,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 8,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Give this OTP to the rider\nonly after you receive\nyour package.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // Coral Warning Box (Screen 15)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Text(
                  'Do not share this code before receiving the package.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),

              const Spacer(),

              // Primary Action: Confirm Handover & Complete Delivery
              CustomButton(
                text: 'I Gave OTP to Rider - Complete',
                onPressed: () async {
                  final provider = context.read<DeliveryProvider>();
                  provider.updateActiveStatus(AppConstants.statusCompleted);
                  await provider.fetchDeliveries();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeliveryCompletedScreen(deliveryId: widget.deliveryId),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 12),

              // Copy OTP Button
              CustomButton(
                text: 'Copy OTP Code',
                type: ButtonType.outlined,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: displayOtp));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('OTP copied to clipboard!'),
                      backgroundColor: AppColors.success,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
