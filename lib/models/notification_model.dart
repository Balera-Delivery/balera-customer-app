class NotificationModel {
  final String id;
  final String userId;
  final String userRole;
  final String title;
  final String message;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.userRole,
    required this.title,
    required this.message,
    required this.isRead,
    this.metadata,
    this.createdAt,
  });

  String? get deliveryId => metadata?['deliveryId']?.toString();
  String? get trackingCode => metadata?['trackingCode']?.toString();

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['customerId']?.toString() ?? json['userId']?.toString() ?? '',
      userRole: json['userRole'] as String? ?? 'CUSTOMER',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userRole': userRole,
      'title': title,
      'message': message,
      'isRead': isRead,
      'metadata': metadata,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? userRole,
    String? title,
    String? message,
    bool? isRead,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
