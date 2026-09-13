import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final TokenStorage tokenStorage;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.tokenStorage,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> login({required String email, required String password}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Connexion internet requise pour se connecter.'));
    }
    try {
      final auth = await remoteDataSource.login(email: email, password: password);
      await tokenStorage.saveTokens(accessToken: auth.accessToken, refreshToken: auth.refreshToken);
      await localDataSource.cacheUser(auth.user);
      return Right(auth.user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Connexion internet requise pour creer un compte.'));
    }
    try {
      final auth = await remoteDataSource.register(name: name, email: email, password: password);
      await tokenStorage.saveTokens(accessToken: auth.accessToken, refreshToken: auth.refreshToken);
      await localDataSource.cacheUser(auth.user);
      return Right(auth.user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      final refreshToken = await tokenStorage.refreshToken;
      if (refreshToken != null) {
        await remoteDataSource.logout(refreshToken);
      }
      await tokenStorage.clear();
      await localDataSource.clearUser();
      return const Right(unit);
    } catch (_) {
      // Local session must be cleared even if the remote call failed.
      await tokenStorage.clear();
      await localDataSource.clearUser();
      return const Right(unit);
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    // Prefer the freshest data when online, fall back to cache otherwise.
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.getProfile();
        await localDataSource.cacheUser(user);
        return Right(user);
      } catch (_) {
        // fall through to cache
      }
    }
    try {
      final cached = await localDataSource.getCachedUser();
      return Right(cached);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
