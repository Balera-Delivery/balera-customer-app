class AppConstants {
  static const String appName = 'Balerra Delivery';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyToken = 'auth_token';
  static const String keyUser = 'user_data';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyRememberMe = 'remember_me';

  // Timeouts (Increased to 30s connect / 45s receive to prevent timeout aborts)
  static const int connectTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 45;

  // Delivery Statuses (Backend Uppercase Enums)
  static const String statusPending = 'PENDING';
  static const String statusAssigned = 'ASSIGNED';
  static const String statusAccepted = 'ACCEPTED';
  static const String statusArrivedAtPickup = 'ARRIVED_AT_PICKUP';
  static const String statusPickedUp = 'PICKED_UP';
  static const String statusOnTheWay = 'ON_THE_WAY';
  static const String statusDelivered = 'DELIVERED';
  static const String statusCompleted = 'COMPLETED';
  static const String statusCancelled = 'CANCELLED';

  // Human-readable status label helper
  static String formatStatus(String? status) {
    if (status == null || status.isEmpty) return 'Pending';
    final upper = status.toUpperCase().replaceAll('-', '_');
    switch (upper) {
      case 'PENDING':
        return 'Pending';
      case 'ASSIGNED':
        return 'Assigned';
      case 'ACCEPTED':
        return 'Accepted';
      case 'ARRIVED_AT_PICKUP':
        return 'Arrived at Pickup';
      case 'PICKED_UP':
        return 'Picked Up';
      case 'ON_THE_WAY':
        return 'On the Way';
      case 'DELIVERED':
        return 'Delivered';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
      case 'CANCELED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  static bool isOngoing(String? status) {
    if (status == null) return false;
    final upper = status.toUpperCase().replaceAll('-', '_');
    return upper != 'COMPLETED' && upper != 'DELIVERED' && upper != 'CANCELLED' && upper != 'CANCELED';
  }

  static bool isCompleted(String? status) {
    if (status == null) return false;
    final upper = status.toUpperCase().replaceAll('-', '_');
    return upper == 'COMPLETED' || upper == 'DELIVERED';
  }

  static bool isCancelled(String? status) {
    if (status == null) return false;
    final upper = status.toUpperCase().replaceAll('-', '_');
    return upper == 'CANCELLED' || upper == 'CANCELED';
  }

  // Item Categories
  static const List<String> itemTypes = [
    'Documents & Letters',
    'Parcel / Box',
    'Electronics & Gadgets',
    'Clothing & Fashion',
    'Food & Groceries',
    'Fragile Items',
    'Medicine & Health',
    'Other'
  ];
}
