import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:cropCompliance/models/employee_model.dart';
import 'package:cropCompliance/models/payslip_model.dart';
import 'package:cropCompliance/views/payslip/utils/payslip_pdf_builder.dart';
import 'package:cropCompliance/views/payslip/utils/pdf_downloader.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

/// Bulk exports for a set of payslips: one Excel spreadsheet of all details,
/// or a ZIP of every individual PDF payslip. (The bank bulk-payment file is
/// in bank_payment_export.dart.)
class PayslipBulkExport {
  PayslipBulkExport._();

  static final _d = DateFormat('yyyy-MM-dd');
  static final _monthStamp = DateFormat('MMM-yyyy');

  static const _xlsxMime =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  /// One .xlsx with a row per payslip and every detail column.
  static Future<void> downloadExcel(
      List<PayslipModel> payslips, String companyName) async {
    final excel = Excel.createExcel();
    final sheet = excel['Payslips'];
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    const headers = [
      'Employee', 'ID Number', 'Type', 'Job',
      'Period Start', 'Period End', 'Pay Date', 'Status',
      'Normal hrs', 'OT hrs', 'DT hrs', 'PH hrs',
      'Sick hrs', 'Holiday hrs', 'Family hrs',
      'Rate (R/hr)', 'Gross (R)', 'PAYE (R)', 'UIF 1% (R)',
      'Other deductions (R)', 'Total deductions (R)', 'Net (R)',
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (final p in payslips) {
      sheet.appendRow(<CellValue?>[
        TextCellValue(p.employeeName),
        TextCellValue(p.employeeIdNumber),
        TextCellValue(p.employmentType.label),
        TextCellValue(p.jobDescription),
        TextCellValue(_d.format(p.payPeriodStart)),
        TextCellValue(_d.format(p.payPeriodEnd)),
        TextCellValue(_d.format(p.payDate)),
        TextCellValue(p.status.displayName),
        DoubleCellValue(p.normalHours),
        DoubleCellValue(p.overtimeHours),
        DoubleCellValue(p.doubleTimeHours),
        DoubleCellValue(p.publicHolidayHours),
        DoubleCellValue(p.sickLeaveHours),
        DoubleCellValue(p.holidayLeaveHours),
        DoubleCellValue(p.familyLeaveHours),
        DoubleCellValue(_round(p.normalRate)),
        DoubleCellValue(_round(p.totalEarnings)),
        DoubleCellValue(_round(p.payeDeduction)),
        DoubleCellValue(_round(p.uifDeduction)),
        DoubleCellValue(_round(p.additionalDeductionsTotal)),
        DoubleCellValue(_round(p.totalDeductions)),
        DoubleCellValue(_round(p.netSalary)),
      ]);
    }

    // Totals row
    final n = payslips.length;
    final gross = payslips.fold<double>(0, (s, p) => s + p.totalEarnings);
    final paye = payslips.fold<double>(0, (s, p) => s + p.payeDeduction);
    final uif = payslips.fold<double>(0, (s, p) => s + p.uifDeduction);
    final other =
        payslips.fold<double>(0, (s, p) => s + p.additionalDeductionsTotal);
    final totDed = payslips.fold<double>(0, (s, p) => s + p.totalDeductions);
    final net = payslips.fold<double>(0, (s, p) => s + p.netSalary);
    sheet.appendRow(<CellValue?>[
      TextCellValue('TOTAL ($n)'),
      ...List<CellValue?>.filled(14, null),
      DoubleCellValue(_round(gross)),
      DoubleCellValue(_round(paye)),
      DoubleCellValue(_round(uif)),
      DoubleCellValue(_round(other)),
      DoubleCellValue(_round(totDed)),
      DoubleCellValue(_round(net)),
    ]);

    final bytes = excel.save();
    if (bytes == null) return;
    final period = payslips.isEmpty
        ? _monthStamp.format(DateTime.now())
        : _monthStamp.format(payslips
            .map((p) => p.payPeriodStart)
            .reduce((a, b) => a.isBefore(b) ? a : b));
    await triggerFileDownload(
        Uint8List.fromList(bytes), '$companyName Payslips $period.xlsx',
        _xlsxMime);
  }

  /// A .zip of every payslip's individual PDF.
  static Future<void> downloadZip(
      List<PayslipModel> payslips, String companyName) async {
    final archive = Archive();
    final used = <String>{};
    for (final p in payslips) {
      final pdf = await PayslipPdfBuilder.buildBytes(p);
      var name = PayslipPdfBuilder.fileName(p);
      // De-duplicate identical filenames (same employee + month).
      if (used.contains(name)) {
        var i = 2;
        final base = name.replaceAll('.pdf', '');
        while (used.contains('$base ($i).pdf')) {
          i++;
        }
        name = '$base ($i).pdf';
      }
      used.add(name);
      archive.addFile(ArchiveFile(name, pdf.length, pdf));
    }
    final zip = ZipEncoder().encode(archive);
    if (zip == null) return;
    await triggerFileDownload(
        Uint8List.fromList(zip), '$companyName Payslips.zip', 'application/zip');
  }

  static double _round(double v) => (v * 100).roundToDouble() / 100;
}
