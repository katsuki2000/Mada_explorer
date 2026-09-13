import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mada_explorer/core/network/auth_interceptor.dart';
import 'package:mada_explorer/core/network/token_storage.dart';

class MockDio extends Mock implements Dio {}

class MockTokenStorage extends Mock implements TokenStorage {}

/// Captures what the interceptor does instead of relying on the protected
/// `future` completer used internally by dio's real handler.
class RecordingErrorHandler extends ErrorInterceptorHandler {
  Response? resolvedResponse;
  DioException? forwardedError;

  @override
  void resolve(Response response) {
    resolvedResponse = response;
  }

  @override
  void next(DioException error) {
    forwardedError = error;
  }
}

void main() {
  late MockDio plainDio;
  late MockTokenStorage tokenStorage;
  late bool forceLogoutCalled;
  late AuthInterceptor interceptor;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/parks'));
  });

  setUp(() {
    plainDio = MockDio();
    tokenStorage = MockTokenStorage();
    forceLogoutCalled = false;
    interceptor = AuthInterceptor(
      tokenStorage: tokenStorage,
      onRefreshFailed: () => forceLogoutCalled = true,
      plainDio: plainDio,
    );
  });

  RequestOptions originalRequest() => RequestOptions(path: '/parks', extra: {});

  DioException unauthorizedError(RequestOptions request) => DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 401),
        type: DioExceptionType.badResponse,
      );

  group('onRequest', () {
    test('injects the Authorization header when an access token exists',
        () async {
      when(() => tokenStorage.accessToken)
          .thenAnswer((_) async => 'access-abc');
      final options = RequestOptions(path: '/parks');
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);
      await Future<void>.delayed(Duration.zero);

      expect(options.headers['Authorization'], 'Bearer access-abc');
    });
  });

  group('onError - 401 handling', () {
    test('refreshes the token and retries the original request once', () async {
      final request = originalRequest();
      final error = unauthorizedError(request);
      final handler = RecordingErrorHandler();

      when(() => tokenStorage.refreshToken)
          .thenAnswer((_) async => 'old-refresh');
      when(() => plainDio.post('/auth/refresh', data: any(named: 'data')))
          .thenAnswer(
        (_) async => Response(
          requestOptions: request,
          statusCode: 200,
          data: {'accessToken': 'new-access', 'refreshToken': 'new-refresh'},
        ),
      );
      when(() => tokenStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});
      final retriedResponse = Response(
          requestOptions: request, statusCode: 200, data: {'ok': true});
      when(() => plainDio.fetch(any()))
          .thenAnswer((_) async => retriedResponse);

      interceptor.onError(error, handler);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      verify(() => tokenStorage.saveTokens(
          accessToken: 'new-access', refreshToken: 'new-refresh')).called(1);
      expect(request.headers['Authorization'], 'Bearer new-access');
      expect(request.extra['retried'], true);
      expect(handler.resolvedResponse, retriedResponse);
      expect(handler.forwardedError, isNull);
      expect(forceLogoutCalled, isFalse);
    });

    test(
        'clears the session and forces logout when the refresh call itself fails',
        () async {
      final request = originalRequest();
      final error = unauthorizedError(request);
      final handler = RecordingErrorHandler();

      when(() => tokenStorage.refreshToken)
          .thenAnswer((_) async => 'old-refresh');
      when(() => plainDio.post('/auth/refresh', data: any(named: 'data')))
          .thenThrow(DioException(
              requestOptions: request, type: DioExceptionType.connectionError));
      when(() => tokenStorage.clear()).thenAnswer((_) async {});

      interceptor.onError(error, handler);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      verify(() => tokenStorage.clear()).called(1);
      expect(forceLogoutCalled, isTrue);
      expect(handler.forwardedError, error);
      expect(handler.resolvedResponse, isNull);
      verifyNever(() => plainDio.fetch(any()));
    });

    test('forces logout immediately when there is no refresh token to use',
        () async {
      final request = originalRequest();
      final error = unauthorizedError(request);
      final handler = RecordingErrorHandler();

      when(() => tokenStorage.refreshToken).thenAnswer((_) async => null);
      when(() => tokenStorage.clear()).thenAnswer((_) async {});

      interceptor.onError(error, handler);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => plainDio.post(any(), data: any(named: 'data')));
      verify(() => tokenStorage.clear()).called(1);
      expect(forceLogoutCalled, isTrue);
      expect(handler.forwardedError, error);
    });

    test('does not attempt a refresh for errors that are not 401', () async {
      final request = originalRequest();
      final error = DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 500),
        type: DioExceptionType.badResponse,
      );
      final handler = RecordingErrorHandler();

      interceptor.onError(error, handler);
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => tokenStorage.refreshToken);
      expect(handler.forwardedError, error);
    });

    test(
        'does not retry twice: a 401 already marked as retried is forwarded as-is',
        () async {
      final request = RequestOptions(path: '/parks', extra: {'retried': true});
      final error = unauthorizedError(request);
      final handler = RecordingErrorHandler();

      interceptor.onError(error, handler);
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => tokenStorage.refreshToken);
      expect(handler.forwardedError, error);
    });
  });
}
