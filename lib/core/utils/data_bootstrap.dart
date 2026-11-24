import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/document_provider.dart';

/// Everything a company-scoped screen (Dashboard, Compliance Tracker, Audit
/// Index, Compliance Report …) needs, loaded in ONE parallel pass instead of the
/// old chain of awaits:
///
///   categories + document types   ┐
///   the company's documents       ├─ all at once
///   the company's type overrides  ┘
///
/// Shared reference data is cached for the session, so on repeat visits this
/// resolves almost instantly. Screens call [isCompanyDataWarm] first and only
/// show their loading indicator when there is genuinely something to wait for.

String _companyIdOf(AuthProvider auth) => auth.effectiveCompany?.id ?? '';

/// True when every provider already holds the data for the active company, so a
/// screen can draw its final UI on the very first frame.
bool isCompanyDataWarm(BuildContext context, {bool withOverrides = true}) {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final docs = Provider.of<DocumentProvider>(context, listen: false);
  final cats = Provider.of<CategoryProvider>(context, listen: false);
  final companyId = _companyIdOf(auth);
  if (auth.currentUser == null || companyId.isEmpty) return false;
  return docs.currentContextCompanyId == companyId &&
      docs.hasLoadedReferenceData &&
      cats.isWarmFor(withOverrides ? companyId : '');
}

/// Loads (or refreshes) everything above for the active company.
///
/// [packages] overrides the package filter applied to the category list; by
/// default the company's own packages are used. [withOverrides] false skips the
/// per-company "switched off" document types for screens that ignore them.
Future<void> loadCompanyData(
  BuildContext context, {
  List<String>? packages,
  bool withOverrides = true,
}) async {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final docs = Provider.of<DocumentProvider>(context, listen: false);
  final cats = Provider.of<CategoryProvider>(context, listen: false);
  if (auth.currentUser == null) return;

  final companyId = _companyIdOf(auth);

  await Future.wait([
    cats.initialize(),
    docs.refreshForUserContext(context),
    if (withOverrides && companyId.isNotEmpty)
      cats.loadCompanyOverrides(companyId),
  ]);

  final filter = packages ?? auth.effectiveCompany?.packages;
  if (filter != null) cats.setPackageFilter(filter);
  if (withOverrides && companyId.isNotEmpty) {
    docs.setDeactivatedDocumentTypeIds(cats.deactivatedDocumentTypeIds);
  }
}
