import 'package:cropCompliance/views/shared/admin_farm_chip.dart';
import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/models/employee_model.dart';
import 'package:cropCompliance/models/payslip_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/payslip_provider.dart';
import 'package:cropCompliance/views/payslip/utils/leave_check.dart';
import 'package:cropCompliance/views/payslip/widgets/leave_shortfall_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'timesheet_calc.dart';
import 'timesheet_payslips.dart';
import 'timesheet_service.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// Payslip Manager · Timesheet.
///
/// Three sheets in the same all-workers grid — Normal hours, Overtime and
/// Piecework — workers as rows, the days of the pay period as columns. Save
/// stores the sheets and recalculates each worker's payslip (as a Draft) from
/// configured rates only. Finalise period locks all three sheets and
/// finalises the payslips. See CC_Payslip_Manager_Timesheet_Spec.
class TimesheetScreen extends StatefulWidget {
  final String companyId;
  final String companyName;

  const TimesheetScreen({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

enum _Sheet { normal, overtime, piece }

class _TimesheetScreenState extends State<TimesheetScreen> {
  static const _green = Color(0xFF2E7D32);
  static DateFormat get _rangeFmt => DateFormat('d MMM yyyy'); // follows the app language
  static DateFormat get _dayName => DateFormat('EEE'); // follows the app language

  final _service = TimesheetService();

  bool _loading = true;
  String? _loadError;
  bool _saving = false;
  bool _dirty = false;

  _Sheet _sheet = _Sheet.normal;
  PeriodType _type = PeriodType.weekly;
  late PayPeriodRecord _period;
  List<PayPeriodRecord> _periods = [];
  Map<String, WorkerSheets> _sheets = {};
  Set<String> _loadedWorkerIds = {};
  TimesheetRates _rates = const TimesheetRates();
  List<PieceRateInfo> _pieceRates = [];

  /// Cell keys whose text didn't parse (shown red; Save is held until fixed).
  final Set<String> _badCells = {};

  /// Bumped per worker on every edit, so only that row (and the footer)
  /// rebuilds while typing.
  final Map<String, ValueNotifier<int>> _rowTick = {};
  final ValueNotifier<int> _footerTick = ValueNotifier(0);

  /// Workers whose payslips couldn't be recalculated on the last Save, and why.
  Map<String, List<String>> _notRecalculated = {};

  PayslipProvider get _prov =>
      Provider.of<PayslipProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _period = PayPeriodRecord.draft(widget.companyId, _type,
        DateTime(now.year, now.month, now.day - (now.weekday - 1)));
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    for (final n in _rowTick.values) {
      n.dispose();
    }
    _footerTick.dispose();
    super.dispose();
  }

  ValueNotifier<int> _tick(String empId) =>
      _rowTick.putIfAbsent(empId, () => ValueNotifier(0));

  // ── Loading ───────────────────────────────────────────────────────────────

  Future<void> _bootstrap() async {
    try {
      await _prov.loadForCompany(widget.companyId);
      final results = await Future.wait([
        _service.recentPeriods(widget.companyId),
        _service.rates(widget.companyId),
        _service.pieceRates(widget.companyId),
      ]);
      _periods = results[0] as List<PayPeriodRecord>;
      _rates = results[1] as TimesheetRates;
      _pieceRates = results[2] as List<PieceRateInfo>;
      if (_periods.isNotEmpty) {
        _period = _periods.first; // most recent period
        _type = _period.type;
      }
      await _loadPeriod(_period);
    } catch (e) {
      _loadError = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadPeriod(PayPeriodRecord p) async {
    final entries = await _service.loadEntries(widget.companyId, p.id);
    _period = p;
    _sheets = entries;
    _loadedWorkerIds = entries.keys.toSet();
    _badCells.clear();
    _notRecalculated = {};
    _dirty = false;
  }

  Future<void> _switchPeriod(PayPeriodRecord p) async {
    if (!await _confirmDiscard()) return;
    setState(() => _loading = true);
    try {
      await _loadPeriod(p);
    } catch (e) {
      _toast(context.l10n.tsLoadPeriodFailed('$e'));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.unsavedChanges),
        content: Text(
            context.l10n.tsUnsavedBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.keepEditing)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.discardChanges)),
        ],
      ),
    );
    return ok == true;
  }

  // ── Editing ───────────────────────────────────────────────────────────────

  WorkerSheets _sheetsOf(String empId) =>
      _sheets.putIfAbsent(empId, () => WorkerSheets());

  void _changed(String empId) {
    _dirty = true;
    _tick(empId).value++;
    _footerTick.value++;
  }

  void _setBad(String key, bool bad) {
    final had = _badCells.contains(key);
    if (bad == had) return;
    setState(() => bad ? _badCells.add(key) : _badCells.remove(key));
  }

  // ── Save / Finalise ───────────────────────────────────────────────────────

  List<EmployeeModel> get _workers => [..._prov.employees]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  PieceRateInfo? get _pieceRate {
    for (final r in _pieceRates) {
      if (r.id == _period.pieceRateId) return r;
    }
    return null;
  }

  Future<bool> _save({bool quiet = false}) async {
    if (_badCells.isNotEmpty) {
      _toast(context.l10n.tsFixRedCells(_badCells.length));
      return false;
    }
    setState(() => _saving = true);
    try {
      await _service.savePeriod(_period);
      // Save every worker who has data now, plus anyone who had data before
      // (so clearing a row actually clears it).
      final toWrite = <String, WorkerSheets>{
        for (final e in _sheets.entries)
          if (!e.value.isEmpty || _loadedWorkerIds.contains(e.key))
            e.key: e.value,
      };
      await _service.saveEntries(widget.companyId, _period.id, toWrite);
      _loadedWorkerIds = toWrite.keys.toSet();
      if (!_periods.any((p) => p.id == _period.id)) {
        _periods = [_period, ..._periods];
      }

      final recalculated = await _recalculatePayslips();
      if (recalculated == null) {
        // User went back to edit leave — the sheets are saved, payslips not.
        _dirty = false;
        return false;
      }
      if (!mounted) return false;

      final auth = Provider.of<AuthProvider>(context, listen: false);
      await _service.audit(widget.companyId, _period.id, 'save',
          actorId: auth.currentUser?.id,
          actorName: auth.currentUser?.name,
          detail: '$recalculated payslip(s) recalculated'); // l10n-ignore: audit log

      _dirty = false;
      if (!quiet) {
        final skipped = _notRecalculated.length;
        _toast(skipped == 0
            ? context.l10n.tsSavedUpdated(recalculated)
            : '${context.l10n.tsSavedUpdated(recalculated)}, '
                '${context.l10n.tsSavedSkipped(skipped)}');
      }
      return true;
    } catch (e) {
      _toast(context.l10n.saveFailedError('$e'));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Recalculates every worker's payslip from the three sheets. Returns how
  /// many were saved, or null if the user went back to edit leave.
  Future<int?> _recalculatePayslips() async {
    final prov = _prov;
    final settings = prov.payrollSettings;
    final days = _period.dayKeys;
    final notDone = <String, List<String>>{};

    // Figures per worker with anything on the sheets.
    final figures = <EmployeeModel, PayslipFigures>{};
    for (final e in _workers) {
      final s = _sheets[e.id];
      if (s == null) continue;
      final t = totalsFor(s, days: days);
      final hasWork = t.normalHours > 0 ||
          t.leaveDays > 0 ||
          t.overtimeHours > 0 ||
          t.pieceHours > 0 ||
          t.units > 0;
      if (!hasWork) continue;
      final f = payslipFiguresFor(
        sheets: s,
        days: days,
        hourlyRate: e.normalHourlyRate,
        rates: _rates,
        pieceRate: _pieceRate,
      );
      if (!f.canCalculate) {
        notDone[e.id] = f.missingRates;
        continue;
      }
      figures[e] = f;
    }

    // Leave check (same rule as the Payslip Manager): SL / AL beyond the
    // balance → ask: pay available / take off / override & pay.
    final shortfalls = <LeaveShortfall>[];
    for (final entry in figures.entries) {
      final e = entry.key;
      final existing = payslipFor(prov.payslips, e.id, _period);
      shortfalls.addAll(findLeaveShortfalls(
        employeeId: e.id,
        employeeName: e.name,
        requested: {
          LeaveType.sick: entry.value.sickLeaveHours,
          LeaveType.holiday: entry.value.holidayLeaveHours,
        },
        available: {
          LeaveType.sick:
              prov.sickLeaveBalance(e.id) + (existing?.sickLeaveHours ?? 0),
          LeaveType.holiday: prov.holidayLeaveBalance(e.id) +
              (existing?.holidayLeaveHours ?? 0),
        },
      ));
    }
    final leaveHours = <String, Map<LeaveType, double>>{};
    if (shortfalls.isNotEmpty && mounted) {
      final choices = await LeaveShortfallDialog.show(context, shortfalls);
      if (choices == null) return null;
      for (var i = 0; i < shortfalls.length; i++) {
        final s = shortfalls[i];
        leaveHours.putIfAbsent(s.employeeId, () => {})[s.type] =
            s.hoursFor(choices[i]);
      }
    }

    var saved = 0;
    for (final entry in figures.entries) {
      final e = entry.key;
      final existing = payslipFor(prov.payslips, e.id, _period);
      final ps = buildTimesheetPayslip(
        existing: existing,
        employee: e,
        period: _period,
        figures: entry.value,
        companyName: widget.companyName,
        companyAddress: settings?.companyAddress ?? '',
        uifRegNumber: settings?.uifRegNumber ?? '',
        sickLeaveHours: leaveHours[e.id]?[LeaveType.sick],
        holidayLeaveHours: leaveHours[e.id]?[LeaveType.holiday],
      );
      if (await prov.savePayslip(ps) != null) saved++;
    }
    if (mounted) setState(() => _notRecalculated = notDone);
    return saved;
  }

  Future<void> _finalise() async {
    // Payslips must be complete before the period can be locked.
    if (_notRecalculated.isNotEmpty) {
      _ratesNeededDialog();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.tsFinaliseTitle),
        content: Text(context.l10n.tsFinaliseBody(
            _rangeFmt.format(_period.start), _rangeFmt.format(_period.end))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.commonCancel)),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _green),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.tsFinalisePeriod)),
        ],
      ),
    );
    if (ok != true) return;
    if (!await _save(quiet: true)) return;
    if (_notRecalculated.isNotEmpty) {
      _ratesNeededDialog();
      return;
    }
    await _setFinalised(true);
  }

  Future<void> _unlock() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.tsUnlockTitle),
        content: Text(context.l10n.tsUnlockBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.actionUnlock)),
        ],
      ),
    );
    if (ok == true) await _setFinalised(false);
  }

  Future<void> _setFinalised(bool finalised) async {
    setState(() => _saving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      _period = _period.copyWith(
        finalised: finalised,
        finalisedAt: finalised ? DateTime.now() : null,
        finalisedBy: finalised ? auth.currentUser?.name : null,
      );
      await _service.savePeriod(_period);
      _periods = [
        for (final p in _periods) p.id == _period.id ? _period : p,
      ];
      final status =
          finalised ? PayslipStatus.finalised : PayslipStatus.draft;
      for (final e in _workers) {
        final p = payslipFor(_prov.payslips, e.id, _period);
        if (p != null && p.status != status) {
          await _prov.savePayslip(withStatus(p, status));
        }
      }
      await _service.audit(widget.companyId, _period.id,
          finalised ? 'finalise' : 'unfinalise',
          actorId: auth.currentUser?.id, actorName: auth.currentUser?.name);
      _toast(finalised
          ? context.l10n.tsFinalisedToast
          : context.l10n.tsUnlockedToast);
    } catch (e) {
      _toast(context.l10n.tsPeriodUpdateFailed('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _ratesNeededDialog() {
    final names = {
      for (final e in _workers)
        if (_notRecalculated.containsKey(e.id)) e.id: e.name,
    };
    final missing = _notRecalculated.values.expand((x) => x).toSet();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.tsNeedRatesTitle),
        content: Text(context.l10n.tsNeedRatesBody(
            names.length,
            '${names.values.take(5).join(', ')}${names.length > 5 ? '…' : ''}', // l10n-ignore: names list
            _missingLabels(missing))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.later)),
          FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (missing.contains(missingPieceRate) && _pieceRate == null) {
                  setState(() => _sheet = _Sheet.piece);
                  _addPieceRate();
                } else {
                  _editRates();
                }
              },
              child: Text(context.l10n.setThemNow)),
        ],
      ),
    );
  }

  Future<void> _editRates() async {
    final result = await showDialog<TimesheetRates>(
      context: context,
      builder: (_) => _RatesDialog(initial: _rates),
    );
    if (result == null) return;
    try {
      await _service.saveRates(widget.companyId, result);
      setState(() => _rates = result);
      _toast(context.l10n.tsRatesSaved);
      _dirty = true;
    } catch (e) {
      _toast(context.l10n.tsRatesSaveFailed('$e'));
    }
  }

  Future<void> _addPieceRate() async {
    final result = await showDialog<(String, String, double)>(
      context: context,
      builder: (_) => const _PieceRateDialog(),
    );
    if (result == null) return;
    try {
      final r = await _service.addPieceRate(
          widget.companyId, result.$1, result.$2, result.$3);
      setState(() {
        _pieceRates = [..._pieceRates, r]
          ..sort((a, b) => a.label.compareTo(b.label));
        _period = _period.copyWith(pieceRateId: r.id);
        _dirty = true;
      });
    } catch (e) {
      _toast(context.l10n.tsPieceRateAddFailed('$e'));
    }
  }

  Future<void> _choosePeriod() async {
    final now = DateTime.now();
    final options = <PayPeriodRecord>[];
    // Existing periods of this type first, then the next one to start.
    options.addAll(_periods.where((p) => p.type == _type).take(8));
    final next = options.isEmpty
        ? PayPeriodRecord.draft(widget.companyId, _type,
            _type == PeriodType.monthly
                ? DateTime(now.year, now.month, 1)
                : DateTime(now.year, now.month, now.day - (now.weekday - 1)))
        : PayPeriodRecord.draft(
            widget.companyId, _type, _type.nextStart(options.first.start));
    if (!options.any((p) => p.id == next.id)) options.insert(0, next);

    final picked = await showDialog<Object>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(context.l10n.tsPayPeriodTitle(_type.label)),
        children: [
          for (final p in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, p),
              child: Row(children: [
                Expanded(
                  child: Text(
                      '${_rangeFmt.format(p.start)} – ${_rangeFmt.format(p.end)}'),
                ),
                if (p.finalised)
                  Icon(Icons.lock_outline,
                      size: 16, color: Colors.grey.shade600)
                else if (!_periods.any((x) => x.id == p.id))
                  Text('new',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
              ]),
            ),
          const Divider(),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'pick'),
            child: Row(children: [
              const Icon(Icons.calendar_month_outlined, size: 18),
              const SizedBox(width: 8),
              Text(context.l10n.tsChooseStartDate),
            ]),
          ),
        ],
      ),
    );
    if (picked is PayPeriodRecord) {
      final existing = _periods.where((p) => p.id == picked.id);
      await _switchPeriod(existing.isNotEmpty ? existing.first : picked);
    } else if (picked == 'pick' && mounted) {
      final d = await showDatePicker(
        context: context,
        initialDate: _period.start,
        firstDate: DateTime(2020),
        lastDate: DateTime(now.year + 1, 12, 31),
        helpText: context.l10n.tsFirstDayHelp,
      );
      if (d == null) return;
      final id = PayPeriodRecord.idFor(widget.companyId, _type, d);
      final existing = _periods.where((p) => p.id == id);
      await _switchPeriod(existing.isNotEmpty
          ? existing.first
          : PayPeriodRecord.draft(widget.companyId, _type, d));
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted) {
          _dirty = false;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F5),
        appBar: AppBar(
          bottom: adminFarmAppBarBottom(context),
          backgroundColor: Theme.of(context).primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(context.l10n.tsTitle(widget.companyName),
              style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton.icon(
              onPressed: _loading ? null : _editRates,
              icon: const Icon(Icons.tune, color: Colors.white, size: 18),
              label: Text(context.l10n.tsRates,
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? _errorView()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _tabs(),
                      _toolbar(),
                      if (_notRecalculated.isNotEmpty) _ratesBanner(),
                      Expanded(child: _grid()),
                      _footer(),
                      _legend(),
                    ],
                  ),
      ),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(context.l10n.tsLoadFailed,
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(_loadError!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _loadError = null;
                });
                _bootstrap();
              },
              child: Text(context.l10n.commonRetry),
            ),
          ]),
        ),
      );

  Widget _tabs() {
    Widget tab(_Sheet s, String label) {
      final sel = _sheet == s;
      return InkWell(
        onTap: () => setState(() => _sheet = s),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: sel ? _green : Colors.transparent, width: 2.5)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? _green : Colors.grey.shade700)),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: [
        tab(_Sheet.normal, context.l10n.tsNormalHours),
        tab(_Sheet.overtime, context.l10n.tsOvertime),
        tab(_Sheet.piece, context.l10n.tsPiecework),
      ]),
    );
  }

  Widget _toolbar() {
    final locked = _period.finalised;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(context.l10n.tsPayPeriod, style: const TextStyle(fontSize: 13)),
          DropdownButton<PeriodType>(
            value: _type,
            isDense: true,
            underline: const SizedBox.shrink(),
            items: [
              for (final t in PeriodType.values)
                DropdownMenuItem(value: t, child: Text(t.label)),
            ],
            onChanged: (t) async {
              if (t == null || t == _type) return;
              setState(() => _type = t);
              await _choosePeriod();
            },
          ),
          OutlinedButton.icon(
            onPressed: _choosePeriod,
            icon: const Icon(Icons.expand_more, size: 18),
            label: Text(
                '${_rangeFmt.format(_period.start)} – ${_rangeFmt.format(_period.end)}'),
          ),
          Text(
              context.l10n.tsDaysWorkers(_workers.length, _period.days.length),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          if (_sheet == _Sheet.piece) _pieceRatePicker(locked),
          if (_sheet == _Sheet.overtime)
            Text(context.l10n.tsNsLegend,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(width: 12),
          if (_saving)
            const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
          else if (locked) ...[
            Chip(
              avatar: const Icon(Icons.lock_outline, size: 16),
              label: Text(
                  _period.finalisedBy != null
                      ? context.l10n.tsFinalisedBy(_period.finalisedBy!)
                      : context.l10n.tsFinalised),
            ),
            TextButton(onPressed: _unlock, child: Text(context.l10n.actionUnlock)),
          ] else ...[
            FilledButton(
              onPressed: () => _save(),
              style: FilledButton.styleFrom(backgroundColor: _green),
              child: Text(context.l10n.actionSave),
            ),
            OutlinedButton(
              onPressed: _finalise,
              child: Text(context.l10n.tsFinalisePeriod),
            ),
          ],
          if (_dirty && !locked)
            Text(context.l10n.unsavedChanges,
                style: TextStyle(
                    fontSize: 12, color: Colors.orange.shade800)),
        ],
      ),
    );
  }

  Widget _pieceRatePicker(bool locked) {
    final current = _pieceRate;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(context.l10n.tsPieceRate, style: const TextStyle(fontSize: 13)),
      const SizedBox(width: 8),
      DropdownButton<String>(
        value: current?.id,
        isDense: true,
        hint: Text(context.l10n.chooseEllipsis),
        underline: const SizedBox.shrink(),
        items: [
          for (final r in _pieceRates)
            DropdownMenuItem(
                value: r.id,
                child: Text('${r.label} · R ${r.rate.toStringAsFixed(2)}')),
          DropdownMenuItem(value: '__add', child: Text(context.l10n.tsAddPieceRateMenu)),
        ],
        onChanged: locked
            ? null
            : (v) {
                if (v == '__add') {
                  _addPieceRate();
                } else if (v != null) {
                  setState(() {
                    _period = _period.copyWith(pieceRateId: v);
                    _dirty = true;
                  });
                  _footerTick.value++;
                }
              },
      ),
    ]);
  }

  Widget _ratesBanner() {
    final n = _notRecalculated.length;
    final missing = _notRecalculated.values.expand((x) => x).toSet();
    return Container(
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
              context.l10n.tsNotUpdatedBanner(n, _missingLabels(missing)),
              style: TextStyle(fontSize: 13, color: Colors.amber.shade900)),
        ),
        TextButton(onPressed: _ratesNeededDialog, child: Text(context.l10n.setThemNow)),
      ]),
    );
  }

  // ── Grid ──────────────────────────────────────────────────────────────────

  static const double _nameW = 190;
  /// Missing-rate ids (from the calculation) as words, joined.
  String _missingLabels(Iterable<String> ids) {
    final l10n = context.l10n;
    return ids
        .map((id) => switch (id) {
              missingOvertime => l10n.missOvertime,
              missingNight => l10n.missNight,
              missingPieceRate => l10n.missPieceRate,
              missingMinWage => l10n.missMinWage,
              missingTopUpPeriod => l10n.missTopUp,
              missingWorkDays => l10n.missWorkDays,
              _ => id,
            })
        .join(', ');
  }

  double get _dayW => _sheet == _Sheet.normal ? 48 : 70;
  double get _rowH => _sheet == _Sheet.normal ? 42 : 56;

  List<({String label, double width})> get _totalCols {
    switch (_sheet) {
      case _Sheet.normal:
        return [
          (label: context.l10n.colHours, width: 60),
          (label: context.l10n.colLeave, width: 90),
          (label: context.l10n.colComment, width: 170),
          (label: '', width: 100),
        ];
      case _Sheet.overtime:
        return [
          (label: context.l10n.colOtHours, width: 70),
          (label: context.l10n.colNsDays, width: 64),
          (label: '', width: 100),
        ];
      case _Sheet.piece:
        return [
          (label: context.l10n.colHours, width: 60),
          (label: context.l10n.colUnits, width: 64),
          (label: context.l10n.colPiecePay, width: 90),
          (label: context.l10n.colTopUp, width: 80),
          (label: '', width: 100),
        ];
    }
  }

  Widget _grid() {
    final workers = _workers;
    if (workers.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(context.l10n.tsNoEmployees),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.tsAddEmployeesHint),
          ),
        ]),
      );
    }
    final days = _period.days;
    const headerH = 44.0;

    final nameCol = Column(children: [
      _headerCell(context.l10n.colWorker, _nameW, headerH, align: Alignment.centerLeft),
      for (final e in workers) _nameCell(e),
    ]);

    final dataCols = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          for (final d in days)
            isSaPublicHoliday(d)
                ? Tooltip(
                    message: context.l10n.tsPhTooltip,
                    child: _headerCell('PH\n${d.day}', _dayW, headerH, // l10n-ignore: sheet code
                        holiday: true),
                  )
                : d.weekday == DateTime.sunday
                    ? Tooltip(
                        message: context.l10n.tsSundayTooltip,
                        child: _headerCell(
                            '${_dayName.format(d)} 2×\n${d.day}', _dayW, headerH,
                            weekend: true),
                      )
                    : _headerCell('${_dayName.format(d)}\n${d.day}', _dayW,
                        headerH,
                        weekend: d.weekday >= 6),
          for (final c in _totalCols) _headerCell(c.label, c.width, headerH),
        ]),
        for (final e in workers) _dataRow(e, days),
      ],
    );

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nameCol,
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: dataCols,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text, double w, double h,
          {bool weekend = false,
          bool holiday = false,
          Alignment align = Alignment.center}) =>
      Container(
        width: w,
        height: h,
        alignment: align,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: holiday
              ? const Color(0xFFFDE2E1)
              : weekend
                  ? const Color(0xFFF1EDE4)
                  : const Color(0xFFEAF3EA),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B5E20))),
      );

  Widget _nameCell(EmployeeModel e) => ValueListenableBuilder<int>(
        valueListenable: _tick(e.id),
        builder: (_, __, ___) {
          final s = _sheets[e.id];
          final warnings = s == null
              ? const <String>[]
              : warningsFor(s, _rates, days: _period.dayKeys);
          // Piecework below the minimum wage → this worker shows in red.
          final below = s != null &&
              s.piece.isNotEmpty &&
              payslipFiguresFor(
                      sheets: s,
                      days: _period.dayKeys,
                      hourlyRate: e.normalHourlyRate,
                      rates: _rates,
                      pieceRate: _pieceRate)
                  .belowMinimumWage;
          return Container(
            width: _nameW,
            height: _rowH,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: below ? Colors.red.shade50 : null,
              border: Border.all(
                  color: below ? Colors.red.shade400 : Colors.grey.shade200,
                  width: below ? 1.2 : 0.5),
            ),
            child: Row(children: [
              Expanded(
                child: Tooltip(
                  message: below
                      ? context.l10n.tsBelowMinTooltip
                      : '',
                  child: Text(e.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: below ? FontWeight.w700 : null,
                          color: below ? Colors.red.shade800 : null)),
                ),
              ),
              if (below)
                Icon(Icons.trending_down,
                    size: 18, color: Colors.red.shade700),
              if (warnings.isNotEmpty)
                Tooltip(
                  message: warnings.join('\n'),
                  child: Icon(Icons.warning_amber_rounded,
                      size: 18, color: Colors.orange.shade700),
                ),
            ]),
          );
        },
      );

  Widget _dataRow(EmployeeModel e, List<DateTime> days) =>
      ValueListenableBuilder<int>(
        valueListenable: _tick(e.id),
        builder: (_, __, ___) {
          final s = _sheetsOf(e.id);
          final t = totalsFor(s, days: _period.dayKeys);
          return SizedBox(
            height: _rowH,
            child: Row(children: [
              for (final d in days) _dayCell(e, s, d),
              ..._totalCells(e, s, t),
            ]),
          );
        },
      );

  Widget _cellBox({
    required double width,
    required Widget child,
    bool weekend = false,
    bool bad = false,
    Color? tint,
  }) =>
      Container(
        width: width,
        height: _rowH,
        decoration: BoxDecoration(
          color: bad
              ? Colors.red.shade50
              : tint ?? (weekend ? const Color(0xFFFAF8F3) : null),
          border: Border.all(
              color: bad ? Colors.red.shade400 : Colors.grey.shade200,
              width: bad ? 1.2 : 0.5),
        ),
        child: child,
      );

  InputDecoration get _cellDeco => const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      );

  Widget _dayCell(EmployeeModel e, WorkerSheets s, DateTime date) {
    final key = dayKey(date);
    final weekend = date.weekday >= 6;
    final locked = _period.finalised;
    final base = '${_period.id}|${e.id}|$key';

    switch (_sheet) {
      case _Sheet.normal:
        final cellKey = '$base|n';
        final v = s.normal[key];
        return _cellBox(
          width: _dayW,
          weekend: weekend,
          bad: _badCells.contains(cellKey),
          tint: v?.code != null ? Colors.blue.shade50 : null,
          child: Center(
            child: TextFormField(
              key: ValueKey(cellKey),
              initialValue: formatNormalCell(v),
              readOnly: locked,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      v?.code != null ? FontWeight.w700 : FontWeight.w500,
                  color: v?.code != null ? Colors.blue.shade800 : null),
              decoration: _cellDeco,
              onChanged: (raw) {
                try {
                  final parsed = parseNormalCell(raw);
                  if (parsed == null) {
                    s.normal.remove(key);
                  } else {
                    s.normal[key] = parsed;
                  }
                  _setBad(cellKey, false);
                } on FormatException {
                  _setBad(cellKey, true);
                }
                _changed(e.id);
              },
            ),
          ),
        );

      case _Sheet.overtime:
        final hKey = '$base|oh';
        final fKey = '$base|of';
        final v = s.overtime[key];
        final night = v != null && v.night && v.hours > 0;
        return _cellBox(
          width: _dayW,
          weekend: weekend,
          bad: _badCells.contains(hKey) || _badCells.contains(fKey),
          tint: night ? Colors.orange.shade50 : null,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(
                width: 34,
                child: TextFormField(
                  key: ValueKey(hKey),
                  initialValue: v != null ? formatHours(v.hours) : '',
                  readOnly: locked,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  decoration: _cellDeco.copyWith(hintText: 'h'),
                  onChanged: (raw) {
                    try {
                      final h = parseHours(raw);
                      final finish = s.overtime[key]?.finish;
                      if (h == null && finish == null) {
                        s.overtime.remove(key);
                      } else {
                        s.overtime[key] =
                            OvertimeDay(hours: h ?? 0, finish: finish);
                      }
                      _setBad(hKey, false);
                    } on FormatException {
                      _setBad(hKey, true);
                    }
                    _changed(e.id);
                  },
                ),
              ),
              if (night)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('NS',
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
            ]),
            SizedBox(
              height: 20,
              child: TextFormField(
                key: ValueKey(fKey),
                initialValue: v?.finish ?? '',
                readOnly: locked,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                decoration: _cellDeco.copyWith(
                    hintText: 'hh:mm',
                    hintStyle:
                        TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    contentPadding: EdgeInsets.zero),
                onChanged: (raw) {
                  try {
                    final f = parseFinishTime(raw);
                    final h = s.overtime[key]?.hours ?? 0;
                    if (f == null && h == 0) {
                      s.overtime.remove(key);
                    } else {
                      s.overtime[key] = OvertimeDay(hours: h, finish: f);
                    }
                    _setBad(fKey, false);
                  } on FormatException {
                    _setBad(fKey, true);
                  }
                  _changed(e.id);
                },
              ),
            ),
          ]),
        );

      case _Sheet.piece:
        final hKey = '$base|ph';
        final uKey = '$base|pu';
        final v = s.piece[key];
        final unit = _pieceRate?.unitType ?? 'units';
        void store(double? h, double? u) {
          if ((h ?? 0) == 0 && (u ?? 0) == 0) {
            s.piece.remove(key);
          } else {
            s.piece[key] = PieceDay(hours: h ?? 0, units: u ?? 0);
          }
        }

        return _cellBox(
          width: _dayW,
          weekend: weekend,
          bad: _badCells.contains(hKey) || _badCells.contains(uKey),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              height: 24,
              child: TextFormField(
                key: ValueKey(hKey),
                initialValue: v != null && v.hours > 0 ? formatHours(v.hours) : '',
                readOnly: locked,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                decoration: _cellDeco.copyWith(
                    hintText: 'h', contentPadding: EdgeInsets.zero),
                onChanged: (raw) {
                  try {
                    store(parseHours(raw), s.piece[key]?.units);
                    _setBad(hKey, false);
                  } on FormatException {
                    _setBad(hKey, true);
                  }
                  _changed(e.id);
                },
              ),
            ),
            SizedBox(
              height: 20,
              child: TextFormField(
                key: ValueKey(uKey),
                initialValue: v != null && v.units > 0 ? formatHours(v.units) : '',
                readOnly: locked,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                decoration: _cellDeco.copyWith(
                    hintText: unit,
                    hintStyle:
                        TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    contentPadding: EdgeInsets.zero),
                onChanged: (raw) {
                  try {
                    store(s.piece[key]?.hours, parseUnits(raw));
                    _setBad(uKey, false);
                  } on FormatException {
                    _setBad(uKey, true);
                  }
                  _changed(e.id);
                },
              ),
            ),
          ]),
        );
    }
  }

  List<Widget> _totalCells(EmployeeModel e, WorkerSheets s, WorkerTotals t) {
    Widget total(String text, double w, {Color? color, bool bold = true}) =>
        _cellBox(
          width: w,
          tint: const Color(0xFFF3F8F3),
          child: Center(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: color ?? const Color(0xFF1B5E20))),
          ),
        );
    final cols = _totalCols;
    final link = _cellBox(width: cols.last.width, child: _viewPayslip(e));

    switch (_sheet) {
      case _Sheet.normal:
        return [
          total(formatHours(t.normalHours), cols[0].width),
          total(t.leaveSummary, cols[1].width, bold: false, color: Colors.black87),
          _cellBox(
            width: cols[2].width,
            child: TextFormField(
              key: ValueKey('${_period.id}|${e.id}|comment'),
              initialValue: s.comment,
              readOnly: _period.finalised,
              style: const TextStyle(fontSize: 12),
              decoration: _cellDeco.copyWith(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 10)),
              onChanged: (v) {
                s.comment = v;
                _changed(e.id);
              },
            ),
          ),
          link,
        ];
      case _Sheet.overtime:
        return [
          total(formatHours(t.overtimeHours), cols[0].width),
          total('${t.nightShiftDays}', cols[1].width),
          link,
        ];
      case _Sheet.piece:
        final f = (t.units > 0 || t.pieceHours > 0)
            ? payslipFiguresFor(
                sheets: s,
                days: _period.dayKeys,
                hourlyRate: e.normalHourlyRate,
                rates: _rates,
                pieceRate: _pieceRate)
            : null;
        final pay = f?.pieceEarnings;
        final top = f?.topUp;
        return [
          total(formatHours(t.pieceHours), cols[0].width),
          total(formatHours(t.units), cols[1].width),
          total(pay == null ? (f == null ? '' : 'R —') : 'R ${pay.toStringAsFixed(0)}',
              cols[2].width),
          _cellBox(
            width: cols[3].width,
            child: Center(
              child: f == null
                  ? const SizedBox.shrink()
                  : top == null
                      ? Text('—', style: TextStyle(color: Colors.grey.shade500))
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: top > 0
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(top > 0 ? context.l10n.colTopUp : context.l10n.tsOk,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: top > 0
                                      ? Colors.red.shade800
                                      : Colors.green.shade800)),
                        ),
            ),
          ),
          link,
        ];
    }
  }

  Widget _viewPayslip(EmployeeModel e) {
    final p = payslipFor(_prov.payslips, e.id, _period);
    if (p == null) {
      return Center(
        child: Text('—', style: TextStyle(color: Colors.grey.shade400)),
      );
    }
    return Center(
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          RouteConstants.payslipDetail,
          arguments: {'payslipId': p.id},
        ),
        child: Text(
          p.isFinalised ? context.l10n.viewPayslip : context.l10n.viewDraft,
          style: const TextStyle(
              fontSize: 12,
              color: _green,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _footer() => ValueListenableBuilder<int>(
        valueListenable: _footerTick,
        builder: (_, __, ___) {
          final days = _period.dayKeys;
          double hours = 0, ot = 0, units = 0;
          int leave = 0, ns = 0;
          for (final s in _sheets.values) {
            final t = totalsFor(s, days: days);
            hours += t.normalHours;
            leave += t.leaveDays;
            ot += t.overtimeHours;
            ns += t.nightShiftDays;
            units += t.units;
          }
          final String text;
          switch (_sheet) {
            case _Sheet.normal:
              text = context.l10n.tsSummaryNormal(leave, formatHours(hours));
              break;
            case _Sheet.overtime:
              text = context.l10n.tsSummaryOvertime(formatHours(ot), ns);
              break;
            case _Sheet.piece:
              text = context.l10n.tsSummaryPiece(formatHours(units)) +
                  (_pieceRate == null ? context.l10n.tsChoosePieceRateSuffix : '');
              break;
          }
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            color: const Color(0xFF1B5E20),
            child: Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 12.5)),
          );
        },
      );

  Widget _legend() {
    final String text;
    switch (_sheet) {
      case _Sheet.normal:
        text = context.l10n.tsHelpNormal;
        break;
      case _Sheet.overtime:
        text = context.l10n.tsHelpOvertime;
        break;
      case _Sheet.piece:
        text = context.l10n.tsHelpPiece;
        break;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(text,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
    );
  }
}

// ── Rates dialog ─────────────────────────────────────────────────────────────

class _RatesDialog extends StatefulWidget {
  final TimesheetRates initial;
  const _RatesDialog({required this.initial});

  @override
  State<_RatesDialog> createState() => _RatesDialogState();
}

class _RatesDialogState extends State<_RatesDialog> {
  late final _ot = TextEditingController(
      text: widget.initial.overtimeMultiplier?.toString() ?? '');
  late final _ns = TextEditingController(
      text: widget.initial.nightAllowancePercent?.toString() ?? '');
  late final _min = TextEditingController(
      text: widget.initial.minimumHourlyWage?.toString() ?? '');
  late final _day = TextEditingController(
      text: widget.initial.ordinaryDayHours.toString());
  late final _week = TextEditingController(
      text: widget.initial.weeklyOvertimeLimit.toString());
  late final _daily = TextEditingController(
      text: widget.initial.dailyHoursLimit.toString());
  late String? _topUp = widget.initial.topUpPeriod;
  late final Set<int> _workDays = {...?widget.initial.ordinaryWorkDays};

  @override
  void dispose() {
    for (final c in [_ot, _ns, _min, _day, _week, _daily]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  // Confirmed with the client (13 Nov 2026). The minimum wage changes every
  // March; top-up period and work days differ per farm, so they're not filled.
  void _fillDefaults() => setState(() {
        _ot.text = '1.5';
        _ns.text = '10';
        _min.text = '30.23';
        _day.text = '8';
        _week.text = '15';
        _daily.text = '12';
      });

  Widget _field(TextEditingController c, String label, String help) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            helperText: help,
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.tsRatesTitle),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.tsRatesConfirmedNote,
                        style: TextStyle(
                            fontSize: 12, color: Colors.amber.shade900)),
                    TextButton(
                      onPressed: _fillDefaults,
                      child: Text(context.l10n.tsFillConfirmed),
                    ),
                  ],
                ),
              ),
              _field(_ot, context.l10n.tsOtMultiplier,
                  context.l10n.tsOtMultiplierHelp),
              _field(_ns, context.l10n.tsNightAllowance,
                  context.l10n.tsNightAllowanceHelp),
              _field(_min, context.l10n.tsMinWage, context.l10n.tsMinWageHelp),
              _field(_day, context.l10n.tsDayHours, context.l10n.tsDayHoursHelp),
              _field(_week, context.l10n.tsWarnWeekLabel,
                  context.l10n.tsWarnWeekHelp),
              _field(_daily, context.l10n.tsWarnDayLabel,
                  context.l10n.tsWarnDayHelp),
              const SizedBox(height: 4),
              Text(context.l10n.tsTopUpTitle,
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                  context.l10n.tsTopUpHelp,
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                emptySelectionAllowed: true,
                segments: [
                  ButtonSegment(value: 'day', label: Text(context.l10n.perDay)),
                  ButtonSegment(value: 'week', label: Text(context.l10n.perWeek)),
                ],
                selected: {if (_topUp != null) _topUp!},
                onSelectionChanged: (v) =>
                    setState(() => _topUp = v.isEmpty ? null : v.first),
              ),
              const SizedBox(height: 16),
              Text(context.l10n.tsWorkDaysTitle,
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                  context.l10n.tsWorkDaysHelp,
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (var wd = 1; wd <= 7; wd++)
                  FilterChip(
                    label: Text(DateFormat.E()
                        .format(DateTime(2023, 1, 1 + wd))),
                    selected: _workDays.contains(wd),
                    onSelected: (on) => setState(() =>
                        on ? _workDays.add(wd) : _workDays.remove(wd)),
                  ),
              ]),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel)),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            TimesheetRates(
              overtimeMultiplier: _num(_ot),
              nightAllowancePercent: _num(_ns),
              minimumHourlyWage: _num(_min),
              ordinaryDayHours: _num(_day) ?? 8,
              weeklyOvertimeLimit: _num(_week) ?? 15,
              dailyHoursLimit: _num(_daily) ?? 12,
              topUpPeriod: _topUp,
              ordinaryWorkDays: _workDays.isEmpty
                  ? null
                  : (_workDays.toList()..sort()),
            ),
          ),
          child: Text(context.l10n.tsSaveRates),
        ),
      ],
    );
  }
}

// ── Piece-rate dialog ────────────────────────────────────────────────────────

class _PieceRateDialog extends StatefulWidget {
  const _PieceRateDialog();

  @override
  State<_PieceRateDialog> createState() => _PieceRateDialogState();
}

class _PieceRateDialogState extends State<_PieceRateDialog> {
  final _task = TextEditingController();
  final _unit =
      TextEditingController(text: LocaleProvider.instance.l10n.tsUnitDefault);
  final _rate = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _task.dispose();
    _unit.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.tsAddPieceRate),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _task,
              decoration: InputDecoration(
                  labelText: context.l10n.tsTaskOrCrop, hintText: context.l10n.tsTaskHint),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? context.l10n.tsTaskRequired : null,
            ),
            TextFormField(
              controller: _unit,
              decoration: InputDecoration(
                  labelText: context.l10n.tsUnit, hintText: context.l10n.tsUnitHint),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? context.l10n.tsUnitRequired : null,
            ),
            TextFormField(
              controller: _rate,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: context.l10n.tsRatePerUnit,
                  helperText: context.l10n.tsRatePerUnitHelp),
              validator: (v) {
                final r = double.tryParse((v ?? '').replaceAll(',', '.'));
                return r == null || r <= 0 ? context.l10n.tsRateRequired : null;
              },
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel)),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, (
              _task.text.trim(),
              _unit.text.trim(),
              double.parse(_rate.text.replaceAll(',', '.')),
            ));
          },
          child: Text(context.l10n.actionAdd),
        ),
      ],
    );
  }
}
