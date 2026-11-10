import 'package:cropCompliance/core/bank_export/bank_export_registry.dart';
import 'package:cropCompliance/core/bank_export/templates/capitec_template.dart';
import 'package:flutter_test/flutter_test.dart';

// Fictitious test data only — never real employee details.
BankPaymentLine _line({
  String name = 'Willem Botha',
  String first = 'Willem',
  String account = '1234567890',
  String branch = '470010',
  int cents = 694500,
}) =>
    BankPaymentLine(
      beneficiaryName: name,
      firstName: first,
      accountNumber: account,
      branchCode: branch,
      amountCents: cents,
    );

void main() {
  const t = CapitecTemplate();
  const ctx = BankExportContext(payerName: 'Test Boerdery');

  test('is verified, has no header row, CRLF line endings', () {
    expect(t.verified, isTrue);
    expect(t.headerRow, isNull);
    expect(t.lineEnding, '\r\n');
    expect(t.userNote, isNull);
  });

  test('formats a row as the 6 Capitec columns', () {
    expect(t.formatRow(_line(), ctx), [
      '470010',
      '1234567890',
      '6945',
      'TEST BOERDERY',
      'Salaries Willem',
      'Willem Botha',
    ]);
  });

  test('amounts: no currency symbol, no trailing zeros', () {
    expect(BankExportTemplate.plainAmount(694500), '6945');
    expect(BankExportTemplate.plainAmount(137214), '1372.14');
    expect(BankExportTemplate.plainAmount(123450), '1234.5');
    expect(BankExportTemplate.plainAmount(5), '0.05');
  });

  test('reference is mixed case, editable prefix, max 20 chars', () {
    expect(
      t.reference(_line(first: 'Christiaan'),
          const BankExportContext(payerName: 'X', referencePrefix: 'Wages')),
      'Wages Christiaan',
    );
    final long = t.reference(_line(first: 'Bartholomeus'), ctx);
    expect(long, 'Salaries Bartholomeu');
    expect(long.length, lessThanOrEqualTo(20));
    // Blank prefix falls back to the default.
    expect(
      t.reference(_line(),
          const BankExportContext(payerName: 'X', referencePrefix: '  ')),
      'Salaries Willem',
    );
  });

  test('build: no quotes, commas stripped from text, CRLF + trailing newline',
      () {
    final out = t.build([
      _line(),
      _line(name: 'Jan, "Jannie" Smit', first: 'Jan', cents: 137214),
    ], ctx);
    expect(
      out,
      '470010,1234567890,6945,TEST BOERDERY,Salaries Willem,Willem Botha\r\n'
      '470010,1234567890,1372.14,TEST BOERDERY,Salaries Jan,Jan Jannie Smit\r\n',
    );
    expect(out.contains('"'), isFalse);
  });

  test('accents are folded rather than dropped', () {
    expect(BankExportTemplate.cleanText('Hendrië Müller', 40), 'Hendrie Muller');
  });

  test('validation rejects bad branch/account and non-positive amounts', () {
    expect(t.validate(_line()), isEmpty);
    expect(t.validate(_line(branch: '4700')), isNotEmpty);
    expect(t.validate(_line(account: '12ab')), isNotEmpty);
    expect(t.validate(_line(cents: 0)), isNotEmpty);
  });
}
