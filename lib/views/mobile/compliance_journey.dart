import 'package:cropCompliance/models/category_model.dart';
import 'package:cropCompliance/models/document_model.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:cropCompliance/models/enums.dart';
import 'package:cropCompliance/l10n/generated/app_localizations.dart';

/// Where one document requirement stands for the farm.
enum TypeStatus { approved, pending, rejected, expired, notApplicable, missing }

extension TypeStatusX on TypeStatus {
  /// Counts as "behind you" on the journey: submitted (approved or awaiting
  /// review) or marked not applicable.
  bool get isDone =>
      this == TypeStatus.approved ||
      this == TypeStatus.pending ||
      this == TypeStatus.notApplicable;

  /// Needs the farm to act again (fix and resubmit / renew).
  bool get needsAction =>
      this == TypeStatus.rejected || this == TypeStatus.expired;

  String label(AppLocalizations l10n) {
    switch (this) {
      case TypeStatus.approved:
        return l10n.statusApproved;
      case TypeStatus.pending:
        return l10n.statusInReview;
      case TypeStatus.rejected:
        return l10n.statusRejected;
      case TypeStatus.expired:
        return l10n.statusExpired;
      case TypeStatus.notApplicable:
        return l10n.statusNotApplicable;
      case TypeStatus.missing:
        return l10n.statusToUpload;
    }
  }
}

/// The current (newest, not superseded) document for a type, if any.
DocumentModel? latestDocument(Iterable<DocumentModel> docsOfType) {
  DocumentModel? best;
  for (final d in docsOfType) {
    if (d.isSuperseded) continue;
    if (best == null || d.createdAt.isAfter(best.createdAt)) best = d;
  }
  return best;
}

TypeStatus statusOf(DocumentModel? latest) {
  if (latest == null) return TypeStatus.missing;
  if (latest.isNotApplicable) return TypeStatus.notApplicable;
  if (latest.status == DocumentStatus.REJECTED) return TypeStatus.rejected;
  if (latest.isExpired) return TypeStatus.expired;
  if (latest.status == DocumentStatus.APPROVED) return TypeStatus.approved;
  return TypeStatus.pending;
}

/// One requirement on the journey.
class JourneyStep {
  final DocumentTypeModel type;
  final CategoryModel category;
  final DocumentModel? latest;
  final TypeStatus status;

  const JourneyStep({
    required this.type,
    required this.category,
    required this.latest,
    required this.status,
  });
}

/// The farm's compliance journey: what's done, what to do right now, what's
/// still ahead — in the order the audit index lists them.
class ComplianceJourney {
  final List<JourneyStep> done;
  final JourneyStep? now;

  /// Still to do after [now] — fixes (rejected / expired) first.
  final List<JourneyStep> ahead;

  const ComplianceJourney(
      {required this.done, required this.now, required this.ahead});

  int get total => done.length + ahead.length + (now == null ? 0 : 1);
  double get fraction => total == 0 ? 0 : done.length / total;
  int get percent => (fraction * 100).round();
}

List<CategoryModel> orderedCategories(Iterable<CategoryModel> categories) =>
    categories.toList()
      ..sort((a, b) {
        final o = a.order.compareTo(b.order);
        return o != 0 ? o : a.name.compareTo(b.name);
      });

/// Builds the journey from the farm's categories (already filtered to its
/// standards), document types and documents.
ComplianceJourney buildJourney({
  required Iterable<CategoryModel> categories,
  required Iterable<DocumentTypeModel> types,
  required Iterable<DocumentModel> documents,
}) {
  final byType = <String, List<DocumentModel>>{};
  for (final d in documents) {
    byType.putIfAbsent(d.documentTypeId, () => []).add(d);
  }
  final typesByCat = <String, List<DocumentTypeModel>>{};
  for (final t in types) {
    typesByCat.putIfAbsent(t.categoryId, () => []).add(t);
  }

  final done = <JourneyStep>[];
  final fixes = <JourneyStep>[];
  final missing = <JourneyStep>[];
  for (final c in orderedCategories(categories)) {
    final list = (typesByCat[c.id] ?? [])
      ..sort((a, b) => a.name.compareTo(b.name));
    for (final t in list) {
      final latest = latestDocument(byType[t.id] ?? const []);
      final step = JourneyStep(
          type: t, category: c, latest: latest, status: statusOf(latest));
      if (step.status.isDone) {
        done.add(step);
      } else if (step.status.needsAction) {
        fixes.add(step);
      } else {
        missing.add(step);
      }
    }
  }
  final todo = [...fixes, ...missing];
  return ComplianceJourney(
    done: done,
    now: todo.isEmpty ? null : todo.first,
    ahead: todo.length > 1 ? todo.sublist(1) : const [],
  );
}
