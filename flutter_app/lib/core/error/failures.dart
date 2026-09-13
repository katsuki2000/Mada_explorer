import 'package:equatable/equatable.dart';

/// Failures are the domain/presentation-facing representation of anything
/// that can go wrong. They never leak Dio/Hive-specific types upward.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Une erreur serveur est survenue.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Identifiants invalides.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message =
        'Pas de connexion internet. Affichage des donnees en cache.',
  ]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Aucune donnee en cache disponible.']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(
      [super.message = 'Une erreur inattendue est survenue.']);
}
