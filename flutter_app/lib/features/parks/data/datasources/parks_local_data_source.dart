import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart';
import '../models/park_model.dart';

/// Hive-backed cache for the parks list. This is what powers offline mode:
/// the repository writes here after every successful network call, and
/// reads from here whenever the network is unavailable.
abstract class ParksLocalDataSource {
  Future<void> cacheParks(List<ParkModel> parks);
  Future<List<ParkModel>> getCachedParks();
  Future<ParkModel> getCachedParkById(String id);
}

class ParksLocalDataSourceImpl implements ParksLocalDataSource {
  static const boxName = 'parks_box';
  static const listKey = 'PARKS_LIST';

  Box get _box => Hive.box(boxName);

  @override
  Future<void> cacheParks(List<ParkModel> parks) async {
    try {
      final raw = parks.map((p) => p.toJson()).toList();
      await _box.put(listKey, raw);
    } catch (e) {
      throw CacheException("Impossible d'enregistrer les parcs en cache: $e");
    }
  }

  @override
  Future<List<ParkModel>> getCachedParks() async {
    final List? raw;
    try {
      raw = _box.get(listKey) as List?;
    } catch (e) {
      throw CacheException('Impossible de lire le cache des parcs: $e');
    }
    if (raw == null || raw.isEmpty) {
      throw CacheException(
          'Aucun parc en cache. Connectez-vous a internet au moins une fois.');
    }
    try {
      return raw
          .map((e) => ParkModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw CacheException('Cache des parcs corrompu: $e');
    }
  }

  @override
  Future<ParkModel> getCachedParkById(String id) async {
    final all = await getCachedParks();
    return all.firstWhere(
      (p) => p.id == id,
      orElse: () => throw CacheException('Parc introuvable dans le cache.'),
    );
  }
}
