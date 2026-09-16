import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/api_response.dart';
import '../models/food_item_model.dart';
import '../models/restaurant_model.dart';

class RestaurantService {
  final ApiClient _client = ApiClient();

  // Get active restaurants & hotels (GET /api/v1/restaurants)
  Future<ApiResponse<List<RestaurantModel>>> getRestaurants({
    String? search,
    String? category,
    String? cuisineType,
  }) async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.restaurants,
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (category != null && category.trim().isNotEmpty && category != 'All') 'category': category.trim(),
          if (cuisineType != null && cuisineType.trim().isNotEmpty) 'cuisineType': cuisineType.trim(),
        },
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          if (json is Map && json['restaurants'] is List) {
            return (json['restaurants'] as List)
                .map((item) => RestaurantModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          if (json is List) {
            return json
                .map((item) => RestaurantModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <RestaurantModel>[];
        },
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Get restaurant details and full menu (GET /api/v1/restaurants/{id})
  Future<ApiResponse<RestaurantModel>> getRestaurantDetails(String restaurantId) async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.restaurantDetails(restaurantId),
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          if (json is Map && json['restaurant'] != null) {
            return RestaurantModel.fromJson(json['restaurant'] as Map<String, dynamic>);
          }
          return RestaurantModel.fromJson(json as Map<String, dynamic>);
        },
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Search/get food dishes across restaurants (GET /api/v1/foods)
  Future<ApiResponse<List<FoodItemModel>>> getFoods({
    String? search,
    String? restaurantId,
    String? category,
    bool? isAvailable,
  }) async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.foods,
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (restaurantId != null && restaurantId.trim().isNotEmpty) 'restaurantId': restaurantId.trim(),
          if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
          if (isAvailable != null) 'isAvailable': isAvailable,
        },
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          if (json is Map && json['foods'] is List) {
            return (json['foods'] as List)
                .map((item) => FoodItemModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          if (json is List) {
            return json
                .map((item) => FoodItemModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return <FoodItemModel>[];
        },
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiClient.handleDioError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
