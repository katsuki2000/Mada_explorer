import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction over device connectivity so repositories can decide
/// remote-vs-cache without depending on a concrete plugin.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;
  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}
