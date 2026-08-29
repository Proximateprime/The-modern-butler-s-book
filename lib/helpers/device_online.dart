import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// True when the OS reports any interface other than none.
///
/// Empty or only [ConnectivityResult.none] is airplane / no-network.
/// Fail-open (treat as online) is handled by [DeviceOnlineMonitor], not here.
bool connectivityMeansOnline(List<ConnectivityResult> results) {
  return results.any((result) => result != ConnectivityResult.none);
}

/// Listens for airplane-mode / no-network. Does not probe the public internet.
///
/// Missing plugin or errors leave the last known value (starts online) so the
/// app never blanks. Ranking and guides do not use this — UI copy only.
class DeviceOnlineMonitor extends ChangeNotifier {
  DeviceOnlineMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _online = true;

  bool get isOnline => _online;

  Future<void> start() async {
    _subscription ??= _connectivity.onConnectivityChanged.listen(_apply);
    try {
      _apply(await _connectivity.checkConnectivity());
    } on MissingPluginException {
      _online = true;
    } catch (_) {
      _online = true;
    }
  }

  void _apply(List<ConnectivityResult> results) {
    final next = connectivityMeansOnline(results);
    if (next == _online) {
      return;
    }
    _online = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
