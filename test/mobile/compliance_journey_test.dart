import 'package:cropCompliance/models/category_model.dart';
import 'package:cropCompliance/models/document_model.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:cropCompliance/models/enums.dart';
import 'package:cropCompliance/views/mobile/compliance_journey.dart';
import 'package:flutter_test/flutter_test.dart';

CategoryModel _cat(String id, int order) => CategoryModel(
    id: id, name: 'Cat $id', description: '', order: order, packageId: 'p');

DocumentTypeModel _type(String id, String cat) => DocumentTypeModel(
      id: id,
      categoryId: cat,
      name: 'Type $id',
      allowMultipleDocuments: false,
      isUploadable: true,
      hasExpiryDate: false,
      hasNotApplicableOption: false,
      requiresSignature: false,
      signatureCount: 0,
    );

DocumentModel _doc(String type, DocumentStatus status,
        {DateTime? created,
        DateTime? expiry,
        bool superseded = false,
        bool na = false}) =>
    DocumentModel(
      id: '$type-${status.name}-${created?.millisecondsSinceEpoch ?? 0}',
      userId: 'u',
      companyId: 'c',
      categoryId: 'c1',
      documentTypeId: type,
      status: status,
      fileUrls: const [],
      formData: const {},
      createdAt: created ?? DateTime(2026, 1, 1),
      updatedAt: created ?? DateTime(2026, 1, 1),
      expiryDate: expiry,
      isNotApplicable: na,
      signatures: const [],
      comments: const [],
      isSuperseded: superseded,
    );

void main() {
  test('status of the newest, non-superseded document', () {
    expect(statusOf(null), TypeStatus.missing);
    expect(statusOf(_doc('a', DocumentStatus.APPROVED)), TypeStatus.approved);
    expect(statusOf(_doc('a', DocumentStatus.PENDING)), TypeStatus.pending);
    expect(statusOf(_doc('a', DocumentStatus.REJECTED)), TypeStatus.rejected);
    expect(
        statusOf(_doc('a', DocumentStatus.APPROVED,
            expiry: DateTime(2020))),
        TypeStatus.expired);
    expect(statusOf(_doc('a', DocumentStatus.PENDING, na: true)),
        TypeStatus.notApplicable);

    final latest = latestDocument([
      _doc('a', DocumentStatus.REJECTED, created: DateTime(2026, 1, 1)),
      _doc('a', DocumentStatus.APPROVED, created: DateTime(2026, 3, 1)),
      _doc('a', DocumentStatus.PENDING,
          created: DateTime(2026, 5, 1), superseded: true),
    ]);
    expect(latest!.status, DocumentStatus.APPROVED);
  });

  test('journey: done, fixes first, then missing — in category order', () {
    final j = buildJourney(
      categories: [_cat('c2', 2), _cat('c1', 1)],
      types: [
        _type('a', 'c1'),
        _type('b', 'c1'),
        _type('c', 'c2'),
        _type('d', 'c2'),
      ],
      documents: [
        _doc('a', DocumentStatus.APPROVED),
        _doc('d', DocumentStatus.REJECTED),
      ],
    );
    expect(j.done.map((s) => s.type.id), ['a']);
    expect(j.now!.type.id, 'd'); // the rejected one comes first
    expect(j.ahead.map((s) => s.type.id), ['b', 'c']);
    expect(j.total, 4);
    expect(j.percent, 25);
  });

  test('all done: nothing right now', () {
    final j = buildJourney(
      categories: [_cat('c1', 1)],
      types: [_type('a', 'c1')],
      documents: [_doc('a', DocumentStatus.PENDING)],
    );
    expect(j.now, isNull);
    expect(j.percent, 100);
  });

  test('no requirements: empty journey, 0%', () {
    final j =
        buildJourney(categories: const [], types: const [], documents: const []);
    expect(j.total, 0);
    expect(j.percent, 0);
  });
}
