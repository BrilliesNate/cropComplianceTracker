import 'package:cropCompliance/core/services/farm_summary_service.dart';
import 'package:cropCompliance/core/utils/session_actions.dart';
import 'package:cropCompliance/models/company_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/views/shared/app_scaffold_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// The landing page for a user with access to more than one farm — the
/// counterpart of the admin dashboard. Pick a farm and the rest of the app
/// (Dashboard, Compliance Tracker, Audit Index …) works inside it. The farm
/// switcher in the app bar remains a shortcut from any page.
class MyFarmsScreen extends StatefulWidget {
  const MyFarmsScreen({Key? key}) : super(key: key);

  @override
  State<MyFarmsScreen> createState() => _MyFarmsScreenState();
}

/// Last result, kept for the session so coming back is instant while fresh
/// numbers load quietly and are swapped in with a single update.
class _FarmsCache {
  final String key;
  final List<FarmSummary> summaries;
  _FarmsCache(this.key, this.summaries);
}

class _MyFarmsScreenState extends State<MyFarmsScreen> {
  static _FarmsCache? _cache;

  List<FarmSummary> _summaries = [];
  bool _isLoading = true; // first visit only: one loader, then the finished page
  bool _refreshing = false;
  bool _opening = false;
  String? _error;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();
  int _generation = 0;

  static const int _searchThreshold = 6;

  String _cacheKey(AuthProvider auth) =>
      '${auth.currentUser?.id}|${auth.accessibleCompanies.map((c) => c.id).join(',')}'; // l10n-ignore: cache key

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cached = _cache;
    if (cached != null && cached.key == _cacheKey(auth)) {
      _summaries = cached.summaries;
      _isLoading = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Only multi-farm users have a farm picker; everyone else goes home.
      if (!auth.canSwitchCompany) {
        Navigator.of(context).pushReplacementNamed(auth.homeRoute);
        return;
      }
      _load();
    });
  }

  @override
  void dispose() {
    _generation++;
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final farms = auth.accessibleCompanies;
    final gen = ++_generation;
    if (_summaries.isNotEmpty) setState(() => _refreshing = true);

    try {
      final result =
          await FarmSummaryService.load(farms, approvedOnly: auth.isAuditer);
      if (!mounted || gen != _generation) return;
      _cache = _FarmsCache(_cacheKey(auth), result);
      setState(() {
        _summaries = result;
        _error = null;
        _isLoading = false;
        _refreshing = false;
      });
    } catch (e) {
      print('MyFarmsScreen: load failed: $e');
      if (!mounted || gen != _generation) return;
      setState(() {
        _isLoading = false;
        _refreshing = false;
        if (_summaries.isEmpty) _error = context.l10n.farmsLoadFailed;
      });
    }
  }

  Future<void> _open(CompanyModel farm) async {
    if (_opening) return;
    setState(() => _opening = true);
    final ok = await switchFarm(context, farm.id);
    if (!mounted) return;
    if (!ok) {
      setState(() => _opening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.farmOpenFailed)),
      );
    }
    // On success the page is replaced by the farm's own screen.
  }

  List<FarmSummary> get _visible {
    if (_query.isEmpty) return _summaries;
    final q = _query.toLowerCase();
    return _summaries
        .where((s) =>
            s.company.name.toLowerCase().contains(q) ||
            s.company.address.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    Widget body;
    if (_isLoading && _summaries.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null && _summaries.isEmpty) {
      body = _buildError();
    } else {
      body = RefreshIndicator(onRefresh: _load, child: _buildContent(auth));
    }

    return AppScaffoldWrapper(
      title: context.l10n.menuMyFarms,
      backgroundColor: Colors.grey.shade50,
      child: body,
    );
  }

  Widget _buildError() {
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
              _load();
            },
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.actionRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AuthProvider auth) {
    final visible = _visible;
    final showSearch = _summaries.length > _searchThreshold;

    return Column(
      children: [
        Container(
          color: Colors.white,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.farmChooseAFarm,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      auth.isAuditer
                          ? context.l10n.farmsAuditorCount(_summaries.length)
                          : context.l10n.farmAccessCount(_summaries.length),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.actionRefresh,
                onPressed: _refreshing ? null : _load,
                icon: Icon(Icons.refresh, color: Colors.grey.shade600, size: 20),
              ),
            ],
          ),
        ),
        if (showSearch)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.l10n.farmsSearchHint,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(context.l10n.farmsNoneFound,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 440,
                    mainAxisExtent: 132, // fixed height: content can never overflow
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (_, i) => _buildFarmCard(visible[i], auth),
                ),
        ),
      ],
    );
  }

  Widget _buildFarmCard(FarmSummary s, AuthProvider auth) {
    final primary = Theme.of(context).primaryColor;
    final farm = s.company;
    final isCurrent = auth.effectiveCompany?.id == farm.id;
    final hasPending = s.pendingDocs > 0;
    final auditor = auth.isAuditer;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _opening ? null : () => _open(farm),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasPending && !auditor
                  ? Colors.orange.shade300
                  : isCurrent
                      ? primary.withOpacity(0.5)
                      : Colors.grey.shade200,
              width: (hasPending && !auditor) || isCurrent ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        farm.name.isNotEmpty ? farm.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farm.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          farm.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.l10n.farmCurrent,
                        style: TextStyle(
                          color: primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  if (farm.packages.contains('siza_wieta')) _badge('SIZA', primary),
                  if (farm.packages.contains('globalgap')) _badge('GAP', primary),
                  if (farm.packages.contains('ipw')) _badge('IPW', primary),
                  if (farm.packages.contains('fairtrade')) _badge('FT', primary),
                  if (farm.packages.contains('siza_environmental'))
                    _badge('SIZA-E', primary),
                  const Spacer(),
                  Icon(Icons.description_outlined,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 2),
                  Text(
                    s.loaded ? '${s.documentCount}' : '—',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (auditor)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('approved',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ),
                  if (!auditor && hasPending) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pending_actions,
                              size: 12, color: Colors.orange.shade700),
                          const SizedBox(width: 3),
                          Text(
                            '${s.pendingDocs}',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!auditor && s.loaded) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _completionColor(s.completion).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${s.completion}%',
                        style: TextStyle(
                          color: _completionColor(s.completion),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color primary) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primary,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Same thresholds as the admin dashboard.
  Color _completionColor(int pct) {
    if (pct >= 80) return Colors.green.shade600;
    if (pct >= 50) return Colors.orange.shade600;
    return Colors.red.shade600;
  }
}
