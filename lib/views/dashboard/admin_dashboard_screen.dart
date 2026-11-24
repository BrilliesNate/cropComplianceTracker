import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/core/services/push_notification_service.dart';
import 'package:cropCompliance/providers/notification_provider.dart';
import 'package:cropCompliance/views/mobile/mobile_admin_dashboard.dart';
import 'package:cropCompliance/views/mobile/mobile_ui.dart' show isPhoneWidth;
import 'package:cropCompliance/models/category_model.dart';
import 'package:cropCompliance/models/company_model.dart';
import 'package:cropCompliance/models/user_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/views/shared/app_scaffold_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cropCompliance/models/document_model.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

/// The last result, kept for the whole session so coming back to this screen
/// (e.g. after opening a company) paints instantly while fresh numbers load.
class _AdminDashboardCache {
  final List<CompanyModel> companies;
  final Map<String, CompanyStats> stats;
  _AdminDashboardCache(this.companies, this.stats);
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static _AdminDashboardCache? _cache;

  // First visit: ONE loading indicator, then the finished page — nothing is
  // drawn half-filled. Return visits show the last result instantly and refresh
  // quietly, swapping the numbers in a single update when they arrive.
  bool _isLoading = true;
  bool _refreshing = false;
  String? _error;
  int _loadGeneration = 0; // a newer load makes any older one stop quietly

  List<CompanyModel> _companies = [];
  Map<String, CompanyStats> _companyStats = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Order is decided from a snapshot of pending counts, taken only when a
  // load finishes, so cards never jump around under the cursor while numbers
  // are still streaming in.
  Map<String, int> _sortPending = {};

  // Pre-loaded category/doc type data for accurate completion calculation
  List<CategoryModel> _allCategories = [];
  Map<String, List<String>> _docTypeIdsByCategory = {}; // categoryId -> [docTypeIds]

  // Global stats
  int _totalCompanies = 0;
  int _totalPendingDocs = 0;
  int _totalUsers = 0;
  int _totalDocuments = 0;

  @override
  void initState() {
    super.initState();
    final cached = _cache;
    if (cached != null) {
      _companies = cached.companies;
      _companyStats = Map.of(cached.stats);
      _sortPending = {
        for (final c in cached.companies)
          c.id: cached.stats[c.id]?.pendingDocs ?? 0,
      };
      _recomputeTotals();
      _isLoading = false;
    }
    _loadData();
  }

  @override
  void dispose() {
    _loadGeneration++; // stop any load still in flight
    _searchController.dispose();
    super.dispose();
  }

  void _recomputeTotals() {
    _totalCompanies = _companies.length;
    _totalUsers = 0;
    _totalPendingDocs = 0;
    _totalDocuments = 0;
    for (final s in _companyStats.values) {
      _totalUsers += s.userCount;
      _totalPendingDocs += s.pendingDocs;
      _totalDocuments += s.documentCount;
    }
  }

  /// Runs [task] over [items] with at most [limit] in flight at once. Firing
  /// hundreds of queries together just queues them behind each other and
  /// delays the first useful result.
  Future<void> _forEachLimited<T>(
    List<T> items,
    int limit,
    Future<void> Function(T item) task,
    bool Function() cancelled,
  ) async {
    var next = 0;
    Future<void> worker() async {
      while (!cancelled()) {
        final i = next++;
        if (i >= items.length) return;
        await task(items[i]);
      }
    }

    await Future.wait(
      List.generate(math.min(limit, items.length), (_) => worker()),
    );
  }

  int _requiredDocTypes(CompanyModel company, Set<String> deactivated) {
    // Categories belonging to this company's audit packages → their doc types,
    // minus any the company has switched off.
    final validCategoryIds = _allCategories
        .where((c) => company.packages.contains(c.packageId))
        .map((c) => c.id);
    final allDocTypeIds = <String>{};
    for (final catId in validCategoryIds) {
      allDocTypeIds.addAll(_docTypeIdsByCategory[catId] ?? const []);
    }
    return allDocTypeIds.difference(deactivated).length;
  }

  Future<void> _loadData() async {
    final gen = ++_loadGeneration;
    bool alive() => mounted && gen == _loadGeneration;
    final fs = FirebaseFirestore.instance;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Quiet refresh when something is already on screen; otherwise the single
    // full-page indicator is showing.
    if (_companies.isNotEmpty) setState(() => _refreshing = true);

    try {
      // ── Step 1: everything the list needs, in ONE parallel round trip ──
      final snaps = await Future.wait([
        fs.collection('categories').get(),
        fs.collection('documentTypes').get(),
        fs.collection('companies').orderBy('name').get(),
        fs.collection('companyDocumentTypeSettings').get(),
      ]);
      if (!alive()) return;

      final categories = snaps[0]
          .docs
          .map((d) => CategoryModel.fromMap(d.data(), d.id))
          .toList();
      final docTypeIdsByCategory = <String, List<String>>{};
      for (final d in snaps[1].docs) {
        DocumentModel.noteTypeExpiry(d.id, d.data()['hasExpiryDate'] == true);
        final categoryId = d.data()['categoryId'] as String?;
        if (categoryId == null) continue;
        docTypeIdsByCategory.putIfAbsent(categoryId, () => []).add(d.id);
      }
      final companies = snaps[2]
          .docs
          .map((d) => CompanyModel.fromMap(d.data(), d.id))
          .toList();

      // Document types each company has switched off.
      final deactivated = <String, Set<String>>{};
      for (final d in snaps[3].docs) {
        final data = d.data();
        final companyId = data['companyId'] as String?;
        final typeId = data['documentTypeId'] as String?;
        if (companyId == null || typeId == null) continue;
        final overrides = data['overrides'] as Map<String, dynamic>? ?? {};
        if (overrides['isActive'] == false) {
          deactivated.putIfAbsent(companyId, () => {}).add(typeId);
        }
      }

      // User counts: the admin's session already holds every user, so counting
      // them costs nothing. Only fetch if (unexpectedly) they aren't loaded.
      List<UserModel> users = auth.allUsers;
      if (users.isEmpty) {
        final us = await fs.collection('users').get();
        if (!alive()) return;
        users = us.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
      }
      final usersPerCompany = <String, int>{};
      for (final u in users) {
        usersPerCompany.update(u.companyId, (v) => v + 1, ifAbsent: () => 1);
      }

      _allCategories = categories;
      _docTypeIdsByCategory = docTypeIdsByCategory;

      final counts = <String, ({int docs, int pending})>{};
      final approved = <String, int>{};

      // ── Step 2: document + pending counts (aggregate queries, no downloads) ──
      await _forEachLimited<CompanyModel>(companies, 12, (c) async {
        try {
          final base =
              fs.collection('documents').where('companyId', isEqualTo: c.id);
          final res = await Future.wait([
            base.count().get(),
            base.where('status', isEqualTo: 'PENDING').count().get(),
          ]);
          counts[c.id] = (docs: res[0].count ?? 0, pending: res[1].count ?? 0);
        } catch (e) {
          print('Admin dashboard: counts failed for ${c.name}: $e');
          counts[c.id] = (docs: 0, pending: 0);
        }
      }, () => !alive());
      if (!alive()) return;

      // ── Step 3: completion % (needs each company's approved documents) ──
      // Companies with no documents at all need no query.
      final withDocs =
          companies.where((c) => (counts[c.id]?.docs ?? 0) > 0).toList();

      await _forEachLimited<CompanyModel>(withDocs, 12, (c) async {
        try {
          final snap = await fs
              .collection('documents')
              .where('companyId', isEqualTo: c.id)
              .where('status', isEqualTo: 'APPROVED')
              .get();

          // Unique document types with at least one approved, in-date,
          // not-replaced document — the same rule as the client dashboard, so
          // the two never disagree (and a company can't exceed 100%).
          final now = DateTime.now();
          final types = <String>{};
          for (final d in snap.docs) {
            final data = d.data();
            if (data['isSuperseded'] == true) continue;
            final typeId = data['documentTypeId'];
            final expiry = DocumentModel.effectiveExpiryFor(
                typeId as String?, (data['expiryDate'] as Timestamp?)?.toDate());
            if (expiry != null && !expiry.isAfter(now)) continue;
            if (typeId is String) types.add(typeId);
          }
          approved[c.id] = types.length;
        } catch (e) {
          print('Admin dashboard: completion failed for ${c.name}: $e');
          approved[c.id] = 0;
        }
      }, () => !alive());
      if (!alive()) return;

      // ── Done: swap everything in with ONE update ──
      final stats = <String, CompanyStats>{
        for (final c in companies)
          c.id: CompanyStats(
            userCount: usersPerCompany[c.id] ?? 0,
            totalRequiredDocTypes:
                _requiredDocTypes(c, deactivated[c.id] ?? const {}),
            documentCount: counts[c.id]?.docs ?? 0,
            pendingDocs: counts[c.id]?.pending ?? 0,
            approvedDocs: approved[c.id] ?? 0,
          ),
      };

      _cache = _AdminDashboardCache(companies, Map.of(stats));
      setState(() {
        _companies = companies;
        _companyStats = stats;
        _sortPending = {for (final c in companies) c.id: stats[c.id]!.pendingDocs};
        _error = null;
        _isLoading = false;
        _refreshing = false;
        _recomputeTotals();
      });
    } catch (e) {
      print('Error loading admin dashboard: $e');
      if (!alive()) return;
      setState(() {
        _isLoading = false;
        _refreshing = false;
        // Only show the error page when there is nothing to show; otherwise
        // keep the cached list on screen.
        if (_companies.isEmpty) _error = context.l10n.adminDashLoadFailed;
      });
    }
  }

  List<CompanyModel> get _filteredCompanies {
    if (_searchQuery.isEmpty) return List.of(_companies);
    final q = _searchQuery.toLowerCase();
    return _companies
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.address.toLowerCase().contains(q))
        .toList();
  }

  // Sort companies: those with pending docs first, then alphabetically.
  // Uses the snapshot taken when counts last finished (see _sortPending).
  List<CompanyModel> get _sortedCompanies {
    final filtered = _filteredCompanies;
    filtered.sort((a, b) {
      final aPending = _sortPending[a.id] ?? 0;
      final bPending = _sortPending[b.id] ?? 0;
      if (aPending > 0 && bPending == 0) return -1;
      if (bPending > 0 && aPending == 0) return 1;
      if (aPending != bPending) return bPending.compareTo(aPending);
      return a.name.compareTo(b.name);
    });
    return filtered;
  }

  Future<void> _navigateToCompany(CompanyModel company) async {
    try {
      // Admins manage a company by SELECTING it — no user needed. Previously
      // this looked up a user to impersonate and aborted with "No users found"
      // for companies that had none (e.g. orphaned company records), which
      // locked admins out. Company-view runs off the selected company only.
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.setSelectedCompany(company);

      // Navigate to the regular dashboard
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteConstants.dashboard,
            (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorWithDetail('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If admin is managing a company, show regular dashboard
    if (authProvider.isManagingCompany) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(RouteConstants.dashboard);
      });
      return const SizedBox.shrink();
    }

    // Phones get the card-grid design; tablets/desktop keep the layout below.
    if (isPhoneWidth(MediaQuery.of(context).size.width)) {
      final uid = authProvider.currentUser?.id;
      if (uid != null) {
        // The phone screen has no AppScaffoldWrapper, which normally starts
        // these — both are idempotent.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Provider.of<NotificationProvider>(context, listen: false).start(uid);
          PushNotificationService.instance.init(uid);
        });
      }
      return MobileAdminDashboard(
        companies: _companies,
        stats: _companyStats,
        users: authProvider.allUsers,
        sortPending: _sortPending,
        loading: _isLoading,
        refreshing: _refreshing,
        error: _error,
        onRefresh: _loadData,
        onOpen: _navigateToCompany,
      );
    }

    Widget body;
    if (_isLoading && _companies.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null && _companies.isEmpty) {
      body = _buildErrorState();
    } else {
      body = RefreshIndicator(
        onRefresh: _loadData,
        child: _buildContent(context),
      );
    }

    return AppScaffoldWrapper(
      title: context.l10n.adminDashboardTitle,
      backgroundColor: Colors.grey.shade50,
      child: body,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(_error ?? context.l10n.somethingWentWrong,
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _error = null;
                _isLoading = true;
              });
              _loadData();
            },
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.actionRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    return Column(
      children: [
        // Fixed header section (KPIs + Search)
        Container(
          color: Colors.white,
          child: Column(
            children: [
              // Compact KPI Row
              _buildCompactKPIRow(),
              const Divider(height: 1),
              // Search Bar
              _buildSearchBar(),
            ],
          ),
        ),

        // Scrollable company list
        Expanded(
          child: _buildCompaniesList(isDesktop, isTablet),
        ),
      ],
    );
  }

  Widget _buildCompactKPIRow() {
    final primaryColor = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildCompactKPI(
            icon: Icons.business,
            value: _totalCompanies.toString(),
            label: context.l10n.kpiCompanies,
            color: primaryColor,
          ),
          _buildKPIDivider(),
          _buildCompactKPI(
            icon: Icons.pending_actions,
            value: _totalPendingDocs.toString(),
            label: context.l10n.statusPending,
            color: _totalPendingDocs > 0 ? Colors.orange.shade700 : primaryColor,
            highlight: _totalPendingDocs > 0,
          ),
          _buildKPIDivider(),
          _buildCompactKPI(
            icon: Icons.people,
            value: _totalUsers.toString(),
            label: context.l10n.kpiUsers,
            color: primaryColor,
          ),
          _buildKPIDivider(),
          _buildCompactKPI(
            icon: Icons.description,
            value: _totalDocuments.toString(),
            label: context.l10n.documentsTitle,
            color: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactKPI({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool highlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: highlight
            ? BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
        )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIDivider() {
    return Container(
      height: 32,
      width: 1,
      color: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.l10n.adminSearchCompanies,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // Pull-to-refresh doesn't exist with a mouse, so give desktop users a button.
          IconButton(
            tooltip: context.l10n.actionRefresh,
            onPressed: _refreshing ? null : _loadData,
            icon: Icon(Icons.refresh, color: Colors.grey.shade600, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCompaniesList(bool isDesktop, bool isTablet) {
    final companies = _sortedCompanies;

    if (companies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              context.l10n.adminNoCompanies,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // Use grid for desktop/tablet, list for mobile
    if (isDesktop || isTablet) {
      final crossAxisCount = isDesktop ? 3 : 2;
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isDesktop ? 2.4 : 2.0,
        ),
        itemCount: companies.length,
        itemBuilder: (context, index) => _buildCompanyCard(companies[index]),
      );
    }

    // Mobile: Use a simple list
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: companies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildCompanyListTile(companies[index]),
    );
  }

  int _completionFor(CompanyStats? stats) {
    if (stats == null || stats.totalRequiredDocTypes <= 0) return 0;
    return ((stats.approvedDocs / stats.totalRequiredDocTypes) * 100).round();
  }

  // Compact card for desktop/tablet
  Widget _buildCompanyCard(CompanyModel company) {
    final stats = _companyStats[company.id];
    final pending = stats?.pendingDocs ?? 0;
    final hasPending = pending > 0;
    final completionRate = _completionFor(stats);
    final primaryColor = Theme.of(context).primaryColor;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _navigateToCompany(company),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasPending ? Colors.orange.shade300 : Colors.grey.shade200,
              width: hasPending ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Avatar + Name + Pending badge
              Row(
                children: [
                  // Company Avatar
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        company.name.isNotEmpty ? company.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Company name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          company.address,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Pending badge (inline, not overlapping)
                  if (hasPending)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        '$pending',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
                ],
              ),

              const Spacer(),

              // Bottom row: Stats
              Row(
                children: [
                  // Package badges
                  if (company.packages.contains('siza_wieta'))
                    _buildMiniPackageBadge('SIZA'),
                  if (company.packages.contains('globalgap'))
                    _buildMiniPackageBadge('GAP'),
                  if (company.packages.contains('ipw'))
                    _buildMiniPackageBadge('IPW'),
                  if (company.packages.contains('fairtrade'))
                    _buildMiniPackageBadge('FT'),
                  if (company.packages.contains('siza_environmental'))
                    _buildMiniPackageBadge('SIZA-E'),

                  const Spacer(),

                  // Stats
                  Icon(Icons.people_outline, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 2),
                  Text(
                    '${stats?.userCount ?? 0}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.description_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 2),
                  Text(
                    '${stats?.documentCount ?? 0}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 10),
                  // Completion
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getCompletionColor(completionRate).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$completionRate%',
                      style: TextStyle(
                        color: _getCompletionColor(completionRate),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Compact list tile for mobile
  Widget _buildCompanyListTile(CompanyModel company) {
    final stats = _companyStats[company.id];
    final pending = stats?.pendingDocs ?? 0;
    final hasPending = pending > 0;
    final completionRate = _completionFor(stats);
    final primaryColor = Theme.of(context).primaryColor;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _navigateToCompany(company),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasPending ? Colors.orange.shade300 : Colors.grey.shade200,
              width: hasPending ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    company.name.isNotEmpty ? company.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Company info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        // Mini stats
                        Icon(Icons.people_outline, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(
                          '${stats?.userCount ?? 0}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.description_outlined, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(
                          '${stats?.documentCount ?? 0}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: _getCompletionColor(completionRate).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '$completionRate%',
                            style: TextStyle(
                              color: _getCompletionColor(completionRate),
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Pending badge
              if (hasPending) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pending_actions, size: 12, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '$pending',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],

              Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPackageBadge(String label) {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primaryColor,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getCompletionColor(int percentage) {
    if (percentage >= 80) return Colors.green.shade600;
    if (percentage >= 50) return Colors.orange.shade600;
    return Colors.red.shade600;
  }
}

// Helper class to hold company stats.
class CompanyStats {
  final int userCount;
  final int totalRequiredDocTypes;
  final int documentCount;
  final int pendingDocs;
  final int approvedDocs;

  CompanyStats({
    required this.userCount,
    required this.totalRequiredDocTypes,
    required this.documentCount,
    required this.pendingDocs,
    required this.approvedDocs,
  });
}
