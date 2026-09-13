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
  Future<Either<Failure, User>> login(
      {required String email, required String password}) async {
    if (!await networkInfo.isConnected) {
      return const Left(
          NetworkFailure('Connexion internet requise pour se connecter.'));
    }
    try {
      final auth =
          await remoteDataSource.login(email: email, password: password);
      await tokenStorage.saveTokens(
          accessToken: auth.accessToken, refreshToken: auth.refreshToken);
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
      return const Left(
          NetworkFailure('Connexion internet requise pour creer un compte.'));
    }
    try {
      final auth = await remoteDataSource.register(
          name: name, email: email, password: password);
      await tokenStorage.saveTokens(
          accessToken: auth.accessToken, refreshToken: auth.refreshToken);
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
    } catch (_) {
      // The remote call is best-effort: an unreachable server or an already
      // invalid refresh token must never prevent the local session from
      // being cleared below.
    }
    // Local session must always be cleared, whether or not the remote call
    // above succeeded. Each cleanup step is isolated so that a failure in
    // one (e.g. a corrupted Hive box) never leaves the other half-done.
    await _clearLocalSessionSilently();
    return const Right(unit);
  }

  Future<void> _clearLocalSessionSilently() async {
    try {
      await tokenStorage.clear();
    } catch (_) {
      // Best-effort: nothing more we can do if secure storage itself fails.
    }
    try {
      await localDataSource.clearUser();
    } catch (_) {
      // Best-effort: a corrupted cache box must not make logout() throw.
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
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
