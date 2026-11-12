/// Checks leave entered on payslips against each employee's balance, so the
/// user is told — and asked what to do — before paying leave someone hasn't got.
library;

enum LeaveType { sick, holiday, family }

extension LeaveTypeX on LeaveType {
  String get code {
    switch (this) {
      case LeaveType.sick:
        return 'SL';
      case LeaveType.holiday:
        return 'HL';
      case LeaveType.family:
        return 'FL';
    }
  }

  String get label {
    switch (this) {
      case LeaveType.sick:
        return 'sick leave';
      case LeaveType.holiday:
        return 'annual (holiday) leave';
      case LeaveType.family:
        return 'family responsibility leave';
    }
  }
}

/// What to do with leave hours beyond the balance.
enum ShortfallChoice {
  /// Pay only the hours still available; the rest is unpaid.
  payAvailable,

  /// Take the leave off this payslip entirely (unpaid).
  remove,

  /// Pay all the hours entered anyway (balance goes negative).
  overridePay,
}

/// One employee asking for more of one leave type than they have.
class LeaveShortfall {
  final String employeeId;
  final String employeeName;
  final LeaveType type;
  final double requested;

  /// Hours available for this payslip (never below 0).
  final double available;

  /// Extra context, e.g. why the balance is 0.
  final String? note;

  const LeaveShortfall({
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.requested,
    required this.available,
    this.note,
  });

  double get over => requested - available;

  /// Hours to keep on the payslip for [choice].
  double hoursFor(ShortfallChoice choice) {
    switch (choice) {
      case ShortfallChoice.payAvailable:
        return available;
      case ShortfallChoice.remove:
        return 0;
      case ShortfallChoice.overridePay:
        return requested;
    }
  }
}

/// Returns a shortfall for each leave type where [requested] exceeds
/// [available] (by more than a rounding margin).
///
/// [available] is the balance *for this payslip*: when re-saving an existing
/// payslip, the hours it already used must be added back by the caller.
List<LeaveShortfall> findLeaveShortfalls({
  required String employeeId,
  required String employeeName,
  required Map<LeaveType, double> requested,
  required Map<LeaveType, double> available,
  Map<LeaveType, String> notes = const {},
}) {
  final out = <LeaveShortfall>[];
  for (final type in LeaveType.values) {
    final req = requested[type] ?? 0;
    if (req <= 0) continue;
    final avail = (available[type] ?? 0).clamp(0, double.infinity).toDouble();
    if (req > avail + 0.005) {
      out.add(LeaveShortfall(
        employeeId: employeeId,
        employeeName: employeeName,
        type: type,
        requested: req,
        available: avail,
        note: notes[type],
      ));
    }
  }
  return out;
}
