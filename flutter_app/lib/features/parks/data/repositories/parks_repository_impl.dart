import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/park.dart';
import '../../domain/repositories/parks_repository.dart';
import '../datasources/parks_local_data_source.dart';
import '../datasources/parks_remote_data_source.dart';

/// Textbook offline-first repository:
/// online  -> fetch remote, cache it, return it
/// offline -> return whatever is cached, or a clear failure if cache is empty
class ParksRepositoryImpl implements ParksRepository {
  final ParksRemoteDataSource remoteDataSource;
  final ParksLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ParksRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Park>>> getParks(
      {bool forceRefresh = false}) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteParks = await remoteDataSource.getParks();
        await localDataSource.cacheParks(remoteParks);
        return Right(remoteParks);
      } on ServerException catch (e) {
        return _fallbackToCache(ServerFailure(e.message));
      } catch (_) {
        return _fallbackToCache(const UnexpectedFailure());
      }
    }
    return _fallbackToCache(const NetworkFailure());
  }

  @override
  Future<Either<Failure, Park>> getParkById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final park = await remoteDataSource.getParkById(id);
        return Right(park);
      } on ServerException catch (_) {
        // fall through to cache below
      } catch (_) {
        // fall through to cache below
      }
    }
    try {
      final cached = await localDataSource.getCachedParkById(id);
      return Right(cached);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  /// Shared helper: try the cache and, if present, return it while still
  /// surfacing the original reason we had to fall back (as the Failure type),
  /// so the UI can show "offline, showing cached data" instead of a raw error.
  Future<Either<Failure, List<Park>>> _fallbackToCache(Failure reason) async {
    try {
      final cached = await localDataSource.getCachedParks();
      return Right(cached);
    } on CacheException {
      return Left(reason);
    }
  }
}
