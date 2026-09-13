import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mada_explorer/core/error/exceptions.dart';
import 'package:mada_explorer/core/error/failures.dart';
import 'package:mada_explorer/core/network/network_info.dart';
import 'package:mada_explorer/core/network/token_storage.dart';
import 'package:mada_explorer/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:mada_explorer/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mada_explorer/features/auth/data/models/auth_response_model.dart';
import 'package:mada_explorer/features/auth/data/models/user_model.dart';
import 'package:mada_explorer/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource remoteDataSource;
  late MockAuthLocalDataSource localDataSource;
  late MockTokenStorage tokenStorage;
  late MockNetworkInfo networkInfo;

  setUpAll(() {
    registerFallbackValue(const UserModel(id: '0', email: 'x@x.com', name: 'x'));
  });

  setUp(() {
    remoteDataSource = MockAuthRemoteDataSource();
    localDataSource = MockAuthLocalDataSource();
    tokenStorage = MockTokenStorage();
    networkInfo = MockNetworkInfo();
    repository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      tokenStorage: tokenStorage,
      networkInfo: networkInfo,
    );
  });

  const tUser = UserModel(id: '1', email: 'rakoto@mada.mg', name: 'Rakoto');
  final tAuthResponse = AuthResponseModel(user: tUser, accessToken: 'access123', refreshToken: 'refresh123');

  group('login', () {
    test('returns a User and persists tokens when the network call succeeds', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remoteDataSource.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => tAuthResponse);
      when(() => tokenStorage.saveTokens(accessToken: any(named: 'accessToken'), refreshToken: any(named: 'refreshToken')))
          .thenAnswer((_) async {});
      when(() => localDataSource.cacheUser(any())).thenAnswer((_) async {});

      final result = await repository.login(email: 'rakoto@mada.mg', password: 'secret1');

      expect(result, const Right(tUser));
      verify(() => tokenStorage.saveTokens(accessToken: 'access123', refreshToken: 'refresh123')).called(1);
      verify(() => localDataSource.cacheUser(tUser)).called(1);
    });

    test('returns AuthFailure when the credentials are rejected by the API', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remoteDataSource.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(AuthException('Identifiants invalides.'));

      final result = await repository.login(email: 'rakoto@mada.mg', password: 'wrong');

      expect(result, const Left(AuthFailure('Identifiants invalides.')));
      verifyNever(() => tokenStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          ));
    });

    test('returns NetworkFailure immediately when there is no connectivity', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.login(email: 'rakoto@mada.mg', password: 'secret1');

      expect(result.isLeft(), true);
      result.fold((failure) => expect(failure, isA<NetworkFailure>()), (_) => fail('expected a Left'));
      verifyNever(() => remoteDataSource.login(email: any(named: 'email'), password: any(named: 'password')));
    });
  });
}
