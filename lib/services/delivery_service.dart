import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/api_response.dart';
import '../models/delivery_model.dart';

class DeliveryService {
  final ApiClient _client = ApiClient();

  // Create Delivery Request (POST /api/v1/customer/deliveries)
  Future<ApiResponse<DeliveryModel>> createDelivery({
    required String pickupLocation,
    required String destination,
    required String itemType,
    required String itemDescription,
    required String receiverName,
    required String receiverPhone,
    String? instructions,
    String? paymentMethod,
    String? receiptUrl,
    double? pickupLat,
    double? pickupLng,
    double? destinationLat,
    double? destinationLng,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.customerDeliveries,
        data: {
          'pickupLocation': pickupLocation,
          'destination': destination,
          'itemType': itemType,
          'itemDescription': itemDescription,
          'receiverName': receiverName,
          'receiverPhone': receiverPhone,
          if (instructions != null && instructions.isNotEmpty) 'specialInstructions': instructions,
          if (paymentMethod != null && paymentMethod.isNotEmpty) 'paymentMethod': paymentMethod,
          if (receiptUrl != null && receiptUrl.isNotEmpty) 'receiptUrl': receiptUrl,
          if (pickupLat != null) 'pickupLatitude': pickupLat,
          if (pickupLng != null) 'pickupLongitude': pickupLng,
          if (destinationLat != null) 'destinationLatitude': destinationLat,
          if (destinationLng != null) 'destinationLongitude': destinationLng,
        },
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DeliveryModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Get Customer Deliveries with filters and pagination (GET /api/v1/customer/deliveries)
  Future<ApiResponse<List<DeliveryModel>>> getDeliveries({
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.customerDeliveries,
        queryParameters: {
          if (status != null && status.isNotEmpty && status.toUpperCase() != 'ALL') 'status': status.toUpperCase(),
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          if (json is Map && json['deliveries'] is List) {
            return (json['deliveries'] as List)
                .map((item) => DeliveryModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          if (json is List) {
            return json.map((item) => DeliveryModel.fromJson(item as Map<String, dynamic>)).toList();
          }
          return <DeliveryModel>[];
        },
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Get Delivery by ID (GET /api/v1/customer/deliveries/{id})
  Future<ApiResponse<DeliveryModel>> getDeliveryDetails(String deliveryId) async {
    try {
      final response = await _client.dio.get('${ApiEndpoints.customerDeliveries}/$deliveryId');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DeliveryModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Get Live GPS Tracking Data (GET /api/v1/customer/deliveries/{id}/track)
  Future<ApiResponse<LiveTrackingData>> getLiveTracking(String deliveryId) async {
    try {
      final response = await _client.dio.get('${ApiEndpoints.customerDeliveries}/$deliveryId/track');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => LiveTrackingData.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Get Delivery Completion 6-Digit OTP (GET /api/v1/customer/deliveries/{id}/otp)
  Future<ApiResponse<String>> getDeliveryOtp(String deliveryId) async {
    try {
      final response = await _client.dio.get('${ApiEndpoints.customerDeliveries}/$deliveryId/otp');

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          if (json is Map && json['otpCode'] != null) {
            return json['otpCode'].toString();
          }
          return '';
        },
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Cancel Delivery Request (POST /api/v1/customer/deliveries/{id}/cancel)
  Future<ApiResponse<void>> cancelDelivery(String deliveryId, {String? reason}) async {
    try {
      final response = await _client.dio.post(
        '${ApiEndpoints.customerDeliveries}/$deliveryId/cancel',
        data: {
          'reason': reason ?? 'Cancelled by customer',
        },
      );

      return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
