import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/api_response.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient _client = ApiClient();

  // Get Customer Notifications (GET /api/v1/customer/notifications)
  Future<ApiResponse<List<NotificationModel>>> getNotifications({int page = 1, int limit = 20}) async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.customerNotifications,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          if (json is Map && json['notifications'] is List) {
            return (json['notifications'] as List)
                .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          if (json is List) {
            return json.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>)).toList();
          }
          return <NotificationModel>[];
        },
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Mark Single Notification as Read (PUT /api/v1/notifications/{id}/read)
  Future<ApiResponse<void>> markAsRead(String notificationId) async {
    try {
      final response = await _client.dio.put('${ApiEndpoints.notifications}/$notificationId/read');
      return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Mark All Notifications as Read (PUT /api/v1/notifications/read-all)
  Future<ApiResponse<void>> markAllAsRead() async {
    try {
      final response = await _client.dio.put(ApiEndpoints.markAllNotificationsRead);
      return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
