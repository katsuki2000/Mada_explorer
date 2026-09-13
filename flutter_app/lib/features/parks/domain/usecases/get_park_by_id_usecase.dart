import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/park.dart';
import '../repositories/parks_repository.dart';

class GetParkByIdParams {
  final String id;
  const GetParkByIdParams(this.id);
}

class GetParkByIdUseCase implements UseCase<Park, GetParkByIdParams> {
  final ParksRepository repository;
  GetParkByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Park>> call(GetParkByIdParams params) {
    return repository.getParkById(params.id);
  }
}
