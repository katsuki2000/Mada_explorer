import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Caches the currently logged-in user's profile so the app can show
/// "who am I" (e.g. on the Profile screen) even fully offline.
/// Tokens themselves are NOT stored here - see core/network/token_storage.dart.
abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel> getCachedUser();
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const boxName = 'auth_box';
  static const userKey = 'CACHED_USER';

  Box get _box => Hive.box(boxName);

  @override
  Future<void> cacheUser(UserModel user) async {
    await _box.put(userKey, user.toJson());
  }

  @override
  Future<UserModel> getCachedUser() async {
    final raw = _box.get(userKey);
    if (raw == null) throw CacheException('Aucun utilisateur en cache.');
    return UserModel.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<void> clearUser() async {
    await _box.delete(userKey);
  }
}
