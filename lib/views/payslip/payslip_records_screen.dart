import 'package:cropCompliance/core/bank_export/bank_export_registry.dart';
import 'package:cropCompliance/models/payslip_model.dart';
import 'package:cropCompliance/providers/payslip_provider.dart';
import 'package:cropCompliance/views/payslip/utils/bank_payment_export.dart';
import 'package:cropCompliance/views/payslip/utils/payslip_bulk_export.dart';
import 'package:cropCompliance/views/payslip/utils/payslip_pdf_builder.dart';
import 'package:cropCompliance/views/payslip/widgets/bank_export_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Browse, filter, bulk-export and bulk-delete a company's payslips.
/// Filter by pay period (presets or a custom range), tick the ones you want,
/// then export them as one Excel sheet or a ZIP of PDFs — or delete them all
/// at once. Individual download/delete stay on every row.
class PayslipRecordsScreen extends StatefulWidget {
  final String companyId;
  final String companyName;

  const PayslipRecordsScreen({
    Key? key,
    required this.companyId,
    required this.companyName,
  }) : super(key: key);

  @override
  State<PayslipRecordsScreen> createState() => _PayslipRecordsScreenState();
}

enum _Preset { thisWeek, lastWeek, thisMonth, lastMonth, all, custom }

class _PayslipRecordsScreenState extends State<PayslipRecordsScreen> {
  static final _dateFmt = DateFormat('d MMM yyyy');
  static final _currency =
      NumberFormat.currency(locale: 'en_ZA', symbol: 'R ', decimalDigits: 2);

  static const _green = Color(0xFF2E7D32);

  _Preset _preset = _Preset.thisMonth;
  late DateTime _from;
  late DateTime _to;

  final Set<String> _selected = {};
  bool _busy = false;
  String? _busyLabel;

  @override
  void initState() {
    super.initState();
    _applyPreset(_Preset.thisMonth);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PayslipProvider>(context, listen: false)
          .loadForCompany(widget.companyId);
    });
  }

  // ── Date range ──────────────────────────────────────────────────────────────
  void _applyPreset(_Preset p) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (p) {
      case _Preset.thisWeek:
        final monday = today.subtract(Duration(days: today.weekday - 1));
        _from = monday;
        _to = monday.add(const Duration(days: 6));
        break;
      case _Preset.lastWeek:
        final monday = today
            .subtract(Duration(days: today.weekday - 1))
            .subtract(const Duration(days: 7));
        _from = monday;
        _to = monday.add(const Duration(days: 6));
        break;
      case _Preset.thisMonth:
        _from = DateTime(now.year, now.month, 1);
        _to = DateTime(now.year, now.month,
            DateUtils.getDaysInMonth(now.year, now.month));
        break;
      case _Preset.lastMonth:
        final m = DateTime(now.year, now.month - 1, 1);
        _from = m;
        _to = DateTime(m.year, m.month,
            DateUtils.getDaysInMonth(m.year, m.month));
        break;
      case _Preset.all:
        _from = DateTime(2000);
        _to = DateTime(2100);
        break;
      case _Preset.custom:
        break;
    }
    setState(() {
      _preset = p;
      _selected.clear();
    });
  }

  List<PayslipModel> _filtered(PayslipProvider prov) {
    final list = prov.payslips
        .where((p) =>
            p.companyId == widget.companyId &&
            !p.payPeriodEnd.isBefore(_from) &&
            !p.payPeriodStart.isAfter(_to))
        .toList()
      ..sort((a, b) {
        final c = b.payPeriodStart.compareTo(a.payPeriodStart);
        return c != 0 ? c : a.employeeName.compareTo(b.employeeName);
      });
    return list;
  }

  // ── Actions ─────────────────────────────────────────────────────────────────
  List<PayslipModel> _selectedList(PayslipProvider prov) =>
      _filtered(prov).where((p) => _selected.contains(p.id)).toList();

  Future<void> _run(String label, Future<void> Function() task) async {
    setState(() {
      _busy = true;
      _busyLabel = label;
    });
    try {
      await task();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$label failed: $e'),
            backgroundColor: Colors.grey.shade800));
      }
    } finally {
      if (mounted) setState(() { _busy = false; _busyLabel = null; });
    }
  }

  Future<void> _bulkDelete(List<PayslipModel> items) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Payslips'),
        content: Text(
            'Permanently delete ${items.length} payslip${items.length == 1 ? '' : 's'}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete ${items.length}'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final prov = Provider.of<PayslipProvider>(context, listen: false);
    await _run('Delete', () async {
      for (final p in items) {
        await prov.deletePayslip(p.id);
      }
      _selected.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${items.length} payslip${items.length == 1 ? '' : 's'} deleted'),
          backgroundColor: Colors.green.shade700));
    }
  }

  /// Review dialog → bulk payment file for online banking.
  Future<void> _bankCsv(PayslipProvider prov, List<PayslipModel> items) async {
    final result = await showDialog<BankExportDialogResult>(
      context: context,
      builder: (_) => BankExportDialog(
        payslipIds: items.map((p) => p.id).toSet(),
        companyId: widget.companyId,
        companyName: widget.companyName,
        // No bank pre-selected on first use; afterwards the farm's last choice.
        initialTemplate: BankExportRegistry.byId(
            prov.payrollSettings?.bankExportTemplateId),
      ),
    );
    if (result == null || !mounted) return;

    // Drafts the user removed are deselected here too, so the list matches.
    if (result.removedDraftIds.isNotEmpty) {
      setState(() => _selected.removeAll(result.removedDraftIds));
    }

    // Remember the bank for this farm (non-fatal if it fails).
    if (prov.payrollSettings?.bankExportTemplateId != result.template.id) {
      prov.saveBankExportTemplate(widget.companyId, result.template.id);
    }

    await _run(
        'Bank file',
        () => BankPaymentExport.download(
            result.plan, result.template, widget.companyName,
            referencePrefix: result.referencePrefix));
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F5),
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Payslip Records – ${widget.companyName}',
            style: const TextStyle(color: Colors.white)),
      ),
      body: Consumer<PayslipProvider>(
        builder: (_, prov, __) {
          // Also covers the very first frame, before the load has started.
          if (prov.isLoading || prov.loadedCompanyId != widget.companyId) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = _filtered(prov);
          final allSelected =
              items.isNotEmpty && items.every((p) => _selected.contains(p.id));
          return Column(
            children: [
              _filterBar(),
              _bulkBar(prov, items, allSelected),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? _empty()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (_, i) => _row(items[i], prov),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterBar() {
    Widget chip(String label, _Preset p) {
      final sel = _preset == p;
      return ChoiceChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) => _applyPreset(p),
        selectedColor: _green.withOpacity(0.15),
        labelStyle: TextStyle(
            fontSize: 12.5,
            color: sel ? _green : Colors.grey.shade700,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500),
        shape: StadiumBorder(
            side: BorderSide(
                color: sel ? _green : Colors.grey.shade300)),
        backgroundColor: Colors.white,
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            chip('This week', _Preset.thisWeek),
            chip('Last week', _Preset.lastWeek),
            chip('This month', _Preset.thisMonth),
            chip('Last month', _Preset.lastMonth),
            chip('All', _Preset.all),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _datePill('From', _from, (d) {
              setState(() {
                _from = d;
                _preset = _Preset.custom;
                _selected.clear();
              });
            }),
            const SizedBox(width: 8),
            _datePill('To', _to, (d) {
              setState(() {
                _to = d;
                _preset = _Preset.custom;
                _selected.clear();
              });
            }),
          ]),
        ],
      ),
    );
  }

  Widget _datePill(String label, DateTime date, ValueChanged<DateTime> onPick) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
            context: context,
            initialDate: date.year < 2001 ? DateTime.now() : date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2035));
        if (d != null) onPick(d);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('$label  ',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          Text(_preset == _Preset.all ? 'Any' : _dateFmt.format(date),
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Icon(Icons.calendar_today, size: 13, color: Colors.grey.shade500),
        ]),
      ),
    );
  }

  Widget _bulkBar(
      PayslipProvider prov, List<PayslipModel> items, bool allSelected) {
    final count = _selected.length;
    final selList = _selectedList(prov);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(children: [
        Checkbox(
          value: allSelected,
          tristate: count > 0 && !allSelected,
          onChanged: items.isEmpty
              ? null
              : (v) => setState(() {
                    if (allSelected) {
                      _selected.clear();
                    } else {
                      _selected
                        ..clear()
                        ..addAll(items.map((p) => p.id));
                    }
                  }),
        ),
        Text(
          count > 0 ? '$count selected' : '${items.length} payslips',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        if (_busy) ...[
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(children: [
              const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
              Text('${_busyLabel ?? ''}…',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ]),
          ),
        ] else
          // Scrolls sideways on narrow phones instead of overflowing.
          Expanded(
            child: Align(
             alignment: Alignment.centerRight,
             child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _barBtn(Icons.grid_on, 'Excel',
                    enabled: count > 0,
                    onTap: () => _run('Excel',
                        () => PayslipBulkExport.downloadExcel(selList, widget.companyName))),
                const SizedBox(width: 8),
                _barBtn(Icons.folder_zip_outlined, 'ZIP',
                    enabled: count > 0,
                    onTap: () => _run('ZIP',
                        () => PayslipBulkExport.downloadZip(selList, widget.companyName))),
                const SizedBox(width: 8),
                _barBtn(Icons.account_balance_outlined, 'Bank CSV',
                    enabled: count > 0,
                    onTap: () => _bankCsv(prov, selList)),
                const SizedBox(width: 8),
                _barBtn(Icons.delete_outline, 'Delete',
                    enabled: count > 0,
                    danger: true,
                    onTap: () => _bulkDelete(selList)),
              ]),
             ),
            ),
          ),
      ]),
    );
  }

  Widget _barBtn(IconData icon, String label,
      {required bool enabled, bool danger = false, required VoidCallback onTap}) {
    final color = danger ? Colors.red.shade600 : _green;
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        side: BorderSide(
            color: enabled ? color.withOpacity(0.5) : Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _row(PayslipModel p, PayslipProvider prov) {
    final sel = _selected.contains(p.id);
    return InkWell(
      onTap: () => setState(() {
        if (sel) {
          _selected.remove(p.id);
        } else {
          _selected.add(p.id);
        }
      }),
      child: Container(
        color: sel ? _green.withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          Checkbox(
            value: sel,
            onChanged: (_) => setState(() {
              if (sel) {
                _selected.remove(p.id);
              } else {
                _selected.add(p.id);
              }
            }),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.employeeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
                Text(
                    '${_dateFmt.format(p.payPeriodStart)} – ${_dateFmt.format(p.payPeriodEnd)}',
                    style:
                        TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(_currency.format(p.netSalary),
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800)),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Download PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            color: _green,
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              try {
                await PayslipPdfBuilder.downloadFile(p);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PDF error: $e')));
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red.shade400,
            visualDensity: VisualDensity.compact,
            onPressed: () => _bulkDelete([p]),
          ),
        ]),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No payslips in this date range.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ]),
      );
}
