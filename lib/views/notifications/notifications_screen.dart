import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/route_constants.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../shared/app_scaffold_wrapper.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppScaffoldWrapper(
      title: context.l10n.notificationsTitle,
      child: Consumer<NotificationProvider>(
        builder: (context, notif, _) {
          if (notif.isLoading && notif.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (notif.notifications.isEmpty) {
            return _buildEmpty(context);
          }
          return Column(
            children: [
              _buildHeaderBar(context, notif),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notif.notifications.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (_, i) =>
                      _buildTile(context, notif, notif.notifications[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderBar(BuildContext context, NotificationProvider notif) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text(
            notif.unreadCount > 0
                ? context.l10n.notifUnreadCount(notif.unreadCount)
                : context.l10n.notifAllCaughtUp,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          if (notif.hasUnread)
            TextButton.icon(
              onPressed: notif.markAllRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: Text(context.l10n.notifMarkAllRead),
            ),
        ],
      ),
    );
  }

  Widget _buildTile(
      BuildContext context, NotificationProvider notif, NotificationModel n) {
    final meta = _typeMeta(n.type);
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => notif.delete(n.id),
      child: Container(
        color: n.read ? Colors.white : meta.tint,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: meta.color.withOpacity(0.15),
            child: Icon(meta.icon, color: meta.color, size: 20),
          ),
          title: Text(
            n.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: n.read ? FontWeight.w500 : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(n.body,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
              const SizedBox(height: 4),
              Text(_relativeTime(context, n.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ],
          ),
          trailing: n.read
              ? null
              : Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                      color: meta.color, shape: BoxShape.circle),
                ),
          isThreeLine: true,
          onTap: () {
            notif.markAsRead(n.id);
            _openTarget(context, n);
          },
        ),
      ),
    );
  }

  void _openTarget(BuildContext context, NotificationModel n) {
    final docId = n.documentId;
    if (docId != null && docId.isNotEmpty) {
      Navigator.of(context).pushNamed(
        RouteConstants.documentDetail,
        arguments: {'documentId': docId},
      );
    }
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(context.l10n.notifNoneYet,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
          const SizedBox(height: 4),
          Text(context.l10n.notifEmptyHint,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12.5)),
        ],
      ),
    );
  }

  _TypeMeta _typeMeta(NotificationType t) {
    switch (t) {
      case NotificationType.rejection:
        return _TypeMeta(Icons.cancel_outlined, Colors.red.shade600,
            Colors.red.shade50);
      case NotificationType.expiryWarning:
        return _TypeMeta(Icons.schedule, Colors.orange.shade700,
            Colors.orange.shade50);
      case NotificationType.expired:
        return _TypeMeta(Icons.event_busy, Colors.red.shade700,
            Colors.red.shade50);
      case NotificationType.auditDue:
        return _TypeMeta(Icons.event_note, Colors.blue.shade700,
            Colors.blue.shade50);
      case NotificationType.general:
        return _TypeMeta(Icons.info_outline, Colors.grey.shade700,
            Colors.grey.shade100);
    }
  }

  String _relativeTime(BuildContext context, DateTime t) {
    final l10n = context.l10n;
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return l10n.timeJustNow;
    if (d.inMinutes < 60) return l10n.timeMinutesAgo(d.inMinutes);
    if (d.inHours < 24) return l10n.timeHoursAgo(d.inHours);
    if (d.inDays < 7) return l10n.timeDaysAgo(d.inDays);
    return DateFormat('d MMM yyyy').format(t);
  }
}

class _TypeMeta {
  final IconData icon;
  final Color color;
  final Color tint;
  _TypeMeta(this.icon, this.color, this.tint);
}
