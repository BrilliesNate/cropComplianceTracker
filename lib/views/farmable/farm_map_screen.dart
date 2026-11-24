import 'package:cropCompliance/views/shared/admin_farm_chip.dart';
import 'package:cropCompliance/core/services/farmable_service.dart';
import 'package:cropCompliance/models/company_model.dart';
import 'package:cropCompliance/models/farmable_models.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/views/farmable/widgets/farm_map_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// Full-screen interactive "Sky View" — satellite map of the linked farm with
/// every block drawn from its real boundary, colour-coded by crop, tappable.
class FarmMapScreen extends StatefulWidget {
  const FarmMapScreen({Key? key}) : super(key: key);

  @override
  State<FarmMapScreen> createState() => _FarmMapScreenState();
}

class _FarmMapScreenState extends State<FarmMapScreen> {
  final _service = FarmableService();
  static final _num2 = NumberFormat('#,##0.00', 'en_ZA');

  bool _loading = true;
  String? _error;
  List<FarmableField> _fields = [];
  Map<String, Color> _cropColors = {};

  CompanyModel? get _company =>
      Provider.of<AuthProvider>(context, listen: false).effectiveCompany;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final company = _company;
    if (company == null || !company.hasFarmable) {
      setState(() {
        _loading = false;
        _error = context.l10n.fmNoFarmLinked;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fields = await _service.getFields(farmId: company.farmableLocationId);
      if (!mounted) return;
      setState(() {
        _fields = fields;
        _cropColors = FarmMapView.cropColorsFor(fields);
        _loading = false;
      });
    } on FarmableException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() { _error = context.l10n.fmMapLoadFailed; _loading = false; });
      }
    }
  }

  void _showBlock(FarmableField f) {
    final crop = FarmMapView.cropOf(f);
    final color = _cropColors[crop] ?? Colors.green;
    final variety =
        f.varieties.isEmpty ? '—' : f.varieties.map((v) => v.name).join(', ');
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 14, height: 14,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(f.name.trim(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 12),
            _row(context.l10n.fmCrop, crop),
            _row(context.l10n.fmVariety, variety),
            _row(context.l10n.fmFieldType, f.fieldType),
            _row(context.l10n.fmArea, context.l10n.fmHectares(_num2.format(f.areaHectares))),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 90,
              child: Text(k,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
          Expanded(
              child: Text(v,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: adminFarmAppBarBottom(context),
        title: Text(context.l10n.fmSkyView),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : Stack(
                  children: [
                    FarmMapView(
                      fields: _fields,
                      cropColors: _cropColors,
                      interactive: true,
                      showLabels: true,
                      onTapField: _showBlock,
                    ),
                    Positioned(left: 12, top: 12, child: _legend()),
                  ],
                ),
    );
  }

  Widget _legend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.fmCropsBlocks(_fields.length),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ..._cropColors.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 12, height: 12,
                      decoration: BoxDecoration(
                          color: e.value,
                          borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Text(e.key, style: const TextStyle(fontSize: 11)),
                ]),
              )),
        ],
      ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(_error ?? context.l10n.errorTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.actionRetry),
              ),
            ],
          ),
        ),
      );
}
