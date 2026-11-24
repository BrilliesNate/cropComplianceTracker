import '../offline/offline_write.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cropCompliance/models/spray_record_model.dart';

class SprayRecordService {
  static const _col = 'sprayRecords';
  final _db = FirebaseFirestore.instance;

  Future<List<SprayRecord>> getRecordsForCompany(String companyId) async {
    final snap = await _db
        .collection(_col)
        .where('companyId', isEqualTo: companyId)
        .orderBy('applicationDate', descending: true)
        .get();
    return snap.docs
        .map((d) => SprayRecord.fromMap(d.data(), d.id))
        .toList();
  }

  Future<SprayRecord?> save(SprayRecord record) async {
    try {
      final now = DateTime.now();
      if (record.id.isEmpty) {
        // Create
        final data = record.copyWith().toMap()
          ..['createdAt'] = Timestamp.fromDate(now)
          ..['updatedAt'] = Timestamp.fromDate(now);
        final ref = _db.collection(_col).doc();
        await commitWrite(ref.set(data), label: 'spray record'); // l10n-ignore: log label
        return SprayRecord.fromMap(data, ref.id);
      } else {
        // Update
        final data = record.toMap()
          ..['updatedAt'] = Timestamp.fromDate(now);
        await commitWrite(_db.collection(_col).doc(record.id).update(data),
            label: 'spray record'); // l10n-ignore: log label
        return record;
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await commitWrite(_db.collection(_col).doc(id).delete(),
          label: 'delete spray record'); // l10n-ignore: log label
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mark a record as synced to Farmable with the returned job ID.
  Future<void> markFarmableSynced(String id, int jobId) async {
    await _db.collection(_col).doc(id).update({
      'farmableSynced': true,
      'farmableJobId': jobId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
