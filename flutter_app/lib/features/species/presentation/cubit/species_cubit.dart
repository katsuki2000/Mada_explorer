import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/usecases/get_species_usecase.dart';
import 'species_state.dart';

class SpeciesCubit extends Cubit<SpeciesState> {
  final GetSpeciesUseCase getSpeciesUseCase;
  final NetworkInfo networkInfo;

  SpeciesCubit({required this.getSpeciesUseCase, required this.networkInfo})
      : super(const SpeciesLoading());

  Future<void> loadSpecies() async {
    emit(const SpeciesLoading());
    final result = await getSpeciesUseCase(const GetSpeciesParams());
    final isOffline = !await networkInfo.isConnected;
    result.fold(
      (failure) => emit(SpeciesError(failure.message)),
      (species) => emit(SpeciesLoaded(species, isOffline: isOffline)),
    );
  }
}
