import 'package:cloud_firestore/cloud_firestore.dart';

/// The kind of event a notification represents.
/// Keep these string keys stable — they're used for per-type preferences
/// and for choosing the icon/colour in the UI.
enum NotificationType {
  rejection,
  expiryWarning,
  expired,
  auditDue,
  general,
}

extension NotificationTypeX on NotificationType {
  String get key {
    switch (this) {
      case NotificationType.rejection:
        return 'rejection';
      case NotificationType.expiryWarning:
        return 'expiry_warning';
      case NotificationType.expired:
        return 'expired';
      case NotificationType.auditDue:
        return 'audit_due';
      case NotificationType.general:
        return 'general';
    }
  }

  static NotificationType fromKey(String? k) {
    switch (k) {
      case 'rejection':
        return NotificationType.rejection;
      case 'expiry_warning':
        return NotificationType.expiryWarning;
      case 'expired':
        return NotificationType.expired;
      case 'audit_due':
        return NotificationType.auditDue;
      default:
        return NotificationType.general;
    }
  }
}

/// A single in-app notification for ONE user.
/// Generated server-side (Cloud Functions) and read in realtime by the app.
class NotificationModel {
  final String id;
  final String userId;
  final String companyId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data; // deep-link payload (documentId, etc.)
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  /// Convenience: the document this notification points to, if any.
  String? get documentId => data['documentId'] as String?;

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      companyId: map['companyId'] ?? '',
      type: NotificationTypeX.fromKey(map['type'] as String?),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      read: map['read'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'companyId': companyId,
      'type': type.key,
      'title': title,
      'body': body,
      'data': data,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
