import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/company_model.dart';
import 'firestore_service.dart';
import 'package:cropCompliance/models/document_model.dart';

/// At-a-glance numbers for one farm, shown on the "My Farms" screen.
class FarmSummary {
  final CompanyModel company;

  /// Total documents (for auditors: approved documents — all they may see).
  final int documentCount;

  /// Documents waiting for review. Always 0 for auditors.
  final int pendingDocs;

  /// Required document types with an approved, in-date, current document.
  final int coveredTypes;

  /// Document types this farm has to provide (its packages, minus any it has
  /// switched off).
  final int requiredTypes;

  /// False when the numbers could not be loaded; the UI shows a dash instead of
  /// a misleading zero.
  final bool loaded;

  const FarmSummary({
    required this.company,
    required this.documentCount,
    required this.pendingDocs,
    required this.coveredTypes,
    required this.requiredTypes,
    this.loaded = true,
  });

  int get completion =>
      requiredTypes <= 0 ? 0 : ((coveredTypes / requiredTypes) * 100).round();
}

/// Loads [FarmSummary]s for the farms a (non-admin) user can switch between.
///
/// Completion follows the same rule as the Dashboard — unique document types
/// with an approved, non-expired, non-superseded document ÷ required types — so
/// the two screens always agree.
class FarmSummaryService {
  FarmSummaryService._();

  static Future<List<FarmSummary>> load(
    List<CompanyModel> farms, {
    required bool approvedOnly,
  }) async {
    final fs = FirebaseFirestore.instance;
    final firestoreService = FirestoreService();

    // Shared, session-cached reference data (no extra reads on repeat visits).
    final ref = await Future.wait([
      firestoreService.getCategories(),
      firestoreService.getAllDocumentTypes(),
    ]);
    final categories = ref[0] as List;
    final docTypes = ref[1] as List;

    final typeIdsByCategory = <String, List<String>>{};
    for (final t in docTypes) {
      (typeIdsByCategory[t.categoryId as String] ??= []).add(t.id as String);
    }

    Future<FarmSummary> summarise(CompanyModel farm) async {
      try {
        final docs =
            fs.collection('documents').where('companyId', isEqualTo: farm.id);
        final approved = docs.where('status', isEqualTo: 'APPROVED');

        final results = await Future.wait<Object>([
          // Auditors may only query approved documents, so they only get that count.
          (approvedOnly ? approved : docs).count().get(),
          if (!approvedOnly) docs.where('status', isEqualTo: 'PENDING').count().get(),
          approved.get(),
          fs
              .collection('companyDocumentTypeSettings')
              .where('companyId', isEqualTo: farm.id)
              .get(),
        ]);

        var i = 0;
        final total = (results[i++] as AggregateQuerySnapshot).count ?? 0;
        final pending =
            approvedOnly ? 0 : ((results[i++] as AggregateQuerySnapshot).count ?? 0);
        final approvedSnap = results[i++] as QuerySnapshot<Map<String, dynamic>>;
        final overridesSnap = results[i++] as QuerySnapshot<Map<String, dynamic>>;

        // Types this farm has switched off.
        final deactivated = <String>{};
        for (final d in overridesSnap.docs) {
          final data = d.data();
          final typeId = data['documentTypeId'] as String?;
          final overrides = data['overrides'] as Map<String, dynamic>? ?? {};
          if (typeId != null && overrides['isActive'] == false) {
            deactivated.add(typeId);
          }
        }

        final required = <String>{};
        for (final c in categories) {
          if (farm.packages.contains(c.packageId)) {
            required.addAll(typeIdsByCategory[c.id as String] ?? const []);
          }
        }
        required.removeAll(deactivated);

        final now = DateTime.now();
        final covered = <String>{};
        for (final d in approvedSnap.docs) {
          final data = d.data();
          if (data['isSuperseded'] == true) continue;
          final typeId = data['documentTypeId'];
          final expiry = DocumentModel.effectiveExpiryFor(
              typeId as String?, (data['expiryDate'] as Timestamp?)?.toDate());
          if (expiry != null && !expiry.isAfter(now)) continue;
          if (typeId is String && required.contains(typeId)) covered.add(typeId);
        }

        return FarmSummary(
          company: farm,
          documentCount: total,
          pendingDocs: pending,
          coveredTypes: covered.length,
          requiredTypes: required.length,
        );
      } catch (e) {
        print('FarmSummaryService: failed for ${farm.name}: $e');
        return FarmSummary(
          company: farm,
          documentCount: 0,
          pendingDocs: 0,
          coveredTypes: 0,
          requiredTypes: 0,
          loaded: false,
        );
      }
    }

    return Future.wait(farms.map(summarise));
  }
}
