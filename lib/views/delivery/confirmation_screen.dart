import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/mock_map_view.dart';
import '../../providers/delivery_provider.dart';
import 'request_submitted_screen.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = context.watch<DeliveryProvider>();
    final pickup = (deliveryProvider.draftPickup != null && deliveryProvider.draftPickup!.isNotEmpty)
        ? deliveryProvider.draftPickup!
        : 'Not specified';
    final destination = (deliveryProvider.draftDestination != null && deliveryProvider.draftDestination!.isNotEmpty)
        ? deliveryProvider.draftDestination!
        : 'Not specified';
    final item = (deliveryProvider.draftItemDescription != null && deliveryProvider.draftItemDescription!.isNotEmpty)
        ? deliveryProvider.draftItemDescription!
        : 'Item';
    final instructions = (deliveryProvider.draftInstructions != null && deliveryProvider.draftInstructions!.isNotEmpty)
        ? deliveryProvider.draftInstructions!
        : 'None';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirm Delivery',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Review your route and delivery details',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Visual Map Route Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: MockMapView(
                    pickupAddress: pickup,
                    destinationAddress: destination,
                    showRoute: true,
                    height: 160,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildFieldBlock('Pickup Location', pickup),
              const SizedBox(height: 16),
              _buildFieldBlock('Destination Location', destination),
              const SizedBox(height: 16),
              _buildFieldBlock('Item to Deliver', item),
              const SizedBox(height: 16),
              _buildFieldBlock('Special Instructions', instructions),

              const SizedBox(height: 32),

              // Submit Delivery Request Button (Screen 08)
              CustomButton(
                text: 'Submit Delivery Request',
                isLoading: deliveryProvider.isSubmitting,
                onPressed: () async {
                  final newDelivery = await deliveryProvider.createDeliveryFromDraft();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestSubmittedScreen(
                          deliveryId: newDelivery.id,
                          trackingCode: newDelivery.trackingCode,
                        ),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Edit Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldBlock(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
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
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
