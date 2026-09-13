import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/usecases/get_parks_usecase.dart';
import 'parks_state.dart';

class ParksCubit extends Cubit<ParksState> {
  final GetParksUseCase getParksUseCase;
  final NetworkInfo networkInfo;

  ParksCubit({required this.getParksUseCase, required this.networkInfo})
      : super(const ParksLoading());

  Future<void> loadParks({bool forceRefresh = false}) async {
    emit(const ParksLoading());
    final result =
        await getParksUseCase(GetParksParams(forceRefresh: forceRefresh));
    final isOffline = !await networkInfo.isConnected;
    result.fold(
      (failure) => emit(ParksError(failure.message)),
      (parks) => emit(ParksLoaded(parks, isOffline: isOffline)),
    );
  }
}
