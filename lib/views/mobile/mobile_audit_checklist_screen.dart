import 'package:cropCompliance/core/constants/app_constants.dart';
import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/core/offline/pending_files_widgets.dart';
import 'package:cropCompliance/core/utils/data_bootstrap.dart';
import 'package:cropCompliance/models/category_model.dart';
import 'package:cropCompliance/models/document_model.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/document_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'compliance_journey.dart';
import 'mobile_ui.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// Audit Index for phones: pick a standard, open a category, and upload or
/// check each requirement right there.
class MobileAuditChecklistScreen extends StatefulWidget {
  const MobileAuditChecklistScreen({super.key});

  @override
  State<MobileAuditChecklistScreen> createState() =>
      _MobileAuditChecklistScreenState();
}

class _MobileAuditChecklistScreenState
    extends State<MobileAuditChecklistScreen> {
  bool _ready = false;
  String? _package;
  String? _openCategoryId;

  @override
  void initState() {
    super.initState();
    _ready = isCompanyDataWarm(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadCompanyData(context);
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final docs = Provider.of<DocumentProvider>(context);
    final packages = AppConstants.auditPackages
        .where((p) => auth.effectivePackages.contains(p.id))
        .toList();
    if (_package == null || !packages.any((p) => p.id == _package)) {
      _package = packages.isNotEmpty ? packages.first.id : null;
    }

    return Scaffold(
      backgroundColor: MobileColors.page,
      body: Column(children: [
        MobileHeader(title: context.l10n.checklistTitle),
        Expanded(
          child: !_ready
              ? const Center(child: CircularProgressIndicator())
              : packages.isEmpty
                  ? _noStandards()
                  : RefreshIndicator(
                      onRefresh: () => loadCompanyData(context),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        children: [
                          if (packages.length > 1) ...[
                            _packageChips(packages),
                            const SizedBox(height: 20),
                          ],
                          ..._categories(docs),
                        ],
                      ),
                    ),
        ),
      ]),
      bottomNavigationBar: const MobileBottomNav(current: MobileTab.checklist),
    );
  }

  Widget _noStandards() => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: 60),
          Icon(Icons.folder_off_outlined, size: 56, color: MobileColors.muted),
          SizedBox(height: 12),
          Text(context.l10n.trackerNoStandards,
              textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
          SizedBox(height: 6),
          Text(context.l10n.checklistAskAdmin,
              textAlign: TextAlign.center,
              style: TextStyle(color: MobileColors.muted)),
        ],
      );

  Widget _packageChips(List<AuditPackage> packages) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (var i = 0; i < packages.length; i++) ...[
          if (i > 0)
            Container(
                width: 1,
                height: 26,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: Colors.grey.shade400),
          GestureDetector(
            onTap: () => setState(() {
              _package = packages[i].id;
              _openCategoryId = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              decoration: BoxDecoration(
                color: _package == packages[i].id
                    ? MobileColors.greenMid
                    : MobileColors.greenSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(packages[i].label,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _package == packages[i].id
                          ? Colors.white
                          : MobileColors.ink)),
            ),
          ),
        ],
      ]),
    );
  }

  List<Widget> _categories(DocumentProvider docs) {
    final cats = orderedCategories(
        docs.categories.where((c) => c.packageId == _package));
    final types = docs.getDocumentTypesForPackages([_package!]);
    final byType = <String, List<DocumentModel>>{};
    for (final d in docs.documents) {
      byType.putIfAbsent(d.documentTypeId, () => []).add(d);
    }
    return [
      for (final c in cats)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _categoryTile(
            c,
            types.where((t) => t.categoryId == c.id).toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
            byType,
          ),
        ),
    ];
  }

  Widget _categoryTile(CategoryModel c, List<DocumentTypeModel> types,
      Map<String, List<DocumentModel>> byType) {
    final open = _openCategoryId == c.id;
    final done = types
        .where((t) => statusOf(latestDocument(byType[t.id] ?? const [])).isDone)
        .length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: open ? MobileColors.greenSoft : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Material(
          color: open ? MobileColors.greenMid : Colors.white,
          child: InkWell(
            onTap: () =>
                setState(() => _openCategoryId = open ? null : c.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              child: Row(children: [
                Icon(_iconFor(c.name),
                    color: open ? Colors.white : MobileColors.greenMid,
                    size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(_cleanName(c.name),
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: open ? Colors.white : MobileColors.ink)),
                ),
                if (types.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text('$done/${types.length}',
                        style: TextStyle(
                            fontSize: 12,
                            color: open
                                ? Colors.white70
                                : MobileColors.muted)),
                  ),
                Icon(open ? Icons.expand_less : Icons.expand_more,
                    color: open ? Colors.white : MobileColors.ink),
              ]),
            ),
          ),
        ),
        if (open) ...[
          if (types.isEmpty)
            Padding(
              padding: EdgeInsets.all(18),
              child: Text(context.l10n.checklistNothingInCategory),
            ),
          for (var i = 0; i < types.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: Colors.green.shade300),
            _itemRow(c, types[i], byType[types[i].id] ?? const []),
          ],
          InkWell(
            onTap: () => Navigator.of(context).pushNamed(
                RouteConstants.categoryDocuments,
                arguments: {'categoryId': c.id, 'categoryName': c.name}),
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Row(children: [
                Text(context.l10n.checklistSeeAllUploaded,
                    style: TextStyle(
                        color: MobileColors.green,
                        fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right, color: MobileColors.green),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _itemRow(
      CategoryModel c, DocumentTypeModel t, List<DocumentModel> docsOfType) {
    final latest = latestDocument(docsOfType);
    final status = statusOf(latest);
    final rules = [
      if (t.allowMultipleDocuments) context.l10n.ruleMultipleAllowed,
      if (t.hasExpiryDate) context.l10n.ruleHasExpiry,
      if (!t.isUploadable) context.l10n.ruleFilledInApp,
    ];

    Widget action;
    switch (status) {
      case TypeStatus.missing:
        action = _smallButton(
            t.isUploadable ? context.l10n.actionUpload : context.l10n.actionFillIn,
            t.isUploadable ? Icons.upload_outlined : Icons.edit_note,
            () => _upload(c, t, null));
        break;
      case TypeStatus.rejected:
        action = _smallButton(
            context.l10n.actionFix, Icons.refresh, () => _upload(c, t, latest), danger: true);
        break;
      case TypeStatus.expired:
        action = _smallButton(context.l10n.actionRenew, Icons.autorenew, () => _upload(c, t, latest),
            danger: true);
        break;
      case TypeStatus.approved:
        action = StatusPill(
            label: context.l10n.statusApproved,
            icon: Icons.check_circle_outline,
            fg: MobileColors.green,
            bg: Colors.white);
        break;
      case TypeStatus.pending:
        action = StatusPill(
            label: context.l10n.statusInReview,
            icon: Icons.hourglass_top,
            fg: Color(0xFF8A5A00),
            bg: MobileColors.amberTint);
        break;
      case TypeStatus.notApplicable:
        action = StatusPill(
            label: context.l10n.statusNotApplicable, fg: MobileColors.muted, bg: Colors.white);
        break;
    }

    return InkWell(
      onTap: latest != null
          ? () => Navigator.of(context).pushNamed(RouteConstants.documentDetail,
              arguments: {'documentId': latest.id})
          : () => _upload(c, t, null),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name,
                  style: const TextStyle(
                      fontSize: 15.5, color: MobileColors.ink, height: 1.25)),
              if (rules.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(rules.join(' · '),
                      style: const TextStyle(
                          fontSize: 12.5, color: Color(0xFF4E5A4C))),
                ),
              if (latest != null && latest.hasPendingFiles)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: PendingUploadChip(document: latest),
                ),
            ]),
          ),
          const SizedBox(width: 10),
          action,
        ]),
      ),
    );
  }

  Widget _smallButton(String label, IconData icon, VoidCallback onTap,
      {bool danger = false}) {
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: danger ? MobileColors.red : MobileColors.greenMid,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }

  void _upload(CategoryModel c, DocumentTypeModel t, DocumentModel? existing) {
    if (!t.isUploadable) {
      Navigator.of(context).pushNamed(RouteConstants.documentForm,
          arguments: {'categoryId': c.id, 'documentTypeId': t.id});
      return;
    }
    Navigator.of(context).pushNamed(RouteConstants.documentUpload, arguments: {
      'categoryId': c.id,
      'documentTypeId': t.id,
      if (existing != null) 'existingDocumentId': existing.id,
    });
  }

  /// "3. Forced Labour" → "Forced Labour" (numbers are for the desktop index).
  String _cleanName(String name) =>
      name.replaceFirst(RegExp(r'^\s*\d+[.)]\s*'), '');

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    bool has(List<String> w) => w.any(n.contains);
    if (has(['business', 'company', 'general', 'certification'])) {
      return Icons.apartment_outlined;
    }
    if (has(['management', 'system', 'commitment'])) {
      return Icons.settings_outlined;
    }
    if (has(['employ', 'condition', 'contract'])) return Icons.people_outline;
    if (has(['forced', 'discrimination', 'protection'])) {
      return Icons.shield_outlined;
    }
    if (has(['child', 'young'])) return Icons.child_care_outlined;
    if (has(['wage', 'hours', 'premium', 'payment'])) {
      return Icons.payments_outlined;
    }
    if (has(['association', 'bargaining', 'union'])) {
      return Icons.groups_outlined;
    }
    if (has(['training', 'capacity', 'development'])) {
      return Icons.school_outlined;
    }
    if (has(['inspection', 'monitor', 'audit', 'corrective'])) {
      return Icons.verified_user_outlined;
    }
    if (has(['health', 'safety', 'medical'])) return Icons.health_and_safety_outlined;
    if (has(['chemical', 'pesticide', 'hazard', 'spray'])) {
      return Icons.science_outlined;
    }
    if (has(['environment', 'water', 'soil', 'waste', 'biodiversity'])) {
      return Icons.eco_outlined;
    }
    if (has(['trade', 'traceab'])) return Icons.local_shipping_outlined;
    if (has(['human rights', 'hredd', 'grievance'])) { // l10n-ignore: matches stored English names
      return Icons.balance_outlined;
    }
    return Icons.description_outlined;
  }
}
