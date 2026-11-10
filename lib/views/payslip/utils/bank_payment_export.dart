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

  /// Works out who can be paid from [payslips]: one row per employee (net pay
  /// summed if they have several payslips in the selection), and a list of
  /// employees left out because they have no/incomplete banking details,
  /// fail [template]'s validation, or have no positive net pay.
  ///
  /// [template] may be null (no bank chosen yet) — only the generic checks
  /// then apply.
  static BankPaymentPlan plan(
    List<PayslipModel> payslips,
    List<EmployeeModel> employees, {
    BankExportTemplate? template,
  }) {
    final byId = {for (final e in employees) e.id: e};
    final grouped = <String, List<PayslipModel>>{};
    for (final p in payslips) {
      grouped.putIfAbsent(p.employeeId, () => []).add(p);
    }

    final ready = <BankPaymentRow>[];
    final skipped = <BankPaymentSkip>[];
    for (final entry in grouped.entries) {
      final slips = entry.value;
      // Sum in cents so the file total matches the payslips exactly.
      final cents =
          slips.fold<int>(0, (s, p) => s + (p.netSalary * 100).round());
      final emp = byId[entry.key];
      if (emp == null) {
        skipped.add(BankPaymentSkip(
            slips.first.employeeName, 'employee record not found'));
        continue;
      }
      final issues = emp.bankingIssues;
      if (issues.isNotEmpty) {
        skipped.add(BankPaymentSkip(emp.name, issues.join(', ')));
        continue;
      }
      if (cents <= 0) {
        skipped.add(BankPaymentSkip(emp.name, 'net pay is R 0.00 or less'));
        continue;
      }
      final line = paymentLine(emp, cents);
      final templateIssues = template?.validate(line) ?? const <String>[];
      if (templateIssues.isNotEmpty) {
        skipped.add(BankPaymentSkip(emp.name, templateIssues.join(', ')));
        continue;
      }
      ready.add(BankPaymentRow(emp, line, slips.length));
    }
    ready.sort((a, b) => a.employee.name.compareTo(b.employee.name));
    skipped.sort((a, b) => a.name.compareTo(b.name));

    return BankPaymentPlan(
      ready: ready,
      skipped: skipped,
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

  /// Downloads [plan] in [template]'s layout.
  static Future<void> download(
    BankPaymentPlan plan,
    BankExportTemplate template,
    String companyName, {
    String referencePrefix = BankExportTemplate.defaultReferencePrefix,
  }) async {
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

/// One payable line in the bulk payment file.
class BankPaymentRow {
  final EmployeeModel employee;
  final BankPaymentLine line;

  /// How many payslips were summed into this payment.
  final int payslipCount;
  BankPaymentRow(this.employee, this.line, this.payslipCount);
}

/// An employee left out of the file, and why.
class BankPaymentSkip {
  final String name;
  final String reason;
  BankPaymentSkip(this.name, this.reason);
}

class BankPaymentPlan {
  final List<BankPaymentRow> ready;
  final List<BankPaymentSkip> skipped;

  /// Selected payslips still in Draft status.
  final int draftCount;
  final DateTime? periodStart;

  BankPaymentPlan({
    required this.ready,
    required this.skipped,
    required this.draftCount,
    required this.periodStart,
  });

  double get total =>
      ready.fold<int>(0, (s, r) => s + r.line.amountCents) / 100;
  int get combinedCount => ready.where((r) => r.payslipCount > 1).length;
}
