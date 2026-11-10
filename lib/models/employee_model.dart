import 'package:cloud_firestore/cloud_firestore.dart';

/// Whether the worker is on a permanent contract or seasonal.
/// Required by BCEA auditors to be visible on the payslip.
enum EmploymentType { permanent, seasonal }

extension EmploymentTypeX on EmploymentType {
  /// Storage key used in Firestore.
  String get key =>
      this == EmploymentType.permanent ? 'permanent' : 'seasonal';

  /// English label for UI / PDF.
  String get label =>
      this == EmploymentType.permanent ? 'Permanent' : 'Seasonal';

  /// Afrikaans label for the payslip PDF.
  String get labelAfr =>
      this == EmploymentType.permanent ? 'Permanent' : 'Seisoen';

  static EmploymentType fromKey(String? k) =>
      k == 'seasonal' ? EmploymentType.seasonal : EmploymentType.permanent;
}

/// Bank account type, as used by SA bulk-payment (ACB-style) imports.
enum BankAccountType { current, savings, transmission }

extension BankAccountTypeX on BankAccountType {
  String get key => name;

  String get label {
    switch (this) {
      case BankAccountType.current:
        return 'Current / Cheque';
      case BankAccountType.savings:
        return 'Savings';
      case BankAccountType.transmission:
        return 'Transmission';
    }
  }

  /// Standard ACB account-type code: 1 = Current/Cheque, 2 = Savings,
  /// 3 = Transmission.
  String get acbCode {
    switch (this) {
      case BankAccountType.current:
        return '1';
      case BankAccountType.savings:
        return '2';
      case BankAccountType.transmission:
        return '3';
    }
  }

  static BankAccountType fromKey(String? k) => BankAccountType.values
      .firstWhere((t) => t.key == k, orElse: () => BankAccountType.savings);
}

/// Universal branch codes for the major SA banks — picking one of these in
/// the employee form fills the branch code automatically.
const Map<String, String> kSaUniversalBranchCodes = {
  'ABSA': '632005',
  'African Bank': '430000',
  'Capitec': '470010',
  'Discovery Bank': '679000',
  'FNB': '250655',
  'Investec': '580105',
  'Nedbank': '198765',
  'Standard Bank': '051001',
  'TymeBank': '678910',
};

class EmployeeModel {
  final String id;
  final String companyId;
  final String name;
  final String idNumber;
  final double normalHourlyRate;
  final DateTime? employmentStartDate;
  final EmploymentType employmentType;
  final String jobDescription;

  // ── Banking details (for the bulk-payment CSV) ──────────────────────────
  final String bankName;
  /// Name on the account, if it differs from the employee's name.
  final String accountHolderName;
  final String accountNumber;
  final String branchCode;
  final BankAccountType accountType;

  final DateTime createdAt;
  final DateTime updatedAt;

  EmployeeModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.idNumber,
    required this.normalHourlyRate,
    this.employmentStartDate,
    this.employmentType = EmploymentType.permanent,
    this.jobDescription = '',
    this.bankName = '',
    this.accountHolderName = '',
    this.accountNumber = '',
    this.branchCode = '',
    this.accountType = BankAccountType.savings,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Name the bank pays to — the account holder if set, else the employee.
  String get beneficiaryName =>
      accountHolderName.trim().isNotEmpty ? accountHolderName.trim() : name;

  /// First word of the employee's name, for "Salaries Willem"-style refs.
  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  /// True if any banking field has been filled in. Banking details are fully
  /// optional — employees without them are simply left out of the bank CSV.
  bool get hasAnyBankingDetails =>
      accountNumber.trim().isNotEmpty || branchCode.trim().isNotEmpty;

  /// Why this employee can't go in the bank CSV; empty list = ready to pay.
  List<String> get bankingIssues {
    if (!hasAnyBankingDetails) return const ['no banking details'];
    final issues = <String>[];
    final acc = accountNumber.replaceAll(RegExp(r'\s'), '');
    final branch = branchCode.replaceAll(RegExp(r'\s'), '');
    if (acc.isEmpty) {
      issues.add('no account number');
    } else if (!RegExp(r'^\d{6,16}$').hasMatch(acc)) {
      issues.add('account number must be 6–16 digits');
    }
    if (branch.isEmpty) {
      issues.add('no branch code');
    } else if (!RegExp(r'^\d{6}$').hasMatch(branch)) {
      issues.add('branch code must be 6 digits');
    }
    return issues;
  }

  bool get hasBankingDetails => bankingIssues.isEmpty;

  double get overtimeRate => normalHourlyRate * 1.5;
  double get doubleTimeRate => normalHourlyRate * 2.0;

  bool get isPostSixMonths {
    if (employmentStartDate == null) return false;
    return DateTime.now().difference(employmentStartDate!).inDays >= 183;
  }

  bool get isFamilyLeaveEligible {
    if (employmentStartDate == null) return false;
    return DateTime.now().difference(employmentStartDate!).inDays >= 120;
  }

  Map<String, dynamic> toMap() => {
        'companyId': companyId,
        'name': name,
        'idNumber': idNumber,
        'normalHourlyRate': normalHourlyRate,
        'employmentStartDate': employmentStartDate != null
            ? Timestamp.fromDate(employmentStartDate!)
            : null,
        'employmentType': employmentType.key,
        'jobDescription': jobDescription,
        'bankName': bankName,
        'accountHolderName': accountHolderName,
        'accountNumber': accountNumber,
        'branchCode': branchCode,
        'accountType': accountType.key,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory EmployeeModel.fromMap(Map<String, dynamic> map, String id) =>
      EmployeeModel(
        id: id,
        companyId: map['companyId'] ?? '',
        name: map['name'] ?? '',
        idNumber: map['idNumber'] ?? '',
        normalHourlyRate: (map['normalHourlyRate'] ?? 0.0).toDouble(),
        employmentStartDate:
            (map['employmentStartDate'] as Timestamp?)?.toDate(),
        employmentType:
            EmploymentTypeX.fromKey(map['employmentType'] as String?),
        jobDescription: map['jobDescription'] ?? '',
        bankName: map['bankName'] ?? '',
        accountHolderName: map['accountHolderName'] ?? '',
        accountNumber: map['accountNumber'] ?? '',
        branchCode: map['branchCode'] ?? '',
        accountType:
            BankAccountTypeX.fromKey(map['accountType'] as String?),
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  EmployeeModel copyWith({
    String? name,
    String? idNumber,
    double? normalHourlyRate,
    DateTime? employmentStartDate,
    EmploymentType? employmentType,
    String? jobDescription,
    String? bankName,
    String? accountHolderName,
    String? accountNumber,
    String? branchCode,
    BankAccountType? accountType,
    bool clearEmploymentStartDate = false,
  }) =>
      EmployeeModel(
        id: id,
        companyId: companyId,
        name: name ?? this.name,
        idNumber: idNumber ?? this.idNumber,
        normalHourlyRate: normalHourlyRate ?? this.normalHourlyRate,
        employmentStartDate: clearEmploymentStartDate
            ? null
            : (employmentStartDate ?? this.employmentStartDate),
        employmentType: employmentType ?? this.employmentType,
        jobDescription: jobDescription ?? this.jobDescription,
        bankName: bankName ?? this.bankName,
        accountHolderName: accountHolderName ?? this.accountHolderName,
        accountNumber: accountNumber ?? this.accountNumber,
        branchCode: branchCode ?? this.branchCode,
        accountType: accountType ?? this.accountType,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
