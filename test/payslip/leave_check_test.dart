import 'package:cropCompliance/views/payslip/utils/leave_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<LeaveShortfall> check(Map<LeaveType, double> req,
          Map<LeaveType, double> avail) =>
      findLeaveShortfalls(
          employeeId: 'e1',
          employeeName: 'Test Worker',
          requested: req,
          available: avail);

  test('no shortfall when within balance', () {
    expect(check({LeaveType.sick: 8}, {LeaveType.sick: 8}), isEmpty);
    expect(check({LeaveType.sick: 0}, {LeaveType.sick: 0}), isEmpty);
  });

  test('flags each leave type that exceeds its balance', () {
    final s = check(
      {LeaveType.sick: 16, LeaveType.holiday: 4, LeaveType.family: 8},
      {LeaveType.sick: 8, LeaveType.holiday: 10, LeaveType.family: 0},
    );
    expect(s.map((x) => x.type), [LeaveType.sick, LeaveType.family]);
    expect(s.first.over, 8);
  });

  test('negative balances count as zero available', () {
    final s = check({LeaveType.sick: 4}, {LeaveType.sick: -3});
    expect(s.single.available, 0);
  });

  test('ignores rounding noise', () {
    expect(check({LeaveType.sick: 8.001}, {LeaveType.sick: 8}), isEmpty);
  });

  test('choices map to the hours kept on the payslip', () {
    final s = check({LeaveType.holiday: 16}, {LeaveType.holiday: 6}).single;
    expect(s.hoursFor(ShortfallChoice.payAvailable), 6);
    expect(s.hoursFor(ShortfallChoice.remove), 0);
    expect(s.hoursFor(ShortfallChoice.overridePay), 16);
  });
}
