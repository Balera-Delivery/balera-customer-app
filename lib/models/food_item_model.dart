class FoodItemModel {
  final String id;
  final String? code;
  final String restaurantId;
  final String? restaurantName;
  final String? restaurantDeliveryTime;
  final double? restaurantRating;
  final String name;
  final String? category;
  final double price;
  final String? description;
  final bool isAvailable;
  final String? tag;
  final String? image;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FoodItemModel({
    required this.id,
    this.code,
    required this.restaurantId,
    this.restaurantName,
    this.restaurantDeliveryTime,
    this.restaurantRating,
    required this.name,
    this.category,
    required this.price,
    this.description,
    this.isAvailable = true,
    this.tag,
    this.image,
    this.createdAt,
    this.updatedAt,
  });

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    String? rName;
    String? rTime;
    double? rRating;

    if (json['restaurant'] is Map) {
      final rMap = json['restaurant'] as Map;
      rName = rMap['name']?.toString();
      rTime = rMap['deliveryTime']?.toString();
      if (rMap['rating'] != null) {
        rRating = double.tryParse(rMap['rating'].toString());
      }
    } else if (json['restaurantName'] != null) {
      rName = json['restaurantName']?.toString();
    }

    return FoodItemModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString(),
      restaurantId: json['restaurantId']?.toString() ?? '',
      restaurantName: rName,
      restaurantDeliveryTime: rTime,
      restaurantRating: rRating,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString(),
      price: (json['price'] != null)
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0,
      description: json['description']?.toString(),
      isAvailable: json['isAvailable'] == true || json['isAvailable'] == 1,
      tag: json['tag']?.toString(),
      image: json['image']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  FoodItemModel copyWith({
    String? id,
    String? code,
    String? restaurantId,
    String? restaurantName,
    String? restaurantDeliveryTime,
    double? restaurantRating,
    String? name,
    String? category,
    double? price,
    String? description,
    bool? isAvailable,
    String? tag,
    String? image,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodItemModel(
      id: id ?? this.id,
      code: code ?? this.code,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantDeliveryTime: restaurantDeliveryTime ?? this.restaurantDeliveryTime,
      restaurantRating: restaurantRating ?? this.restaurantRating,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
      tag: tag ?? this.tag,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (code != null) 'code': code,
      'restaurantId': restaurantId,
      if (restaurantName != null) 'restaurantName': restaurantName,
      if (restaurantDeliveryTime != null) 'restaurantDeliveryTime': restaurantDeliveryTime,
      if (restaurantRating != null) 'restaurantRating': restaurantRating,
      'name': name,
      if (category != null) 'category': category,
      'price': price,
      if (description != null) 'description': description,
      'isAvailable': isAvailable,
      if (tag != null) 'tag': tag,
      if (image != null) 'image': image,
    };
  }
}
