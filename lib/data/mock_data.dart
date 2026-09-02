import '../core/constants/app_constants.dart';
import '../models/delivery_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

class MockData {
  // Current Logged-in Customer
  static final UserModel defaultUser = UserModel(
    id: 'USR-88219',
    fullName: 'Faisa Mohammed',
    phoneNumber: '0912345678',
    email: 'faisa.mohammed@balera.com',
    address: 'Bole, Addis Ababa, Ethiopia',
    createdAt: DateTime.now().subtract(const Duration(days: 45)),
    token: 'mock_jwt_token_balera_secure_session',
  );

  // Active Rider
  static final RiderInfo defaultRider = RiderInfo(
    id: 'RDR-0042',
    fullName: 'Abdi Tesfaye',
    phoneNumber: '0922334455',
  );

  // Deliveries List matching the 20 screens
  static final List<DeliveryModel> initialDeliveries = [
    DeliveryModel(
      id: 'DLV-00126',
      customerId: 'USR-88219',
      riderId: 'RDR-0042',
      rider: defaultRider,
      pickupLocation: 'Bole, Addis Ababa',
      destination: 'Piazza, Addis Ababa',
      itemType: 'Small Package',
      itemDescription: 'Documents and keys in sealed pouch',
      receiverName: 'Abebe Kebede',
      receiverPhone: '0911556677',
      instructions: 'Handle carefully. Call before delivery.',
      status: AppConstants.statusOnTheWay,
      otpCode: '482913',
      createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      pickupLat: 8.9953,
      pickupLng: 38.7889,
      destinationLat: 9.0348,
      destinationLng: 38.7525,
    ),
    DeliveryModel(
      id: 'DLV-00120',
      customerId: 'USR-88219',
      riderId: 'RDR-0019',
      rider: RiderInfo(id: 'RDR-0019', fullName: 'Dawit Bekele', phoneNumber: '0933112233'),
      pickupLocation: 'Megenagna, Addis Ababa',
      destination: 'Bole, Addis Ababa',
      itemType: 'Documents',
      itemDescription: 'Contract agreements',
      receiverName: 'Sara Hailu',
      receiverPhone: '0912889900',
      instructions: 'Deliver to office 4B',
      status: AppConstants.statusCompleted,
      otpCode: '391024',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DeliveryModel(
      id: 'DLV-00115',
      customerId: 'USR-88219',
      riderId: 'RDR-0033',
      rider: RiderInfo(id: 'RDR-0033', fullName: 'Yonas Tadesse', phoneNumber: '0944778899'),
      pickupLocation: 'Sarbet, Addis Ababa',
      destination: 'Kazanchis, Addis Ababa',
      itemType: 'Electronics',
      itemDescription: 'Laptop charger and wireless mouse',
      receiverName: 'Helen Girma',
      receiverPhone: '0911334455',
      instructions: 'Leave at reception',
      status: AppConstants.statusCompleted,
      otpCode: '827419',
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
    ),
    DeliveryModel(
      id: 'DLV-00110',
      customerId: 'USR-88219',
      pickupLocation: 'Piazza, Addis Ababa',
      destination: 'Gerji, Addis Ababa',
      itemType: 'Fragile Box',
      itemDescription: 'Glassware sample',
      receiverName: 'Kidus Yohannes',
      receiverPhone: '0911009988',
      instructions: 'Very fragile',
      status: AppConstants.statusCancelled,
      createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    DeliveryModel(
      id: 'DLV-00105',
      customerId: 'USR-88219',
      riderId: 'RDR-0042',
      rider: defaultRider,
      pickupLocation: 'Bole, Addis Ababa',
      destination: 'CMC, Addis Ababa',
      itemType: 'Parcel',
      itemDescription: 'Gift package',
      receiverName: 'Marta Assefa',
      receiverPhone: '0911667788',
      instructions: 'Deliver before 5 PM',
      status: AppConstants.statusCompleted,
      otpCode: '109283',
      createdAt: DateTime.now().subtract(const Duration(days: 4, hours: 6)),
      updatedAt: DateTime.now().subtract(const Duration(days: 4, hours: 5)),
    ),
  ];

  // Notifications matching screen 19
  static final List<NotificationModel> initialNotifications = [
    NotificationModel(
      id: 'NTF-005',
      userId: 'USR-88219',
      userRole: 'Customer',
      title: 'Delivery Completed',
      message: 'Your delivery #DLV-00126 was completed successfully.',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    NotificationModel(
      id: 'NTF-004',
      userId: 'USR-88219',
      userRole: 'Customer',
      title: 'Rider Has Arrived',
      message: 'Your rider has arrived at the destination.',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    NotificationModel(
      id: 'NTF-003',
      userId: 'USR-88219',
      userRole: 'Customer',
      title: 'Package Picked Up',
      message: 'Your package has been collected and is on the way.',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    NotificationModel(
      id: 'NTF-002',
      userId: 'USR-88219',
      userRole: 'Customer',
      title: 'Delivery OTP',
      message: 'Your delivery verification code is 482913.',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    NotificationModel(
      id: 'NTF-001',
      userId: 'USR-88219',
      userRole: 'Customer',
      title: 'Rider Assigned',
      message: 'Your rider Abdi Tesfaye has been assigned to #DLV-00126.',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];
}
