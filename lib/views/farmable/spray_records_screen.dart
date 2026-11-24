import 'package:cropCompliance/core/services/farmable_service.dart';
import 'package:cropCompliance/core/services/spray_record_service.dart';
import 'package:cropCompliance/models/company_model.dart';
import 'package:cropCompliance/models/farmable_models.dart';
import 'package:cropCompliance/models/spray_record_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/theme/theme_constants.dart';
import 'package:cropCompliance/views/shared/app_scaffold_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

class SprayRecordsScreen extends StatefulWidget {
  const SprayRecordsScreen({Key? key}) : super(key: key);

  @override
  State<SprayRecordsScreen> createState() => _SprayRecordsScreenState();
}

class _SprayRecordsScreenState extends State<SprayRecordsScreen> {
  final _service = SprayRecordService();
  final _farmableService = FarmableService();

  List<SprayRecord> _records = [];
  List<FarmableField> _farmableFields = [];
  bool _loading = true;
  String? _error;
  SprayRecordType _filter = SprayRecordType.spray;

  static DateFormat get _dateFmt => DateFormat('d MMM yyyy'); // follows the app language

  CompanyModel? get _company =>
      Provider.of<AuthProvider>(context, listen: false).effectiveCompany;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final company = _company;
    if (company == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final records = await _service.getRecordsForCompany(company.id);
      List<FarmableField> fields = [];
      if (company.hasFarmable) {
        try {
          fields = await _farmableService.getFields(
              farmId: company.farmableLocationId);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _records = records;
          _farmableFields = fields;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<SprayRecord> get _filtered =>
      _records.where((r) => r.type == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return AppScaffoldWrapper(
      title: context.l10n.srTitle,
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, null),
        backgroundColor: primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(context.l10n.srAddRecord, style: const TextStyle(color: Colors.white)),
      ),
      child: Column(
        children: [
          // ── Tab bar ────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _typeTab(SprayRecordType.spray, Icons.opacity, primary),
                const SizedBox(width: 10),
                _typeTab(SprayRecordType.fertilizer, Icons.grass, primary),
                const Spacer(),
                Text(
                  context.l10n.srRecordCount(_filtered.length),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Content ────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _filtered.isEmpty
                        ? _buildEmpty()
                        : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _typeTab(SprayRecordType type, IconData icon, Color primary) {
    final active = _filter == type;
    return GestureDetector(
      onTap: () => setState(() => _filter = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: active ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              type.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildCard(_filtered[i]),
    );
  }

  Widget _buildCard(SprayRecord record) {
    final primary = Theme.of(context).primaryColor;
    final isSpray = record.type == SprayRecordType.spray;
    final accent = isSpray ? Colors.blue.shade700 : Colors.green.shade700;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: ThemeConstants.cardColors,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _showForm(context, record),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      isSpray ? 'SPRAY' : 'FERTILIZER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      record.productName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (record.farmableSynced)
                    Tooltip(
                      message: context.l10n.srSyncedFarmable('${record.farmableJobId}'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sync, size: 11, color: Colors.green.shade700),
                            const SizedBox(width: 3),
                            Text('Farmable', // l10n-ignore: product name
                            
                                style: TextStyle(
                                    fontSize: 10, color: Colors.green.shade700)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _dateFmt.format(record.applicationDate),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Details row
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _detail(Icons.pest_control_outlined,
                      record.targetPestOrCrop, accent),
                  _detail(Icons.grass_outlined,
                      record.fieldNames.isEmpty
                          ? context.l10n.srNoFields
                          : record.fieldNames.join(', '),
                      Colors.grey.shade600),
                  _detail(Icons.science_outlined,
                      '${record.rate} ${record.unit}', Colors.grey.shade600),
                  _detail(Icons.person_outline,
                      record.operatorName, Colors.grey.shade600),
                  if (record.preHarvestIntervalDays != null)
                    _detail(Icons.timer_outlined,
                        context.l10n.srPhiDays(record.preHarvestIntervalDays!),
                        Colors.orange.shade700),
                ],
              ),

              if (record.notes != null && record.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  record.notes!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String text, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(fontSize: 12, color: color),
              overflow: TextOverflow.ellipsis),
        ],
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _filter == SprayRecordType.spray
                  ? Icons.opacity_outlined
                  : Icons.grass_outlined,
              size: 56,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 14),
            Text(
              _filter == SprayRecordType.spray
                  ? context.l10n.srNoRecordsSpray
                  : context.l10n.srNoRecordsFert,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.srEmptyHint,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 40),
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: Colors.red.shade600)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: Text(context.l10n.actionRetry)),
          ],
        ),
      );

  // ── Add / Edit form ─────────────────────────────────────────────────────

  void _showForm(BuildContext context, SprayRecord? existing) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SprayRecordFormDialog(
        existing: existing,
        companyId: _company?.id ?? '',
        farmableFields: _farmableFields,
        onSaved: (record) async {
          final saved = await _service.save(record);
          if (saved != null) {
            await _load();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(existing == null
                    ? context.l10n.srAdded
                    : context.l10n.srUpdated),
                backgroundColor: Colors.green,
              ));
            }
          }
        },
        onDelete: existing == null
            ? null
            : () async {
                final ok = await _service.delete(existing.id);
                if (ok) {
                  await _load();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(context.l10n.srDeleted),
                      backgroundColor: Colors.red,
                    ));
                  }
                }
              },
      ),
    );
  }
}

// ── Form dialog ─────────────────────────────────────────────────────────────

class SprayRecordFormDialog extends StatefulWidget {
  final SprayRecord? existing;
  final String companyId;
  final List<FarmableField> farmableFields;
  final void Function(SprayRecord) onSaved;
  final VoidCallback? onDelete;

  const SprayRecordFormDialog({
    Key? key,
    required this.existing,
    required this.companyId,
    required this.farmableFields,
    required this.onSaved,
    this.onDelete,
  }) : super(key: key);

  @override
  State<SprayRecordFormDialog> createState() => _SprayRecordFormDialogState();
}

class _SprayRecordFormDialogState extends State<SprayRecordFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late SprayRecordType _type;
  late DateTime _date;
  late TextEditingController _product;
  late TextEditingController _activeIngredient;
  late TextEditingController _regNumber;
  late TextEditingController _target;
  late TextEditingController _rate;
  late String _unit;
  late TextEditingController _totalAmount;
  late TextEditingController _operator;
  late TextEditingController _equipment;
  late TextEditingController _phi;
  late TextEditingController _rei;
  late TextEditingController _weather;
  late TextEditingController _notes;

  // Selected Farmable fields
  final Set<int> _selectedFieldIds = {};

  static DateFormat get _dateFmt => DateFormat('d MMM yyyy'); // follows the app language

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? SprayRecordType.spray;
    _date = e?.applicationDate ?? DateTime.now();
    _product = TextEditingController(text: e?.productName ?? '');
    _activeIngredient = TextEditingController(text: e?.activeIngredient ?? '');
    _regNumber = TextEditingController(text: e?.registrationNumber ?? '');
    _target = TextEditingController(text: e?.targetPestOrCrop ?? '');
    _rate = TextEditingController(
        text: e != null ? e.rate.toString() : '');
    _unit = e?.unit ?? 'L/ha';
    _totalAmount = TextEditingController(
        text: e?.totalAmountUsed?.toString() ?? '');
    _operator = TextEditingController(text: e?.operatorName ?? '');
    _equipment = TextEditingController(text: e?.equipment ?? '');
    _phi = TextEditingController(
        text: e?.preHarvestIntervalDays?.toString() ?? '');
    _rei = TextEditingController(
        text: e?.reEntryIntervalDays?.toString() ?? '');
    _weather = TextEditingController(text: e?.weatherConditions ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    if (e != null) _selectedFieldIds.addAll(e.farmableFieldIds);
  }

  @override
  void dispose() {
    for (final c in [
      _product, _activeIngredient, _regNumber, _target, _rate,
      _totalAmount, _operator, _equipment, _phi, _rei, _weather, _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d != null) setState(() => _date = d);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final selectedFields = widget.farmableFields
        .where((f) => _selectedFieldIds.contains(f.id))
        .toList();

    final record = SprayRecord(
      id: widget.existing?.id ?? '',
      companyId: widget.companyId,
      type: _type,
      applicationDate: _date,
      productName: _product.text.trim(),
      activeIngredient: _activeIngredient.text.trim().isEmpty
          ? null
          : _activeIngredient.text.trim(),
      registrationNumber: _regNumber.text.trim().isEmpty
          ? null
          : _regNumber.text.trim(),
      targetPestOrCrop: _target.text.trim(),
      rate: double.tryParse(_rate.text) ?? 0,
      unit: _unit,
      totalAmountUsed: double.tryParse(_totalAmount.text),
      fieldNames: selectedFields.isEmpty
          ? (_product.text.trim().isNotEmpty ? [] : [])
          : selectedFields.map((f) => f.name).toList(),
      farmableFieldIds: _selectedFieldIds.toList(),
      operatorName: _operator.text.trim(),
      equipment: _equipment.text.trim().isEmpty ? null : _equipment.text.trim(),
      preHarvestIntervalDays: int.tryParse(_phi.text),
      reEntryIntervalDays: int.tryParse(_rei.text),
      weatherConditions:
          _weather.text.trim().isEmpty ? null : _weather.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      farmableSynced: widget.existing?.farmableSynced ?? false,
      farmableJobId: widget.existing?.farmableJobId,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context);
    widget.onSaved(record);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null
                          ? context.l10n.srLogTitle
                          : context.l10n.srEditTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red.shade400, size: 20),
                      tooltip: context.l10n.srDeleteTooltip,
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(context.l10n.srDeleteTitle),
                            content: Text(context.l10n.srDeleteBody),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(context.l10n.commonCancel)),
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: Text(context.l10n.actionDelete,
                                      style:
                                          const TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          Navigator.pop(context);
                          widget.onDelete!();
                        }
                      },
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),

            // ── Form ─────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type toggle
                      Row(
                        children: [
                          _typeBtn(SprayRecordType.spray, Icons.opacity, context.l10n.srSpray, primary),
                          const SizedBox(width: 10),
                          _typeBtn(SprayRecordType.fertilizer, Icons.grass, context.l10n.srFertilizer, primary),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Date
                      _label(context.l10n.srAppDate),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 16, color: primary),
                              const SizedBox(width: 8),
                              Text(_dateFmt.format(_date),
                                  style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Product
                      _label(context.l10n.srProduct),
                      _field(_product,
                          hint: context.l10n.srProductHint,
                          validator: (v) => v == null || v.isEmpty
                              ? context.l10n.required
                              : null),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label(context.l10n.srActiveIngredient),
                                _field(_activeIngredient,
                                    hint: context.l10n.srActiveIngredientHint),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label(context.l10n.srRegNumber),
                                _field(_regNumber, hint: 'e.g. L3421'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Target
                      _label(_type == SprayRecordType.spray
                          ? context.l10n.srTargetPest
                          : context.l10n.srTargetCrop),
                      _field(_target,
                          hint: _type == SprayRecordType.spray
                              ? context.l10n.srTargetPestHint
                              : context.l10n.srTargetCropHint,
                          validator: (v) =>
                              v == null || v.isEmpty ? context.l10n.required : null),
                      const SizedBox(height: 14),

                      // Rate + unit
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label(context.l10n.srRate),
                                _field(_rate,
                                    hint: '0.00',
                                    keyboard: TextInputType.numberWithOptions(
                                        decimal: true),
                                    validator: (v) {
                                  if (v == null || v.isEmpty) return context.l10n.required;
                                  if (double.tryParse(v) == null) {
                                    return context.l10n.enterANumber;
                                  }
                                  return null;
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label(context.l10n.srUnit),
                                DropdownButtonFormField<String>(
                                  value: _unit,
                                  decoration: _inputDec(''),
                                  items: kSprayUnits
                                      .map((u) => DropdownMenuItem(
                                          value: u, child: Text(u, style: const TextStyle(fontSize: 13))))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _unit = v);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label(context.l10n.srTotalUsed),
                                _field(_totalAmount,
                                    hint: 'e.g. 50 L',
                                    keyboard: TextInputType.numberWithOptions(
                                        decimal: true)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Farmable fields (optional)
                      if (widget.farmableFields.isNotEmpty) ...[
                        _label(context.l10n.srFieldsTreated),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.farmableFields.map((f) {
                            final selected = _selectedFieldIds.contains(f.id);
                            return FilterChip(
                              label: Text(f.name,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: selected
                                          ? Colors.white
                                          : Colors.black87)),
                              selected: selected,
                              selectedColor: primary,
                              checkmarkColor: Colors.white,
                              backgroundColor: Colors.grey.shade100,
                              onSelected: (v) => setState(() {
                                if (v) {
                                  _selectedFieldIds.add(f.id);
                                } else {
                                  _selectedFieldIds.remove(f.id);
                                }
                              }),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Operator + equipment
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label(context.l10n.srOperator),
                                _field(_operator,
                                    hint: context.l10n.fullNameHint,
                                    validator: (v) =>
                                        v == null || v.isEmpty
                                            ? context.l10n.required
                                            : null),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label(context.l10n.srEquipment),
                                _field(_equipment,
                                    hint: context.l10n.srEquipmentHint),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // PHI + REI
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label(context.l10n.srPhi),
                                _field(_phi,
                                    hint: context.l10n.srPhiHint,
                                    keyboard: TextInputType.number),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label(context.l10n.srRei),
                                _field(_rei,
                                    hint: context.l10n.srReiHint,
                                    keyboard: TextInputType.number),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _label(context.l10n.srWeather),
                      _field(_weather,
                          hint: context.l10n.srWeatherHint),
                      const SizedBox(height: 14),

                      _label(context.l10n.formNotes),
                      _field(_notes, hint: context.l10n.srNotesHint, maxLines: 2),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer ───────────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.l10n.commonCancel),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                        backgroundColor: primary),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            widget.existing == null ? context.l10n.srSave : context.l10n.actionUpdate,
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(SprayRecordType t, IconData icon, String label, Color primary) {
    final active = _type == t;
    return GestureDetector(
      onTap: () => setState(() => _type = t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? primary : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: active ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700)),
      );

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      );

  Widget _field(
    TextEditingController ctrl, {
    String hint = '',
    String? Function(String?)? validator,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: ctrl,
        validator: validator,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13),
        decoration: _inputDec(hint),
      );
}
