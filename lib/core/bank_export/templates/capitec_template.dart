import '../bank_export_template.dart';

/// Capitec Business bulk payment import.
///
/// VERIFIED against a real file a client imports into Capitec:
/// no header row, 6 unquoted columns —
///   branch code, account number, amount, payer (company) name,
///   beneficiary reference, beneficiary full name
/// CRLF line endings with a trailing newline; amounts with no currency
/// symbol and no trailing zeros (6945, 1372.14); references mixed case,
/// max 20 characters ("Salaries Willem").
class CapitecTemplate extends BankExportTemplate {
  const CapitecTemplate();

  @override
  String get id => 'capitec';
  @override
  String get displayName => 'Capitec';
  @override
  bool get verified => true;

  @override
  int get nameMaxLength => 40;
  @override
  int get payerNameMaxLength => 40;

  @override
  List<String> formatRow(BankPaymentLine line, BankExportContext ctx) => [
        BankExportTemplate.digitsOnly(line.branchCode),
        BankExportTemplate.digitsOnly(line.accountNumber),
        BankExportTemplate.plainAmount(line.amountCents),
        BankExportTemplate.cleanText(ctx.payerName, payerNameMaxLength)
            .toUpperCase(),
        reference(line, ctx),
        BankExportTemplate.cleanText(line.beneficiaryName, nameMaxLength),
      ];
}
