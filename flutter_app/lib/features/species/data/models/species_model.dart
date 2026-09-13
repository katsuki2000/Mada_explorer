import '../../domain/entities/species.dart';

class SpeciesModel extends Species {
  const SpeciesModel({
    required super.id,
    required super.commonName,
    required super.scientificName,
    required super.conservationStatus,
    required super.description,
    required super.imageUrl,
  });

  factory SpeciesModel.fromJson(Map<String, dynamic> json) => SpeciesModel(
        id: json['id'] as String,
        commonName: json['commonName'] as String,
        scientificName: json['scientificName'] as String,
        conservationStatus: json['conservationStatus'] as String,
        description: json['description'] as String,
        imageUrl: json['imageUrl'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'commonName': commonName,
        'scientificName': scientificName,
        'conservationStatus': conservationStatus,
        'description': description,
        'imageUrl': imageUrl,
      };
}
