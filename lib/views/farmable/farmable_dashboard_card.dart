import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/core/services/farmable_service.dart';
import 'package:cropCompliance/models/company_model.dart';
import 'package:cropCompliance/models/farmable_models.dart';
import 'package:cropCompliance/theme/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// Shown on the dashboard when the company has a Farmable farm linked.
/// Displays fields (crops) and recent sales/harvest records.
class FarmableDashboardCard extends StatefulWidget {
  final CompanyModel company;

  const FarmableDashboardCard({Key? key, required this.company})
      : super(key: key);

  @override
  State<FarmableDashboardCard> createState() => _FarmableDashboardCardState();
}

class _FarmableDashboardCardState extends State<FarmableDashboardCard> {
  final _service = FarmableService();
  static DateFormat get _dateFmt => DateFormat('d MMM yyyy'); // follows the app language

  // Last result per farm, kept for the session so coming back to the dashboard
  // shows the card immediately while a fresh copy loads quietly in the background.
  static final Map<int, ({List<FarmableField> fields, List<FarmableSale> sales})>
      _cache = {};

  List<FarmableField> _fields = [];
  List<FarmableSale> _sales = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final cached = _cache[widget.company.farmableLocationId];
    if (cached != null) {
      _fields = cached.fields;
      _sales = cached.sales;
      _loading = false;
    }
    _load(silent: cached != null);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final farmId = widget.company.farmableLocationId!;
      // Fields and sales are independent requests — run them side by side
      // (fields used to be requested twice, one after the other), then keep
      // only the sales that belong to this farm's fields.
      final results = await Future.wait<Object>([
        _service.getFields(farmId: farmId),
        _service.getSales(),
      ]);
      final fields = results[0] as List<FarmableField>;
      final fieldIds = fields.map((f) => f.id).toSet();
      final sales = (results[1] as List<FarmableSale>)
          .where((s) => s.fieldIds.any(fieldIds.contains))
          .take(5)
          .toList();
      _cache[farmId] = (fields: fields, sales: sales);
      if (mounted) {
        setState(() {
          _fields = fields;
          _sales = sales;
          _error = null;
          _loading = false;
        });
      }
    } on FarmableException catch (e) {
      if (mounted && !silent) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted && !silent) setState(() { _error = context.l10n.fmFarmableLoadFailed; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: ThemeConstants.cardColors,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'FARMABLE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.fmFarmData,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!_loading)
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: context.l10n.actionRefresh,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.grey.shade500,
                  ),
              ],
            ),
            const SizedBox(height: 14),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _buildError()
            else ...[
              // ── Fields / Crops ───────────────────────────────────────
              if (_fields.isNotEmpty) ...[
                _sectionLabel(context.l10n.fmFieldsCrops, Icons.grass_outlined, primary),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _fields.map((f) => _buildFieldChip(f)).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // ── Recent Sales ─────────────────────────────────────────
              if (_sales.isNotEmpty) ...[
                _sectionLabel(context.l10n.fmRecentSales,
                    Icons.shopping_basket_outlined, primary),
                const SizedBox(height: 8),
                ...(_sales.map((s) => _buildSaleRow(s, primary))),
              ] else
                Text(
                  context.l10n.fmNoSales,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(RouteConstants.farmRegister),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: Text(context.l10n.fmViewRegister),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon, Color color) => Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.3),
          ),
        ],
      );

  Widget _buildFieldChip(FarmableField field) {
    final cropNames = field.varieties.isEmpty
        ? context.l10n.fmNoCrops
        : field.varieties.map((v) => v.categoryName).toSet().join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.name,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.fmCropArea(cropNames, field.areaHectares.toStringAsFixed(2)),
            style: TextStyle(fontSize: 11, color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleRow(FarmableSale sale, Color primary) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.shopping_basket_outlined,
                  size: 16, color: primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${sale.variety} — ${sale.categoryName}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _dateFmt.format(sale.date),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Text(
              sale.volumeDisplay,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700),
            ),
          ],
        ),
      );

  Widget _buildError() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ),
            TextButton(
              onPressed: _load,
              child: Text(context.l10n.actionRetry),
            ),
          ],
        ),
      );
}
