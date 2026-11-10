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
    expect(_reason(sel, noBank),
        startsWith('None of these employees have banking details'));
  });

  test('mixed exclusions point to the Not included list', () {
    final mixed = [
      _emp('e1', 'Willem Botha', bank: false),
      _emp('e2', 'Jan Smit'),
    ];
    final sel = [
      _slip('p1', 'e1', 'Willem Botha'),
      _slip('p2', 'e2', 'Jan Smit', hours: 0), // R 0 net pay
    ];
    expect(_reason(sel, mixed), 'No one can be paid — see "Not included" below.');
  });
}
