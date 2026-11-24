import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/models/employee_model.dart';
import 'package:cropCompliance/models/payslip_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/payslip_provider.dart';
import 'package:cropCompliance/views/payslip/utils/leave_check.dart';
import 'package:cropCompliance/views/payslip/utils/payslip_pdf_builder.dart';
import 'package:cropCompliance/views/payslip/widgets/employee_form_dialog.dart';
import 'package:cropCompliance/views/payslip/widgets/leave_shortfall_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'mobile_ui.dart';
import 'package:cropCompliance/providers/locale_provider.dart';
import 'package:cropCompliance/l10n/generated/app_localizations.dart';

/// The values captured on the Hours Worked card, one tab each.
enum _Field { rate, normal, overtime, doubleTime, publicHoliday, sick, holiday, family }

extension on _Field {
  String tab(AppLocalizations l10n) => switch (this) {
        _Field.rate => l10n.hoursTabRate,
        _Field.normal => l10n.hoursTabNormal,
        _Field.overtime => l10n.hoursTabOvertime,
        _Field.doubleTime => l10n.hoursTabDouble,
        _Field.publicHoliday => l10n.hoursTabPublicHoliday,
        _Field.sick => l10n.hoursTabSick,
        _Field.holiday => l10n.hoursTabHoliday,
        _Field.family => l10n.hoursTabFamily,
      };

  String get unit => this == _Field.rate ? 'R/hr' : 'hrs';
}

/// Payslips for phones: the selected worker's latest payslip, the worker
/// carousel, and an Hours Worked card to capture the next payslip one value
/// at a time (works offline — it syncs when there's signal).
class MobilePayslipsScreen extends StatefulWidget {
  const MobilePayslipsScreen({super.key});

  @override
  State<MobilePayslipsScreen> createState() => _MobilePayslipsScreenState();
}

class _MobilePayslipsScreenState extends State<MobilePayslipsScreen> {
  static DateFormat get _date => DateFormat('d MMM yy'); // follows the app language
  static DateFormat get _longDate => DateFormat('d-MMM-yyyy'); // follows the app language
  static final _rand =
      NumberFormat.currency(locale: 'en_ZA', symbol: 'R ', decimalDigits: 2);

  String? _employeeId;
  _Field _field = _Field.rate;
  final _value = TextEditingController();
  late DateTime _start;
  late DateTime _end;
  bool _saving = false;

  /// Hours entered for the payslip being captured, per worker.
  final Map<String, Map<_Field, double>> _draft = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month + 1, 0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  String? get _companyId =>
      Provider.of<AuthProvider>(context, listen: false).effectiveCompany?.id;

  Future<void> _load() async {
    final id = _companyId;
    if (id == null) return;
    await Provider.of<PayslipProvider>(context, listen: false)
        .loadForCompany(id);
    if (mounted) setState(() {});
  }

  EmployeeModel? _selected(List<EmployeeModel> list) {
    if (list.isEmpty) return null;
    for (final e in list) {
      if (e.id == _employeeId) return e;
    }
    return list.first;
  }

  PayslipModel? _latestFor(PayslipProvider prov, String employeeId) {
    PayslipModel? best;
    for (final p in prov.payslips) {
      if (p.employeeId != employeeId) continue;
      if (best == null || p.payPeriodStart.isAfter(best.payPeriodStart)) {
        best = p;
      }
    }
    return best;
  }

  double _currentValue(EmployeeModel e) {
    if (_field == _Field.rate) {
      return _draft[e.id]?[_Field.rate] ?? e.normalHourlyRate;
    }
    return _draft[e.id]?[_field] ?? 0;
  }

  void _selectEmployee(EmployeeModel e) {
    setState(() {
      _employeeId = e.id;
      _field = _Field.rate;
      _value.text = _fmt(_currentValue(e));
    });
  }

  void _selectField(EmployeeModel e, _Field f) {
    setState(() {
      _field = f;
      final v = _currentValue(e);
      _value.text = v == 0 && f != _Field.rate ? '' : _fmt(v);
    });
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// "Set": keep the value and move to the next tab.
  void _set(EmployeeModel e) {
    final v = double.tryParse(_value.text.trim().replaceAll(',', '.'));
    if (v == null || v < 0) {
      _toast(context.l10n.hoursTypeNumber);
      return;
    }
    setState(() {
      _draft.putIfAbsent(e.id, () => {})[_field] = v;
      final next = _field.index + 1;
      if (next < _Field.values.length) {
        _field = _Field.values[next];
        final nv = _currentValue(e);
        _value.text = nv == 0 ? '' : _fmt(nv);
      }
    });
  }

  // ── Save payslip ─────────────────────────────────────────────────────────

  Future<void> _savePayslip(EmployeeModel e, PayslipProvider prov) async {
    final d = _draft[e.id] ?? {};
    double v(_Field f) => d[f] ?? 0;
    final rate = d[_Field.rate] ?? e.normalHourlyRate;
    if (rate <= 0) {
      _selectField(e, _Field.rate);
      _toast(context.l10n.hoursSetRateFirst(e.name));
      return;
    }
    final hours = _Field.values
        .where((f) => f != _Field.rate)
        .fold<double>(0, (s, f) => s + v(f));
    if (hours <= 0) {
      _selectField(e, _Field.normal);
      _toast(context.l10n.hoursEnterFirst);
      return;
    }

    // Same period already has a payslip? Replace it (after asking).
    PayslipModel? existing;
    for (final p in prov.payslips) {
      if (p.employeeId == e.id &&
          DateUtils.isSameDay(p.payPeriodStart, _start) &&
          DateUtils.isSameDay(p.payPeriodEnd, _end)) {
        existing = p;
      }
    }
    if (existing != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.payslipReplaceTitle),
          content: Text(context.l10n.payslipReplaceBody(
              e.name, _date.format(_start), _date.format(_end))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.l10n.commonCancel)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(context.l10n.actionReplace)),
          ],
        ),
      );
      if (ok != true) return;
    }

    // Leave check (same as the Payslip Manager).
    var sl = v(_Field.sick), hl = v(_Field.holiday), fl = v(_Field.family);
    final shortfalls = findLeaveShortfalls(
      employeeId: e.id,
      employeeName: e.name,
      requested: {
        LeaveType.sick: sl,
        LeaveType.holiday: hl,
        LeaveType.family: fl,
      },
      available: {
        LeaveType.sick:
            prov.sickLeaveBalance(e.id) + (existing?.sickLeaveHours ?? 0),
        LeaveType.holiday: prov.holidayLeaveBalance(e.id) +
            (existing?.holidayLeaveHours ?? 0),
        LeaveType.family:
            prov.familyLeaveBalance(e.id) + (existing?.familyLeaveHours ?? 0),
      },
    );
    if (shortfalls.isNotEmpty) {
      if (!mounted) return;
      final choices = await LeaveShortfallDialog.show(context, shortfalls);
      if (choices == null) return;
      for (var i = 0; i < shortfalls.length; i++) {
        final h = shortfalls[i].hoursFor(choices[i]);
        switch (shortfalls[i].type) {
          case LeaveType.sick:
            sl = h;
            break;
          case LeaveType.holiday:
            hl = h;
            break;
          case LeaveType.family:
            fl = h;
            break;
        }
      }
    }

    if (!mounted) return;
    final company =
        Provider.of<AuthProvider>(context, listen: false).effectiveCompany;
    setState(() => _saving = true);
    try {
      // The rate on the employee record follows what was set here.
      if (d[_Field.rate] != null && d[_Field.rate] != e.normalHourlyRate) {
        await prov.saveEmployee(e.copyWith(normalHourlyRate: rate));
      }
      final settings = prov.payrollSettings;
      PayslipModel build(double paye) => PayslipModel(
            id: existing?.id ?? '',
            companyId: e.companyId,
            companyName: company?.name ?? '',
            companyAddress: (settings?.companyAddress ?? '').isNotEmpty
                ? settings!.companyAddress
                : company?.address ?? '',
            employeeId: e.id,
            employeeName: e.name,
            employeeIdNumber: e.idNumber,
            employmentType: e.employmentType,
            jobDescription: e.jobDescription,
            uifRegNumber: settings?.uifRegNumber ?? '',
            payPeriodStart: _start,
            payPeriodEnd: _end,
            payDate: existing?.payDate ?? DateTime.now(),
            normalHours: v(_Field.normal),
            overtimeHours: v(_Field.overtime),
            doubleTimeHours: v(_Field.doubleTime),
            publicHolidayHours: v(_Field.publicHoliday),
            sickLeaveHours: sl,
            holidayLeaveHours: hl,
            familyLeaveHours: fl,
            normalRate: rate,
            overtimeRate: rate * 1.5,
            doubleTimeRate: rate * 2.0,
            additionalDeductions: existing?.additionalDeductions ?? const [],
            additionalEarnings: existing?.additionalEarnings ?? const [],
            payeDeduction: paye,
            payeAutoCalculated: true,
            status: PayslipStatus.finalised,
            createdAt: existing?.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
          );
      final draft = build(0);
      final paye = PayslipModel.calculatePayeForPeriod(
          draft.totalEarnings, _start, _end);
      final saved = await prov.savePayslip(build(paye));
      if (!mounted) return;
      if (saved == null) {
        _toast(context.l10n.payslipSaveFailed);
        return;
      }
      setState(() {
        _draft.remove(e.id);
        _field = _Field.rate;
        _value.text = _fmt(rate);
      });
      _toast(context.l10n
          .payslipSavedFor(e.name, _rand.format(saved.netSalary)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate(bool start) async {
    final d = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: start ? context.l10n.periodStart : context.l10n.periodEnd,
    );
    if (d == null) return;
    setState(() {
      if (start) {
        _start = d;
        if (_end.isBefore(d)) _end = d;
      } else {
        _end = d;
        if (_start.isAfter(d)) _start = d;
      }
    });
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final prov = Provider.of<PayslipProvider>(context);
    final company = auth.effectiveCompany;
    final loading =
        prov.isLoading || (company != null && prov.loadedCompanyId != company.id);
    final employees = [...prov.employees]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final e = _selected(employees);
    if (e != null && _employeeId == null) {
      _employeeId = e.id;
      _value.text = _fmt(e.normalHourlyRate);
    }

    return Scaffold(
      backgroundColor: MobileColors.page,
      body: Column(children: [
        MobileHeader(
          title: context.l10n
              .payslipsHeaderTitle(company?.name ?? context.l10n.farm),
          leading: const Icon(Icons.location_on_outlined,
              color: MobileColors.ink, size: 28),
          trailing: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${employees.length}',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800)),
            Text(context.l10n.employeesLabel,
                style: TextStyle(fontSize: 13, color: MobileColors.muted)),
          ]),
        ),
        Expanded(
          child: company == null
              ? Center(child: Text(context.l10n.chooseFarmFirst))
              : loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => prov.loadForCompany(company.id,
                          force: true),
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          const SizedBox(height: 16),
                          if (e != null)
                            _payslipPreview(e, _latestFor(prov, e.id)),
                          _sectionTitle(
                              context.l10n.employeeLabel,
                              context.l10n.actionViewAll,
                              () => _allEmployees(employees)),
                          employees.isEmpty
                              ? _noEmployees()
                              : _carousel(employees, e),
                          if (e != null) ...[
                            _sectionTitle(
                                context.l10n.hoursWorked,
                                context.l10n.navPayslips,
                                () => Navigator.of(context).pushNamed(
                                        RouteConstants.payslipRecords,
                                        arguments: {
                                          'companyId': company.id,
                                          'companyName': company.name,
                                        })),
                            _hoursCard(e, prov),
                          ],
                        ],
                      ),
                    ),
        ),
      ]),
      bottomNavigationBar: const MobileBottomNav(current: MobileTab.payslips),
    );
  }

  Widget _sectionTitle(String title, String link, VoidCallback onLink) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 16, 10),
        child: Row(children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: onLink,
            child: Row(children: [
              Text(link,
                  style: const TextStyle(
                      fontSize: 18,
                      decoration: TextDecoration.underline,
                      color: MobileColors.ink)),
              const Icon(Icons.chevron_right, color: MobileColors.ink),
            ]),
          ),
        ]),
      );

  // ── Payslip preview (SALARIS STROKIE) ────────────────────────────────────

  Widget _payslipPreview(EmployeeModel e, PayslipModel? p) {
    if (p == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: MobileCard(
          child: Row(children: [
            const Icon(Icons.receipt_long_outlined, color: MobileColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  context.l10n.payslipNoneYetFor(e.name),
                  style: const TextStyle(color: MobileColors.muted)),
            ),
          ]),
        ),
      );
    }
    TableRow row(String a, String b, {bool bold = false, Color? color}) =>
        TableRow(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(a, style: TextStyle(fontSize: 13, color: color)),
          ),
          Text(b,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: color)),
        ]);
    Widget head(String t) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: const Color(0xFFE6E8E6),
          child: Text(t,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: MobileColors.green)),
        );
    String r(double v) => _rand.format(v);

    final l10n = context.l10n;
    final earnings = <TableRow>[
      row(l10n.payslipNormalPayHours(_fmt(p.normalHours)), r(p.normalPay)),
      if (p.overtimeHours > 0)
        row(l10n.payslipOvertimePayHours(_fmt(p.overtimeHours)),
            r(p.overtimePay)),
      if (p.doubleTimeHours > 0)
        row(l10n.payslipDoubleTimeHours(_fmt(p.doubleTimeHours)),
            r(p.doubleTimePay)),
      if (p.publicHolidayHours > 0)
        row(l10n.payslipPublicHolidayHours(_fmt(p.publicHolidayHours)),
            r(p.publicHolidayPay)),
      if (p.sickLeaveHours > 0)
        row(l10n.payslipSickLeaveHours(_fmt(p.sickLeaveHours)),
            r(p.sickLeavePay)),
      if (p.holidayLeaveHours > 0)
        row(l10n.payslipAnnualLeaveHours(_fmt(p.holidayLeaveHours)),
            r(p.holidayLeavePay)),
      if (p.familyLeaveHours > 0)
        row(l10n.payslipFamilyLeaveHours(_fmt(p.familyLeaveHours)),
            r(p.familyLeavePay)),
      for (final x in p.additionalEarnings) row(x.description, r(x.amount)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: MobileCard(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: head(l10n.payslipTitle)),
          Table(columnWidths: const {0: FlexColumnWidth(1.1)}, children: [
            row(l10n.payslipName, p.employeeName, bold: true),
            row(l10n.payslipIdNumber, p.employeeIdNumber, bold: true),
            row(l10n.payslipPeriod, '${_longDate.format(p.payPeriodStart)} – ${_longDate.format(p.payPeriodEnd)}',
                bold: true),
            row(l10n.payslipPayDate, _longDate.format(p.payDate), bold: true),
          ]),
          head(l10n.payslipEarnings),
          Table(children: [
            ...earnings,
            row(l10n.payslipTotalEarnings, r(p.totalEarnings),
                bold: true, color: MobileColors.green),
          ]),
          head(l10n.payslipDeductions),
          Table(children: [
            row(l10n.payslipUifEmployee, r(p.uifDeduction)),
            row(l10n.payslipPayeTax, r(p.payeDeduction)),
            for (final x in p.additionalDeductions)
              row(x.description, r(x.amount)),
            row(l10n.payslipTotalDeductions, r(p.totalDeductions),
                bold: true, color: MobileColors.red),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: MobileColors.greenTint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: MobileColors.greenMid),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text(l10n.payslipNetSalary,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: MobileColors.green)),
                  ),
                  Text(r(p.netSalary),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: MobileColors.green)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: MobileColors.greenMid,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: l10n.actionDownloadPdf,
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: () async {
                  try {
                    await PayslipPdfBuilder.downloadFile(p);
                  } catch (err) {
                    _toast(l10n.pdfOpenFailed('$err'));
                  }
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Employees ────────────────────────────────────────────────────────────

  Widget _noEmployees() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: MobileCard(
          onTap: _addEmployee,
          child: Row(children: [
            const Icon(Icons.person_add_alt_1, color: MobileColors.green),
            const SizedBox(width: 12),
            Expanded(child: Text(context.l10n.employeesNoneYetTapAdd)),
          ]),
        ),
      );

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : ''))
        .toUpperCase();
  }

  Widget _carousel(List<EmployeeModel> list, EmployeeModel? selected) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final e = list[i];
          final sel = e.id == selected?.id;
          return GestureDetector(
            onTap: () => _selectEmployee(e),
            child: SizedBox(
              width: 112,
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: sel ? 96 : 84,
                  height: sel ? 96 : 84,
                  margin: EdgeInsets.only(top: sel ? 0 : 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MobileColors.greenTint,
                    border: Border.all(
                        color: sel
                            ? MobileColors.greenMid
                            : MobileColors.greenSoft,
                        width: sel ? 5 : 4),
                  ),
                  alignment: Alignment.center,
                  child: Text(_initials(e.name),
                      style: TextStyle(
                          fontSize: sel ? 30 : 26,
                          fontWeight: FontWeight.w700,
                          color: MobileColors.green)),
                ),
                const SizedBox(height: 8),
                Text(e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: sel ? FontWeight.w800 : FontWeight.w600)),
                Text(
                    e.idNumber.isEmpty
                        ? context.l10n.employeeNoId
                        : context.l10n.employeeIdShort(e.idNumber),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: MobileColors.muted)),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _allEmployees(List<EmployeeModel> list) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        var query = '';
        return StatefulBuilder(builder: (ctx, setSheet) {
          final shown = list
              .where((e) =>
                  e.name.toLowerCase().contains(query) ||
                  e.idNumber.contains(query))
              .toList();
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.8,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  autofocus: false,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: context.l10n.employeeSearchHint,
                    filled: true,
                    fillColor: MobileColors.page,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setSheet(() => query = v.toLowerCase()),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                    backgroundColor: MobileColors.greenMid,
                    child: Icon(Icons.add, color: Colors.white)),
                title: Text(context.l10n.employeeAdd,
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _addEmployee();
                },
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: shown.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: MobileColors.greenTint,
                      child: Text(_initials(shown[i].name),
                          style: const TextStyle(color: MobileColors.green)),
                    ),
                    title: Text(shown[i].name),
                    subtitle: Text(shown[i].idNumber),
                    trailing: IconButton(
                      tooltip: context.l10n.actionEdit,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _editEmployee(shown[i]);
                      },
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _selectEmployee(shown[i]);
                    },
                  ),
                ),
              ),
            ]),
          );
        });
      },
    );
  }

  Future<void> _addEmployee() => _editEmployee(null);

  Future<void> _editEmployee(EmployeeModel? e) async {
    final companyId = _companyId;
    if (companyId == null) return;
    final prov = Provider.of<PayslipProvider>(context, listen: false);
    await showDialog<void>(
      context: context,
      builder: (dctx) => EmployeeFormDialog(
        companyId: companyId,
        employee: e,
        onSave: (emp) async {
          final saved = await prov.upsertEmployee(emp);
          if (!dctx.mounted) return;
          if (saved != null) {
            Navigator.of(dctx).pop();
            if (mounted) _selectEmployee(saved);
          } else {
            _toast(context.l10n
                .saveFailedReason(prov.error ?? context.l10n.errorUnknown));
          }
        },
      ),
    );
  }

  // ── Hours Worked card ────────────────────────────────────────────────────

  String _help(EmployeeModel e, PayslipProvider prov) {
    final l10n = context.l10n;
    String bal(double v) => l10n.hoursLeft(_fmt(v < 0 ? 0 : v));
    switch (_field) {
      case _Field.rate:
        return l10n.hoursHelpRate;
      case _Field.normal:
        return l10n.hoursHelpNormal;
      case _Field.overtime:
        return l10n.hoursHelpOvertime;
      case _Field.doubleTime:
        return l10n.hoursHelpDouble;
      case _Field.publicHoliday:
        return l10n.hoursHelpPublicHoliday;
      case _Field.sick:
        return l10n.hoursHelpSick(bal(prov.sickLeaveBalance(e.id)));
      case _Field.holiday:
        return l10n.hoursHelpHoliday(bal(prov.holidayLeaveBalance(e.id)));
      case _Field.family:
        return l10n.hoursHelpFamily(bal(prov.familyLeaveBalance(e.id)));
    }
  }

  Widget _hoursCard(EmployeeModel e, PayslipProvider prov) {
    final d = _draft[e.id] ?? {};
    final entered = d.entries
        .where((x) => x.key != _Field.rate && x.value > 0)
        .map((x) =>
            '${x.key.tab(context.l10n).split('\n').first} ${_fmt(x.value)}')
        .join(' · ');
    final last = _field == _Field.family;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            color: MobileColors.greenMid,
            child: Column(children: [
              // Tabs
              Container(
                color: MobileColors.greenSoft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final f in _Field.values)
                      GestureDetector(
                        onTap: () => _selectField(e, f),
                        child: Container(
                          width: 64,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: f == _field
                                ? MobileColors.greenMid
                                : Colors.transparent,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18)),
                          ),
                          child: Column(children: [
                            Text(f.tab(context.l10n),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13.5,
                                    height: 1.2,
                                    fontWeight: f == _field
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: f == _field
                                        ? Colors.white
                                        : MobileColors.ink)),
                            if (d[f] != null && f != _Field.rate)
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: f == _field
                                      ? Colors.white
                                      : MobileColors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ]),
                        ),
                      ),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(
                            text: e.name,
                            style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        if (e.idNumber.isNotEmpty)
                          TextSpan(
                              text: '   ${context.l10n.employeeIdLabel(e.idNumber)}',
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.white)),
                      ])),
                      const SizedBox(height: 6),
                      Text(_help(e, prov),
                          style: const TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              color: Colors.white)),
                      const SizedBox(height: 14),
                      Row(children: [
                        Column(children: [
                          _datePill(context.l10n.dateStart, _start,
                              () => _pickDate(true)),
                          const SizedBox(height: 6),
                          _datePill(context.l10n.dateEnd, _end,
                              () => _pickDate(false)),
                        ]),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 72,
                            decoration: BoxDecoration(
                              color: MobileColors.green,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: TextField(
                              controller: _value,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFFE082)),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                suffixText: _field.unit,
                                suffixStyle: const TextStyle(
                                    color: Color(0xFFFFE082),
                                    fontWeight: FontWeight.w700),
                                hintText: '0',
                                hintStyle: const TextStyle(
                                    color: Color(0x88FFE082)),
                              ),
                              onSubmitted: (_) => _set(e),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 72,
                          child: OutlinedButton(
                            onPressed: () => _set(e),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Colors.white, width: 2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                            ),
                            child: Text(
                                last
                                    ? context.l10n.actionSetDone
                                    : context.l10n.actionSet,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                      ]),
                    ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        if (entered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(context.l10n.hoursEntered(entered),
                textAlign: TextAlign.center,
                style: const TextStyle(color: MobileColors.muted)),
          ),
        MobilePrimaryButton(
          label: context.l10n.payslipSaveFor(e.name.split(' ').first),
          icon: Icons.save_outlined,
          busy: _saving,
          onPressed: () => _savePayslip(e, prov),
        ),
      ]),
    );
  }

  Widget _datePill(String label, DateTime d, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 40,
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.white)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: MobileColors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(_date.format(d),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ]),
        ),
      ]),
    );
  }
}
