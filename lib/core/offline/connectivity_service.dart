import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Knows whether the device has a network connection, and tells listeners
/// when it changes — so saves can skip waiting on the server while offline,
/// and the upload outbox can flush the moment the signal comes back.
///
/// "Online" means the phone has a network interface (Wi-Fi / mobile data).
/// That can't prove the internet is reachable, so nothing here *depends* on
/// it being right: offline-first writes and the outbox's retries make a wrong
/// guess harmless — at worst a sync waits for the next retry.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final ValueNotifier<bool> online = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _started = false;

  bool get isOnline => online.value;

  /// Starts watching the connection. Safe to call more than once.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    final c = Connectivity();
    try {
      online.value = _hasNetwork(await c.checkConnectivity());
    } catch (_) {
      online.value = true; // unknown → behave as before
    }
    _sub = c.onConnectivityChanged.listen((r) {
      final now = _hasNetwork(r);
      if (now != online.value) {
        debugPrint('Connectivity: ${now ? 'ONLINE' : 'OFFLINE'}');
        online.value = now;
      }
    });
  }

  static bool _hasNetwork(List<ConnectivityResult> r) =>
      r.any((x) => x != ConnectivityResult.none);

  void dispose() {
    _sub?.cancel();
  }
}
