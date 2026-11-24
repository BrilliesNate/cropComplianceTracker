import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/core/offline/connectivity_service.dart';
import 'package:cropCompliance/core/offline/upload_outbox.dart';
import 'package:cropCompliance/core/utils/session_actions.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'farm_picker_sheet.dart';
import 'mobile_ui.dart';
import 'package:cropCompliance/providers/locale_provider.dart';
import 'package:cropCompliance/views/shared/language_toggle.dart';

/// Profile tab on phones: who you are, which farm you're on (switch if you
/// have several), notifications, sync status, and sign out.
class MobileProfileScreen extends StatelessWidget {
  const MobileProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final unread = Provider.of<NotificationProvider>(context).unreadCount;
    final farm = auth.effectiveCompany;
    final name = user?.name ?? '';
    final initials = name.trim().isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join();

    return Scaffold(
      backgroundColor: MobileColors.page,
      body: Column(children: [
        MobileHeader(title: l10n.navProfile),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: MobileColors.greenSoft,
                  child: Text(initials,
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: MobileColors.green)),
                ),
              ),
              const SizedBox(height: 12),
              Text(name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              Text(user?.email ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: MobileColors.muted)),
              const SizedBox(height: 24),
              if (auth.isAdmin) ...[
                _adminFarmCard(context, auth),
              ] else
                MobileCard(
                  onTap: auth.canSwitchCompany
                      ? () => _switchFarm(context, auth)
                      : null,
                  child: Row(children: [
                    const Icon(Icons.location_on_outlined,
                        color: MobileColors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.farm,
                                style: TextStyle(
                                    fontSize: 12, color: MobileColors.muted)),
                            Text(farm?.name ?? '—',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                          ]),
                    ),
                    if (auth.canSwitchCompany)
                      Text(l10n.commonSwitch,
                          style: TextStyle(
                              color: MobileColors.green,
                              fontWeight: FontWeight.w700)),
                  ]),
                ),
              const SizedBox(height: 12),
              MobileCard(
                onTap: () => Navigator.of(context)
                    .pushNamed(RouteConstants.notifications),
                child: Row(children: [
                  const Icon(Icons.notifications_outlined,
                      color: MobileColors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l10n.notificationsTitle,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  if (unread > 0)
                    StatusPill(
                        label: l10n.unreadCountNew(unread),
                        fg: Colors.white,
                        bg: MobileColors.greenMid),
                  const Icon(Icons.chevron_right),
                ]),
              ),
              const SizedBox(height: 12),
              _syncCard(),
              const SizedBox(height: 12),
              MobileCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.translate, color: MobileColors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(l10n.language,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(l10n.languageHint,
                          style: const TextStyle(
                              fontSize: 13, color: MobileColors.muted)),
                      const SizedBox(height: 12),
                      const Center(child: LanguageToggle()),
                    ]),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () => _signOut(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: MobileColors.red,
                  side: const BorderSide(color: MobileColors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout),
                label: Text(l10n.signOut,
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ]),
      bottomNavigationBar: const MobileBottomNav(current: MobileTab.profile),
    );
  }

  /// Admins: which farm is open (if any), switch to another, or go back to
  /// the list of all farms.
  Widget _adminFarmCard(BuildContext context, AuthProvider auth) {
    final open = auth.isManagingCompany ? auth.selectedCompany : null;
    return MobileCard(
      onTap: () async {
        final farm = await showFarmPickerSheet(context,
            title: open == null
                ? context.l10n.farmOpenAFarm
                : context.l10n.farmSwitchFarm,
            currentId: open?.id);
        if (farm == null || !context.mounted) return;
        auth.setSelectedCompany(farm);
        Navigator.of(context)
            .pushNamedAndRemoveUntil(RouteConstants.dashboard, (_) => false);
      },
      child: Column(children: [
        Row(children: [
          const Icon(Icons.location_on_outlined, color: MobileColors.green),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.l10n.farmOpenLabel,
                  style: TextStyle(fontSize: 12, color: MobileColors.muted)),
              Text(open?.name ?? context.l10n.farmNoneViewingAll,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ]),
          ),
          Text(open == null ? context.l10n.commonOpen : context.l10n.commonSwitch,
              style: const TextStyle(
                  color: MobileColors.green, fontWeight: FontWeight.w700)),
        ]),
        if (open != null) ...[
          const Divider(height: 24),
          InkWell(
            onTap: () {
              auth.clearCompanySelection();
              Navigator.of(context).pushNamedAndRemoveUntil(
                  RouteConstants.adminDashboard, (_) => false);
            },
            child: Row(children: [
              Icon(Icons.grid_view_rounded, color: MobileColors.green),
              SizedBox(width: 12),
              Expanded(
                child: Text(context.l10n.farmBackToAll,
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              Icon(Icons.chevron_right),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _syncCard() {
    final outbox = UploadOutbox.instance;
    return AnimatedBuilder(
      animation: Listenable.merge(
          [ConnectivityService.instance.online, outbox.pending]),
      builder: (context, _) {
        final online = ConnectivityService.instance.isOnline;
        final pending = outbox.pending.value;
        final text = !online
            ? context.l10n.syncOffline
            : pending > 0
                ? context.l10n.syncFilesWaiting(pending)
                : context.l10n.syncAllSynced;
        return MobileCard(
          onTap: online && pending > 0 ? outbox.flush : null,
          child: Row(children: [
            Icon(
                !online
                    ? Icons.cloud_off_outlined
                    : pending > 0
                        ? Icons.cloud_upload_outlined
                        : Icons.cloud_done_outlined,
                color: !online ? MobileColors.muted : MobileColors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            if (online && pending > 0)
              Text(context.l10n.syncUploadNow,
                  style: TextStyle(
                      color: MobileColors.green, fontWeight: FontWeight.w700)),
          ]),
        );
      },
    );
  }

  Future<void> _switchFarm(BuildContext context, AuthProvider auth) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(context.l10n.farmChooseAFarm,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          for (final c in auth.accessibleCompanies)
            ListTile(
              leading: Icon(
                  c.id == auth.effectiveCompany?.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: MobileColors.green),
              title: Text(c.name),
              onTap: () => Navigator.pop(ctx, c.id),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (id != null && context.mounted) {
      await switchFarm(context, id);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final pending = UploadOutbox.instance.pending.value;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.signOutConfirmTitle),
        content: Text(pending > 0
            ? context.l10n.signOutPendingFiles(pending)
            : context.l10n.signOutCanSignInAgain),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.signOut)),
        ],
      ),
    );
    if (ok == true && context.mounted) await signOutAndReset(context);
  }
}
