import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/views/mobile/farm_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// True when an admin has a farm open (the "managing a company" mode).
bool adminFarmOpen(AuthProvider auth) =>
    auth.isAdmin && auth.isManagingCompany && auth.selectedCompany != null;

/// Leave the open farm and go back to the list of all farms.
void exitAdminFarm(BuildContext context) {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  auth.clearCompanySelection();
  Navigator.of(context)
      .pushNamedAndRemoveUntil(RouteConstants.adminDashboard, (_) => false);
}

/// Pick another farm and open its dashboard.
/// Pages that belong to one farm and take no route arguments, so they can be
/// reopened for another farm. An admin needs a farm open to see them.
const adminFarmPages = {
  RouteConstants.dashboard,
  RouteConstants.auditTracker,
  RouteConstants.complianceReport,
  RouteConstants.auditIndex,
  RouteConstants.payslipManager,
  RouteConstants.sprayRecords,
  RouteConstants.farmRegister,
  RouteConstants.farmMap,
};

/// Picks another farm. If the admin is on a farm page (e.g. Payslip Manager)
/// that page reopens for the new farm; otherwise they land on its dashboard.
Future<void> switchAdminFarm(BuildContext context) async {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final nav = Navigator.of(context);
  final here = ModalRoute.of(context)?.settings.name;
  final farm = await showFarmPickerSheet(context,
      title: context.l10n.farmSwitchFarm, currentId: auth.selectedCompany?.id);
  if (farm == null) return;
  auth.setSelectedCompany(farm);
  nav.pushNamedAndRemoveUntil(RouteConstants.dashboard, (_) => false);
  if (here != null &&
      here != RouteConstants.dashboard &&
      adminFarmPages.contains(here)) {
    nav.pushNamed(here);
  }
}

/// The orange "which farm am I in" badge an admin sees in the top bar of
/// every page while a farm is open (same look as the web app). Tap the name
/// to switch farm; tap × to go back to all farms. Draws nothing otherwise.
class AdminFarmChip extends StatelessWidget {
  /// Smaller version for under a page title in a standard app bar.
  final bool compact;

  const AdminFarmChip({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!adminFarmOpen(auth)) return const SizedBox.shrink();
    final name = auth.selectedCompany!.name;
    final font = compact ? 11.5 : 13.0;
    final icon = compact ? 14.0 : 16.0;

    return Semantics(
      label: context.l10n.farmViewing(name),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade600,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1),
          boxShadow: const [
            BoxShadow(
                color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: InkWell(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(20)),
              onTap: () => switchAdminFarm(context),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    compact ? 8 : 10, compact ? 3 : 5, 4, compact ? 3 : 5),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.business, color: Colors.white, size: icon),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: font,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            ),
          ),
          // Big enough to hit with a thumb even though the pill is small.
          Tooltip(
            message: context.l10n.farmBackToAll,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => exitAdminFarm(context),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    4, compact ? 3 : 4, compact ? 7 : 8, compact ? 3 : 4),
                child: Icon(Icons.close,
                    color: Colors.white, size: compact ? 16 : 18),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// A page title with the farm badge underneath it when an admin has a farm
/// open — for standard app bars, which have room for two short lines.
class TitleWithAdminFarm extends StatelessWidget {
  final Widget title;
  const TitleWithAdminFarm({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!adminFarmOpen(auth)) return title;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 17),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: title),
        const SizedBox(height: 3),
        const AdminFarmChip(compact: true),
      ],
    );
  }
}

/// For a standard AppBar's `bottom:` — a slim strip with the farm badge when
/// an admin has a farm open, otherwise null (no strip).
PreferredSizeWidget? adminFarmAppBarBottom(BuildContext context) {
  final auth = Provider.of<AuthProvider>(context);
  if (!adminFarmOpen(auth)) return null;
  return const PreferredSize(
    preferredSize: Size.fromHeight(36),
    child: Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AdminFarmChip(compact: true),
      ),
    ),
  );
}
