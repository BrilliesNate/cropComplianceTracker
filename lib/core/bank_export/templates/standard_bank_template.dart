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
  String get displayName => 'Standard Bank'; // l10n-ignore: bank name
  @override
  bool get verified => false;

  @override
  List<String> get headerRow => const [
        'Beneficiary Name', // l10n-ignore: bank file format
        'Branch Code', // l10n-ignore: bank file format
        'Account Number', // l10n-ignore: bank file format
        'Account Type', // l10n-ignore: bank file format
        'Amount', // l10n-ignore: bank file format
        'Beneficiary Reference', // l10n-ignore: bank file format
        'Own Reference', // l10n-ignore: bank file format
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
            'SAL ${line.beneficiaryName}', referenceMaxLength), // l10n-ignore: bank file format
      ];
}
