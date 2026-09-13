class ApiConstants {
  ApiConstants._();

  /// Base URL of the Mada Explorer backend (see /backend in the repo).
  /// - Android emulator -> use 10.0.2.2 instead of localhost
  /// - iOS simulator / desktop / web -> localhost works
  /// - Physical device -> use your machine's LAN IP
  static const String baseUrl = 'http://10.0.2.2:3000';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String profile = '/profile';
  static const String parks = '/parks';
  static const String species = '/species';

  static const connectTimeoutMs = 10000;
  static const receiveTimeoutMs = 10000;
}
