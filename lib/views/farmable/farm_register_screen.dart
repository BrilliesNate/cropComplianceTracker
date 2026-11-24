import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/core/services/farmable_service.dart';
import 'package:cropCompliance/models/company_model.dart';
import 'package:cropCompliance/models/farmable_models.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/views/farmable/farmable_register_pdf.dart';
import 'package:cropCompliance/views/farmable/widgets/farm_dashboard_view.dart';
import 'package:cropCompliance/views/farmable/widgets/farm_map_view.dart';
import 'package:cropCompliance/views/shared/app_scaffold_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// Loads a Farmable-linked company's data and renders the immersive
/// [FarmDashboardView] (satellite hero + registers), with an audit PDF export.
class FarmRegisterScreen extends StatefulWidget {
  const FarmRegisterScreen({Key? key}) : super(key: key);

  @override
  State<FarmRegisterScreen> createState() => _FarmRegisterScreenState();
}

class _FarmRegisterScreenState extends State<FarmRegisterScreen> {
  final _service = FarmableService();

  bool _loading = true;
  String? _error;

  FarmableLocation? _farm;
  List<FarmableField> _fields = [];
  List<FarmableEquipment> _equipment = [];
  List<({FarmableMember member, String role})> _people = [];
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
    final farmId = company.farmableLocationId!;
    try {
      final results = await Future.wait([
        _service.getFarms(),
        _service.getFields(farmId: farmId),
        _service.getEquipment(farmId: farmId),
        _service.getFarmMembers(),
      ]);
      final farms = results[0] as List<FarmableLocation>;
      FarmableLocation? farm;
      for (final f in farms) {
        if (f.id == farmId) farm = f;
      }
      final members = results[3] as List<FarmableMember>;
      final people = members
          .where((m) => m.roles.containsKey('$farmId'))
          .map((m) => (member: m, role: m.roles['$farmId']!))
          .toList();
      final fields = (results[1] as List<FarmableField>)
        ..sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;
      setState(() {
        _farm = farm;
        _fields = fields;
        _cropColors = FarmMapView.cropColorsFor(fields);
        _equipment = results[2] as List<FarmableEquipment>;
        _people = people;
        _loading = false;
      });
    } on FarmableException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() { _error = context.l10n.fmDataLoadFailed; _loading = false; });
      }
    }
  }

  Future<void> _downloadPdf() async {
    try {
      await FarmableRegisterPdf.download(
        companyName: _company?.name ?? context.l10n.farm,
        farm: _farm,
        fields: _fields,
        equipment: _equipment,
        people: _people,
        generatedOn: DateTime.now(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.pdfError('$e')),
            backgroundColor: Colors.grey.shade800));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldWrapper(
      title: context.l10n.menuFarmRegister,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : FarmDashboardView(
                  farm: _farm,
                  companyName: _company?.name ?? context.l10n.farm,
                  fields: _fields,
                  equipment: _equipment,
                  people: _people,
                  cropColors: _cropColors,
                  onSkyView: () => Navigator.of(context)
                      .pushNamed(RouteConstants.farmMap),
                  onPdf: _downloadPdf,
                ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 48, color: Colors.grey.shade400),
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
