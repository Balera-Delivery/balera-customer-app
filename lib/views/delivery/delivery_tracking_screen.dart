import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/real_google_map_view.dart';
import '../../models/delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../services/storage_service.dart';
import 'delivery_completed_screen.dart';
import 'delivery_details_screen.dart';
import 'live_tracking_screen.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  final String? deliveryId;
  final DeliveryModel? initialDelivery;
  final bool enablePolling;

  const DeliveryTrackingScreen({
    super.key,
    this.deliveryId,
    this.initialDelivery,
    this.enablePolling = true,
  });

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  DeliveryModel? _delivery;
  bool _hasShownCompletionDialog = false;
  Timer? _pollTimer;
  bool _isChecking = false;
  bool _isCheckingCompletion = false;
  DateTime _lastCheckedTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _delivery = widget.initialDelivery;
    if (widget.enablePolling) {
      _startAdaptivePolling();
    }
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

  void _callRider(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
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
  }

  void _messageRider(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');
    final uri = Uri.parse('sms:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
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
  }

  int _getStageIndex(String status) {
    final upper = status.toUpperCase().replaceAll('-', '_');
    switch (upper) {
      case 'PENDING':
        return 2; // Step 1 (Order submitted) is finished, Step 2 (Rider assigned) is in progress
      case 'ASSIGNED':
      case 'ACCEPTED':
      case 'ARRIVED_AT_PICKUP':
        return 3; // Steps 1 & 2 finished, Step 3 (Item picked up) is in progress
      case 'PICKED_UP':
      case 'ON_THE_WAY':
        return 4; // Steps 1, 2, 3 finished, Step 4 (On the way) is in progress
      case 'DELIVERED':
      case 'ARRIVED':
      case 'ARRIVED_AT_DROPOFF':
        return 5; // Steps 1, 2, 3, 4 finished, Step 5 (Rider arrived) is in progress
      case 'COMPLETED':
        return 6; // All 6 steps finished!
      default:
        return 2;
    }
  }

  String _getFlowStageName(int stage) {
    switch (stage) {
      case 6:
        return 'Delivered & complete';
      case 5:
        return 'Rider arrived';
      case 4:
        return 'On the way';
      case 3:
        return 'Item picked up';
      case 2:
        return 'Rider assigned';
      case 1:
      default:
        return 'Order submitted';
    }
  }

  void _checkAndShowCompletionDialog(String status) {
    if ((status.toUpperCase() == 'COMPLETED' || status == AppConstants.statusCompleted) && !_hasShownCompletionDialog && mounted) {
      _showDeliveryCompletedPopup(_delivery ?? context.read<DeliveryProvider>().activeDelivery);
    }
  }

  Future<void> _handleCompleteDeliveryClick(DeliveryModel active, DeliveryProvider provider) async {
    if (_isCheckingCompletion) return;
    setState(() => _isCheckingCompletion = true);

    try {
      final targetId = widget.deliveryId ?? active.id;
      // 1. Check live status from backend to verify if rider entered and verified the OTP
      final res = await provider.deliveryService.getDeliveryDetails(targetId);
      final liveDelivery = res.data;
      final currentStatus = (liveDelivery?.status ?? active.status).toUpperCase();

      final bool isRiderVerifiedAndCompleted = currentStatus == 'COMPLETED';

      if (mounted) {
        setState(() => _isCheckingCompletion = false);

        if (isRiderVerifiedAndCompleted) {
          // Rider verified OTP and completed!
          provider.updateActiveStatus(AppConstants.statusCompleted);
          await provider.fetchDeliveries();
          _showDeliveryCompletedPopup(liveDelivery ?? active);
        } else {
          // Rider has not verified OTP yet! Customer cannot complete before giving OTP
          _showWaitingForRiderOtpDialog(active.otpCode ?? '482913', active);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingCompletion = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not verify status: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showWaitingForRiderOtpDialog(String otp, DeliveryModel active) {
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
                        _checkStatus(isManual: true);
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

  void _showDeliveryCompletedPopup(DeliveryModel? delivery) {
    if (_hasShownCompletionDialog) return;
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

  void _showTrackingOptionsMenu(BuildContext context, DeliveryModel active) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                title: const Text('Refresh Status', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Poll current courier location & status'),
                onTap: () {
                  Navigator.pop(ctx);
                  _checkStatus(isManual: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.map_rounded, color: AppColors.primary),
                title: const Text('Fullscreen Live Map', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Expand interactive map to full screen'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LiveTrackingScreen(delivery: active)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                title: const Text('View Full Delivery Details', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Review package specifications and receipt'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DeliveryDetailsScreen(delivery: active)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: AppColors.primary),
                title: const Text('Copy Tracking Code', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: active.trackingCode ?? active.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tracking code copied to clipboard!')),
                  );
                },
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
    final isArrived = currentStage == 5 ||
        active.status == "DELIVERED" ||
        active.status == "ARRIVED" ||
        active.status == "ARRIVED_AT_DROPOFF";
    final isCompleted = currentStage == 6 || active.status.toUpperCase() == "COMPLETED";
    final isEnRouteOrArrived = (currentStage >= 4 || isArrived) && !isCompleted;
    if (isCompleted) {
      _checkAndShowCompletionDialog(active.status);
    }

    final rider = active.rider;
    final displayCode = (active.trackingCode != null && active.trackingCode!.isNotEmpty)
        ? active.trackingCode!
        : active.id;

    AuthProvider? authProvider;
    try {
      authProvider = Provider.of<AuthProvider?>(context);
    } catch (_) {}

    String customerName = 'Faisa Mohammed';
    final currentUser = authProvider?.currentUser;
    if (currentUser != null && currentUser.fullName.trim().isNotEmpty) {
      customerName = currentUser.fullName.trim();
    } else {
      try {
        final cached = StorageService.getUser();
        if (cached != null && cached.fullName.trim().isNotEmpty) {
          customerName = cached.fullName.trim();
        }
      } catch (_) {}
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = screenHeight * 0.42;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // -------------------------------------------------------------------
          // 1. TOP HALF: INTERACTIVE MAP VIEW WITH ETA OVERLAY
          // -------------------------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: mapHeight + 32, // Extra overlap under the bottom sheet
            child: Stack(
              children: [
                Positioned.fill(
                  child: RealGoogleMapView(
                    pickupAddress: active.pickupLocation,
                    destinationAddress: active.destination,
                    pickupLat: active.pickupLat,
                    pickupLng: active.pickupLng,
                    destinationLat: active.destinationLat,
                    destinationLng: active.destinationLng,
                    riderLat: active.rider?.currentLatitude,
                    riderLng: active.rider?.currentLongitude,
                  ),
                ),

                // Floating Live ETA Bubble over the map
                Positioned(
                  top: 100,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_shipping_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text(
                          _getFlowStageName(currentStage),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // 2. TOP FLOATING APP BAR
          // -------------------------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Floating Back Button
                    _buildCircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),

                    // Centered Title Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Track Package',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),

                    // Floating 3-Dots More Options Button
                    _buildCircleIconButton(
                      icon: Icons.more_vert_rounded,
                      onPressed: () => _showTrackingOptionsMenu(context, active),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // 3. BOTTOM SHEET / PANEL WITH HORIZONTAL TRACKING
          // -------------------------------------------------------------------
          Positioned(
            top: mapHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Grab Handle Pill
                      Center(
                        child: Container(
                          width: 44,
                          height: 4.5,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      // A. Rider Info Header Row
                      _buildRiderHeaderRow(rider),
                      const SizedBox(height: 14),

                      // B. Dynamic Status Banner Pill
                      _buildStatusPillBanner(active, currentStage, customerName),
                      const SizedBox(height: 14),

                      // C. The Core Booking Card & Horizontal Stepper
                      _buildBookingCard(active, currentStage, displayCode, customerName),

                      // D. Rider Arrival & OTP Verification Card (When Handover Ready)
                      if (isArrived || active.otpCode != null) ...[
                        const SizedBox(height: 14),
                        _buildOtpCard(active, provider, displayCode),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Circular Floating Icon Button
  // ---------------------------------------------------------------------------
  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: AppColors.textPrimary),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // A. Rider Header Row (Avatar, Name, Rating, Call & Message Buttons)
  // ---------------------------------------------------------------------------
  Widget _buildRiderHeaderRow(RiderInfo? rider) {
    final hasRider = rider != null && rider.fullName.isNotEmpty;
    final riderName = hasRider ? rider.fullName : 'Assigning Courier...';

    return Row(
      children: [
        // Rider Avatar
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            color: const Color(0xFFF1F5F9),
            child: Image.asset(
              'assets/images/rider_avatar_default.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFE0F2FE),
                child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Rider Name & Rating
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'Delivery',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                  SizedBox(width: 2),
                  Text(
                    '4.8',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                riderName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Action Buttons: Call & Chat (Balera Primary Blue & Obsidian Navy)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: hasRider ? () => _callRider(rider.phoneNumber) : null,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasRider ? AppColors.primary : const Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                  boxShadow: hasRider
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: const Center(
                  child: Icon(Icons.phone_rounded, color: Colors.white, size: 17),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: hasRider ? () => _messageRider(rider.phoneNumber) : null,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasRider ? AppColors.navyDark : const Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                  boxShadow: hasRider
                      ? [
                          BoxShadow(
                            color: AppColors.navyDark.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: const Center(
                  child: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // B. Dynamic Status Banner Pill
  // ---------------------------------------------------------------------------
  Widget _buildStatusPillBanner(DeliveryModel active, int stage, String customerName) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    Color dotColor;
    String leftText;
    String rightText;

    if (stage >= 6 || active.status.toUpperCase() == 'COMPLETED') {
      bgColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF166534);
      dotColor = const Color(0xFF16A34A);
      leftText = 'Delivered to $customerName';
      rightText = 'Completed ✓';
    } else if (stage == 5 || active.status.toUpperCase() == 'ARRIVED' || active.status.toUpperCase() == 'DELIVERED') {
      bgColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
      textColor = const Color(0xFF15803D);
      dotColor = const Color(0xFF16A34A);
      leftText = 'Rider arrived at destination';
      rightText = 'Share OTP with rider';
    } else if (stage >= 4 || active.status.toUpperCase() == 'ON_THE_WAY') {
      bgColor = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFFBFDBFE);
      textColor = const Color(0xFF1D4ED8);
      dotColor = AppColors.primary;
      leftText = 'Rider is on the way';
      rightText = 'In transit';
    } else if (stage >= 3 || active.status.toUpperCase() == 'PICKED_UP') {
      bgColor = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFFBFDBFE);
      textColor = const Color(0xFF1D4ED8);
      dotColor = AppColors.primary;
      leftText = 'Item picked up by rider';
      rightText = 'Heading to you';
    } else if (stage >= 2 || active.status.toUpperCase() == 'ASSIGNED') {
      bgColor = const Color(0xFFF1F5F9);
      borderColor = const Color(0xFFE2E8F0);
      textColor = const Color(0xFF334155);
      dotColor = AppColors.primary;
      leftText = 'Rider assigned to order';
      rightText = 'Heading to pickup';
    } else {
      bgColor = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFFDBEAFE);
      textColor = AppColors.primaryDark;
      dotColor = AppColors.primary;
      leftText = 'Order submitted successfully';
      rightText = 'Searching rider';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                leftText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          Text(
            rightText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // C. The Booking Card with Horizontal Stepper & 3D Package Illustration
  // ---------------------------------------------------------------------------
  Widget _buildBookingCard(DeliveryModel active, int stage, String displayCode, String customerName) {
    String statusBadgeText;
    if (stage >= 6 || active.status.toUpperCase() == 'COMPLETED') {
      statusBadgeText = 'Delivered';
    } else if (stage >= 4 || active.status.toUpperCase() == 'ON_THE_WAY') {
      statusBadgeText = 'Transit';
    } else if (stage >= 2 || active.status.toUpperCase() == 'ASSIGNED') {
      statusBadgeText = 'Process';
    } else {
      statusBadgeText = 'Process';
    }

    final isFood = active.itemType.toLowerCase().contains('food');
    final String priceString = isFood ? '240.00 Birr' : '164.00 Birr';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: "Booking" label + Black status badge pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Booking',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4.5),
                decoration: BoxDecoration(
                  gradient: AppColors.logoGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  statusBadgeText,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),

          // Prominent Booking ID
          Text(
            displayCode.startsWith('#') ? displayCode : '#$displayCode',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 16),

          // 6-STEP FLOW STEPPER (No minutes, Flow with Border / Full Color states)
          _buildFlowStepper(active, stage),

          const SizedBox(height: 18),

          // Summary Details Row (From, To, Order Cost, Customer + 3D Package Box)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Column 1: From & Order Cost
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('From', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 2),
                    Text(
                      active.pickupLocation.isNotEmpty ? active.pickupLocation : 'Bale Robe Central',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    const Text('Order Cost', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 2),
                    Text(
                      priceString,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Column 2: To & Customer
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('To', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 2),
                    Text(
                      active.destination.isNotEmpty ? active.destination : 'Destination',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    const Text('Customer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 2),
                    Text(
                      customerName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Column 3: 3D Delivery Box Illustration
              SizedBox(
                width: 76,
                height: 76,
                child: Image.asset(
                  'assets/images/package_box_3d.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: Color(0xFFD97706), size: 36),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6-Step Flow Stepper (Order submitted -> Rider assigned -> Item picked up -> On the way -> Rider arrived -> Delivered & complete)
  // ---------------------------------------------------------------------------
  Widget _buildFlowStepper(DeliveryModel active, int activeStage) {
    final isCompleted = active.status.toUpperCase() == 'COMPLETED';

    final steps = const [
      'Order submitted',
      'Rider assigned',
      'Item picked up',
      'On the way',
      'Rider arrived',
      'Delivered & complete',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DELIVERY FLOW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFDCFCE7)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isCompleted ? 'Completed ✓' : 'Step $activeStage of 6',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isCompleted ? const Color(0xFF166534) : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Horizontal 6-Node Visual Progress Bar
          Row(
            children: List.generate(11, (index) {
              if (index.isEven) {
                final stepNum = (index ~/ 2) + 1; // 1 to 6
                final bool isFinished = isCompleted || stepNum < activeStage;
                final bool isActive = !isCompleted && stepNum == activeStage;

                return _buildFlowNode(
                  stepNum: stepNum,
                  isFinished: isFinished,
                  isActive: isActive,
                );
              } else {
                final previousStepNum = (index ~/ 2) + 1;
                final bool isConnectorActive = isCompleted || previousStepNum < activeStage;

                return Expanded(
                  child: Container(
                    height: 2.5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isConnectorActive ? AppColors.primary : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }
            }),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // 6 Steps Detailed Flow List
          ...List.generate(steps.length, (i) {
            final stepNum = i + 1;
            final bool isFinished = isCompleted || stepNum < activeStage;
            final bool isActive = !isCompleted && stepNum == activeStage;
            final isLast = i == steps.length - 1;

            return _buildFlowStepRow(
              stepNumber: stepNum,
              title: steps[i],
              isFinished: isFinished,
              isActive: isActive,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFlowNode({
    required int stepNum,
    required bool isFinished,
    required bool isActive,
  }) {
    if (isFinished) {
      // Finished: Full color filled circle with white check
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.check_rounded, color: Colors.white, size: 13),
        ),
      );
    } else if (isActive) {
      // Active: Border color only & processed (pulsing inner primary dot)
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else {
      // Upcoming: Subtle grey border with grey step number
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        ),
        child: Center(
          child: Text(
            '$stepNum',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildFlowStepRow({
    required int stepNumber,
    required String title,
    required bool isFinished,
    required bool isActive,
    required bool isLast,
  }) {
    Color indicatorBg;
    Border? indicatorBorder;
    Widget indicatorChild;
    Color textColor;
    FontWeight textWeight;
    Widget? statusBadge;

    if (isFinished) {
      // Finished: Full color with checkmark
      indicatorBg = AppColors.primary;
      indicatorBorder = null;
      indicatorChild = const Icon(Icons.check_rounded, color: Colors.white, size: 14);
      textColor = const Color(0xFF0F172A);
      textWeight = FontWeight.w700;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Completed ✓',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF166534),
          ),
        ),
      );
    } else if (isActive) {
      // Active: Border color only & processed
      indicatorBg = Colors.white;
      indicatorBorder = Border.all(color: AppColors.primary, width: 2.5);
      indicatorChild = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      );
      textColor = AppColors.primary;
      textWeight = FontWeight.w800;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(width: 5),
            Text(
              'Processing',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    } else {
      // Upcoming: Muted grey border
      indicatorBg = Colors.white;
      indicatorBorder = Border.all(color: const Color(0xFFCBD5E1), width: 1.5);
      indicatorChild = Text(
        '$stepNumber',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8),
        ),
      );
      textColor = const Color(0xFF94A3B8);
      textWeight = FontWeight.w500;
      statusBadge = null;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Node + Vertical line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: indicatorBg,
                  shape: BoxShape.circle,
                  border: indicatorBorder,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(child: indicatorChild),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: isFinished ? AppColors.primary : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Right: Title & Status Badge
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14, top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$stepNumber. $title',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: textWeight,
                      color: textColor,
                    ),
                  ),
                  if (statusBadge != null) statusBadge,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // D. Rider Arrival & Handover OTP Card
  // ---------------------------------------------------------------------------
  Widget _buildOtpCard(DeliveryModel active, DeliveryProvider provider, String displayCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22),
              SizedBox(width: 8),
              Text(
                'Rider Has Arrived!',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF15803D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Share this 6-digit OTP with rider to complete verification:',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF166534), height: 1.3),
          ),
          const SizedBox(height: 12),

          // Giant OTP Display Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  active.otpCode ?? '482913',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  tooltip: 'Copy OTP',
                  icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: active.otpCode ?? '482913'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('OTP copied to clipboard!'),
                        backgroundColor: Color(0xFF16A34A),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Handover Completion Action Button
          CustomButton(
            text: 'I Gave OTP to Rider - Complete',
            isLoading: _isCheckingCompletion,
            onPressed: () => _handleCompleteDeliveryClick(active, provider),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Dotted Line Custom Painter
// -----------------------------------------------------------------------------
class DottedLinePainter extends CustomPainter {
  final Color color;
  final double dotRadius;
  final double spacing;

  DottedLinePainter({
    required this.color,
    this.dotRadius = 2.0,
    this.spacing = 3.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double startX = dotRadius;
    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawCircle(Offset(startX, y), dotRadius, paint);
      startX += dotRadius * 2 + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant DottedLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dotRadius != dotRadius;
}
