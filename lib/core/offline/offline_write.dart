import 'dart:async';

import 'package:flutter/foundation.dart';

import 'connectivity_service.dart';

/// Runs a Firestore write without making the user wait on the server.
///
/// With offline persistence on, Firestore applies a write to the phone's
/// local copy straight away (every screen sees it immediately) and sends it
/// to the server when it can. But the write's Future only completes once the
/// SERVER confirms — so `await`ing it offline hangs forever, which is why
/// saving used to spin with no signal.
///
/// - Offline: don't wait. The write is already applied locally and queued;
///   Firestore delivers it when the connection returns, even after a restart.
/// - Online: wait as before (so real errors such as "permission denied" still
///   reach the caller), but only up to [timeout] — on a weak signal we treat
///   the write as queued rather than leave the user stuck.
///
/// Web keeps the old behaviour (the offline work targets the mobile app).
Future<void> commitWrite(
  Future<void> write, {
  String label = 'write',
  Duration timeout = const Duration(seconds: 12),
}) async {
  if (kIsWeb) return write;

  void logLater(Object e) => debugPrint('Offline-queued $label failed later: $e');

  if (!ConnectivityService.instance.isOnline) {
    unawaited(write.catchError(logLater));
    return;
  }
  try {
    await write.timeout(timeout);
  } on TimeoutException {
    debugPrint('$label: no server reply in ${timeout.inSeconds}s — queued for sync');
    unawaited(write.catchError(logLater));
  }
}
