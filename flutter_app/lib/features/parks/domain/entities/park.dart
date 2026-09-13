import 'package:equatable/equatable.dart';

class Park extends Equatable {
  final String id;
  final String name;
  final String region;
  final String description;
  final int areaKm2;
  final int createdYear;
  final String imageUrl;
  final List<String> speciesIds;

  const Park({
    required this.id,
    required this.name,
    required this.region,
    required this.description,
    required this.areaKm2,
    required this.createdYear,
    required this.imageUrl,
    required this.speciesIds,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        region,
        description,
        areaKm2,
        createdYear,
        imageUrl,
        speciesIds
      ];
}
