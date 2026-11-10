import '../bank_export_template.dart';

/// FNB Online Banking — payment import (CSV).
///
/// UNVERIFIED: best-known layout, not yet checked against a file FNB has
/// accepted. FNB's own downloadable template may also start with "BInSol"
/// preamble lines (version, date, paying account) that this does not emit.
/// Update this class and set [verified] once confirmed with a client file.
class FnbTemplate extends BankExportTemplate {
  const FnbTemplate();

  @override
  String get id => 'fnb';
  @override
  String get displayName => 'FNB';
  @override
  bool get verified => false;

  @override
  List<String> get headerRow => const [
        'RECIPIENT NAME',
        'RECIPIENT ACCOUNT',
        'RECIPIENT ACCOUNT TYPE',
        'BRANCHCODE',
        'AMOUNT',
        'OWN REFERENCE',
        'RECIPIENT REFERENCE',
      ];

  @override
  List<String> formatRow(BankPaymentLine line, BankExportContext ctx) => [
        BankExportTemplate.cleanText(line.beneficiaryName, nameMaxLength),
        BankExportTemplate.digitsOnly(line.accountNumber),
        line.accountTypeCode,
        BankExportTemplate.digitsOnly(line.branchCode),
        BankExportTemplate.fixedAmount(line.amountCents),
        BankExportTemplate.cleanText(
            'SAL ${line.beneficiaryName}', referenceMaxLength),
        reference(line, ctx),
      ];
}
