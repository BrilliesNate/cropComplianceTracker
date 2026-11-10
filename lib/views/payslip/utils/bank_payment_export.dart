import 'dart:convert';
import 'dart:typed_data';

import 'package:cropCompliance/core/bank_export/bank_export_registry.dart';
import 'package:cropCompliance/models/employee_model.dart';
import 'package:cropCompliance/models/payslip_model.dart';
import 'package:cropCompliance/views/payslip/utils/pdf_downloader.dart';
import 'package:intl/intl.dart';

/// Bulk bank-payment file for a set of payslips: works out who can be paid,
/// then writes the file in the chosen bank's [BankExportTemplate] layout.
class BankPaymentExport {
  BankPaymentExport._();

  static final _monthStamp = DateFormat('MMM-yyyy');

  /// Finds the employee a payslip belongs to.
  ///
  /// Normally by `employeeId`. A payslip can outlive its employee record
  /// (the Payslip Manager's "Remove employee" deletes the record but keeps
  /// the payslips, and re-adding the person creates a NEW id), so when the
  /// id no longer exists we fall back to the SA ID number, then to the exact
  /// name — but only when exactly one current employee matches, so we never
  /// guess between two people.
  static EmployeeModel? resolveEmployee(
      PayslipModel p, List<EmployeeModel> employees) {
    for (final e in employees) {
      if (p.employeeId.isNotEmpty && e.id == p.employeeId) return e;
    }
    EmployeeModel? unique(bool Function(EmployeeModel) test) {
      final hits = employees.where(test).toList();
      return hits.length == 1 ? hits.first : null;
    }

    final idNo = p.employeeIdNumber.trim();
    if (idNo.isNotEmpty) {
      final byIdNo = unique((e) => e.idNumber.trim() == idNo);
      if (byIdNo != null) return byIdNo;
    }
    final name = p.employeeName.trim().toLowerCase();
    if (name.isEmpty) return null;
    return unique((e) => e.name.trim().toLowerCase() == name);
  }

  /// Works out who can be paid from [payslips]: one row per employee (net pay
  /// summed if they have several payslips in the selection), and a list of
  /// employees left out — each with a [SkipKind] so the UI can offer the
  /// right fix.
  ///
  /// [template] may be null (no bank chosen yet) — only the generic checks
  /// then apply.
  static BankPaymentPlan plan(
    List<PayslipModel> payslips,
    List<EmployeeModel> employees, {
    BankExportTemplate? template,
  }) {
    // Group by resolved employee; unresolved payslips by their stored
    // id/name so one missing person shows once, not once per payslip.
    final groups = <String, List<PayslipModel>>{};
    final resolved = <String, EmployeeModel>{};
    final relinks = <String, EmployeeModel>{};
    for (final p in payslips) {
      final emp = resolveEmployee(p, employees);
      final key = emp != null
          ? 'e:${emp.id}'
          : 'm:${p.employeeId.isNotEmpty ? p.employeeId : p.employeeName.trim().toLowerCase()}';
      groups.putIfAbsent(key, () => []).add(p);
      if (emp != null) {
        resolved[key] = emp;
        if (emp.id != p.employeeId) relinks[p.id] = emp;
      }
    }

    final ready = <BankPaymentRow>[];
    final skipped = <BankPaymentSkip>[];
    for (final entry in groups.entries) {
      final slips = entry.value;
      // Sum in cents so the file total matches the payslips exactly.
      final cents =
          slips.fold<int>(0, (s, p) => s + (p.netSalary * 100).round());
      final emp = resolved[entry.key];
      if (emp == null) {
        skipped.add(BankPaymentSkip(
          name: slips.first.employeeName.trim().isEmpty
              ? 'Unnamed employee'
              : slips.first.employeeName,
          reason: 'employee record no longer exists',
          kind: SkipKind.missingEmployee,
          payslips: slips,
        ));
        continue;
      }
      if (!emp.hasAnyBankingDetails) {
        skipped.add(BankPaymentSkip(
          name: emp.name,
          reason: 'no banking details',
          kind: SkipKind.noBankingDetails,
          employee: emp,
          payslips: slips,
        ));
        continue;
      }
      if (cents <= 0) {
        skipped.add(BankPaymentSkip(
          name: emp.name,
          reason: 'net pay is R 0.00 or less',
          kind: SkipKind.nonPositivePay,
          employee: emp,
          payslips: slips,
        ));
        continue;
      }
      final line = paymentLine(emp, cents);
      final issues = {
        ...emp.bankingIssues,
        ...?template?.validate(line),
      }.toList();
      if (issues.isNotEmpty) {
        skipped.add(BankPaymentSkip(
          name: emp.name,
          reason: issues.join(', '),
          kind: SkipKind.invalidBankingDetails,
          employee: emp,
          payslips: slips,
        ));
        continue;
      }
      ready.add(BankPaymentRow(emp, line, slips.length));
    }
    ready.sort((a, b) => a.employee.name.compareTo(b.employee.name));
    skipped.sort((a, b) => a.name.compareTo(b.name));

    return BankPaymentPlan(
      ready: ready,
      skipped: skipped,
      relinks: relinks,
      draftCount: payslips.where((p) => !p.isFinalised).length,
      periodStart: payslips.isEmpty
          ? null
          : payslips
              .map((p) => p.payPeriodStart)
              .reduce((a, b) => a.isBefore(b) ? a : b),
    );
  }

  /// Converts an employee + amount into the template-neutral payment line.
  static BankPaymentLine paymentLine(EmployeeModel e, int amountCents) =>
      BankPaymentLine(
        beneficiaryName: e.beneficiaryName,
        firstName: e.firstName,
        accountNumber: e.accountNumber,
        branchCode: e.branchCode,
        bankName: e.bankName,
        accountTypeCode: e.accountType.acbCode,
        accountTypeLabel: e.accountType.label,
        idNumber: e.idNumber,
        amountCents: amountCents,
      );

  /// One-line reason the Download button is disabled, or null if the file
  /// can be downloaded. Checked in the order a user would fix things. The
  /// dialog always pairs a reason with an action to resolve it.
  static String? disabledReason({
    required int selectedCount,
    required bool bankChosen,
    required int draftCount,
    required DraftChoice draftChoice,
    required BankPaymentPlan plan,
  }) {
    if (selectedCount == 0) return 'No payslips selected.';
    if (!bankChosen) return 'Choose the bank the farm pays from.';
    if (draftCount > 0 && draftChoice == DraftChoice.undecided) {
      return '$draftCount draft payslip${draftCount == 1 ? '' : 's'} '
          'selected — remove ${draftCount == 1 ? 'it' : 'them'} or include '
          '${draftCount == 1 ? 'it' : 'them'} anyway.';
    }
    if (draftChoice == DraftChoice.remove && selectedCount == draftCount) {
      return 'All selected payslips are drafts — include them anyway or '
          'select finalised payslips.';
    }
    if (plan.ready.isEmpty) {
      final kinds = plan.skipped.map((s) => s.kind).toSet();
      if (kinds.every((k) => k.isBankingFix)) {
        return 'Nobody has banking details yet — add them to continue.';
      }
      if (kinds.every((k) => k == SkipKind.missingEmployee)) {
        return 'These payslips aren\'t linked to an employee — fix them to '
            'continue.';
      }
      return 'Nobody can be paid yet — fix the employees listed below.';
    }
    return null;
  }

  /// Downloads [plan] in [template]'s layout. Never writes an empty file.
  static Future<void> download(
    BankPaymentPlan plan,
    BankExportTemplate template,
    String companyName, {
    String referencePrefix = BankExportTemplate.defaultReferencePrefix,
  }) async {
    if (plan.ready.isEmpty) {
      throw StateError('No payable employees — nothing to export.');
    }
    final ctx = BankExportContext(
        payerName: companyName, referencePrefix: referencePrefix);
    final content =
        template.build(plan.ready.map((r) => r.line).toList(), ctx);
    final stamp = _monthStamp.format(plan.periodStart ?? DateTime.now());
    await triggerFileDownload(
      Uint8List.fromList(utf8.encode(content)),
      template.fileName(companyName, stamp),
      template.mimeType,
    );
  }
}

/// What to do with Draft payslips in the current selection.
enum DraftChoice { undecided, remove, include }

/// Why someone was left out — drives which fix the dialog offers.
enum SkipKind {
  /// Payslip points to an employee record that no longer exists.
  missingEmployee,

  /// No account number / branch code captured (banking is optional).
  noBankingDetails,

  /// Banking details captured but invalid for the chosen bank.
  invalidBankingDetails,

  /// Net pay is zero or negative — the payslip itself needs fixing.
  nonPositivePay,
}

extension SkipKindX on SkipKind {
  bool get isBankingFix =>
      this == SkipKind.noBankingDetails ||
      this == SkipKind.invalidBankingDetails;
}

/// One payable line in the bulk payment file.
class BankPaymentRow {
  final EmployeeModel employee;
  final BankPaymentLine line;

  /// How many payslips were summed into this payment.
  final int payslipCount;
  BankPaymentRow(this.employee, this.line, this.payslipCount);
}

/// An employee left out of the file, why, and what's needed to fix it.
class BankPaymentSkip {
  final String name;
  final String reason;
  final SkipKind kind;

  /// The resolved employee (null for [SkipKind.missingEmployee]).
  final EmployeeModel? employee;

  /// The selected payslips this row stands for.
  final List<PayslipModel> payslips;

  BankPaymentSkip({
    required this.name,
    required this.reason,
    required this.kind,
    this.employee,
    this.payslips = const [],
  });
}

class BankPaymentPlan {
  final List<BankPaymentRow> ready;
  final List<BankPaymentSkip> skipped;

  /// Payslips whose stored employeeId no longer exists but which were
  /// matched to a current employee by ID number or name (payslip id →
  /// employee). Paid normally; the dialog offers to save the link.
  final Map<String, EmployeeModel> relinks;

  /// Selected payslips still in Draft status.
  final int draftCount;
  final DateTime? periodStart;

  BankPaymentPlan({
    required this.ready,
    required this.skipped,
    this.relinks = const {},
    required this.draftCount,
    required this.periodStart,
  });

  double get total =>
      ready.fold<int>(0, (s, r) => s + r.line.amountCents) / 100;
  int get combinedCount => ready.where((r) => r.payslipCount > 1).length;
}
