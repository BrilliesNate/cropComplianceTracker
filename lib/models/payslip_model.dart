import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cropCompliance/models/employee_model.dart';

class AdditionalDeduction {
  final String description;
  final double amount;

  AdditionalDeduction({required this.description, required this.amount});

  Map<String, dynamic> toMap() => {
        'description': description,
        'amount': amount,
      };

  factory AdditionalDeduction.fromMap(Map<String, dynamic> map) =>
      AdditionalDeduction(
        description: map['description'] ?? '',
        amount: (map['amount'] ?? 0.0).toDouble(),
      );

  AdditionalDeduction copyWith({String? description, double? amount}) =>
      AdditionalDeduction(
        description: description ?? this.description,
        amount: amount ?? this.amount,
      );
}

/// Mirror of [AdditionalDeduction] but for extra income lines
/// (e.g. bonus, allowance, reimbursement) added to the gross.
class AdditionalEarning {
  final String description;
  final double amount;

  AdditionalEarning({required this.description, required this.amount});

  Map<String, dynamic> toMap() => {
        'description': description,
        'amount': amount,
      };

  factory AdditionalEarning.fromMap(Map<String, dynamic> map) =>
      AdditionalEarning(
        description: map['description'] ?? '',
        amount: (map['amount'] ?? 0.0).toDouble(),
      );

  AdditionalEarning copyWith({String? description, double? amount}) =>
      AdditionalEarning(
        description: description ?? this.description,
        amount: amount ?? this.amount,
      );
}

enum PayslipStatus { draft, finalised }

extension PayslipStatusExtension on PayslipStatus {
  String get value => this == PayslipStatus.draft ? 'draft' : 'final';
  String get displayName => this == PayslipStatus.draft ? 'Draft' : 'Final';

  static PayslipStatus fromString(String? s) {
    if (s == 'final') return PayslipStatus.finalised;
    return PayslipStatus.draft;
  }
}

class PayslipModel {
  final String id;
  final String companyId;
  final String companyName;
  final String companyAddress; // snapshot of the company address at issue time
  final String employeeId;
  final String employeeName;
  final String employeeIdNumber;
  final EmploymentType employmentType; // snapshot of the worker's type
  final String jobDescription; // snapshot of the worker's job title
  final String uifRegNumber;
  final DateTime payPeriodStart;
  final DateTime payPeriodEnd;
  final DateTime payDate;
  final double normalHours;
  final double overtimeHours;
  final double doubleTimeHours;
  final double publicHolidayHours;
  final double sickLeaveHours;
  final double holidayLeaveHours;
  final double familyLeaveHours;
  final double normalRate;
  final double overtimeRate;
  final double doubleTimeRate;
  final List<AdditionalDeduction> additionalDeductions;
  final List<AdditionalEarning> additionalEarnings;
  // Stored at generation time so tax-bracket changes don't alter old payslips.
  final double payeDeduction;
  // True when payeDeduction was auto-calculated; false when the user typed an
  // override. Lets us re-derive PAYE on edit only when it wasn't overridden.
  final bool payeAutoCalculated;
  final PayslipStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  PayslipModel({
    required this.id,
    required this.companyId,
    required this.companyName,
    this.companyAddress = '',
    required this.employeeId,
    required this.employeeName,
    required this.employeeIdNumber,
    this.employmentType = EmploymentType.permanent,
    this.jobDescription = '',
    required this.uifRegNumber,
    required this.payPeriodStart,
    required this.payPeriodEnd,
    required this.payDate,
    required this.normalHours,
    required this.overtimeHours,
    required this.doubleTimeHours,
    required this.publicHolidayHours,
    this.sickLeaveHours = 0,
    this.holidayLeaveHours = 0,
    this.familyLeaveHours = 0,
    required this.normalRate,
    required this.overtimeRate,
    required this.doubleTimeRate,
    required this.additionalDeductions,
    this.additionalEarnings = const [],
    this.payeDeduction = 0,
    this.payeAutoCalculated = true,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── SA PAYE calculator (2025/26 tax year) ─────────────────────────────────

  /// Annual tax before rebates, per the 2025/26 SARS brackets.
  static double _annualTaxBeforeRebate(double annual) {
    if (annual <= 237100) return annual * 0.18;
    if (annual <= 370500) return 42678 + (annual - 237100) * 0.26;
    if (annual <= 512800) return 77362 + (annual - 370500) * 0.31;
    if (annual <= 673000) return 121475 + (annual - 512800) * 0.36;
    if (annual <= 857900) return 179147 + (annual - 673000) * 0.39;
    if (annual <= 1817000) return 251258 + (annual - 857900) * 0.41;
    return 644489 + (annual - 1817000) * 0.45;
  }

  /// How many pay periods per year the given period length represents.
  /// Weekly slips must be annualised ×52, fortnightly ×26, monthly ×12 —
  /// otherwise a week's pay is taxed as if it were a whole month (far too low).
  static int payPeriodsPerYear(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1; // inclusive
    if (days <= 10) return 52; // weekly
    if (days <= 20) return 26; // fortnightly
    return 12; // monthly (default)
  }

  /// PAYE for a single pay period, annualising by the period's frequency.
  /// This is the correct entry point — the gross passed is the gross *for that
  /// period* (e.g. one week), not a monthly figure.
  static double calculatePayeForPeriod(
      double periodGross, DateTime start, DateTime end) {
    final periods = payPeriodsPerYear(start, end);
    final annual = periodGross * periods;
    final afterRebate = _annualTaxBeforeRebate(annual) - 17235; // primary rebate
    final annualPaye = afterRebate < 0 ? 0.0 : afterRebate;
    return annualPaye / periods;
  }

  /// Legacy helper — assumes the gross is a monthly figure. Kept for callers
  /// that genuinely work monthly; prefer [calculatePayeForPeriod].
  static double calculateMonthlyPaye(double monthlyGross) {
    final afterRebate = _annualTaxBeforeRebate(monthlyGross * 12) - 17235;
    return afterRebate < 0 ? 0 : afterRebate / 12;
  }

  // ── Computed getters ──────────────────────────────────────────────────────
  double get normalPay => normalHours * normalRate;
  double get overtimePay => overtimeHours * overtimeRate;
  double get doubleTimePay => doubleTimeHours * doubleTimeRate;
  double get publicHolidayPay => publicHolidayHours * normalRate;
  double get sickLeavePay => sickLeaveHours * normalRate;
  double get holidayLeavePay => holidayLeaveHours * normalRate;
  double get familyLeavePay => familyLeaveHours * normalRate;
  double get hoursEarnings =>
      normalPay +
      overtimePay +
      doubleTimePay +
      publicHolidayPay +
      sickLeavePay +
      holidayLeavePay +
      familyLeavePay;
  double get additionalEarningsTotal =>
      additionalEarnings.fold(0.0, (sum, e) => sum + e.amount);
  double get totalEarnings => hoursEarnings + additionalEarningsTotal;
  double get uifDeduction => totalEarnings * 0.01;
  double get additionalDeductionsTotal =>
      additionalDeductions.fold(0.0, (sum, d) => sum + d.amount);
  double get totalDeductions =>
      uifDeduction + payeDeduction + additionalDeductionsTotal;
  double get netSalary => totalEarnings - totalDeductions;

  // Total hours that count toward leave accrual (worked hours, not leave hours)
  double get workedHoursForAccrual =>
      normalHours + overtimeHours + doubleTimeHours + publicHolidayHours;

  bool get isFinalised => status == PayslipStatus.finalised;

  // ── Serialisation ─────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'companyId': companyId,
        'companyName': companyName,
        'companyAddress': companyAddress,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'employeeIdNumber': employeeIdNumber,
        'employmentType': employmentType.key,
        'jobDescription': jobDescription,
        'uifRegNumber': uifRegNumber,
        'payPeriodStart': Timestamp.fromDate(payPeriodStart),
        'payPeriodEnd': Timestamp.fromDate(payPeriodEnd),
        'payDate': Timestamp.fromDate(payDate),
        'normalHours': normalHours,
        'overtimeHours': overtimeHours,
        'doubleTimeHours': doubleTimeHours,
        'publicHolidayHours': publicHolidayHours,
        'sickLeaveHours': sickLeaveHours,
        'holidayLeaveHours': holidayLeaveHours,
        'familyLeaveHours': familyLeaveHours,
        'normalRate': normalRate,
        'overtimeRate': overtimeRate,
        'doubleTimeRate': doubleTimeRate,
        'additionalDeductions':
            additionalDeductions.map((d) => d.toMap()).toList(),
        'additionalEarnings':
            additionalEarnings.map((e) => e.toMap()).toList(),
        'payeDeduction': payeDeduction,
        'payeAutoCalculated': payeAutoCalculated,
        'status': status.value,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory PayslipModel.fromMap(Map<String, dynamic> map, String id) =>
      PayslipModel(
        id: id,
        companyId: map['companyId'] ?? '',
        companyName: map['companyName'] ?? '',
        companyAddress: map['companyAddress'] ?? '',
        employeeId: map['employeeId'] ?? '',
        employeeName: map['employeeName'] ?? '',
        employeeIdNumber: map['employeeIdNumber'] ?? '',
        employmentType:
            EmploymentTypeX.fromKey(map['employmentType'] as String?),
        jobDescription: map['jobDescription'] ?? '',
        uifRegNumber: map['uifRegNumber'] ?? '',
        payPeriodStart:
            (map['payPeriodStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
        payPeriodEnd:
            (map['payPeriodEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
        payDate: (map['payDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        normalHours: (map['normalHours'] ?? 0.0).toDouble(),
        overtimeHours: (map['overtimeHours'] ?? 0.0).toDouble(),
        doubleTimeHours: (map['doubleTimeHours'] ?? 0.0).toDouble(),
        publicHolidayHours: (map['publicHolidayHours'] ?? 0.0).toDouble(),
        sickLeaveHours: (map['sickLeaveHours'] ?? 0.0).toDouble(),
        holidayLeaveHours: (map['holidayLeaveHours'] ?? 0.0).toDouble(),
        familyLeaveHours: (map['familyLeaveHours'] ?? 0.0).toDouble(),
        normalRate: (map['normalRate'] ?? 0.0).toDouble(),
        overtimeRate: (map['overtimeRate'] ?? 0.0).toDouble(),
        doubleTimeRate: (map['doubleTimeRate'] ?? 0.0).toDouble(),
        additionalDeductions:
            ((map['additionalDeductions'] as List?) ?? [])
                .map((d) =>
                    AdditionalDeduction.fromMap(d as Map<String, dynamic>))
                .toList(),
        additionalEarnings:
            ((map['additionalEarnings'] as List?) ?? [])
                .map((e) =>
                    AdditionalEarning.fromMap(e as Map<String, dynamic>))
                .toList(),
        payeDeduction: (map['payeDeduction'] ?? 0.0).toDouble(),
        payeAutoCalculated: map['payeAutoCalculated'] ?? true,
        status: PayslipStatusExtension.fromString(map['status']),
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
