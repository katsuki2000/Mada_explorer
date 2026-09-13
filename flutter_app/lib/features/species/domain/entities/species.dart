import 'package:equatable/equatable.dart';

class Species extends Equatable {
  final String id;
  final String commonName;
  final String scientificName;
  final String conservationStatus;
  final String description;
  final String imageUrl;

  const Species({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.conservationStatus,
    required this.description,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        commonName,
        scientificName,
        conservationStatus,
        description,
        imageUrl
      ];
}
