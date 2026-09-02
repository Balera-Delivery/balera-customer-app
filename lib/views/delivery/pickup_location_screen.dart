import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/mock_map_view.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/location_provider.dart';

class PickupLocationScreen extends StatefulWidget {
  const PickupLocationScreen({super.key});

  @override
  State<PickupLocationScreen> createState() => _PickupLocationScreenState();
}

class _PickupLocationScreenState extends State<PickupLocationScreen> {
  late TextEditingController _searchController;
  String _selectedAddress = '';

  @override
  void initState() {
    super.initState();
    final current = context.read<DeliveryProvider>().draftPickup ?? '';
    _selectedAddress = current;
    _searchController = TextEditingController(text: current);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _useCurrentLocation() async {
    final locProvider = context.read<LocationProvider>();
    await locProvider.fetchCurrentLocation();
    if (locProvider.currentAddress != null && mounted) {
      setState(() {
        _selectedAddress = locProvider.currentAddress!;
        _searchController.text = _selectedAddress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pickup Location',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Search and select pickup',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _selectedAddress = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search location',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _useCurrentLocation,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location, color: AppColors.primary, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Use current location',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Map Area (Screen 06)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: MockMapView(
                  pickupAddress: _selectedAddress,
                  showRoute: false,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bottom Address Confirmation Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      _selectedAddress.isNotEmpty ? _selectedAddress : 'Type your pickup address above or tap on map',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _selectedAddress.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                        color: _selectedAddress.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Confirm Pickup Location',
                    onPressed: () {
                      if (_selectedAddress.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter or search for a pickup location.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      context.read<DeliveryProvider>().setDraftDetails(pickup: _selectedAddress.trim());
                      Navigator.pop(context, _selectedAddress.trim());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
