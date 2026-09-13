import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/species.dart';
import '../../domain/repositories/species_repository.dart';
import '../datasources/species_local_data_source.dart';
import '../datasources/species_remote_data_source.dart';

class SpeciesRepositoryImpl implements SpeciesRepository {
  final SpeciesRemoteDataSource remoteDataSource;
  final SpeciesLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  SpeciesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Species>>> getSpecies() async {
    if (await networkInfo.isConnected) {
      try {
        final remote = await remoteDataSource.getSpecies();
        await localDataSource.cacheSpecies(remote);
        return Right(remote);
      } on ServerException catch (e) {
        return _fallbackToCache(ServerFailure(e.message));
      } catch (_) {
        return _fallbackToCache(const UnexpectedFailure());
      }
    }
    return _fallbackToCache(const NetworkFailure());
  }

  Future<Either<Failure, List<Species>>> _fallbackToCache(
      Failure reason) async {
    try {
      final cached = await localDataSource.getCachedSpecies();
      return Right(cached);
    } on CacheException {
      return Left(reason);
    }
  }
}
