import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import 'delivery_otp_screen.dart';
import 'delivery_tracking_screen.dart';

class DeliveryDetailsScreen extends StatelessWidget {
  final DeliveryModel delivery;

  const DeliveryDetailsScreen({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final customerName = authProvider.currentUser?.fullName ?? 'Faisa Mohammed';
    final customerPhone = authProvider.currentUser?.phoneNumber ?? '0912345678';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '#${delivery.trackingCode ?? delivery.id}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: StatusBadge(status: delivery.status),
            ),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailSection('Customer', customerName),
              const SizedBox(height: 16),
              _buildDetailSection('Phone', customerPhone),
              const Divider(height: 28, color: Color(0xFFF1F5F9)),
              _buildDetailSection('Pickup', delivery.pickupLocation),
              const SizedBox(height: 16),
              _buildDetailSection('Destination', delivery.destination),
              const Divider(height: 28, color: Color(0xFFF1F5F9)),
              _buildDetailSection('Item', delivery.itemType),
              const SizedBox(height: 16),
              _buildDetailSection('Instructions', delivery.instructions ?? 'Handle carefully. Call before delivery.'),
              if (delivery.cancellationReason != null) ...[
                const SizedBox(height: 16),
                _buildDetailSection('Cancellation Reason', delivery.cancellationReason!),
              ],
              const Divider(height: 28, color: Color(0xFFF1F5F9)),

              // Payment & Receipt Section
              if (delivery.paymentMethod != null || delivery.receiptUrl != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.payment_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Payment & Receipt',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: (delivery.paymentStatus == 'VERIFIED_PAID' || delivery.paymentStatus == 'Paid')
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              delivery.paymentStatus ?? 'Pending Verification',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: (delivery.paymentStatus == 'VERIFIED_PAID' || delivery.paymentStatus == 'Paid')
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Method:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            delivery.paymentMethod ?? 'Direct Transfer',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      if (delivery.receiptUrl != null) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => Dialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppBar(
                                      title: const Text('Payment Receipt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                      automaticallyImplyLeading: false,
                                      actions: [
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded),
                                          onPressed: () => Navigator.pop(ctx),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      color: const Color(0xFF0F172A),
                                      constraints: const BoxConstraints(maxHeight: 500),
                                      alignment: Alignment.center,
                                      child: InteractiveViewer(
                                        panEnabled: true,
                                        minScale: 0.8,
                                        maxScale: 4.0,
                                        child: _buildReceiptImage(delivery.receiptUrl!),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primary),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'View Uploaded Transfer Slip',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                ),
                                Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Divider(height: 32, color: Color(0xFFF1F5F9)),

              // Rider Assignment Pending Banner (No live tracking or rider contact if not assigned)
              if (delivery.status == AppConstants.statusPending || delivery.rider == null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Waiting for Rider Assignment',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your delivery is submitted and awaiting admin dispatch. Once a rider is assigned, live tracking and rider contact will become available.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF78350F),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF92400E),
                            side: const BorderSide(color: Color(0xFFD97706)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.track_changes_rounded, size: 16),
                          label: const Text('Track Order Status'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DeliveryTrackingScreen(
                                  deliveryId: delivery.id,
                                  initialDelivery: delivery,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Rider Contact Card (Screen 18) - ONLY when rider is assigned
              if (delivery.rider != null && delivery.status != AppConstants.statusPending) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assigned Rider',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          delivery.rider!.fullName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (delivery.rider?.vehicleInfo != null)
                          Text(
                            delivery.rider!.vehicleInfo!,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Calling ${delivery.rider!.fullName} (${delivery.rider!.phoneNumber})...'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons: Live Tracking & View OTP (ONLY when rider is assigned)
              if (delivery.rider != null && delivery.status != AppConstants.statusPending && AppConstants.isOngoing(delivery.status)) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.track_changes_rounded, size: 18),
                        label: const Text('Track Order Status'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DeliveryTrackingScreen(
                                deliveryId: delivery.id,
                                initialDelivery: delivery,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.pin_outlined, size: 18),
                        label: const Text('View OTP'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DeliveryOtpScreen(
                                deliveryId: delivery.trackingCode ?? delivery.id,
                                otpCode: delivery.otpCode,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Cancel Delivery Button (Only if still pending or assigned)
              if (delivery.status == AppConstants.statusPending || delivery.status == AppConstants.statusAssigned) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE2E2),
                      foregroundColor: const Color(0xFFDC2626),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel Delivery Request', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _confirmCancel(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Delivery?'),
        content: const Text('Are you sure you want to cancel this delivery request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<DeliveryProvider>().cancelDelivery(
                    delivery.id,
                    reason: 'Cancelled by customer',
                  );
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delivery request cancelled.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to cancel delivery.'),
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

  Widget _buildDetailSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptImage(String receiptUrl) {
    if (receiptUrl.startsWith('data:image')) {
      try {
        final commaIndex = receiptUrl.indexOf(',');
        final base64Data = commaIndex != -1 ? receiptUrl.substring(commaIndex + 1) : receiptUrl;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('Could not render receipt image', style: TextStyle(color: Colors.white70)),
          ),
        );
      } catch (e) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text('Error decoding image: $e', style: const TextStyle(color: Colors.white70)),
        );
      }
    }

    return Image.network(
      receiptUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Padding(
        padding: EdgeInsets.all(32.0),
        child: Text('Receipt Image Preview', style: TextStyle(color: Colors.white70)),
      ),
    );
  }

}