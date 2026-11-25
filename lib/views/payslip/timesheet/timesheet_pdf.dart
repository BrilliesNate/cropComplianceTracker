/// Timesheet as a PDF — the same three sheets as the screen (Normal hours,
/// Overtime, Piecework), A4 landscape, workers as rows and the period's days
/// as columns, with totals and a "checked by" line for the farm's records.
/// Overtime / Piecework pages are only added when that sheet has entries.
library;

import 'dart:typed_data';

import 'package:cropCompliance/models/employee_model.dart';
import 'package:cropCompliance/providers/locale_provider.dart';
import 'package:cropCompliance/views/payslip/utils/pdf_downloader.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'timesheet_calc.dart';
import 'timesheet_service.dart';
import 'package:cropCompliance/views/payslip/utils/pdf_theme.dart';

class TimesheetPdf {
  TimesheetPdf._();

  static const _rowsPerPage = 22;
  static const _green = PdfColor.fromInt(0xFF1B5E20);
  static const _headBg = PdfColor.fromInt(0xFFEAF3EA);
  static const _weekendBg = PdfColor.fromInt(0xFFF1EDE4);
  static const _holidayBg = PdfColor.fromInt(0xFFFDE2E1);
  static const _totalBg = PdfColor.fromInt(0xFFF3F8F3);
  static const _grid = PdfColor.fromInt(0xFFCCCCCC);

  static PdfColor _codeBg(String code) => switch (code) {
        'SL' => const PdfColor.fromInt(0xFFE0F2F1),
        'HL' => const PdfColor.fromInt(0xFFE3F2FD),
        'FL' => const PdfColor.fromInt(0xFFEDE7F6),
        'PH' => const PdfColor.fromInt(0xFFFDE2E1),
        _ => const PdfColor.fromInt(0xFFEEEEEE),
      };

  static String fileName(String companyName, PayPeriodRecord period) {
    final company = companyName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    return LocaleProvider.instance.l10n.tsPdfFile(
        company,
        DateFormat('yyyy-MM-dd')
            .format(period.start)); // l10n-ignore: date pattern
  }

  /// Builds the PDF and downloads it (web) / opens it (phone).
  static Future<void> download({
    required String companyName,
    required PayPeriodRecord period,
    required List<EmployeeModel> workers,
    required Map<String, WorkerSheets> sheets,
    required TimesheetRates rates,
    PieceRateInfo? pieceRate,
  }) async {
    final bytes = await build(
      companyName: companyName,
      period: period,
      workers: workers,
      sheets: sheets,
      rates: rates,
      pieceRate: pieceRate,
    );
    await triggerPdfDownload(bytes, fileName(companyName, period));
  }

  static Future<Uint8List> build({
    required String companyName,
    required PayPeriodRecord period,
    required List<EmployeeModel> workers,
    required Map<String, WorkerSheets> sheets,
    required TimesheetRates rates,
    PieceRateInfo? pieceRate,
  }) async {
    final l10n = LocaleProvider.instance.l10n;
    final days = period.days;
    final keys = period.dayKeys;
    WorkerSheets of(EmployeeModel e) => sheets[e.id] ?? WorkerSheets();

    bool any(bool Function(WorkerSheets s) test) =>
        workers.any((e) => test(of(e)));
    final hasOvertime =
        any((s) => keys.any((k) => (s.overtime[k]?.hours ?? 0) > 0));
    final hasPiece = any((s) => keys.any((k) => s.piece[k] != null));
    final hasComment = any((s) => s.comment.trim().isNotEmpty);

    final pages = <_SheetPage>[];

    // ── Normal hours ──
    pages.add(_SheetPage(
      title: l10n.tsNormalHours,
      totalHeads: [
        l10n.colHours,
        l10n.colLeave,
        if (hasComment) l10n.colComment,
      ],
      totalWidths: [38, 70, if (hasComment) 110],
      legend: [
        for (final c in leaveCodes) '${leaveCodeLabel(c)} ${leaveCodeName(c)}',
        if (workers
            .any((e) => keys.any((k) => of(e).normal[k]?.settled ?? false)))
          l10n.tsPdfUnpaidLegend,
      ].join('   ·   '),
      rows: [
        for (final e in workers)
          () {
            final s = of(e);
            final t = totalsFor(s, days: keys);
            return _Row(
              name: e.name,
              cells: [
                for (final k in keys)
                  () {
                    final d = s.normal[k];
                    if (d == null) return const _Cell('');
                    if (d.settled) {
                      final h = paidLeaveHours(d, rates.ordinaryDayHours);
                      return _Cell(
                          '${leaveCodeLabel(d.code!)}\n${formatHours(h)}h', // l10n-ignore: hours unit
                          bg: h <= 0
                              ? const PdfColor.fromInt(0xFFF0F0F0)
                              : _codeBg(d.code!),
                          bold: true);
                    }
                    if (d.code != null) {
                      return _Cell(leaveCodeLabel(d.code!),
                          bg: _codeBg(d.code!), bold: true);
                    }
                    return _Cell(formatHours(d.hours ?? 0));
                  }(),
              ],
              totals: [
                formatHours(t.normalHours),
                [
                  ...t.leaveByCode.entries
                      .map((x) => '${leaveCodeLabel(x.key)} ${x.value}'),
                  if (unpaidLeaveHours(s, keys, rates.ordinaryDayHours) > 0)
                    l10n.tsUnpaidBadge(formatHours(
                        unpaidLeaveHours(s, keys, rates.ordinaryDayHours))),
                ].join('  '),
                if (hasComment) s.comment.trim(),
              ],
            );
          }(),
      ],
    ));

    // ── Overtime ──
    if (hasOvertime) {
      pages.add(_SheetPage(
        title: l10n.tsOvertime,
        totalHeads: [l10n.colOtHours, l10n.colNsDays],
        totalWidths: [44, 40],
        legend: l10n.tsNsLegend,
        rows: [
          for (final e in workers)
            () {
              final s = of(e);
              final t = totalsFor(s, days: keys);
              return _Row(
                name: e.name,
                cells: [
                  for (final k in keys)
                    () {
                      final v = s.overtime[k];
                      if (v == null || v.hours <= 0) return const _Cell('');
                      final night = v.night;
                      return _Cell(
                          night
                              ? '${formatHours(v.hours)} NS' // l10n-ignore: sheet code
                              : formatHours(v.hours),
                          bg: night ? const PdfColor.fromInt(0xFFFFF3E0) : null,
                          bold: night);
                    }(),
                ],
                totals: [
                  formatHours(t.overtimeHours),
                  '${t.nightShiftDays}',
                ],
              );
            }(),
        ],
      ));
    }

    // ── Piecework ──
    if (hasPiece) {
      final unit = pieceRate?.unitType ?? l10n.colUnits;
      pages.add(_SheetPage(
        title: pieceRate == null
            ? l10n.tsPiecework
            : '${l10n.tsPiecework} · ${pieceRate.taskOrCrop} · R ${pieceRate.rate.toStringAsFixed(2)} / $unit',
        totalHeads: [
          l10n.colHours,
          l10n.colUnits,
          l10n.colPiecePay,
          l10n.colTopUp,
        ],
        totalWidths: [34, 38, 52, 48],
        legend: l10n.tsPdfPieceLegend(unit),
        rows: [
          for (final e in workers)
            () {
              final s = of(e);
              final t = totalsFor(s, days: keys);
              final has = t.units > 0 || t.pieceHours > 0;
              final f = has
                  ? payslipFiguresFor(
                      sheets: s,
                      days: keys,
                      hourlyRate: e.normalHourlyRate,
                      rates: rates,
                      pieceRate: pieceRate)
                  : null;
              final pay = f?.pieceEarnings;
              final top = f?.topUp;
              return _Row(
                name: e.name,
                red: f?.belowMinimumWage ?? false,
                cells: [
                  for (final k in keys)
                    () {
                      final v = s.piece[k];
                      if (v == null) return const _Cell('');
                      return _Cell(
                          '${formatHours(v.hours)}h\n${formatHours(v.units)}'); // l10n-ignore: hours / units
                    }(),
                ],
                totals: [
                  has ? formatHours(t.pieceHours) : '',
                  has ? formatHours(t.units) : '',
                  !has
                      ? ''
                      : pay == null
                          ? 'R —' // l10n-ignore: amount not known
                          : 'R ${pay.toStringAsFixed(2)}',
                  !has
                      ? ''
                      : top == null
                          ? '—'
                          : top > 0
                              ? 'R ${top.toStringAsFixed(2)}'
                              : l10n.tsOk,
                ],
              );
            }(),
        ],
      ));
    }

    // Split long sheets so each page keeps its column headings.
    final chunks = <(_SheetPage, List<_Row>)>[];
    for (final p in pages) {
      if (p.rows.isEmpty) {
        chunks.add((p, const []));
        continue;
      }
      for (var i = 0; i < p.rows.length; i += _rowsPerPage) {
        chunks.add((
          p,
          p.rows.sublist(i, (i + _rowsPerPage).clamp(0, p.rows.length).toInt())
        ));
      }
    }

    final rangeFmt = DateFormat('d MMM yyyy'); // follows the app language
    final dayName = DateFormat('EEE'); // follows the app language
    final range =
        '${rangeFmt.format(period.start)} – ${rangeFmt.format(period.end)}';
    final status = period.finalised
        ? (period.finalisedBy != null
            ? l10n.tsFinalisedBy(period.finalisedBy!)
            : l10n.tsFinalised)
        : l10n.tsPdfDraft;
    final printed = l10n.tsPdfPrinted(rangeFmt.format(DateTime.now()));

    final doc = pw.Document(theme: await pdfTheme());
    for (var i = 0; i < chunks.length; i++) {
      final (sheet, rows) = chunks[i];
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(20, 18, 20, 16),
        build: (ctx) {
          const nameW = 110.0;
          final totalsW = sheet.totalWidths.fold<double>(0, (a, b) => a + b);
          final avail = ctx.page.pageFormat.availableWidth - nameW - totalsW;
          final dayW = (avail / days.length).clamp(12.0, 40.0).toDouble();
          final small = days.length > 16;
          final fs = small ? 6.5 : 8.0;
          // Narrow day columns get two-letter day names (Mo, Tu… / Ma, Di…).
          String shortDay(DateTime d) {
            final n = dayName.format(d).replaceAll('.', '');
            return small && n.length > 2 ? n.substring(0, 2) : n;
          }

          pw.Widget cell(String text,
                  {PdfColor? bg,
                  bool bold = false,
                  PdfColor? color,
                  pw.Alignment align = pw.Alignment.center,
                  double? size}) =>
              pw.Container(
                color: bg,
                alignment: align,
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                child: pw.Text(text,
                    textAlign: align == pw.Alignment.center
                        ? pw.TextAlign.center
                        : pw.TextAlign.left,
                    style: pw.TextStyle(
                        fontSize: size ?? fs,
                        color: color,
                        fontWeight:
                            bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
              );

          final header = pw.TableRow(children: [
            cell(l10n.colWorker,
                bg: _headBg,
                bold: true,
                color: _green,
                align: pw.Alignment.centerLeft),
            for (final d in days)
              cell(
                  isSaPublicHoliday(d, rates.extraHolidays)
                      ? '${leaveCodeLabel('PH')}\n${d.day}'
                      : '${shortDay(d)}\n${d.day}',
                  bg: isSaPublicHoliday(d, rates.extraHolidays)
                      ? _holidayBg
                      : d.weekday >= 6
                          ? _weekendBg
                          : _headBg,
                  bold: true,
                  color: _green),
            for (final h in sheet.totalHeads)
              cell(h, bg: _headBg, bold: true, color: _green),
          ]);

          final body = [
            for (final r in rows)
              pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.full,
                  children: [
                    cell(r.name,
                        align: pw.Alignment.centerLeft,
                        bold: r.red,
                        color: r.red ? PdfColors.red800 : null,
                        size: 8),
                    for (var c = 0; c < r.cells.length; c++)
                      cell(r.cells[c].text,
                          bg: r.cells[c].bg ??
                              (days[c].weekday >= 6
                                  ? const PdfColor.fromInt(0xFFFAF8F3)
                                  : null),
                          bold: r.cells[c].bold),
                    for (var t = 0; t < r.totals.length; t++)
                      cell(r.totals[t],
                          bg: _totalBg,
                          bold: t == 0,
                          color: _green,
                          align: sheet.totalHeads[t] == l10n.colComment
                              ? pw.Alignment.centerLeft
                              : pw.Alignment.center),
                  ]),
          ];

          return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(companyName.toUpperCase(),
                                  style: pw.TextStyle(
                                      fontSize: 13,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 2),
                              pw.Text(l10n.tsPdfHeading(sheet.title),
                                  style: const pw.TextStyle(
                                      fontSize: 11, color: _green)),
                            ]),
                      ),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(range,
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 2),
                            pw.Text(status,
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    color: period.finalised
                                        ? _green
                                        : PdfColors.orange800)),
                          ]),
                    ]),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: _grid, width: 0.5),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(nameW),
                    for (var c = 0; c < days.length; c++)
                      c + 1: pw.FixedColumnWidth(dayW),
                    for (var t = 0; t < sheet.totalWidths.length; t++)
                      days.length + 1 + t:
                          pw.FixedColumnWidth(sheet.totalWidths[t]),
                  },
                  children: [header, ...body],
                ),
                pw.SizedBox(height: 6),
                pw.Text(sheet.legend,
                    style: const pw.TextStyle(
                        fontSize: 7.5, color: PdfColors.grey700)),
                pw.Spacer(),
                pw.Text(l10n.tsPdfChecked,
                    style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 6),
                pw.Row(children: [
                  pw.Text(printed,
                      style: const pw.TextStyle(
                          fontSize: 7.5, color: PdfColors.grey600)),
                  pw.Spacer(),
                  pw.Text(l10n.pageOf(i + 1, chunks.length),
                      style: const pw.TextStyle(
                          fontSize: 7.5, color: PdfColors.grey600)),
                ]),
              ]);
        },
      ));
    }
    return Uint8List.fromList(await doc.save());
  }
}

class _Cell {
  final String text;
  final PdfColor? bg;
  final bool bold;
  const _Cell(this.text, {this.bg, this.bold = false});
}

class _Row {
  final String name;
  final List<_Cell> cells;
  final List<String> totals;
  final bool red;
  const _Row({
    required this.name,
    required this.cells,
    required this.totals,
    this.red = false,
  });
}

class _SheetPage {
  final String title;
  final List<String> totalHeads;
  final List<double> totalWidths;
  final String legend;
  final List<_Row> rows;
  const _SheetPage({
    required this.title,
    required this.totalHeads,
    required this.totalWidths,
    required this.legend,
    required this.rows,
  });
}
