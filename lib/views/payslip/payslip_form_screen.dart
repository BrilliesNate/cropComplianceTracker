import 'package:cropCompliance/models/employee_model.dart';
import 'package:cropCompliance/models/payslip_model.dart';
import 'package:cropCompliance/providers/payslip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PayslipFormScreen extends StatefulWidget {
  final String? payslipId;
  final String companyId;
  final String companyName;

  const PayslipFormScreen({
    Key? key,
    this.payslipId,
    required this.companyId,
    required this.companyName,
  }) : super(key: key);

  @override
  State<PayslipFormScreen> createState() => _PayslipFormScreenState();
}

class _PayslipFormScreenState extends State<PayslipFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currency =
      NumberFormat.currency(locale: 'en_ZA', symbol: 'R ', decimalDigits: 2);
  final _dateFormat = DateFormat('d MMM yyyy');

  // Employee
  EmployeeModel? _selectedEmployee;

  // Dates
  DateTime _periodStart = DateTime.now().subtract(const Duration(days: 14));
  DateTime _periodEnd = DateTime.now();
  DateTime _payDate = DateTime.now();

  // Rate controllers
  late TextEditingController _normalRate;
  late TextEditingController _overtimeRate;
  late TextEditingController _doubleTimeRate;

  // Hours controllers
  late TextEditingController _normalHours;
  late TextEditingController _overtimeHours;
  late TextEditingController _doubleHours;
  late TextEditingController _publicHolidayHours;

  // Additional deductions
  final List<_DeductionRow> _deductions = [];

  bool _saving = false;
  bool _isEdit = false;
  PayslipModel? _existingPayslip;

  @override
  void initState() {
    super.initState();
    _normalRate = TextEditingController()..addListener(_rebuild);
    _overtimeRate = TextEditingController()..addListener(_rebuild);
    _doubleTimeRate = TextEditingController()..addListener(_rebuild);
    _normalHours = TextEditingController()..addListener(_rebuild);
    _overtimeHours = TextEditingController()..addListener(_rebuild);
    _doubleHours = TextEditingController()..addListener(_rebuild);
    _publicHolidayHours = TextEditingController()..addListener(_rebuild);

    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _rebuild() => setState(() {});

  Future<void> _init() async {
    final provider =
        Provider.of<PayslipProvider>(context, listen: false);

    if (widget.payslipId != null) {
      _existingPayslip = provider.getPayslipById(widget.payslipId!);
      if (_existingPayslip != null) {
        _isEdit = true;
        _prefillFromPayslip(_existingPayslip!, provider.employees);
      }
    }
  }

  void _prefillFromPayslip(PayslipModel p, List<EmployeeModel> employees) {
    try {
      _selectedEmployee =
          employees.firstWhere((e) => e.id == p.employeeId);
    } catch (_) {}

    _periodStart = p.payPeriodStart;
    _periodEnd = p.payPeriodEnd;
    _payDate = p.payDate;

    _normalRate.text = p.normalRate.toStringAsFixed(2);
    _overtimeRate.text = p.overtimeRate.toStringAsFixed(2);
    _doubleTimeRate.text = p.doubleTimeRate.toStringAsFixed(2);
    _normalHours.text = p.normalHours.toStringAsFixed(2);
    _overtimeHours.text =
        p.overtimeHours > 0 ? p.overtimeHours.toStringAsFixed(2) : '';
    _doubleHours.text =
        p.doubleTimeHours > 0 ? p.doubleTimeHours.toStringAsFixed(2) : '';
    _publicHolidayHours.text = p.publicHolidayHours > 0
        ? p.publicHolidayHours.toStringAsFixed(2)
        : '';

    for (final d in p.additionalDeductions) {
      _deductions.add(_DeductionRow(
        desc: TextEditingController(text: d.description),
        amount: TextEditingController(text: d.amount.toStringAsFixed(2)),
      ));
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      _normalRate, _overtimeRate, _doubleTimeRate,
      _normalHours, _overtimeHours, _doubleHours, _publicHolidayHours
    ]) {
      c.dispose();
    }
    for (final d in _deductions) {
      d.dispose();
    }
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  double _d(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0.0;

  PayslipModel _buildPayslip(PayslipStatus status) {
    return PayslipModel(
      id: _existingPayslip?.id ?? '',
      companyId: widget.companyId,
      companyName: widget.companyName,
      employeeId: _selectedEmployee?.id ?? '',
      employeeName: _selectedEmployee?.name ?? '',
      employeeIdNumber: _selectedEmployee?.idNumber ?? '',
      uifRegNumber: '', // UIF reg is company-level, set via payrollSettings
      payPeriodStart: _periodStart,
      payPeriodEnd: _periodEnd,
      payDate: _payDate,
      normalHours: _d(_normalHours),
      overtimeHours: _d(_overtimeHours),
      doubleTimeHours: _d(_doubleHours),
      publicHolidayHours: _d(_publicHolidayHours),
      normalRate: _d(_normalRate),
      overtimeRate: _d(_overtimeRate),
      doubleTimeRate: _d(_doubleTimeRate),
      additionalDeductions: _deductions
          .where((d) => d.desc.text.trim().isNotEmpty && _d(d.amount) > 0)
          .map((d) => AdditionalDeduction(
                description: d.desc.text.trim(),
                amount: _d(d.amount),
              ))
          .toList(),
      status: status,
      createdAt: _existingPayslip?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _onEmployeeChanged(EmployeeModel emp) {
    setState(() {
      _selectedEmployee = emp;
      _normalRate.text = emp.normalHourlyRate.toStringAsFixed(2);
      _overtimeRate.text = emp.overtimeRate.toStringAsFixed(2);
      _doubleTimeRate.text = emp.doubleTimeRate.toStringAsFixed(2);
    });
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _periodStart : _periodEnd;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _periodStart = picked;
        } else {
          _periodEnd = picked;
        }
      });
    }
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

  Future<void> _submit(PayslipStatus status) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an employee')));
      return;
    }

    if (status == PayslipStatus.finalised) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Finalise Payslip'),
          content: const Text(
              'Once finalised this payslip cannot be edited. Continue?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Finalise')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _saving = true);
    final payslip = _buildPayslip(status);
    final provider = Provider.of<PayslipProvider>(context, listen: false);
    final saved = await provider.savePayslip(payslip);
    if (mounted) {
      setState(() => _saving = false);
      if (saved != null) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.error ?? 'Failed to save')));
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final provider = Provider.of<PayslipProvider>(context);
    final live = _buildPayslip(PayslipStatus.draft);
    final readOnly = _isEdit && (_existingPayslip?.isFinalised ?? false);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          readOnly
              ? 'View Payslip'
              : (_isEdit ? 'Edit Payslip' : 'New Payslip'),
          style: const TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (readOnly)
              _buildFinalBanner(),

            // ── Employee & Period ────────────────────────────────────────
            _buildSection(
              title: 'Employee & Pay Period',
              icon: Icons.person_outline,
              children: [
                _buildEmployeeDropdown(provider.employees, readOnly),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                        child: _buildDateTile(
                            'Period Start',
                            _periodStart,
                            readOnly ? null : () => _pickDate(true))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildDateTile(
                            'Period End',
                            _periodEnd,
                            readOnly ? null : () => _pickDate(false))),
                  ],
                ),
                const SizedBox(height: 14),
                _buildDateTile('Pay Date', _payDate,
                    readOnly ? null : _pickPayDate),
              ],
            ),
            const SizedBox(height: 16),

            // ── Rates ────────────────────────────────────────────────────
            _buildSection(
              title: 'Hourly Rates',
              icon: Icons.attach_money,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _numField(_normalRate, 'Normal Rate (R)',
                            readOnly: readOnly,
                            onChanged: (_) {
                              final r = _d(_normalRate);
                              if (r > 0) {
                                _overtimeRate.text =
                                    (r * 1.5).toStringAsFixed(2);
                                _doubleTimeRate.text =
                                    (r * 2.0).toStringAsFixed(2);
                              }
                            })),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _numField(_overtimeRate, 'Overtime Rate (R)',
                            readOnly: readOnly,
                            helperText: '1.5×')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _numField(_doubleTimeRate, 'Double Rate (R)',
                            readOnly: readOnly,
                            helperText: '2×')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Hours Worked ─────────────────────────────────────────────
            _buildSection(
              title: 'Hours Worked',
              icon: Icons.schedule_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _numField(_normalHours, 'Normal Hours',
                            readOnly: readOnly)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _numField(_overtimeHours, 'Overtime Hours',
                            readOnly: readOnly, required: false)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                        child: _numField(_doubleHours, 'Double Time Hours',
                            readOnly: readOnly, required: false)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _numField(
                            _publicHolidayHours, 'Public Holiday Hours',
                            readOnly: readOnly, required: false)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Earnings Summary ─────────────────────────────────────────
            _buildSection(
              title: 'Earnings Summary',
              icon: Icons.trending_up,
              children: [
                if (live.normalPay > 0)
                  _earningRow('Normal Pay',
                      '${_d(_normalHours).toStringAsFixed(1)} hrs',
                      live.normalPay),
                if (live.overtimePay > 0)
                  _earningRow('Overtime Pay',
                      '${_d(_overtimeHours).toStringAsFixed(1)} hrs',
                      live.overtimePay),
                if (live.doubleTimePay > 0)
                  _earningRow('Double Time Pay',
                      '${_d(_doubleHours).toStringAsFixed(1)} hrs',
                      live.doubleTimePay),
                if (live.publicHolidayPay > 0)
                  _earningRow('Public Holiday Pay',
                      '${_d(_publicHolidayHours).toStringAsFixed(1)} hrs',
                      live.publicHolidayPay),
                const Divider(),
                _earningRow('Total Earnings', '', live.totalEarnings,
                    bold: true),
              ],
            ),
            const SizedBox(height: 16),

            // ── Deductions ───────────────────────────────────────────────
            _buildSection(
              title: 'Deductions',
              icon: Icons.remove_circle_outline,
              children: [
                _earningRow(
                    'UIF (1% of earnings)', 'Compulsory', live.uifDeduction),
                if (_deductions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ..._deductions.asMap().entries.map((e) =>
                      _buildDeductionRow(e.key, e.value, readOnly)),
                ],
                if (!readOnly) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => setState(() => _deductions.add(
                        _DeductionRow(
                            desc: TextEditingController()
                              ..addListener(_rebuild),
                            amount: TextEditingController()
                              ..addListener(_rebuild)))),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Deduction'),
                  ),
                ],
                const Divider(),
                _earningRow('Total Deductions', '', live.totalDeductions,
                    bold: true, color: Colors.red.shade700),
              ],
            ),
            const SizedBox(height: 16),

            // ── Net Salary ───────────────────────────────────────────────
            _buildNetSalaryCard(live.netSalary, primaryColor),
            const SizedBox(height: 24),

            // ── Actions ──────────────────────────────────────────────────
            if (!readOnly)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => _submit(PayslipStatus.draft),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save Draft',
                              style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving
                          ? null
                          : () => _submit(PayslipStatus.finalised),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Finalise',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Section builder ───────────────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: primaryColor)),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  // ── Employee dropdown ─────────────────────────────────────────────────────

  Widget _buildEmployeeDropdown(
      List<EmployeeModel> employees, bool readOnly) {
    if (readOnly) {
      return _readonlyField(
          'Employee', _selectedEmployee?.name ?? '-');
    }
    return DropdownButtonFormField<EmployeeModel>(
      value: _selectedEmployee,
      decoration: InputDecoration(
        labelText: 'Employee',
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      items: employees
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e.name),
              ))
          .toList(),
      onChanged: (e) {
        if (e != null) _onEmployeeChanged(e);
      },
      validator: (v) => v == null ? 'Select an employee' : null,
      hint: employees.isEmpty
          ? const Text('No employees – add one first')
          : const Text('Select employee'),
    );
  }

  // ── Date tile ─────────────────────────────────────────────────────────────

  Widget _buildDateTile(
      String label, DateTime date, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 16,
                color: onTap != null
                    ? Theme.of(context).primaryColor
                    : Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(_dateFormat.format(date),
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Numeric field ─────────────────────────────────────────────────────────

  Widget _numField(
    TextEditingController controller,
    String label, {
    bool readOnly = false,
    bool required = true,
    String? helperText,
    void Function(String)? onChanged,
  }) {
    if (readOnly) {
      return _readonlyField(label, controller.text.isEmpty ? '0.00' : controller.text);
    }
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
      ],
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      onChanged: onChanged,
      validator: required
          ? (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (double.tryParse(v) == null) return 'Invalid number';
              return null;
            }
          : null,
    );
  }

  Widget _readonlyField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // ── Earning row ───────────────────────────────────────────────────────────

  Widget _earningRow(String label, String sub, double amount,
      {bool bold = false, Color? color}) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: style),
              if (sub.isNotEmpty)
                Text(sub,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500])),
            ],
          )),
          Text(_currency.format(amount),
              style: style.copyWith(
                  color: color ??
                      (bold ? Colors.black87 : Colors.grey[800]))),
        ],
      ),
    );
  }

  // ── Additional deduction row ──────────────────────────────────────────────

  Widget _buildDeductionRow(
      int idx, _DeductionRow row, bool readOnly) {
    if (readOnly) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(child: Text(row.desc.text)),
            Text(_currency.format(_d(row.amount))),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: row.desc,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row.amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
              ],
              decoration: InputDecoration(
                labelText: 'Amount (R)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon:
                Icon(Icons.remove_circle_outline, color: Colors.red.shade400),
            onPressed: () =>
                setState(() => _deductions.removeAt(idx)),
          ),
        ],
      ),
    );
  }

  // ── Net salary card ───────────────────────────────────────────────────────

  Widget _buildNetSalaryCard(double net, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Net Salary',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                _currency.format(net),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinalBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.green.shade700),
          const SizedBox(width: 10),
          Text('This payslip has been finalised and cannot be edited.',
              style: TextStyle(color: Colors.green.shade800)),
        ],
      ),
    );
  }
}

class _DeductionRow {
  final TextEditingController desc;
  final TextEditingController amount;
  _DeductionRow({required this.desc, required this.amount});
  void dispose() {
    desc.dispose();
    amount.dispose();
  }
}
