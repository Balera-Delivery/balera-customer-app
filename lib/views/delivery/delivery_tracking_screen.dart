import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/mock_map_view.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import 'delivery_completed_screen.dart';
import 'live_tracking_screen.dart';

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
  bool _hasShownCompletionDialog = false;

  void _checkAndShowCompletionDialog(String status) {
    if ((status.toUpperCase() == 'COMPLETED' || status == AppConstants.statusCompleted) && !_hasShownCompletionDialog && mounted) {
      _hasShownCompletionDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 8,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
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
                          size: 44,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Delivery Completed! 🎉',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Delivery completed, thankyou for choosing us keep in touch',
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext);
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
            );
          },
        );
      });
    }
  }
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
            _checkAndShowCompletionDialog(res.data!.status);

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
        return 1;
      case 'ASSIGNED':
      case 'ACCEPTED':
        return 2;
      case 'ARRIVED_AT_PICKUP':
      case 'PICKED_UP':
        return 3;
      case 'ON_THE_WAY':
        return 4;
      case 'DELIVERED':
      case 'ARRIVED':
        return 5;
      case 'COMPLETED':
        return 6;
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
    final isArrived = currentStage == 5 || active.status == "DELIVERED" || active.status == "ARRIVED";
    final isCompleted = currentStage == 6 || active.status.toUpperCase() == "COMPLETED";
    if (isCompleted) {
      _checkAndShowCompletionDialog(active.status);
    }
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
              if (isArrived) ...[
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
                      title: 'Admin Review & Rider Assignment',
                      subtitle: rider != null
                          ? '${rider.fullName} assigned by dispatch admin.'
                          : 'Admin is reviewing and assigning an online rider.',
                      isCompleted: currentStage > 1,
                      isActive: currentStage == 1,
                    ),
                    _buildTimelineStep(
                      stepNumber: 3,
                      title: 'Item Picked Up',
                      subtitle: currentStage >= 3
                          ? 'Item picked up and verified from pickup location.'
                          : 'Rider is heading to pickup the package.',
                      isCompleted: currentStage >= 3,
                      isActive: currentStage == 2,
                    ),
                    _buildTimelineStep(
                      stepNumber: 4,
                      title: 'On The Way to Destination',
                      subtitle: currentStage >= 4
                          ? 'Rider is en route to your drop-off address.'
                          : 'Awaiting package pickup completion.',
                      isCompleted: currentStage >= 4,
                      isActive: currentStage == 3,
                    ),
                    _buildTimelineStep(
                      stepNumber: 5,
                      title: 'Rider Arrived at Destination',
                      subtitle: isArrived
                          ? 'Rider has arrived outside! Share your 6-digit OTP code.'
                          : 'Rider arrives and requests your verification OTP.',
                      isCompleted: currentStage >= 6,
                      isActive: currentStage == 4 || currentStage == 5,
                      highlightGreen: isArrived,
                    ),
                    _buildTimelineStep(
                      stepNumber: 6,
                      title: 'Delivered & Completed',
                      subtitle: isCompleted
                          ? 'Package safely delivered and verified via OTP! 🎉'
                          : 'Final handover upon OTP confirmation.',
                      isCompleted: isCompleted,
                      isActive: false,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Live Map Tracking Card Under Flow Steps
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.map_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Live Map Tracking',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.radar_rounded, size: 12, color: Color(0xFF16A34A)),
                              SizedBox(width: 4),
                              Text(
                                'Live GPS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Live route and rider location from pickup to destination',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    // Embedded Interactive Map Container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            MockMapView(
                              pickupAddress: active.pickupLocation,
                              destinationAddress: active.destination,
                              showRoute: true,
                              showRider: currentStage >= 2 && currentStage < 5,
                              height: 220,
                            ),

                            // Top Left Live ETA / Distance Badge
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      currentStage >= 4
                                          ? 'Arriving in ~6 mins'
                                          : (currentStage >= 2
                                              ? 'Heading to pickup ~8 mins'
                                              : 'Awaiting rider assignment'),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Top Right Fullscreen Expand Action
                            Positioned(
                              top: 10,
                              right: 10,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LiveTrackingScreen(delivery: active),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.fullscreen_rounded, size: 16, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'Full Map',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
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
    bool highlightGreen = false,
    bool isLast = false,
  }) {
    Color bgColor;
    Widget iconWidget;

    if (isCompleted) {
      bgColor = AppColors.success;
      iconWidget = const Icon(Icons.check, size: 15, color: Colors.white);
    } else if (isActive) {
      bgColor = const Color(0xFFEFF6FF);
      iconWidget = Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          Text(
            '$stepNumber',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
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
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.success
                      : (isActive ? Colors.transparent : const Color(0xFFE2E8F0)),
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
