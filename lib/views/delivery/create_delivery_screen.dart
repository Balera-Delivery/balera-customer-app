import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../models/food_item_model.dart';
import '../../models/restaurant_model.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/restaurant_provider.dart';
import 'checkout_screen.dart';
import 'destination_location_screen.dart';
import 'pickup_location_screen.dart';

enum DeliveryCategory { food, other }

class CreateDeliveryScreen extends StatefulWidget {
  const CreateDeliveryScreen({super.key});

  @override
  State<CreateDeliveryScreen> createState() => _CreateDeliveryScreenState();
}

class _CreateDeliveryScreenState extends State<CreateDeliveryScreen> {
  DeliveryCategory _selectedCategory = DeliveryCategory.food;

  late TextEditingController _pickupController;
  late TextEditingController _destinationController;
  final _itemDescriptionController = TextEditingController();
  final _instructionsController = TextEditingController();

  double? _selectedPickupLat;
  double? _selectedPickupLng;
  double? _selectedFoodPrice;
  String? _selectedRestaurantName;
  String? _selectedRestaurantId;

  @override
  void initState() {
    super.initState();
    final deliveryProvider = context.read<DeliveryProvider>();
    _pickupController = TextEditingController(text: deliveryProvider.draftPickup ?? '');
    _destinationController = TextEditingController(text: deliveryProvider.draftDestination ?? '');

    if (deliveryProvider.draftItemDescription != null && deliveryProvider.draftItemDescription!.isNotEmpty) {
      _itemDescriptionController.text = deliveryProvider.draftItemDescription!;
      if (deliveryProvider.draftItemType == 'Food & Groceries') {
        _selectedCategory = DeliveryCategory.food;
      } else {
        _selectedCategory = DeliveryCategory.other;
      }
    } else {
      _selectedCategory = DeliveryCategory.food;
    }

    if (deliveryProvider.draftInstructions != null) {
      _instructionsController.text = deliveryProvider.draftInstructions!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurantProvider = context.read<RestaurantProvider>();
      restaurantProvider.fetchRestaurants();
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _itemDescriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _syncFromRestaurantProvider(RestaurantProvider provider) {
    final restaurant = provider.selectedRestaurant;
    final food = provider.selectedFoodItem;
    final qty = provider.selectedQuantity;

    if (restaurant != null) {
      _selectedRestaurantName = restaurant.name;
      _selectedRestaurantId = restaurant.id;
      _selectedPickupLat = restaurant.latitude ?? 7.0083;
      _selectedPickupLng = restaurant.longitude ?? 39.9833;
      _pickupController.text = restaurant.address;

      if (food != null) {
        _selectedFoodPrice = food.price * qty;
        final qtyPrefix = qty > 1 ? '${qty}x ' : '';
        _itemDescriptionController.text =
            '$qtyPrefix${food.name} (${(food.price * qty).toStringAsFixed(0)} Birr) - ${restaurant.name}';
      } else {
        _selectedFoodPrice = 0.0;
        _itemDescriptionController.text = 'Food Delivery from ${restaurant.name}';
      }
    } else {
      _selectedRestaurantName = null;
      _selectedRestaurantId = null;
      _selectedPickupLat = null;
      _selectedPickupLng = null;
      _selectedFoodPrice = null;
      _pickupController.clear();
      _itemDescriptionController.clear();
    }
    if (mounted) setState(() {});
  }

  void _onCategorySelected(DeliveryCategory category) {
    setState(() {
      _selectedCategory = category;
      if (category == DeliveryCategory.food) {
        final restaurantProvider = context.read<RestaurantProvider>();
        if (restaurantProvider.selectedRestaurant != null) {
          _syncFromRestaurantProvider(restaurantProvider);
        } else {
          _itemDescriptionController.clear();
          _pickupController.clear();
        }
      } else {
        _itemDescriptionController.clear();
        _pickupController.clear();
        _selectedFoodPrice = null;
        _selectedRestaurantName = null;
        _selectedRestaurantId = null;
        _selectedPickupLat = null;
        _selectedPickupLng = null;
      }
    });
  }

  void _openRestaurantPicker(BuildContext context) {
    final restaurantProvider = context.read<RestaurantProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RestaurantPickerSheet(
        onSelected: (restaurant) {
          Navigator.pop(ctx);
          restaurantProvider.selectRestaurant(restaurant).then((_) {
            if (mounted) {
              _syncFromRestaurantProvider(restaurantProvider);
            }
          });
        },
      ),
    );
  }

  void _onFoodItemSelected(FoodItemModel foodItem) {
    final restaurantProvider = context.read<RestaurantProvider>();
    restaurantProvider.selectFoodItem(foodItem);
    _syncFromRestaurantProvider(restaurantProvider);
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

    if (itemDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a hotel & food dish, or describe your item.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (pickup.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a hotel or enter pickup location.'),
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

    final deliveryProvider = context.read<DeliveryProvider>();
    deliveryProvider.setDraftDetails(
      pickup: pickup,
      destination: destination,
      itemType: _selectedCategory == DeliveryCategory.food ? 'Food & Groceries' : 'Parcel / Box',
      itemDescription: itemDescription,
      instructions: instructions.isNotEmpty ? instructions : null,
      foodPrice: _selectedFoodPrice,
      restaurantName: _selectedRestaurantName,
      restaurantId: _selectedRestaurantId,
      pickupLat: _selectedPickupLat ?? 7.0083,
      pickupLng: _selectedPickupLng ?? 39.9833,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFood = _selectedCategory == DeliveryCategory.food;
    final isOther = _selectedCategory == DeliveryCategory.other;
    final restaurantProvider = context.watch<RestaurantProvider>();
    final selectedRestaurant = restaurantProvider.selectedRestaurant;
    final selectedFood = restaurantProvider.selectedFoodItem;
    final allHotels = restaurantProvider.restaurants;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Request Delivery',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Where & What to Deliver',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose your category: order delicious meals or send custom items.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // 1. Category Switcher ("Order Food" vs "Order Other")
              Row(
                children: [
                  // Card 1: Order Food
                  Expanded(
                    child: _buildCategoryCard(
                      title: 'Order Food',
                      subtitle: 'Hotels & Menus',
                      icon: Icons.restaurant_rounded,
                      isSelected: isFood,
                      activeBgColor: const Color(0xFFEFF6FF),
                      activeBorderColor: AppColors.primary,
                      activeIconColor: AppColors.primary,
                      onTap: () => _onCategorySelected(DeliveryCategory.food),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Card 2: Order Other
                  Expanded(
                    child: _buildCategoryCard(
                      title: 'Order Other',
                      subtitle: 'Parcels & custom items',
                      icon: Icons.inventory_2_rounded,
                      isSelected: isOther,
                      activeBgColor: const Color(0xFFEEF2FF),
                      activeBorderColor: const Color(0xFF4F46E5),
                      activeIconColor: const Color(0xFF4F46E5),
                      onTap: () => _onCategorySelected(DeliveryCategory.other),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              if (isFood) ...[
                // --- SECTION: EXPLORE HOTELS & RESTAURANTS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Explore Hotels & Restaurants',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (selectedRestaurant != null)
                      InkWell(
                        onTap: () => _openRestaurantPicker(context),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Change Hotel',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // State A: When NO hotel is selected yet
                if (selectedRestaurant == null) ...[
                  InkWell(
                    onTap: () => _openRestaurantPicker(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 26),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select a Hotel to View Menu',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Tap here to browse all verified partner hotels in Bale Robe',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),

                  // Horizontal Quick Hotel Explorer List
                  if (allHotels.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Popular Hotels in Bale Robe:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 86,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: allHotels.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, idx) {
                          final h = allHotels[idx];
                          return InkWell(
                            onTap: () {
                              restaurantProvider.selectRestaurant(h).then((_) {
                                if (mounted) _syncFromRestaurantProvider(restaurantProvider);
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 160,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      color: const Color(0xFFE0F2FE),
                                      child: h.avatar != null && h.avatar!.isNotEmpty
                                          ? Image.network(
                                              h.avatar!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 20),
                                            )
                                          : const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          h.name,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded, size: 12, color: Color(0xFFEAB308)),
                                            const SizedBox(width: 2),
                                            Text('${h.rating}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ] else ...[
                  // State B: When a hotel is selected
                  InkWell(
                    onTap: () => _openRestaurantPicker(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Hotel Avatar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 54,
                              height: 54,
                              color: const Color(0xFFE0F2FE),
                              child: selectedRestaurant.avatar != null && selectedRestaurant.avatar!.isNotEmpty
                                  ? Image.network(
                                      selectedRestaurant.avatar!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 26),
                                    )
                                  : const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 26),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        selectedRestaurant.name,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Verified',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  selectedRestaurant.address,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFEAB308)),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${selectedRestaurant.rating}',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
                                    const SizedBox(width: 3),
                                    Text(
                                      selectedRestaurant.deliveryTime,
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // --- SECTION: SELECT FOOD DISH & PRICE ---
                const Text(
                  'Select Food Dish & Price',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                if (selectedRestaurant == null) ...[
                  // Empty state when no hotel is selected yet
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Please select a hotel above to view and choose from its food menu.',
                            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (restaurantProvider.isLoadingMenu) ...[
                  Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(color: AppColors.primary),
                  ),
                ] else if (selectedRestaurant.foods.isNotEmpty) ...[
                  // Food Dishes List for Selected Hotel
                  SizedBox(
                    height: 172,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedRestaurant.foods.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, idx) {
                        final food = selectedRestaurant.foods[idx];
                        final isSelected = selectedFood?.id == food.id;

                        return InkWell(
                          onTap: () => _onFoodItemSelected(food),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                width: isSelected ? 2.0 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        height: 72,
                                        width: double.infinity,
                                        color: const Color(0xFFF1F5F9),
                                        child: food.image != null && food.image!.isNotEmpty
                                            ? Image.network(
                                                food.image!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.fastfood_rounded, color: AppColors.textMuted, size: 28),
                                              )
                                            : const Icon(Icons.fastfood_rounded, color: AppColors.textMuted, size: 28),
                                      ),
                                    ),
                                    if (food.tag != null && food.tag!.isNotEmpty)
                                      Positioned(
                                        top: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD97706),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            food.tag!,
                                            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    if (isSelected)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  food.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${food.price.toStringAsFixed(0)} Birr',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    isSelected ? 'Selected ✓' : 'Select Dish',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Quantity Selector for Selected Dish
                  if (selectedFood != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Portion: ${selectedFood.name}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              Text(
                                '${selectedFood.price.toStringAsFixed(0)} Birr × ${restaurantProvider.selectedQuantity} = ${(selectedFood.price * restaurantProvider.selectedQuantity).toStringAsFixed(0)} Birr',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, size: 22, color: AppColors.primary),
                                onPressed: () {
                                  restaurantProvider.decrementQuantity();
                                  _syncFromRestaurantProvider(restaurantProvider);
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  '${restaurantProvider.selectedQuantity}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_rounded, size: 22, color: AppColors.primary),
                                onPressed: () {
                                  restaurantProvider.incrementQuantity();
                                  _syncFromRestaurantProvider(restaurantProvider);
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 14),

                // --- HELPFUL REMINDER BANNER FOR CUSTOM ORDERS ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.35),
                            children: [
                              const TextSpan(text: "Can't find your hotel or meal? "),
                              const TextSpan(
                                text: "Select the 'Order Other' option above ",
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const TextSpan(
                                text: "and write what you want—our rider will purchase and deliver it for you!",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // 2. "What do you want delivered?"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'What do you want delivered?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (isFood && selectedFood != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Auto-filled from Menu',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _itemDescriptionController,
                maxLines: isFood ? 2 : 1,
                readOnly: isFood && selectedFood != null,
                decoration: InputDecoration(
                  hintText: isFood
                      ? 'Selected hotel and food dish will appear here'
                      : 'Describe your item (e.g. Documents, Laptop, Keys, Clothes, Special meal)',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  filled: isFood && selectedFood != null,
                  fillColor: (isFood && selectedFood != null) ? const Color(0xFFF0F9FF) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: (isFood && selectedFood != null) ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: (isFood && selectedFood != null) ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 3. "Delivery Instructions (Optional)"
              const Text(
                'Delivery Instructions (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _instructionsController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Any special instructions (e.g. Extra chili sauce, call upon arrival, leave at door)',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                ),
              ),

              const SizedBox(height: 18),

              // 4. "Pickup Location" (Auto-filled if hotel is chosen)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pickup Location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (isFood && selectedRestaurant != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Hotel Address',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _pickupController,
                decoration: InputDecoration(
                  hintText: isFood
                      ? (selectedRestaurant != null ? selectedRestaurant.address : 'Select a hotel above to auto-fill pickup')
                      : 'Enter pickup address (or pick on map)',
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

              // 5. "Destination"
              const Text(
                'Destination',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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

              const SizedBox(height: 28),

              // 6. Continue to Checkout Button
              CustomButton(
                text: 'Continue to Checkout',
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

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color activeBgColor,
    required Color activeBorderColor,
    required Color activeIconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeBorderColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBorderColor.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? activeBorderColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? activeIconColor : AppColors.textSecondary,
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: isSelected ? activeBorderColor : const Color(0xFFCBD5E1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeIconColor : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modal sheet to search and choose from all hotels (No category tabs, direct full list)
class _RestaurantPickerSheet extends StatefulWidget {
  final ValueChanged<RestaurantModel> onSelected;

  const _RestaurantPickerSheet({required this.onSelected});

  @override
  State<_RestaurantPickerSheet> createState() => _RestaurantPickerSheetState();
}

class _RestaurantPickerSheetState extends State<_RestaurantPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = context.watch<RestaurantProvider>();
    final restaurants = restaurantProvider.restaurants;

    final query = _searchCtrl.text.toLowerCase().trim();
    final filtered = restaurants.where((r) {
      return query.isEmpty ||
          r.name.toLowerCase().contains(query) ||
          r.address.toLowerCase().contains(query) ||
          (r.cuisineType?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Hotels & Restaurants',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'All verified partner establishments in Bale Robe',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by hotel name or address...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // List of All Hotels
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No hotels found matching your search.', style: TextStyle(color: AppColors.textSecondary)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      final isCurrent = restaurantProvider.selectedRestaurant?.id == item.id;

                      return InkWell(
                        onTap: () => widget.onSelected(item),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCurrent ? const Color(0xFFF0F9FF) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrent ? AppColors.primary : const Color(0xFFE2E8F0),
                              width: isCurrent ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  color: const Color(0xFFE0F2FE),
                                  child: item.avatar != null && item.avatar!.isNotEmpty
                                      ? Image.network(
                                          item.avatar!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 28),
                                        )
                                      : const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 28),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (isCurrent)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text('Selected', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.address,
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFEAB308)),
                                        const SizedBox(width: 3),
                                        Text('${item.rating}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                                        const SizedBox(width: 8),
                                        Text('• ${item.foods.length} dishes in menu', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
