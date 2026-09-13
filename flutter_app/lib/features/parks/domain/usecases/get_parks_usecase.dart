import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/park.dart';
import '../repositories/parks_repository.dart';

class GetParksParams {
  final bool forceRefresh;
  const GetParksParams({this.forceRefresh = false});
}

class GetParksUseCase implements UseCase<List<Park>, GetParksParams> {
  final ParksRepository repository;
  GetParksUseCase(this.repository);

  @override
  Future<Either<Failure, List<Park>>> call(GetParksParams params) {
    return repository.getParks(forceRefresh: params.forceRefresh);
  }
}
