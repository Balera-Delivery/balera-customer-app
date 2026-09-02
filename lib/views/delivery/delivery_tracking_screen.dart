import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import 'delivery_completed_screen.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final String? deliveryId;
  final DeliveryModel? initialDelivery;

  const DeliveryTrackingScreen({
    super.key,
    this.deliveryId,
    this.initialDelivery,
  });

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  DeliveryModel? _delivery;
  Timer? _pollTimer;
  bool _isChecking = false;
  DateTime _lastCheckedTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _delivery = widget.initialDelivery;
    _startAdaptivePolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startAdaptivePolling() async {
    await _checkStatus(isManual: false);
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    _pollTimer?.cancel();
    if (!mounted) return;
    _pollTimer = Timer(const Duration(seconds: 7), () async {
      if (!mounted) return;
      await _checkStatus(isManual: false);
      _scheduleNextPoll();
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  Future<void> _checkStatus({bool isManual = false}) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final provider = context.read<DeliveryProvider>();
      final targetId = widget.deliveryId ?? _delivery?.id ?? provider.activeDelivery?.id;

      if (targetId != null && targetId.isNotEmpty) {
        final res = await provider.deliveryService.getDeliveryDetails(targetId);
        if (isManual) {
          await provider.fetchDeliveries();
        }

        if (mounted) {
          setState(() {
            _lastCheckedTime = DateTime.now();
          });

          if (res.success && res.data != null) {
            setState(() {
              _delivery = res.data!;
            });
            provider.setActiveDelivery(res.data!);

            if (isManual) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Status updated (${AppConstants.formatStatus(res.data!.status)}) at ${_formatTime(_lastCheckedTime)}'),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        }
      }
    } catch (_) {
      // Gracefully ignore network glitches
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  void _callRider(String phoneNumber) {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');
    Clipboard.setData(ClipboardData(text: cleanPhone));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rider phone ($cleanPhone) copied to clipboard!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  int _getStageIndex(String status) {
    final upper = status.toUpperCase().replaceAll('-', '_');
    switch (upper) {
      case 'PENDING':
        return 1; // Step 2 (Admin Review) is in progress
      case 'ASSIGNED':
      case 'ACCEPTED':
        return 2; // Step 3 (Rider Heading to Pickup) is in progress
      case 'ARRIVED_AT_PICKUP':
      case 'ARRIVED':
        return 3; // Step 4 (Rider Arrived - OTP Active!)
      case 'PICKED_UP':
      case 'ON_THE_WAY':
        return 4; // Step 5 (Package Picked Up & On the way)
      case 'DELIVERED':
      case 'COMPLETED':
        return 5; // Step 6 (Delivered & Completed)
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();
    final active = _delivery ?? provider.activeDelivery;

    if (active == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Track Order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('No active delivery found to track.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final currentStage = _getStageIndex(active.status);
    final isArrived = currentStage == 3;
    final isCompleted = currentStage == 5;
    final rider = active.rider;
    final displayCode = (active.trackingCode != null && active.trackingCode!.isNotEmpty)
        ? active.trackingCode!
        : active.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Track Order #$displayCode',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Status',
            icon: _isChecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => _checkStatus(isManual: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card: Tracking Code & Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Order Status',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '#$displayCode',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        StatusBadge(status: active.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Last checked: ${_formatTime(_lastCheckedTime)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        InkWell(
                          onTap: () => _checkStatus(isManual: true),
                          child: const Text(
                            'Check Now',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // MAIN ACTION & ARRIVAL OTP CARD (When Rider Arrives or Active Handover)
              if (isArrived || active.status == AppConstants.statusArrivedAtPickup || active.status == 'ARRIVED') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF86EFAC), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Rider Has Arrived!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Please give this 6-digit OTP code to the rider to confirm handover:',
                        style: TextStyle(fontSize: 13, color: Color(0xFF166534), height: 1.3),
                      ),
                      const SizedBox(height: 14),

                      // Giant OTP Display Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              active.otpCode ?? '482913',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 6,
                                color: AppColors.primary,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Copy OTP',
                              icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 22),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: active.otpCode ?? '482913'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('OTP copied to clipboard!'),
                                    backgroundColor: AppColors.success,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // THE MAIN ACTION BUTTON
                      CustomButton(
                        text: 'I Gave OTP to Rider - Complete',
                        onPressed: () async {
                          provider.updateActiveStatus(AppConstants.statusCompleted);
                          await provider.fetchDeliveries();
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DeliveryCompletedScreen(deliveryId: displayCode),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Rider Card (if assigned)
              if (rider != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFDBEAFE),
                        child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Assigned Rider',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            Text(
                              rider.fullName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            if (rider.vehicleInfo != null && rider.vehicleInfo!.isNotEmpty)
                              Text(
                                rider.vehicleInfo!,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFFEFF6FF)),
                        icon: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 22),
                        onPressed: () => _callRider(rider.phoneNumber),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Step-by-Step Status Flow (Vertical Timeline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Flow Steps',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildTimelineStep(
                      stepNumber: 1,
                      title: 'Order Submitted',
                      subtitle: 'Delivery request created and logged in the system.',
                      isCompleted: true,
                      isActive: false,
                    ),
                    _buildTimelineStep(
                      stepNumber: 2,
                      title: 'Admin Review & Assignment',
                      subtitle: rider != null
                          ? 'Rider assigned by dispatch admin.'
                          : 'Admin is reviewing and assigning an available rider.',
                      isCompleted: currentStage > 1,
                      isActive: currentStage == 1,
                      isLoading: currentStage == 1,
                    ),
                    _buildTimelineStep(
                      stepNumber: 3,
                      title: 'Rider Heading to Pickup',
                      subtitle: rider != null
                          ? '${rider.fullName} is on the way to your pickup location.'
                          : 'Waiting for rider to start heading to pickup.',
                      isCompleted: currentStage > 2,
                      isActive: currentStage == 2,
                    ),
                    _buildTimelineStep(
                      stepNumber: 4,
                      title: 'Rider Arrived at Pickup',
                      subtitle: isArrived
                          ? 'Rider is here! Give the OTP code to complete handover.'
                          : 'Rider arrives and requests your 6-digit OTP code.',
                      isCompleted: currentStage > 3,
                      isActive: currentStage == 3,
                      highlightGreen: isArrived,
                    ),
                    _buildTimelineStep(
                      stepNumber: 5,
                      title: 'Package Picked Up & On the Way',
                      subtitle: 'Package verified and en route to the destination.',
                      isCompleted: currentStage > 4,
                      isActive: currentStage == 4,
                    ),
                    _buildTimelineStep(
                      stepNumber: 6,
                      title: 'Delivered & Completed',
                      subtitle: isCompleted
                          ? 'Package safely delivered to receiver.'
                          : 'Final package handover to receiver.',
                      isCompleted: currentStage == 5,
                      isActive: currentStage == 5,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Route & Package Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Locations',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle, color: AppColors.primary, size: 14),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pickup Location', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              Text(active.pickupLocation, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: SizedBox(height: 18, child: VerticalDivider(color: Color(0xFFCBD5E1), thickness: 1.5)),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Destination', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              Text(active.destination, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    bool isLoading = false,
    bool highlightGreen = false,
    bool isLast = false,
  }) {
    Color bgColor;
    Widget iconWidget;

    if (isCompleted) {
      bgColor = AppColors.success;
      iconWidget = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (isActive) {
      if (highlightGreen) {
        bgColor = AppColors.success;
        iconWidget = const Icon(Icons.directions_bike_rounded, size: 14, color: Colors.white);
      } else if (isLoading) {
        bgColor = const Color(0xFFEFF6FF);
        iconWidget = const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        );
      } else {
        bgColor = AppColors.primary;
        iconWidget = Text(
          '$stepNumber',
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        );
      }
    } else {
      bgColor = const Color(0xFFF1F5F9);
      iconWidget = Text(
        '$stepNumber',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.success
                      : (isActive ? AppColors.primary : const Color(0xFFE2E8F0)),
                  width: 1.5,
                ),
              ),
              child: Center(child: iconWidget),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isCompleted ? AppColors.success : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive || isCompleted ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? (highlightGreen ? const Color(0xFF15803D) : AppColors.primary)
                        : (isCompleted ? AppColors.textPrimary : AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
