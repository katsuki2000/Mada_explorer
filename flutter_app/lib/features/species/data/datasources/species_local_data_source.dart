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
    await _box.put(listKey, species.map((s) => s.toJson()).toList());
  }

  @override
  Future<List<SpeciesModel>> getCachedSpecies() async {
    final raw = _box.get(listKey) as List?;
    if (raw == null || raw.isEmpty) {
      throw CacheException('Aucune espece en cache. Connectez-vous a internet au moins une fois.');
    }
    return raw.map((e) => SpeciesModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}
