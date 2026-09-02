import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  // Register Customer (POST /api/v1/auth/register)
  Future<ApiResponse<UserModel>> register({
    required String fullName,
    required String phoneNumber,
    String? email,
    required String password,
    String? address,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.register,
        data: {
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          if (email != null && email.isNotEmpty) 'email': email,
          'password': password,
          if (address != null && address.isNotEmpty) 'address': address,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        if (apiResponse.data!.token != null) {
          await StorageService.saveToken(apiResponse.data!.token!);
        }
        await StorageService.saveUser(apiResponse.data!);
      }

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Login Customer (POST /api/v1/auth/login)
  Future<ApiResponse<UserModel>> login({
    required String identifier, // Phone or Email
    required String password,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.login,
        data: {
          'identifier': identifier,
          'password': password,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        if (apiResponse.data!.token != null) {
          await StorageService.saveToken(apiResponse.data!.token!);
        }
        await StorageService.saveUser(apiResponse.data!);
      }

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Get Current Authenticated User (GET /api/v1/auth/me)
  Future<ApiResponse<UserModel>> getMe() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.me);
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        await StorageService.saveUser(apiResponse.data!);
      }

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Change Password (PUT /api/v1/auth/change-password)
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _client.dio.put(
        ApiEndpoints.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Register / Update FCM Device Push Token (PUT /api/v1/auth/fcm-token)
  Future<ApiResponse<void>> updateFcmToken(String fcmToken) async {
    try {
      final response = await _client.dio.put(
        ApiEndpoints.fcmToken,
        data: {
          'fcmToken': fcmToken,
        },
      );
      return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Get Customer Profile (GET /api/v1/customer/profile)
  Future<ApiResponse<UserModel>> getProfile() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.customerProfile);
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        await StorageService.saveUser(apiResponse.data!);
      }

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Update Customer Profile (PUT /api/v1/customer/profile)
  Future<ApiResponse<UserModel>> updateProfile({
    required String fullName,
    String? email,
    String? address,
    String? phoneNumber,
  }) async {
    try {
      final response = await _client.dio.put(
        ApiEndpoints.customerProfile,
        data: {
          'fullName': fullName,
          if (email != null) 'email': email,
          if (address != null) 'address': address,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        await StorageService.saveUser(apiResponse.data!);
      }

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Logout (POST /api/v1/auth/logout)
  Future<void> logout() async {
    try {
      await _client.dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await StorageService.clearSession();
    }
  }
}
