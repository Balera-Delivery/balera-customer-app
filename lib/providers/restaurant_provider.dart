import 'package:flutter/material.dart';
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

    _isLoading = false;
    notifyListeners();
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
    return const [
      RestaurantModel(
        id: 'htl-all-seasons',
        name: 'All Seasons Hotel',
        address: 'Bale Robe Bypass Highway, Ethiopia',
        latitude: 7.0083,
        longitude: 39.9833,
        rating: 4.9,
        totalReviews: 310,
        deliveryTime: '25 - 40 min',
        deliveryFee: 70.0,
        priceRange: '\$\$\$',
        avatar: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200&auto=format&fit=crop&q=80',
        foods: [
          FoodItemModel(
            id: 'fb-as-1',
            restaurantId: 'htl-all-seasons',
            name: 'Special Fetira with Honey & Egg',
            price: 390,
            category: 'Breakfast & Breads',
            description: 'Layered crispy pastry stuffed with egg and drizzled with pure honey.',
            image: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400&auto=format&fit=crop&q=80',
          ),
          FoodItemModel(
            id: 'fb-as-2',
            restaurantId: 'htl-all-seasons',
            name: 'Special Beef Tibs',
            price: 620,
            category: 'Traditional Stews',
            description: 'Spiced torn injera cooked with tender sizzling beef tibs.',
            image: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400&auto=format&fit=crop&q=80',
          ),
          FoodItemModel(
            id: 'fb-as-3',
            restaurantId: 'htl-all-seasons',
            name: 'Cheese Burger & Fries',
            price: 720,
            category: 'Burgers & Sandwiches',
            description: 'Grilled beef patty topped with a double layer of melted cheddar cheese.',
            image: 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=400&auto=format&fit=crop&q=80',
          ),
          FoodItemModel(
            id: 'fb-as-4',
            restaurantId: 'htl-all-seasons',
            name: 'Fresh Mango Juice',
            price: 390,
            category: 'Drinks & Juices',
            description: '100% freshly pressed thick sweet mango juice.',
            image: 'https://images.unsplash.com/photo-1613478223719-2ab802602423?w=400&auto=format&fit=crop&q=80',
          ),
        ],
      ),
      RestaurantModel(
        id: 'htl-bale-mountain',
        name: 'Bale Mountain Lodge & Hotel',
        address: 'Bale National Park Road, Bale Robe',
        latitude: 7.0125,
        longitude: 39.9880,
        rating: 4.8,
        totalReviews: 240,
        deliveryTime: '20 - 35 min',
        deliveryFee: 60.0,
        avatar: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&auto=format&fit=crop&q=80',
        foods: [
          FoodItemModel(
            id: 'fb-bml-1',
            restaurantId: 'htl-bale-mountain',
            name: 'Traditional Bale Kitfo',
            price: 650,
            category: 'Specialty',
            description: 'Minced prime lean beef seasoned with niter kibbeh and mitmita.',
            image: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400&auto=format&fit=crop&q=80',
          ),
          FoodItemModel(
            id: 'fb-bml-2',
            restaurantId: 'htl-bale-mountain',
            name: 'Special Shiro Tegabino',
            price: 450,
            category: 'Traditional Stews',
            description: 'Clay pot bubbling shiro served boiling hot with fresh injera.',
            image: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400&auto=format&fit=crop&q=80',
          ),
        ],
      ),
      RestaurantModel(
        id: 'htl-robe-grand',
        name: 'Robe Grand Hotel',
        address: 'Bale Robe Central Boulevard',
        latitude: 7.0083,
        longitude: 39.9833,
        rating: 4.7,
        totalReviews: 185,
        deliveryTime: '25 - 40 min',
        deliveryFee: 60.0,
        avatar: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=200&auto=format&fit=crop&q=80',
        foods: [
          FoodItemModel(
            id: 'fb-rgh-1',
            restaurantId: 'htl-robe-grand',
            name: 'Roasted Doro Wat',
            price: 680,
            category: 'Main Dish',
            description: 'Traditional slow-cooked spicy chicken stew with hard-boiled egg.',
            image: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400&auto=format&fit=crop&q=80',
          ),
          FoodItemModel(
            id: 'fb-rgh-2',
            restaurantId: 'htl-robe-grand',
            name: 'Club Sandwich & Fries',
            price: 520,
            category: 'Burgers & Sandwiches',
            description: 'Triple decker toast with chicken, egg, cheese, and french fries.',
            image: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400&auto=format&fit=crop&q=80',
          ),
        ],
      ),
      RestaurantModel(
        id: 'htl-wabe-shebelle',
        name: 'Wabe Shebelle Hotel Robe',
        address: 'Near Old Bus Station, Bale Robe',
        latitude: 7.0102,
        longitude: 39.9855,
        rating: 4.6,
        totalReviews: 140,
        deliveryTime: '20 - 30 min',
        deliveryFee: 50.0,
        avatar: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200&auto=format&fit=crop&q=80',
        foods: [
          FoodItemModel(
            id: 'fb-wsh-1',
            restaurantId: 'htl-wabe-shebelle',
            name: 'Derek Beef Tibs',
            price: 590,
            category: 'Main Dish',
            description: 'Well-done crispy beef tibs served with awaze and mitmita.',
            image: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=400&auto=format&fit=crop&q=80',
          ),
        ],
      ),
    ];
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
