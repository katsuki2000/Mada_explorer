import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart';
import '../models/species_model.dart';

abstract class SpeciesLocalDataSource {
  Future<void> cacheSpecies(List<SpeciesModel> species);
  Future<List<SpeciesModel>> getCachedSpecies();
}

class SpeciesLocalDataSourceImpl implements SpeciesLocalDataSource {
  static const boxName = 'species_box';
  static const listKey = 'SPECIES_LIST';

  Box get _box => Hive.box(boxName);

  @override
  Future<void> cacheSpecies(List<SpeciesModel> species) async {
    try {
      await _box.put(listKey, species.map((s) => s.toJson()).toList());
    } catch (e) {
      throw CacheException("Impossible d'enregistrer les especes en cache: $e");
    }
  }

  @override
  Future<List<SpeciesModel>> getCachedSpecies() async {
    final List? raw;
    try {
      raw = _box.get(listKey) as List?;
    } catch (e) {
      throw CacheException('Impossible de lire le cache des especes: $e');
    }
    if (raw == null || raw.isEmpty) {
      throw CacheException(
          'Aucune espece en cache. Connectez-vous a internet au moins une fois.');
    }
    try {
      return raw
          .map(
              (e) => SpeciesModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw CacheException('Cache des especes corrompu: $e');
    }
  }
}
