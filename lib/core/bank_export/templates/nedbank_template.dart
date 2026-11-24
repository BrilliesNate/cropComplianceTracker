import '../bank_export_template.dart';

/// Nedbank NetBank Business — payment import (CSV).
///
/// UNVERIFIED: best-known layout, not yet checked against a file Nedbank
/// has accepted. Update and set [verified] once confirmed.
class NedbankTemplate extends BankExportTemplate {
  const NedbankTemplate();

  @override
  String get id => 'nedbank';
  @override
  String get displayName => 'Nedbank'; // l10n-ignore: bank name
  @override
  bool get verified => false;

  @override
  List<String> get headerRow => const [
        'Beneficiary Name', // l10n-ignore: bank file format
        'Account Number', // l10n-ignore: bank file format
        'Branch Code', // l10n-ignore: bank file format
        'Account Type', // l10n-ignore: bank file format
        'Amount', // l10n-ignore: bank file format
        'Beneficiary Reference', // l10n-ignore: bank file format
        'Own Reference', // l10n-ignore: bank file format
      ];

  @override
  List<String> formatRow(BankPaymentLine line, BankExportContext ctx) => [
        BankExportTemplate.cleanText(line.beneficiaryName, nameMaxLength),
        BankExportTemplate.digitsOnly(line.accountNumber),
        BankExportTemplate.digitsOnly(line.branchCode),
        line.accountTypeCode,
        BankExportTemplate.fixedAmount(line.amountCents),
        reference(line, ctx),
        BankExportTemplate.cleanText(
            'SAL ${line.beneficiaryName}', referenceMaxLength), // l10n-ignore: bank file format
      ];
}
