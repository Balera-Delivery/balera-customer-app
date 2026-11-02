import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/delivery_provider.dart';
import 'delivery_completed_screen.dart';

class DeliveryOtpScreen extends StatefulWidget {
  final String deliveryId;
  final String? otpCode;
  final String? qrCodeToken;

  const DeliveryOtpScreen({
    super.key,
    this.deliveryId = 'DLV-00126',
    this.otpCode,
    this.qrCodeToken,
  });

  @override
  State<DeliveryOtpScreen> createState() => _DeliveryOtpScreenState();
}

class _DeliveryOtpScreenState extends State<DeliveryOtpScreen> {
  String? _loadedOtp;
  bool _showOtpInstead = false;
  Timer? _pollTimer;
  bool _isCheckingCompletion = false;
  bool _hasNavigatedToCompleted = false;

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
    _startAdaptivePolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startAdaptivePolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || _hasNavigatedToCompleted) return;
      await _checkRiderStatus(silent: true);
    });
  }

  Future<void> _checkRiderStatus({bool silent = false}) async {
    try {
      final provider = context.read<DeliveryProvider>();
      final res = await provider.deliveryService.getDeliveryDetails(widget.deliveryId);
      if (res.success && res.data != null) {
        final status = res.data!.status.toUpperCase();
        if (status == 'COMPLETED') {
          _pollTimer?.cancel();
          _onRiderVerifiedAndCompleted();
        }
      }
    } catch (_) {}
  }

  void _onRiderVerifiedAndCompleted() {
    if (_hasNavigatedToCompleted || !mounted) return;
    _hasNavigatedToCompleted = true;
    final provider = context.read<DeliveryProvider>();
    provider.updateActiveStatus(AppConstants.statusCompleted);
    provider.fetchDeliveries();

    _showDeliveryCompletedPopup();
  }

  Future<void> _handleCompleteButtonClick(String displayOtp) async {
    if (_isCheckingCompletion) return;
    setState(() => _isCheckingCompletion = true);

    try {
      final provider = context.read<DeliveryProvider>();
      final res = await provider.deliveryService.getDeliveryDetails(widget.deliveryId);
      final currentStatus = (res.data?.status ?? '').toUpperCase();

      if (mounted) {
        setState(() => _isCheckingCompletion = false);
        if (currentStatus == 'COMPLETED') {
          _onRiderVerifiedAndCompleted();
        } else {
          _showWaitingForRiderOtpDialog(displayOtp);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingCompletion = false);
        _showWaitingForRiderOtpDialog(displayOtp);
      }
    }
  }

  void _showWaitingForRiderOtpDialog(String otp) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_clock_rounded,
                    color: Color(0xFFD97706),
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Waiting for Rider to Verify OTP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'You cannot complete the delivery yet. Please share your 6-digit OTP code below with the rider. The rider must enter and confirm it in their app to finish the delivery.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Delivery OTP',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                        ),
                        Text(
                          otp,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: otp));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('OTP copied to clipboard!'),
                            backgroundColor: AppColors.primary,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        _checkRiderStatus();
                      },
                      child: const Text('Check Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeliveryCompletedPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF86EFAC), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Delivery Completed! 🎉',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Your package has been successfully delivered and confirmed by rider. Thank you for choosing Balera!',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();
    final active = provider.activeDelivery;
    final displayOtp = _loadedOtp ?? provider.currentOtp ?? active?.otpCode ?? '482913';
    final displayQr = widget.qrCodeToken ?? active?.qrCodeToken ?? 'BALERA-${widget.deliveryId}-$displayOtp';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Delivery Verification',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Segmented Toggle between QR (Primary) and OTP (Secondary)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _showOtpInstead = false),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_showOtpInstead ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_showOtpInstead
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                size: 18,
                                color: !_showOtpInstead ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'QR Code (Primary)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: !_showOtpInstead ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _showOtpInstead = true),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _showOtpInstead ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _showOtpInstead
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pin_outlined,
                                size: 18,
                                color: _showOtpInstead ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'OTP Code',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _showOtpInstead ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (!_showOtpInstead) ...[
                // 1. PRIMARY VERIFICATION: QR CODE DISPLAY
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: displayQr,
                        version: QrVersions.auto,
                        size: 210.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.primary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Delivery #${widget.deliveryId}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Show this QR code to the rider\nto scan and confirm package delivery.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                TextButton.icon(
                  icon: const Icon(Icons.key_rounded, size: 18, color: AppColors.primary),
                  label: const Text(
                    'Rider camera not working? Use OTP code instead',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  onPressed: () => setState(() => _showOtpInstead = true),
                ),
              ] else ...[
                // 2. SECONDARY OPTION: 6-DIGIT OTP CODE
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    size: 42,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'One-Time Verification Password (OTP)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    displayOtp,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 8,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Tell this 6-digit code to the rider\nafter you have received your package.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                TextButton.icon(
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18, color: AppColors.primary),
                  label: const Text(
                    'Switch back to QR Code display',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  onPressed: () => setState(() => _showOtpInstead = false),
                ),
              ],

              const SizedBox(height: 16),

              // Coral Warning Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Text(
                  'Do not verify before physically receiving and inspecting your package.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Primary Action: Confirm Handover & Complete Delivery
              CustomButton(
                text: 'Package Received - Done',
                isLoading: _isCheckingCompletion,
                onPressed: () => _handleCompleteButtonClick(displayOtp),
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
