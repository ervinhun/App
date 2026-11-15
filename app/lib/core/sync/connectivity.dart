import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device has a network connection at all. It may still not reach
/// the backend: `SyncStatus.reachable` says whether the last attempt did.
///
/// Assumes a connection when the platform can't tell, as in tests.
final networkAvailableProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool connected(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  try {
    yield connected(await connectivity.checkConnectivity());
  } catch (e) {
    debugPrint('Could not check the connection: $e');
    yield true;
    return;
  }
  yield* connectivity.onConnectivityChanged
      .map(connected)
      .handleError((Object e) => debugPrint('Connection updates failed: $e'));
});
