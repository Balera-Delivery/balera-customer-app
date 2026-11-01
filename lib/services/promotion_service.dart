import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';

class PromotionValidationResult {
  final bool valid;
  final String message;
  final double discountAmount;
  final double finalAmount;
  final String? promoCode;
  final String? promoTitle;

  const PromotionValidationResult({
    required this.valid,
    required this.message,
    this.discountAmount = 0.0,
    this.finalAmount = 0.0,
    this.promoCode,
    this.promoTitle,
  });
}

class PromotionService {
  final ApiClient _client = ApiClient();

  Future<PromotionValidationResult> validatePromo({
    required String code,
    required double orderAmount,
    double deliveryFee = 100.0,
    String? deliveryType,
    String? restaurantId,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.validatePromotion,
        data: {
          'code': code.trim().toUpperCase(),
          'orderAmount': orderAmount,
          'deliveryFee': deliveryFee,
          'deliveryType': deliveryType,
          if (restaurantId != null) 'restaurantId': restaurantId,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null && data['valid'] == true) {
        return PromotionValidationResult(
          valid: true,
          message: data['message'] ?? 'Promo applied successfully!',
          discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0.0,
          finalAmount: (data['finalAmount'] as num?)?.toDouble() ?? orderAmount,
          promoCode: data['promotion']?['code'] ?? code.toUpperCase(),
          promoTitle: data['promotion']?['title'],
        );
      }
      return PromotionValidationResult(
        valid: false,
        message: response.data['message'] ?? 'Invalid promo code.',
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Promo code invalid or expired.';
      return PromotionValidationResult(valid: false, message: msg);
    } catch (_) {
      return const PromotionValidationResult(valid: false, message: 'Could not validate promo code.');
    }
  }
}
