class UserModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String? address;
  final DateTime? createdAt;
  final String? token;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.address,
    this.createdAt,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Backend can return data either flat or nested inside 'customer', 'user', or 'data'
    Map<String, dynamic> data = json;
    if (json.containsKey('customer') && json['customer'] is Map<String, dynamic>) {
      data = json['customer'] as Map<String, dynamic>;
    } else if (json.containsKey('user') && json['user'] is Map<String, dynamic>) {
      data = json['user'] as Map<String, dynamic>;
    }

    final token = json['token'] as String? ?? (data['token'] as String?);

    return UserModel(
      id: data['id']?.toString() ?? data['_id']?.toString() ?? '',
      fullName: data['fullName'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      email: data['email'] as String?,
      address: data['address'] as String?,
      createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt'].toString()) : null,
      token: token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'createdAt': createdAt?.toIso8601String(),
      'token': token,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? address,
    DateTime? createdAt,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      token: token ?? this.token,
    );
  }
}
