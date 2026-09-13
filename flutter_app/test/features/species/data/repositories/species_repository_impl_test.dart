import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mada_explorer/core/error/exceptions.dart';
import 'package:mada_explorer/core/network/network_info.dart';
import 'package:mada_explorer/features/species/data/datasources/species_local_data_source.dart';
import 'package:mada_explorer/features/species/data/datasources/species_remote_data_source.dart';
import 'package:mada_explorer/features/species/data/models/species_model.dart';
import 'package:mada_explorer/features/species/data/repositories/species_repository_impl.dart';

class MockSpeciesRemoteDataSource extends Mock
    implements SpeciesRemoteDataSource {}

class MockSpeciesLocalDataSource extends Mock
    implements SpeciesLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late SpeciesRepositoryImpl repository;
  late MockSpeciesRemoteDataSource remoteDataSource;
  late MockSpeciesLocalDataSource localDataSource;
  late MockNetworkInfo networkInfo;

  setUp(() {
    remoteDataSource = MockSpeciesRemoteDataSource();
    localDataSource = MockSpeciesLocalDataSource();
    networkInfo = MockNetworkInfo();
    repository = SpeciesRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      networkInfo: networkInfo,
    );
  });

  const tSpecies = [
    SpeciesModel(
      id: 's1',
      commonName: 'Indri',
      scientificName: 'Indri indri',
      conservationStatus: 'En danger critique',
      description: 'Le plus grand lemurien vivant.',
      imageUrl: 'https://example.com/indri.jpg',
    ),
  ];

  test(
      'getSpecies falls back to cache and preserves the original failure reason when both remote and cache fail',
      () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => remoteDataSource.getSpecies())
        .thenThrow(ServerException('Erreur serveur.'));
    when(() => localDataSource.getCachedSpecies())
        .thenThrow(CacheException('vide'));

    final result = await repository.getSpecies();

    expect(result.isLeft(), true);
    result.fold(
      (failure) => expect(failure.message, 'Erreur serveur.'),
      (_) => fail('expected a Left'),
    );
  });

  test(
      'getSpecies returns remote data and refreshes the cache when online and reachable',
      () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => remoteDataSource.getSpecies()).thenAnswer((_) async => tSpecies);
    when(() => localDataSource.cacheSpecies(any())).thenAnswer((_) async {});

    final result = await repository.getSpecies();

    expect(result, const Right(tSpecies));
    verify(() => localDataSource.cacheSpecies(tSpecies)).called(1);
  });

  test(
      'getSpecies returns cached data when the remote call throws but cache has data',
      () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => remoteDataSource.getSpecies())
        .thenThrow(ServerException('down'));
    when(() => localDataSource.getCachedSpecies())
        .thenAnswer((_) async => tSpecies);

    final result = await repository.getSpecies();

    expect(result, const Right(tSpecies));
  });
}
