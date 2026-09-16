import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiEndpoints {
  // Dynamic default baseUrl depending on runtime platform:
  // - Android emulator uses 10.0.2.2 to access host machine's localhost
  // - Windows / macOS / Linux / Web uses localhost
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5000';
    } catch (_) {}
    return 'http://localhost:5000';
  }

  static const String liveBaseUrl = 'https://api.balerra.com';

  // Auth Endpoints (/api/v1/auth)
  static const String register = '/api/v1/auth/register';
  static const String login = '/api/v1/auth/login';
  static const String me = '/api/v1/auth/me';
  static const String changePassword = '/api/v1/auth/change-password';
  static const String fcmToken = '/api/v1/auth/fcm-token';
  static const String logout = '/api/v1/auth/logout';

  // Customer Deliveries & Profile (/api/v1/customer)
  static const String customerDeliveries = '/api/v1/customer/deliveries';
  static const String customerProfile = '/api/v1/customer/profile';
  static const String customerNotifications = '/api/v1/customer/notifications';

  // General Notification Endpoints (/api/v1/notifications)
  static const String notifications = '/api/v1/notifications';
  static const String markAllNotificationsRead = '/api/v1/notifications/read-all';

  // Restaurant & Food Menu Endpoints (/api/v1/restaurants, /api/v1/foods)
  static const String restaurants = '/api/v1/restaurants';
  static String restaurantDetails(String id) => '/api/v1/restaurants/$id';
  static const String foods = '/api/v1/foods';
  static const String customerFoodOrders = '/api/v1/customer/orders';
  static String customerFoodOrderDetails(String id) => '/api/v1/customer/orders/$id';
}

