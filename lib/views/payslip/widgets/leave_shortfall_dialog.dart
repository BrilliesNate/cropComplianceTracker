import 'package:cropCompliance/views/payslip/utils/leave_check.dart';
import 'package:flutter/material.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// Shown when payslips include more leave than an employee has left. Lists
/// each case by name and lets the user decide, per case: pay only what's
/// available, take the leave off (unpaid), or override and pay it all.
///
/// Returns the choice per shortfall (same order), or null if the user went
/// back to edit instead.
class LeaveShortfallDialog extends StatefulWidget {
  final List<LeaveShortfall> shortfalls;

  const LeaveShortfallDialog({super.key, required this.shortfalls});

  static Future<List<ShortfallChoice>?> show(
          BuildContext context, List<LeaveShortfall> shortfalls) =>
      showDialog<List<ShortfallChoice>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => LeaveShortfallDialog(shortfalls: shortfalls),
      );

  @override
  State<LeaveShortfallDialog> createState() => _LeaveShortfallDialogState();
}

class _LeaveShortfallDialogState extends State<LeaveShortfallDialog> {
  late final List<ShortfallChoice?> _choices =
      List.filled(widget.shortfalls.length, null);

  String _h(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  void _setAll(ShortfallChoice c) =>
      setState(() => _choices.fillRange(0, _choices.length, c));

  @override
  Widget build(BuildContext context) {
    final undecided = _choices.where((c) => c == null).length;
    final n = widget.shortfalls.length;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(children: [
        Icon(Icons.event_busy_outlined, color: Colors.orange.shade800),
        const SizedBox(width: 10),
        Expanded(child: Text(context.l10n.shortfallTitle)),
      ]),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                n == 1
                    ? context.l10n.shortfallOne
                    : context.l10n.shortfallMany,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              ),
              if (n > 1) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  Text(context.l10n.applyToAll,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700)),
                  _allLink(context.l10n.payAvailable, ShortfallChoice.payAvailable),
                  _allLink(context.l10n.takeOff, ShortfallChoice.remove),
                  _allLink(context.l10n.overridePay, ShortfallChoice.overridePay),
                ]),
              ],
              const SizedBox(height: 8),
              for (var i = 0; i < n; i++) _card(i),
            ],
          ),
        ),
      ),
      actions: [
        if (undecided > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              context.l10n.chooseForMore(undecided),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.backToEdit),
        ),
        FilledButton(
          onPressed: undecided > 0
              ? null
              : () => Navigator.pop(
                  context, _choices.cast<ShortfallChoice>().toList()),
          child: Text(context.l10n.applyAndSave),
        ),
      ],
    );
  }

  Widget _allLink(String label, ShortfallChoice c) => InkWell(
        onTap: () => _setAll(c),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).primaryColor,
                decoration: TextDecoration.underline)),
      );

  /// Leave code in the app language (SL / HL / FL ↔ SV / VV / GV).
  String _code(LeaveType t) => switch (t) {
        LeaveType.sick => context.l10n.leaveCodeSL,
        LeaveType.holiday => context.l10n.leaveCodeHL,
        LeaveType.family => context.l10n.leaveCodeFL,
      };

  Widget _card(int i) {
    final s = widget.shortfalls[i];
    final choice = _choices[i];
    Widget option(ShortfallChoice c, String title, String subtitle) {
      final selected = choice == c;
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _choices[i] = c),
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                width: selected ? 1.6 : 1),
            color: selected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.06)
                : null,
          ),
          child: Row(children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: selected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade500),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700)),
                ],
              ),
            ),
          ]),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(
                text: s.employeeName,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            TextSpan(
                text:
                    context.l10n.shortfallLine(_h(s.requested), s.type.label, _h(s.available)),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
          ])),
          if (s.note != null) ...[
            const SizedBox(height: 4),
            Text(s.note!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
          if (s.available > 0)
            option(
              ShortfallChoice.payAvailable,
              context.l10n.shortfallPayAvailableTitle(_h(s.available)),
              context.l10n.shortfallPayAvailableSub(_h(s.over)),
            ),
          option(
            ShortfallChoice.remove,
            context.l10n.shortfallTakeOffTitle,
            context.l10n.shortfallTakeOffSub(_code(s.type), _h(s.requested)),
          ),
          option(
            ShortfallChoice.overridePay,
            context.l10n.shortfallOverrideTitle(_h(s.requested)),
            context.l10n.shortfallOverrideSub(_code(s.type), _h(s.over)),
          ),
        ],
      ),
    );
  }
}
