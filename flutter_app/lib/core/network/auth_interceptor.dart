import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'token_storage.dart';

/// Injects the current access token into every request and transparently
/// refreshes it on a 401 response, retrying the original request once.
///
/// Uses QueuedInterceptor so that if several requests fail at once with a
/// 401, only a single /auth/refresh call is fired and the others wait for it.
class AuthInterceptor extends QueuedInterceptor {
  final TokenStorage tokenStorage;
  final Dio _refreshDio; // separate Dio instance: no auth header, no retry loop
  final void Function() onRefreshFailed; // e.g. force logout

  AuthInterceptor({
    required this.tokenStorage,
    required this.onRefreshFailed,
  }) : _refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenStorage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRetry = err.requestOptions.extra['retried'] == true;

    if (isUnauthorized && !isRetry) {
      try {
        final refreshToken = await tokenStorage.refreshToken;
        if (refreshToken == null) throw Exception('No refresh token');

        final response = await _refreshDio.post(
          ApiConstants.refresh,
          data: {'refreshToken': refreshToken},
        );

        final newAccess = response.data['accessToken'] as String;
        final newRefresh = response.data['refreshToken'] as String;
        await tokenStorage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);

        // Retry the original request with the fresh token.
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccess';
        retryOptions.extra['retried'] = true;

        final cloneDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
        final retryResponse = await cloneDio.fetch(retryOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        await tokenStorage.clear();
        onRefreshFailed();
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}
