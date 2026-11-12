import 'package:cropCompliance/models/employee_model.dart';
import 'package:cropCompliance/models/payslip_model.dart';

import 'timesheet_calc.dart';
import 'timesheet_service.dart';

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// The existing payslip for [employeeId] in [period], if any (keyed by worker
/// + period, as in the spec).
PayslipModel? payslipFor(
    List<PayslipModel> payslips, String employeeId, PayPeriodRecord period) {
  for (final p in payslips) {
    if (p.employeeId == employeeId &&
        sameDay(p.payPeriodStart, period.start) &&
        sameDay(p.payPeriodEnd, period.end)) {
      return p;
    }
  }
  return null;
}

/// Builds (or rebuilds) a worker's payslip from their timesheet figures.
///
/// Keeps everything the user set on an existing payslip by hand — its
/// deductions, any earnings lines the timesheet didn't generate, a PAYE
/// override, the pay date — and replaces only the timesheet-driven parts.
/// Status follows the period: Draft until the period is finalised.
PayslipModel buildTimesheetPayslip({
  required PayslipModel? existing,
  required EmployeeModel employee,
  required PayPeriodRecord period,
  required PayslipFigures figures,
  required String companyName,
  required String companyAddress,
  required String uifRegNumber,
  double? sickLeaveHours,
  double? holidayLeaveHours,
}) {
  final rate = employee.normalHourlyRate;
  final keptEarnings = (existing?.additionalEarnings ?? const [])
      .where((e) => !isTimesheetLine(e.description))
      .toList();
  final earnings = [
    ...keptEarnings,
    for (final e in figures.earnings)
      AdditionalEarning(description: e.description, amount: e.amount),
  ];

  PayslipModel build(double paye, bool auto) => PayslipModel(
        id: existing?.id ?? '',
        companyId: period.companyId,
        companyName: companyName,
        companyAddress: companyAddress,
        employeeId: employee.id,
        employeeName: employee.name,
        employeeIdNumber: employee.idNumber,
        employmentType: employee.employmentType,
        jobDescription: employee.jobDescription,
        uifRegNumber: uifRegNumber,
        payPeriodStart: period.start,
        payPeriodEnd: period.end,
        payDate: existing?.payDate ?? period.end,
        normalHours: figures.normalHours,
        overtimeHours: figures.overtimeHours,
        doubleTimeHours: 0,
        publicHolidayHours: figures.publicHolidayHours,
        sickLeaveHours: sickLeaveHours ?? figures.sickLeaveHours,
        holidayLeaveHours: holidayLeaveHours ?? figures.holidayLeaveHours,
        familyLeaveHours: existing?.familyLeaveHours ?? 0,
        normalRate: rate,
        overtimeRate: figures.overtimeRate ?? existing?.overtimeRate ?? 0,
        doubleTimeRate: existing?.doubleTimeRate ?? 0,
        additionalDeductions: existing?.additionalDeductions ?? const [],
        additionalEarnings: earnings,
        payeDeduction: paye,
        payeAutoCalculated: auto,
        status:
            period.finalised ? PayslipStatus.finalised : PayslipStatus.draft,
        createdAt: existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

  // PAYE: keep a typed override; otherwise frequency-aware auto PAYE on the
  // new taxable gross.
  if (existing != null && !existing.payeAutoCalculated) {
    return build(existing.payeDeduction, false);
  }
  final draft = build(0, true);
  final paye = PayslipModel.calculatePayeForPeriod(
      draft.totalEarnings, period.start, period.end);
  return build(paye, true);
}

/// The same payslip with a different status (used by Finalise / Unlock).
PayslipModel withStatus(PayslipModel p, PayslipStatus status) {
  final map = p.toMap()..['status'] = status.value;
  return PayslipModel.fromMap(map, p.id);
}
