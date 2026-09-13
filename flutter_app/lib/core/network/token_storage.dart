import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure, single place where JWT access/refresh tokens live.
/// Kept out of Hive on purpose: tokens are secrets, not cacheable content.
class TokenStorage {
  final FlutterSecureStorage _storage;
  TokenStorage(this._storage);

  static const _kAccess = 'ACCESS_TOKEN';
  static const _kRefresh = 'REFRESH_TOKEN';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _kAccess, value: accessToken);
    await _storage.write(key: _kRefresh, value: refreshToken);
  }

  Future<String?> get accessToken => _storage.read(key: _kAccess);
  Future<String?> get refreshToken => _storage.read(key: _kRefresh);

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
