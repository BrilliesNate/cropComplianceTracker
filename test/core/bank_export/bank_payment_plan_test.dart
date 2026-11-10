import 'package:cropCompliance/core/bank_export/templates/capitec_template.dart';
import 'package:cropCompliance/models/employee_model.dart';
import 'package:cropCompliance/models/payslip_model.dart';
import 'package:cropCompliance/views/payslip/utils/bank_payment_export.dart';
import 'package:flutter_test/flutter_test.dart';

// Fictitious test data only.
final _now = DateTime(2026, 11, 1);

EmployeeModel _emp(String id, String name, {bool bank = true}) =>
    EmployeeModel(
      id: id,
      companyId: 'c1',
      name: name,
      idNumber: '',
      normalHourlyRate: 30,
      accountNumber: bank ? '1234567890' : '',
      branchCode: bank ? '470010' : '',
      createdAt: _now,
      updatedAt: _now,
    );

PayslipModel _slip(String id, String empId, String name,
        {bool draft = false, double hours = 100}) =>
    PayslipModel(
      id: id,
      companyId: 'c1',
      companyName: 'Test Farm',
      employeeId: empId,
      employeeName: name,
      employeeIdNumber: '',
      uifRegNumber: '',
      payPeriodStart: _now,
      payPeriodEnd: _now.add(const Duration(days: 29)),
      payDate: _now.add(const Duration(days: 30)),
      normalHours: hours,
      overtimeHours: 0,
      doubleTimeHours: 0,
      publicHolidayHours: 0,
      normalRate: 30,
      overtimeRate: 45,
      doubleTimeRate: 60,
      additionalDeductions: const [],
      status: draft ? PayslipStatus.draft : PayslipStatus.finalised,
      createdAt: _now,
      updatedAt: _now,
    );

String? _reason(List<PayslipModel> selected, List<EmployeeModel> emps,
    {bool bank = true, DraftChoice choice = DraftChoice.undecided}) {
  final drafts = selected.where((p) => !p.isFinalised).length;
  final included = choice == DraftChoice.remove
      ? selected.where((p) => p.isFinalised).toList()
      : selected;
  final plan = BankPaymentExport.plan(included, emps,
      template: bank ? const CapitecTemplate() : null);
  return BankPaymentExport.disabledReason(
    selectedCount: selected.length,
    bankChosen: bank,
    draftCount: drafts,
    draftChoice: choice,
    plan: plan,
  );
}

void main() {
  final emps = [_emp('e1', 'Willem Botha'), _emp('e2', 'Jan Smit')];

  test('draft payslips are still payable — the plan never drops them', () {
    final plan = BankPaymentExport.plan(
        [_slip('p1', 'e1', 'Willem Botha', draft: true)], emps);
    expect(plan.ready.length, 1);
    expect(plan.draftCount, 1);
  });

  test('enabled when a bank is chosen and nobody is excluded', () {
    expect(_reason([_slip('p1', 'e1', 'Willem Botha')], emps), isNull);
  });

  test('no bank chosen gives a one-line reason', () {
    expect(_reason([_slip('p1', 'e1', 'Willem Botha')], emps, bank: false),
        'Choose the bank the farm pays from.');
  });

  test('undecided drafts block with a reason; remove or include unblocks',
      () {
    final sel = [
      _slip('p1', 'e1', 'Willem Botha', draft: true),
      _slip('p2', 'e2', 'Jan Smit'),
    ];
    expect(_reason(sel, emps), contains('1 draft payslip selected'));
    expect(_reason(sel, emps, choice: DraftChoice.remove), isNull);
    expect(_reason(sel, emps, choice: DraftChoice.include), isNull);
  });

  test('removing drafts when every payslip is a draft explains why', () {
    final sel = [_slip('p1', 'e1', 'Willem Botha', draft: true)];
    expect(_reason(sel, emps, choice: DraftChoice.remove),
        startsWith('All selected payslips are drafts'));
  });

  test('employees without banking details are excluded with a reason', () {
    final noBank = [_emp('e1', 'Willem Botha', bank: false)];
    final sel = [_slip('p1', 'e1', 'Willem Botha')];
    final plan = BankPaymentExport.plan(sel, noBank);
    expect(plan.ready, isEmpty);
    expect(plan.skipped.single.reason, 'no banking details');
    expect(plan.skipped.single.kind, SkipKind.noBankingDetails);
    expect(plan.skipped.single.employee?.id, 'e1');
    expect(_reason(sel, noBank), startsWith('Nobody has banking details'));
  });

  test('mixed exclusions point to the list of fixes', () {
    final mixed = [
      _emp('e1', 'Willem Botha', bank: false),
      _emp('e2', 'Jan Smit'),
    ];
    final sel = [
      _slip('p1', 'e1', 'Willem Botha'),
      _slip('p2', 'e2', 'Jan Smit', hours: 0), // R 0 net pay
    ];
    final plan = BankPaymentExport.plan(sel, mixed);
    expect(plan.skipped.map((s) => s.kind).toSet(),
        {SkipKind.noBankingDetails, SkipKind.nonPositivePay});
    expect(_reason(sel, mixed), startsWith('Nobody can be paid yet'));
  });

  group('payslips whose employee record was removed', () {
    // Payslip points at "old-id" (deleted); the person was re-added as e9.
    PayslipModel orphan({String idNo = '9001015009087', String name = 'Piet Venter'}) =>
        PayslipModel(
          id: 'p9',
          companyId: 'c1',
          companyName: 'Test Farm',
          employeeId: 'old-id',
          employeeName: name,
          employeeIdNumber: idNo,
          uifRegNumber: '',
          payPeriodStart: _now,
          payPeriodEnd: _now.add(const Duration(days: 29)),
          payDate: _now,
          normalHours: 100,
          overtimeHours: 0,
          doubleTimeHours: 0,
          publicHolidayHours: 0,
          normalRate: 30,
          overtimeRate: 45,
          doubleTimeRate: 60,
          additionalDeductions: const [],
          status: PayslipStatus.finalised,
          createdAt: _now,
          updatedAt: _now,
        );

    EmployeeModel readded({String idNo = '9001015009087', String id = 'e9'}) =>
        EmployeeModel(
          id: id,
          companyId: 'c1',
          name: 'Piet Venter',
          idNumber: idNo,
          normalHourlyRate: 30,
          accountNumber: '1234567890',
          branchCode: '470010',
          createdAt: _now,
          updatedAt: _now,
        );

    test('matched by ID number, paid, and offered as a relink', () {
      final plan = BankPaymentExport.plan([orphan()], [readded()]);
      expect(plan.ready.single.employee.id, 'e9');
      expect(plan.relinks['p9']?.id, 'e9');
    });

    test('matched by exact name when there is no ID number', () {
      final plan = BankPaymentExport.plan(
          [orphan(idNo: '')], [readded(idNo: '')]);
      expect(plan.ready.single.employee.id, 'e9');
    });

    test('never guesses between two people with the same name', () {
      final plan = BankPaymentExport.plan([orphan(idNo: '')],
          [readded(idNo: '', id: 'a'), readded(idNo: '', id: 'b')]);
      expect(plan.ready, isEmpty);
      expect(plan.skipped.single.kind, SkipKind.missingEmployee);
      expect(plan.skipped.single.payslips.single.id, 'p9');
    });

    test('truly missing → missingEmployee with a fix-oriented reason', () {
      final plan = BankPaymentExport.plan([orphan()], emps);
      expect(plan.skipped.single.kind, SkipKind.missingEmployee);
      expect(_reason([orphan()], emps), contains('aren\'t linked'));
    });
  });
}
