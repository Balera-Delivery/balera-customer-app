import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import '../main/main_navigation_screen.dart';
import 'rider_assigned_screen.dart';

class WaitingForRiderScreen extends StatefulWidget {
  final String deliveryId;
  final String? trackingCode;

  const WaitingForRiderScreen({
    super.key,
    required this.deliveryId,
    this.trackingCode,
  });

  @override
  State<WaitingForRiderScreen> createState() => _WaitingForRiderScreenState();
}

class _WaitingForRiderScreenState extends State<WaitingForRiderScreen> {
  Timer? _pollTimer;
  bool _isChecking = false;
  DeliveryModel? _delivery;
  DateTime _lastCheckedTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startAdaptivePolling();
  }

  void _startAdaptivePolling() async {
    await _checkStatus(isManual: false);
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    _pollTimer?.cancel();
    if (!mounted) return;
    _pollTimer = Timer(const Duration(seconds: 8), () async {
      if (!mounted) return;
      await _checkStatus(isManual: false);
      _scheduleNextPoll();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  Future<void> _checkStatus({bool isManual = false}) async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
    });

    try {
      final provider = context.read<DeliveryProvider>();
      final res = await provider.deliveryService.getDeliveryDetails(widget.deliveryId);
      if (isManual) {
        await provider.fetchDeliveries();
      }

      if (mounted) {
        setState(() {
          _lastCheckedTime = DateTime.now();
        });

        if (res.success && res.data != null) {
          final fetched = res.data!;
          setState(() {
            _delivery = fetched;
          });

          // Check if admin has assigned a rider
          final hasRider = fetched.rider != null ||
              fetched.status == AppConstants.statusAssigned ||
              fetched.status == AppConstants.statusAccepted ||
              fetched.status == AppConstants.statusOnTheWay ||
              fetched.status == AppConstants.statusPickedUp;

          if (hasRider) {
            _pollTimer?.cancel();
            provider.setActiveDelivery(fetched);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Rider assigned: ${fetched.rider?.fullName ?? "Your Rider"}!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RiderAssignedScreen(delivery: fetched),
              ),
            );
            return;
          }

          if (fetched.status == AppConstants.statusCancelled) {
            _pollTimer?.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This delivery has been cancelled.'),
                backgroundColor: AppColors.error,
              ),
            );
            Navigator.pop(context);
            return;
          }

          if (isManual) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Status refreshed at ${_formatTime(_lastCheckedTime)}: Still waiting for admin assignment.'),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else if (isManual) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status checked: Waiting for admin assignment.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      if (isManual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not reach server. Will retry automatically.'),
            backgroundColor: AppColors.textMuted,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel this delivery request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, Keep Waiting'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              _pollTimer?.cancel();
              final success = await context.read<DeliveryProvider>().cancelDelivery(
                    widget.deliveryId,
                    reason: 'Cancelled by customer while waiting for rider',
                  );
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delivery request cancelled.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                    (route) => false,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to cancel delivery request.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();
    final active = _delivery ?? provider.activeDelivery;
    final displayCode = widget.trackingCode ?? active?.trackingCode ?? widget.deliveryId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '#$displayCode',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: _isChecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Status',
            onPressed: () => _checkStatus(isManual: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Steady Clean Top Icon (No spinning at the top!)
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                ),
                child: const Icon(
                  Icons.assignment_ind_outlined,
                  size: 42,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Waiting for Rider Assignment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your request has been submitted. The admin dispatch team is currently reviewing and assigning an available rider.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // Real Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#$displayCode',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        StatusBadge(status: active?.status ?? AppConstants.statusPending),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFE2E8F0)),
                    if (active?.pickupLocation != null && active!.pickupLocation.isNotEmpty) ...[
                      _buildSummaryRow(Icons.radio_button_checked, 'Pickup', active.pickupLocation, Colors.blue),
                      const SizedBox(height: 10),
                    ],
                    if (active?.destination != null && active!.destination.isNotEmpty) ...[
                      _buildSummaryRow(Icons.location_on_rounded, 'Destination', active.destination, Colors.green),
                      const SizedBox(height: 10),
                    ],
                    if (active?.itemDescription != null && active!.itemDescription.isNotEmpty) ...[
                      _buildSummaryRow(Icons.inventory_2_outlined, 'Item', active.itemDescription, AppColors.primary),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Timeline Steps (Reload animation ONLY on Step 2: Admin Review & Assignment)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildStepRow('1. Request Submitted', isDone: true, isCurrent: false),
                    _buildStepLine(isPassed: true),
                    _buildStepRow('2. Admin Review & Assignment', isDone: false, isCurrent: true), // Reload spinner only here!
                    _buildStepLine(isPassed: false),
                    _buildStepRow('3. Rider Assigned', isDone: false, isCurrent: false),
                    _buildStepLine(isPassed: false),
                    _buildStepRow('4. Pickup & Delivery', isDone: false, isCurrent: false),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Last checked timestamp feedback
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sync_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Last checked: ${_formatTime(_lastCheckedTime)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Check Status Button
              CustomButton(
                text: _isChecking ? 'Checking Status...' : 'Check Status Now',
                isLoading: _isChecking,
                onPressed: () => _checkStatus(isManual: true),
              ),

              const SizedBox(height: 12),

              // Return to Home Button
              CustomButton(
                text: 'Return to Home',
                type: ButtonType.outlined,
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 16),

              // Cancel Request Link
              TextButton(
                onPressed: _confirmCancel,
                child: const Text(
                  'Cancel Delivery Request',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepRow(String title, {required bool isDone, required bool isCurrent}) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? AppColors.success
                : (isCurrent ? AppColors.primary : Colors.white),
            border: Border.all(
              color: isDone
                  ? AppColors.success
                  : (isCurrent ? AppColors.primary : const Color(0xFFCBD5E1)),
              width: 2,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : (isCurrent
                    ? const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                      )
                    : null),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isCurrent ? FontWeight.w700 : (isDone ? FontWeight.w600 : FontWeight.w400),
            color: (isDone || isCurrent) ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine({required bool isPassed}) {
    return Container(
      margin: const EdgeInsets.only(left: 10),
      alignment: Alignment.centerLeft,
      height: 20,
      width: 2,
      color: isPassed ? AppColors.success : const Color(0xFFE2E8F0),
    );
  }
}
