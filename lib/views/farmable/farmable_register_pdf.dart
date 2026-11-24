import 'dart:typed_data';
import 'package:cropCompliance/models/farmable_models.dart';
import 'package:cropCompliance/views/payslip/utils/pdf_downloader.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cropCompliance/providers/locale_provider.dart';

/// Builds an audit-ready Farm Register PDF from Farmable data:
/// fields/blocks (crop, variety, hectares), equipment (with inspection dates)
/// and people/roles. Designed as evidence for SIZA/WIETA/GlobalGAP/IPW audits.
class FarmableRegisterPdf {
  FarmableRegisterPdf._();

  static DateFormat get _date => DateFormat('d-MMM-yyyy'); // follows the app language
  static final _num2 = NumberFormat('#,##0.00', 'en_ZA');

  static Future<void> download({
    required String companyName,
    required FarmableLocation? farm,
    required List<FarmableField> fields,
    required List<FarmableEquipment> equipment,
    required List<({FarmableMember member, String role})> people,
    required DateTime generatedOn,
  }) async {
    final bytes = Uint8List.fromList(await _build(
      companyName: companyName,
      farm: farm,
      fields: fields,
      equipment: equipment,
      people: people,
      generatedOn: generatedOn,
    ));
    final stamp = DateFormat('yyyy-MM-dd').format(generatedOn);
    await triggerPdfDownload(bytes, LocaleProvider.instance.l10n.frFileName(companyName, stamp));
  }

  static Future<List<int>> _build({
    required String companyName,
    required FarmableLocation? farm,
    required List<FarmableField> fields,
    required List<FarmableEquipment> equipment,
    required List<({FarmableMember member, String role})> people,
    required DateTime generatedOn,
  }) async {
    final doc = pw.Document();
    const accent = PdfColors.green800;

    final sortedFields = [...fields]..sort((a, b) => a.name.compareTo(b.name));
    final totalHa =
        sortedFields.fold<double>(0, (s, f) => s + f.areaHectares);

    pw.Widget hCell(String t, {bool left = false}) => pw.Container(
          padding: const pw.EdgeInsets.all(5),
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          child: pw.Text(t,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: accent),
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

    pw.Widget sectionTitle(String t) => pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(top: 16, bottom: 6),
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          color: PdfColors.grey200,
          child: pw.Text(t,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: accent)),
        );

    String cropOf(FarmableField f) => f.varieties.isEmpty
        ? '-'
        : f.varieties.map((v) => v.categoryName).toSet().join(', ');
    String varOf(FarmableField f) => f.varieties.isEmpty
        ? '-'
        : f.varieties.map((v) => v.name).join(', ');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          // Header
          pw.Text(companyName.toUpperCase(),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
              textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            color: PdfColors.grey200,
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Text(LocaleProvider.instance.l10n.frTitle,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: accent),
                textAlign: pw.TextAlign.center),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                if (farm != null)
                  pw.Text(LocaleProvider.instance.l10n.frFarm(farm.displayName),
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                if (farm?.country != null)
                  pw.Text(LocaleProvider.instance.l10n.frCountry('${farm!.country}'),
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                if (farm?.coordinate != null)
                  pw.Text(
                      LocaleProvider.instance.l10n.frLocation(farm!.coordinate!.y.toStringAsFixed(5), farm.coordinate!.x.toStringAsFixed(5)),
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text(LocaleProvider.instance.l10n.frGenerated(_date.format(generatedOn)),
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                pw.Text(
                    LocaleProvider.instance.l10n.frCounts(sortedFields.length, _num2.format(totalHa), equipment.length, people.length),
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ]),
            ],
          ),

          // Fields register
          sectionTitle(LocaleProvider.instance.l10n.frFieldsSection),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(2.4),
              1: const pw.FlexColumnWidth(1.6),
              2: const pw.FlexColumnWidth(2.0),
              3: const pw.FlexColumnWidth(2.4),
              4: const pw.FlexColumnWidth(1.4),
            },
            children: [
              pw.TableRow(children: [
                hCell(LocaleProvider.instance.l10n.frBlockField, left: true),
                hCell(LocaleProvider.instance.l10n.xlsType, left: true),
                hCell(LocaleProvider.instance.l10n.fmCrop, left: true),
                hCell(LocaleProvider.instance.l10n.fmVariety, left: true),
                hCell(LocaleProvider.instance.l10n.frAreaHa),
              ]),
              ...sortedFields.map((f) => pw.TableRow(children: [
                    c(f.name.trim(), left: true, bold: true),
                    c(f.fieldType, left: true),
                    c(cropOf(f), left: true),
                    c(varOf(f), left: true),
                    c(_num2.format(f.areaHectares)),
                  ])),
              pw.TableRow(children: [
                c('TOTAL', left: true, bold: true),
                c(''),
                c(''),
                c(''),
                c(_num2.format(totalHa), bold: true, color: accent),
              ]),
            ],
          ),

          // Equipment register
          sectionTitle(LocaleProvider.instance.l10n.frEquipmentSection),
          if (equipment.isEmpty)
            pw.Text(LocaleProvider.instance.l10n.fmNoEquipmentRecord,
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
          else
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(2.4),
                1: const pw.FlexColumnWidth(1.8),
                2: const pw.FlexColumnWidth(1.8),
                3: const pw.FlexColumnWidth(2.0),
                4: const pw.FlexColumnWidth(1.6),
                5: const pw.FlexColumnWidth(1.8),
              },
              children: [
                pw.TableRow(children: [
                  hCell(LocaleProvider.instance.l10n.fmEquipment, left: true),
                  hCell(LocaleProvider.instance.l10n.xlsType, left: true),
                  hCell(LocaleProvider.instance.l10n.frCapacity, left: true),
                  hCell(LocaleProvider.instance.l10n.frRate, left: true),
                  hCell(LocaleProvider.instance.l10n.frRegNo, left: true),
                  hCell(LocaleProvider.instance.l10n.frInspection, left: true),
                ]),
                ...equipment.map((e) {
                  final noInspection = e.inspectionDate == null;
                  return pw.TableRow(children: [
                    c(e.name.trim(), left: true, bold: true),
                    c(e.equipmentType, left: true),
                    c(e.tankSize ?? '-', left: true),
                    c(e.rate ?? '-', left: true),
                    c((e.registrationNumber?.isNotEmpty == true)
                        ? e.registrationNumber!
                        : '-', left: true),
                    c(
                        noInspection
                            ? 'MISSING'
                            : _date.format(e.inspectionDate!),
                        left: true,
                        bold: noInspection,
                        color: noInspection ? PdfColors.red700 : null),
                  ]);
                }),
              ],
            ),

          // People
          sectionTitle(LocaleProvider.instance.l10n.frPeopleSection),
          if (people.isEmpty)
            pw.Text(LocaleProvider.instance.l10n.fmNoPeople,
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
          else
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(2.4),
                1: const pw.FlexColumnWidth(3.0),
                2: const pw.FlexColumnWidth(1.8),
              },
              children: [
                pw.TableRow(children: [
                  hCell(LocaleProvider.instance.l10n.frName, left: true),
                  hCell(LocaleProvider.instance.l10n.frEmail, left: true),
                  hCell(LocaleProvider.instance.l10n.frRole, left: true),
                ]),
                ...people.map((p) => pw.TableRow(children: [
                      c(p.member.fullName, left: true, bold: true),
                      c(p.member.email, left: true),
                      c(p.role, left: true),
                    ])),
              ],
            ),

          pw.SizedBox(height: 16),
          pw.Text(
            LocaleProvider.instance.l10n.frSource,
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );

    return doc.save();
  }
}
