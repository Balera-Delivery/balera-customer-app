import 'package:flutter/material.dart';
import '../models/food_item_model.dart';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';

class RestaurantProvider extends ChangeNotifier {
  final RestaurantService _restaurantService = RestaurantService();

  final List<RestaurantModel> _restaurants = [];
  RestaurantModel? _selectedRestaurant;
  FoodItemModel? _selectedFoodItem;
  int _selectedQuantity = 1;

  bool _isLoading = false;
  bool _isLoadingMenu = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<RestaurantModel> get restaurants => _restaurants;
  RestaurantModel? get selectedRestaurant => _selectedRestaurant;
  FoodItemModel? get selectedFoodItem => _selectedFoodItem;
  int get selectedQuantity => _selectedQuantity;
  bool get isLoading => _isLoading;
  bool get isLoadingMenu => _isLoadingMenu;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  double get currentFoodPrice {
    if (_selectedFoodItem == null) return 0.0;
    return _selectedFoodItem!.price * _selectedQuantity;
  }

  RestaurantProvider() {
    fetchRestaurants();
  }

  // Fetch all active partner hotels from backend
  Future<void> fetchRestaurants({String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    if (search != null) _searchQuery = search;
    notifyListeners();

    final response = await _restaurantService.getRestaurants(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );

    if (response.success && response.data != null && response.data!.isNotEmpty) {
      _restaurants.clear();
      _restaurants.addAll(response.data!);

      if (_selectedRestaurant != null) {
        final found = _restaurants.where((r) => r.id == _selectedRestaurant!.id);
        if (found.isNotEmpty) {
          _selectedRestaurant = found.first;
        }
      }
      _errorMessage = null;
    } else {
      _errorMessage = response.message.isNotEmpty ? response.message : 'Failed to load hotels.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Select a hotel and load its menu if needed (initially dish is not chosen until customer picks one)
  Future<void> selectRestaurant(RestaurantModel restaurant) async {
    _selectedRestaurant = restaurant;
    _selectedFoodItem = null;
    _selectedQuantity = 1;
    notifyListeners();

    if (restaurant.foods.isEmpty) {
      _isLoadingMenu = true;
      notifyListeners();

      final res = await _restaurantService.getRestaurantDetails(restaurant.id);
      if (res.success && res.data != null) {
        _selectedRestaurant = res.data;
      }

      _isLoadingMenu = false;
      notifyListeners();
    }
  }

  // Select a specific dish / food item
  void selectFoodItem(FoodItemModel foodItem) {
    _selectedFoodItem = foodItem;
    notifyListeners();
  }

  // Clear selections
  void clearSelection() {
    _selectedRestaurant = null;
    _selectedFoodItem = null;
    _selectedQuantity = 1;
    notifyListeners();
  }

  // Update quantity
  void setQuantity(int qty) {
    if (qty > 0) {
      _selectedQuantity = qty;
      notifyListeners();
    }
  }

  void incrementQuantity() {
    _selectedQuantity++;
    notifyListeners();
  }

  void decrementQuantity() {
    if (_selectedQuantity > 1) {
      _selectedQuantity--;
      notifyListeners();
    }
  }

  // Formatted summary of selected order for the delivery description
  String get formattedDeliveryDescription {
    if (_selectedRestaurant == null) {
      return '';
    }
    if (_selectedFoodItem == null) {
      return 'Food Delivery from ${_selectedRestaurant!.name}';
    }
    final dish = _selectedFoodItem!.name;
    final qty = _selectedQuantity > 1 ? '${_selectedQuantity}x ' : '';
    final price = '${(_selectedFoodItem!.price * _selectedQuantity).toStringAsFixed(0)} Birr';
    return '$qty$dish ($price) - ${_selectedRestaurant!.name}';
  }
}
