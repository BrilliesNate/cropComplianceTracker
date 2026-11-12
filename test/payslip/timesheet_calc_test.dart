import 'package:cropCompliance/views/payslip/timesheet/timesheet_calc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normal-hours cells', () {
    test('hours and leave codes', () {
      expect(parseNormalCell('9')!.hours, 9);
      expect(parseNormalCell('7,5')!.hours, 7.5);
      expect(parseNormalCell('sl')!.code, 'SL');
      expect(parseNormalCell('PH')!.code, 'PH');
      expect(parseNormalCell(''), isNull);
      expect(parseNormalCell('0'), isNull);
      expect(() => parseNormalCell('xx'), throwsFormatException);
      expect(() => parseNormalCell('30'), throwsFormatException);
    });
  });

  group('night work (SD13: after 20:00, before 04:00)', () {
    test('spec examples', () {
      expect(isNightWork('21:30'), isTrue);
      expect(isNightWork('22:00'), isTrue);
      expect(isNightWork('19:00'), isFalse);
      expect(isNightWork('18:30'), isFalse);
    });
    test('boundaries fall outside the window', () {
      expect(isNightWork('20:00'), isFalse);
      expect(isNightWork('20:01'), isTrue);
      expect(isNightWork('03:59'), isTrue);
      expect(isNightWork('04:00'), isFalse);
    });
    test('finish time parsing', () {
      expect(parseFinishTime('2130'), '21:30');
      expect(parseFinishTime('21:30'), '21:30');
      expect(parseFinishTime('9:5'), '09:05');
      expect(parseFinishTime('21h30'), '21:30');
      expect(parseFinishTime(''), isNull);
      expect(() => parseFinishTime('25:00'), throwsFormatException);
    });
  });

  test('totals across the three sheets', () {
    final s = WorkerSheets(normal: {
      '2026-08-04': const NormalDay(hours: 9),
      '2026-08-05': const NormalDay(code: 'SL'),
      '2026-08-06': const NormalDay(code: 'AL'),
      '2026-08-07': const NormalDay(code: 'A'),
    }, overtime: {
      '2026-08-04': const OvertimeDay(hours: 2, finish: '19:00'),
      '2026-08-07': const OvertimeDay(hours: 1.5, finish: '21:30'),
    }, piece: {
      '2026-08-08': const PieceDay(hours: 9, units: 14),
    });
    final t = totalsFor(s);
    expect(t.normalHours, 9);
    expect(t.sickDays, 1);
    expect(t.annualDays, 1);
    expect(t.absentDays, 1);
    expect(t.overtimeHours, 3.5);
    expect(t.nightShiftDays, 1);
    expect(t.units, 14);
    expect(t.leaveSummary, 'SL 1 · AL 1 · A 1');
  });

  group('payslip figures use configured rates only', () {
    final days = daysBetween(DateTime(2026, 8, 4), DateTime(2026, 8, 17))
        .map(dayKey);

    test('missing rates are reported, not guessed', () {
      final s = WorkerSheets(
        overtime: {'2026-08-04': const OvertimeDay(hours: 2, finish: '22:00')},
        piece: {'2026-08-05': const PieceDay(hours: 9, units: 10)},
      );
      final f = payslipFiguresFor(
          sheets: s, days: days, hourlyRate: 30, rates: const TimesheetRates());
      expect(f.canCalculate, isFalse);
      expect(f.missingRates, containsAll([
        'overtime multiplier',
        'night-shift allowance %',
        'piece rate',
        'minimum hourly wage',
      ]));
    });

    test('overtime, night allowance, leave days', () {
      final s = WorkerSheets(normal: {
        '2026-08-04': const NormalDay(code: 'SL'),
        '2026-08-05': const NormalDay(code: 'PH'),
      }, overtime: {
        '2026-08-06': const OvertimeDay(hours: 2, finish: '21:30'),
      });
      const rates = TimesheetRates(
          overtimeMultiplier: 1.5, nightAllowancePercent: 10, ordinaryDayHours: 8);
      final f = payslipFiguresFor(
          sheets: s, days: days, hourlyRate: 30, rates: rates);
      expect(f.canCalculate, isTrue);
      expect(f.overtimeRate, 45);
      expect(f.sickLeaveHours, 8);
      expect(f.publicHolidayHours, 8);
      // 10% of (30 × 8) = 24 for one NS day.
      expect(f.earnings.single.amount, 24);
      expect(isTimesheetLine(f.earnings.single.description), isTrue);
    });

    test('piece pay with a minimum-wage top-up', () {
      final s = WorkerSheets(piece: {
        '2026-08-04': const PieceDay(hours: 9, units: 8),
        '2026-08-05': const PieceDay(hours: 9, units: 7),
      });
      const rates = TimesheetRates(minimumHourlyWage: 30);
      const rate = PieceRateInfo(
          id: 'r', taskOrCrop: 'Harvest', unitType: 'bins', rate: 20);
      final f = payslipFiguresFor(
          sheets: s, days: days, hourlyRate: 30, rates: rates, pieceRate: rate);
      expect(f.pieceEarnings, 300); // 15 × 20
      expect(f.topUp, 240); // 18 h × 30 = 540 − 300
      expect(f.earnings.length, 2);
    });

    test('no top-up when piece pay beats the minimum', () {
      final s = WorkerSheets(piece: {
        '2026-08-04': const PieceDay(hours: 9, units: 20),
      });
      final f = payslipFiguresFor(
        sheets: s,
        days: days,
        hourlyRate: 30,
        rates: const TimesheetRates(minimumHourlyWage: 30),
        pieceRate: const PieceRateInfo(
            id: 'r', taskOrCrop: 'Harvest', unitType: 'bins', rate: 20),
      );
      expect(f.topUp, 0);
      expect(f.earnings.length, 1);
    });
  });

  test('warnings: daily and weekly limits', () {
    final s = WorkerSheets(normal: {
      '2026-08-04': const NormalDay(hours: 9),
    }, overtime: {
      '2026-08-04': const OvertimeDay(hours: 4),
      '2026-08-05': const OvertimeDay(hours: 6),
      '2026-08-06': const OvertimeDay(hours: 6),
    });
    final w = warningsFor(s, const TimesheetRates());
    expect(w.where((x) => x.contains('a day')).length, 1); // 13 h on the 4th
    expect(w.where((x) => x.contains('overtime in week')).length, 1); // 16 h
  });

  test('period types', () {
    final start = DateTime(2026, 8, 4);
    expect(PeriodType.weekly.endFor(start), DateTime(2026, 8, 10));
    expect(PeriodType.fortnightly.endFor(start), DateTime(2026, 8, 17));
    expect(PeriodType.monthly.endFor(DateTime(2026, 8, 1)),
        DateTime(2026, 8, 31));
    expect(daysBetween(start, DateTime(2026, 8, 17)).length, 14);
  });
}
