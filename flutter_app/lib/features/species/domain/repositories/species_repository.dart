import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/species.dart';

abstract class SpeciesRepository {
  Future<Either<Failure, List<Species>>> getSpecies();
}
