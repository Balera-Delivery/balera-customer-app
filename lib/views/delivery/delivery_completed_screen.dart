import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/delivery_provider.dart';
import '../main/main_navigation_screen.dart';
import 'delivery_details_screen.dart';

class DeliveryCompletedScreen extends StatelessWidget {
  final String deliveryId;

  const DeliveryCompletedScreen({super.key, this.deliveryId = 'DLV-00126'});

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = context.watch<DeliveryProvider>();
    final delivery = deliveryProvider.activeDelivery;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '#$deliveryId',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Large Green Check Icon (Screen 16)
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Delivery Completed!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your package was delivered\nsuccessfully.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Summary Info Card (Screen 16)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Delivery ID', '#$deliveryId'),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildSummaryRow('Rider', delivery?.rider?.fullName ?? 'Abdi Tesfaye'),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildSummaryRow('Completed at', 'Today, 10:48 AM'),
                  ],
                ),
              ),

              const Spacer(),

              // Back to Home Button (Screen 16)
              CustomButton(
                text: 'Back to Home',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 0)),
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 12),

              // View Details Button
              CustomButton(
                text: 'View Details',
                type: ButtonType.outlined,
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
