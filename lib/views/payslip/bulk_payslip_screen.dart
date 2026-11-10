import 'package:cropCompliance/models/employee_model.dart';
import 'package:cropCompliance/models/payslip_model.dart';
import 'package:cropCompliance/providers/payslip_provider.dart';
import 'package:cropCompliance/views/payslip/utils/payslip_pdf_builder.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ── Helper class to hold per-employee row state ───────────────────────────────

class _EmployeeRow {
  final EmployeeModel employee;

  final TextEditingController rateCtrl;
  final TextEditingController normalCtrl;
  final TextEditingController overtimeCtrl;
  final TextEditingController doubleCtrl;
  final TextEditingController publicCtrl;

  // Result after generation
  PayslipModel? generated;
  bool generating = false;
  String? error;

  _EmployeeRow(EmployeeModel emp)
      : employee = emp,
        rateCtrl = TextEditingController(
            text: emp.normalHourlyRate > 0
                ? emp.normalHourlyRate.toStringAsFixed(2)
                : ''),
        normalCtrl = TextEditingController(),
        overtimeCtrl = TextEditingController(),
        doubleCtrl = TextEditingController(),
        publicCtrl = TextEditingController();

  void dispose() {
    rateCtrl.dispose();
    normalCtrl.dispose();
    overtimeCtrl.dispose();
    doubleCtrl.dispose();
    publicCtrl.dispose();
  }

  double get _rate => double.tryParse(rateCtrl.text) ?? 0;
  double get _normal => double.tryParse(normalCtrl.text) ?? 0;
  double get _overtime => double.tryParse(overtimeCtrl.text) ?? 0;
  double get _double => double.tryParse(doubleCtrl.text) ?? 0;
  double get _public => double.tryParse(publicCtrl.text) ?? 0;

  double get liveNetPay {
    final r = _rate;
    final earnings = _normal * r +
        _overtime * r * 1.5 +
        _double * r * 2.0 +
        _public * r;
    return earnings * 0.99; // minus 1% UIF
  }

  bool get hasAnyHours =>
      _normal > 0 || _overtime > 0 || _double > 0 || _public > 0;
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class BulkPayslipScreen extends StatefulWidget {
  final String companyId;
  final String companyName;

  const BulkPayslipScreen({
    Key? key,
    required this.companyId,
    required this.companyName,
  }) : super(key: key);

  @override
  State<BulkPayslipScreen> createState() => _BulkPayslipScreenState();
}

class _BulkPayslipScreenState extends State<BulkPayslipScreen> {
  // ── Header controllers ──────────────────────────────────────────────────────
  DateTime _periodStart = DateTime(
      DateTime.now().year, DateTime.now().month, 1);
  DateTime _periodEnd = DateTime(
      DateTime.now().year, DateTime.now().month,
      DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month));
  DateTime _payDate = DateTime.now();
  final TextEditingController _uifCtrl = TextEditingController();

  // ── Row state ───────────────────────────────────────────────────────────────
  List<_EmployeeRow> _rows = [];
  bool _generating = false;
  bool _generated = false; // true once at least one payslip created

  static final _currency =
      NumberFormat.currency(locale: 'en_ZA', symbol: 'R ', decimalDigits: 2);
  static final _dateFmt = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final provider = Provider.of<PayslipProvider>(context, listen: false);
    final settings = provider.payrollSettings;
    if (settings != null) {
      _uifCtrl.text = settings.uifRegNumber;
    }
    setState(() {
      _rows = provider.employees
          .map((e) => _EmployeeRow(e))
          .toList();
    });
  }

  @override
  void dispose() {
    _uifCtrl.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  // ── Date pickers ────────────────────────────────────────────────────────────

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _periodStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _periodStart = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _periodEnd,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _periodEnd = picked);
  }

  Future<void> _pickPayDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _payDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _payDate = picked);
  }

  // ── Generate ────────────────────────────────────────────────────────────────

  Future<void> _generate() async {
    // Save UIF reg if changed
    final provider = Provider.of<PayslipProvider>(context, listen: false);
    final newUif = _uifCtrl.text.trim();
    final currentUif = provider.payrollSettings?.uifRegNumber ?? '';
    if (newUif != currentUif) {
      await provider.savePayrollSettings(
        PayrollSettings(companyId: widget.companyId, uifRegNumber: newUif),
      );
    }

    final rowsToGenerate = _rows.where((r) => r.hasAnyHours).toList();
    if (rowsToGenerate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter hours for at least one employee.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _generating = true);

    int success = 0;
    int failed = 0;

    for (final row in rowsToGenerate) {
      setState(() => row.generating = true);
      try {
        final rate = double.tryParse(row.rateCtrl.text) ?? 0;
        final payslip = PayslipModel(
          id: '',
          companyId: widget.companyId,
          companyName: widget.companyName,
          employeeId: row.employee.id,
          employeeName: row.employee.name,
          employeeIdNumber: row.employee.idNumber,
          uifRegNumber: newUif,
          payPeriodStart: _periodStart,
          payPeriodEnd: _periodEnd,
          payDate: _payDate,
          normalHours: double.tryParse(row.normalCtrl.text) ?? 0,
          overtimeHours: double.tryParse(row.overtimeCtrl.text) ?? 0,
          doubleTimeHours: double.tryParse(row.doubleCtrl.text) ?? 0,
          publicHolidayHours: double.tryParse(row.publicCtrl.text) ?? 0,
          normalRate: rate,
          overtimeRate: rate * 1.5,
          doubleTimeRate: rate * 2.0,
          additionalDeductions: [],
          status: PayslipStatus.draft,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final saved = await provider.savePayslip(payslip);
        setState(() {
          row.generating = false;
          row.generated = saved;
          row.error = saved == null ? 'Save failed' : null;
        });
        if (saved != null) success++; else failed++;
      } catch (e) {
        setState(() {
          row.generating = false;
          row.error = e.toString();
        });
        failed++;
      }
    }

    setState(() {
      _generating = false;
      _generated = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failed == 0
              ? '$success payslip${success == 1 ? '' : 's'} generated successfully'
              : '$success generated, $failed failed'),
          backgroundColor: failed == 0 ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ── PDF ─────────────────────────────────────────────────────────────────────

  Future<void> _downloadPdf(_EmployeeRow row) async {
    if (row.generated == null) return;
    try {
      await PayslipPdfBuilder.openInBrowser(row.generated!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('PDF error: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bulk Payslip Generator',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            Text(widget.companyName,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        elevation: 0,
        actions: [
          if (!_generating && _rows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: FilledButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.bolt, size: 18),
                label: const Text('Generate All'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primary,
                ),
              ),
            ),
        ],
      ),
      body: _rows.isEmpty
          ? _buildEmptyState(primary)
          : Column(
              children: [
                _buildHeader(primary),
                Expanded(child: _buildTable(primary)),
              ],
            ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState(Color primary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No employees found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Add employees in the Payslip Manager first.',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Manager'),
          ),
        ],
      ),
    );
  }

  // ── Header (period + UIF) ───────────────────────────────────────────────────

  Widget _buildHeader(Color primary) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _dateChip(
            label: 'Period Start',
            date: _periodStart,
            onTap: _pickStart,
            primary: primary,
          ),
          _dateChip(
            label: 'Period End',
            date: _periodEnd,
            onTap: _pickEnd,
            primary: primary,
          ),
          _dateChip(
            label: 'Pay Date',
            date: _payDate,
            onTap: _pickPayDate,
            primary: primary,
          ),
          SizedBox(
            width: 200,
            child: TextField(
              controller: _uifCtrl,
              decoration: InputDecoration(
                labelText: 'Employer UIF Reg Nr',
                hintText: 'e.g. 2230696/3',
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
          if (_generating)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _dateChip(
      {required String label,
      required DateTime date,
      required VoidCallback onTap,
      required Color primary}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 14, color: primary),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade600)),
                Text(_dateFmt.format(date),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Table ───────────────────────────────────────────────────────────────────

  Widget _buildTable(Color primary) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTableHeader(primary),
          ..._rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            return _buildTableRow(row, idx, primary);
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  static const _colWidths = <double>[
    200, // Employee name
    110, // Rate
    90,  // Normal hrs
    90,  // OT hrs
    90,  // DT hrs
    90,  // PH hrs
    110, // Live net pay
    90,  // Action
  ];

  Widget _buildTableHeader(Color primary) {
    final headers = [
      'Employee',
      'Rate (R/hr)',
      'Normal\nhrs',
      'Overtime\nhrs',
      'Double\nTime',
      'Public\nHol',
      'Est. Net Pay',
      '',
    ];

    return Container(
      decoration: BoxDecoration(
        color: primary.withOpacity(0.06),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < headers.length; i++)
            SizedBox(
              width: _colWidths[i],
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Text(
                  headers[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                  textAlign:
                      i == 0 ? TextAlign.left : TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableRow(_EmployeeRow row, int idx, Color primary) {
    final isOdd = idx.isOdd;
    final bgColor = isOdd ? Colors.grey.shade50 : Colors.white;
    final hasGen = row.generated != null;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Employee name
          SizedBox(
            width: _colWidths[0],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  if (hasGen)
                    Icon(Icons.check_circle,
                        size: 14, color: Colors.green.shade600)
                  else if (row.error != null)
                    Icon(Icons.error_outline,
                        size: 14, color: Colors.red.shade600)
                  else
                    Icon(Icons.person_outline,
                        size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      row.employee.name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rate
          SizedBox(
            width: _colWidths[1],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: _compactField(
                  row.rateCtrl, primary, enabled: !hasGen),
            ),
          ),

          // Normal hours
          SizedBox(
            width: _colWidths[2],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: _compactField(row.normalCtrl, primary,
                  enabled: !hasGen),
            ),
          ),

          // Overtime
          SizedBox(
            width: _colWidths[3],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: _compactField(row.overtimeCtrl, primary,
                  enabled: !hasGen),
            ),
          ),

          // Double time
          SizedBox(
            width: _colWidths[4],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: _compactField(row.doubleCtrl, primary,
                  enabled: !hasGen),
            ),
          ),

          // Public holiday
          SizedBox(
            width: _colWidths[5],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: _compactField(row.publicCtrl, primary,
                  enabled: !hasGen),
            ),
          ),

          // Est. net pay / result
          SizedBox(
            width: _colWidths[6],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: hasGen
                  ? Text(
                      _currency.format(row.generated!.netSalary),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700),
                      textAlign: TextAlign.center,
                    )
                  : row.error != null
                      ? Text('Error',
                          style: TextStyle(
                              fontSize: 12, color: Colors.red.shade600),
                          textAlign: TextAlign.center)
                      : _LiveNetPay(row: row, currency: _currency),
            ),
          ),

          // Action button
          SizedBox(
            width: _colWidths[7],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: row.generating
                  ? const Center(
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2)))
                  : hasGen
                      ? Tooltip(
                          message: 'Download PDF',
                          child: IconButton(
                            icon: Icon(Icons.picture_as_pdf,
                                color: primary, size: 20),
                            onPressed: () => _downloadPdf(row),
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactField(TextEditingController ctrl, Color primary,
      {bool enabled = true}) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: !enabled,
        fillColor: Colors.grey.shade100,
      ),
      onChanged: (_) => setState(() {}),
    );
  }
}

// ── Live net pay widget (rebuilds when controllers change) ─────────────────────

class _LiveNetPay extends StatefulWidget {
  final _EmployeeRow row;
  final NumberFormat currency;

  const _LiveNetPay({required this.row, required this.currency});

  @override
  State<_LiveNetPay> createState() => _LiveNetPayState();
}

class _LiveNetPayState extends State<_LiveNetPay> {
  @override
  void initState() {
    super.initState();
    widget.row.rateCtrl.addListener(_rebuild);
    widget.row.normalCtrl.addListener(_rebuild);
    widget.row.overtimeCtrl.addListener(_rebuild);
    widget.row.doubleCtrl.addListener(_rebuild);
    widget.row.publicCtrl.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.row.rateCtrl.removeListener(_rebuild);
    widget.row.normalCtrl.removeListener(_rebuild);
    widget.row.overtimeCtrl.removeListener(_rebuild);
    widget.row.doubleCtrl.removeListener(_rebuild);
    widget.row.publicCtrl.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final net = widget.row.liveNetPay;
    if (net <= 0) {
      return Text('–',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          textAlign: TextAlign.center);
    }
    return Text(
      widget.currency.format(net),
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700),
      textAlign: TextAlign.center,
    );
  }
}
