import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService([Connectivity? connectivity]) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<bool> get isOffline => _connectivity.onConnectivityChanged
      .map((results) => results.isEmpty || results.every((r) => r == ConnectivityResult.none));
}
