import 'package:cropCompliance/views/shared/admin_farm_chip.dart';
import 'package:cropCompliance/models/employee_model.dart';
import 'package:cropCompliance/models/leave_balance_model.dart';
import 'package:cropCompliance/providers/payslip_provider.dart';
import 'package:cropCompliance/views/payslip/utils/payslip_pdf_builder.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

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
  static DateFormat get _dateFmt => DateFormat('d MMM yyyy'); // follows the app language

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
        bottom: adminFarmAppBarBottom(context),
        backgroundColor: primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.l10n.leaveRecordsTitle(widget.companyName),
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
                        child: Text(context.l10n.noEmployeesFoundDot,
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
                _legendItem(Icons.beach_access_outlined, context.l10n.leaveCodeHL,
                    context.l10n.leaveHoliday, Colors.orange.shade700,
                    context.l10n.leaveHolidayRule),
                _legendItem(Icons.medical_services_outlined, context.l10n.leaveCodeSL,
                    context.l10n.leaveSickTitle, Colors.blue.shade700,
                    context.l10n.leaveSickRule),
                _legendItem(Icons.family_restroom_outlined, context.l10n.leaveCodeFL,
                    context.l10n.leaveFamilyTitle, Colors.purple.shade700,
                    context.l10n.leaveFamilyRule),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: provider.employees.isEmpty
                ? null
                : () => _downloadReport(provider),
            icon: const Icon(Icons.download_outlined, size: 16),
            label: Text(context.l10n.leaveReportPdf,
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
            hintText: context.l10n.searchEmployees,
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
                          Text(emp.idNumber.isNotEmpty ? emp.idNumber : context.l10n.employeeNoId,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                          if (emp.employmentStartDate != null) ...[
                            Text(' · ', style: TextStyle(color: Colors.grey.shade400)),
                            Text(
                                context.l10n.employedSince(_dateFmt.format(emp.employmentStartDate!)),
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
                  label: Text(context.l10n.setOpeningLeave,
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
                  Text(context.l10n.hoursWorkedInSystem,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700)),
                  Text(context.l10n.hoursAmount(_numFmt.format(totalHrs)),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Text(context.l10n.accrualNote,
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
                  label: context.l10n.leaveHoliday,
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
                  label: context.l10n.leaveSickTitle,
                  color: Colors.blue.shade700,
                  opening: balance.openingSickHours,
                  accrued: slInSystem,
                  used: slUsed,
                  balance: slBalance,
                  eligible: true,
                  allocatedLabel: isSL6mo ? context.l10n.allocated30Day : context.l10n.accrued126,
                  onAllocate: () => _showAllocateSickLeaveDialog(
                      emp, balance, provider, isSL6mo),
                ),
                // Family leave
                _leaveCard(
                  code: 'FL',
                  label: context.l10n.leaveFamilyTitle,
                  color: Colors.purple.shade700,
                  opening: balance.openingFamilyHours,
                  accrued: provider.familyLeaveEntitlement(emp.id),
                  used: flUsed,
                  balance: flBalance,
                  eligible: isFLEligible,
                  allocatedLabel: context.l10n.entitlement3Days,
                  onAllocate: isFLEligible
                      ? () => _showAllocateFamilyLeaveDialog(
                          emp, balance, provider)
                      : null,
                  ineligibleReason: isFLEligible
                      ? null
                      : (emp.employmentStartDate == null
                          ? context.l10n.setStartDateToEnable
                          : context.l10n.eligibleAfter4Months),
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
              _balanceRow(context.l10n.openingPreSystem,
                  context.l10n.hoursAmount(_numFmt.format(opening)), color),
            _balanceRow(allocatedLabel ?? context.l10n.accrued,
                context.l10n.hoursAmount(_numFmt.format(accrued)), color),
            _balanceRow(context.l10n.taken,
                context.l10n.hoursAmount(_numFmt.format(used)), Colors.grey),
            const Divider(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.l10n.balance,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                Text(
                  context.l10n.hoursAmount(_numFmt.format(balance)),
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
            content: Text(context.l10n.pdfError('$e')),
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
              helperText: context.l10n.balanceHoursHelp,
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
            Expanded(
                child: Text(context.l10n.openingLeaveTitle,
                    style: TextStyle(fontSize: 16))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.openingLeaveBody(emp.name),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              field(hlCtrl, context.l10n.openingHL,
                  Colors.orange.shade700),
              field(slCtrl, context.l10n.openingSL, Colors.blue.shade700),
              field(flCtrl, context.l10n.openingFL,
                  Colors.purple.shade700),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.commonCancel)),
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
            child: Text(context.l10n.actionSave),
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
                            Text(context.l10n.sickAllocationTitle(emp.name),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            Text(
                              isPostSixMonths
                                  ? context.l10n.sickPost6Months
                                  : context.l10n.sickPre6Months,
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
                    child: Text(context.l10n.previousAllocations,
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
                            context.l10n.hoursOnDate(_numFmt.format(a.hours), _dateFmt.format(a.allocatedOn)),
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
                        context.l10n.sickAutoNote,
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
        Text(context.l10n.grantSickBatch,
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
                  labelText: context.l10n.colHours,
                  hintText: context.l10n.hours240Hint,
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
                  labelText: context.l10n.noteOptional,
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
            label: Text(context.l10n.grantSickLeave,
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
            Text(context.l10n.leaveFamilyTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.familyAllocateBody(emp.name),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: hrsCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.hoursAllocated,
                hintText: context.l10n.hours24Hint,
                helperText: context.l10n.hours24Help,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixText: 'hrs',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.commonCancel)),
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
            child: Text(context.l10n.actionAllocate),
          ),
        ],
      ),
    );
  }
}
