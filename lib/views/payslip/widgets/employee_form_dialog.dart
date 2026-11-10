import 'package:cropCompliance/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EmployeeFormDialog extends StatefulWidget {
  final String companyId;
  final EmployeeModel? employee;
  final Future<void> Function(EmployeeModel) onSave;

  const EmployeeFormDialog({
    Key? key,
    required this.companyId,
    required this.onSave,
    this.employee,
  }) : super(key: key);

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _idNumber;
  late final TextEditingController _rate;
  late final TextEditingController _jobDescription;
  late final TextEditingController _bankName;
  late final TextEditingController _accountHolder;
  late final TextEditingController _accountNumber;
  late final TextEditingController _branchCode;
  BankAccountType _accountType = BankAccountType.savings;
  /// True when "Other bank…" is picked (bank name typed manually).
  bool _customBank = false;
  DateTime? _employmentStartDate;
  EmploymentType _employmentType = EmploymentType.permanent;
  bool _saving = false;

  static final _dateFmt = DateFormat('d MMM yyyy');

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _name = TextEditingController(text: e?.name ?? '');
    _idNumber = TextEditingController(text: e?.idNumber ?? '');
    _rate = TextEditingController(
        text: e != null ? e.normalHourlyRate.toStringAsFixed(2) : '');
    _jobDescription = TextEditingController(text: e?.jobDescription ?? '');
    _employmentStartDate = e?.employmentStartDate;
    _employmentType = e?.employmentType ?? EmploymentType.permanent;
    _bankName = TextEditingController(text: e?.bankName ?? '');
    _accountHolder = TextEditingController(text: e?.accountHolderName ?? '');
    _accountNumber = TextEditingController(text: e?.accountNumber ?? '');
    _branchCode = TextEditingController(text: e?.branchCode ?? '');
    _accountType = e?.accountType ?? BankAccountType.savings;
    _customBank = _bankName.text.trim().isNotEmpty &&
        !kSaUniversalBranchCodes.containsKey(_bankName.text.trim());
  }

  @override
  void dispose() {
    _name.dispose();
    _idNumber.dispose();
    _rate.dispose();
    _jobDescription.dispose();
    _bankName.dispose();
    _accountHolder.dispose();
    _accountNumber.dispose();
    _branchCode.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _employmentStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _employmentStartDate = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final e = widget.employee;
    final employee = EmployeeModel(
      id: e?.id ?? '',
      companyId: widget.companyId,
      name: _name.text.trim(),
      idNumber: _idNumber.text.trim(),
      normalHourlyRate: double.parse(_rate.text),
      employmentStartDate: _employmentStartDate,
      employmentType: _employmentType,
      jobDescription: _jobDescription.text.trim(),
      bankName: _bankName.text.trim(),
      accountHolderName: _accountHolder.text.trim(),
      accountNumber: _accountNumber.text.replaceAll(RegExp(r'\s'), ''),
      branchCode: _branchCode.text.replaceAll(RegExp(r'\s'), ''),
      accountType: _accountType,
      createdAt: e?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await widget.onSave(employee);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        // Never grow taller than the screen — the middle section scrolls
        // instead, and the Save button stays pinned and always visible.
        constraints: BoxConstraints(maxWidth: 440, maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Fixed header ──────────────────────────────────────
                Row(
                  children: [
                    Icon(Icons.person_add_outlined, color: primaryColor),
                    const SizedBox(width: 10),
                    Text(
                      _isEdit ? 'Edit Employee' : 'Add Employee',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Scrollable form fields ────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _field(
                          controller: _name,
                          label: 'Full Name',
                          hint: 'e.g. John Smith',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _field(
                          controller: _idNumber,
                          label: 'ID Number',
                          hint: 'e.g. 9001015009087',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _field(
                          controller: _rate,
                          label: 'Normal Hourly Rate (R)',
                          hint: 'e.g. 28.79',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(v) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                          helperText: _buildRateHelper(),
                        ),
                        const SizedBox(height: 14),
                        _field(
                          controller: _jobDescription,
                          label: 'Job Description',
                          hint: 'e.g. Farm Worker, Tractor Driver',
                        ),
                        const SizedBox(height: 14),
                        // Employment type — Permanent / Seasonal
                        _employmentTypeSelector(),
                        const SizedBox(height: 14),
                        // Employment start date
                        InkWell(
                          onTap: _pickStartDate,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Employment Start Date (optional)',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _employmentStartDate != null
                                          ? _dateFmt
                                              .format(_employmentStartDate!)
                                          : 'Tap to set',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: _employmentStartDate != null
                                              ? Colors.black87
                                              : Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                if (_employmentStartDate != null)
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => _employmentStartDate = null),
                                    child: Icon(Icons.clear,
                                        size: 16,
                                        color: Colors.grey.shade500),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (_employmentStartDate != null) ...[
                          const SizedBox(height: 6),
                          _buildLeaveEligibilityHint(),
                        ],
                        const SizedBox(height: 22),
                        _bankingSection(),
                      ],
                    ),
                  ),
                ),
                // ── Pinned Save button — always visible ───────────────
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(_isEdit ? 'Save Changes' : 'Add Employee',
                            style: const TextStyle(
                                fontSize: 15, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _employmentTypeSelector() {
    Widget pill(EmploymentType type, IconData icon) {
      final selected = _employmentType == type;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _employmentType = type),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.green.shade50
                  : Colors.transparent,
              border: Border.all(
                color: selected
                    ? Colors.green.shade600
                    : Colors.grey.shade400,
                width: selected ? 1.6 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.green.shade800
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Employment Type',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Row(children: [
          pill(EmploymentType.permanent, Icons.badge_outlined),
          const SizedBox(width: 10),
          pill(EmploymentType.seasonal, Icons.event_repeat_outlined),
        ]),
      ],
    );
  }

  static const _otherBank = 'Other';

  Widget _bankingSection() {
    final known = kSaUniversalBranchCodes.containsKey(_bankName.text.trim());
    final choice = _customBank ? _otherBank : (known ? _bankName.text.trim() : null);
    final showCustomName = _customBank;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.account_balance_outlined,
              size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          const Text('Banking Details',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text('(optional)',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ]),
        const SizedBox(height: 4),
        Text(
          'Only needed if you pay staff with the Bank CSV bulk-payment '
          'file. Leave blank otherwise.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: choice,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Bank',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          items: [
            ...kSaUniversalBranchCodes.keys
                .map((b) => DropdownMenuItem(value: b, child: Text(b))),
            const DropdownMenuItem(
                value: _otherBank, child: Text('Other bank…')),
          ],
          onChanged: (v) => setState(() {
            if (v == null) return;
            if (v == _otherBank) {
              // User types the bank name and its branch code themselves.
              if (!_customBank) _bankName.clear();
              _customBank = true;
            } else {
              _customBank = false;
              _bankName.text = v;
              _branchCode.text = kSaUniversalBranchCodes[v]!;
            }
          }),
        ),
        if (showCustomName) ...[
          const SizedBox(height: 14),
          _field(
            controller: _bankName,
            label: 'Bank name',
            hint: 'e.g. Bidvest Bank',
          ),
        ],
        const SizedBox(height: 14),
        _field(
          controller: _accountHolder,
          label: 'Account holder (if not the employee)',
          hint: 'Leave blank to use the employee\'s name',
        ),
        const SizedBox(height: 14),
        _field(
          controller: _accountNumber,
          label: 'Account Number',
          keyboardType: TextInputType.number,
          validator: (v) {
            final s = (v ?? '').replaceAll(RegExp(r'\s'), '');
            if (s.isEmpty) return null; // optional
            if (!RegExp(r'^\d{6,16}$').hasMatch(s)) {
              return 'Digits only, 6–16 long';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        _field(
          controller: _branchCode,
          label: 'Branch Code',
          hint: 'Filled in automatically for major banks',
          keyboardType: TextInputType.number,
          validator: (v) {
            final s = (v ?? '').replaceAll(RegExp(r'\s'), '');
            if (s.isEmpty) return null; // optional
            if (!RegExp(r'^\d{6}$').hasMatch(s)) return 'Must be 6 digits';
            return null;
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<BankAccountType>(
          initialValue: _accountType,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Account Type',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          items: BankAccountType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: (v) =>
              setState(() => _accountType = v ?? _accountType),
        ),
      ],
    );
  }

  Widget _buildLeaveEligibilityHint() {
    final days = DateTime.now().difference(_employmentStartDate!).inDays;
    final months = (days / 30.4).floor();
    final isFL = days >= 120;
    final isSL6 = days >= 183;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Leave eligibility ($months months employed):',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800)),
          const SizedBox(height: 4),
          _eligibilityRow(
              'Family Resp. Leave (3 days/yr)', isFL, '4 months required'),
          _eligibilityRow(
              'Sick Leave (30 days/3 yr)', isSL6, '6 months required'),
        ],
      ),
    );
  }

  Widget _eligibilityRow(String label, bool eligible, String requirement) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(
            eligible ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 14,
            color: eligible ? Colors.green.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: eligible
                      ? Colors.green.shade700
                      : Colors.grey.shade500)),
          if (!eligible) ...[
            const SizedBox(width: 4),
            Text('($requirement)',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ],
        ],
      ),
    );
  }

  String? _buildRateHelper() {
    final r = double.tryParse(_rate.text);
    if (r == null || r == 0) return null;
    return 'Overtime: R ${(r * 1.5).toStringAsFixed(2)}/hr  ·  Double: R ${(r * 2).toStringAsFixed(2)}/hr';
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? helperText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: validator,
      onChanged: (_) => setState(() {}),
    );
  }
}
