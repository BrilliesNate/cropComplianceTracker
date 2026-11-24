import '../core/offline/offline_write.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

/// Listens to the current user's notifications in realtime and exposes
/// the feed + unread count to the UI. All reads are scoped to one user.
class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _userId;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.read).length;
  bool get hasUnread => unreadCount > 0;

  /// Start (or restart) listening for a given user. Safe to call repeatedly;
  /// it only re-subscribes when the user actually changes.
  void start(String userId) {
    if (_userId == userId && _sub != null) return;
    _userId = userId;
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();

    _sub = _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen((snap) {
      _notifications = snap.docs
          .map((d) => NotificationModel.fromMap(d.data(), d.id))
          .toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('NotificationProvider stream error: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Stop listening (e.g. on logout) and clear state.
  void stop() {
    _sub?.cancel();
    _sub = null;
    _userId = null;
    _notifications = [];
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    // Optimistic update for snappy UI; the stream will confirm.
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1 || _notifications[idx].read) return;
    try {
      await commitWrite(
          _db.collection('notifications').doc(id).update({'read': true}),
          label: 'mark read'); // l10n-ignore: log label
    } catch (e) {
      debugPrint('markAsRead failed: $e');
    }
  }

  Future<void> markAllRead() async {
    final unread = _notifications.where((n) => !n.read).toList();
    if (unread.isEmpty) return;
    try {
      // Batch in chunks of 500 (Firestore limit) for scale.
      for (var i = 0; i < unread.length; i += 500) {
        final batch = _db.batch();
        for (final n in unread.skip(i).take(500)) {
          batch.update(_db.collection('notifications').doc(n.id), {'read': true});
        }
        await commitWrite(batch.commit(), label: 'mark all read'); // l10n-ignore: log label
      }
    } catch (e) {
      debugPrint('markAllRead failed: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await commitWrite(_db.collection('notifications').doc(id).delete(),
          label: 'delete notification'); // l10n-ignore: log label
    } catch (e) {
      debugPrint('delete notification failed: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
