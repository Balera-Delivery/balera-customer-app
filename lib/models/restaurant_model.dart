import 'food_item_model.dart';

class RestaurantModel {
  final String id;
  final String? code;
  final String name;
  final List<String> aliases;
  final String? category;
  final String? cuisineType;
  final String? phone1;
  final String? phone2;
  final String address;
  final double? latitude;
  final double? longitude;
  final double rating;
  final int totalReviews;
  final String deliveryTime;
  final double deliveryFee;
  final String? priceRange;
  final String status;
  final String? openingHours;
  final bool isPartner;
  final String? banner;
  final String? avatar;
  final List<FoodItemModel> foods;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RestaurantModel({
    required this.id,
    this.code,
    required this.name,
    this.aliases = const [],
    this.category,
    this.cuisineType,
    this.phone1,
    this.phone2,
    required this.address,
    this.latitude,
    this.longitude,
    this.rating = 4.5,
    this.totalReviews = 0,
    this.deliveryTime = '20 - 35 min',
    this.deliveryFee = 60.0,
    this.priceRange = '\$',
    this.status = 'Active',
    this.openingHours,
    this.isPartner = true,
    this.banner,
    this.avatar,
    this.foods = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedAliases = [];
    if (json['aliases'] is List) {
      parsedAliases = (json['aliases'] as List).map((e) => e.toString()).toList();
    }

    List<FoodItemModel> parsedFoods = [];
    if (json['foods'] is List) {
      parsedFoods = (json['foods'] as List)
          .map((e) => FoodItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['menu'] is List) {
      parsedFoods = (json['menu'] as List)
          .map((e) => FoodItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return RestaurantModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString(),
      name: json['name']?.toString() ?? '',
      aliases: parsedAliases,
      category: json['category']?.toString(),
      cuisineType: json['cuisineType']?.toString(),
      phone1: json['phone1']?.toString(),
      phone2: json['phone2']?.toString(),
      address: json['address']?.toString() ?? 'Bale Robe, Ethiopia',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString()) ?? 4.5
          : 4.5,
      totalReviews: json['totalReviews'] != null
          ? int.tryParse(json['totalReviews'].toString()) ?? 0
          : 0,
      deliveryTime: json['deliveryTime']?.toString() ?? '20 - 35 min',
      deliveryFee: json['deliveryFee'] != null
          ? double.tryParse(json['deliveryFee'].toString()) ?? 60.0
          : 60.0,
      priceRange: json['priceRange']?.toString() ?? '\$',
      status: json['status']?.toString() ?? 'Active',
      openingHours: json['openingHours']?.toString() ?? '07:00 AM - 10:00 PM',
      isPartner: json['isPartner'] == true || json['isPartner'] == 1,
      banner: json['banner']?.toString(),
      avatar: json['avatar']?.toString(),
      foods: parsedFoods,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (code != null) 'code': code,
      'name': name,
      'aliases': aliases,
      if (category != null) 'category': category,
      if (cuisineType != null) 'cuisineType': cuisineType,
      if (phone1 != null) 'phone1': phone1,
      if (phone2 != null) 'phone2': phone2,
      'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'rating': rating,
      'totalReviews': totalReviews,
      'deliveryTime': deliveryTime,
      'deliveryFee': deliveryFee,
      if (priceRange != null) 'priceRange': priceRange,
      'status': status,
      if (openingHours != null) 'openingHours': openingHours,
      'isPartner': isPartner,
      if (banner != null) 'banner': banner,
      if (avatar != null) 'avatar': avatar,
      'foods': foods.map((f) => f.toJson()).toList(),
    };
  }
}
