import '../bank_export_template.dart';

/// Absa Online Banking for Business — bulk payment import (CSV).
///
/// UNVERIFIED: best-known layout, not yet checked against a file Absa has
/// accepted. Update and set [verified] once confirmed.
class AbsaTemplate extends BankExportTemplate {
  const AbsaTemplate();

  @override
  String get id => 'absa';
  @override
  String get displayName => 'ABSA';
  @override
  bool get verified => false;

  @override
  List<String> get headerRow => const [
        'Account Number', // l10n-ignore: bank file format
        'Branch Code', // l10n-ignore: bank file format
        'Account Type', // l10n-ignore: bank file format
        'Amount', // l10n-ignore: bank file format
        'Beneficiary Name', // l10n-ignore: bank file format
        'Beneficiary Reference', // l10n-ignore: bank file format
        'Own Reference', // l10n-ignore: bank file format
      ];

  @override
  List<String> formatRow(BankPaymentLine line, BankExportContext ctx) => [
        BankExportTemplate.digitsOnly(line.accountNumber),
        BankExportTemplate.digitsOnly(line.branchCode),
        line.accountTypeCode,
        BankExportTemplate.fixedAmount(line.amountCents),
        BankExportTemplate.cleanText(line.beneficiaryName, nameMaxLength),
        reference(line, ctx),
        BankExportTemplate.cleanText(
            'SAL ${line.beneficiaryName}', referenceMaxLength), // l10n-ignore: bank file format
      ];
}
