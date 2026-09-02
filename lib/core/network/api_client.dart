import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import 'api_interceptor.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: AppConstants.connectTimeoutSeconds),
        receiveTimeout: const Duration(seconds: AppConstants.receiveTimeoutSeconds),
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(ApiInterceptor());
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
      ),
    );
  }

  // Update base URL if needed dynamically
  void setBaseUrl(String url) {
    dio.options.baseUrl = url;
  }

  // Helper method to format Dio exceptions into user-friendly strings
  static String handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        if (data is Map && data.containsKey('message')) {
          return data['message'].toString();
        }
        return 'Server error (${error.response?.statusCode}). Please try again later.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Please verify your internet connection.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
