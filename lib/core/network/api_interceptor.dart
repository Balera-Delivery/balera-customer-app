import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
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
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Automatic Android host fallback (127.0.0.1 <-> 10.0.2.2) on connection error
    if (err.type == DioExceptionType.connectionError && !kIsWeb) {
      try {
        final uri = err.requestOptions.uri;
        final alreadyRetried = err.requestOptions.extra['retried_fallback'] == true;
        if (!alreadyRetried && (uri.host == '127.0.0.1' || uri.host == '10.0.2.2')) {
          final alternateHost = uri.host == '127.0.0.1' ? '10.0.2.2' : '127.0.0.1';
          final newPath = err.requestOptions.path.replaceFirst(uri.host, alternateHost);
          final newBaseUrl = err.requestOptions.baseUrl.replaceFirst(uri.host, alternateHost);

          ApiEndpoints.customBaseUrl = newBaseUrl;

          final retryDio = Dio(
            BaseOptions(
              baseUrl: newBaseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 15),
              responseType: err.requestOptions.responseType,
            ),
          );

          final newHeaders = Map<String, dynamic>.from(err.requestOptions.headers);
          final newExtra = Map<String, dynamic>.from(err.requestOptions.extra);
          newExtra['retried_fallback'] = true;

          final response = await retryDio.request(
            newPath.startsWith('http') ? newPath : err.requestOptions.path,
            data: err.requestOptions.data,
            queryParameters: err.requestOptions.queryParameters,
            options: Options(
              method: err.requestOptions.method,
              headers: newHeaders,
              extra: newExtra,
            ),
          );
          return handler.resolve(response);
        }
      } catch (_) {
        // Proceed with original error handler below if fallback fails
      }
    }

    // Only handle 401 Unauthorized globally if token expired on an authenticated endpoint
    // Never clear session on login/register attempt failures or unauthenticated requests!
    final path = err.requestOptions.path;
    final isAuthEndpoint = path.contains('/auth/login') || path.contains('/auth/register');

    if (err.response?.statusCode == 401 && !isAuthEndpoint && err.requestOptions.headers.containsKey('Authorization')) {
      StorageService.clearSession();
      StorageService.onSessionExpired?.call();
    }
    return handler.next(err);
  }
}
