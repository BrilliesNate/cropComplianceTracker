import 'package:cloud_firestore/cloud_firestore.dart';

class SickLeaveAllocation {
  final String id;
  final DateTime allocatedOn;
  final double hours;
  final String note;

  SickLeaveAllocation({
    required this.id,
    required this.allocatedOn,
    required this.hours,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'allocatedOn': Timestamp.fromDate(allocatedOn),
        'hours': hours,
        'note': note,
      };

  factory SickLeaveAllocation.fromMap(Map<String, dynamic> map) =>
      SickLeaveAllocation(
        id: map['id'] ?? '',
        allocatedOn:
            (map['allocatedOn'] as Timestamp?)?.toDate() ?? DateTime.now(),
        hours: (map['hours'] ?? 0.0).toDouble(),
        note: map['note'] ?? '',
      );
}

class LeaveBalanceModel {
  final String employeeId;
  final String companyId;
  // Opening leave balances (in HOURS) the employee had already accumulated
  // BEFORE the company started using this system. Entered directly by the admin
  // — NOT derived from hours worked. This fixes long-tenured employees whose
  // real leave predates the app. Balance = opening + accrued-in-system − taken.
  final double openingHolidayHours;
  final double openingSickHours;
  final double openingFamilyHours;
  // Admin-granted sick leave batches (30 days each, after 6-month mark or per 3-year cycle)
  final List<SickLeaveAllocation> sickLeaveAllocations;
  // Annual family responsibility leave hours allocated (admin grants when eligible)
  final double familyLeaveAllocatedHours;
  final DateTime? familyLeaveAllocYear;
  final DateTime updatedAt;

  const LeaveBalanceModel({
    required this.employeeId,
    required this.companyId,
    this.openingHolidayHours = 0,
    this.openingSickHours = 0,
    this.openingFamilyHours = 0,
    this.sickLeaveAllocations = const [],
    this.familyLeaveAllocatedHours = 0,
    this.familyLeaveAllocYear,
    required this.updatedAt,
  });

  double get totalSickLeaveAllocated =>
      sickLeaveAllocations.fold(0.0, (sum, a) => sum + a.hours);

  factory LeaveBalanceModel.empty(String employeeId, String companyId) =>
      LeaveBalanceModel(
        employeeId: employeeId,
        companyId: companyId,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'employeeId': employeeId,
        'companyId': companyId,
        'openingHolidayHours': openingHolidayHours,
        'openingSickHours': openingSickHours,
        'openingFamilyHours': openingFamilyHours,
        'sickLeaveAllocations':
            sickLeaveAllocations.map((a) => a.toMap()).toList(),
        'familyLeaveAllocatedHours': familyLeaveAllocatedHours,
        'familyLeaveAllocYear': familyLeaveAllocYear != null
            ? Timestamp.fromDate(familyLeaveAllocYear!)
            : null,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory LeaveBalanceModel.fromMap(
          Map<String, dynamic> map, String employeeId) =>
      LeaveBalanceModel(
        employeeId: employeeId,
        companyId: map['companyId'] ?? '',
        openingHolidayHours: (map['openingHolidayHours'] ?? 0.0).toDouble(),
        openingSickHours: (map['openingSickHours'] ?? 0.0).toDouble(),
        openingFamilyHours: (map['openingFamilyHours'] ?? 0.0).toDouble(),
        sickLeaveAllocations: ((map['sickLeaveAllocations'] as List?) ?? [])
            .map((a) => SickLeaveAllocation.fromMap(a as Map<String, dynamic>))
            .toList(),
        familyLeaveAllocatedHours:
            (map['familyLeaveAllocatedHours'] ?? 0.0).toDouble(),
        familyLeaveAllocYear:
            (map['familyLeaveAllocYear'] as Timestamp?)?.toDate(),
        updatedAt:
            (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  LeaveBalanceModel copyWith({
    double? openingHolidayHours,
    double? openingSickHours,
    double? openingFamilyHours,
    List<SickLeaveAllocation>? sickLeaveAllocations,
    double? familyLeaveAllocatedHours,
    DateTime? familyLeaveAllocYear,
  }) =>
      LeaveBalanceModel(
        employeeId: employeeId,
        companyId: companyId,
        openingHolidayHours: openingHolidayHours ?? this.openingHolidayHours,
        openingSickHours: openingSickHours ?? this.openingSickHours,
        openingFamilyHours: openingFamilyHours ?? this.openingFamilyHours,
        sickLeaveAllocations:
            sickLeaveAllocations ?? this.sickLeaveAllocations,
        familyLeaveAllocatedHours:
            familyLeaveAllocatedHours ?? this.familyLeaveAllocatedHours,
        familyLeaveAllocYear: familyLeaveAllocYear ?? this.familyLeaveAllocYear,
        updatedAt: DateTime.now(),
      );
}
