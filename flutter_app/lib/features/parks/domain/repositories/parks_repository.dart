import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/park.dart';

abstract class ParksRepository {
  /// Returns the list of parks. Tries the network first; if unreachable,
  /// transparently falls back to whatever is cached locally.
  Future<Either<Failure, List<Park>>> getParks({bool forceRefresh = false});

  Future<Either<Failure, Park>> getParkById(String id);
}
