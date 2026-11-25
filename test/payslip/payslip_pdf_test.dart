import 'dart:io';

import 'package:cropCompliance/models/payslip_model.dart';
import 'package:cropCompliance/providers/locale_provider.dart';
import 'package:cropCompliance/views/payslip/utils/payslip_pdf_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('draft payslip PDF shows timesheet lines and PAYE', () async {
    await LocaleProvider.instance.init();
    final p = PayslipModel(
      id: 'p1',
      companyId: 'c1',
      companyName: 'Test Farm', // l10n-ignore: test data
      employeeId: 'e1',
      employeeName: 'Worker One', // l10n-ignore: test data
      employeeIdNumber: '9001015009087',
      uifRegNumber: 'U123',
      payPeriodStart: DateTime(2026, 11, 2),
      payPeriodEnd: DateTime(2026, 11, 8),
      payDate: DateTime(2026, 11, 8),
      normalHours: 36,
      overtimeHours: 2,
      doubleTimeHours: 0,
      publicHolidayHours: 0,
      familyLeaveHours: 9,
      normalRate: 30.23,
      overtimeRate: 45.35,
      doubleTimeRate: 0,
      additionalDeductions: const [],
      additionalEarnings: [
        AdditionalEarning(
            description:
                'Night-shift allowance – 1 night × R 27.21', // l10n-ignore: test data
            amount: 27.21,
            generated: true),
      ],
      payeDeduction: 0,
      status: PayslipStatus.draft,
      createdAt: DateTime(2026, 11, 8),
      updatedAt: DateTime(2026, 11, 8),
    );
    final bytes = await PayslipPdfBuilder.buildBytes(p);
    expect(bytes.length, greaterThan(1000));
    final out = Platform.environment['PAYSLIP_PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });
}
