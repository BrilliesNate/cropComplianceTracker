import '../bank_export_template.dart';

/// Standard Bank Business Online — beneficiary payment import (CSV).
///
/// UNVERIFIED: best-known layout, not yet checked against a file Standard
/// Bank has accepted. Update and set [verified] once confirmed.
class StandardBankTemplate extends BankExportTemplate {
  const StandardBankTemplate();

  @override
  String get id => 'standard_bank';
  @override
  String get displayName => 'Standard Bank';
  @override
  bool get verified => false;

  @override
  List<String> get headerRow => const [
        'Beneficiary Name',
        'Branch Code',
        'Account Number',
        'Account Type',
        'Amount',
        'Beneficiary Reference',
        'Own Reference',
      ];

  @override
  List<String> formatRow(BankPaymentLine line, BankExportContext ctx) => [
        BankExportTemplate.cleanText(line.beneficiaryName, nameMaxLength),
        BankExportTemplate.digitsOnly(line.branchCode),
        BankExportTemplate.digitsOnly(line.accountNumber),
        line.accountTypeCode,
        BankExportTemplate.fixedAmount(line.amountCents),
        reference(line, ctx),
        BankExportTemplate.cleanText(
            'SAL ${line.beneficiaryName}', referenceMaxLength),
      ];
}
