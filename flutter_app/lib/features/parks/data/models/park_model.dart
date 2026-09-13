import '../../domain/entities/park.dart';

class ParkModel extends Park {
  const ParkModel({
    required super.id,
    required super.name,
    required super.region,
    required super.description,
    required super.areaKm2,
    required super.createdYear,
    required super.imageUrl,
    required super.speciesIds,
  });

  factory ParkModel.fromJson(Map<String, dynamic> json) => ParkModel(
        id: json['id'] as String,
        name: json['name'] as String,
        region: json['region'] as String,
        description: json['description'] as String,
        areaKm2: json['areaKm2'] as int,
        createdYear: json['createdYear'] as int,
        imageUrl: json['imageUrl'] as String,
        speciesIds: List<String>.from(json['species'] as List? ?? const []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'region': region,
        'description': description,
        'areaKm2': areaKm2,
        'createdYear': createdYear,
        'imageUrl': imageUrl,
        'species': speciesIds,
      };
}
