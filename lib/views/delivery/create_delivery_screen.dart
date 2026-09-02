import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/mock_map_view.dart';
import '../../providers/delivery_provider.dart';
import 'confirmation_screen.dart';
import 'destination_location_screen.dart';
import 'pickup_location_screen.dart';

class CreateDeliveryScreen extends StatefulWidget {
  const CreateDeliveryScreen({super.key});

  @override
  State<CreateDeliveryScreen> createState() => _CreateDeliveryScreenState();
}

class _CreateDeliveryScreenState extends State<CreateDeliveryScreen> {
  late TextEditingController _pickupController;
  late TextEditingController _destinationController;
  final _itemDescriptionController = TextEditingController();
  final _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<DeliveryProvider>();
    _pickupController = TextEditingController(text: provider.draftPickup ?? '');
    _destinationController = TextEditingController(text: provider.draftDestination ?? '');
    if (provider.draftItemDescription != null) {
      _itemDescriptionController.text = provider.draftItemDescription!;
    }
    if (provider.draftInstructions != null) {
      _instructionsController.text = provider.draftInstructions!;
    }

    _pickupController.addListener(_onAddressChanged);
    _destinationController.addListener(_onAddressChanged);
  }

  void _onAddressChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _pickupController.removeListener(_onAddressChanged);
    _destinationController.removeListener(_onAddressChanged);
    _pickupController.dispose();
    _destinationController.dispose();
    _itemDescriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _openPickupPicker() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PickupLocationScreen()),
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _pickupController.text = result;
      });
    }
  }

  void _openDestinationPicker() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const DestinationLocationScreen()),
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _destinationController.text = result;
      });
    }
  }

  void _handleContinue() {
    final pickup = _pickupController.text.trim();
    final destination = _destinationController.text.trim();
    final itemDescription = _itemDescriptionController.text.trim();
    final instructions = _instructionsController.text.trim();

    if (pickup.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or select a pickup location.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or select a destination.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (itemDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the item you want delivered.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final deliveryProvider = context.read<DeliveryProvider>();
    deliveryProvider.setDraftDetails(
      pickup: pickup,
      destination: destination,
      itemDescription: itemDescription,
      instructions: instructions.isNotEmpty ? instructions : null,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ConfirmationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPickup = _pickupController.text.trim().isNotEmpty;
    final hasDestination = _destinationController.text.trim().isNotEmpty;

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
                'Request a Delivery',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter your locations and item details',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Live Map Route Preview Card
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      MockMapView(
                        pickupAddress: hasPickup ? _pickupController.text : null,
                        destinationAddress: hasDestination ? _destinationController.text : null,
                        showRoute: hasPickup || hasDestination,
                        height: 150,
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map_outlined, size: 13, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Live Map Preview',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Pickup Location Input
              const Text(
                'Pickup Location',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _pickupController,
                decoration: InputDecoration(
                  hintText: 'Enter pickup address (or pick on map)',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                    tooltip: 'Pick on map',
                    onPressed: _openPickupPicker,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Destination Location Input
              const Text(
                'Destination',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _destinationController,
                decoration: InputDecoration(
                  hintText: 'Enter destination address (or pick on map)',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                    tooltip: 'Pick on map',
                    onPressed: _openDestinationPicker,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // What do you want delivered? (Clean, customer writes their own)
              CustomTextField(
                label: 'What do you want delivered?',
                hint: 'Describe your item (e.g. Documents, Laptop, Clothes)',
                controller: _itemDescriptionController,
              ),

              const SizedBox(height: 18),

              // Delivery Instructions (Optional)
              CustomTextField(
                label: 'Delivery Instructions',
                hint: 'Any special instructions (optional)',
                controller: _instructionsController,
                maxLines: 2,
              ),

              const SizedBox(height: 28),

              // Continue Button
              CustomButton(
                text: 'Continue to Review',
                onPressed: _handleContinue,
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
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
}
