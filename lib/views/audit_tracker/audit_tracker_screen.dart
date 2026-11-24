import 'dart:developer' as developer;

import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/core/utils/data_bootstrap.dart';
import 'package:cropCompliance/core/constants/app_constants.dart';
import 'package:cropCompliance/models/category_model.dart';
import 'package:cropCompliance/models/document_model.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:cropCompliance/models/enums.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/category_provider.dart';
import 'package:cropCompliance/providers/document_provider.dart';
import 'package:cropCompliance/theme/theme_constants.dart';
import 'package:cropCompliance/views/shared/app_scaffold_wrapper.dart';
import 'package:cropCompliance/views/shared/error_display.dart';
import 'package:cropCompliance/views/shared/loading_indicator.dart';
import 'package:cropCompliance/views/shared/status_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

// Timing/trace output used while profiling. Off by default: logging from inside
// build() on every rebuild is itself a noticeable cost in debug builds.
const bool _kTrackerTrace = false;
void _tlog(String message) {
  if (_kTrackerTrace) developer.log(message);
}

class AuditTrackerScreen extends StatefulWidget {
  const AuditTrackerScreen({Key? key}) : super(key: key);

  @override
  State<AuditTrackerScreen> createState() => _AuditTrackerScreenState();
}

class _AuditTrackerScreenState extends State<AuditTrackerScreen> {
  bool _showDocuments = true; // Toggle between Documents and Audit List views
  Map<String, bool> _expandedCategories = {};
  Stopwatch _stopwatch = Stopwatch();
  String _selectedPackage = 'siza_wieta'; // NEW: Selected package filter

  late bool _ready; // one loader, then the finished page (no half-filled UI)

  @override
  void initState() {
    super.initState();
    _ready = isCompanyDataWarm(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    // Initial package filter: the company's first available package.
    final packages = authProvider.effectivePackages;
    if (packages.isNotEmpty) _selectedPackage = packages.first;

    try {
      // Categories, documents and the company's switched-off document types
      // load together, so the first thing drawn already has the final numbers.
      await loadCompanyData(
        context,
        packages: packages.isNotEmpty ? [_selectedPackage] : null,
      );
    } finally {
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    _tlog('AuditTrackerScreen - build method called');
    _stopwatch.reset();
    _stopwatch.start();

    final authProvider = Provider.of<AuthProvider>(context);
    _tlog('AuditTrackerScreen - build: authProvider accessed: ${_stopwatch.elapsedMilliseconds}ms');

    final documentProvider = Provider.of<DocumentProvider>(context);
    _tlog('AuditTrackerScreen - build: documentProvider accessed: ${_stopwatch.elapsedMilliseconds}ms');

    final categoryProvider = Provider.of<CategoryProvider>(context);
    _tlog('AuditTrackerScreen - build: categoryProvider accessed: ${_stopwatch.elapsedMilliseconds}ms');

    if (authProvider.currentUser == null) {
      _tlog('AuditTrackerScreen - build: No user logged in, showing login prompt');
      return Scaffold(
        body: Center(
          child: Text(context.l10n.pleaseLogIn),
        ),
      );
    }

    final isLoading = !_ready || documentProvider.isLoading || categoryProvider.isLoading;
    final hasError = documentProvider.error != null || categoryProvider.error != null;
    final error = documentProvider.error ?? categoryProvider.error ?? '';

    _tlog('AuditTrackerScreen - build: isLoading=$isLoading, hasError=$hasError');

    Widget content;
    if (isLoading) {
      _tlog('AuditTrackerScreen - build: Showing loading indicator');
      content = LoadingIndicator(message: context.l10n.trackerLoading);
    } else if (hasError) {
      _tlog('AuditTrackerScreen - build: Showing error: $error');
      content = ErrorDisplay(
        error: error,
        onRetry: () {
          setState(() => _ready = false);
          _initializeData();
        },
      );
    } else {
      _stopwatch.reset();
      _stopwatch.start();
      _tlog('AuditTrackerScreen - build: Starting to build content sections');

      _tlog('AuditTrackerScreen - build: Building KPI section');
      final kpiSection = _buildKPISection(documentProvider, authProvider);
      _tlog('AuditTrackerScreen - build: KPI section built: ${_stopwatch.elapsedMilliseconds}ms');

      _tlog('AuditTrackerScreen - build: Building toggle buttons');
      final toggleButtons = _buildViewToggleButtons();
      _tlog('AuditTrackerScreen - build: Toggle buttons built: ${_stopwatch.elapsedMilliseconds}ms');

      _tlog('AuditTrackerScreen - build: Preparing main content view (documents or audit list)');

      // Check if mobile before building content
      final isMobile = MediaQuery.of(context).size.width < 600;

      // NEW: Build package toggle (only when Audit Checklist is selected and company has both packages)
      final packageToggle = (!_showDocuments && authProvider.hasBothPackages)
          ? _buildPackageToggle(authProvider, categoryProvider)
          : const SizedBox.shrink();

      if (isMobile) {
        // MOBILE: Everything in one scrollable list
        content = ListView(
          children: [
            kpiSection,
            toggleButtons,
            packageToggle, // NEW
            _showDocuments
                ? _buildDocumentsViewMobile(documentProvider, categoryProvider)
                : _buildAuditListViewMobile(documentProvider, categoryProvider),
          ],
        );
      } else {
        // DESKTOP: Fixed KPI and toggle, scrollable content
        final mainContent = _showDocuments
            ? _buildDocumentsView(documentProvider, categoryProvider)
            : _buildAuditListView(documentProvider, categoryProvider);

        content = Column(
          children: [
            kpiSection,
            toggleButtons,
            packageToggle, // NEW
            Expanded(child: mainContent),
          ],
        );
      }

      _tlog('AuditTrackerScreen - build: Content column assembled: ${_stopwatch.elapsedMilliseconds}ms');
    }

    _stopwatch.stop();
    _tlog('AuditTrackerScreen - build method completed: ${_stopwatch.elapsedMilliseconds}ms');

    return AppScaffoldWrapper(
      title: context.l10n.trackerTitle,
      backgroundColor: ThemeConstants.lightBackgroundColor,
      child: content,
    );
  }

  Widget _buildKPISection(DocumentProvider documentProvider, AuthProvider authProvider) {
    _stopwatch.reset();
    _stopwatch.start();
    _tlog('AuditTrackerScreen - _buildKPISection started');

    // ============================================
    // UPDATED: Use package-aware filtering for KPI metrics
    // ============================================

    // Get the company's packages
    final companyPackages = authProvider.effectivePackages;

    // Use the new package-aware method to get compliance stats
    final complianceStats = documentProvider.getComplianceStatsForPackages(companyPackages);

    final totalDocuments = complianceStats['totalDocTypes'] as int;
    final uploadedDocuments = complianceStats['uploadedDocs'] as int;
    final approvedDocuments = complianceStats['approvedDocs'] as int;
    final pendingDocuments = complianceStats['pendingDocs'] as int;
    final rejectedDocuments = complianceStats['rejectedDocs'] as int;

    _tlog('AuditTrackerScreen - KPI counts (filtered by packages: $companyPackages) - '
        'total: $totalDocuments, '
        'uploaded: $uploadedDocuments, '
        'approved: $approvedDocuments, '
        'pending: $pendingDocuments, '
        'rejected: $rejectedDocuments');

    // Calculate completion percentage
    double completionPercentage = 0;
    if (totalDocuments > 0) {
      completionPercentage = (uploadedDocuments / totalDocuments) * 100;
    }

    // Calculate approval rate percentage
    double approvalRate = 0;
    if (uploadedDocuments > 0) {
      approvalRate = (approvedDocuments / uploadedDocuments) * 100;
    }

    // Completion per standard the company is enrolled in (in the app's
    // standard order). Categories belong to exactly one standard, so these add
    // up to the overall figure.
    final standards = <_StandardProgress>[];
    for (final p in AppConstants.auditPackages) {
      if (!companyPackages.contains(p.id)) continue;
      final s = documentProvider.getComplianceStatsForPackages([p.id]);
      standards.add(_StandardProgress(
        p.label,
        s['uploadedDocs'] as int,
        s['totalDocTypes'] as int,
      ));
    }

    // Check if we're on a small screen
    final isMobile = MediaQuery.of(context).size.width < 600;

    final result = Container(
      padding: isMobile ? const EdgeInsets.all(8) : const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCompletionCard(uploadedDocuments, totalDocuments,
                  completionPercentage, standards),
              const SizedBox(height: 6),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildKPICard(
                        context.l10n.kpiApproval,
                        '$approvedDocuments/$uploadedDocuments',
                        '${approvalRate.toStringAsFixed(1)}%',
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildKPICard(
                        context.l10n.statusPending,
                        '$pendingDocuments',
                        pendingDocuments > 0 ? context.l10n.kpiActionNeeded : context.l10n.kpiAllClear,
                        Colors.orange,
                        Icons.hourglass_empty,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildKPICard(
                        context.l10n.statusRejected,
                        '$rejectedDocuments',
                        rejectedDocuments > 0 ? context.l10n.kpiFixRequired : context.l10n.kpiAllClear,
                        Colors.red,
                        Icons.error_outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
              : IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _buildCompletionCard(uploadedDocuments, totalDocuments,
                    completionPercentage, standards),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  context.l10n.kpiApprovalRate,
                  '$approvedDocuments/$uploadedDocuments',
                  '${approvalRate.toStringAsFixed(1)}%',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  context.l10n.kpiPendingReview,
                  '$pendingDocuments',
                  pendingDocuments > 0 ? context.l10n.kpiActionNeeded : context.l10n.kpiAllClear,
                  Colors.orange,
                  Icons.hourglass_empty,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  context.l10n.kpiRejectedItems,
                  '$rejectedDocuments',
                  rejectedDocuments > 0 ? context.l10n.kpiNeedsAttention : context.l10n.kpiAllClear,
                  Colors.red,
                  Icons.error_outline,
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );

    _stopwatch.stop();
    _tlog('AuditTrackerScreen - _buildKPISection completed: ${_stopwatch.elapsedMilliseconds}ms');

    return result;
  }
  Widget _buildDocumentsViewMobile(DocumentProvider documentProvider, CategoryProvider categoryProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.currentUser?.role == UserRole.ADMIN;

    bool isExpiringSoon(DocumentModel doc) {
      if (doc.effectiveExpiryDate == null) return false;
      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));
      return doc.effectiveExpiryDate!.isBefore(thirtyDaysFromNow) || doc.effectiveExpiryDate!.isAtSameMomentAs(thirtyDaysFromNow);
    }

    final documents = _showApprovedDocuments
        ? documentProvider.documents.where((doc) => !doc.isSuperseded && doc.status == DocumentStatus.APPROVED && !doc.isExpired && !isExpiringSoon(doc)).toList()
        : documentProvider.documents.where((doc) => !doc.isSuperseded && (doc.status != DocumentStatus.APPROVED || doc.isExpired || isExpiringSoon(doc))).toList();

    if (documents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(_showApprovedDocuments ? context.l10n.trackerNoApproved : context.l10n.trackerNoActionItems),
        ),
      );
    }

    return Column(
      children: [
        // Filter toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(context.l10n.filterColon),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(context.l10n.trackerActionItems),
                selected: !_showApprovedDocuments,
                onSelected: (selected) {
                  if (selected) setState(() => _showApprovedDocuments = false);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(context.l10n.trackerApprovedCurrent),
                selected: _showApprovedDocuments,
                onSelected: (selected) {
                  if (selected) setState(() => _showApprovedDocuments = true);
                },
              ),
            ],
          ),
        ),

        // Document list with shrinkWrap
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final document = documents[index];

            // Find document type
            DocumentTypeModel? documentType;
            try {
              documentType = documentProvider.documentTypes.firstWhere((dt) => dt.id == document.documentTypeId) as DocumentTypeModel?;
            } catch (_) {
              documentType = null;
            }

            // Find category
            CategoryModel category;
            try {
              category = categoryProvider.categories.firstWhere((c) => c.id == document.categoryId);
            } catch (_) {
              category = CategoryModel(id: document.categoryId, name: context.l10n.unknownCategory, description: '', order: 0, packageId: 'siza_wieta');
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: _buildMobileDocumentCard(document, documentType?.name ?? context.l10n.unknown, category.name, isAdmin),
            );
          },
        ),
      ],
    );
  }

// MOBILE VERSION - Uses shrinkWrap
  Widget _buildAuditListViewMobile(DocumentProvider documentProvider, CategoryProvider categoryProvider) {
    // Only show categories that have at least one active document type
    final categories = categoryProvider.categories
        .where((c) => documentProvider.documentTypes.any((dt) => dt.categoryId == c.id))
        .toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        if (!_expandedCategories.containsKey(category.id)) {
          _expandedCategories[category.id] = false;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              ListTile(
                leading: Icon(_getCategoryIcon(category.name), color: Theme.of(context).primaryColor),
                title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: Icon(_expandedCategories[category.id]! ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                  onPressed: () => setState(() => _expandedCategories[category.id] = !_expandedCategories[category.id]!),
                ),
                onTap: () => setState(() => _expandedCategories[category.id] = !_expandedCategories[category.id]!),
              ),
              if (_expandedCategories[category.id]!) ...[
                const Divider(height: 1),
                _buildDocumentTypesList(category.id, documentProvider, true),
              ],
            ],
          ),
        );
      },
    );
  }

  /// The green Completion Rate card: the overall figure on the left and one
  /// progress bar per standard the company is enrolled in. Stacks vertically on
  /// phones; nothing in it can overflow (names ellipsize, numbers scale down).
  Widget _buildCompletionCard(int uploaded, int total, double percentage,
      List<_StandardProgress> standards) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final green = Theme.of(context).primaryColor;

    final arrow = Container(
      width: isMobile ? 24 : 34,
      height: isMobile ? 24 : 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.22),
      ),
      child: Icon(Icons.north_east,
          size: isMobile ? 13 : 17, color: Colors.white),
    );

    final overall = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '$uploaded/$total',
            style: TextStyle(
              fontSize: isMobile ? 26 : 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 4 : 6),
        Text(
          context.l10n.percentOverall(percentage.toStringAsFixed(1)),
          style: TextStyle(
            fontSize: isMobile ? 11 : 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.85),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final breakdown = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < standards.length; i++) ...[
          if (i > 0) SizedBox(height: isMobile ? 8 : 10),
          _buildStandardBar(standards[i], isMobile),
        ],
      ],
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  context.l10n.kpiCompletionRate,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: isMobile ? 12 : 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              arrow,
            ],
          ),
          SizedBox(height: isMobile ? 8 : 14),
          if (standards.isEmpty)
            overall
          else if (isMobile) ...[
            overall,
            const SizedBox(height: 12),
            breakdown,
          ] else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    flex: 4,
                    child: Align(alignment: Alignment.centerLeft, child: overall),
                  ),
                  const SizedBox(width: 20),
                  // Thin divider, as tall as the per-standard bars.
                  Container(width: 1, color: Colors.white.withOpacity(0.25)),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 6,
                    child: Align(alignment: Alignment.centerLeft, child: breakdown),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStandardBar(_StandardProgress s, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${s.done}/${s.total}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: isMobile ? 10 : 11,
              ),
            ),
            SizedBox(
              width: isMobile ? 38 : 44,
              child: Text(
                '${s.percent.round()}%',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: s.fraction,
            minHeight: isMobile ? 5 : 6,
            backgroundColor: Colors.white.withOpacity(0.22),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(
      String title, String value, String subtitle, Color color, IconData icon,
      {bool primary = false}) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final green = Theme.of(context).primaryColor;

    final bg = primary ? green : Colors.white;
    final titleColor = primary ? Colors.white : const Color(0xFF5A6270);
    final valueColor = primary ? Colors.white : const Color(0xFF1A1D22);
    final subtitleColor =
        primary ? Colors.white.withOpacity(0.85) : Colors.grey.shade500;

    // Circular arrow badge (↗) top-right.
    final arrow = Container(
      width: isMobile ? 24 : 34,
      height: isMobile ? 24 : 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primary ? Colors.white.withOpacity(0.22) : Colors.white,
        border: primary
            ? null
            : Border.all(color: Colors.grey.shade200),
      ),
      child: Icon(Icons.north_east,
          size: isMobile ? 13 : 17,
          color: primary ? Colors.white : const Color(0xFF1A1D22)),
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: primary ? null : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(primary ? 0.10 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                    fontSize: isMobile ? 12 : 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              arrow,
            ],
          ),
          SizedBox(height: isMobile ? 8 : 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 20 : 34,
                fontWeight: FontWeight.w800,
                color: valueColor,
                height: 1,
                letterSpacing: -0.5,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 2 : 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isMobile ? 10 : 13,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }



  Widget _buildViewToggleButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showDocuments = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _showDocuments
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                foregroundColor: _showDocuments ? Colors.white : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                context.l10n.trackerActionItems,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showDocuments = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: !_showDocuments
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                foregroundColor:
                !_showDocuments ? Colors.white : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                context.l10n.checklistTitle,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _packageIcon(String id) {
    switch (id) {
      case 'globalgap':
        return Icons.eco;
      case 'ipw':
        return Icons.wine_bar;
      case 'fairtrade':
        return Icons.handshake_outlined;
      case 'siza_environmental':
        return Icons.forest_outlined;
      default:
        return Icons.people;
    }
  }

  // Package toggle buttons — rendered from the company's enabled packages.
  Widget _buildPackageToggle(AuthProvider authProvider, CategoryProvider categoryProvider) {
    final enabled = AppConstants.auditPackages
        .where((p) => authProvider.effectivePackages.contains(p.id))
        .toList();
    if (enabled.length < 2) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < enabled.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: _buildPackageButton(
                packageId: enabled[i].id,
                label: enabled[i].label,
                icon: _packageIcon(enabled[i].id),
                isSelected: _selectedPackage == enabled[i].id,
                categoryProvider: categoryProvider,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPackageButton({
    required String packageId,
    required String label,
    required IconData icon,
    required bool isSelected,
    required CategoryProvider categoryProvider,
  }) {
    return Material(
      color: isSelected
          ? Theme.of(context).primaryColor
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: isSelected ? 4 : 2,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPackage = packageId;
          });
          categoryProvider.setPackageFilter([packageId]);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // State variable for showing approved documents
  bool _showApprovedDocuments = false;

  // Documents View (Action Items)
  Widget _buildDocumentsView(
      DocumentProvider documentProvider, CategoryProvider categoryProvider) {
    _stopwatch.reset();
    _stopwatch.start();
    _tlog('AuditTrackerScreen - _buildDocumentsView started');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserRole = authProvider.currentUser?.role;
    final isAdmin = currentUserRole == UserRole.ADMIN;

    // Helper method to check if document is expiring soon (within 30 days)
    bool isExpiringSoon(DocumentModel doc) {
      if (doc.effectiveExpiryDate == null) return false;

      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));

      return doc.effectiveExpiryDate!.isBefore(thirtyDaysFromNow) || doc.effectiveExpiryDate!.isAtSameMomentAs(thirtyDaysFromNow);
    }

    // Filter documents based on the _showApprovedDocuments toggle
    final documents = _showApprovedDocuments
        ? documentProvider.documents.where((doc) {
      // For "Approved Documents" filter: only show approved documents that are NOT expired and NOT expiring soon
      return !doc.isSuperseded &&
          doc.status == DocumentStatus.APPROVED &&
          !doc.isExpired &&
          !isExpiringSoon(doc);
    }).toList()
        : documentProvider.documents.where((doc) {
      // For "Action Items" filter: show documents that need attention — but a
      // superseded (replaced) document is no longer an action item.
      if (doc.isSuperseded) return false;
      return doc.status != DocumentStatus.APPROVED ||  // Not approved documents
          doc.isExpired ||                           // OR expired documents (even if approved)
          isExpiringSoon(doc);                       // OR documents expiring within 30 days (even if approved)
    }).toList();

    _tlog('AuditTrackerScreen - Filtered ${documents.length} documents to display');

    if (documents.isEmpty) {
      _tlog('AuditTrackerScreen - No documents to display in this filter');
      return Center(
        child: Text(_showApprovedDocuments
            ? context.l10n.trackerNoApprovedCurrent
            : context.l10n.trackerNoActionItems),
      );
    }

    // Add a filter option at the top
    final result = Column(
      children: [
        // Filter toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(context.l10n.filterColon),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(context.l10n.trackerActionItems),
                selected: !_showApprovedDocuments,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _showApprovedDocuments = false;
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(context.l10n.trackerApprovedCurrent),
                selected: _showApprovedDocuments,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _showApprovedDocuments = true;
                    });
                  }
                },
              ),
            ],
          ),
        ),

        // Document list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];

              // Find document type and category details
              DocumentTypeModel? documentType;
              try {
                _stopwatch.reset();
                _stopwatch.start();
                documentType = documentProvider.documentTypes
                    .firstWhere((dt) => dt.id == document.documentTypeId)
                as DocumentTypeModel?;
                _tlog('AuditTrackerScreen - Found document type for document ${index+1}/${documents.length}: ${_stopwatch.elapsedMilliseconds}ms');
              } catch (_) {
                _tlog('AuditTrackerScreen - Document type not found for document ${index+1}/${documents.length}');
                documentType = null;
              }

              // Find category details
              CategoryModel? category;
              try {
                _stopwatch.reset();
                _stopwatch.start();
                category = categoryProvider.categories
                    .firstWhere((c) => c.id == document.categoryId);
                _tlog('AuditTrackerScreen - Found category for document ${index+1}/${documents.length}: ${_stopwatch.elapsedMilliseconds}ms');
              } catch (e) {
                _tlog('AuditTrackerScreen - Category not found for document ${index+1}/${documents.length}: ${e.toString()}');
                // Category not found, create a placeholder
                category = CategoryModel(
                  id: document.categoryId,
                  name: context.l10n.unknownCategory,
                  description: '',
                  order: 0,
                  packageId: 'siza_wieta',
                );
              }

              final documentName =
                  documentType?.name ?? context.l10n.unknownDocumentType;
              final categoryName = category.name;

              // Check if we're on a small screen
              final isSmallScreen = MediaQuery.of(context).size.width < 600;

              _stopwatch.reset();
              _stopwatch.start();
              final card = Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: isSmallScreen
                    ? _buildMobileDocumentCard(
                    document, documentName, categoryName, isAdmin)
                    : _buildDesktopDocumentCard(
                    document, documentName, categoryName, isAdmin),
              );
              _tlog('AuditTrackerScreen - Built card for document ${index+1}/${documents.length}: ${_stopwatch.elapsedMilliseconds}ms');

              return card;
            },
          ),
        ),
      ],
    );

    _stopwatch.stop();
    _tlog('AuditTrackerScreen - _buildDocumentsView completed: ${_stopwatch.elapsedMilliseconds}ms');

    return result;
  }

  // Mobile document card with comments and expiry warnings
  Widget _buildMobileDocumentCard(DocumentModel document, String documentName,
      String categoryName, bool isAdmin) {

    // Helper method to check if document is expiring soon (within 30 days)
    bool isExpiringSoon(DocumentModel doc) {
      if (doc.effectiveExpiryDate == null) return false;

      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));

      return doc.effectiveExpiryDate!.isBefore(thirtyDaysFromNow) || doc.effectiveExpiryDate!.isAtSameMomentAs(thirtyDaysFromNow);
    }

    // Helper method to get days until expiry
    int? getDaysUntilExpiry(DocumentModel doc) {
      if (doc.effectiveExpiryDate == null) return null;

      final now = DateTime.now();
      final difference = doc.effectiveExpiryDate!.difference(now).inDays;

      return difference;
    }

    final daysUntilExpiry = getDaysUntilExpiry(document);
    final isExpiringSoonFlag = isExpiringSoon(document);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document name and status
          Row(
            children: [
              Expanded(
                child: Text(
                  documentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              document.isNotApplicable
                  ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              )
                  : StatusBadge(
                status: document.status,
                isExpired: document.isExpired,
                isExpiringSoon: isExpiringSoonFlag,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Category info
          Row(
            children: [
              Icon(
                _getCategoryIcon(categoryName),
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  categoryName,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Expiry date with enhanced warnings
          if (document.effectiveExpiryDate != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: document.isExpired
                    ? Colors.red.shade50
                    : isExpiringSoonFlag
                    ? Colors.orange.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: document.isExpired
                      ? Colors.red.shade300
                      : isExpiringSoonFlag
                      ? Colors.orange.shade300
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    document.isExpired
                        ? Icons.error
                        : isExpiringSoonFlag
                        ? Icons.warning
                        : Icons.schedule,
                    size: 14,
                    color: document.isExpired
                        ? Colors.red
                        : isExpiringSoonFlag
                        ? Colors.orange
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.isExpired
                              ? context.l10n.expiredCaps
                              : isExpiringSoonFlag
                              ? context.l10n.expiresSoonCaps
                              : context.l10n.colExpires,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: document.isExpired
                                ? Colors.red
                                : isExpiringSoonFlag
                                ? Colors.orange
                                : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, y').format(document.effectiveExpiryDate!),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: document.isExpired
                                ? Colors.red
                                : isExpiringSoonFlag
                                ? Colors.orange
                                : Colors.grey.shade700,
                          ),
                        ),
                        if (daysUntilExpiry != null && !document.isExpired)
                          Text(
                            daysUntilExpiry > 0
                                ? context.l10n.daysLeft(daysUntilExpiry)
                                : context.l10n.expiresToday,
                            style: TextStyle(
                              fontSize: 10,
                              color: isExpiringSoonFlag
                                  ? Colors.orange.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Show renewal/update prompt for expired or expiring soon approved documents
          if ((document.isExpired || isExpiringSoonFlag) && document.status == DocumentStatus.APPROVED) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: document.isExpired ? Colors.red.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: document.isExpired ? Colors.red.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    document.isExpired ? Icons.error : Icons.warning,
                    size: 16,
                    color: document.isExpired ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      document.isExpired
                          ? context.l10n.docExpiredRenew
                          : context.l10n.docExpiresSoonRenew,
                      style: TextStyle(
                        fontSize: 12,
                        color: document.isExpired ? Colors.red.shade700 : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Comments section
          if (document.comments.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            Text(
              context.l10n.commentsColon,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            ...document.comments.map((comment) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, y').format(comment.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comment.text,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          const SizedBox(height: 12),

          // Action buttons
          if (document.status == DocumentStatus.REJECTED ||
              (document.status == DocumentStatus.APPROVED && (document.isExpired || isExpiringSoonFlag))) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(
                  document.status == DocumentStatus.REJECTED ? Icons.refresh : Icons.update,
                  color: Colors.white,
                  size: 16,
                ),
                label: Text(document.status == DocumentStatus.REJECTED
                    ? context.l10n.actionResubmit
                    : context.l10n.uploadNewVersion),
                onPressed: () {
                  // Navigate to document upload/form screen with existing document ID
                  Navigator.of(context).pushNamed(
                    RouteConstants.documentUpload,
                    arguments: {
                      'categoryId': document.categoryId,
                      'documentTypeId': document.documentTypeId,
                      'existingDocumentId': document.id,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // View/Update document button (available to all users)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.visibility, size: 16),
              label: Text(context.l10n.actionViewDetails),
              onPressed: () {
                Navigator.of(context).pushNamed(
                  RouteConstants.documentDetail,
                  arguments: {'documentId': document.id},
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 8),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Delete button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete, size: 16),
              label: Text(context.l10n.actionDelete),
              onPressed: () => _showDeleteConfirmation(context, document),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 8),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),

        ],
      ),
    );
  }


  Future<void> _showDeleteConfirmation(BuildContext context, DocumentModel document) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteDocTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.deleteDocConfirm),
            const SizedBox(height: 16),
            Text(
              context.l10n.deleteDocWarning,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.l10n.actionDelete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteDocument(document);
    }
  }

  Future<void> _deleteDocument(DocumentModel document) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text(context.l10n.deletingDoc),
            ],
          ),
        ),
      );

      final success = await documentProvider.deleteDocument(
        documentId: document.id,
        user: authProvider.currentUser!,
        reason: 'Deleted by admin ${authProvider.currentUser!.name}', // l10n-ignore: stored audit log
      );

      // Hide loading
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.docDeleted),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.docDeleteFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading if still showing
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.docDeleteError('$e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Desktop document card with comments - simplified
  Widget _buildDesktopDocumentCard(DocumentModel document, String documentName,
      String categoryName, bool isAdmin) {

    // Helper method to check if document is expiring soon (within 30 days)
    bool isExpiringSoon(DocumentModel doc) {
      if (doc.effectiveExpiryDate == null) return false;

      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));

      return doc.effectiveExpiryDate!.isBefore(thirtyDaysFromNow) || doc.effectiveExpiryDate!.isAtSameMomentAs(thirtyDaysFromNow);
    }

    final isExpiringSoonFlag = isExpiringSoon(document);

    return Column(
      children: [
        // Card header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  documentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  document.effectiveExpiryDate != null
                      ? context.l10n.expiresOn(DateFormat('MMM d, y').format(document.effectiveExpiryDate!))
                      : context.l10n.noExpiryDate,
                  style: TextStyle(
                    fontSize: 13,
                    color: document.isExpired ? Colors.red : Colors.grey.shade700,
                  ),
                ),
              ),
              document.isNotApplicable
                  ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  context.l10n.notApplicable,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              )
                  : StatusBadge(
                status: document.status,
                isExpired: document.isExpired,
                isExpiringSoon: isExpiringSoonFlag,
              ),
            ],
          ),
        ),

        // Description row with category and buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(categoryName),
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  categoryName,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
              // Add resubmit button for rejected documents
              if (document.status == DocumentStatus.REJECTED)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh,
                        color: Colors.white, size: 16),
                    label: Text(context.l10n.actionResubmit),
                    onPressed: () {
                      // Navigate to document upload/form screen with existing document ID
                      Navigator.of(context).pushNamed(
                        RouteConstants.documentUpload,
                        arguments: {
                          'categoryId': document.categoryId,
                          'documentTypeId': document.documentTypeId,
                          'existingDocumentId': document.id,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),

              // View Details button (available to all users)
              OutlinedButton.icon(
                icon: const Icon(Icons.visibility, size: 16),
                label: Text(context.l10n.actionViewDetails),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    RouteConstants.documentDetail,
                    arguments: {'documentId': document.id},
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),

              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete, size: 16),
                label: Text(context.l10n.actionDelete),
                onPressed: () => _showDeleteConfirmation(context, document),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        // Add comments section
        if (document.comments.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.commentsColon,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ...document.comments.map((comment) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            comment.userName.isNotEmpty
                                ? comment.userName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    comment.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('MMM d, y')
                                        .format(comment.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.text,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAuditListView(
      DocumentProvider documentProvider, CategoryProvider categoryProvider) {
    _stopwatch.reset();
    _stopwatch.start();
    _tlog('AuditTrackerScreen - _buildAuditListView started');

    // Only show categories that have at least one active document type
    final categories = categoryProvider.categories
        .where((c) => documentProvider.documentTypes.any((dt) => dt.categoryId == c.id))
        .toList();
    _tlog('AuditTrackerScreen - Categories count: ${categories.length}');

    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    final result = ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        _stopwatch.reset();
        _stopwatch.start();
        _tlog('AuditTrackerScreen - Building category item ${index+1}/${categories.length}');

        final category = categories[index];

        // Initialize expandedCategories map entry if needed
        if (!_expandedCategories.containsKey(category.id)) {
          _expandedCategories[category.id] = false;
        }

        final card = Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              // Category header
              ListTile(
                leading: Icon(
                  _getCategoryIcon(category.name),
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: Icon(
                    _expandedCategories[category.id]!
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  onPressed: () {
                    setState(() {
                      _expandedCategories[category.id] =
                      !_expandedCategories[category.id]!;
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    _expandedCategories[category.id] =
                    !_expandedCategories[category.id]!;
                  });
                },
              ),

              // Document types list (expandable)
              if (_expandedCategories[category.id]!) ...[
                const Divider(height: 1),
                _buildDocumentTypesList(
                    category.id, documentProvider, isSmallScreen),
              ],
            ],
          ),
        );

        _tlog('AuditTrackerScreen - Built category item ${index+1}/${categories.length}: ${_stopwatch.elapsedMilliseconds}ms');
        return card;
      },
    );

    _stopwatch.stop();
    _tlog('AuditTrackerScreen - _buildAuditListView completed: ${_stopwatch.elapsedMilliseconds}ms');

    return result;
  }

  Widget _buildDocumentTypesList(String categoryId,
      DocumentProvider documentProvider, bool isSmallScreen) {
    _stopwatch.reset();
    _stopwatch.start();
    _tlog('AuditTrackerScreen - _buildDocumentTypesList started for category: $categoryId');

    final documentTypes = documentProvider.documentTypes
        .where((dt) => dt.categoryId == categoryId)
        .toList();

    _tlog('AuditTrackerScreen - Document types for category $categoryId: ${documentTypes.length}');

    if (documentTypes.isEmpty) {
      _tlog('AuditTrackerScreen - No document types found for category: $categoryId');
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(context.l10n.docTypesNoneInCategory),
      );
    }

    final result = ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documentTypes.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        _stopwatch.reset();
        _stopwatch.start();
        _tlog('AuditTrackerScreen - Building document type ${index+1}/${documentTypes.length} for category: $categoryId');

        final documentType = documentTypes[index];

        // Check if this document type has been uploaded
        final existingDocuments = documentProvider.documents
            .where((doc) => doc.documentTypeId == documentType.id)
            .toList();

        _tlog('AuditTrackerScreen - Found ${existingDocuments.length} existing documents for type: ${documentType.id}');

        final hasDocument = existingDocuments.isNotEmpty;
        final documentStatus = hasDocument
            ? existingDocuments.first.isNotApplicable
            ? _naKey
            : existingDocuments.first.status.name
            : _noneKey;

        final listItem = isSmallScreen
            ? _buildMobileDocumentTypeItem(context, documentType, hasDocument,
            documentStatus, existingDocuments)
            : _buildDesktopDocumentTypeItem(context, documentType, hasDocument,
            documentStatus, existingDocuments);

        _tlog('AuditTrackerScreen - Built document type ${index+1}/${documentTypes.length}: ${_stopwatch.elapsedMilliseconds}ms');
        return listItem;
      },
    );

    _stopwatch.stop();
    _tlog('AuditTrackerScreen - _buildDocumentTypesList completed for category $categoryId: ${_stopwatch.elapsedMilliseconds}ms');

    return result;
  }



  Widget _buildMobileDocumentTypeItem(
      BuildContext context,
      DocumentTypeModel documentType,
      bool hasDocument,
      String documentStatus,
      List<DocumentModel> existingDocuments) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            documentType.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            _getDocumentTypeDescription(documentType),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),

          // Show existing documents count if any
          if (hasDocument) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                context.l10n.docsUploadedCount(existingDocuments.length),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          Row(
            children: [
              _buildStatusChip(documentStatus),
              const Spacer(),

              // Always show upload/add button (unless document type doesn't allow multiple and has approved document)
              if (_shouldShowUploadButton(documentType, existingDocuments))
                OutlinedButton(
                  onPressed: () => _navigateToDocumentUpload(context, documentType),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(_getUploadButtonText(documentType, hasDocument)),
                ),

              const SizedBox(width: 8),

              // View button if documents exist
              if (hasDocument)
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: context.l10n.viewDocuments,
                  onPressed: () {
                    _showDocumentsList(context, documentType, existingDocuments);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDocumentTypeItem(
      BuildContext context,
      DocumentTypeModel documentType,
      bool hasDocument,
      String documentStatus,
      List<DocumentModel> existingDocuments) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 24, right: 16),
      title: Text(documentType.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getDocumentTypeDescription(documentType),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          // Show existing documents count if any
          if (hasDocument) ...[
            const SizedBox(height: 4),
            Text(
              context.l10n.docsUploadedCount(existingDocuments.length),
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusChip(documentStatus),
          const SizedBox(width: 8),

          // Always show upload/add button (unless document type doesn't allow multiple and has approved document)
          if (_shouldShowUploadButton(documentType, existingDocuments))
            OutlinedButton(
              onPressed: () => _navigateToDocumentUpload(context, documentType),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(_getUploadButtonText(documentType, hasDocument)),
            ),

          const SizedBox(width: 8),

          // View button if documents exist
          if (hasDocument)
            IconButton(
              icon: const Icon(Icons.visibility),
              tooltip: context.l10n.viewDocuments,
              onPressed: () {
                _showDocumentsList(context, documentType, existingDocuments);
              },
            ),
        ],
      ),
    );
  }

  // Helper method to show documents list
  void _showDocumentsList(BuildContext context, DocumentTypeModel documentType, List<DocumentModel> documents) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          documentType.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.docsUploadedCount(documents.length),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Documents list
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: documents.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final document = documents[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(document.status).withOpacity(0.1),
                            child: Icon(
                              _getStatusIcon(document.status),
                              color: _getStatusColor(document.status),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            document.specification?.isNotEmpty == true
                                ? document.specification!
                                : context.l10n.specNoneShort,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.uploadedOn(DateFormat('MMM d, y').format(document.createdAt)),
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (document.effectiveExpiryDate != null)
                                Text(
                                  context.l10n.expiresOn(DateFormat('MMM d, y').format(document.effectiveExpiryDate!)),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: document.isExpired ? Colors.red : null,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStatusChip(document.status.name),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.open_in_new, size: 18),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pushNamed(
                                    RouteConstants.documentDetail,
                                    arguments: {'documentId': document.id},
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushNamed(
                              RouteConstants.documentDetail,
                              arguments: {'documentId': document.id},
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Add more button at bottom
                  if (documentType.allowMultipleDocuments) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(documentType.isUploadable ? context.l10n.addAnotherDocument : context.l10n.addAnotherForm),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _navigateToDocumentUpload(context, documentType);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to determine if upload button should be shown
  bool _shouldShowUploadButton(DocumentTypeModel documentType, List<DocumentModel> existingDocuments) {
    // If no documents exist, always show upload button
    if (existingDocuments.isEmpty) {
      return true;
    }

    // If document type allows multiple documents, always show add button
    if (documentType.allowMultipleDocuments) {
      return true;
    }

    // If document type doesn't allow multiple documents, only show if:
    // - No approved documents exist (can replace rejected/pending)
    // - Or all existing documents are rejected (can retry)
    final hasApprovedDocument = existingDocuments.any((doc) => doc.status == DocumentStatus.APPROVED);
    final allRejected = existingDocuments.every((doc) => doc.status == DocumentStatus.REJECTED);

    return !hasApprovedDocument || allRejected;
  }

  // Helper method to get the appropriate button text
  String _getUploadButtonText(DocumentTypeModel documentType, bool hasDocument) {
    if (!hasDocument) {
      return documentType.isUploadable ? context.l10n.actionUpload : context.l10n.actionFillForm;
    }

    if (documentType.allowMultipleDocuments) {
      return documentType.isUploadable ? context.l10n.actionAddMore : context.l10n.actionAddForm;
    } else {
      return documentType.isUploadable ? context.l10n.actionReplace : context.l10n.actionUpdateForm;
    }
  }

  // Status keys for documents that aren't approved / pending / rejected.
  static const _naKey = 'NA';
  static const _noneKey = 'NONE';

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    final l10n = context.l10n;
    final String label;
    switch (status) {
      case 'APPROVED':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = l10n.statusApproved;
        break;
      case 'PENDING':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = l10n.statusPending;
        break;
      case 'REJECTED':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = l10n.statusRejected;
        break;
      case _naKey:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        label = l10n.notApplicable;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        label = l10n.statusNotUploaded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getDocumentTypeDescription(DocumentTypeModel documentType) {
    List<String> properties = [];

    if (documentType.allowMultipleDocuments) {
      properties.add(context.l10n.ruleMultipleAllowed);
    }

    if (documentType.hasExpiryDate) {
      properties.add(context.l10n.ruleRequiresExpiry);
    }

    if (documentType.requiresSignature) {
      properties.add(context.l10n.ruleRequiresSignature);
    }

    if (documentType.hasNotApplicableOption) {
      properties.add(context.l10n.ruleCanBeNa);
    }

    return properties.join(' • ');
  }
// Helper methods for the documents list
  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.APPROVED:
        return Colors.green;
      case DocumentStatus.PENDING:
        return Colors.orange;
      case DocumentStatus.REJECTED:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.APPROVED:
        return Icons.check_circle;
      case DocumentStatus.PENDING:
        return Icons.hourglass_empty;
      case DocumentStatus.REJECTED:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }


  void _navigateToDocumentUpload(
      BuildContext context, DocumentTypeModel documentType) {
    _tlog('AuditTrackerScreen - Navigating to document upload/form: ${documentType.id}');

    if (documentType.isUploadable) {
      Navigator.of(context).pushNamed(
        RouteConstants.documentUpload,
        arguments: {
          'categoryId': documentType.categoryId,
          'documentTypeId': documentType.id,
        },
      );
    } else {
      Navigator.of(context).pushNamed(
        RouteConstants.documentForm,
        arguments: {
          'categoryId': documentType.categoryId,
          'documentTypeId': documentType.id,
        },
      );
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('business') || name.contains('compliance')) {
      return Icons.business;
    } else if (name.contains('management')) {
      return Icons.settings;
    } else if (name.contains('employment')) {
      return Icons.people;
    } else if (name.contains('child') || name.contains('young')) {
      return Icons.child_care;
    } else if (name.contains('forced') || name.contains('labor prevention')) { // l10n-ignore: matches stored names
      return Icons.security;
    } else if (name.contains('wages') || name.contains('working')) {
      return Icons.payments;
    } else if (name.contains('association')) {
      return Icons.groups;
    } else if (name.contains('training')) {
      return Icons.school;
    } else if (name.contains('health') || name.contains('safety')) {
      return Icons.health_and_safety;
    } else if (name.contains('chemical') || name.contains('pesticide')) {
      return Icons.science;
    } else if (name.contains('service') || name.contains('provider')) {
      return Icons.handyman;
    } else if (name.contains('environmental') || name.contains('community')) {
      return Icons.eco;
    }

    return Icons.folder;
  }
}

/// Completion for one standard on the Compliance Tracker's KPI card.
class _StandardProgress {
  final String label;
  final int done; // document types with at least one upload
  final int total; // document types required by this standard
  const _StandardProgress(this.label, this.done, this.total);

  double get fraction => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);
  double get percent => fraction * 100;
}
