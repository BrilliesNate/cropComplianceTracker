import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/models/company_model.dart';
import 'package:cropCompliance/models/employee_model.dart';
import 'package:cropCompliance/models/payslip_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/payslip_provider.dart';
import 'package:cropCompliance/views/payslip/utils/payslip_pdf_builder.dart';
import 'package:cropCompliance/views/payslip/widgets/employee_form_dialog.dart';
import 'package:cropCompliance/views/shared/app_scaffold_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ── Draft snapshot ─────────────────────────────────────────────────────────────

class _DraftDeduction {
  final String desc;
  final String amount;
  const _DraftDeduction(this.desc, this.amount);
}

class _DraftEarning {
  final String desc;
  final String amount;
  const _DraftEarning(this.desc, this.amount);
}

class _RowDraft {
  final String rate, normal, overtime, doubleTime, publicHol, sick, holiday, family;
  final String paye; // PAYE override; '' = auto
  final DateTime periodStart, periodEnd;
  final List<_DraftDeduction> deductions;
  final List<_DraftEarning> earnings;
  const _RowDraft({
    this.rate = '', this.normal = '', this.overtime = '', this.doubleTime = '',
    this.publicHol = '', this.sick = '', this.holiday = '', this.family = '',
    this.paye = '',
    required this.periodStart, required this.periodEnd,
    this.deductions = const [],
    this.earnings = const [],
  });
}

// ── Deduction entry ────────────────────────────────────────────────────────────

class _DeductionEntry {
  final TextEditingController descCtrl;
  final TextEditingController amountCtrl;

  _DeductionEntry({String desc = '', String amount = ''})
      : descCtrl = TextEditingController(text: desc),
        amountCtrl = TextEditingController(text: amount);

  double get amount => double.tryParse(amountCtrl.text) ?? 0;
  bool get isValid => descCtrl.text.trim().isNotEmpty && amount > 0;

  AdditionalDeduction toModel() =>
      AdditionalDeduction(description: descCtrl.text.trim(), amount: amount);

  void dispose() {
    descCtrl.dispose();
    amountCtrl.dispose();
  }
}

// ── Earning (addition) entry ───────────────────────────────────────────────────

class _EarningEntry {
  final TextEditingController descCtrl;
  final TextEditingController amountCtrl;

  _EarningEntry({String desc = '', String amount = ''})
      : descCtrl = TextEditingController(text: desc),
        amountCtrl = TextEditingController(text: amount);

  double get amount => double.tryParse(amountCtrl.text) ?? 0;
  bool get isValid => descCtrl.text.trim().isNotEmpty && amount > 0;

  AdditionalEarning toModel() =>
      AdditionalEarning(description: descCtrl.text.trim(), amount: amount);

  void dispose() {
    descCtrl.dispose();
    amountCtrl.dispose();
  }
}

// ── Per-employee row ───────────────────────────────────────────────────────────

class _EmployeeRow {
  final EmployeeModel employee;
  final TextEditingController rateCtrl;
  final TextEditingController normalCtrl;
  final TextEditingController overtimeCtrl;
  final TextEditingController doubleCtrl;
  final TextEditingController publicCtrl;
  final TextEditingController sickCtrl;
  final TextEditingController holidayCtrl;
  final TextEditingController familyCtrl;
  // PAYE override (tax). Empty string = auto-calculate; otherwise this value
  // is used verbatim as the PAYE deduction. Kept off the dense grid — edited in
  // the Deductions dialog — so there is still only one PAYE line on the slip.
  final TextEditingController payeCtrl;
  final FocusNode rateNode;
  final FocusNode normalNode;
  final FocusNode overtimeNode;
  final FocusNode doubleNode;
  final FocusNode publicNode;
  final FocusNode sickNode;
  final FocusNode holidayNode;
  final FocusNode familyNode;

  // Period for the "New Payslip" position
  DateTime newPeriodStart;
  DateTime newPeriodEnd;

  // Navigation: 0..n-1 = existing payslips (sorted ascending); n = "New Payslip"
  int navIndex = 0;
  bool isEditingExisting = false;
  bool generating = false;
  String? error;
  List<_DeductionEntry> deductions = [];
  List<_EarningEntry> earnings = [];

  final VoidCallback _onFocused;

  _EmployeeRow(EmployeeModel emp, DateTime start, DateTime end,
      {required VoidCallback onFocused})
      : employee = emp,
        newPeriodStart = start,
        newPeriodEnd = end,
        _onFocused = onFocused,
        rateCtrl = TextEditingController(
            text: emp.normalHourlyRate > 0
                ? emp.normalHourlyRate.toStringAsFixed(2)
                : ''),
        normalCtrl = TextEditingController(),
        overtimeCtrl = TextEditingController(),
        doubleCtrl = TextEditingController(),
        publicCtrl = TextEditingController(),
        sickCtrl = TextEditingController(),
        holidayCtrl = TextEditingController(),
        familyCtrl = TextEditingController(),
        payeCtrl = TextEditingController(),
        rateNode = FocusNode(),
        normalNode = FocusNode(),
        overtimeNode = FocusNode(),
        doubleNode = FocusNode(),
        publicNode = FocusNode(),
        sickNode = FocusNode(),
        holidayNode = FocusNode(),
        familyNode = FocusNode() {
    for (final node in [
      rateNode, normalNode, overtimeNode, doubleNode,
      publicNode, sickNode, holidayNode, familyNode
    ]) {
      node.addListener(() { if (node.hasFocus) _onFocused(); });
    }
  }

  void dispose() {
    rateCtrl.dispose(); normalCtrl.dispose(); overtimeCtrl.dispose();
    doubleCtrl.dispose(); publicCtrl.dispose(); sickCtrl.dispose();
    holidayCtrl.dispose(); familyCtrl.dispose(); payeCtrl.dispose();
    rateNode.dispose(); normalNode.dispose(); overtimeNode.dispose();
    doubleNode.dispose(); publicNode.dispose(); sickNode.dispose();
    holidayNode.dispose(); familyNode.dispose();
    for (final d in deductions) d.dispose();
    for (final e in earnings) e.dispose();
  }

  double get _rate   => double.tryParse(rateCtrl.text)     ?? 0;
  double get _normal => double.tryParse(normalCtrl.text)   ?? 0;
  double get _ot     => double.tryParse(overtimeCtrl.text) ?? 0;
  double get _dt     => double.tryParse(doubleCtrl.text)   ?? 0;
  double get _ph     => double.tryParse(publicCtrl.text)   ?? 0;
  double get _sl     => double.tryParse(sickCtrl.text)     ?? 0;
  double get _hl     => double.tryParse(holidayCtrl.text)  ?? 0;
  double get _fl     => double.tryParse(familyCtrl.text)   ?? 0;

  /// Gross that PAYE is calculated on: worked + leave pay + additional income.
  double get grossForPaye {
    final r = _rate;
    final hoursGross = _normal * r + _ot * r * 1.5 + _dt * r * 2.0 +
        _ph * r + _sl * r + _hl * r + _fl * r;
    final addIncome = earnings.fold<double>(0.0, (s, e) => s + e.amount);
    return hoursGross + addIncome;
  }

  double get liveNetPay {
    final gross = grossForPaye;
    final extra = deductions.fold<double>(0.0, (s, d) => s + d.amount);
    return gross * 0.99 - extra;
  }

  bool get hasAnyHours =>
      _normal > 0 || _ot > 0 || _dt > 0 || _ph > 0 ||
      _sl > 0 || _hl > 0 || _fl > 0 ||
      earnings.any((e) => e.amount > 0);
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class PayslipManagerScreen extends StatefulWidget {
  const PayslipManagerScreen({super.key});
  @override
  State<PayslipManagerScreen> createState() => _PayslipManagerScreenState();
}

class _PayslipManagerScreenState extends State<PayslipManagerScreen> {
  List<CompanyModel> _companies = [];
  CompanyModel? _selectedCompany;
  bool _loadingCompanies = true;
  bool _isAdminMode = false;

  DateTime _periodStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _periodEnd   = DateTime(DateTime.now().year, DateTime.now().month,
      DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month));
  DateTime _payDate = DateTime.now();

  final _uifCtrl  = TextEditingController();
  bool _editingUif = false;
  final _addressCtrl = TextEditingController();
  bool _editingAddress = false;

  List<_EmployeeRow> _rows = [];
  bool _generating = false;
  String? _focusedEmployeeId;

  final _searchCtrl = TextEditingController();
  int _page = 0;
  static const _pageSize = 20;

  static final Map<String, _RowDraft> _draftCache = {};

  static final _currency =
      NumberFormat.currency(locale: 'en_ZA', symbol: 'R ', decimalDigits: 2);
  static final _dateFmt   = DateFormat('d MMM yy');
  static final _shortDate = DateFormat('d-MMM-yyyy');

  // ── Flex column widths (shared between header and rows) ───────────────────
  static const int _fName = 22;
  static const int _fId   = 13;
  static const int _fRate = 9;
  static const int _fHour = 6;   // × 7
  static const int _fNet  = 11;
  static const int _fNav  = 27;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _page = 0));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCompanies());
  }

  @override
  void dispose() {
    _saveDrafts();
    _uifCtrl.dispose();
    _addressCtrl.dispose();
    _searchCtrl.dispose();
    for (final r in _rows) r.dispose();
    super.dispose();
  }

  // ── Draft helpers ──────────────────────────────────────────────────────────

  void _saveDrafts() {
    if (_selectedCompany == null) return;
    for (final row in _rows) {
      _draftCache['${_selectedCompany!.id}/${row.employee.id}'] = _RowDraft(
        rate: row.rateCtrl.text, normal: row.normalCtrl.text,
        overtime: row.overtimeCtrl.text, doubleTime: row.doubleCtrl.text,
        publicHol: row.publicCtrl.text, sick: row.sickCtrl.text,
        holiday: row.holidayCtrl.text, family: row.familyCtrl.text,
        paye: row.payeCtrl.text,
        periodStart: row.newPeriodStart, periodEnd: row.newPeriodEnd,
        deductions: row.deductions
            .map((d) => _DraftDeduction(d.descCtrl.text, d.amountCtrl.text))
            .toList(),
        earnings: row.earnings
            .map((e) => _DraftEarning(e.descCtrl.text, e.amountCtrl.text))
            .toList(),
      );
    }
  }

  // ── Nav helpers ────────────────────────────────────────────────────────────

  List<PayslipModel> _getEmployeePayslips(_EmployeeRow row, PayslipProvider p) {
    final list = p.payslips.where((ps) => ps.employeeId == row.employee.id).toList();
    list.sort((a, b) => a.payPeriodStart.compareTo(b.payPeriodStart));
    return list;
  }

  /// The pay period the row currently represents — the existing payslip being
  /// viewed/edited, or the "New Payslip" period. Used to make PAYE
  /// frequency-aware (weekly vs monthly).
  ({DateTime start, DateTime end}) _rowPeriod(_EmployeeRow row) {
    final prov = Provider.of<PayslipProvider>(context, listen: false);
    final list = _getEmployeePayslips(row, prov);
    if (row.navIndex >= list.length) {
      return (start: row.newPeriodStart, end: row.newPeriodEnd);
    }
    final ex = list[row.navIndex];
    return (start: ex.payPeriodStart, end: ex.payPeriodEnd);
  }

  void _fillRowFromPayslip(_EmployeeRow row, PayslipModel p) {
    row.rateCtrl.text        = p.normalRate > 0          ? p.normalRate.toStringAsFixed(2)          : '';
    row.normalCtrl.text      = p.normalHours > 0         ? p.normalHours.toStringAsFixed(2)         : '';
    row.overtimeCtrl.text    = p.overtimeHours > 0       ? p.overtimeHours.toStringAsFixed(2)       : '';
    row.doubleCtrl.text      = p.doubleTimeHours > 0     ? p.doubleTimeHours.toStringAsFixed(2)     : '';
    row.publicCtrl.text      = p.publicHolidayHours > 0  ? p.publicHolidayHours.toStringAsFixed(2)  : '';
    row.sickCtrl.text        = p.sickLeaveHours > 0      ? p.sickLeaveHours.toStringAsFixed(2)      : '';
    row.holidayCtrl.text     = p.holidayLeaveHours > 0   ? p.holidayLeaveHours.toStringAsFixed(2)   : '';
    row.familyCtrl.text      = p.familyLeaveHours > 0    ? p.familyLeaveHours.toStringAsFixed(2)    : '';
    // Only surface a PAYE override if this slip was manually overridden;
    // otherwise leave blank so it re-derives (frequency-aware) on save.
    row.payeCtrl.text = p.payeAutoCalculated
        ? ''
        : p.payeDeduction.toStringAsFixed(2);
    for (final d in row.deductions) d.dispose();
    row.deductions = p.additionalDeductions
        .map((d) => _DeductionEntry(
            desc: d.description, amount: d.amount.toStringAsFixed(2)))
        .toList();
    for (final e in row.earnings) e.dispose();
    row.earnings = p.additionalEarnings
        .map((e) => _EarningEntry(
            desc: e.description, amount: e.amount.toStringAsFixed(2)))
        .toList();
  }

  void _clearRowForNew(_EmployeeRow row, List<PayslipModel> sorted) {
    row.normalCtrl.text   = '';
    row.overtimeCtrl.text = '';
    row.doubleCtrl.text   = '';
    row.publicCtrl.text   = '';
    row.sickCtrl.text     = '';
    row.holidayCtrl.text  = '';
    row.familyCtrl.text   = '';
    row.payeCtrl.text     = '';
    if (sorted.isNotEmpty && sorted.last.normalRate > 0) {
      row.rateCtrl.text = sorted.last.normalRate.toStringAsFixed(2);
    }
    for (final d in row.deductions) d.dispose();
    row.deductions = [];
    for (final e in row.earnings) e.dispose();
    row.earnings = [];
    row.newPeriodStart = _periodStart;
    row.newPeriodEnd   = _periodEnd;
  }

  void _navLeft(_EmployeeRow row, PayslipProvider prov) {
    final list = _getEmployeePayslips(row, prov);
    if (row.navIndex <= 0) return;
    setState(() {
      row.navIndex--;
      row.isEditingExisting = false;
      _fillRowFromPayslip(row, list[row.navIndex]);
      row.error = null;
    });
  }

  void _navRight(_EmployeeRow row, PayslipProvider prov) {
    final list = _getEmployeePayslips(row, prov);
    if (row.navIndex >= list.length) return; // already at "new"
    setState(() {
      row.navIndex++;
      row.isEditingExisting = false;
      if (row.navIndex < list.length) {
        _fillRowFromPayslip(row, list[row.navIndex]);
      } else {
        _clearRowForNew(row, list);
      }
      row.error = null;
    });
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadCompanies() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final prov = Provider.of<PayslipProvider>(context, listen: false);
    _isAdminMode = auth.isAdmin;
    try {
      // For everyone except an admin who hasn't picked a farm, the company to
      // show first is already known — so its payroll data starts loading right
      // now, alongside the company list, rather than after it.
      final known = auth.isAdmin
          ? (auth.isManagingCompany ? auth.selectedCompany : null)
          : auth.effectiveCompany;
      final Future<void>? earlyLoad =
          known != null ? prov.loadForCompany(known.id) : null;

      List<CompanyModel> companies = [];
      if (auth.isAdmin) {
        final snap = await FirebaseFirestore.instance
            .collection('companies').orderBy('name').get();
        companies = snap.docs
            .map((d) => CompanyModel.fromMap(d.data(), d.id)).toList();
      } else if (known != null) {
        companies = [known];
      }

      CompanyModel? pre;
      if (auth.isAdmin && auth.isManagingCompany) {
        pre = companies.firstWhere(
            (c) => c.id == auth.selectedCompany!.id,
            orElse: () => companies.first);
      } else if (companies.isNotEmpty) {
        pre = companies.first;
      }

      if (pre != null) {
        // Wait for the data BEFORE revealing the screen, so it opens finished.
        await (known != null && known.id == pre.id
            ? earlyLoad!
            : prov.loadForCompany(pre.id));
      }

      if (mounted) {
        setState(() {
          _companies = companies;
          _selectedCompany = pre;
          _loadingCompanies = false;
        });
        if (pre != null) _applyCompanyData(prov);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCompanies = false);
    }
  }

  Future<void> _loadForCompany(String id) async {
    final prov = Provider.of<PayslipProvider>(context, listen: false);
    await prov.loadForCompany(id);
    if (!mounted) return;
    _applyCompanyData(prov);
  }

  void _applyCompanyData(PayslipProvider prov) {
    _rebuildRows(prov);
    _uifCtrl.text = prov.payrollSettings?.uifRegNumber ?? '';
    // Fallback to CompanyModel.address if no payroll-specific address is set.
    _addressCtrl.text = prov.payrollSettings?.companyAddress.isNotEmpty == true
        ? prov.payrollSettings!.companyAddress
        : (_selectedCompany?.address ?? '');
  }

  void _rebuildRows(PayslipProvider prov) {
    _saveDrafts();
    for (final r in _rows) r.dispose();
    setState(() {
      _rows = prov.employees.map((e) {
        final row = _EmployeeRow(e, _periodStart, _periodEnd, onFocused: () {
          if (_focusedEmployeeId != e.id) setState(() => _focusedEmployeeId = e.id);
        });

        final sorted = prov.payslips
            .where((p) => p.employeeId == e.id)
            .toList()
          ..sort((a, b) => a.payPeriodStart.compareTo(b.payPeriodStart));

        // Start at "New Payslip" position
        row.navIndex = sorted.length;

        final key  = _selectedCompany != null ? '${_selectedCompany!.id}/${e.id}' : null;
        final draft = key != null ? _draftCache[key] : null;

        if (draft != null) {
          row.rateCtrl.text     = draft.rate;
          row.normalCtrl.text   = draft.normal;
          row.overtimeCtrl.text = draft.overtime;
          row.doubleCtrl.text   = draft.doubleTime;
          row.publicCtrl.text   = draft.publicHol;
          row.sickCtrl.text     = draft.sick;
          row.holidayCtrl.text  = draft.holiday;
          row.familyCtrl.text   = draft.family;
          row.payeCtrl.text     = draft.paye;
          row.newPeriodStart    = draft.periodStart;
          row.newPeriodEnd      = draft.periodEnd;
          row.deductions = draft.deductions
              .map((d) => _DeductionEntry(desc: d.desc, amount: d.amount)).toList();
          row.earnings = draft.earnings
              .map((e) => _EarningEntry(desc: e.desc, amount: e.amount)).toList();
        } else if (sorted.isNotEmpty && sorted.last.normalRate > 0) {
          row.rateCtrl.text = sorted.last.normalRate.toStringAsFixed(2);
        }

        return row;
      }).toList();
      _page = 0;
    });
  }

  void _applyGlobalDates() {
    for (final r in _rows) {
      r.newPeriodStart = _periodStart;
      r.newPeriodEnd   = _periodEnd;
      r.isEditingExisting = false;
    }
  }

  Future<void> _selectCompany(CompanyModel c) async {
    setState(() { _selectedCompany = c; _searchCtrl.clear(); _editingUif = false; });
    await _loadForCompany(c.id);
  }

  // ── Filter ─────────────────────────────────────────────────────────────────

  List<_EmployeeRow> get _filtered {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _rows;
    return _rows.where((r) =>
        r.employee.name.toLowerCase().contains(q) ||
        r.employee.idNumber.toLowerCase().contains(q)).toList();
  }

  // ── Date picker ────────────────────────────────────────────────────────────

  Future<void> _pickDate(DateTime current, void Function(DateTime) onPicked) async {
    final d = await showDatePicker(context: context, initialDate: current,
        firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (d != null) onPicked(d);
  }

  // ── UIF ─────────────────────────────────────────────────────────────────────

  Future<void> _saveUif() async {
    final p = Provider.of<PayslipProvider>(context, listen: false);
    await p.savePayrollSettings(PayrollSettings(
      companyId: _selectedCompany!.id,
      uifRegNumber: _uifCtrl.text.trim(),
      companyAddress: _addressCtrl.text.trim(),
    ));
    setState(() => _editingUif = false);
  }

  Future<void> _saveAddress() async {
    final p = Provider.of<PayslipProvider>(context, listen: false);
    await p.savePayrollSettings(PayrollSettings(
      companyId: _selectedCompany!.id,
      uifRegNumber: _uifCtrl.text.trim(),
      companyAddress: _addressCtrl.text.trim(),
    ));
    setState(() => _editingAddress = false);
  }

  // ── Save payslips ──────────────────────────────────────────────────────────

  Future<void> _saveAll() async {
    final prov = Provider.of<PayslipProvider>(context, listen: false);

    final toSave = <_EmployeeRow>[];
    for (final row in _rows) {
      if (!row.hasAnyHours) continue;
      final list = _getEmployeePayslips(row, prov);
      final isNew = row.navIndex >= list.length;
      if (isNew || row.isEditingExisting) toSave.add(row);
    }

    if (toSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter hours for at least one employee first.')));
      return;
    }

    final uif = _uifCtrl.text.trim();
    final addr = _addressCtrl.text.trim();
    final settingsChanged =
        uif != (prov.payrollSettings?.uifRegNumber ?? '') ||
            addr != (prov.payrollSettings?.companyAddress ?? '');
    if (settingsChanged) {
      await prov.savePayrollSettings(PayrollSettings(
        companyId: _selectedCompany!.id,
        uifRegNumber: uif,
        companyAddress: addr,
      ));
    }

    setState(() => _generating = true);
    int ok = 0, fail = 0;

    for (final row in toSave) {
      setState(() => row.generating = true);
      try {
        final list   = _getEmployeePayslips(row, prov);
        final isNew  = row.navIndex >= list.length;
        DateTime pStart, pEnd;
        if (isNew) {
          pStart = row.newPeriodStart;
          pEnd   = row.newPeriodEnd;
        } else {
          final ex = list[row.navIndex];
          await prov.deletePayslip(ex.id);
          pStart = ex.payPeriodStart;
          pEnd   = ex.payPeriodEnd;
        }

        final rate = double.tryParse(row.rateCtrl.text)     ?? 0;
        final nh   = double.tryParse(row.normalCtrl.text)   ?? 0;
        final oth  = double.tryParse(row.overtimeCtrl.text) ?? 0;
        final dth  = double.tryParse(row.doubleCtrl.text)   ?? 0;
        final ph   = double.tryParse(row.publicCtrl.text)   ?? 0;
        final sl   = double.tryParse(row.sickCtrl.text)     ?? 0;
        final hl   = double.tryParse(row.holidayCtrl.text)  ?? 0;
        final fl   = double.tryParse(row.familyCtrl.text)   ?? 0;
        final gross = nh * rate + oth * rate * 1.5 + dth * rate * 2.0 +
            ph * rate + sl * rate + hl * rate + fl * rate;

        // PAYE: frequency-aware auto value on the taxable gross, unless the
        // user typed an override in the Deductions dialog.
        final taxableGross = gross +
            row.earnings
                .where((e) => e.isValid)
                .fold<double>(0.0, (s, e) => s + e.amount);
        final payeOverride = double.tryParse(row.payeCtrl.text.trim());
        final payeValue = payeOverride ??
            PayslipModel.calculatePayeForPeriod(taxableGross, pStart, pEnd);

        final ps = PayslipModel(
          id: '', companyId: _selectedCompany!.id,
          companyName: _selectedCompany!.name,
          companyAddress: addr.isNotEmpty ? addr : _selectedCompany!.address,
          employeeId: row.employee.id, employeeName: row.employee.name,
          employeeIdNumber: row.employee.idNumber,
          employmentType: row.employee.employmentType,
          jobDescription: row.employee.jobDescription,
          uifRegNumber: uif,
          payPeriodStart: pStart, payPeriodEnd: pEnd, payDate: _payDate,
          normalHours: nh, overtimeHours: oth, doubleTimeHours: dth,
          publicHolidayHours: ph, sickLeaveHours: sl,
          holidayLeaveHours: hl, familyLeaveHours: fl,
          normalRate: rate, overtimeRate: rate * 1.5, doubleTimeRate: rate * 2.0,
          additionalDeductions: row.deductions
              .where((d) => d.isValid).map((d) => d.toModel()).toList(),
          additionalEarnings: row.earnings
              .where((e) => e.isValid).map((e) => e.toModel()).toList(),
          payeDeduction: payeValue,
          payeAutoCalculated: payeOverride == null,
          status: PayslipStatus.finalised,
          createdAt: DateTime.now(), updatedAt: DateTime.now(),
        );

        final saved = await prov.savePayslip(ps);
        if (saved != null) {
          ok++;
          _draftCache.remove('${_selectedCompany!.id}/${row.employee.id}');
          final newList = _getEmployeePayslips(row, prov);
          final idx = newList.indexWhere((p) => p.id == saved.id);
          setState(() {
            row.navIndex = idx >= 0 ? idx : max(0, newList.length - 1);
            row.isEditingExisting = false;
            row.generating = false;
            row.error = null;
          });
        } else {
          fail++;
          setState(() { row.generating = false; row.error = 'Save failed'; });
        }
      } catch (e) {
        fail++;
        setState(() { row.generating = false; row.error = e.toString(); });
      }
    }

    setState(() => _generating = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(fail == 0
            ? '$ok payslip${ok == 1 ? '' : 's'} saved'
            : '$ok saved, $fail failed'),
        backgroundColor: fail == 0 ? Colors.green.shade700 : Colors.grey.shade800,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  // ── Delete payslip ─────────────────────────────────────────────────────────

  Future<void> _deletePayslip(PayslipModel p, PayslipProvider prov, _EmployeeRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Payslip'),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.employeeName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Text('${_shortDate.format(p.payPeriodStart)} – ${_shortDate.format(p.payPeriodEnd)}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text('Net: ${_currency.format(p.netSalary)}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 10),
          const Text('This cannot be undone.',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.black87),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await prov.deletePayslip(p.id);
      final newList = _getEmployeePayslips(row, prov);
      setState(() {
        row.navIndex = newList.length; // go to "new" position
        row.isEditingExisting = false;
        row.error = null;
        _clearRowForNew(row, newList);
      });
    }
  }

  // ── Employee CRUD ──────────────────────────────────────────────────────────

  void _showEmployeeDialog({EmployeeModel? employee}) {
    if (_selectedCompany == null) return;
    showDialog(
      context: context,
      builder: (_) => EmployeeFormDialog(
        companyId: _selectedCompany!.id, employee: employee,
        onSave: (emp) async {
          final prov = Provider.of<PayslipProvider>(context, listen: false);
          final ok = await prov.saveEmployee(emp);
          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok
                ? (employee == null ? 'Employee added' : 'Employee updated')
                : 'Error: ${prov.error ?? 'Could not save'}'),
            backgroundColor: ok ? Colors.green.shade700 : Colors.grey.shade800,
          ));
          if (ok) _rebuildRows(prov);
        },
      ),
    );
  }

  Future<void> _removeEmployee(_EmployeeRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Employee'),
        content: Text('Remove ${row.employee.name}? Payslips are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove',
                style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final prov = Provider.of<PayslipProvider>(context, listen: false);
      await prov.deleteEmployee(row.employee.id);
      _rebuildRows(prov);
    }
  }

  // ── Download ───────────────────────────────────────────────────────────────

  Future<void> _downloadAll(PayslipProvider prov) async {
    // Download whatever payslip each row is currently viewing
    final list = <PayslipModel>[];
    for (final row in _rows) {
      final payslips = _getEmployeePayslips(row, prov);
      if (row.navIndex < payslips.length) {
        list.add(payslips[row.navIndex]);
      }
    }
    if (list.isEmpty) return;
    await PayslipPdfBuilder.downloadAllAsSinglePdf(
      list,
      '${_selectedCompany?.name ?? 'Company'} Payslips.pdf',
    );
  }

  // ── Deductions dialog ──────────────────────────────────────────────────────

  // PAYE (tax) override — pinned at the top of the Deductions dialog. Shows the
  // frequency-aware auto value; typing a number overrides it. This keeps a
  // single PAYE line on the payslip (no more manual "PAYE" deduction workaround).
  Widget _buildPayeOverrideField(
      BuildContext ctx, _EmployeeRow row, void Function(void Function()) set) {
    final period = _rowPeriod(row);
    final periods = PayslipModel.payPeriodsPerYear(period.start, period.end);
    final freqLabel = periods == 52
        ? 'weekly'
        : periods == 26
            ? 'fortnightly'
            : 'monthly';
    final auto = PayslipModel.calculatePayeForPeriod(
        row.grossForPaye, period.start, period.end);
    final overridden = row.payeCtrl.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.account_balance_outlined, size: 16),
          const SizedBox(width: 8),
          const Text('PAYE (Tax)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('Auto ($freqLabel): ${_currency.format(auto)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: row.payeCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                labelText: 'PAYE amount (R)',
                labelStyle: const TextStyle(fontSize: 12),
                hintText: 'Leave blank to use auto',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              onChanged: (_) => set(() {}),
            ),
          ),
          if (overridden) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                row.payeCtrl.clear();
                set(() {});
              },
              child: const Text('Use auto', style: TextStyle(fontSize: 12)),
            ),
          ],
        ]),
        const SizedBox(height: 4),
        Text(
          overridden
              ? 'Manual PAYE — this exact amount will be used.'
              : 'Auto PAYE is calculated on the taxable gross for this $freqLabel period.',
          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
        ),
      ]),
    );
  }

  void _showDeductionsDialog(_EmployeeRow row) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
                child: Row(children: [
                  const Icon(Icons.remove_circle_outline, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(row.employee.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Additional Deductions',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ])),
                  IconButton(onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close)),
                ]),
              ),
              const Divider(height: 20),
              _buildPayeOverrideField(ctx, row, set),
              const Divider(height: 20),
              Expanded(
                child: row.deductions.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.remove_circle_outline,
                            size: 40, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text('No deductions yet',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ]))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: row.deductions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final e = row.deductions[i];
                          return Row(children: [
                            Expanded(flex: 5, child: TextField(
                              controller: e.descCtrl,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Reason',
                                labelStyle: const TextStyle(fontSize: 12),
                                isDense: true,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                              ),
                              onChanged: (_) => set(() {}),
                            )),
                            const SizedBox(width: 8),
                            Expanded(flex: 3, child: TextField(
                              controller: e.amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Amount (R)',
                                labelStyle: const TextStyle(fontSize: 12),
                                isDense: true,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                              ),
                              onChanged: (_) => set(() {}),
                            )),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () {
                                row.deductions[i].dispose();
                                set(() => row.deductions.removeAt(i));
                              },
                              icon: Icon(Icons.delete_outline,
                                  size: 18, color: Colors.grey.shade500),
                              visualDensity: VisualDensity.compact,
                            ),
                          ]);
                        },
                      ),
              ),
              if (row.deductions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total: ${_currency.format(row.deductions.fold<double>(0, (s, d) => s + d.amount))}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(children: [
                  OutlinedButton.icon(
                    onPressed: () => set(() => row.deductions.add(_DeductionEntry())),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Deduction',
                        style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () { setState(() {}); Navigator.pop(ctx); },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black87,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Done'),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Additions (extra income) dialog ───────────────────────────────────────

  void _showEarningsDialog(_EmployeeRow row) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
                child: Row(children: [
                  const Icon(Icons.add_circle_outline, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(row.employee.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Additional Income',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ])),
                  IconButton(onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close)),
                ]),
              ),
              const Divider(height: 20),
              Expanded(
                child: row.earnings.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.add_circle_outline,
                            size: 40, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text('No additions yet',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ]))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: row.earnings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final e = row.earnings[i];
                          return Row(children: [
                            Expanded(flex: 5, child: TextField(
                              controller: e.descCtrl,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Description',
                                labelStyle: const TextStyle(fontSize: 12),
                                isDense: true,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                              ),
                              onChanged: (_) => set(() {}),
                            )),
                            const SizedBox(width: 8),
                            Expanded(flex: 3, child: TextField(
                              controller: e.amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Amount (R)',
                                labelStyle: const TextStyle(fontSize: 12),
                                isDense: true,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                              ),
                              onChanged: (_) => set(() {}),
                            )),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () {
                                row.earnings[i].dispose();
                                set(() => row.earnings.removeAt(i));
                              },
                              icon: Icon(Icons.delete_outline,
                                  size: 18, color: Colors.grey.shade500),
                              visualDensity: VisualDensity.compact,
                            ),
                          ]);
                        },
                      ),
              ),
              if (row.earnings.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total: ${_currency.format(row.earnings.fold<double>(0, (s, e) => s + e.amount))}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(children: [
                  OutlinedButton.icon(
                    onPressed: () => set(() => row.earnings.add(_EarningEntry())),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Income',
                        style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () { setState(() {}); Navigator.pop(ctx); },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black87,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Done'),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── UIF summary ────────────────────────────────────────────────────────────

  void _showUifSummary() {
    final prov = Provider.of<PayslipProvider>(context, listen: false);
    final list = prov.payslips.where((p) =>
        !p.payPeriodEnd.isBefore(_periodStart) &&
        !p.payPeriodStart.isAfter(_periodEnd)).toList();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 540),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
              child: Row(children: [
                const Icon(Icons.summarize_outlined, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('UIF Summary',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${_shortDate.format(_periodStart)} – ${_shortDate.format(_periodEnd)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ])),
                IconButton(onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close)),
              ]),
            ),
            const Divider(height: 20),
            if (list.isEmpty)
              const Expanded(child: Center(
                  child: Text('No payslips for this period.',
                      style: TextStyle(color: Colors.grey))))
            else
              Expanded(child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildUifTable(ctx, list))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: list.isEmpty ? null : () async {
                    try {
                      await PayslipPdfBuilder.downloadUifSummary(
                        companyName: _selectedCompany?.name ?? 'Company',
                        uifRegNumber: _uifCtrl.text.trim(),
                        periodStart: _periodStart,
                        periodEnd: _periodEnd,
                        payslips: list,
                      );
                    } catch (e) {
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('PDF error: $e'),
                              backgroundColor: Colors.grey.shade800));
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.download_outlined,
                      color: Colors.white, size: 18),
                  label: const Text('Download UIF Summary PDF',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildUifTable(BuildContext ctx, List<PayslipModel> payslips) {
    // FIXED: sum totals per employee for the entire period — previously
    // this only kept the *latest* payslip per employee, which under-reported
    // multi-payslip months.
    final earningsByEmp = <String, double>{};
    final uifByEmp = <String, double>{};
    final payeByEmp = <String, double>{};
    final otherByEmp = <String, double>{};
    final nameByEmp = <String, String>{};
    for (final p in payslips) {
      earningsByEmp.update(
          p.employeeId, (v) => v + p.totalEarnings,
          ifAbsent: () => p.totalEarnings);
      uifByEmp.update(
          p.employeeId, (v) => v + p.uifDeduction,
          ifAbsent: () => p.uifDeduction);
      payeByEmp.update(
          p.employeeId, (v) => v + p.payeDeduction,
          ifAbsent: () => p.payeDeduction);
      otherByEmp.update(
          p.employeeId, (v) => v + p.additionalDeductionsTotal,
          ifAbsent: () => p.additionalDeductionsTotal);
      nameByEmp[p.employeeId] = p.employeeName;
    }
    double totalDed(String id) =>
        payeByEmp[id]! + uifByEmp[id]! + otherByEmp[id]!;
    final empIds = nameByEmp.keys.toList()
      ..sort((a, b) => nameByEmp[a]!.compareTo(nameByEmp[b]!));
    final totalE = earningsByEmp.values.fold<double>(0, (s, v) => s + v);
    final totalU = uifByEmp.values.fold<double>(0, (s, v) => s + v);
    final totalP = payeByEmp.values.fold<double>(0, (s, v) => s + v);
    final totalD = empIds.fold<double>(0, (s, id) => s + totalDed(id));
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3), 1: FlexColumnWidth(2),
        2: FlexColumnWidth(2), 3: FlexColumnWidth(2), 4: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            _tHdr('Employee', TextAlign.left),
            _tHdr('Earnings', TextAlign.right),
            _tHdr('PAYE', TextAlign.right),
            _tHdr('UIF', TextAlign.right),
            _tHdr('Total Ded', TextAlign.right),
          ],
        ),
        ...empIds.map((id) => TableRow(children: [
          _tCell(nameByEmp[id]!, TextAlign.left),
          _tCell(_currency.format(earningsByEmp[id]!), TextAlign.right),
          _tCell(_currency.format(payeByEmp[id]!), TextAlign.right),
          _tCell(_currency.format(uifByEmp[id]!), TextAlign.right),
          _tCell(_currency.format(totalDed(id)), TextAlign.right),
        ])),
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: [
            _tCell('TOTAL', TextAlign.left, bold: true),
            _tCell(_currency.format(totalE), TextAlign.right, bold: true),
            _tCell(_currency.format(totalP), TextAlign.right, bold: true),
            _tCell(_currency.format(totalU), TextAlign.right, bold: true),
            _tCell(_currency.format(totalD), TextAlign.right, bold: true),
          ],
        ),
      ],
    );
  }

  Widget _tHdr(String t, TextAlign a) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Text(t, textAlign: a,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)));

  Widget _tCell(String t, TextAlign a, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: Text(t, textAlign: a,
          style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal)));

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // One loading indicator until the company and its payroll data are ready,
    // so the screen never flashes "no company" or an empty table first.
    if (_loadingCompanies) {
      return const AppScaffoldWrapper(
        title: 'Payslip Manager',
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return AppScaffoldWrapper(
      title: 'Payslip Manager',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isAdminMode) _buildCompanyBar(),
          if (_selectedCompany != null) ...[
            _buildPeriodBar(),
            Consumer<PayslipProvider>(
                builder: (_, prov, __) => _buildActionBar(prov)),
          ],
          Expanded(
            child: _selectedCompany == null
                ? _buildNoCompany()
                : Consumer<PayslipProvider>(
                    builder: (_, prov, __) {
                      if (prov.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (prov.error != null) return _buildError(prov);
                      return _buildTable(prov);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Company bar ────────────────────────────────────────────────────────────

  Widget _buildCompanyBar() {
    if (_loadingCompanies) return const LinearProgressIndicator();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(children: [
        const Icon(Icons.business_outlined, size: 18, color: Colors.black87),
        const SizedBox(width: 10),
        const Text('Company:',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CompanyModel>(
              value: _selectedCompany,
              hint: const Text('Select a company',
                  style: TextStyle(fontSize: 13)),
              isExpanded: true,
              items: _companies.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13)),
              )).toList(),
              onChanged: (c) { if (c != null) _selectCompany(c); },
            ),
          ),
        ),
      ]),
    );
  }

  // ── Period bar ─────────────────────────────────────────────────────────────

  Widget _buildPeriodBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Wrap(
          spacing: 12, runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _datePill('Default Start', _periodStart, subtitle: 'fills all rows',
                onTap: () => _pickDate(_periodStart, (d) =>
                    setState(() { _periodStart = d; _applyGlobalDates(); }))),
            _datePill('Default End', _periodEnd, subtitle: 'fills all rows',
                onTap: () => _pickDate(_periodEnd, (d) =>
                    setState(() { _periodEnd = d; _applyGlobalDates(); }))),
            _datePill('Pay Date', _payDate,
                onTap: () => _pickDate(_payDate,
                    (d) => setState(() => _payDate = d))),
            _buildUifField(),
            _buildAddressField(),
          ]),
    );
  }

  Widget _buildAddressField() {
    if (_editingAddress) {
      return SizedBox(
        width: 320, height: 38,
        child: Row(children: [
          Expanded(child: TextField(
            controller: _addressCtrl, autofocus: true,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Company Address (on payslip)', isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 9),
            ),
            onSubmitted: (_) => _saveAddress(),
          )),
          IconButton(
              icon: const Icon(Icons.check, color: Colors.black87, size: 18),
              onPressed: _saveAddress),
        ]),
      );
    }
    return InkWell(
      onTap: () => setState(() => _editingAddress = true),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.place_outlined, size: 13, color: Colors.black87),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Company Address',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade500)),
                Text(
                  _addressCtrl.text.isEmpty ? 'Tap to set' : _addressCtrl.text,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _addressCtrl.text.isEmpty
                          ? Colors.grey.shade400
                          : Colors.black87),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.edit, size: 12, color: Colors.grey.shade400),
        ]),
      ),
    );
  }

  Widget _datePill(String label, DateTime date,
      {VoidCallback? onTap, String? subtitle}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_today, size: 13, color: Colors.black87),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              if (subtitle != null) ...[
                const SizedBox(width: 4),
                Text('($subtitle)',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
              ],
            ]),
            Text(_dateFmt.format(date),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildUifField() {
    if (_editingUif) {
      return SizedBox(
        width: 220, height: 38,
        child: Row(children: [
          Expanded(child: TextField(
            controller: _uifCtrl, autofocus: true,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Employer UIF Reg Nr', isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 9),
            ),
            onSubmitted: (_) => _saveUif(),
          )),
          IconButton(
              icon: const Icon(Icons.check, color: Colors.black87, size: 18),
              onPressed: _saveUif),
        ]),
      );
    }
    return InkWell(
      onTap: () => setState(() => _editingUif = true),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.badge_outlined, size: 13, color: Colors.black87),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Employer UIF Reg Nr',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            Text(_uifCtrl.text.isEmpty ? 'Tap to set' : _uifCtrl.text,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: _uifCtrl.text.isEmpty
                        ? Colors.grey.shade400
                        : Colors.black87)),
          ]),
          const SizedBox(width: 6),
          Icon(Icons.edit, size: 12, color: Colors.grey.shade400),
        ]),
      ),
    );
  }

  // ── Action bar ─────────────────────────────────────────────────────────────

  Widget _buildActionBar(PayslipProvider prov) {
    int newCount = 0, editCount = 0;
    for (final row in _rows) {
      if (!row.hasAnyHours) continue;
      final list = _getEmployeePayslips(row, prov);
      if (row.navIndex >= list.length) {
        newCount++;
      } else if (row.isEditingExisting) {
        editCount++;
      }
    }
    final total = newCount + editCount;

    String label;
    if (_generating) {
      label = 'Saving…';
    } else if (editCount > 0 && newCount == 0) {
      label = 'Save Changes ($editCount)';
    } else if (editCount > 0) {
      label = 'Save All ($total)';
    } else if (newCount > 0) {
      label = 'Save Payslips ($newCount)';
    } else {
      label = 'Save Payslips';
    }

    final hasAny = prov.payslips.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
            top: BorderSide(color: Colors.grey.shade200),
            bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(children: [
        SizedBox(width: 260, child: _searchBox()),
        const Spacer(),
        _barBtn(Icons.person_add_outlined, 'Add Employee',
            onTap: _showEmployeeDialog),
        const SizedBox(width: 8),
        _barBtn(Icons.event_note_outlined, 'Leave Records',
            onTap: () => Navigator.of(context).pushNamed(
                RouteConstants.leaveManagement,
                arguments: {
                  'companyId': _selectedCompany?.id ?? '',
                  'companyName': _selectedCompany?.name ?? ''
                })),
        const SizedBox(width: 8),
        _barBtn(Icons.receipt_long_outlined, 'Payslip Records',
            onTap: () => Navigator.of(context).pushNamed(
                RouteConstants.payslipRecords,
                arguments: {
                  'companyId': _selectedCompany?.id ?? '',
                  'companyName': _selectedCompany?.name ?? ''
                })),
        const SizedBox(width: 8),
        _barBtn(Icons.summarize_outlined, 'UIF Summary',
            onTap: _showUifSummary),
        if (hasAny) ...[
          const SizedBox(width: 8),
          _barBtn(Icons.download_outlined, 'Download',
              onTap: () => _downloadAll(prov)),
        ],
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: (_generating || total == 0) ? null : _saveAll,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            disabledBackgroundColor: Colors.grey.shade300,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          icon: _generating
              ? const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save_outlined, size: 18, color: Colors.white),
          label: Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.white)),
        ),
      ]),
    );
  }

  Widget _barBtn(IconData icon, String label, {required VoidCallback onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      icon: Icon(icon, size: 16, color: Colors.black87),
      label: Text(label,
          style: const TextStyle(fontSize: 13, color: Colors.black87)),
    );
  }

  // ── Table ──────────────────────────────────────────────────────────────────

  Widget _buildTable(PayslipProvider prov) {
    final filtered = _filtered;
    final totalPages = max(1, (filtered.length / _pageSize).ceil());
    final page = _page.clamp(0, totalPages - 1);
    final paged = filtered.skip(page * _pageSize).take(_pageSize).toList();

    return Column(children: [
      _buildHeader(),
      Expanded(
        child: paged.isEmpty
            ? _buildEmpty(Icons.people_outline, 'No employees found')
            : ListView.builder(
                itemCount: paged.length,
                itemBuilder: (_, i) => _buildRow(paged[i], i, prov),
              ),
      ),
      _buildPagination(total: filtered.length, page: page),
    ]);
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 40,
        child: Row(children: [
          Expanded(flex: _fName, child: _hdr('Employee',    TextAlign.left)),
          Expanded(flex: _fId,   child: _hdr('ID Number',  TextAlign.left)),
          Expanded(flex: _fRate, child: _hdr('Rate\n(R/hr)',TextAlign.center)),
          Expanded(flex: _fHour, child: _hdr('Norm\nhrs',  TextAlign.center)),
          Expanded(flex: _fHour, child: _hdr('OT\nhrs',    TextAlign.center)),
          Expanded(flex: _fHour, child: _hdr('DT\nhrs',    TextAlign.center)),
          Expanded(flex: _fHour, child: _hdr('PH\nhrs',    TextAlign.center)),
          Expanded(flex: _fHour, child: _hdr('SL\nhrs',    TextAlign.center)),
          Expanded(flex: _fHour, child: _hdr('HL\nhrs',    TextAlign.center)),
          Expanded(flex: _fHour, child: _hdr('FL\nhrs',    TextAlign.center)),
          Expanded(flex: _fNet,  child: _hdr('Net Pay',    TextAlign.right)),
          Expanded(flex: _fNav,  child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _hdr('Payslip Period', TextAlign.center),
          )),
        ]),
      ),
    );
  }

  Widget _hdr(String t, TextAlign a) => Text(t, textAlign: a,
      style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.bold,
          color: Colors.black87, height: 1.2));

  // ── Single row ─────────────────────────────────────────────────────────────

  Widget _buildRow(_EmployeeRow row, int idx, PayslipProvider prov) {
    final payslips = _getEmployeePayslips(row, prov);
    final isNew    = row.navIndex >= payslips.length;
    final existing = isNew ? null : payslips[row.navIndex];
    final locked   = !isNew && !row.isEditingExisting;

    Color? leftAccent;
    if (locked)                 leftAccent = Colors.green.shade500;
    else if (row.isEditingExisting) leftAccent = Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: idx.isOdd ? Colors.grey.shade50 : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
          left: leftAccent != null
              ? BorderSide(color: leftAccent, width: 3)
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

          // ── Employee name ──
          Expanded(flex: _fName, child: Row(children: [
            _statusDot(row, locked),
            const SizedBox(width: 5),
            Expanded(
              child: GestureDetector(
                onTap: () => _showEmployeeDialog(employee: row.employee),
                behavior: HitTestBehavior.opaque,
                child: Text(row.employee.name,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
            ),
            // Employment type chip — visible, click-through to edit dialog.
            Tooltip(
              message: row.employee.employmentType == EmploymentType.permanent
                  ? 'Permanent employee'
                  : 'Seasonal worker',
              child: GestureDetector(
                onTap: () => _showEmployeeDialog(employee: row.employee),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: row.employee.employmentType ==
                            EmploymentType.permanent
                        ? Colors.green.shade50
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: row.employee.employmentType ==
                              EmploymentType.permanent
                          ? Colors.green.shade300
                          : Colors.amber.shade400,
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    row.employee.employmentType == EmploymentType.permanent
                        ? 'PERM'
                        : 'SEAS',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: row.employee.employmentType ==
                              EmploymentType.permanent
                          ? Colors.green.shade800
                          : Colors.amber.shade900,
                    ),
                  ),
                ),
              ),
            ),
            // Informational only: banking details are optional. A faint
            // bank icon shows who's on file for the Bank CSV; nothing is
            // shown for employees without any banking details.
            if (row.employee.hasAnyBankingDetails)
              Tooltip(
                message: row.employee.hasBankingDetails
                    ? 'Banking details on file — included in Bank CSV'
                    : 'Banking details incomplete (${row.employee.bankingIssues.join(', ')}) — not included in Bank CSV',
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.account_balance_outlined,
                      size: 13,
                      color: row.employee.hasBankingDetails
                          ? Colors.grey.shade500
                          : Colors.grey.shade300),
                ),
              ),
            // Visible Edit icon — replaces the hidden ⋮ menu.
            Tooltip(
              message: 'Edit employee details',
              child: GestureDetector(
                onTap: () => _showEmployeeDialog(employee: row.employee),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.edit_outlined,
                      size: 14, color: Colors.grey.shade600),
                ),
              ),
            ),
            // Remove employee — secondary action.
            Tooltip(
              message: 'Remove employee',
              child: GestureDetector(
                onTap: () => _removeEmployee(row),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.person_remove_outlined,
                      size: 14, color: Colors.grey.shade400),
                ),
              ),
            ),
          ])),

          // ── ID number ──
          Expanded(flex: _fId, child: Text(
            row.employee.idNumber.isNotEmpty ? row.employee.idNumber : '—',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          )),

          // ── Rate ──
          Expanded(flex: _fRate, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _field(row.rateCtrl, row.rateNode, locked: locked),
          )),

          // ── 7 hour fields ──
          Expanded(flex: _fHour, child: _hourField(row.normalCtrl,  row.normalNode,  locked)),
          Expanded(flex: _fHour, child: _hourField(row.overtimeCtrl,row.overtimeNode,locked)),
          Expanded(flex: _fHour, child: _hourField(row.doubleCtrl,  row.doubleNode,  locked)),
          Expanded(flex: _fHour, child: _hourField(row.publicCtrl,  row.publicNode,  locked)),
          Expanded(flex: _fHour, child: _hourField(row.sickCtrl,    row.sickNode,    locked)),
          Expanded(flex: _fHour, child: _hourField(row.holidayCtrl, row.holidayNode, locked)),
          Expanded(flex: _fHour, child: _hourField(row.familyCtrl,  row.familyNode,  locked)),

          // ── Net pay ──
          Expanded(flex: _fNet, child: locked
              ? Text(_currency.format(existing!.netSalary),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold,
                      color: Colors.green.shade700))
              : _LiveNet(row: row, currency: _currency)),

          // ── Navigation ──
          Expanded(flex: _fNav, child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _buildNav(row, payslips, existing, isNew, locked, prov),
          )),
        ]),
      ),
    );
  }

  // ── Navigation section ─────────────────────────────────────────────────────

  Widget _buildNav(
    _EmployeeRow row,
    List<PayslipModel> payslips,
    PayslipModel? existing,
    bool isNew,
    bool locked,
    PayslipProvider prov,
  ) {
    final canLeft  = row.navIndex > 0;
    final canRight = row.navIndex < payslips.length; // can go to "new"

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ← arrow
        _navArrow(Icons.chevron_left, canLeft,
            onTap: () => _navLeft(row, prov)),
        const SizedBox(width: 2),

        // Centre: date or "New Payslip"
        Expanded(
          child: isNew
              ? _buildNavNew(row)
              : _buildNavExisting(
                  existing!, row, locked, prov,
                  counter: '${row.navIndex + 1}/${payslips.length}'),
        ),

        const SizedBox(width: 2),
        // → arrow
        _navArrow(Icons.chevron_right, canRight,
            onTap: () => _navRight(row, prov)),
      ],
    );
  }

  Widget _navArrow(IconData icon, bool enabled, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? Colors.black87 : Colors.grey.shade200,
        ),
        child: Icon(icon, size: 16,
            color: enabled ? Colors.white : Colors.grey.shade400),
      ),
    );
  }

  // Nav centre – viewing an existing payslip
  Widget _buildNavExisting(PayslipModel p, _EmployeeRow row,
      bool locked, PayslipProvider prov, {required String counter}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            '${_dateFmt.format(p.payPeriodStart)} – ${_dateFmt.format(p.payPeriodEnd)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(counter,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
          ),
        ]),
        const SizedBox(height: 3),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          // PDF
          _navIcon(Icons.picture_as_pdf, 'Download PDF', onTap: () async {
            try {
              await PayslipPdfBuilder.downloadFile(p);
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('PDF error: $e')));
            }
          }),
          const SizedBox(width: 6),
          // Edit / Cancel
          if (!row.isEditingExisting)
            _navIcon(Icons.edit_outlined, 'Edit this payslip', onTap: () {
              setState(() {
                row.isEditingExisting = true;
                _fillRowFromPayslip(row, p);
              });
            })
          else
            _navIcon(Icons.close, 'Cancel edit', onTap: () {
              setState(() {
                row.isEditingExisting = false;
                _fillRowFromPayslip(row, p);
              });
            }),
          const SizedBox(width: 6),
          // Additions (extra income) – active when editing
          _navIcon(
            Icons.add_circle_outline,
            !locked
                ? (row.earnings.isEmpty
                    ? 'Add income'
                    : '${row.earnings.length} addition${row.earnings.length == 1 ? '' : 's'}')
                : (row.earnings.isEmpty
                    ? 'No additions (edit to add)'
                    : '${row.earnings.length} addition${row.earnings.length == 1 ? '' : 's'} (edit to change)'),
            count: row.earnings.length,
            active: !locked,
            onTap: !locked ? () => _showEarningsDialog(row) : null,
          ),
          const SizedBox(width: 6),
          // Deductions – active when editing, shows count badge when locked
          _navIcon(
            Icons.remove_circle_outline,
            !locked
                ? (row.deductions.isEmpty
                    ? 'Add deductions'
                    : '${row.deductions.length} deduction${row.deductions.length == 1 ? '' : 's'}')
                : (row.deductions.isEmpty
                    ? 'No deductions (edit to add)'
                    : '${row.deductions.length} deduction${row.deductions.length == 1 ? '' : 's'} (edit to change)'),
            count: row.deductions.length,
            active: !locked,
            onTap: !locked ? () => _showDeductionsDialog(row) : null,
          ),
          const SizedBox(width: 6),
          // Delete
          _navIcon(Icons.delete_outline, locked ? 'Delete payslip' : 'Finish editing first',
              active: locked,
              onTap: locked ? () => _deletePayslip(p, prov, row) : null),
        ]),
      ],
    );
  }

  // Nav centre – "New Payslip" position
  Widget _buildNavNew(_EmployeeRow row) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('New Payslip',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: Colors.black87)),
        const SizedBox(height: 3),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _miniDateChip(row.newPeriodStart, () => _pickDate(
              row.newPeriodStart,
              (d) => setState(() => row.newPeriodStart = d))),
          Text(' – ',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          _miniDateChip(row.newPeriodEnd, () => _pickDate(
              row.newPeriodEnd,
              (d) => setState(() => row.newPeriodEnd = d))),
        ]),
        const SizedBox(height: 3),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _navIcon(
            Icons.add_circle_outline,
            row.earnings.isEmpty
                ? 'Add income'
                : '${row.earnings.length} addition${row.earnings.length == 1 ? '' : 's'}',
            count: row.earnings.length,
            onTap: () => _showEarningsDialog(row),
          ),
          const SizedBox(width: 8),
          _navIcon(
            Icons.remove_circle_outline,
            row.deductions.isEmpty
                ? 'Add deductions'
                : '${row.deductions.length} deduction${row.deductions.length == 1 ? '' : 's'}',
            count: row.deductions.length,
            onTap: () => _showDeductionsDialog(row),
          ),
        ]),
      ],
    );
  }

  Widget _miniDateChip(DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Text(_dateFmt.format(date),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _navIcon(IconData icon, String tip,
      {VoidCallback? onTap, bool active = true, int count = 0}) {
    final color = (onTap != null && active)
        ? Colors.black87
        : Colors.grey.shade300;
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Stack(clipBehavior: Clip.none, children: [
            Icon(icon, size: 15, color: color),
            if (count > 0)
              Positioned(right: -3, top: -3,
                child: Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(
                      color: Colors.black87, shape: BoxShape.circle),
                  child: Center(child: Text('$count',
                      style: const TextStyle(
                          fontSize: 7, color: Colors.white,
                          fontWeight: FontWeight.bold))),
                )),
          ]),
        ),
      ),
    );
  }

  // ── Status dot ─────────────────────────────────────────────────────────────

  Widget _statusDot(_EmployeeRow row, bool locked) {
    if (row.generating) {
      return const SizedBox(width: 10, height: 10,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54));
    }
    if (row.error != null) {
      return Tooltip(message: row.error!,
          child: const Icon(Icons.error_outline, size: 13, color: Colors.black54));
    }
    if (locked) {
      return Icon(Icons.check_circle, size: 13, color: Colors.green.shade600);
    }
    if (row.isEditingExisting) {
      return const Icon(Icons.edit, size: 12, color: Colors.black54);
    }
    return Icon(Icons.radio_button_unchecked, size: 12, color: Colors.grey.shade300);
  }

  // ── Input fields ───────────────────────────────────────────────────────────

  Widget _hourField(TextEditingController ctrl, FocusNode node, bool locked) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: _field(ctrl, node, locked: locked),
    );
  }

  Widget _field(TextEditingController ctrl, FocusNode node,
      {bool locked = false}) {
    return SizedBox(
      height: 30,
      child: TextField(
        controller: ctrl, focusNode: node,
        enabled: !locked,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 11,
            color: locked ? Colors.grey.shade500 : Colors.black87),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          filled: locked,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Colors.black87, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _searchBox() {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search employees…',
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey[400]),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 14),
                  onPressed: _searchCtrl.clear, splashRadius: 14)
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400)),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          filled: true, fillColor: Colors.white,
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildPagination(
      {required int total, required int page}) {
    if (total == 0) return const SizedBox.shrink();
    final pages = (total / _pageSize).ceil();
    final from  = page * _pageSize + 1;
    final to    = min((page + 1) * _pageSize, total);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(children: [
        Text('Showing $from–$to of $total',
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const Spacer(),
        if (pages > 1) ...[
          _pgBtn(Icons.chevron_left,
              page > 0 ? () => setState(() => _page = page - 1) : null),
          ..._visPages(page, pages).map((n) {
            if (n < 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text('…',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              );
            }
            final active = n == page;
            return GestureDetector(
              onTap: active ? null : () => setState(() => _page = n),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: active ? Colors.black87 : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: active ? Colors.black87 : Colors.grey.shade300),
                ),
                child: Center(child: Text('${n + 1}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: active
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: active ? Colors.white : Colors.grey[700]))),
              ),
            );
          }),
          _pgBtn(Icons.chevron_right,
              page < pages - 1 ? () => setState(() => _page = page + 1) : null),
        ],
      ]),
    );
  }

  List<int> _visPages(int cur, int tot) {
    if (tot <= 7) return List.generate(tot, (i) => i);
    if (cur < 4) return [0, 1, 2, 3, 4, -1, tot - 1];
    if (cur > tot - 5) return [0, -1, tot-5, tot-4, tot-3, tot-2, tot-1];
    return [0, -1, cur-1, cur, cur+1, -1, tot-1];
  }

  Widget _pgBtn(IconData icon, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 30, height: 30,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: onTap == null
                  ? Colors.grey.shade200
                  : Colors.grey.shade300)),
      child: Icon(icon, size: 18,
          color: onTap == null ? Colors.grey[300] : Colors.grey[600]),
    ),
  );

  Widget _buildError(PayslipProvider prov) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: Colors.black54, size: 48),
        const SizedBox(height: 16),
        const Text('Failed to load data',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text(prov.error!, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            prov.clearError();
            if (_selectedCompany != null) {
              prov.loadForCompany(_selectedCompany!.id, force: true);
            }
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ]),
    ),
  );

  Widget _buildNoCompany() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.business_outlined, size: 56, color: Colors.grey[300]),
      const SizedBox(height: 16),
      Text('Select a company to manage payslips',
          style: TextStyle(color: Colors.grey[500], fontSize: 15)),
    ]),
  );

  Widget _buildEmpty(IconData icon, String msg) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 48, color: Colors.grey[200]),
      const SizedBox(height: 12),
      Text(msg, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: _showEmployeeDialog,
        icon: const Icon(Icons.person_add_outlined, size: 16),
        label: const Text('Add First Employee'),
      ),
    ]),
  );
}

// ── Live net pay ───────────────────────────────────────────────────────────────

class _LiveNet extends StatefulWidget {
  final _EmployeeRow row;
  final NumberFormat currency;
  const _LiveNet({required this.row, required this.currency});
  @override
  State<_LiveNet> createState() => _LiveNetState();
}

class _LiveNetState extends State<_LiveNet> {
  @override
  void initState() {
    super.initState();
    for (final c in _ctrls) c.addListener(_rebuild);
  }

  List<TextEditingController> get _ctrls => [
    widget.row.rateCtrl, widget.row.normalCtrl, widget.row.overtimeCtrl,
    widget.row.doubleCtrl, widget.row.publicCtrl, widget.row.sickCtrl,
    widget.row.holidayCtrl, widget.row.familyCtrl,
  ];

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    for (final c in _ctrls) c.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final net = widget.row.liveNetPay;
    return Text(
      net > 0 ? widget.currency.format(net) : '—',
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: 12,
        fontWeight: net > 0 ? FontWeight.w500 : FontWeight.normal,
        color: net > 0 ? Colors.grey.shade700 : Colors.grey.shade300,
      ),
    );
  }
}
