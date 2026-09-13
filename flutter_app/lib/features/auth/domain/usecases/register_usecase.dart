import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterParams extends Equatable {
  final String name;
  final String email;
  final String password;
  const RegisterParams({required this.name, required this.email, required this.password});

  @override
  List<Object?> get props => [name, email, password];
}

class RegisterUseCase implements UseCase<User, RegisterParams> {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(RegisterParams params) {
    return repository.register(name: params.name, email: params.email, password: params.password);
  }
}
