import 'package:flutter/material.dart';
import '../data/fallback_hotel_data.dart';
import '../models/food_item_model.dart';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';

class RestaurantProvider extends ChangeNotifier {
  final RestaurantService _restaurantService = RestaurantService();

  final List<RestaurantModel> _restaurants = [];
  final List<FoodItemModel> _foods = [];
  RestaurantModel? _selectedRestaurant;
  FoodItemModel? _selectedFoodItem;
  int _selectedQuantity = 1;

  bool _isLoading = false;
  bool _isLoadingMenu = false;
  bool _isLoadingFoods = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<RestaurantModel> get restaurants => _restaurants;
  List<FoodItemModel> get foods => _foods;
  RestaurantModel? get selectedRestaurant => _selectedRestaurant;
  FoodItemModel? get selectedFoodItem => _selectedFoodItem;
  int get selectedQuantity => _selectedQuantity;
  bool get isLoading => _isLoading;
  bool get isLoadingMenu => _isLoadingMenu;
  bool get isLoadingFoods => _isLoadingFoods;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  double get currentFoodPrice {
    if (_selectedFoodItem == null) return 0.0;
    return _selectedFoodItem!.price * _selectedQuantity;
  }

  RestaurantProvider() {
    _restaurants.addAll(_getFallbackRestaurants());
    _populateFallbackFoods();
    fetchRestaurants();
    fetchFoods();
  }

  void _populateFallbackFoods() {
    _foods.clear();
    for (final r in _restaurants) {
      for (final f in r.foods) {
        _foods.add(
          f.copyWith(
            restaurantName: r.name,
            restaurantDeliveryTime: r.deliveryTime,
            restaurantRating: r.rating,
          ),
        );
      }
    }
  }

  String getRestaurantName(String restaurantId) {
    for (final r in _restaurants) {
      if (r.id == restaurantId || r.code == restaurantId) {
        return r.name;
      }
    }
    return 'Partner Restaurant';
  }

  String getRestaurantDeliveryTime(String restaurantId) {
    for (final r in _restaurants) {
      if (r.id == restaurantId || r.code == restaurantId) {
        return r.deliveryTime;
      }
    }
    return '20 - 30 min';
  }

  double getRestaurantRating(String restaurantId) {
    for (final r in _restaurants) {
      if (r.id == restaurantId || r.code == restaurantId) {
        return r.rating;
      }
    }
    return 4.7;
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
      if (_restaurants.isEmpty) {
        _restaurants.addAll(_getFallbackRestaurants());
      }
      _errorMessage = response.message.isNotEmpty ? response.message : 'Failed to load hotels.';
    }

    // Refresh foods so any new partner foods or restaurants are merged immediately
    _populateFoodsFromRestaurants();

    _isLoading = false;
    notifyListeners();
  }

  void _populateFoodsFromRestaurants() {
    // If backend foods hasn't loaded separate foods yet, or if offline,
    // ensure all partner dishes from all restaurants are populated
    final Map<String, FoodItemModel> foodMap = {};

    // 1. First add any existing foods
    for (final f in _foods) {
      foodMap[f.id] = f;
    }

    // 2. Add all partner foods from all restaurants
    for (final r in _restaurants) {
      for (final f in r.foods) {
        foodMap[f.id] = f.copyWith(
          restaurantName: r.name,
          restaurantDeliveryTime: r.deliveryTime,
          restaurantRating: r.rating,
        );
      }
    }

    _foods.clear();
    _foods.addAll(foodMap.values);
  }

  // Fetch all partner food dishes across restaurants (GET /api/v1/foods)
  Future<void> fetchFoods({String? search, String? category}) async {
    _isLoadingFoods = true;
    notifyListeners();

    final response = await _restaurantService.getFoods(
      search: search,
      category: category,
    );

    if (response.success && response.data != null && response.data!.isNotEmpty) {
      _foods.clear();
      // Ensure each food has restaurant name & delivery time attached
      for (final f in response.data!) {
        final rName = (f.restaurantName != null && f.restaurantName!.isNotEmpty)
            ? f.restaurantName
            : getRestaurantName(f.restaurantId);
        final rTime = (f.restaurantDeliveryTime != null && f.restaurantDeliveryTime!.isNotEmpty)
            ? f.restaurantDeliveryTime
            : getRestaurantDeliveryTime(f.restaurantId);
        final rRating = f.restaurantRating ?? getRestaurantRating(f.restaurantId);

        _foods.add(
          f.copyWith(
            restaurantName: rName,
            restaurantDeliveryTime: rTime,
            restaurantRating: rRating,
          ),
        );
      }
    } else {
      // If backend foods endpoint is empty or offline, fallback to hotel menus
      if (_foods.isEmpty) {
        _populateFallbackFoods();
      }
    }

    _isLoadingFoods = false;
    notifyListeners();
  }

  static List<RestaurantModel> _getFallbackRestaurants() {
    return FallbackHotelData.restaurants;
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
