import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login({required String email, required String password});

  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> logout();

  /// Returns the cached user if a session already exists (used on app start).
  Future<Either<Failure, User>> getCurrentUser();
}
