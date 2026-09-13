import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/species.dart';
import '../repositories/species_repository.dart';

class GetSpeciesParams {
  const GetSpeciesParams();
}

class GetSpeciesUseCase implements UseCase<List<Species>, GetSpeciesParams> {
  final SpeciesRepository repository;
  GetSpeciesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Species>>> call(GetSpeciesParams params) {
    return repository.getSpecies();
  }
}
