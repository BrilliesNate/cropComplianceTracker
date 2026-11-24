import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/route_constants.dart';
import '../navigation/app_navigator.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// Top-level background handler — MUST be a top-level function (not a method)
/// so it can run in its own isolate when the app is terminated.
/// We don't need to do anything here for display: on Android, FCM
/// "notification" messages are shown by the OS automatically when the app is
/// backgrounded/terminated. This handler just needs to exist and be registered.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally minimal. The OS renders the notification tray entry.
  debugPrint('BG message: ${message.messageId}');
}

/// Handles device-token registration and foreground notification display.
/// In-app notifications (the bell) are handled separately by
/// NotificationProvider — this class is ONLY about OS-level push.
class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;
  final _local = FlutterLocalNotificationsPlugin();

  String? _currentUserId;
  bool _initialised = false;

  // Name and description shown in the phone's notification settings, in the
  // app language at the time the channel is created.
  static AndroidNotificationChannel get _channel => AndroidNotificationChannel(
        'compliance_alerts',
        LocaleProvider.instance.l10n.pushChannelName,
        description: LocaleProvider.instance.l10n.pushChannelDesc,
        importance: Importance.high,
      );

  /// Call after login. Sets up permissions, the local-notification channel,
  /// foreground display, and token sync for [userId]. Safe to call repeatedly
  /// — it only does the real work once per user.
  Future<void> init(String userId) async {
    // Push is only wired for Android right now.
    if (kIsWeb || !Platform.isAndroid) return;
    if (_initialised && _currentUserId == userId) return;
    _currentUserId = userId;

    if (!_initialised) {
      _initialised = true;

      // 1. Ask the OS for notification permission (Android 13+).
      await _messaging.requestPermission();

      // 2. Create the Android channel that foreground notifications use.
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        // Tapping a notification we showed while the app was open.
        onDidReceiveNotificationResponse: (r) =>
            _open({if (r.payload != null) 'documentId': r.payload!}),
      );

      // 3. When a push arrives while the app is OPEN, the OS does NOT show it
      //    automatically — so we render it via local notifications.
      FirebaseMessaging.onMessage.listen(_showForeground);

      // 4. Tapping a notification opens what it's about:
      //    - app in the background → onMessageOpenedApp
      //    - app was closed → getInitialMessage (handled once signed in)
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data));
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _open(initial.data);
    }

    // 5. Register this device's token and keep it fresh.
    await _syncToken(userId);
    _messaging.onTokenRefresh.listen((t) {
      if (_currentUserId != null) _saveToken(_currentUserId!, t);
    });
  }

  // ── Opening what a notification is about ────────────────────────────────

  bool _appReady = false; // signed in and on a home screen
  Map<String, dynamic>? _pendingTap; // a tap that arrived before that

  /// Called once the signed-in user has landed on their home screen; opens
  /// any notification they tapped to launch the app.
  void markAppReady() {
    _appReady = true;
    final tap = _pendingTap;
    _pendingTap = null;
    if (tap != null) _open(tap);
  }

  /// Called on sign-out: taps must wait for the next sign-in.
  void markSignedOut() {
    _appReady = false;
    _pendingTap = null;
  }

  void _open(Map<String, dynamic> data) {
    if (!_appReady) {
      _pendingTap = data; // open it once the user is signed in
      return;
    }
    final nav = appNavigatorKey.currentState;
    if (nav == null) {
      _pendingTap = data;
      return;
    }
    final documentId = data['documentId'] as String?;
    if (documentId != null && documentId.isNotEmpty) {
      nav.pushNamed(RouteConstants.documentDetail,
          arguments: {'documentId': documentId});
    } else {
      nav.pushNamed(RouteConstants.notifications);
    }
  }

  void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data['documentId'] as String?,
    );
  }

  Future<void> _syncToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(userId, token);
    } catch (e) {
      debugPrint('getToken failed: $e');
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(token)
          .set({
        'fcmToken': token,
        'platform': 'android',
        'valid': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveToken failed: $e');
    }
  }

  /// Remove this device's token on logout so the user stops getting push
  /// on a device they've signed out of.
  Future<void> removeToken() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final uid = _currentUserId;
    _currentUserId = null;
    if (uid == null) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _db
            .collection('users')
            .doc(uid)
            .collection('devices')
            .doc(token)
            .delete();
      }
    } catch (e) {
      debugPrint('removeToken failed: $e');
    }
  }
}
