import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../network/token_storage.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

import '../../features/parks/data/datasources/parks_local_data_source.dart';
import '../../features/parks/data/datasources/parks_remote_data_source.dart';
import '../../features/parks/data/repositories/parks_repository_impl.dart';
import '../../features/parks/domain/repositories/parks_repository.dart';
import '../../features/parks/domain/usecases/get_park_by_id_usecase.dart';
import '../../features/parks/domain/usecases/get_parks_usecase.dart';
import '../../features/parks/presentation/cubit/parks_cubit.dart';

import '../../features/species/data/datasources/species_local_data_source.dart';
import '../../features/species/data/datasources/species_remote_data_source.dart';
import '../../features/species/data/repositories/species_repository_impl.dart';
import '../../features/species/domain/repositories/species_repository.dart';
import '../../features/species/domain/usecases/get_species_usecase.dart';
import '../../features/species/presentation/cubit/species_cubit.dart';

/// Single service locator (GetIt) for the whole app. Registered once in
/// main() before runApp(). Keeping wiring in one file makes it obvious how
/// every layer (data -> domain -> presentation) is assembled.
final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ----- Core -----
  sl.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());
  sl.registerLazySingleton<TokenStorage>(() => TokenStorage(sl()));
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  sl.registerLazySingleton<DioClient>(
    () => DioClient(
      tokenStorage: sl(),
      onSessionExpired: () => sl<AuthCubit>().forceLogout(),
    ),
  );
  sl.registerLazySingleton(() => sl<DioClient>().build());

  // ----- Auth feature -----
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl());
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      tokenStorage: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(
    () => AuthCubit(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      authRepository: sl(),
    ),
  );

  // ----- Parks feature -----
  sl.registerLazySingleton<ParksRemoteDataSource>(() => ParksRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<ParksLocalDataSource>(() => ParksLocalDataSourceImpl());
  sl.registerLazySingleton<ParksRepository>(
    () => ParksRepositoryImpl(remoteDataSource: sl(), localDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => GetParksUseCase(sl()));
  sl.registerLazySingleton(() => GetParkByIdUseCase(sl()));
  sl.registerFactory(() => ParksCubit(getParksUseCase: sl(), networkInfo: sl()));

  // ----- Species feature -----
  sl.registerLazySingleton<SpeciesRemoteDataSource>(() => SpeciesRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<SpeciesLocalDataSource>(() => SpeciesLocalDataSourceImpl());
  sl.registerLazySingleton<SpeciesRepository>(
    () => SpeciesRepositoryImpl(remoteDataSource: sl(), localDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => GetSpeciesUseCase(sl()));
  sl.registerFactory(() => SpeciesCubit(getSpeciesUseCase: sl(), networkInfo: sl()));
}
