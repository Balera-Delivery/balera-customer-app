import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';

class PromotionModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final String promotionType;
  final String discountType;
  final double discountValue;
  final double? maxDiscount;
  final double minOrderAmount;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  const PromotionModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.promotionType,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    required this.minOrderAmount,
    required this.isActive,
    this.startDate,
    this.endDate,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      promotionType: json['promotionType']?.toString() ?? 'PROMO_CODE',
      discountType: json['discountType']?.toString() ?? 'PERCENTAGE',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble(),
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] == true,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
    );
  }
}

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

  Future<List<PromotionModel>> getActivePromotions() async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.promotions,
        queryParameters: {'isActive': 'true'},
      );
      final rawList = response.data['data'] as List<dynamic>?;
      if (rawList == null) return [];
      final now = DateTime.now();
      return rawList.map((item) => PromotionModel.fromJson(item as Map<String, dynamic>)).where((p) {
        if (!p.isActive) return false;
        if (p.startDate != null && now.isBefore(p.startDate!)) return false;
        if (p.endDate != null && now.isAfter(p.endDate!)) return false;
        return true;
      }).toList();
    } catch (_) {
      // If endpoint is unreachable or no promotions are configured in admin yet, return empty list
      return [];
    }
  }

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
