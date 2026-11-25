import 'dart:io';

import 'package:cropCompliance/models/employee_model.dart';
import 'package:cropCompliance/providers/locale_provider.dart';
import 'package:cropCompliance/views/payslip/timesheet/timesheet_calc.dart';
import 'package:cropCompliance/views/payslip/timesheet/timesheet_pdf.dart';
import 'package:cropCompliance/views/payslip/timesheet/timesheet_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('timesheet PDF builds with all three sheets', () async {
    await LocaleProvider.instance.init();
    final period =
        PayPeriodRecord.draft('c1', PeriodType.monthly, DateTime(2026, 11, 1));
    final workers = [
      for (var i = 0; i < 26; i++)
        EmployeeModel.fromMap({
          'name': 'Worker ${i + 1}', // l10n-ignore: test data
          'normalHourlyRate': 30.23,
          'companyId': 'c1',
        }, 'e$i'),
    ];
    final sheets = {
      'e0': WorkerSheets(normal: {
        '2026-11-02': const NormalDay(hours: 9),
        '2026-11-03': const NormalDay(code: 'SL'),
        '2026-11-04': const NormalDay(code: 'HL'),
        '2026-11-05': const NormalDay(code: 'FL'),
        '2026-11-06': const NormalDay(code: 'A'),
      }, overtime: {
        '2026-11-02': const OvertimeDay(hours: 2, finish: '21:30'),
      }, piece: {
        '2026-11-07': const PieceDay(hours: 8, units: 10),
      }, comment: 'Late Tuesday'), // l10n-ignore: test data
    };
    final bytes = await TimesheetPdf.build(
      companyName: 'Test Farm', // l10n-ignore: test data
      period: period,
      workers: workers,
      sheets: sheets,
      rates: const TimesheetRates(
          overtimeMultiplier: 1.5,
          nightAllowancePercent: 10,
          minimumHourlyWage: 30.23,
          topUpPeriod: 'day',
          ordinaryDayHours: 9),
      pieceRate: const PieceRateInfo(
          id: 'p',
          taskOrCrop: 'Apples',
          unitType: 'bins',
          rate: 20), // l10n-ignore: test data
    );
    expect(bytes.length, greaterThan(1000));
    final out = Platform.environment['TIMESHEET_PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });
}
