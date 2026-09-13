/// Exceptions are thrown by the data layer (datasources) and are always
/// caught by repositories, which translate them into [Failure]s.
class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server error']);
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'Authentication error']);
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache error']);
}
