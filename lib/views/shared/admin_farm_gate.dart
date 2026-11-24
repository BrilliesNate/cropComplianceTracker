import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/locale_provider.dart';
import 'package:cropCompliance/views/dashboard/admin_dashboard_screen.dart';
import 'package:cropCompliance/views/mobile/farm_picker_sheet.dart';
import 'package:cropCompliance/views/mobile/mobile_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cropCompliance/views/shared/app_scaffold_wrapper.dart';

/// Farm pages (dashboard, tracker, report, audit index, payslips…) show ONE
/// farm. An admin with no farm open used to land on them anyway and see their
/// own account's company — while the rest of the app correctly treated them
/// as having no farm open. Now:
///  * the Dashboard becomes the Admin Dashboard;
///  * any other farm page first asks "Which farm?" right there, then opens.
class AdminFarmGate extends StatelessWidget {
  final Widget child;

  /// The Dashboard: show the Admin Dashboard instead of asking.
  final bool isDashboard;

  const AdminFarmGate(
      {super.key, required this.child, this.isDashboard = false});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final noFarmOpen = auth.isAdmin && !auth.isManagingCompany;
    if (!noFarmOpen) return child;
    if (isDashboard) return const AdminDashboardScreen();

    final l10n = context.l10n;
    // Phones: the phone design. Web / tablet: the normal web page (green bar,
    // side menu) with the farm list in a card.
    if (!isPhoneWidth(MediaQuery.of(context).size.width)) {
      return AppScaffoldWrapper(
        title: l10n.farmWhichFarm,
        backgroundColor: Colors.grey.shade50,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 1,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Row(children: [
                      Icon(Icons.agriculture_outlined,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l10n.farmWhichFarm,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context)
                            .pushReplacementNamed(
                                RouteConstants.adminDashboard),
                        icon: const Icon(Icons.grid_view, size: 18),
                        label: Text(l10n.farmBackToAll),
                      ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(l10n.farmPickForPage,
                          style: TextStyle(color: Colors.grey.shade700)),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    // Opening the farm rebuilds this gate, which then shows
                    // the page.
                    child: FarmPickerList(onPick: auth.setSelectedCompany),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
    }

    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: MobileColors.page,
      body: Column(children: [
        MobileHeader(
          title: l10n.farmWhichFarm,
          showBack: true,
          showAdminFarm: false,
          leading: canPop
              ? null
              : IconButton(
                  tooltip: l10n.farmBackToAll,
                  icon: const Icon(Icons.arrow_back, color: MobileColors.ink),
                  onPressed: () => Navigator.of(context)
                      .pushReplacementNamed(RouteConstants.adminDashboard),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
          child: Text(l10n.farmPickForPage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: MobileColors.muted, fontSize: 15)),
        ),
        Expanded(
          // Opening the farm rebuilds this gate, which then shows the page.
          child: FarmPickerList(onPick: auth.setSelectedCompany),
        ),
      ]),
    );
  }
}
