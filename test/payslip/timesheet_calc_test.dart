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
      '2026-08-06': const NormalDay(code: 'HL'),
      '2026-08-07': const NormalDay(code: 'A'),
      '2026-08-10': const NormalDay(code: 'FL'),
      '2026-08-11': const NormalDay(code: 'AL'), // older sheets
    }, overtime: {
      '2026-08-04': const OvertimeDay(hours: 2, finish: '19:00'),
      '2026-08-07': const OvertimeDay(hours: 1.5, finish: '21:30'),
    }, piece: {
      '2026-08-08': const PieceDay(hours: 9, units: 14),
    });
    final t = totalsFor(s);
    expect(t.normalHours, 9);
    expect(t.sickDays, 1);
    expect(t.holidayDays, 2);
    expect(t.familyDays, 1);
    expect(t.absentDays, 1);
    expect(t.overtimeHours, 3.5);
    expect(t.nightShiftDays, 1);
    expect(t.units, 14);
    expect(t.leaveSummary, 'SL 1 · HL 2 · FL 1 · A 1');
  });

  test('leave codes: HL / FL, old AL and Afrikaans spellings', () {
    expect(parseNormalCell('hl')!.code, 'HL');
    expect(parseNormalCell('FL')!.code, 'FL');
    expect(parseNormalCell('AL')!.code, 'HL');
    expect(parseNormalCell('sv')!.code, 'SL');
    expect(parseNormalCell('VV')!.code, 'HL');
    expect(parseNormalCell('GV')!.code, 'FL');
    expect(parseNormalCell('OV')!.code, 'PH');
    expect(NormalDay.fromMap({'c': 'AL'}).code, 'HL');
    expect(() => parseNormalCell('XL'), throwsFormatException);
  });

  test('family responsibility leave is paid as ordinary days', () {
    final s = WorkerSheets(normal: {
      '2026-08-04': const NormalDay(code: 'FL'),
      '2026-08-05': const NormalDay(code: 'HL'),
    });
    final f = payslipFiguresFor(
        sheets: s,
        days: ['2026-08-04', '2026-08-05'],
        hourlyRate: 30,
        rates: const TimesheetRates(ordinaryDayHours: 9));
    expect(f.familyLeaveHours, 9);
    expect(f.holidayLeaveHours, 9);
  });

  group('payslip figures use configured rates only', () {
    final days =
        daysBetween(DateTime(2026, 8, 4), DateTime(2026, 8, 17)).map(dayKey);

    test('missing rates are reported, not guessed', () {
      final s = WorkerSheets(
        overtime: {'2026-08-04': const OvertimeDay(hours: 2, finish: '22:00')},
        piece: {'2026-08-05': const PieceDay(hours: 9, units: 10)},
      );
      final f = payslipFiguresFor(
          sheets: s, days: days, hourlyRate: 30, rates: const TimesheetRates());
      expect(f.canCalculate, isFalse);
      expect(
          f.missingRates,
          containsAll([
            missingOvertime,
            missingNight,
            missingPieceRate,
            missingMinWage,
            missingTopUpPeriod,
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
          overtimeMultiplier: 1.5,
          nightAllowancePercent: 10,
          ordinaryDayHours: 8);
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
      const rates = TimesheetRates(minimumHourlyWage: 30, topUpPeriod: 'week');
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
        rates: const TimesheetRates(minimumHourlyWage: 30, topUpPeriod: 'day'),
        pieceRate: const PieceRateInfo(
            id: 'r', taskOrCrop: 'Harvest', unitType: 'bins', rate: 20),
      );
      expect(f.topUp, 0);
      expect(f.earnings.length, 1);
    });
  });

  group('confirmed client rules (13 Nov 2026)', () {
    final days =
        daysBetween(DateTime(2026, 8, 4), DateTime(2026, 8, 17)).map(dayKey);
    const harvest = PieceRateInfo(
        id: 'r', taskOrCrop: 'Harvest', unitType: 'bins', rate: 20);

    test('top-up per day vs per week', () {
      // Tue: 20 bins = R400 for 9 h (floor R270) → fine.
      // Wed:  5 bins = R100 for 9 h (floor R270) → R170 short.
      final s = WorkerSheets(piece: {
        '2026-08-04': const PieceDay(hours: 9, units: 20),
        '2026-08-05': const PieceDay(hours: 9, units: 5),
      });
      PayslipFigures run(String period) => payslipFiguresFor(
          sheets: s,
          days: days,
          hourlyRate: 30,
          rates: TimesheetRates(minimumHourlyWage: 30, topUpPeriod: period),
          pieceRate: harvest);
      expect(run('day').topUp, 170); // a good day can't cover a bad day
      expect(run('week').topUp, 40); // R500 for the week vs R540
      expect(run('day').belowMinimumWage, isTrue);
    });

    test('no top-up and not red when piece pay beats the minimum', () {
      final s = WorkerSheets(
          piece: {'2026-08-04': const PieceDay(hours: 9, units: 20)});
      final f = payslipFiguresFor(
          sheets: s,
          days: days,
          hourlyRate: 30,
          rates:
              const TimesheetRates(minimumHourlyWage: 30, topUpPeriod: 'week'),
          pieceRate: harvest);
      expect(f.belowMinimumWage, isFalse);
    });

    test('Sunday: double pay, at least the daily wage', () {
      // 16 Aug 2026 is a Sunday. 3 h normal + 0 OT at R30: 2 × 30 × 3 = 180,
      // below the daily wage (8 h × 30 = 240) → R60 minimum-pay line.
      final s = WorkerSheets(normal: {
        '2026-08-14': const NormalDay(hours: 8), // Friday
        '2026-08-16': const NormalDay(hours: 3), // Sunday
      });
      final f = payslipFiguresFor(
          sheets: s,
          days: days,
          hourlyRate: 30,
          rates: const TimesheetRates(ordinaryDayHours: 8));
      expect(f.normalHours, 8);
      expect(f.sundayHours, 3);
      final line = f.earnings.single;
      expect(line.description, startsWith(sundayMinimumPrefix));
      expect(line.amount, 60);
    });

    test('Sunday overtime is double time too, not 1.5×', () {
      final s = WorkerSheets(normal: {
        '2026-08-16': const NormalDay(hours: 8),
      }, overtime: {
        '2026-08-16': const OvertimeDay(hours: 2, finish: '18:00'),
      });
      final f = payslipFiguresFor(
          sheets: s,
          days: days,
          hourlyRate: 30,
          rates: const TimesheetRates(overtimeMultiplier: 1.5));
      expect(f.sundayHours, 10);
      expect(f.overtimeHours, 0);
      expect(f.earnings, isEmpty); // 2 × 30 × 10 = 600 > daily wage
    });

    test('public holiday worked: normal work day vs not', () {
      // Women's Day 9 Aug 2026 is a Sunday → Monday 10 Aug is the holiday.
      final s = WorkerSheets(normal: {
        '2026-08-10': const NormalDay(hours: 4),
      });
      PayslipFigures run(List<int>? workDays) => payslipFiguresFor(
          sheets: s,
          days: days,
          hourlyRate: 30,
          rates:
              TimesheetRates(ordinaryDayHours: 8, ordinaryWorkDays: workDays));
      // Mon is a normal work day: greater of 2 × 240 = 480 or 240 + 120.
      final normal = run([1, 2, 3, 4, 5]);
      expect(normal.normalHours, 0);
      expect(normal.earnings.single.description,
          startsWith(publicHolidayWorkedPrefix));
      expect(normal.earnings.single.amount, 480);
      // Not a normal work day: daily wage + hours = 240 + 120.
      expect(run([2, 3, 4, 5, 6]).earnings.single.amount, 360);
      // Work days not set → reported, not guessed.
      expect(run(null).missingRates, contains(missingWorkDays));
    });

    test('public holiday worked long: daily wage + hours wins', () {
      final s = WorkerSheets(normal: {
        '2026-08-10': const NormalDay(hours: 9),
      });
      final f = payslipFiguresFor(
          sheets: s,
          days: days,
          hourlyRate: 30,
          rates: const TimesheetRates(
              ordinaryDayHours: 8, ordinaryWorkDays: [1, 2, 3, 4, 5]));
      expect(f.earnings.single.amount, 510); // 240 + 270 > 480
    });

    test('South African public holidays', () {
      expect(easterSunday(2026), DateTime(2026, 4, 5));
      expect(easterSunday(2027), DateTime(2027, 3, 28));
      final h = saPublicHolidays(2026);
      expect(h, contains('2026-04-03')); // Good Friday
      expect(h, contains('2026-04-06')); // Family Day
      expect(h, contains('2026-08-10')); // Women's Day moved off Sunday
      expect(h, isNot(contains('2026-08-09')));
      expect(h, contains('2026-12-16'));
      expect(h.length, 12);
    });

    test('rates round-trip, including the new settings', () {
      const r = TimesheetRates(
          overtimeMultiplier: 1.5,
          nightAllowancePercent: 10,
          minimumHourlyWage: 30.23,
          topUpPeriod: 'week',
          ordinaryWorkDays: [1, 2, 3, 4, 5]);
      final back = TimesheetRates.fromMap(r.toMap());
      expect(back.topUpPeriod, 'week');
      expect(back.ordinaryWorkDays, [1, 2, 3, 4, 5]);
      expect(back.minimumHourlyWage, 30.23);
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
    expect(
        PeriodType.monthly.endFor(DateTime(2026, 8, 1)), DateTime(2026, 8, 31));
    expect(daysBetween(start, DateTime(2026, 8, 17)).length, 14);
  });
}
