import 'package:equatable/equatable.dart';
import '../../domain/entities/park.dart';

abstract class ParksState extends Equatable {
  const ParksState();
  @override
  List<Object?> get props => [];
}

class ParksLoading extends ParksState {
  const ParksLoading();
}

class ParksLoaded extends ParksState {
  final List<Park> parks;
  final bool isOffline;
  const ParksLoaded(this.parks, {this.isOffline = false});
  @override
  List<Object?> get props => [parks, isOffline];
}

class ParksError extends ParksState {
  final String message;
  const ParksError(this.message);
  @override
  List<Object?> get props => [message];
}
