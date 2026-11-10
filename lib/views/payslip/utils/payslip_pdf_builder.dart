import 'dart:typed_data';
import 'package:cropCompliance/models/employee_model.dart';
import 'package:cropCompliance/models/payslip_model.dart';
import 'package:cropCompliance/views/payslip/utils/pdf_downloader.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// One employee's leave standing, for the Leave Records report.
/// All values are in HOURS; the report also shows days (÷8).
class LeaveReportRow {
  final String employeeName;
  final String idNumber;
  final double hlOpening, hlAccrued, hlTaken, hlBalance;
  final double slOpening, slAccrued, slTaken, slBalance;
  final double flOpening, flAccrued, flTaken, flBalance;

  const LeaveReportRow({
    required this.employeeName,
    required this.idNumber,
    this.hlOpening = 0,
    this.hlAccrued = 0,
    this.hlTaken = 0,
    this.hlBalance = 0,
    this.slOpening = 0,
    this.slAccrued = 0,
    this.slTaken = 0,
    this.slBalance = 0,
    this.flOpening = 0,
    this.flAccrued = 0,
    this.flTaken = 0,
    this.flBalance = 0,
  });
}

/// Static utility that builds PDFs for payslips and UIF summaries (Flutter Web only).
class PayslipPdfBuilder {
  PayslipPdfBuilder._();

  static final _currency =
      NumberFormat.currency(locale: 'en_ZA', symbol: 'R ', decimalDigits: 2);
  static final _num1 = NumberFormat('#,##0.0', 'en_ZA');
  static final _shortDate = DateFormat('d-MMM-yyyy');
  static final _monthYear = DateFormat('MMM-yyyy');

  // ── Public entry points ───────────────────────────────────────────────────

  static String fileName(PayslipModel p) {
    final name = p.employeeName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final period = _monthYear.format(p.payPeriodStart);
    return '$name $period Payslip.pdf';
  }

  static Future<Uint8List> buildBytes(PayslipModel payslip) async {
    return Uint8List.fromList(await _buildPdf(payslip));
  }

  /// Downloads a single PDF. On web this triggers a file download; on mobile it opens the system PDF viewer.
  static Future<void> downloadFile(PayslipModel payslip) async {
    final bytes = await buildBytes(payslip);
    await triggerPdfDownload(bytes, fileName(payslip));
  }

  /// Opens the PDF in a new browser tab (web) or PDF viewer (mobile).
  static Future<void> openInBrowser(PayslipModel payslip) async {
    final bytes = await buildBytes(payslip);
    await openPdfInBrowser(bytes);
  }

  /// Merges all payslips into a single PDF (one page per employee) and downloads it.
  static Future<void> downloadAllAsSinglePdf(
      List<PayslipModel> payslips, String name) async {
    final doc = pw.Document();
    for (final p in payslips) {
      doc.addPage(_buildPayslipPage(p));
    }
    final bytes = Uint8List.fromList(await doc.save());
    await triggerPdfDownload(bytes, name);
  }

  /// Downloads a UIF summary PDF for a list of payslips.
  static Future<void> downloadUifSummary({
    required String companyName,
    required String uifRegNumber,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<PayslipModel> payslips,
  }) async {
    final bytes = Uint8List.fromList(await _buildUifSummaryPdf(
      companyName: companyName,
      uifRegNumber: uifRegNumber,
      periodStart: periodStart,
      periodEnd: periodEnd,
      payslips: payslips,
    ));
    final period = _monthYear.format(periodStart);
    await triggerPdfDownload(bytes, '$companyName UIF Summary $period.pdf');
  }

  /// Downloads a Leave Records report — per-employee Opening / Accrued / Taken /
  /// Balance for Holiday, Sick and Family responsibility leave.
  static Future<void> downloadLeaveReport({
    required String companyName,
    required DateTime generatedOn,
    required List<LeaveReportRow> rows,
  }) async {
    final bytes = Uint8List.fromList(await _buildLeaveReportPdf(
      companyName: companyName,
      generatedOn: generatedOn,
      rows: rows,
    ));
    final stamp = DateFormat('yyyy-MM-dd').format(generatedOn);
    await triggerPdfDownload(bytes, '$companyName Leave Records $stamp.pdf');
  }

  // ── Single payslip PDF ────────────────────────────────────────────────────

  static Future<List<int>> _buildPdf(PayslipModel p) async {
    final doc = pw.Document();
    doc.addPage(_buildPayslipPage(p));
    return doc.save();
  }

  static pw.Page _buildPayslipPage(PayslipModel p) {

    const accentColor = PdfColors.green800;

    pw.Widget sectionHeader(String title) => pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          margin: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Text(title,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: accentColor,
                  letterSpacing: 0.5)),
        );

    pw.Widget detailRow(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
          child: pw.Row(children: [
            pw.SizedBox(
              width: 90,
              child: pw.Text(label,
                  style:
                      pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ),
            pw.Expanded(
              child: pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
          ]),
        );

    pw.Widget rateRow(String label, double rate) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(label,
                    style:
                        pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text(_currency.format(rate),
                    style:
                        pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              ]),
        );

    pw.Widget hoursRow(String label, double hours, double amount) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
          child: pw.Row(children: [
            pw.Expanded(
                child: pw.Text(label,
                    style: const pw.TextStyle(fontSize: 9))),
            pw.SizedBox(
              width: 50,
              child: pw.Text(hours.toStringAsFixed(2),
                  style: pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center),
            ),
            pw.SizedBox(
              width: 70,
              child: pw.Text(_currency.format(amount),
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.right),
            ),
          ]),
        );

    pw.Widget deductionRow(String label, double amount) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
                pw.Text(_currency.format(amount),
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ]),
        );

    pw.Widget totalRow(String label, double amount, PdfColor color) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(label,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                        color: color)),
                pw.Text(_currency.format(amount),
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: color)),
              ]),
        );

    pw.Widget leftCol() => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            sectionHeader('PERSOONLIKE BESONDERHEDE'),
            detailRow('Naam', p.employeeName),
            detailRow('ID Nommer', p.employeeIdNumber),
            detailRow('Werknemer Tipe', p.employmentType.labelAfr),
            if (p.jobDescription.trim().isNotEmpty)
              detailRow('Posbeskrywing', p.jobDescription),
            detailRow('Periode Begin', _shortDate.format(p.payPeriodStart)),
            detailRow('Periode Einde', _shortDate.format(p.payPeriodEnd)),
            pw.SizedBox(height: 14),
            sectionHeader('VERDIENSTE'),
            rateRow('Uurlikse Loon', p.normalRate),
            if (p.overtimeHours > 0) rateRow('Oortyd Loon', p.overtimeRate),
            if (p.doubleTimeHours > 0)
              rateRow('Dubbel Tyd Loon', p.doubleTimeRate),
            pw.SizedBox(height: 6),
            hoursRow('Normale Loon', p.normalHours, p.normalPay),
            if (p.overtimePay > 0)
              hoursRow('Oortyd Loon', p.overtimeHours, p.overtimePay),
            if (p.doubleTimePay > 0)
              hoursRow('Dubbel Tyd', p.doubleTimeHours, p.doubleTimePay),
            if (p.publicHolidayPay > 0)
              hoursRow(
                  'Openbare Vakansie', p.publicHolidayHours, p.publicHolidayPay),
            if (p.sickLeavePay > 0)
              hoursRow('Siekteverlof (SV)', p.sickLeaveHours, p.sickLeavePay),
            if (p.holidayLeavePay > 0)
              hoursRow(
                  'Vakansieverlof (VV)', p.holidayLeaveHours, p.holidayLeavePay),
            if (p.familyLeavePay > 0)
              hoursRow('Gesinsverlof (GV)', p.familyLeaveHours,
                  p.familyLeavePay),
            // Extra income lines (bonus, allowance, etc.)
            for (final earning in p.additionalEarnings)
              deductionRow(earning.description, earning.amount),
            pw.Divider(),
            totalRow('TOTALE INKOMSTE', p.totalEarnings, accentColor),
          ],
        );

    pw.Widget rightCol() => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            sectionHeader('ANDER BESONDERHEDE'),
            detailRow('Betaaldatum', _shortDate.format(p.payDate)),
            detailRow('UIF Reg Nr',
                p.uifRegNumber.isNotEmpty ? p.uifRegNumber : '-'),
            pw.SizedBox(height: 14),
            sectionHeader('AFTREKKINGS'),
            deductionRow('UIF Werknemer (1%)', p.uifDeduction),
            if (p.payeDeduction > 0)
              deductionRow('PAYE Belasting', p.payeDeduction),
            for (final d in p.additionalDeductions)
              deductionRow(d.description, d.amount),
            pw.Divider(),
            totalRow(
                'TOTALE AFTREKKINGS', p.totalDeductions, PdfColors.red700),
            pw.SizedBox(height: 12),
            sectionHeader('NETTO SALARIS'),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.green300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Nett Salaris',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: accentColor,
                          fontSize: 10)),
                  pw.Text(_currency.format(p.netSalary),
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: accentColor,
                          fontSize: 14)),
                ],
              ),
            ),
          ],
        );

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(p.companyName.toUpperCase(),
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 16),
              textAlign: pw.TextAlign.center),
          if (p.companyAddress.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(p.companyAddress,
                style: pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center),
          ],
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            color: PdfColors.grey200,
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Text('SALARIS STROKIE',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: accentColor),
                textAlign: pw.TextAlign.center),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: leftCol()),
              pw.Container(
                  width: 1,
                  color: PdfColors.grey300,
                  margin:
                      const pw.EdgeInsets.symmetric(horizontal: 12)),
              pw.Expanded(child: rightCol()),
            ],
          ),
          pw.Spacer(),
          pw.Divider(color: PdfColors.grey400),
          pw.Text(
            p.isFinalised
                ? 'This payslip has been finalised.'
                : 'DRAFT – This payslip has not been finalised.',
            style: pw.TextStyle(
                fontSize: 8,
                color: p.isFinalised
                    ? PdfColors.green700
                    : PdfColors.orange700,
                fontStyle: p.isFinalised
                    ? pw.FontStyle.normal
                    : pw.FontStyle.italic),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── UIF Summary PDF ───────────────────────────────────────────────────────

  static pw.Widget _sumRow(String label, String value, {bool bold = false}) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: bold ? 10 : 9,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: bold ? 10 : 9, fontWeight: pw.FontWeight.bold)),
        ],
      );

  static Future<List<int>> _buildUifSummaryPdf({
    required String companyName,
    required String uifRegNumber,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<PayslipModel> payslips,
  }) async {
    final doc = pw.Document();
    const accentColor = PdfColors.green800;

    // FIXED: sum totals per employee for the whole period — previously
    // this kept only the latest payslip per employee, which under-reported
    // multi-payslip months.
    final earningsByEmp = <String, double>{};
    final uifByEmp = <String, double>{};
    final payeByEmp = <String, double>{};
    final otherDedByEmp = <String, double>{};
    final nameByEmp = <String, String>{};
    final idNumByEmp = <String, String>{};
    for (final p in payslips) {
      earningsByEmp.update(p.employeeId, (v) => v + p.totalEarnings,
          ifAbsent: () => p.totalEarnings);
      uifByEmp.update(p.employeeId, (v) => v + p.uifDeduction,
          ifAbsent: () => p.uifDeduction);
      payeByEmp.update(p.employeeId, (v) => v + p.payeDeduction,
          ifAbsent: () => p.payeDeduction);
      otherDedByEmp.update(
          p.employeeId, (v) => v + p.additionalDeductionsTotal,
          ifAbsent: () => p.additionalDeductionsTotal);
      nameByEmp[p.employeeId] = p.employeeName;
      idNumByEmp[p.employeeId] = p.employeeIdNumber;
    }
    // Total deductions the EMPLOYEE bears (employer UIF is not deducted from pay).
    double empDedTotal(String id) =>
        payeByEmp[id]! + uifByEmp[id]! + otherDedByEmp[id]!;

    final rowIds = nameByEmp.keys.toList()
      ..sort((a, b) => nameByEmp[a]!.compareTo(nameByEmp[b]!));

    final totalEarnings =
        earningsByEmp.values.fold<double>(0, (s, v) => s + v);
    final totalEmployeeUIF = uifByEmp.values.fold<double>(0, (s, v) => s + v);
    final totalEmployerUIF = totalEmployeeUIF; // employer matches 1%
    final totalUIF = totalEmployeeUIF + totalEmployerUIF;
    final totalPaye = payeByEmp.values.fold<double>(0, (s, v) => s + v);
    final totalOtherDed =
        otherDedByEmp.values.fold<double>(0, (s, v) => s + v);
    final totalEmpDed = totalPaye + totalEmployeeUIF + totalOtherDed;

    pw.Widget headerCell(String text) => pw.Container(
          padding: const pw.EdgeInsets.all(5),
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          child: pw.Text(text,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor),
              textAlign: pw.TextAlign.right),
        );

    pw.Widget headerCellLeft(String text) => pw.Container(
          padding: const pw.EdgeInsets.all(5),
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          child: pw.Text(text,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor)),
        );

    pw.Widget cell(String text, {bool bold = false}) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200))),
          child: pw.Text(text,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
              textAlign: pw.TextAlign.right),
        );

    pw.Widget cellLeft(String text, {bool bold = false}) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200))),
          child: pw.Text(text,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        );

    pw.Widget totCell(String text, {bool left = false}) => pw.Container(
          padding: const pw.EdgeInsets.all(5),
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          child: pw.Text(text,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              textAlign: left ? pw.TextAlign.left : pw.TextAlign.right),
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Text(companyName.toUpperCase(),
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
              textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            color: PdfColors.grey200,
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Text('UIF & AFTREKKINGS OPSOMMING',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: accentColor),
                textAlign: pw.TextAlign.center),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(
                    'Periode: ${_shortDate.format(periodStart)} – ${_shortDate.format(periodEnd)}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                pw.Text(
                    'UIF Reg Nr: ${uifRegNumber.isNotEmpty ? uifRegNumber : '-'}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ]),
              pw.Text('${rowIds.length} werknemer${rowIds.length == 1 ? '' : 's'}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(2.6),
              1: const pw.FlexColumnWidth(1.9),
              2: const pw.FlexColumnWidth(1.6),
              3: const pw.FlexColumnWidth(1.6),
              4: const pw.FlexColumnWidth(1.6),
              5: const pw.FlexColumnWidth(1.6),
              6: const pw.FlexColumnWidth(1.6),
              7: const pw.FlexColumnWidth(1.8),
            },
            children: [
              pw.TableRow(children: [
                headerCellLeft('Werknemer'),
                headerCellLeft('ID Nommer'),
                headerCell('Inkomste'),
                headerCell('PAYE'),
                headerCell('UIF Wrkn (1%)'),
                headerCell('UIF Wrkgr (1%)'),
                headerCell('Ander Aftr.'),
                headerCell('Werkn. Aftr.'),
              ]),
              ...rowIds.map((id) => pw.TableRow(children: [
                    cellLeft(nameByEmp[id]!),
                    cellLeft(idNumByEmp[id]!.isNotEmpty
                        ? idNumByEmp[id]!
                        : '-'),
                    cell(_currency.format(earningsByEmp[id]!)),
                    cell(_currency.format(payeByEmp[id]!)),
                    cell(_currency.format(uifByEmp[id]!)),
                    cell(_currency.format(uifByEmp[id]!)),
                    cell(_currency.format(otherDedByEmp[id]!)),
                    cell(_currency.format(empDedTotal(id)), bold: true),
                  ])),
              // Totals row
              pw.TableRow(children: [
                totCell('TOTAAL', left: true),
                totCell(''),
                totCell(_currency.format(totalEarnings)),
                totCell(_currency.format(totalPaye)),
                totCell(_currency.format(totalEmployeeUIF)),
                totCell(_currency.format(totalEmployerUIF)),
                totCell(_currency.format(totalOtherDed)),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  color: accentColor,
                  child: pw.Text(_currency.format(totalEmpDed),
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white),
                      textAlign: pw.TextAlign.right),
                ),
              ]),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Opsomming',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: accentColor)),
                  pw.SizedBox(height: 4),
                  _sumRow('PAYE Belasting:', _currency.format(totalPaye)),
                  _sumRow('Werknemers UIF bydrae (1%):',
                      _currency.format(totalEmployeeUIF)),
                  _sumRow('Ander aftrekkings:',
                      _currency.format(totalOtherDed)),
                  pw.Divider(color: PdfColors.grey400),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('TOTALE WERKNEMER AFTREKKINGS:',
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: accentColor)),
                        pw.Text(_currency.format(totalEmpDed),
                            style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: accentColor)),
                      ]),
                  pw.SizedBox(height: 6),
                  _sumRow('Werkgewer UIF bydrae (1%):',
                      _currency.format(totalEmployerUIF)),
                  _sumRow('TOTALE UIF BETAALBAAR (Wrkn + Wrkgr):',
                      _currency.format(totalUIF),
                      bold: true),
                ]),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ── Leave Records PDF ─────────────────────────────────────────────────────

  static Future<List<int>> _buildLeaveReportPdf({
    required String companyName,
    required DateTime generatedOn,
    required List<LeaveReportRow> rows,
  }) async {
    final doc = pw.Document();
    const accentColor = PdfColors.green800;

    final sorted = [...rows]
      ..sort((a, b) => a.employeeName.compareTo(b.employeeName));

    // hrs + (days) e.g. "40.0  (5.0 d)"
    String hd(double hrs) =>
        '${_num1.format(hrs)}  (${_num1.format(hrs / 8.0)} d)';

    pw.Widget hCell(String t, {bool left = false}) => pw.Container(
          padding: const pw.EdgeInsets.all(5),
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          child: pw.Text(t,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor),
              textAlign: left ? pw.TextAlign.left : pw.TextAlign.right),
        );

    pw.Widget c(String t,
            {bool left = false, bool bold = false, PdfColor? color}) =>
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200))),
          child: pw.Text(t,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: color ?? PdfColors.black),
              textAlign: left ? pw.TextAlign.left : pw.TextAlign.right),
        );

    // Three rows per employee (HL / SL / FL); name only on the first, with a
    // heavier top border to group. Balance column bold.
    pw.TableRow typeRow(String name, String id, String type, PdfColor typeColor,
        double opening, double accrued, double taken, double balance,
        {required bool first}) {
      pw.BoxDecoration? deco = first
          ? const pw.BoxDecoration(
              border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey500, width: 0.8)))
          : null;
      return pw.TableRow(decoration: deco, children: [
        c(first ? name : '', left: true, bold: true),
        c(first ? (id.isNotEmpty ? id : '-') : '', left: true),
        c(type, left: true, bold: true, color: typeColor),
        c(hd(opening)),
        c(hd(accrued)),
        c(hd(taken)),
        c(hd(balance),
            bold: true, color: balance < 0 ? PdfColors.red700 : typeColor),
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Text(companyName.toUpperCase(),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
              textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            color: PdfColors.grey200,
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Text('VERLOF REKORDS  /  LEAVE RECORDS',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: accentColor),
                textAlign: pw.TextAlign.center),
          ),
          pw.SizedBox(height: 8),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Opgestel / Generated: ${_shortDate.format(generatedOn)}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.Text('Waardes in ure (dae = ure ÷ 8)',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ]),
          pw.SizedBox(height: 12),
          if (sorted.isEmpty)
            pw.Text('Geen werknemers / No employees.',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
          else
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(2.6),
                1: const pw.FlexColumnWidth(2.0),
                2: const pw.FlexColumnWidth(2.2),
                3: const pw.FlexColumnWidth(2.0),
                4: const pw.FlexColumnWidth(2.0),
                5: const pw.FlexColumnWidth(2.0),
                6: const pw.FlexColumnWidth(2.2),
              },
              children: [
                pw.TableRow(children: [
                  hCell('Werknemer / Employee', left: true),
                  hCell('ID Nommer', left: true),
                  hCell('Verlof Tipe / Type', left: true),
                  hCell('Opening'),
                  hCell('Toegeken / Accrued'),
                  hCell('Geneem / Taken'),
                  hCell('Saldo / Balance'),
                ]),
                for (final r in sorted) ...[
                  typeRow(r.employeeName, r.idNumber, 'Vakansie / Holiday (HL)',
                      PdfColors.orange800, r.hlOpening, r.hlAccrued, r.hlTaken,
                      r.hlBalance,
                      first: true),
                  typeRow(r.employeeName, r.idNumber, 'Siekte / Sick (SL)',
                      PdfColors.blue800, r.slOpening, r.slAccrued, r.slTaken,
                      r.slBalance,
                      first: false),
                  typeRow(r.employeeName, r.idNumber, 'Gesin / Family (FL)',
                      PdfColors.purple800, r.flOpening, r.flAccrued, r.flTaken,
                      r.flBalance,
                      first: false),
                ],
              ],
            ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Saldo = Opening (voor die stelsel) + Toegeken (in stelsel) − Geneem.   '
              'Balance = Opening (pre-system) + Accrued (in-system) − Taken.',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }
}
