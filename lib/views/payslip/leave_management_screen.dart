import 'package:cropCompliance/models/employee_model.dart';
import 'package:cropCompliance/models/leave_balance_model.dart';
import 'package:cropCompliance/providers/payslip_provider.dart';
import 'package:cropCompliance/views/payslip/utils/payslip_pdf_builder.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class LeaveManagementScreen extends StatefulWidget {
  final String companyId;
  final String companyName;

  const LeaveManagementScreen({
    Key? key,
    required this.companyId,
    required this.companyName,
  }) : super(key: key);

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  static const _uuid = Uuid();
  static final _numFmt = NumberFormat('#,##0.0', 'en_ZA');
  static final _dateFmt = DateFormat('d MMM yyyy');

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureLoaded() async {
    final provider = Provider.of<PayslipProvider>(context, listen: false);
    // No-op when this company's data is already loaded (or loading).
    await provider.loadForCompany(widget.companyId);
  }

  List<EmployeeModel> get _filtered {
    final provider = Provider.of<PayslipProvider>(context, listen: false);
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return provider.employees;
    return provider.employees
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.idNumber.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Leave Records – ${widget.companyName}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Consumer<PayslipProvider>(
        builder: (_, provider, __) {
          // Also covers the very first frame, before the load has started.
          if (provider.isLoading || provider.loadedCompanyId != widget.companyId) {
            return const Center(child: CircularProgressIndicator());
          }

          final employees = _filtered;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoBanner(primary, provider),
              _buildSearchBar(),
              Expanded(
                child: employees.isEmpty
                    ? Center(
                        child: Text('No employees found.',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 14)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: employees.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _buildEmployeeCard(employees[i], provider, primary),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoBanner(Color primary, PayslipProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: primary.withOpacity(0.06),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              spacing: 24,
              runSpacing: 6,
              children: [
                _legendItem(Icons.beach_access_outlined, 'HL', 'Holiday Leave',
                    Colors.orange.shade700, '1 hr per 17 hrs worked'),
                _legendItem(Icons.medical_services_outlined, 'SL', 'Sick Leave',
                    Colors.blue.shade700,
                    '1 hr per 26 hrs (pre-6mo) / 30 days per 3 yrs'),
                _legendItem(Icons.family_restroom_outlined, 'FL',
                    'Family Resp. Leave', Colors.purple.shade700,
                    '3 days/yr after 4 months (needs start date)'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: provider.employees.isEmpty
                ? null
                : () => _downloadReport(provider),
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Leave Report (PDF)',
                style: TextStyle(fontSize: 13)),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
      IconData icon, String code, String label, Color color, String rule) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(code,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500)),
            Text(rule,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        height: 38,
        child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search employees…',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            prefixIcon:
                Icon(Icons.search, size: 18, color: Colors.grey.shade400),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 14),
                    onPressed: _searchCtrl.clear,
                    splashRadius: 14,
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(
      EmployeeModel emp, PayslipProvider provider, Color primary) {
    final balance = provider.getLeaveBalance(emp.id);
    final totalHrs = provider.totalHoursWorked(emp.id);
    final hlAccrued = provider.holidayLeaveAccrued(emp.id);
    final hlUsed = provider.holidayLeaveUsed(emp.id);
    final hlBalance = provider.holidayLeaveBalance(emp.id);
    final slInSystem = provider.sickLeaveInSystem(emp.id);
    final slUsed = provider.sickLeaveUsed(emp.id);
    final slBalance = provider.sickLeaveBalance(emp.id);
    final flUsed = provider.familyLeaveUsed(emp.id);
    final flBalance = provider.familyLeaveBalance(emp.id);

    final bool isSL6mo = emp.isPostSixMonths;
    final bool isFLEligible = emp.isFamilyLeaveEligible;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primary.withOpacity(0.12),
                  child: Text(emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                      style: TextStyle(
                          color: primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emp.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Row(
                        children: [
                          Text(emp.idNumber.isNotEmpty ? emp.idNumber : 'No ID',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                          if (emp.employmentStartDate != null) ...[
                            Text(' · ', style: TextStyle(color: Colors.grey.shade400)),
                            Text(
                                'Employed ${_dateFmt.format(emp.employmentStartDate!)}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Set opening leave button
                TextButton.icon(
                  onPressed: () =>
                      _showSetOpeningLeaveDialog(emp, balance, provider),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Set opening leave',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Total hours worked
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('Hours worked in system: ',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700)),
                  Text('${_numFmt.format(totalHrs)} hrs',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Text('(drives new accrual; opening balances set separately)',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Leave balance cards
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                // Holiday leave
                _leaveCard(
                  code: 'HL',
                  label: 'Holiday Leave',
                  color: Colors.orange.shade700,
                  opening: balance.openingHolidayHours,
                  accrued: hlAccrued,
                  used: hlUsed,
                  balance: hlBalance,
                  eligible: true,
                  onAllocate: null,
                ),
                // Sick leave
                _leaveCard(
                  code: 'SL',
                  label: 'Sick Leave',
                  color: Colors.blue.shade700,
                  opening: balance.openingSickHours,
                  accrued: slInSystem,
                  used: slUsed,
                  balance: slBalance,
                  eligible: true,
                  allocatedLabel: isSL6mo ? 'Allocated (30-day batches)' : 'Accrued (1/26 hrs)',
                  onAllocate: () => _showAllocateSickLeaveDialog(
                      emp, balance, provider, isSL6mo),
                ),
                // Family leave
                _leaveCard(
                  code: 'FL',
                  label: 'Family Resp. Leave',
                  color: Colors.purple.shade700,
                  opening: balance.openingFamilyHours,
                  accrued: provider.familyLeaveEntitlement(emp.id),
                  used: flUsed,
                  balance: flBalance,
                  eligible: isFLEligible,
                  allocatedLabel: 'Entitlement (3 days/yr)',
                  onAllocate: isFLEligible
                      ? () => _showAllocateFamilyLeaveDialog(
                          emp, balance, provider)
                      : null,
                  ineligibleReason: isFLEligible
                      ? null
                      : (emp.employmentStartDate == null
                          ? 'Set employment start date to enable'
                          : 'Eligible after 4 months employment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _leaveCard({
    required String code,
    required String label,
    required Color color,
    double opening = 0,
    required double accrued,
    required double used,
    required double balance,
    required bool eligible,
    String? allocatedLabel,
    VoidCallback? onAllocate,
    String? ineligibleReason,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: eligible ? color.withOpacity(0.06) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: eligible ? color.withOpacity(0.25) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: eligible ? color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(code,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: eligible ? Colors.black87 : Colors.grey))),
              if (onAllocate != null)
                InkWell(
                  onTap: onAllocate,
                  child: Icon(Icons.add_circle_outline,
                      size: 16, color: color),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!eligible && ineligibleReason != null)
            Text(ineligibleReason,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500))
          else ...[
            if (opening > 0)
              _balanceRow('Opening (pre-system)',
                  '${_numFmt.format(opening)} hrs', color),
            _balanceRow(allocatedLabel ?? 'Accrued',
                '${_numFmt.format(accrued)} hrs', color),
            _balanceRow('Taken', '${_numFmt.format(used)} hrs', Colors.grey),
            const Divider(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Balance',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                Text(
                  '${_numFmt.format(balance)} hrs',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? color : Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _balanceRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color)),
        ],
      ),
    );
  }

  // ── Leave report ──────────────────────────────────────────────────────────

  Future<void> _downloadReport(PayslipProvider provider) async {
    final rows = provider.employees.map((e) {
      final b = provider.getLeaveBalance(e.id);
      return LeaveReportRow(
        employeeName: e.name,
        idNumber: e.idNumber,
        hlOpening: b.openingHolidayHours,
        hlAccrued: provider.holidayLeaveAccrued(e.id),
        hlTaken: provider.holidayLeaveUsed(e.id),
        hlBalance: provider.holidayLeaveBalance(e.id),
        slOpening: b.openingSickHours,
        slAccrued: provider.sickLeaveInSystem(e.id),
        slTaken: provider.sickLeaveUsed(e.id),
        slBalance: provider.sickLeaveBalance(e.id),
        flOpening: b.openingFamilyHours,
        flAccrued: provider.familyLeaveEntitlement(e.id),
        flTaken: provider.familyLeaveUsed(e.id),
        flBalance: provider.familyLeaveBalance(e.id),
      );
    }).toList();

    try {
      await PayslipPdfBuilder.downloadLeaveReport(
        companyName: widget.companyName,
        generatedOn: DateTime.now(),
        rows: rows,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('PDF error: $e'),
            backgroundColor: Colors.grey.shade800));
      }
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showSetOpeningLeaveDialog(
      EmployeeModel emp, LeaveBalanceModel balance, PayslipProvider provider) {
    final hlCtrl = TextEditingController(
        text: balance.openingHolidayHours > 0
            ? balance.openingHolidayHours.toStringAsFixed(1)
            : '');
    final slCtrl = TextEditingController(
        text: balance.openingSickHours > 0
            ? balance.openingSickHours.toStringAsFixed(1)
            : '');
    final flCtrl = TextEditingController(
        text: balance.openingFamilyHours > 0
            ? balance.openingFamilyHours.toStringAsFixed(1)
            : '');
    final primary = Theme.of(context).primaryColor;

    Widget field(TextEditingController ctrl, String label, Color color) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: label,
              hintText: 'e.g. 40',
              helperText: 'Balance in hours (8 hrs = 1 day)',
              helperStyle: const TextStyle(fontSize: 10),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 1.5),
              ),
              suffixText: 'hrs',
            ),
          ),
        );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(Icons.history_toggle_off, color: primary, size: 20),
            const SizedBox(width: 8),
            const Expanded(
                child: Text('Leave Accumulated Before Using the System',
                    style: TextStyle(fontSize: 16))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For ${emp.name} — enter the leave this employee had already '
                'banked BEFORE you started using the app. This is the opening '
                'balance; the system adds new accrual on top and subtracts '
                'leave taken. Enter each type separately — holiday and sick '
                'leave are not the same.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              field(hlCtrl, 'Holiday Leave (HL) opening',
                  Colors.orange.shade700),
              field(slCtrl, 'Sick Leave (SL) opening', Colors.blue.shade700),
              field(flCtrl, 'Family Resp. Leave (FL) opening',
                  Colors.purple.shade700),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final hl = double.tryParse(hlCtrl.text.trim()) ?? 0;
              final sl = double.tryParse(slCtrl.text.trim()) ?? 0;
              final fl = double.tryParse(flCtrl.text.trim()) ?? 0;
              if (hl < 0 || sl < 0 || fl < 0) return;
              final updated = balance.copyWith(
                openingHolidayHours: hl,
                openingSickHours: sl,
                openingFamilyHours: fl,
              );
              await provider.saveLeaveBalance(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAllocateSickLeaveDialog(EmployeeModel emp, LeaveBalanceModel balance,
      PayslipProvider provider, bool isPostSixMonths) {
    final primary = Theme.of(context).primaryColor;
    final existingAllocations = balance.sickLeaveAllocations;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
                  child: Row(
                    children: [
                      Icon(Icons.medical_services_outlined,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sick Leave Allocation – ${emp.name}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            Text(
                              isPostSixMonths
                                  ? 'Employee has passed 6 months — grant 30-day batches'
                                  : 'Pre-6 months: auto-accrues 1 hr per 26 hrs worked',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
                const Divider(height: 20),
                if (existingAllocations.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Previous allocations',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700)),
                  ),
                  const SizedBox(height: 6),
                  ...existingAllocations.map((a) => ListTile(
                        dense: true,
                        leading: Icon(Icons.check_circle_outline,
                            size: 16, color: Colors.blue.shade600),
                        title: Text(
                            '${_numFmt.format(a.hours)} hrs on ${_dateFmt.format(a.allocatedOn)}',
                            style: const TextStyle(fontSize: 13)),
                        subtitle: a.note.isNotEmpty
                            ? Text(a.note,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600))
                            : null,
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 16, color: Colors.red.shade300),
                          onPressed: () async {
                            final updated = balance.copyWith(
                              sickLeaveAllocations: existingAllocations
                                  .where((x) => x.id != a.id)
                                  .toList(),
                            );
                            await provider.saveLeaveBalance(updated);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        ),
                      )),
                  const Divider(height: 16),
                ],
                if (isPostSixMonths)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildAddAllocationForm(
                        ctx, emp, balance, provider, setDlgState, primary),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        'Sick leave is auto-calculated at 1 hour per 26 hours worked. '
                        'No manual allocation needed until 6 months of employment.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.blue.shade800),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddAllocationForm(BuildContext ctx, EmployeeModel emp,
      LeaveBalanceModel balance, PayslipProvider provider,
      StateSetter setDlgState, Color primary) {
    final hrsCtrl = TextEditingController(text: '240'); // 30 days × 8 hrs
    final noteCtrl = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Grant new 30-day sick leave batch',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: hrsCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Hours',
                  hintText: '240 (= 30 days × 8 hrs)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              final hrs = double.tryParse(hrsCtrl.text);
              if (hrs == null || hrs <= 0) return;
              final newAlloc = SickLeaveAllocation(
                id: _uuid.v4(),
                allocatedOn: DateTime.now(),
                hours: hrs,
                note: noteCtrl.text.trim(),
              );
              final updated = balance.copyWith(
                sickLeaveAllocations: [
                  ...balance.sickLeaveAllocations,
                  newAlloc
                ],
              );
              await provider.saveLeaveBalance(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
            icon: const Icon(Icons.add, color: Colors.white, size: 16),
            label: const Text('Grant Sick Leave',
                style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  void _showAllocateFamilyLeaveDialog(EmployeeModel emp,
      LeaveBalanceModel balance, PayslipProvider provider) {
    final primary = Theme.of(context).primaryColor;
    final hrsCtrl = TextEditingController(
        text: balance.familyLeaveAllocatedHours > 0
            ? balance.familyLeaveAllocatedHours.toStringAsFixed(1)
            : '24'); // 3 days × 8 hrs default

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.family_restroom_outlined,
                color: Colors.purple.shade700, size: 20),
            const SizedBox(width: 8),
            const Text('Family Resp. Leave'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${emp.name} — allocate annual family responsibility leave. '
              'SA law provides 3 days per year for employees employed > 4 months.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: hrsCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Hours allocated',
                hintText: '24 (= 3 days × 8 hrs)',
                helperText: 'Typically 24 hrs (3 working days at 8 hrs/day)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixText: 'hrs',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final hrs = double.tryParse(hrsCtrl.text);
              if (hrs == null || hrs <= 0) return;
              final updated = balance.copyWith(
                familyLeaveAllocatedHours: hrs,
                familyLeaveAllocYear: DateTime.now(),
              );
              await provider.saveLeaveBalance(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
                backgroundColor: Colors.purple.shade700),
            child: const Text('Allocate'),
          ),
        ],
      ),
    );
  }
}
