import 'package:cloud_firestore/cloud_firestore.dart';

import 'timesheet_calc.dart';

/// A pay period for one farm. Shared by all three sheets.
class PayPeriodRecord {
  final String id;
  final String companyId;
  final PeriodType type;
  final DateTime start;
  final DateTime end;
  final bool finalised;
  final DateTime? finalisedAt;
  final String? finalisedBy;
  final String? pieceRateId; // the piece rate chosen for this period's sheet

  const PayPeriodRecord({
    required this.id,
    required this.companyId,
    required this.type,
    required this.start,
    required this.end,
    this.finalised = false,
    this.finalisedAt,
    this.finalisedBy,
    this.pieceRateId,
  });

  /// Deterministic id: one period per farm + type + start date, so two people
  /// opening the same week share it instead of creating duplicates.
  static String idFor(String companyId, PeriodType type, DateTime start) =>
      '${companyId}_${type.key}_${dayKey(start).replaceAll('-', '')}';

  factory PayPeriodRecord.draft(
          String companyId, PeriodType type, DateTime start) =>
      PayPeriodRecord(
        id: idFor(companyId, type, start),
        companyId: companyId,
        type: type,
        start: DateTime(start.year, start.month, start.day),
        end: type.endFor(start),
      );

  List<DateTime> get days => daysBetween(start, end);
  List<String> get dayKeys => days.map(dayKey).toList();

  PayPeriodRecord copyWith({
    bool? finalised,
    DateTime? finalisedAt,
    String? finalisedBy,
    String? pieceRateId,
    bool clearPieceRate = false,
  }) =>
      PayPeriodRecord(
        id: id,
        companyId: companyId,
        type: type,
        start: start,
        end: end,
        finalised: finalised ?? this.finalised,
        finalisedAt: finalisedAt ?? this.finalisedAt,
        finalisedBy: finalisedBy ?? this.finalisedBy,
        pieceRateId: clearPieceRate ? null : (pieceRateId ?? this.pieceRateId),
      );

  Map<String, dynamic> toMap() => {
        'companyId': companyId,
        'type': type.key,
        'startDate': Timestamp.fromDate(start),
        'endDate': Timestamp.fromDate(end),
        'finalised': finalised,
        'finalisedAt':
            finalisedAt != null ? Timestamp.fromDate(finalisedAt!) : null,
        'finalisedBy': finalisedBy,
        'pieceRateId': pieceRateId,
      };

  factory PayPeriodRecord.fromMap(Map<String, dynamic> m, String id) =>
      PayPeriodRecord(
        id: id,
        companyId: m['companyId'] ?? '',
        type: PeriodTypeX.fromKey(m['type'] as String?),
        start: (m['startDate'] as Timestamp).toDate(),
        end: (m['endDate'] as Timestamp).toDate(),
        finalised: m['finalised'] ?? false,
        finalisedAt: (m['finalisedAt'] as Timestamp?)?.toDate(),
        finalisedBy: m['finalisedBy'],
        pieceRateId: m['pieceRateId'],
      );
}

/// Firestore access for the timesheet. Collections (all keyed by companyId so
/// the existing per-farm security rules pattern applies):
///   payPeriods        one doc per farm + type + start date
///   timesheetEntries  one doc per period + worker: {normal, overtime, piece}
///   pieceRates        configured piece rates per farm
///   timesheetAudit    save / finalise / unfinalise log
/// Rates live on payrollSettings/{companyId}.timesheetRates.
class TimesheetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Periods ───────────────────────────────────────────────────────────────

  Future<List<PayPeriodRecord>> recentPeriods(String companyId) async {
    final snap = await _db
        .collection('payPeriods')
        .where('companyId', isEqualTo: companyId)
        .get();
    return snap.docs
        .map((d) => PayPeriodRecord.fromMap(d.data(), d.id))
        .toList()
      ..sort((a, b) => b.start.compareTo(a.start));
  }

  Future<void> savePeriod(PayPeriodRecord p) =>
      _db.collection('payPeriods').doc(p.id).set(p.toMap(), SetOptions(merge: true));

  // ── Entries ───────────────────────────────────────────────────────────────

  String _entryId(String periodId, String employeeId) =>
      '${periodId}_$employeeId';

  Future<Map<String, WorkerSheets>> loadEntries(
      String companyId, String periodId) async {
    final snap = await _db
        .collection('timesheetEntries')
        .where('companyId', isEqualTo: companyId)
        .where('periodId', isEqualTo: periodId)
        .get();
    final out = <String, WorkerSheets>{};
    for (final d in snap.docs) {
      final m = d.data();
      Map<String, T> parse<T>(Object? raw, T Function(Map) f) {
        final res = <String, T>{};
        if (raw is Map) {
          raw.forEach((k, v) {
            if (v is Map) res[k.toString()] = f(v);
          });
        }
        return res;
      }

      out[m['employeeId'] as String] = WorkerSheets(
        normal: parse(m['normal'], NormalDay.fromMap),
        overtime: parse(m['overtime'], OvertimeDay.fromMap),
        piece: parse(m['piece'], PieceDay.fromMap),
        comment: m['comment'] ?? '',
      );
    }
    return out;
  }

  /// Writes the sheets for each worker in [sheets] (whole-document replace,
  /// so cleared cells are removed). Batched.
  Future<void> saveEntries(String companyId, String periodId,
      Map<String, WorkerSheets> sheets) async {
    final entries = sheets.entries.toList();
    for (var i = 0; i < entries.length; i += 400) {
      final batch = _db.batch();
      for (final e in entries.skip(i).take(400)) {
        final s = e.value;
        batch.set(_db.collection('timesheetEntries').doc(_entryId(periodId, e.key)), {
          'companyId': companyId,
          'periodId': periodId,
          'employeeId': e.key,
          'normal': {
            for (final d in s.normal.entries)
              if (!d.value.isEmpty) d.key: d.value.toMap(),
          },
          'overtime': {
            for (final d in s.overtime.entries) d.key: d.value.toMap(),
          },
          'piece': {for (final d in s.piece.entries) d.key: d.value.toMap()},
          'comment': s.comment,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  // ── Piece rates ───────────────────────────────────────────────────────────

  Future<List<PieceRateInfo>> pieceRates(String companyId) async {
    final snap = await _db
        .collection('pieceRates')
        .where('companyId', isEqualTo: companyId)
        .get();
    return snap.docs
        .where((d) => d.data()['active'] != false)
        .map((d) => PieceRateInfo(
              id: d.id,
              taskOrCrop: d.data()['taskOrCrop'] ?? '',
              unitType: d.data()['unitType'] ?? 'units',
              rate: (d.data()['rate'] as num?)?.toDouble() ?? 0,
            ))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }

  Future<PieceRateInfo> addPieceRate(String companyId, String taskOrCrop,
      String unitType, double rate) async {
    final ref = await _db.collection('pieceRates').add({
      'companyId': companyId,
      'taskOrCrop': taskOrCrop,
      'unitType': unitType,
      'rate': rate,
      'validFrom': Timestamp.fromDate(DateTime.now()),
      'validTo': null,
      'active': true,
    });
    return PieceRateInfo(
        id: ref.id, taskOrCrop: taskOrCrop, unitType: unitType, rate: rate);
  }

  // ── Rates ─────────────────────────────────────────────────────────────────

  Future<TimesheetRates> rates(String companyId) async {
    final doc = await _db.collection('payrollSettings').doc(companyId).get();
    return TimesheetRates.fromMap(doc.data()?['timesheetRates'] as Map?);
  }

  Future<void> saveRates(String companyId, TimesheetRates r) =>
      _db.collection('payrollSettings').doc(companyId).set({
        'companyId': companyId,
        'timesheetRates': r.toMap(),
      }, SetOptions(merge: true));

  // ── Audit ─────────────────────────────────────────────────────────────────

  Future<void> audit(String companyId, String periodId, String action,
      {String? actorId, String? actorName, String? detail}) async {
    try {
      await _db.collection('timesheetAudit').add({
        'companyId': companyId,
        'periodId': periodId,
        'action': action, // save | finalise | unfinalise
        'actorId': actorId,
        'actorName': actorName,
        if (detail != null) 'detail': detail,
        'at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // The log must never stop the user from saving.
    }
  }
}
