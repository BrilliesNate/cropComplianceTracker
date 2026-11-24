import 'package:cropCompliance/core/constants/app_constants.dart';
import 'package:cropCompliance/siza_environmental_seed_data.dart';
import 'package:flutter_test/flutter_test.dart';

// Locks the seed to the client's "SIZA Environmental Audit Index.docx".
void main() {
  final items = [for (final s in sizaEnvironmentalSections) ...s.items];

  test('5 sections, 92 document types', () {
    expect(sizaEnvironmentalSections.length, 5);
    expect(items.length, 92);
    expect(sizaEnvironmentalSections.map((s) => s.items.length),
        [18, 24, 23, 12, 15]);
  });

  test('flags match the document', () {
    for (final i in items) {
      expect(RegExp(r'^[MENSR]+$').hasMatch(i.flags), isTrue, reason: i.name);
      // Every item: more than one document + specification needed.
      expect(i.flags, contains('M'), reason: i.name);
      expect(i.flags, contains('S'), reason: i.name);
    }
    int count(String f) => items.where((i) => i.flags.contains(f)).length;
    expect(count('R'), 7); // {add reviewed date}
    expect(count('N'), 13); // not applicable option
    expect(count('E'), 31); // expiry date
  });

  test('document type fields', () {
    final f = sizaEnvironmentalTypeFields('Environmental Management Plan (EMP)', 'MESR');
    expect(f['isUploadable'], isTrue);
    expect(f['requiresSignature'], isFalse);
    expect(f['hasExpiryDate'], isTrue);
    expect(f['hasReviewedDate'], isTrue);
    expect(f['hasNotApplicableOption'], isFalse);
    expect(f['requiresSpecification'], isTrue);
  });

  test('registered as an audit package', () {
    final p = AppConstants.auditPackages
        .firstWhere((p) => p.id == sizaEnvironmentalPackageId);
    expect(p.label, 'SIZA Environmental');
  });
}
