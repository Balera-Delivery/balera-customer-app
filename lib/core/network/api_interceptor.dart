import 'package:dio/dio.dart';
import '../../services/storage_service.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';

    // Auto-generate Idempotency-Key for mutating actions if not already provided
    if (['POST', 'PUT', 'PATCH'].contains(options.method.toUpperCase())) {
      if (!options.headers.containsKey('Idempotency-Key')) {
        final randomPart = (DateTime.now().microsecondsSinceEpoch ^ (options.data?.hashCode ?? 0)).abs().toRadixString(36);
        options.headers['Idempotency-Key'] = 'cust_${DateTime.now().millisecondsSinceEpoch}_$randomPart';
      }
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 Unauthorized globally if token expired
    if (err.response?.statusCode == 401) {
      StorageService.clearSession();
    }
    return handler.next(err);
  }
}
