import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/mock_map_view.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import 'delivery_details_screen.dart';
import 'delivery_otp_screen.dart';
import 'package:balera_customer_app/views/delivery/package_picked_up_screen.dart';
import 'package:balera_customer_app/views/delivery/rider_arrived_screen.dart';

class LiveTrackingScreen extends StatefulWidget {
  final DeliveryModel? delivery;

  const LiveTrackingScreen({super.key, this.delivery});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final active = widget.delivery ?? context.read<DeliveryProvider>().activeDelivery;
      if (active != null) {
        context.read<DeliveryProvider>().fetchTracking(active.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = context.watch<DeliveryProvider>();
    final delivery = widget.delivery ?? deliveryProvider.activeDelivery;
    final tracking = deliveryProvider.liveTrackingData;
    final rider = tracking?.rider ?? delivery?.rider;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '#${delivery?.trackingCode ?? delivery?.id ?? 'DLV-00126'}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'picked_up') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PackagePickedUpScreen()));
              } else if (val == 'arrived') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderArrivedScreen()));
              } else if (val == 'otp') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeliveryOtpScreen(
                      deliveryId: delivery?.trackingCode ?? delivery?.id ?? '',
                      otpCode: delivery?.otpCode,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'picked_up', child: Text('View: Package Picked Up (Screen 13)')),
              PopupMenuItem(value: 'arrived', child: Text('View: Rider Arrived (Screen 14)')),
              PopupMenuItem(value: 'otp', child: Text('View: Delivery OTP (Screen 15)')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full Interactive Map Area (Screen 12)
          Positioned.fill(
            child: MockMapView(
              pickupAddress: tracking?.pickupAddress.isNotEmpty == true ? tracking!.pickupAddress : delivery?.pickupLocation,
              destinationAddress: tracking?.destinationAddress.isNotEmpty == true ? tracking!.destinationAddress : delivery?.destination,
              showRoute: true,
              showRider: true,
            ),
          ),

          // Floating Bottom Sheet / Details Panel (Screen 12)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delivery_dining_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rider != null ? 'Rider: ${rider.fullName}' : 'Arranging Rider...',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (rider?.vehicleInfo != null && rider!.vehicleInfo!.isNotEmpty)
                              Text(
                                rider.vehicleInfo!,
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PackagePickedUpScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Estimated arrival',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          Row(
                            children: [
                              Text(
                                '7 min (2.5 km)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Arrived Handover OTP Card (Customer gives OTP to rider on arrival)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Handover OTP Code',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              delivery?.otpCode ?? '482913',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4, color: AppColors.primary),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DeliveryOtpScreen(
                                  deliveryId: delivery?.trackingCode ?? delivery?.id ?? 'DLV-00126',
                                  otpCode: delivery?.otpCode,
                                ),
                              ),
                            );
                          },
                          child: const Text('Give OTP', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (rider != null) ...[
                        Expanded(
                          child: CustomButton(
                            text: 'Contact Rider',
                            type: ButtonType.outlined,
                            height: 46,
                            onPressed: () {
                              _showContactSheet(
                                context,
                                rider.fullName,
                                rider.phoneNumber,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: CustomButton(
                          text: 'Delivery Details',
                          height: 46,
                          onPressed: () {
                            if (delivery != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DeliveryDetailsScreen(delivery: delivery),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactSheet(BuildContext context, String riderName, String riderPhone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact $riderName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.phone, color: AppColors.primary)),
              title: Text('Call $riderPhone'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling $riderName ($riderPhone)...')),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.chat, color: AppColors.primary)),
              title: const Text('Send In-App Message'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
