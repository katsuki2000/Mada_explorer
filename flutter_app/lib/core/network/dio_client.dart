import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

/// Central Dio factory used everywhere in the data layer, so there is a
/// single place that configures base URL, timeouts and interceptors.
class DioClient {
  final TokenStorage tokenStorage;
  final void Function() onSessionExpired;

  DioClient({required this.tokenStorage, required this.onSessionExpired});

  Dio build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: ApiConstants.connectTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: ApiConstants.receiveTimeoutMs),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(AuthInterceptor(
      tokenStorage: tokenStorage,
      onRefreshFailed: onSessionExpired,
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint:
          (_) {}, // swap for a real logger; kept silent for release builds
    ));

    return dio;
  }
}
