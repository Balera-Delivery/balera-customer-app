import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiEndpoints {
  // Optional override if connecting over local Wi-Fi (e.g. 'http://192.168.1.50:5000')
  static String? customBaseUrl;

  // Dynamic default baseUrl depending on runtime platform:
  // - Physical Android device via USB: http://127.0.0.1:5000 (after `adb reverse tcp:5000 tcp:5000`)
  // - Android emulator: works with both 127.0.0.1 (via adb reverse) and 10.0.2.2
  // - Windows / macOS / Linux / Web: http://localhost:5000
  static String get baseUrl {
    if (customBaseUrl != null) return customBaseUrl!;
    if (kIsWeb) return 'http://localhost:5000';
    try {
      if (Platform.isAndroid) return 'http://127.0.0.1:5000';
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

