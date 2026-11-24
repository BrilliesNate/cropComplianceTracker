import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/models/company_model.dart';
import 'package:cropCompliance/models/user_model.dart';
import 'package:cropCompliance/views/dashboard/admin_dashboard_screen.dart'
    show CompanyStats;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mobile_ui.dart';
import 'package:cropCompliance/providers/locale_provider.dart';
import 'package:cropCompliance/l10n/generated/app_localizations.dart';

/// Completion of a farm: approved, in-date document types out of the ones its
/// standards require. Same rule as the web admin dashboard.
int companyCompletion(CompanyStats? s) {
  if (s == null || s.totalRequiredDocTypes <= 0) return 0;
  return ((s.approvedDocs / s.totalRequiredDocTypes) * 100)
      .round()
      .clamp(0, 100);
}

/// The standards shown on each farm card, in display order.
const _standards = <({String id, String label})>[
  (id: 'siza_wieta', label: 'SIZA/WIETA'),
  (id: 'ipw', label: 'IPW'),
  (id: 'globalgap', label: 'GlobalG.A.P.'),
  (id: 'fairtrade', label: 'Fairtrade'), // l10n-ignore: brand name
  (id: 'siza_environmental', label: 'SIZA Env.'), // l10n-ignore: brand name
];

/// Shown on a card only when the farm has them.
const _optionalStandards = {'fairtrade', 'siza_environmental'};

enum _Sort { pending, name, lowest, highest }

String _sortLabel(AppLocalizations l10n, _Sort s) {
  switch (s) {
    case _Sort.pending:
      return l10n.adminSortMostPending;
    case _Sort.name:
      return l10n.adminSortName;
    case _Sort.lowest:
      return l10n.adminSortLowest;
    case _Sort.highest:
      return l10n.adminSortHighest;
  }
}

/// Phone layout of the Admin Dashboard: search + filters, then a two-column
/// grid of farm cards (pending documents, employees, standards, progress
/// bars). Data loading stays in [AdminDashboardScreen]; this only draws it.
class MobileAdminDashboard extends StatefulWidget {
  final List<CompanyModel> companies;
  final Map<String, CompanyStats> stats;

  /// Everyone's user records (initials on each card).
  final List<UserModel> users;

  /// Pending counts captured when the last load finished, so cards don't
  /// reshuffle while numbers update.
  final Map<String, int> sortPending;
  final bool loading;
  final bool refreshing;
  final String? error;
  final Future<void> Function() onRefresh;
  final void Function(CompanyModel) onOpen;

  const MobileAdminDashboard({
    super.key,
    required this.companies,
    required this.stats,
    required this.users,
    required this.sortPending,
    required this.loading,
    required this.refreshing,
    required this.error,
    required this.onRefresh,
    required this.onOpen,
  });

  @override
  State<MobileAdminDashboard> createState() => _MobileAdminDashboardState();
}

class _MobileAdminDashboardState extends State<MobileAdminDashboard> {
  final _search = TextEditingController();
  String _query = '';
  _Sort _sort = _Sort.pending;
  final Set<String> _packages = {};
  bool _onlyPending = false;

  // One card per row or two. Saved on the device so the app opens in the
  // layout the admin last chose; also kept in memory so coming back to this
  // screen doesn't flash the other layout while the setting is read.
  static const _layoutKey = 'adminDashboard.singleColumn';
  static bool? _singleColumnMemo;
  bool _singleColumn = _singleColumnMemo ?? false;

  @override
  void initState() {
    super.initState();
    if (_singleColumnMemo == null) _loadLayout();
  }

  Future<void> _loadLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_layoutKey) ?? false;
      _singleColumnMemo = saved;
      if (mounted && saved != _singleColumn) {
        setState(() => _singleColumn = saved);
      }
    } catch (e) {
      debugPrint('Admin dashboard: could not read layout setting: $e');
    }
  }

  Future<void> _toggleLayout() async {
    final next = !_singleColumn;
    setState(() => _singleColumn = next);
    _singleColumnMemo = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_layoutKey, next);
    } catch (e) {
      debugPrint('Admin dashboard: could not save layout setting: $e');
    }
  }

  bool get _filtersActive =>
      _sort != _Sort.pending || _packages.isNotEmpty || _onlyPending;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearAll() {
    _search.clear();
    setState(() {
      _query = '';
      _sort = _Sort.pending;
      _packages.clear();
      _onlyPending = false;
    });
  }

  List<CompanyModel> get _visible {
    final q = _query.toLowerCase();
    final list = widget.companies.where((c) {
      if (q.isNotEmpty &&
          !c.name.toLowerCase().contains(q) &&
          !c.address.toLowerCase().contains(q)) {
        return false;
      }
      if (_packages.isNotEmpty && !_packages.any(c.packages.contains)) {
        return false;
      }
      if (_onlyPending && (widget.stats[c.id]?.pendingDocs ?? 0) == 0) {
        return false;
      }
      return true;
    }).toList();

    int pct(CompanyModel c) => companyCompletion(widget.stats[c.id]);
    list.sort((a, b) {
      switch (_sort) {
        case _Sort.pending:
          final pa = widget.sortPending[a.id] ?? 0;
          final pb = widget.sortPending[b.id] ?? 0;
          if (pa != pb) return pb.compareTo(pa);
          break;
        case _Sort.lowest:
          final d = pct(a).compareTo(pct(b));
          if (d != 0) return d;
          break;
        case _Sort.highest:
          final d = pct(b).compareTo(pct(a));
          if (d != 0) return d;
          break;
        case _Sort.name:
          break;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final usersByCompany = <String, List<UserModel>>{};
    for (final u in widget.users) {
      usersByCompany.putIfAbsent(u.companyId, () => []).add(u);
    }

    return Scaffold(
      backgroundColor: MobileColors.page,
      body: Column(children: [
        MobileHeader(
          title: context.l10n.adminDashboardTitle,
          showAdminFarm: false,
          trailing: IconButton(
            tooltip: context.l10n.adminTools,
            icon: const Icon(Icons.menu_rounded,
                size: 30, color: MobileColors.ink),
            onPressed: () => _openMenu(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 2, 2),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v.trim()),
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: context.l10n.commonSearchHint,
                  hintStyle:
                      const TextStyle(color: Color(0xFF9AA09A), fontSize: 15),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF4A4F49), size: 22),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: const Color(0xFFEDEFED),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            IconButton(
              tooltip: _singleColumn
                  ? context.l10n.adminShowTwoPerRow
                  : context.l10n.adminShowOnePerRow,
              onPressed: _toggleLayout,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => RotationTransition(
                  turns: Tween(begin: 0.75, end: 1.0).animate(CurvedAnimation(
                      parent: animation, curve: Curves.easeOutCubic)),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                    _singleColumn
                        ? Icons.grid_view_rounded
                        : Icons.view_agenda_outlined,
                    key: ValueKey(_singleColumn),
                    size: 26,
                    color: const Color(0xFF4A4F49)),
              ),
            ),
            IconButton(
              tooltip: context.l10n.adminSortAndFilter,
              onPressed: () => _openFilters(context),
              icon: Badge(
                isLabelVisible: _filtersActive,
                backgroundColor: MobileColors.greenMid,
                smallSize: 9,
                child: const Icon(Icons.tune_rounded,
                    size: 26, color: Color(0xFF4A4F49)),
              ),
            ),
          ]),
        ),
        if (widget.refreshing)
          const LinearProgressIndicator(
            minHeight: 2,
            color: MobileColors.greenMid,
            backgroundColor: Colors.transparent,
          ),
        Expanded(child: _body(usersByCompany)),
      ]),
      bottomNavigationBar: const MobileBottomNav(current: MobileTab.home),
    );
  }

  Widget _body(Map<String, List<UserModel>> usersByCompany) {
    if (widget.loading && widget.companies.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: MobileColors.greenMid));
    }
    if (widget.error != null && widget.companies.isEmpty) {
      return _message(
        icon: Icons.cloud_off_outlined,
        text: context.l10n.adminLoadFailed,
        action: context.l10n.commonRetry,
        onAction: widget.onRefresh,
      );
    }
    final farms = _visible;
    if (farms.isEmpty) {
      return _message(
        icon: Icons.search_off,
        text: widget.companies.isEmpty
            ? context.l10n.adminNoFarmsYet
            : context.l10n.adminNoFarmsMatch,
        action: widget.companies.isEmpty
            ? context.l10n.adminAddFarm
            : context.l10n.adminClearSearchFilters,
        onAction: widget.companies.isEmpty
            ? () => Navigator.of(context)
                .pushNamed(RouteConstants.companyManagement)
            : _clearAll,
      );
    }
    return RefreshIndicator(
      color: MobileColors.greenMid,
      onRefresh: widget.onRefresh,
      child: LayoutBuilder(builder: (context, c) {
        // Two columns unless the admin chose one (or the screen is very narrow).
        final columns = _singleColumn || c.maxWidth < 300 ? 1 : 2;
        // One-per-row cards are taller. The whole card is scaled up (text,
        // bars, chips) so it keeps the design's proportions instead of just
        // stretching the bars.
        const cardHeight = 120.0;
        const singleScale = 1.3;
        final single = columns == 1;
        final grid = GridView.builder(
          key: ValueKey(columns),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: single ? 11 : 9,
            crossAxisSpacing: 9,
            mainAxisExtent: single ? cardHeight * singleScale : cardHeight,
          ),
          itemCount: farms.length,
          itemBuilder: (context, i) {
            final farm = farms[i];
            final card = _FarmCard(
              farm: farm,
              stats: widget.stats[farm.id],
              users: usersByCompany[farm.id] ?? const [],
              onTap: () => widget.onOpen(farm),
            );
            if (!single) return card;
            return LayoutBuilder(
              builder: (context, tile) => FittedBox(
                child: SizedBox(
                  width: tile.maxWidth / singleScale,
                  height: cardHeight,
                  child: card,
                ),
              ),
            );
          },
        );
        // Switching layouts: the old grid fades out while the new one fades
        // in and settles from a slight zoom — quick (~280ms) and subtle.
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.96, end: 1.0).animate(animation),
              child: child,
            ),
          ),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, if (current != null) current],
          ),
          child: grid,
        );
      }),
    );
  }

  Widget _message({
    required IconData icon,
    required String text,
    required String action,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: MobileColors.muted),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: MobileColors.muted)),
          const SizedBox(height: 16),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: MobileColors.greenMid),
            onPressed: onAction,
            child: Text(action),
          ),
        ]),
      ),
    );
  }

  // ── Sort & filter sheet ───────────────────────────────────────────────────

  Future<void> _openFilters(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        void update(VoidCallback f) {
          setState(f);
          setSheet(() {});
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(context.l10n.adminSortAndFilter,
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800)),
                  ),
                  if (_filtersActive)
                    TextButton(
                      onPressed: () => update(() {
                        _sort = _Sort.pending;
                        _packages.clear();
                        _onlyPending = false;
                      }),
                      child: Text(context.l10n.commonReset),
                    ),
                ]),
                const SizedBox(height: 8),
                Text(context.l10n.adminSortBy,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: MobileColors.muted)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final s in _Sort.values)
                    ChoiceChip(
                      label: Text(_sortLabel(context.l10n, s)),
                      selected: _sort == s,
                      selectedColor: MobileColors.greenSoft,
                      onSelected: (_) => update(() => _sort = s),
                    ),
                ]),
                const SizedBox(height: 16),
                Text(context.l10n.adminStandards,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: MobileColors.muted)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final s in _standards)
                    FilterChip(
                      label: Text(s.label),
                      selected: _packages.contains(s.id),
                      selectedColor: MobileColors.greenSoft,
                      onSelected: (on) => update(() =>
                          on ? _packages.add(s.id) : _packages.remove(s.id)),
                    ),
                ]),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: MobileColors.greenMid,
                  title: Text(context.l10n.adminOnlyPending),
                  value: _onlyPending,
                  onChanged: (v) => update(() => _onlyPending = v),
                ),
                const SizedBox(height: 8),
                MobilePrimaryButton(
                  label: context.l10n.adminShowFarms(_visible.length),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Hamburger: admin tools ────────────────────────────────────────────────

  static List<({String title, IconData icon, String route})> _tools(
          AppLocalizations l10n) =>
      [
    (
      title: l10n.menuCompanyManagement,
      icon: Icons.business_outlined,
      route: RouteConstants.companyManagement
    ),
    (
      title: l10n.menuUserManagement,
      icon: Icons.people_outline,
      route: RouteConstants.userManagement
    ),
    (
      title: l10n.menuCategoryManagement,
      icon: Icons.category_outlined,
      route: RouteConstants.categoryManagement
    ),
    (
      title: l10n.menuDocumentSettings,
      icon: Icons.toggle_on_outlined,
      route: RouteConstants.overrid
    ),
    (
      title: l10n.menuDataFixUtility,
      icon: Icons.build_outlined,
      route: RouteConstants.dataFixUtility
    ),
    (
      title: l10n.menuFarmableConsole,
      icon: Icons.eco_outlined,
      route: RouteConstants.farmableConsole
    ),
    (
      title: l10n.notificationsTitle,
      icon: Icons.notifications_outlined,
      route: RouteConstants.notifications
    ),
  ];

  Future<void> _openMenu(BuildContext context) async {
    final route = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Text(context.l10n.adminTools,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          ),
          for (final t in _tools(context.l10n))
            ListTile(
              leading: Icon(t.icon, color: MobileColors.green),
              title: Text(t.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(ctx).pop(t.route),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (route != null && context.mounted) {
      Navigator.of(context).pushNamed(route);
    }
  }
}

// ── Farm card ───────────────────────────────────────────────────────────────
//
// Compact, like the design: five rows of two fit on a normal phone. Sizes
// below are for a ~165-wide card (360-wide phone).

class _FarmCard extends StatelessWidget {
  final CompanyModel farm;
  final CompanyStats? stats;
  final List<UserModel> users;
  final VoidCallback onTap;

  const _FarmCard({
    required this.farm,
    required this.stats,
    required this.users,
    required this.onTap,
  });

  static const _cardBg = Color(0xFFC8E6C9);
  static const _headerBg = Color(0xFF43A047);

  @override
  Widget build(BuildContext context) {
    final pending = stats?.pendingDocs ?? 0;
    final employees = stats?.userCount ?? users.length;
    final pct = companyCompletion(stats);
    final shown = _standards
        // Fairtrade / SIZA Environmental only when the farm has them, so the
        // chips stay readable.
        .where((s) =>
            !_optionalStandards.contains(s.id) ||
            farm.packages.contains(s.id))
        .toList();
    // At most 4 chips fit; if a farm has extra standards, the faded
    // (switched-off) ones make room first.
    if (shown.length > 4) {
      shown.removeWhere((s) => !farm.packages.contains(s.id));
    }
    final address = farm.address.trim();

    return Semantics(
      button: true,
      label: context.l10n.adminFarmCardSemantics(farm.name, pending, pct),
      child: Material(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: logo, name, location, arrow
              Container(
                color: _headerBg,
                height: 36,
                padding: const EdgeInsets.fromLTRB(7, 0, 5, 0),
                child: Row(children: [
                  _logo(),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(farm.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                height: 1.15,
                                fontWeight: FontWeight.w700)),
                        Row(children: [
                          const Icon(Icons.location_on_outlined,
                              size: 9, color: Colors.white70),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                                address.isEmpty
                                    ? context.l10n.farmNoAddress
                                    : address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                    height: 1.2)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 16),
                ]),
              ),
              // Pending documents — yellow band when there are any
              Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                decoration: pending > 0
                    ? const BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Color(0xFFF2C94C),
                          Color(0xFFF6DD7A),
                          _cardBg,
                        ], stops: [
                          0,
                          0.55,
                          1
                        ]),
                      )
                    : null,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('$pending',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: MobileColors.ink)),
                    const SizedBox(width: 5),
                    Text(
                        context.l10n.pendingDocumentsLabel(pending),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: MobileColors.ink)),
                  ]),
                ),
              ),
              // Employees
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 3, 8, 0),
                child: SizedBox(
                  height: 16,
                  child: Row(children: [
                    if (users.isNotEmpty) ...[
                      _avatars(),
                      const SizedBox(width: 5),
                    ],
                    Expanded(
                      child: Text(
                          context.l10n.employeeCount(employees),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: MobileColors.ink)),
                    ),
                  ]),
                ),
              ),
              // Standards
              Padding(
                padding: const EdgeInsets.fromLTRB(7, 3, 7, 0),
                child: Row(children: [
                  for (var i = 0; i < shown.length; i++) ...[
                    if (i > 0)
                      Container(
                        width: 1,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        color: Colors.white70,
                      ),
                    Expanded(
                      flex: shown[i].id == 'ipw' ? 2 : 3,
                      child: _standardChip(
                          shown[i].label, farm.packages.contains(shown[i].id)),
                    ),
                  ],
                ]),
              ),
              // Progress bars + percentage
              Expanded(
                child: Stack(fit: StackFit.expand, children: [
                  CustomPaint(painter: _BarsPainter(pct / 100)),
                  Positioned(
                    right: 7,
                    bottom: 0,
                    child: _OutlinedText('$pct%'),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        farm.name.trim().isEmpty ? '?' : farm.name.trim()[0].toUpperCase(),
        style: const TextStyle(
            color: MobileColors.green,
            fontSize: 11,
            fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _avatars() {
    const size = 15.0;
    const step = 9.0;
    final shown = users.take(4).toList();
    const colours = [
      Color(0xFF2E7D32),
      Color(0xFF6D4C41),
      Color(0xFF00897B),
      Color(0xFF5D4037),
    ];
    return SizedBox(
      width: size + step * (shown.length - 1),
      height: size,
      child: Stack(children: [
        for (var i = 0; i < shown.length; i++)
          Positioned(
            left: step * i,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: colours[i % colours.length],
                shape: BoxShape.circle,
                border: Border.all(color: _cardBg, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                shown[i].name.trim().isEmpty
                    ? '?'
                    : shown[i].name.trim()[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _standardChip(String label, bool active) {
    return Container(
      height: 13,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: active ? _headerBg : const Color(0xFFA5D6A7),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label,
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : const Color(0xFF7CB98A))),
      ),
    );
  }
}

/// Vertical bars across the bottom of a card; the first [fraction] of them
/// are dark green (done), the rest pale.
class _BarsPainter extends CustomPainter {
  final double fraction;
  _BarsPainter(this.fraction);

  @override
  void paint(Canvas canvas, Size size) {
    // Edge to edge, like the design: the first bar touches the card's left
    // edge and the last its right edge (the card's rounded corners clip them).
    // The spacing stretches slightly so the bars always fill the width.
    const barWidth = 4.5;
    const gap = 3.5;
    final count = ((size.width + gap) / (barWidth + gap)).round().clamp(2, 200);
    final pitch = (size.width - barWidth) / (count - 1);
    final filled = (fraction * count).round();
    final done = Paint()..color = const Color(0xFF43A047);
    final todo = Paint()..color = const Color(0xFFA5D6A7);
    for (var i = 0; i < count; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * pitch, 5, barWidth, size.height - 5),
        i < filled ? done : todo,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.fraction != fraction;
}

/// Big percentage outlined in the card colour so it stays readable over the bars.
class _OutlinedText extends StatelessWidget {
  final String text;
  const _OutlinedText(this.text);

  @override
  Widget build(BuildContext context) {
    const style =
        TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.1);
    return Stack(children: [
      Text(text,
          style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3
                ..strokeJoin = StrokeJoin.round
                ..color = _FarmCard._cardBg)),
      Text(text, style: style.copyWith(color: const Color(0xFF388E3C))),
    ]);
  }
}
