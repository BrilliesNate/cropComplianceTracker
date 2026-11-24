import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/admin_farm_chip.dart';
import 'farm_picker_sheet.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// Shared look for the phone screens (matches the mobile dashboard design):
/// soft green page, rounded header card, white rounded cards, one strong
/// green, and a 4-icon bottom bar with the current screen in a green circle.
class MobileColors {
  MobileColors._();
  static const page = Color(0xFFF1F8F1);
  static const green = Color(0xFF2E7D32);
  static const greenMid = Color(0xFF43A047);
  static const greenSoft = Color(0xFFC8E6C9);
  static const greenTint = Color(0xFFE8F5E9);
  static const ink = Color(0xFF1F2A1F);
  static const muted = Color(0xFF6B7568);
  static const amber = Color(0xFFE6A100);
  static const amberTint = Color(0xFFFFF6D8);
  static const red = Color(0xFFC62828);
  static const redTint = Color(0xFFFDECEA);
}

/// Phones get the mobile screens; tablets/desktop keep the full layouts.
bool isPhoneWidth(double width) => width < 650;

/// The rounded header card at the top of each mobile screen.
class MobileHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final Widget? leading;
  final Widget? trailing;

  /// Show the orange "farm open" badge under the title when an admin has a
  /// farm open. Off only on screens that are never inside a farm.
  final bool showAdminFarm;

  const MobileHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.leading,
    this.trailing,
    this.showAdminFarm = true,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final farmBadge =
        showAdminFarm && adminFarmOpen(Provider.of<AuthProvider>(context));
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7FBF7),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            const SizedBox(width: 8),
            if (showBack && canPop)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: MobileColors.ink),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            else if (leading != null)
              Padding(padding: const EdgeInsets.only(left: 12), child: leading!)
            else
              const SizedBox(width: 48),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: leading != null
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign:
                        leading != null ? TextAlign.left : TextAlign.center,
                    maxLines: farmBadge ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: farmBadge ? 17 : 19,
                      fontWeight: FontWeight.w700,
                      color: MobileColors.ink,
                    ),
                  ),
                  if (farmBadge) ...[
                    const SizedBox(height: 4),
                    const AdminFarmChip(compact: true),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: trailing != null ? null : 48,
              child: trailing,
            ),
            const SizedBox(width: 12),
          ]),
        ),
      ),
    );
  }
}

/// Which bottom-bar tab a screen belongs to.
enum MobileTab { home, checklist, payslips, profile }

/// The 4-icon bottom bar. The current screen's icon sits in a big green
/// circle; tapping another goes there (replacing, so Back doesn't stack tabs).
class MobileBottomNav extends StatelessWidget {
  final MobileTab current;

  /// False on screens reached from a tab (e.g. the Compliance Tracker from
  /// Home): the tab is still highlighted, and tapping it goes back to it.
  final bool atTabRoot;

  const MobileBottomNav(
      {super.key, required this.current, this.atTabRoot = true});

  static const _routes = {
    MobileTab.home: RouteConstants.dashboard,
    MobileTab.checklist: RouteConstants.auditIndex,
    MobileTab.payslips: RouteConstants.payslipManager,
    MobileTab.profile: RouteConstants.profile,
  };

  static const _icons = {
    MobileTab.home: Icons.home_rounded,
    MobileTab.checklist: Icons.folder_rounded,
    MobileTab.payslips: Icons.request_page_rounded,
    MobileTab.profile: Icons.person_rounded,
  };

  static String _label(BuildContext context, MobileTab tab) {
    final l10n = context.l10n;
    switch (tab) {
      case MobileTab.home:
        return l10n.navHome;
      case MobileTab.checklist:
        return l10n.navAuditChecklist;
      case MobileTab.payslips:
        return l10n.navPayslips;
      case MobileTab.profile:
        return l10n.navProfile;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MobileColors.page,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final tab in MobileTab.values) _item(context, tab),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _go(BuildContext context, MobileTab tab) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminWithoutFarm = auth.isAdmin && !auth.isManagingCompany;
    final nav = Navigator.of(context);

    if (tab == MobileTab.home && adminWithoutFarm) {
      nav.pushReplacementNamed(RouteConstants.adminDashboard);
      return;
    }
    // The checklist and payslips belong to one farm. An admin with no farm
    // open picks one right here instead of landing on an empty screen.
    if (adminWithoutFarm &&
        (tab == MobileTab.checklist || tab == MobileTab.payslips)) {
      final farm = await showFarmPickerSheet(
        context,
        title: context.l10n.farmWhichFarm,
        message: tab == MobileTab.checklist
            ? context.l10n.farmPickForChecklist
            : context.l10n.farmPickForPayslips,
      );
      if (farm == null) return;
      auth.setSelectedCompany(farm);
      nav.pushNamedAndRemoveUntil(_routes[tab]!, (_) => false);
      return;
    }
    nav.pushReplacementNamed(_routes[tab]!);
  }

  Widget _item(BuildContext context, MobileTab tab) {
    final active = tab == current;
    return Semantics(
      button: true,
      selected: active,
      label: _label(context, tab),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: active && atTabRoot ? null : () => _go(context, tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 64 : 52,
          height: active ? 64 : 52,
          decoration: BoxDecoration(
            color: active ? MobileColors.green : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: MobileColors.green.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            _icons[tab],
            size: active ? 30 : 28,
            color: active ? Colors.white : const Color(0xFF4A4F49),
          ),
        ),
      ),
    );
  }
}

/// White rounded card used for list rows and panels.
class MobileCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  const MobileCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 10,
                  offset: Offset(0, 3)),
            ],
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Small coloured status pill (Approved / Pending / Rejected / Expired …).
class StatusPill extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  final IconData? icon;

  const StatusPill(
      {super.key,
      required this.label,
      required this.fg,
      required this.bg,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
        ],
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }
}

/// Big full-width green action button.
class MobilePrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;

  const MobilePrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: MobileColors.greenMid,
          disabledBackgroundColor: Colors.grey.shade300,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ]),
      ),
    );
  }
}
