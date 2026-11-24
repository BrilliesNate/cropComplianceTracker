import 'dart:async';

import 'package:cropCompliance/core/offline/connectivity_service.dart';
import 'package:cropCompliance/core/offline/offline_write.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final online = ConnectivityService.instance.online;
  tearDown(() => online.value = true);

  test('offline: returns at once without waiting for the server', () async {
    online.value = false;
    final never = Completer<void>(); // a server reply that never comes
    final sw = Stopwatch()..start();
    await commitWrite(never.future);
    expect(sw.elapsedMilliseconds, lessThan(200));
  });

  test('offline: a later failure is swallowed, not thrown at the user',
      () async {
    online.value = false;
    final c = Completer<void>();
    await commitWrite(c.future);
    c.completeError(Exception('rejected later'));
    await Future<void>.delayed(Duration.zero); // no unhandled error
  });

  test('online: waits for the server and surfaces real errors', () async {
    online.value = true;
    await commitWrite(Future<void>.value());
    expect(
      () => commitWrite(Future<void>.error(Exception('permission-denied'))),
      throwsException,
    );
  });

  test('online but no reply: gives up waiting after the timeout', () async {
    online.value = true;
    final never = Completer<void>();
    final sw = Stopwatch()..start();
    await commitWrite(never.future,
        timeout: const Duration(milliseconds: 150));
    expect(sw.elapsedMilliseconds, lessThan(1000));
  });
}
