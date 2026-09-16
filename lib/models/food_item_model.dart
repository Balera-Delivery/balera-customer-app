class FoodItemModel {
  final String id;
  final String? code;
  final String restaurantId;
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
    return FoodItemModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString(),
      restaurantId: json['restaurantId']?.toString() ?? '',
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (code != null) 'code': code,
      'restaurantId': restaurantId,
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
