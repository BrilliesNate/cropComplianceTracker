import 'package:cropCompliance/models/document_model.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:cropCompliance/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

DocumentModel _doc(String typeId, DateTime? expiry) => DocumentModel(
      id: 'd-$typeId',
      userId: 'u',
      companyId: 'c',
      categoryId: 'cat',
      documentTypeId: typeId,
      status: DocumentStatus.APPROVED,
      fileUrls: const [],
      formData: const {},
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      expiryDate: expiry,
      isNotApplicable: false,
      signatures: const [],
      comments: const [],
    );

// "SARS registration documents" has no expiry date, yet old uploads carry a
// stamped "upload day + 1 year" date. They must never show as expired.
void main() {
  final lastYear = DateTime.now().subtract(const Duration(days: 30));

  test('a type without expiry dates never makes its documents expired', () {
    DocumentTypeModel.fromMap({'name': 'SARS registration', 'hasExpiryDate': false}, 'sars');
    final d = _doc('sars', lastYear);
    expect(d.isExpired, isFalse);
    expect(d.effectiveExpiryDate, isNull);
    expect(d.hasStrayExpiryDate, isTrue);
    expect(d.expiryDate, lastYear); // still there to be seen and cleared
  });

  test('a missing flag counts as no expiry (same as the type model)', () {
    DocumentTypeModel.fromMap({'name': 'Old type'}, 'old');
    expect(_doc('old', lastYear).isExpired, isFalse);
  });

  test('types with expiry dates still expire', () {
    DocumentTypeModel.fromMap({'name': 'Permit', 'hasExpiryDate': true}, 'permit');
    expect(_doc('permit', lastYear).isExpired, isTrue);
    expect(_doc('permit', DateTime.now().add(const Duration(days: 30))).isExpired, isFalse);
  });

  test('switching expiry off later clears existing expiries', () {
    DocumentTypeModel.fromMap({'name': 'Plan', 'hasExpiryDate': true}, 'plan');
    expect(_doc('plan', lastYear).isExpired, isTrue);
    DocumentTypeModel.fromMap({'name': 'Plan', 'hasExpiryDate': false}, 'plan');
    expect(_doc('plan', lastYear).isExpired, isFalse);
  });

  test('raw data helper used by the admin dashboards', () {
    DocumentModel.noteTypeExpiry('raw', false);
    expect(DocumentModel.effectiveExpiryFor('raw', lastYear), isNull);
    expect(DocumentModel.effectiveExpiryFor('unknown', lastYear), lastYear);
  });
}
