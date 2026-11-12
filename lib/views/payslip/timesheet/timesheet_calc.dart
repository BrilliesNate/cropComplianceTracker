/// Pure timesheet logic (no Flutter / Firestore) — parsing cells, night-work
/// detection, totals, warnings, and turning a worker's sheets into payslip
/// figures. Every rate comes from [TimesheetRates] (configuration); nothing
/// statutory is hard-coded here. See the Payslip Manager timesheet spec.
library;

// ── Leave codes on the Normal-hours sheet ──────────────────────────────────

/// SL sick · AL annual · PH public holiday · A absent (unpaid).
const Set<String> leaveCodes = {'SL', 'AL', 'PH', 'A'};

/// One day on the Normal-hours sheet: ordinary hours OR a leave code.
class NormalDay {
  final double? hours;
  final String? code;
  const NormalDay({this.hours, this.code});

  bool get isEmpty => (hours == null || hours == 0) && code == null;

  Map<String, dynamic> toMap() =>
      code != null ? {'c': code} : {'h': hours ?? 0};

  static NormalDay fromMap(Map m) => NormalDay(
        hours: (m['h'] as num?)?.toDouble(),
        code: m['c'] as String?,
      );
}

/// Parses what the user typed in a Normal-hours cell: a number (9, 7.5,
/// "7,5") or a leave code (case-insensitive). Returns null for blank and
/// throws [FormatException] for anything else.
NormalDay? parseNormalCell(String raw) {
  final t = raw.trim();
  if (t.isEmpty || t == '-' || t == '–') return null;
  final upper = t.toUpperCase();
  if (leaveCodes.contains(upper)) return NormalDay(code: upper);
  final v = double.tryParse(t.replaceAll(',', '.'));
  if (v == null || v < 0 || v > 24) {
    throw const FormatException('Type hours (e.g. 9) or SL / AL / PH / A');
  }
  return v == 0 ? null : NormalDay(hours: v);
}

String formatNormalCell(NormalDay? d) {
  if (d == null) return '';
  if (d.code != null) return d.code!;
  return formatHours(d.hours ?? 0);
}

String formatHours(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2).replaceAll(RegExp(r'0$'), '');

/// Parses an hours field (overtime / piece hours). Blank → null.
double? parseHours(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final v = double.tryParse(t.replaceAll(',', '.'));
  if (v == null || v < 0 || v > 24) {
    throw const FormatException('Type hours, e.g. 2 or 1.5');
  }
  return v == 0 ? null : v;
}

/// Parses a units field (bins, crates). Blank → null.
double? parseUnits(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final v = double.tryParse(t.replaceAll(',', '.'));
  if (v == null || v < 0) throw const FormatException('Type a number of units');
  return v == 0 ? null : v;
}

// ── Overtime finish time & night work ──────────────────────────────────────

/// Normalises a typed finish time: "21:30", "2130", "21h30", "9:05" → "HH:MM".
/// Blank → null. Throws [FormatException] if it isn't a valid time.
String? parseFinishTime(String raw) {
  var t = raw.trim().toLowerCase().replaceAll('h', ':').replaceAll('.', ':');
  if (t.isEmpty) return null;
  int h, m;
  if (t.contains(':')) {
    final p = t.split(':');
    h = int.tryParse(p[0]) ?? -1;
    m = int.tryParse(p.length > 1 && p[1].isNotEmpty ? p[1] : '0') ?? -1;
  } else if (RegExp(r'^\d{3,4}$').hasMatch(t)) {
    h = int.parse(t.substring(0, t.length - 2));
    m = int.parse(t.substring(t.length - 2));
  } else if (RegExp(r'^\d{1,2}$').hasMatch(t)) {
    h = int.parse(t);
    m = 0;
  } else {
    throw const FormatException('Type the finish time, e.g. 21:30');
  }
  if (h < 0 || h > 23 || m < 0 || m > 59) {
    throw const FormatException('Type the finish time, e.g. 21:30');
  }
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// SD13 clause 17: night work is work performed AFTER 20:00 and BEFORE 04:00.
/// A shift is flagged NS when its finish time falls in that window; 20:00
/// and 04:00 exactly fall outside it (to be confirmed with Patrick).
bool isNightWork(String? finish) {
  if (finish == null) return false;
  final p = finish.split(':');
  if (p.length != 2) return false;
  final mins = (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  return mins > 20 * 60 || mins < 4 * 60;
}

class OvertimeDay {
  final double hours;
  final String? finish; // "HH:MM"
  const OvertimeDay({required this.hours, this.finish});

  bool get night => isNightWork(finish);

  Map<String, dynamic> toMap() => {'h': hours, if (finish != null) 'f': finish};
  static OvertimeDay fromMap(Map m) => OvertimeDay(
        hours: (m['h'] as num?)?.toDouble() ?? 0,
        finish: m['f'] as String?,
      );
}

class PieceDay {
  final double hours;
  final double units;
  const PieceDay({required this.hours, required this.units});

  Map<String, dynamic> toMap() => {'h': hours, 'u': units};
  static PieceDay fromMap(Map m) => PieceDay(
        hours: (m['h'] as num?)?.toDouble() ?? 0,
        units: (m['u'] as num?)?.toDouble() ?? 0,
      );
}

/// Everything one worker has on the three sheets for one pay period.
/// Day keys are "yyyy-MM-dd".
class WorkerSheets {
  final Map<String, NormalDay> normal;
  final Map<String, OvertimeDay> overtime;
  final Map<String, PieceDay> piece;
  String comment;

  WorkerSheets({
    Map<String, NormalDay>? normal,
    Map<String, OvertimeDay>? overtime,
    Map<String, PieceDay>? piece,
    this.comment = '',
  })  : normal = normal ?? {},
        overtime = overtime ?? {},
        piece = piece ?? {};

  bool get isEmpty =>
      normal.values.every((d) => d.isEmpty) &&
      overtime.isEmpty &&
      piece.isEmpty &&
      comment.trim().isEmpty;
}

// ── Totals ─────────────────────────────────────────────────────────────────

class WorkerTotals {
  final double normalHours;
  final int sickDays, annualDays, publicHolidayDays, absentDays;
  final double overtimeHours;
  final int nightShiftDays;
  final double pieceHours;
  final double units;

  const WorkerTotals({
    this.normalHours = 0,
    this.sickDays = 0,
    this.annualDays = 0,
    this.publicHolidayDays = 0,
    this.absentDays = 0,
    this.overtimeHours = 0,
    this.nightShiftDays = 0,
    this.pieceHours = 0,
    this.units = 0,
  });

  int get leaveDays => sickDays + annualDays + publicHolidayDays + absentDays;

  /// "SL 1 · AL 2" style summary for the Leave column.
  String get leaveSummary => [
        if (sickDays > 0) 'SL $sickDays',
        if (annualDays > 0) 'AL $annualDays',
        if (publicHolidayDays > 0) 'PH $publicHolidayDays',
        if (absentDays > 0) 'A $absentDays',
      ].join(' · ');
}

WorkerTotals totalsFor(WorkerSheets s, {Iterable<String>? days}) {
  bool inPeriod(String d) => days == null || days.contains(d);
  double nh = 0, ot = 0, ph = 0, units = 0;
  int sl = 0, al = 0, pub = 0, ab = 0, ns = 0;
  s.normal.forEach((d, v) {
    if (!inPeriod(d)) return;
    switch (v.code) {
      case 'SL':
        sl++;
        break;
      case 'AL':
        al++;
        break;
      case 'PH':
        pub++;
        break;
      case 'A':
        ab++;
        break;
      default:
        nh += v.hours ?? 0;
    }
  });
  s.overtime.forEach((d, v) {
    if (!inPeriod(d)) return;
    ot += v.hours;
    if (v.night && v.hours > 0) ns++;
  });
  s.piece.forEach((d, v) {
    if (!inPeriod(d)) return;
    ph += v.hours;
    units += v.units;
  });
  return WorkerTotals(
    normalHours: nh,
    sickDays: sl,
    annualDays: al,
    publicHolidayDays: pub,
    absentDays: ab,
    overtimeHours: ot,
    nightShiftDays: ns,
    pieceHours: ph,
    units: units,
  );
}

// ── Rates (configuration) ──────────────────────────────────────────────────

/// Per-farm rates. Nullable on purpose: until someone has confirmed a figure
/// the timesheet shows "R —" and won't calculate that part of the payslip.
class TimesheetRates {
  /// e.g. 1.5 (SD13 cl 14) — confirm with Patrick.
  final double? overtimeMultiplier;

  /// Night-shift allowance as % of the ordinary daily wage, e.g. 10 (SD13 cl 17).
  final double? nightAllowancePercent;

  /// Farm-worker minimum wage per ordinary hour for the period (NMWA).
  final double? minimumHourlyWage;

  /// Ordinary hours in a working day — used for leave days (SL/AL/PH) and
  /// the "ordinary daily wage" behind the night-shift allowance.
  final double ordinaryDayHours;

  /// Warning thresholds (SD13 cl 13): don't block saving, just flag.
  final double weeklyOvertimeLimit;
  final double dailyHoursLimit;

  const TimesheetRates({
    this.overtimeMultiplier,
    this.nightAllowancePercent,
    this.minimumHourlyWage,
    this.ordinaryDayHours = 8,
    this.weeklyOvertimeLimit = 15,
    this.dailyHoursLimit = 12,
  });

  Map<String, dynamic> toMap() => {
        'overtimeMultiplier': overtimeMultiplier,
        'nightAllowancePercent': nightAllowancePercent,
        'minimumHourlyWage': minimumHourlyWage,
        'ordinaryDayHours': ordinaryDayHours,
        'weeklyOvertimeLimit': weeklyOvertimeLimit,
        'dailyHoursLimit': dailyHoursLimit,
      };

  static TimesheetRates fromMap(Map? m) {
    if (m == null) return const TimesheetRates();
    double? d(String k) => (m[k] as num?)?.toDouble();
    return TimesheetRates(
      overtimeMultiplier: d('overtimeMultiplier'),
      nightAllowancePercent: d('nightAllowancePercent'),
      minimumHourlyWage: d('minimumHourlyWage'),
      ordinaryDayHours: d('ordinaryDayHours') ?? 8,
      weeklyOvertimeLimit: d('weeklyOvertimeLimit') ?? 15,
      dailyHoursLimit: d('dailyHoursLimit') ?? 12,
    );
  }
}

/// A configured piece rate (task/crop + unit + rand per unit).
class PieceRateInfo {
  final String id;
  final String taskOrCrop;
  final String unitType; // bins, crates, …
  final double rate;
  const PieceRateInfo({
    required this.id,
    required this.taskOrCrop,
    required this.unitType,
    required this.rate,
  });

  String get label => '$taskOrCrop · $unitType';
}

// ── Payslip figures ────────────────────────────────────────────────────────

/// Payslip lines generated by the timesheet. Their descriptions start with
/// these prefixes so a recalculation can replace them without touching lines
/// the user added by hand.
const String nightAllowancePrefix = 'Night-shift allowance';
const String piecePayPrefix = 'Piecework';
const String topUpPrefix = 'Minimum wage top-up';
bool isTimesheetLine(String description) =>
    description.startsWith(nightAllowancePrefix) ||
    description.startsWith(piecePayPrefix) ||
    description.startsWith(topUpPrefix);

class EarningLine {
  final String description;
  final double amount;
  const EarningLine(this.description, this.amount);
}

class PayslipFigures {
  final double normalHours;
  final double overtimeHours;
  final double sickLeaveHours;
  final double holidayLeaveHours;
  final double publicHolidayHours;
  final double? overtimeRate; // null → multiplier not configured
  final List<EarningLine> earnings;
  final double? pieceEarnings;
  final double? topUp;

  /// Rates still needed before this worker's payslip can be calculated.
  final List<String> missingRates;

  const PayslipFigures({
    required this.normalHours,
    required this.overtimeHours,
    required this.sickLeaveHours,
    required this.holidayLeaveHours,
    required this.publicHolidayHours,
    required this.overtimeRate,
    required this.earnings,
    required this.pieceEarnings,
    required this.topUp,
    required this.missingRates,
  });

  bool get canCalculate => missingRates.isEmpty;
}

double _r2(double v) => (v * 100).roundToDouble() / 100;
String _rand(double v) => 'R ${v.toStringAsFixed(2)}';

/// Turns one worker's sheets into payslip figures, using only configured
/// rates. Anything that needs a missing rate is listed in [missingRates]
/// instead of being guessed.
PayslipFigures payslipFiguresFor({
  required WorkerSheets sheets,
  required Iterable<String> days,
  required double hourlyRate,
  required TimesheetRates rates,
  PieceRateInfo? pieceRate,
}) {
  final t = totalsFor(sheets, days: days);
  final missing = <String>[];
  final earnings = <EarningLine>[];

  double? otRate;
  if (t.overtimeHours > 0) {
    if (rates.overtimeMultiplier == null) {
      missing.add('overtime multiplier');
    } else {
      otRate = _r2(hourlyRate * rates.overtimeMultiplier!);
    }
  }

  if (t.nightShiftDays > 0) {
    if (rates.nightAllowancePercent == null) {
      missing.add('night-shift allowance %');
    } else {
      final dailyWage = hourlyRate * rates.ordinaryDayHours;
      final perDay = dailyWage * rates.nightAllowancePercent! / 100;
      earnings.add(EarningLine(
          '$nightAllowancePrefix (${t.nightShiftDays} day${t.nightShiftDays == 1 ? '' : 's'} × ${_rand(perDay)})',
          _r2(perDay * t.nightShiftDays)));
    }
  }

  double? pieceEarnings, topUp;
  if (t.units > 0 || t.pieceHours > 0) {
    if (pieceRate == null) {
      missing.add('piece rate');
    } else {
      pieceEarnings = _r2(t.units * pieceRate.rate);
      earnings.add(EarningLine(
          '$piecePayPrefix: ${formatHours(t.units)} ${pieceRate.unitType} × ${_rand(pieceRate.rate)} (${pieceRate.taskOrCrop})',
          pieceEarnings));
    }
    if (rates.minimumHourlyWage == null) {
      missing.add('minimum hourly wage');
    } else if (pieceEarnings != null) {
      // NMWA s 5(3): not less than the minimum wage for the hours worked.
      // Assessed across the pay period (to be confirmed with Patrick).
      final floor = rates.minimumHourlyWage! * t.pieceHours;
      topUp = _r2((floor - pieceEarnings).clamp(0, double.infinity).toDouble());
      if (topUp > 0) {
        earnings.add(EarningLine(
            '$topUpPrefix (${formatHours(t.pieceHours)} h × ${_rand(rates.minimumHourlyWage!)} − piece pay)',
            topUp));
      }
    }
  }

  final dayH = rates.ordinaryDayHours;
  return PayslipFigures(
    normalHours: t.normalHours,
    overtimeHours: t.overtimeHours,
    sickLeaveHours: t.sickDays * dayH,
    holidayLeaveHours: t.annualDays * dayH,
    publicHolidayHours: t.publicHolidayDays * dayH,
    overtimeRate: otRate,
    earnings: earnings,
    pieceEarnings: pieceEarnings,
    topUp: topUp,
    missingRates: missing,
  );
}

// ── Warnings (SD13 cl 13 — warn, don't block) ──────────────────────────────

/// Plain-language warnings for one worker: days over the daily limit and
/// weeks (Mon–Sun) over the weekly overtime limit.
List<String> warningsFor(WorkerSheets s, TimesheetRates rates,
    {Iterable<String>? days}) {
  final out = <String>[];
  final allDays = <String>{
    ...s.normal.keys,
    ...s.overtime.keys,
    ...s.piece.keys,
  }.where((d) => days == null || days.contains(d)).toList()
    ..sort();

  for (final d in allDays) {
    final total = (s.normal[d]?.hours ?? 0) +
        (s.overtime[d]?.hours ?? 0) +
        (s.piece[d]?.hours ?? 0);
    if (total > rates.dailyHoursLimit + 0.001) {
      out.add('${formatHours(total)} h on $d (over ${formatHours(rates.dailyHoursLimit)} h a day)');
    }
  }

  final weekly = <String, double>{};
  s.overtime.forEach((d, v) {
    if (days != null && !days.contains(d)) return;
    final date = DateTime.parse(d);
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final key = dayKey(monday);
    weekly[key] = (weekly[key] ?? 0) + v.hours;
  });
  weekly.forEach((week, h) {
    if (h > rates.weeklyOvertimeLimit + 0.001) {
      out.add('${formatHours(h)} h overtime in week of $week (over ${formatHours(rates.weeklyOvertimeLimit)} h)');
    }
  });
  return out;
}

// ── Dates ──────────────────────────────────────────────────────────────────

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

enum PeriodType { weekly, fortnightly, monthly }

extension PeriodTypeX on PeriodType {
  String get key => name;
  String get label {
    switch (this) {
      case PeriodType.weekly:
        return 'Weekly';
      case PeriodType.fortnightly:
        return 'Fortnightly';
      case PeriodType.monthly:
        return 'Monthly';
    }
  }

  static PeriodType fromKey(String? k) => PeriodType.values
      .firstWhere((t) => t.name == k, orElse: () => PeriodType.weekly);

  /// Last day of a period starting on [start].
  DateTime endFor(DateTime start) {
    final s = DateTime(start.year, start.month, start.day);
    switch (this) {
      case PeriodType.weekly:
        return s.add(const Duration(days: 6));
      case PeriodType.fortnightly:
        return s.add(const Duration(days: 13));
      case PeriodType.monthly:
        return DateTime(s.year, s.month + 1, s.day)
            .subtract(const Duration(days: 1));
    }
  }

  /// The period after the one starting on [start].
  DateTime nextStart(DateTime start) =>
      endFor(start).add(const Duration(days: 1));
}

/// Every day from [start] to [end] inclusive.
List<DateTime> daysBetween(DateTime start, DateTime end) {
  final out = <DateTime>[];
  var d = DateTime(start.year, start.month, start.day);
  final last = DateTime(end.year, end.month, end.day);
  while (!d.isAfter(last)) {
    out.add(d);
    d = DateTime(d.year, d.month, d.day + 1);
  }
  return out;
}
