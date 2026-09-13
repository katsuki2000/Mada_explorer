import 'package:equatable/equatable.dart';
import '../../domain/entities/species.dart';

abstract class SpeciesState extends Equatable {
  const SpeciesState();
  @override
  List<Object?> get props => [];
}

class SpeciesLoading extends SpeciesState {
  const SpeciesLoading();
}

class SpeciesLoaded extends SpeciesState {
  final List<Species> species;
  final bool isOffline;
  const SpeciesLoaded(this.species, {this.isOffline = false});
  @override
  List<Object?> get props => [species, isOffline];
}

class SpeciesError extends SpeciesState {
  final String message;
  const SpeciesError(this.message);
  @override
  List<Object?> get props => [message];
}
