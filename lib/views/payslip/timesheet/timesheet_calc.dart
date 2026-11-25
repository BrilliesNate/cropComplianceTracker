/// Timesheet logic (no widgets / Firestore; texts come from the app's
/// translations) — parsing cells, night-work
/// detection, totals, warnings, and turning a worker's sheets into payslip
/// figures. Every rate comes from [TimesheetRates] (configuration); nothing
/// statutory is hard-coded here. See the Payslip Manager timesheet spec.
library;

import 'dart:math' as math;
import 'package:cropCompliance/providers/locale_provider.dart';

// ── Leave codes on the Normal-hours sheet ──────────────────────────────────

/// SL sick · HL holiday (annual) · FL family responsibility ·
/// PH public holiday · A absent (unpaid). Stored on the sheet as these codes
/// whatever the app language.
const List<String> leaveCodes = ['SL', 'HL', 'FL', 'PH', 'A'];

/// Other spellings people type, mapped to the stored code: AL (the old annual
/// leave code — earlier sheets were saved with it) and the Afrikaans codes the
/// Payslip Manager shows (SV siekverlof, VV vakansieverlof, GV
/// gesinsverantwoordelikheidsverlof, OV openbare vakansiedag).
const Map<String, String> leaveCodeAliases = {
  'AL': 'HL',
  'SV': 'SL',
  'VV': 'HL',
  'GV': 'FL',
  'OV': 'PH',
};

/// The code as shown in the app language (SV / VV / GV / OV in Afrikaans);
/// the sheet always stores the English code.
String leaveCodeLabel(String code) {
  final l10n = LocaleProvider.instance.l10n;
  return switch (code) {
    'SL' => l10n.leaveCodeSL,
    'HL' => l10n.leaveCodeHL,
    'FL' => l10n.leaveCodeFL,
    'PH' => l10n.leaveCodePH,
    'A' => l10n.leaveCodeA,
    _ => code,
  };
}

/// What a leave code means, e.g. "Holiday leave".
String leaveCodeName(String code) {
  final l10n = LocaleProvider.instance.l10n;
  return switch (code) {
    'SL' => l10n.tsCodeSL,
    'HL' => l10n.tsCodeHL,
    'FL' => l10n.tsCodeFL,
    'PH' => l10n.tsCodePH,
    _ => l10n.tsCodeA,
  };
}

/// The stored code for what was typed, or null when it isn't a leave code.
String? normaliseLeaveCode(String raw) {
  final upper = raw.trim().toUpperCase();
  if (leaveCodes.contains(upper)) return upper;
  return leaveCodeAliases[upper];
}

/// Leave codes paid from a balance (and checked against it when saving).
const Set<String> balanceLeaveCodes = {'SL', 'HL', 'FL'};

/// One day on the Normal-hours sheet: ordinary hours OR a leave code.
class NormalDay {
  final double? hours;
  final String? code;

  /// For SL / HL / FL days: what was chosen in "Not enough leave left" —
  /// the hours paid for this day (0 = unpaid; a full day = paid anyway).
  /// null = no choice made: paid in full if the balance allows (checked on
  /// every save). Typing the code again clears it.
  final double? paid;

  const NormalDay({this.hours, this.code, this.paid});

  bool get isEmpty => (hours == null || hours == 0) && code == null;

  /// A choice was made for this leave day when saving.
  bool get settled => paid != null && balanceLeaveCodes.contains(code);

  Map<String, dynamic> toMap() => code != null
      ? {'c': code, if (paid != null) 'p': paid}
      : {'h': hours ?? 0};

  static NormalDay fromMap(Map m) => NormalDay(
        hours: (m['h'] as num?)?.toDouble(),
        code: m['c'] == null
            ? null
            : normaliseLeaveCode(m['c'] as String) ?? m['c'] as String,
        paid: (m['p'] as num?)?.toDouble(),
      );
}

/// Hours paid for one leave day: the choice made when saving, else a full
/// ordinary day.
double paidLeaveHours(NormalDay d, double dayH) =>
    d.settled ? d.paid!.clamp(0, dayH).toDouble() : dayH;

/// [code] leave on one worker's Normal sheet, in hours: [pending] = days with
/// no choice yet (checked against the balance on save), [settled] = hours
/// already chosen to be paid.
({double pending, double settled}) leaveHoursFor(
    WorkerSheets s, Iterable<String> days, String code, double dayH) {
  double pending = 0, settled = 0;
  for (final k in days) {
    final d = s.normal[k];
    if (d == null || d.code != code) continue;
    if (d.settled) {
      settled += paidLeaveHours(d, dayH);
    } else {
      pending += dayH;
    }
  }
  return (pending: pending, settled: settled);
}

/// Writes the "Not enough leave left" choice onto the [code] days that had no
/// choice yet: pays up to [payHours] in date order — full days, then part of a
/// day — and the remaining days are unpaid. Use [double.infinity] to pay all.
void settleLeave(WorkerSheets s, Iterable<String> days, String code,
    double dayH, double payHours) {
  var left = payHours;
  for (final k in [...days]..sort()) {
    final d = s.normal[k];
    if (d == null || d.code != code || d.settled) continue;
    final pay = left >= dayH ? dayH : (left > 0 ? left : 0.0);
    left -= pay;
    s.normal[k] = NormalDay(code: code, paid: (pay * 100).round() / 100);
  }
}

/// Leave hours not paid because the balance was short (settled days).
double unpaidLeaveHours(WorkerSheets s, Iterable<String> days, double dayH) {
  double total = 0;
  for (final k in days) {
    final d = s.normal[k];
    if (d == null || !d.settled) continue;
    total += dayH - paidLeaveHours(d, dayH);
  }
  return total;
}

/// Parses what the user typed in a Normal-hours cell: a number (9, 7.5,
/// "7,5") or a leave code (case-insensitive). Returns null for blank and
/// throws [FormatException] for anything else.
NormalDay? parseNormalCell(String raw) {
  final t = raw.trim();
  if (t.isEmpty || t == '-' || t == '–') return null;
  final code = normaliseLeaveCode(t);
  if (code != null) return NormalDay(code: code);
  final v = double.tryParse(t.replaceAll(',', '.'));
  if (v == null || v < 0 || v > 24) {
    throw const FormatException(
        'Type hours (e.g. 9) or SL / HL / FL / PH / A'); // l10n-ignore: not shown
  }
  return v == 0 ? null : NormalDay(hours: v);
}

String formatNormalCell(NormalDay? d) {
  if (d == null) return '';
  if (d.code != null) return d.code!;
  return formatHours(d.hours ?? 0);
}

String formatHours(double v) => v == v.roundToDouble()
    ? v.toStringAsFixed(0)
    : v.toStringAsFixed(2).replaceAll(RegExp(r'0$'), '');

/// Parses an hours field (overtime / piece hours). Blank → null.
double? parseHours(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final v = double.tryParse(t.replaceAll(',', '.'));
  if (v == null || v < 0 || v > 24) {
    throw const FormatException(
        'Type hours, e.g. 2 or 1.5'); // l10n-ignore: not shown
  }
  return v == 0 ? null : v;
}

/// Parses a units field (bins, crates). Blank → null.
double? parseUnits(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final v = double.tryParse(t.replaceAll(',', '.'));
  if (v == null || v < 0)
    throw const FormatException(
        'Type a number of units'); // l10n-ignore: not shown
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
    throw const FormatException(
        'Type the finish time, e.g. 21:30'); // l10n-ignore: not shown
  }
  if (h < 0 || h > 23 || m < 0 || m > 59) {
    throw const FormatException(
        'Type the finish time, e.g. 21:30'); // l10n-ignore: not shown
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
  final int sickDays, holidayDays, familyDays, publicHolidayDays, absentDays;
  final double overtimeHours;
  final int nightShiftDays;
  final double pieceHours;
  final double units;

  const WorkerTotals({
    this.normalHours = 0,
    this.sickDays = 0,
    this.holidayDays = 0,
    this.familyDays = 0,
    this.publicHolidayDays = 0,
    this.absentDays = 0,
    this.overtimeHours = 0,
    this.nightShiftDays = 0,
    this.pieceHours = 0,
    this.units = 0,
  });

  int get leaveDays =>
      sickDays + holidayDays + familyDays + publicHolidayDays + absentDays;

  /// Days per leave code, in the order of [leaveCodes]; codes not used are
  /// left out.
  Map<String, int> get leaveByCode => {
        for (final e in {
          'SL': sickDays,
          'HL': holidayDays,
          'FL': familyDays,
          'PH': publicHolidayDays,
          'A': absentDays,
        }.entries)
          if (e.value > 0) e.key: e.value,
      };

  /// "SL 1 · HL 2" style summary for the Leave column.
  String get leaveSummary =>
      leaveByCode.entries.map((e) => '${e.key} ${e.value}').join(' · ');
}

WorkerTotals totalsFor(WorkerSheets s, {Iterable<String>? days}) {
  bool inPeriod(String d) => days == null || days.contains(d);
  double nh = 0, ot = 0, ph = 0, units = 0;
  int sl = 0, hl = 0, fl = 0, pub = 0, ab = 0, ns = 0;
  s.normal.forEach((d, v) {
    if (!inPeriod(d)) return;
    switch (v.code) {
      case 'SL':
        sl++;
        break;
      case 'HL':
      case 'AL': // older sheets
        hl++;
        break;
      case 'FL':
        fl++;
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
    holidayDays: hl,
    familyDays: fl,
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

  /// Ordinary hours in a working day — used for leave days (SL/HL/FL/PH) and
  /// the "ordinary daily wage" behind the night-shift allowance.
  final double ordinaryDayHours;

  /// Warning thresholds (SD13 cl 13): don't block saving, just flag.
  final double weeklyOvertimeLimit;
  final double dailyHoursLimit;

  /// Piecework minimum-wage top-up is worked out per 'day' or per 'week'
  /// (Mon–Sun) — it differs per client, so it must be chosen; null = not set.
  final String? topUpPeriod;

  /// The weekdays the farm's workers normally work (1 = Monday … 7 = Sunday).
  /// Decides how a worked public holiday is paid (SD13). Null = not set.
  final List<int>? ordinaryWorkDays;

  const TimesheetRates({
    this.overtimeMultiplier,
    this.nightAllowancePercent,
    this.minimumHourlyWage,
    this.ordinaryDayHours = 8,
    this.weeklyOvertimeLimit = 15,
    this.dailyHoursLimit = 12,
    this.topUpPeriod,
    this.ordinaryWorkDays,
  });

  Map<String, dynamic> toMap() => {
        'overtimeMultiplier': overtimeMultiplier,
        'nightAllowancePercent': nightAllowancePercent,
        'minimumHourlyWage': minimumHourlyWage,
        'ordinaryDayHours': ordinaryDayHours,
        'weeklyOvertimeLimit': weeklyOvertimeLimit,
        'dailyHoursLimit': dailyHoursLimit,
        'topUpPeriod': topUpPeriod,
        'ordinaryWorkDays': ordinaryWorkDays,
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
      topUpPeriod: (m['topUpPeriod'] == 'day' || m['topUpPeriod'] == 'week')
          ? m['topUpPeriod'] as String
          : null,
      ordinaryWorkDays: (m['ordinaryWorkDays'] as List?)
          ?.map((e) => (e as num).toInt())
          .where((d) => d >= 1 && d <= 7)
          .toList(),
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
// Generated lines are now marked (AdditionalEarning.generated). These English
// prefixes still recognise lines saved before that, so they get replaced too.
const String nightAllowancePrefix =
    'Night-shift allowance'; // l10n-ignore: legacy match
const String piecePayPrefix = 'Piecework'; // l10n-ignore: legacy match
const String topUpPrefix = 'Minimum wage top-up'; // l10n-ignore: legacy match
const String sundayMinimumPrefix =
    'Sunday minimum pay'; // l10n-ignore: legacy match
const String publicHolidayWorkedPrefix =
    'Public holiday worked'; // l10n-ignore: legacy match
/// Ids of the rates a payslip may still be missing (see [PayslipFigures.missingRates]).
const missingOvertime = 'overtime';
const missingNight = 'night';
const missingPieceRate = 'pieceRate';
const missingMinWage = 'minWage';
const missingTopUpPeriod = 'topUpPeriod';
const missingWorkDays = 'workDays';

bool isTimesheetLine(String description) =>
    description.startsWith(nightAllowancePrefix) ||
    description.startsWith(piecePayPrefix) ||
    description.startsWith(topUpPrefix) ||
    description.startsWith(sundayMinimumPrefix) ||
    description.startsWith(publicHolidayWorkedPrefix);

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
  final double familyLeaveHours;
  final double publicHolidayHours;

  /// Hours worked on Sundays — paid at double the ordinary wage (SD13).
  final double sundayHours;
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
    this.familyLeaveHours = 0,
    required this.publicHolidayHours,
    this.sundayHours = 0,
    required this.overtimeRate,
    required this.earnings,
    required this.pieceEarnings,
    required this.topUp,
    required this.missingRates,
  });

  bool get canCalculate => missingRates.isEmpty;

  /// Piece pay fell below the minimum wage (a top-up was needed) — the
  /// timesheet shows these workers in red.
  bool get belowMinimumWage => (topUp ?? 0) > 0;
}

double _r2(double v) => (v * 100).roundToDouble() / 100;
String _rand(double v) => 'R ${v.toStringAsFixed(2)}';

/// Turns one worker's sheets into payslip figures, using only configured
/// rates. Anything that needs a missing rate is listed in [missingRates]
/// instead of being guessed.
///
/// Sundays and public holidays follow SD13 (confirmed by the client), not
/// the 1.5× overtime rate:
///  * Sunday: double the ordinary hourly wage for every hour worked (normal
///    and overtime columns); if that comes to less than the ordinary daily
///    wage, the worker gets the daily wage (minimum payment).
///  * Public holiday worked, on a day the worker normally works: the greater
///    of 2 × the daily wage, or the daily wage + pay for the hours worked.
///  * Public holiday worked, on a day not normally worked: the daily wage +
///    pay for the hours worked.
///  * Public holiday not worked: "PH" on the normal sheet = one daily wage.
PayslipFigures payslipFiguresFor({
  required WorkerSheets sheets,
  required Iterable<String> days,
  required double hourlyRate,
  required TimesheetRates rates,
  PieceRateInfo? pieceRate,
}) {
  final dayList = days.toList();
  final t = totalsFor(sheets, days: dayList);
  final missing = <String>[];
  final earnings = <EarningLine>[];
  final dailyWage = hourlyRate * rates.ordinaryDayHours;

  // ── Sundays and public holidays (taken out of normal / overtime hours) ──
  double normalHours = t.normalHours;
  double overtimeHours = t.overtimeHours;
  double sundayHours = 0;
  double sundayTopUp = 0;
  int sundayTopUpDays = 0;
  for (final d in dayList) {
    final n = sheets.normal[d];
    final normalPart = n != null && n.code == null ? (n.hours ?? 0) : 0.0;
    final otPart = sheets.overtime[d]?.hours ?? 0;
    final worked = normalPart + otPart;
    if (worked <= 0) continue;
    final date = DateTime.parse(d);

    if (date.weekday == DateTime.sunday) {
      normalHours -= normalPart;
      overtimeHours -= otPart;
      sundayHours += worked;
      final pay = 2 * hourlyRate * worked;
      if (pay < dailyWage) {
        sundayTopUp += dailyWage - pay;
        sundayTopUpDays++;
      }
    } else if (isSaPublicHoliday(date)) {
      normalHours -= normalPart;
      overtimeHours -= otPart;
      final workDays = rates.ordinaryWorkDays;
      if (workDays == null) {
        if (!missing.contains(missingWorkDays)) {
          missing.add(missingWorkDays);
        }
        continue;
      }
      final hoursPay = hourlyRate * worked;
      final normallyWorked = workDays.contains(date.weekday);
      final amount = normallyWorked
          ? math.max(2 * dailyWage, dailyWage + hoursPay)
          : dailyWage + hoursPay;
      earnings.add(EarningLine(
          normallyWorked
              ? LocaleProvider.instance.l10n.tsLinePhWorkedNormal(
                  d, formatHours(worked), _rand(dailyWage), _rand(hourlyRate))
              : LocaleProvider.instance.l10n.tsLinePhWorkedOff(
                  d, formatHours(worked), _rand(dailyWage), _rand(hourlyRate)),
          _r2(amount)));
    }
  }
  if (sundayTopUp > 0) {
    earnings.add(EarningLine(
        LocaleProvider.instance.l10n
            .tsLineSundayMin(sundayTopUpDays, _rand(dailyWage)),
        _r2(sundayTopUp)));
  }

  double? otRate;
  if (overtimeHours > 0) {
    if (rates.overtimeMultiplier == null) {
      missing.add(missingOvertime);
    } else {
      otRate = _r2(hourlyRate * rates.overtimeMultiplier!);
    }
  }

  if (t.nightShiftDays > 0) {
    if (rates.nightAllowancePercent == null) {
      missing.add(missingNight);
    } else {
      final perDay = dailyWage * rates.nightAllowancePercent! / 100;
      earnings.add(EarningLine(
          LocaleProvider.instance.l10n
              .tsLineNight(t.nightShiftDays, _rand(perDay)),
          _r2(perDay * t.nightShiftDays)));
    }
  }

  double? pieceEarnings, topUp;
  if (t.units > 0 || t.pieceHours > 0) {
    if (pieceRate == null) {
      missing.add(missingPieceRate);
    } else {
      pieceEarnings = _r2(t.units * pieceRate.rate);
      earnings.add(EarningLine(
          LocaleProvider.instance.l10n.tsLinePiece(formatHours(t.units),
              pieceRate.unitType, _rand(pieceRate.rate), pieceRate.taskOrCrop),
          pieceEarnings));
    }
    if (rates.minimumHourlyWage == null) {
      missing.add(missingMinWage);
    }
    if (rates.topUpPeriod == null) {
      missing.add(missingTopUpPeriod);
    }
    if (pieceRate != null &&
        rates.minimumHourlyWage != null &&
        rates.topUpPeriod != null) {
      // NMWA s 5(3): piece pay may not be less than the minimum wage for the
      // hours worked — checked per day or per week (Mon–Sun), per client.
      final perDay = rates.topUpPeriod == 'day';
      final groups = <String, ({double hours, double units})>{};
      for (final d in dayList) {
        final p = sheets.piece[d];
        if (p == null) continue;
        final date = DateTime.parse(d);
        final key = perDay
            ? d
            : dayKey(date.subtract(Duration(days: date.weekday - 1)));
        final g = groups[key];
        groups[key] = (
          hours: (g?.hours ?? 0) + p.hours,
          units: (g?.units ?? 0) + p.units,
        );
      }
      var total = 0.0;
      var short = 0;
      for (final g in groups.values) {
        final floor = rates.minimumHourlyWage! * g.hours;
        final pay = g.units * pieceRate.rate;
        if (pay < floor) {
          total += floor - pay;
          short++;
        }
      }
      topUp = _r2(total);
      if (topUp > 0) {
        earnings.add(EarningLine(
            perDay
                ? LocaleProvider.instance.l10n
                    .tsLineTopUpDays(short, _rand(rates.minimumHourlyWage!))
                : LocaleProvider.instance.l10n
                    .tsLineTopUpWeeks(short, _rand(rates.minimumHourlyWage!)),
            topUp));
      }
    }
  }

  final dayH = rates.ordinaryDayHours;
  return PayslipFigures(
    normalHours: normalHours,
    overtimeHours: overtimeHours,
    sickLeaveHours: _paidOf(sheets, dayList, 'SL', dayH),
    holidayLeaveHours: _paidOf(sheets, dayList, 'HL', dayH),
    familyLeaveHours: _paidOf(sheets, dayList, 'FL', dayH),
    publicHolidayHours: t.publicHolidayDays * dayH,
    sundayHours: sundayHours,
    overtimeRate: otRate,
    earnings: earnings,
    pieceEarnings: pieceEarnings,
    topUp: topUp,
    missingRates: missing,
  );
}

double _paidOf(
    WorkerSheets s, Iterable<String> days, String code, double dayH) {
  final h = leaveHoursFor(s, days, code, dayH);
  return h.pending + h.settled;
}

// ── South African public holidays ──────────────────────────────────────────

/// Easter Sunday (Gregorian calendar, anonymous algorithm).
DateTime easterSunday(int year) {
  final a = year % 19, b = year ~/ 100, c = year % 100;
  final d = b ~/ 4, e = b % 4, f = (b + 8) ~/ 25, g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4, k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = ((h + l - 7 * m + 114) % 31) + 1;
  return DateTime(year, month, day);
}

/// The statutory public holidays (Public Holidays Act 36 of 1994), with a
/// holiday that falls on a Sunday moved to the Monday. Once-off holidays
/// (e.g. election days) aren't included — mark those days "PH" by hand.
Set<String> saPublicHolidays(int year) {
  final fixed = [
    DateTime(year, 1, 1), // New Year's Day
    DateTime(year, 3, 21), // Human Rights Day
    DateTime(year, 4, 27), // Freedom Day
    DateTime(year, 5, 1), // Workers' Day
    DateTime(year, 6, 16), // Youth Day
    DateTime(year, 8, 9), // National Women's Day
    DateTime(year, 9, 24), // Heritage Day
    DateTime(year, 12, 16), // Day of Reconciliation
    DateTime(year, 12, 25), // Christmas Day
    DateTime(year, 12, 26), // Day of Goodwill
  ];
  final easter = easterSunday(year);
  final out = <String>{
    dayKey(easter.subtract(const Duration(days: 2))), // Good Friday
    dayKey(easter.add(const Duration(days: 1))), // Family Day
  };
  for (final d in fixed) {
    out.add(dayKey(
        d.weekday == DateTime.sunday ? d.add(const Duration(days: 1)) : d));
  }
  return out;
}

final _holidayCache = <int, Set<String>>{};
bool isSaPublicHoliday(DateTime d) => _holidayCache
    .putIfAbsent(d.year, () => saPublicHolidays(d.year))
    .contains(dayKey(d));

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
      out.add(LocaleProvider.instance.l10n.tsWarnDay(
          formatHours(total), d, formatHours(rates.dailyHoursLimit)));
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
      out.add(LocaleProvider.instance.l10n.tsWarnWeek(
          formatHours(h), week, formatHours(rates.weeklyOvertimeLimit)));
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
        return LocaleProvider.instance.l10n.periodWeekly;
      case PeriodType.fortnightly:
        return LocaleProvider.instance.l10n.periodFortnightly;
      case PeriodType.monthly:
        return LocaleProvider.instance.l10n.periodMonthly;
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
