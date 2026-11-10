import 'package:cropCompliance/core/bank_export/bank_export_registry.dart';
import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/models/employee_model.dart';
import 'package:cropCompliance/models/payslip_model.dart';
import 'package:cropCompliance/providers/payslip_provider.dart';
import 'package:cropCompliance/views/payslip/utils/bank_payment_export.dart';
import 'package:cropCompliance/views/payslip/widgets/employee_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// What the user confirmed in [BankExportDialog].
class BankExportDialogResult {
  final BankExportTemplate template;
  final String referencePrefix;
  final BankPaymentPlan plan;

  /// Draft payslips the user removed from this export (to deselect them).
  final Set<String> removedDraftIds;

  BankExportDialogResult({
    required this.template,
    required this.referencePrefix,
    required this.plan,
    required this.removedDraftIds,
  });
}

/// Review step before downloading the bulk payment file: pick the bank, set
/// the reference, resolve Draft payslips and fix anyone who can't be paid.
///
/// Product rule: whenever something can't be done, offer the way forward
/// right here — every "Not included" row has a fix button, and if nobody can
/// be paid the dialog leads with a step-through call to action. Fixes save
/// immediately and the export recalculates live (it reads the provider).
class BankExportDialog extends StatefulWidget {
  /// The selected payslips (by id — read live so fixes are picked up).
  final Set<String> payslipIds;
  final String companyId;
  final String companyName;

  /// The farm's last-used bank, or null on first use (nothing pre-selected).
  final BankExportTemplate? initialTemplate;

  const BankExportDialog({
    super.key,
    required this.payslipIds,
    required this.companyId,
    required this.companyName,
    this.initialTemplate,
  });

  @override
  State<BankExportDialog> createState() => _BankExportDialogState();
}

class _BankExportDialogState extends State<BankExportDialog> {
  static const _green = Color(0xFF2E7D32);
  static final _currency =
      NumberFormat.currency(locale: 'en_ZA', symbol: 'R ', decimalDigits: 2);
  static final _date = DateFormat('d MMM');

  late final TextEditingController _refCtrl;
  BankExportTemplate? _template;
  DraftChoice _draftChoice = DraftChoice.undecided;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _refCtrl = TextEditingController(
        text: BankExportTemplate.defaultReferencePrefix);
    _template = widget.initialTemplate;
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    super.dispose();
  }

  PayslipProvider get _prov =>
      Provider.of<PayslipProvider>(context, listen: false);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PayslipProvider>();
    final selected = prov.payslips
        .where((p) => widget.payslipIds.contains(p.id))
        .toList();
    final drafts = selected.where((p) => !p.isFinalised).toList()
      ..sort((a, b) => a.employeeName.compareTo(b.employeeName));
    final included = _draftChoice == DraftChoice.remove
        ? selected.where((p) => p.isFinalised).toList()
        : selected;
    final plan =
        BankPaymentExport.plan(included, prov.employees, template: _template);
    final reason = BankPaymentExport.disabledReason(
      selectedCount: selected.length,
      bankChosen: _template != null,
      draftCount: drafts.length,
      draftChoice: _draftChoice,
      plan: plan,
    );
    final note = _template?.userNote;
    final sample = plan.ready.isEmpty
        ? null
        : (_template ?? BankExportRegistry.all.first).reference(
            plan.ready.first.line,
            BankExportContext(
                payerName: widget.companyName,
                referencePrefix: _refCtrl.text));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Bulk Payment File'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.ready.isEmpty
                    ? 'No payments yet'
                    : '${plan.ready.length} payment${plan.ready.length == 1 ? '' : 's'} · total ${_currency.format(plan.total)}',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Upload the file to your online banking as a bulk payment, '
                'check the total, then approve once.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (plan.ready.isEmpty && plan.skipped.isNotEmpty)
                _nobodyPayableCta(plan),
              const SizedBox(height: 14),
              _bankPicker(),
              if (note != null) _smallNote(note),
              const SizedBox(height: 14),
              TextField(
                controller: _refCtrl,
                maxLength: 15,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Reference',
                  helperText: sample == null
                      ? 'Each employee\'s first name is added'
                      : 'Each employee\'s first name is added — e.g. "$sample"',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
              if (drafts.isNotEmpty) _draftsPanel(drafts),
              if (plan.relinks.isNotEmpty) _relinksNote(plan),
              if (plan.combinedCount > 0)
                _line(Icons.merge_type, Colors.blue,
                    '${plan.combinedCount} employee${plan.combinedCount == 1 ? ' has' : 's have'} more than one payslip selected — their net pay is combined into one payment.'),
              if (plan.skipped.isNotEmpty) _notIncluded(plan),
            ],
          ),
        ),
      ),
      actions: [
        if (reason != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Icon(Icons.info_outline, size: 15, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(reason,
                    style: TextStyle(
                        fontSize: 12.5, color: Colors.grey.shade800)),
              ),
            ]),
          ),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (_working)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _green),
            onPressed: reason != null || _working
                ? null
                : () => Navigator.pop(
                      context,
                      BankExportDialogResult(
                        template: _template!,
                        referencePrefix: _refCtrl.text,
                        plan: plan,
                        removedDraftIds: _draftChoice == DraftChoice.remove
                            ? drafts.map((p) => p.id).toSet()
                            : const <String>{},
                      ),
                    ),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download file'),
          ),
        ]),
      ],
    );
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  Widget _bankPicker() => DropdownButtonFormField<String>(
        initialValue: _template?.id,
        isExpanded: true,
        hint: const Text('Choose your bank'),
        decoration: InputDecoration(
          labelText: 'Bank the farm pays from',
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
        items: BankExportRegistry.all
            .map((t) =>
                DropdownMenuItem(value: t.id, child: Text(t.displayName)))
            .toList(),
        onChanged: (id) =>
            setState(() => _template = BankExportRegistry.byId(id)),
      );

  /// Shown when nobody can be paid: lead with the fix, not a dead end.
  Widget _nobodyPayableCta(BankPaymentPlan plan) {
    final banking = plan.skipped.where((s) => s.kind.isBankingFix).toList();
    final missing = plan.skipped
        .where((s) => s.kind == SkipKind.missingEmployee)
        .toList();
    final payslipFix = plan.skipped
        .where((s) => s.kind == SkipKind.nonPositivePay)
        .toList();

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _green.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nobody can be paid yet — let\'s fix that',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Each fix saves straight away and this list updates as you go.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (banking.isNotEmpty)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _green),
                onPressed: _working ? null : () => _stepThrough(banking),
                icon: const Icon(Icons.account_balance_outlined, size: 18),
                label: Text(
                    'Add banking details for ${banking.length} employee${banking.length == 1 ? '' : 's'}'),
              ),
            if (missing.isNotEmpty)
              FilledButton.tonalIcon(
                onPressed: _working ? null : () => _stepThrough(missing),
                icon: const Icon(Icons.person_search_outlined, size: 18),
                label: Text(
                    'Fix ${missing.length} unlinked payslip${missing.length == 1 ? '' : 's'}'),
              ),
            if (payslipFix.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _working ? null : () => _stepThrough(payslipFix),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(
                    'Review ${payslipFix.length} R 0 payslip${payslipFix.length == 1 ? '' : 's'}'),
              ),
          ]),
        ],
      ),
    );
  }

  /// Per-employee reasons, each with its own fix button.
  Widget _notIncluded(BankPaymentPlan plan) {
    final banking = plan.skipped.where((s) => s.kind.isBankingFix).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Not included (${plan.skipped.length})',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900)),
            ),
            if (plan.ready.isNotEmpty && banking.length > 1)
              TextButton(
                onPressed: _working ? null : () => _stepThrough(banking),
                child: Text('Add banking details for all ${banking.length}'),
              ),
          ]),
          ...plan.skipped.map(_skipRow),
        ],
      ),
    );
  }

  Widget _skipRow(BankPaymentSkip s) {
    final actions = <Widget>[];
    switch (s.kind) {
      case SkipKind.noBankingDetails:
        actions.add(_rowButton('Add banking details', () => _fix(s)));
        break;
      case SkipKind.invalidBankingDetails:
        actions.add(_rowButton('Fix banking details', () => _fix(s)));
        break;
      case SkipKind.missingEmployee:
        actions.add(_rowButton('Link to employee', () => _linkToEmployee(s)));
        actions.add(_rowButton('Re-create', () => _recreateEmployee(s)));
        break;
      case SkipKind.nonPositivePay:
        actions.add(_rowButton('Edit payslip', () => _editPayslip(s)));
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          child: Text.rich(TextSpan(children: [
            TextSpan(
                text: s.name,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600)),
            TextSpan(
                text: ' — ${s.reason}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ])),
        ),
        ...actions,
      ]),
    );
  }

  Widget _rowButton(String label, Future<bool> Function() onTap) => TextButton(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          foregroundColor: _green,
        ),
        onPressed: _working ? null : onTap,
        child: Text(label, style: const TextStyle(fontSize: 12.5)),
      );

  /// Payslips whose employee record was removed but which we matched to a
  /// current employee by ID number / name. Offer to make that permanent.
  Widget _relinksNote(BankPaymentPlan plan) {
    final n = plan.relinks.length;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.link, size: 18, color: Colors.blue.shade700),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$n payslip${n == 1 ? ' was' : 's were'} linked to a removed '
            'employee record — matched to the current employee by ID number '
            'or name.',
            style: TextStyle(fontSize: 12.5, color: Colors.blue.shade900),
          ),
        ),
        TextButton(
          onPressed: _working ? null : () => _saveRelinks(plan),
          child: const Text('Save links'),
        ),
      ]),
    );
  }

  /// Lists the Draft payslips by name with one-click Remove / Include.
  Widget _draftsPanel(List<PayslipModel> drafts) {
    final n = drafts.length;
    final undecided = _draftChoice == DraftChoice.undecided;
    final removed = _draftChoice == DraftChoice.remove;

    final String title;
    if (undecided) {
      title = '$n selected payslip${n == 1 ? ' is' : 's are'} still Draft '
          '— amounts may still change:';
    } else if (removed) {
      title = '$n draft payslip${n == 1 ? '' : 's'} removed from this export:';
    } else {
      title = '$n draft payslip${n == 1 ? '' : 's'} included as they are now:';
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: undecided ? Colors.orange.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: undecided ? Colors.orange.shade200 : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.edit_note,
                size: 18,
                color: undecided
                    ? Colors.orange.shade800
                    : Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: undecided
                          ? Colors.orange.shade900
                          : Colors.grey.shade800)),
            ),
          ]),
          const SizedBox(height: 4),
          ...drafts.map((p) => Padding(
                padding: const EdgeInsets.only(left: 26, top: 2),
                child: Text(
                  '${p.employeeName} · ${_date.format(p.payPeriodStart)}–'
                  '${_date.format(p.payPeriodEnd)} · '
                  '${_currency.format(p.netSalary)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade800,
                      decoration:
                          removed ? TextDecoration.lineThrough : null),
                ),
              )),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 4, children: [
            if (undecided) ...[
              FilledButton.tonal(
                onPressed: () =>
                    setState(() => _draftChoice = DraftChoice.remove),
                child: Text('Remove draft${n == 1 ? '' : 's'}'),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _draftChoice = DraftChoice.include),
                child: const Text('Include anyway'),
              ),
            ] else
              TextButton(
                onPressed: () =>
                    setState(() => _draftChoice = DraftChoice.undecided),
                child: const Text('Undo'),
              ),
          ]),
        ],
      ),
    );
  }

  // ── Fixes (each saves immediately; the plan recalculates live) ────────────

  /// Opens the right fix for one skipped row. Returns true if it was fixed.
  Future<bool> _fix(BankPaymentSkip s) {
    switch (s.kind) {
      case SkipKind.noBankingDetails:
      case SkipKind.invalidBankingDetails:
        return _editBanking(s.employee!);
      case SkipKind.missingEmployee:
        return _resolveMissing(s);
      case SkipKind.nonPositivePay:
        return _editPayslip(s);
    }
  }

  /// Walks through [rows] one at a time; stops if the user cancels one.
  Future<void> _stepThrough(List<BankPaymentSkip> rows) async {
    for (final s in rows) {
      if (!mounted) return;
      final done = await _fix(s);
      if (!done) break;
    }
  }

  /// The employee form, banking section first, on top of this dialog.
  Future<bool> _editBanking(EmployeeModel e) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (dctx) => EmployeeFormDialog(
        companyId: widget.companyId,
        employee: e,
        title: 'Banking details — ${e.name}',
        bankingFirst: true,
        onSave: (emp) async {
          final ok = await _prov.saveEmployee(emp);
          if (!dctx.mounted) return;
          if (ok) {
            Navigator.of(dctx).pop(true);
          } else {
            _toast('Could not save: ${_prov.error ?? 'unknown error'}');
          }
        },
      ),
    );
    return saved == true;
  }

  /// For a payslip with no employee record: ask whether to link it to an
  /// existing employee or re-create the employee.
  Future<bool> _resolveMissing(BankPaymentSkip s) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(s.name),
        content: const Text(
            'This payslip is linked to an employee record that no longer '
            'exists (the employee was probably removed). Link it to a '
            'current employee, or re-create the employee from the payslip.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Skip')),
          TextButton(
              onPressed: () => Navigator.pop(dctx, 'link'),
              child: const Text('Link to employee')),
          FilledButton(
              onPressed: () => Navigator.pop(dctx, 'recreate'),
              child: const Text('Re-create employee')),
        ],
      ),
    );
    if (choice == 'link') return _linkToEmployee(s);
    if (choice == 'recreate') return _recreateEmployee(s);
    return false;
  }

  /// Pick a current employee and point this row's payslips at them.
  Future<bool> _linkToEmployee(BankPaymentSkip s) async {
    final employees = [..._prov.employees]
      ..sort((a, b) => a.name.compareTo(b.name));
    if (employees.isEmpty) return _recreateEmployee(s);

    // Returns an EmployeeModel, the string 'recreate', or null (dismissed).
    final picked = await showDialog<Object>(
      context: context,
      builder: (dctx) => SimpleDialog(
        title: Text('Link "${s.name}" to…'),
        children: [
          SizedBox(
            width: 380,
            height: 360,
            child: ListView(
              children: employees
                  .map((e) => ListTile(
                        dense: true,
                        title: Text(e.name),
                        subtitle: Text(e.idNumber.isNotEmpty
                            ? 'ID ${e.idNumber}'
                            : 'No ID number'),
                        trailing: e.hasBankingDetails
                            ? Icon(Icons.account_balance_outlined,
                                size: 16, color: Colors.grey.shade500)
                            : null,
                        onTap: () => Navigator.pop(dctx, e),
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TextButton.icon(
              onPressed: () => Navigator.pop(dctx, 'recreate'),
              icon: const Icon(Icons.person_add_alt, size: 18),
              label: const Text('Not listed? Re-create the employee instead'),
            ),
          ),
        ],
      ),
    );
    if (picked == 'recreate') {
      return mounted ? _recreateEmployee(s) : false;
    }
    if (picked is! EmployeeModel) return false; // dismissed
    final ok = await _busy(() =>
        _prov.relinkPayslips(s.payslips.map((p) => p.id), picked.id));
    if (!ok) _toast('Could not link: ${_prov.error ?? 'unknown error'}');
    return ok;
  }

  /// New employee pre-filled from the payslip snapshot (name, ID number,
  /// rate, job, type), banking first; then the payslips are linked to it.
  Future<bool> _recreateEmployee(BankPaymentSkip s) async {
    final p = s.payslips.first;
    final draft = EmployeeModel(
      id: '', // always a new record — never overwrite an unknown doc
      companyId: widget.companyId,
      name: p.employeeName,
      idNumber: p.employeeIdNumber,
      normalHourlyRate: p.normalRate,
      employmentType: p.employmentType,
      jobDescription: p.jobDescription,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    EmployeeModel? created;
    await showDialog<bool>(
      context: context,
      builder: (dctx) => EmployeeFormDialog(
        companyId: widget.companyId,
        employee: draft,
        title: 'Re-create employee',
        bankingFirst: true,
        onSave: (emp) async {
          created = await _prov.upsertEmployee(emp);
          if (!dctx.mounted) return;
          if (created != null) {
            Navigator.of(dctx).pop(true);
          } else {
            _toast('Could not save: ${_prov.error ?? 'unknown error'}');
          }
        },
      ),
    );
    if (created == null) return false;
    final ok = await _busy(() =>
        _prov.relinkPayslips(s.payslips.map((p) => p.id), created!.id));
    if (!ok) _toast('Employee saved, but linking payslips failed.');
    return ok;
  }

  /// Opens the payslip form on top; the plan recalculates on return.
  Future<bool> _editPayslip(BankPaymentSkip s) async {
    await Navigator.of(context).pushNamed(
      RouteConstants.payslipForm,
      arguments: {
        'payslipId': s.payslips.first.id,
        'companyId': widget.companyId,
        'companyName': widget.companyName,
      },
    );
    if (!mounted) return false;
    final still = _prov.getPayslipById(s.payslips.first.id);
    return still != null && still.netSalary > 0;
  }

  Future<void> _saveRelinks(BankPaymentPlan plan) async {
    final byEmployee = <String, List<String>>{};
    plan.relinks.forEach((payslipId, emp) =>
        byEmployee.putIfAbsent(emp.id, () => []).add(payslipId));
    var ok = true;
    await _busy(() async {
      for (final e in byEmployee.entries) {
        ok = await _prov.relinkPayslips(e.value, e.key) && ok;
      }
      return ok;
    });
    _toast(ok ? 'Payslip links saved' : 'Some links could not be saved');
  }

  Future<bool> _busy(Future<bool> Function() task) async {
    setState(() => _working = true);
    try {
      return await task();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Small pieces ──────────────────────────────────────────────────────────

  Widget _smallNote(String text) => Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, size: 14, color: Colors.amber.shade800),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style:
                    TextStyle(fontSize: 11.5, color: Colors.amber.shade900)),
          ),
        ]),
      );

  Widget _line(IconData icon, MaterialColor color, String text) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: color.shade700),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 12.5, color: color.shade900))),
        ]),
      );
}
