import 'package:cropCompliance/views/payslip/utils/leave_check.dart';
import 'package:flutter/material.dart';

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
        const Expanded(child: Text('Not enough leave left')),
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
                    ? 'This employee doesn\'t have enough leave left for what was entered. Choose what to do:'
                    : 'These employees don\'t have enough leave left for what was entered. Choose what to do for each:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              ),
              if (n > 1) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  Text('Apply to all:',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700)),
                  _allLink('Pay available', ShortfallChoice.payAvailable),
                  _allLink('Take off', ShortfallChoice.remove),
                  _allLink('Override & pay', ShortfallChoice.overridePay),
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
              'Choose an option for $undecided more',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to edit'),
        ),
        FilledButton(
          onPressed: undecided > 0
              ? null
              : () => Navigator.pop(
                  context, _choices.cast<ShortfallChoice>().toList()),
          child: const Text('Apply & save'),
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
                    ' — ${_h(s.requested)} h ${s.type.label} entered, only ${_h(s.available)} h left',
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
              'Pay only the ${_h(s.available)} h available',
              'The other ${_h(s.over)} h is left off the payslip (unpaid).',
            ),
          option(
            ShortfallChoice.remove,
            'Take the leave off',
            'No ${s.type.code} on this payslip — the ${_h(s.requested)} h is unpaid.',
          ),
          option(
            ShortfallChoice.overridePay,
            'Override & pay all ${_h(s.requested)} h',
            'Pays the full amount as ${s.type.code}; their ${s.type.code} balance goes ${_h(s.over)} h below zero.',
          ),
        ],
      ),
    );
  }
}
