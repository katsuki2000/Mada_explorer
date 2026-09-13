import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mada_explorer/core/error/exceptions.dart';
import 'package:mada_explorer/core/error/failures.dart';
import 'package:mada_explorer/core/network/network_info.dart';
import 'package:mada_explorer/features/parks/data/datasources/parks_local_data_source.dart';
import 'package:mada_explorer/features/parks/data/datasources/parks_remote_data_source.dart';
import 'package:mada_explorer/features/parks/data/models/park_model.dart';
import 'package:mada_explorer/features/parks/data/repositories/parks_repository_impl.dart';

class MockParksRemoteDataSource extends Mock implements ParksRemoteDataSource {}

class MockParksLocalDataSource extends Mock implements ParksLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late ParksRepositoryImpl repository;
  late MockParksRemoteDataSource remoteDataSource;
  late MockParksLocalDataSource localDataSource;
  late MockNetworkInfo networkInfo;

  setUp(() {
    remoteDataSource = MockParksRemoteDataSource();
    localDataSource = MockParksLocalDataSource();
    networkInfo = MockNetworkInfo();
    repository = ParksRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      networkInfo: networkInfo,
    );
  });

  const tParks = [
    ParkModel(
      id: 'p1',
      name: 'Ranomafana',
      region: 'Haute Matsiatra',
      description: 'Foret tropicale humide',
      areaKm2: 416,
      createdYear: 1991,
      imageUrl: 'https://example.com/img.jpg',
      speciesIds: ['s1'],
    ),
  ];

  group('getParks - online', () {
    test('fetches from remote and caches the result when connected', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remoteDataSource.getParks()).thenAnswer((_) async => tParks);
      when(() => localDataSource.cacheParks(any())).thenAnswer((_) async {});

      final result = await repository.getParks();

      expect(result, const Right(tParks));
      verify(() => localDataSource.cacheParks(tParks)).called(1);
      verifyNever(() => localDataSource.getCachedParks());
    });
  });

  group('getParks - offline', () {
    test('returns cached parks when there is no connectivity', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);
      when(() => localDataSource.getCachedParks()).thenAnswer((_) async => tParks);

      final result = await repository.getParks();

      expect(result, const Right(tParks));
      verifyNever(() => remoteDataSource.getParks());
    });

    test('returns NetworkFailure when offline and the cache is empty', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);
      when(() => localDataSource.getCachedParks()).thenThrow(CacheException('empty'));

      final result = await repository.getParks();

      expect(result.isLeft(), true);
      result.fold((failure) => expect(failure, isA<NetworkFailure>()), (_) => fail('expected a Left'));
    });
  });
}
