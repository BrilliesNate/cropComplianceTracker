import 'package:cropCompliance/core/bank_export/bank_export_registry.dart';
import 'package:cropCompliance/models/employee_model.dart';
import 'package:cropCompliance/models/payslip_model.dart';
import 'package:cropCompliance/views/payslip/utils/bank_payment_export.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

/// Review step before downloading the bulk payment file: pick the bank,
/// set the reference, resolve any Draft payslips, see who is left out.
/// Download is only enabled when the file would have at least one row;
/// otherwise a one-line reason says why.
class BankExportDialog extends StatefulWidget {
  final List<PayslipModel> payslips;
  final List<EmployeeModel> employees;
  final String companyName;

  /// The farm's last-used bank, or null on first use (nothing pre-selected).
  final BankExportTemplate? initialTemplate;

  const BankExportDialog({
    super.key,
    required this.payslips,
    required this.employees,
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

  List<PayslipModel> get _drafts =>
      widget.payslips.where((p) => !p.isFinalised).toList()
        ..sort((a, b) => a.employeeName.compareTo(b.employeeName));

  /// Payslips that go into the file given the current draft choice.
  List<PayslipModel> get _included => _draftChoice == DraftChoice.remove
      ? widget.payslips.where((p) => p.isFinalised).toList()
      : widget.payslips;

  @override
  Widget build(BuildContext context) {
    final drafts = _drafts;
    final plan = BankPaymentExport.plan(_included, widget.employees,
        template: _template);
    final reason = BankPaymentExport.disabledReason(
      selectedCount: widget.payslips.length,
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
        width: 480,
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
              if (plan.combinedCount > 0)
                _line(Icons.merge_type, Colors.blue,
                    '${plan.combinedCount} employee${plan.combinedCount == 1 ? ' has' : 's have'} more than one payslip selected — their net pay is combined into one payment.'),
              if (plan.skipped.isNotEmpty) ...[
                _line(Icons.info_outline, Colors.grey,
                    'Not included (${plan.skipped.length}):'),
                ...plan.skipped.map((s) => Padding(
                      padding: const EdgeInsets.only(left: 30, top: 3),
                      child: Text('${s.name} — ${s.reason}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700)),
                    )),
              ],
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _green),
            onPressed: reason != null
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
