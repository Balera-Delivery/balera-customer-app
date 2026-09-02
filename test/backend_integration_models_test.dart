import 'package:flutter_test/flutter_test.dart';
import 'package:balera_customer_app/models/user_model.dart';
import 'package:balera_customer_app/models/delivery_model.dart';
import 'package:balera_customer_app/models/notification_model.dart';
import 'package:balera_customer_app/core/constants/app_constants.dart';

void main() {
  group('Backend Swagger Integration Models Tests', () {
    test('UserModel parses backend auth customer response', () {
      final json = {
        'customer': {
          'id': 'cust-12345',
          'fullName': 'Abebe Bikila',
          'phoneNumber': '0911223344',
          'email': 'abebe@example.com',
          'address': 'Bole, Addis Ababa',
          'status': 'ACTIVE',
          'createdAt': '2026-08-27T01:00:00.000Z',
        },
        'token': 'jwt_mock_token_abc_123',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'cust-12345');
      expect(user.fullName, 'Abebe Bikila');
      expect(user.phoneNumber, '0911223344');
      expect(user.email, 'abebe@example.com');
      expect(user.address, 'Bole, Addis Ababa');
      expect(user.token, 'jwt_mock_token_abc_123');
    });

    test('UserModel parses backend GET /api/v1/auth/me user response', () {
      final json = {
        'user': {
          'id': 'usr-me-999',
          'fullName': 'Tirunesh Dibaba',
          'phoneNumber': '0922334455',
          'address': 'Kazanchis, Addis Ababa',
        },
        'role': 'CUSTOMER',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'usr-me-999');
      expect(user.fullName, 'Tirunesh Dibaba');
      expect(user.phoneNumber, '0922334455');
      expect(user.address, 'Kazanchis, Addis Ababa');
    });

    test('DeliveryModel parses backend delivery JSON with trackingCode and coordinates', () {
      final json = {
        'id': 'dlv-778899',
        'trackingCode': 'BAL-2026-X89',
        'customerId': 'cust-123',
        'pickupLocation': 'Bole Atlas',
        'pickupLatitude': 8.9953,
        'pickupLongitude': 38.7889,
        'destination': 'Piazza Church',
        'destinationLatitude': 9.0348,
        'destinationLongitude': 38.7525,
        'itemType': 'Electronics',
        'itemDescription': 'Laptop inside bag',
        'receiverName': 'Derartu Tulu',
        'receiverPhone': '0933445566',
        'specialInstructions': 'Call upon arrival',
        'status': 'PENDING',
        'otpCode': '654321',
        'createdAt': '2026-08-27T01:30:00.000Z',
        'updatedAt': '2026-08-27T01:35:00.000Z',
      };

      final delivery = DeliveryModel.fromJson(json);

      expect(delivery.id, 'dlv-778899');
      expect(delivery.trackingCode, 'BAL-2026-X89');
      expect(delivery.pickupLocation, 'Bole Atlas');
      expect(delivery.pickupLat, 8.9953);
      expect(delivery.pickupLng, 38.7889);
      expect(delivery.destination, 'Piazza Church');
      expect(delivery.destinationLat, 9.0348);
      expect(delivery.destinationLng, 38.7525);
      expect(delivery.itemType, 'Electronics');
      expect(delivery.instructions, 'Call upon arrival');
      expect(delivery.status, 'PENDING');
      expect(delivery.otpCode, '654321');
      expect(AppConstants.isOngoing(delivery.status), isTrue);
      expect(AppConstants.isCompleted(delivery.status), isFalse);
    });

    test('LiveTrackingData parses backend GET /api/v1/customer/deliveries/{id}/track response', () {
      final json = {
        'deliveryId': 'dlv-778899',
        'trackingCode': 'BAL-2026-X89',
        'status': 'ON_THE_WAY',
        'pickup': {
          'address': 'Bole Medhanealem',
          'latitude': 8.9953,
          'longitude': 38.7889,
        },
        'destination': {
          'address': 'Meskel Square',
          'latitude': 9.0100,
          'longitude': 38.7600,
        },
        'assignedRider': {
          'id': 'rdr-111',
          'fullName': 'Haile Gebrselassie',
          'phoneNumber': '0944556677',
          'vehicleType': 'Motorcycle',
          'plateNumber': 'AA 3-12345',
        },
      };

      final tracking = LiveTrackingData.fromJson(json);

      expect(tracking.deliveryId, 'dlv-778899');
      expect(tracking.trackingCode, 'BAL-2026-X89');
      expect(tracking.status, 'ON_THE_WAY');
      expect(tracking.pickupAddress, 'Bole Medhanealem');
      expect(tracking.pickupLat, 8.9953);
      expect(tracking.destinationAddress, 'Meskel Square');
      expect(tracking.destinationLat, 9.0100);
      expect(tracking.rider, isNotNull);
      expect(tracking.rider!.fullName, 'Haile Gebrselassie');
      expect(tracking.rider!.phoneNumber, '0944556677');
      expect(tracking.rider!.vehicleInfo, 'Motorcycle • AA 3-12345');
    });

    test('NotificationModel parses backend customer notifications response', () {
      final json = {
        'id': 'notif-001',
        'customerId': 'cust-123',
        'userRole': 'CUSTOMER',
        'title': 'Rider Assigned',
        'message': 'Rider Haile is heading to pickup',
        'isRead': false,
        'metadata': {
          'deliveryId': 'dlv-778899',
          'trackingCode': 'BAL-2026-X89',
        },
        'createdAt': '2026-08-27T01:45:00.000Z',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.id, 'notif-001');
      expect(notif.title, 'Rider Assigned');
      expect(notif.message, 'Rider Haile is heading to pickup');
      expect(notif.isRead, isFalse);
      expect(notif.deliveryId, 'dlv-778899');
      expect(notif.trackingCode, 'BAL-2026-X89');
    });

    test('AppConstants status helper functions accurately classify statuses', () {
      expect(AppConstants.isOngoing('PENDING'), isTrue);
      expect(AppConstants.isOngoing('ASSIGNED'), isTrue);
      expect(AppConstants.isOngoing('ON_THE_WAY'), isTrue);
      expect(AppConstants.isOngoing('COMPLETED'), isFalse);
      expect(AppConstants.isOngoing('DELIVERED'), isFalse);
      expect(AppConstants.isOngoing('CANCELLED'), isFalse);

      expect(AppConstants.isCompleted('COMPLETED'), isTrue);
      expect(AppConstants.isCompleted('DELIVERED'), isTrue);

      expect(AppConstants.isCancelled('CANCELLED'), isTrue);

      expect(AppConstants.formatStatus('ON_THE_WAY'), 'On the Way');
      expect(AppConstants.formatStatus('ARRIVED_AT_PICKUP'), 'Arrived at Pickup');
      expect(AppConstants.formatStatus('PENDING'), 'Pending');
    });
  });
}
