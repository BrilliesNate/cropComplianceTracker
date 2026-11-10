import 'package:cropCompliance/core/bank_export/bank_export_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('includes the major SA banks plus a generic fallback', () {
    final ids = BankExportRegistry.all.map((t) => t.id).toSet();
    expect(ids, containsAll(
        ['capitec', 'fnb', 'standard_bank', 'absa', 'nedbank', 'generic']));
  });

  test('ids are unique and display names are set', () {
    final ids = BankExportRegistry.all.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final t in BankExportRegistry.all) {
      expect(t.displayName.trim(), isNotEmpty);
    }
  });

  test('byId: known, unknown and empty', () {
    expect(BankExportRegistry.byId('capitec')?.displayName, 'Capitec');
    expect(BankExportRegistry.byId('no_such_bank'), isNull);
    expect(BankExportRegistry.byId(null), isNull);
    expect(BankExportRegistry.byId(''), isNull);
  });

  test('generic template is last in the picker', () {
    expect(BankExportRegistry.all.last.isGeneric, isTrue);
  });

  test('only Capitec is marked verified; others show a caution note', () {
    for (final t in BankExportRegistry.all) {
      if (t.id == 'capitec') {
        expect(t.verified, isTrue);
        expect(t.userNote, isNull);
      } else {
        expect(t.verified, isFalse);
        expect(t.userNote, isNotNull);
      }
    }
  });

  test('every template emits a header (if any) and rows of equal width', () {
    const line = BankPaymentLine(
      beneficiaryName: 'Test Person',
      firstName: 'Test',
      accountNumber: '1234567890',
      branchCode: '250655',
      amountCents: 100050,
    );
    const ctx = BankExportContext(payerName: 'Test Farm');
    for (final t in BankExportRegistry.all) {
      final row = t.formatRow(line, ctx);
      if (t.headerRow != null) {
        expect(row.length, t.headerRow!.length, reason: t.id);
      }
      expect(t.build([line], ctx).endsWith(t.lineEnding), isTrue,
          reason: t.id);
    }
  });
}
