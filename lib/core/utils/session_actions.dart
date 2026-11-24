import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/route_constants.dart';
import '../services/firestore_service.dart';
import '../services/push_notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/route_provider.dart';

/// Top-level screens that make sense to stay on after switching farm. Anything
/// else (the My Farms picker, a payslip detail, a single document, …) lands the
/// user on the first screen inside the new farm instead.
const Set<String> _staysOnSwitch = {
  RouteConstants.dashboard,
  RouteConstants.auditTracker,
  RouteConstants.complianceReport,
  RouteConstants.auditIndex,
  RouteConstants.payslipManager,
  RouteConstants.sprayRecords,
  RouteConstants.farmRegister,
};

/// Signs the user out and wipes everything cached for them, so the next person
/// to sign in on this browser/device (e.g. an auditor after an admin) can never
/// glimpse the previous user's documents, however briefly.
Future<void> signOutAndReset(BuildContext context) async {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final docs = Provider.of<DocumentProvider>(context, listen: false);
  final cats = Provider.of<CategoryProvider>(context, listen: false);
  final route = Provider.of<RouteProvider>(context, listen: false);
  final navigator = Navigator.of(context);

  docs.clearContext();
  cats.clearCompanyOverrides();
  FirestoreService.invalidateReferenceData();
  PushNotificationService.instance.markSignedOut();
  await auth.logout();
  route.setActiveRoute(RouteConstants.login);
  navigator.pushNamedAndRemoveUntil(RouteConstants.login, (_) => false);
}

/// Switches a multi-farm user to [companyId] and reloads the current screen for
/// that farm. Returns false if the user isn't allowed that farm.
Future<bool> switchFarm(BuildContext context, String companyId) async {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final docs = Provider.of<DocumentProvider>(context, listen: false);
  final cats = Provider.of<CategoryProvider>(context, listen: false);
  final route = Provider.of<RouteProvider>(context, listen: false);
  final navigator = Navigator.of(context);
  final current = ModalRoute.of(context)?.settings.name;

  final switched = await auth.switchCompany(companyId);
  if (!switched) return false;

  // Drop everything belonging to the previous farm before any screen reloads.
  docs.clearContext();
  cats.clearCompanyOverrides();

  var target = (current != null && _staysOnSwitch.contains(current))
      ? current
      : auth.farmHomeRoute;
  final needsFarmable =
      target == RouteConstants.farmRegister || target == RouteConstants.sprayRecords;
  if (needsFarmable && auth.effectiveCompany?.hasFarmable != true) {
    target = auth.farmHomeRoute;
  }

  route.setActiveRoute(target);
  navigator.pushReplacementNamed(target);
  return true;
}
