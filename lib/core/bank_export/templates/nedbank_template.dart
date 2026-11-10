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
  String get displayName => 'Nedbank';
  @override
  bool get verified => false;

  @override
  List<String> get headerRow => const [
        'Beneficiary Name',
        'Account Number',
        'Branch Code',
        'Account Type',
        'Amount',
        'Beneficiary Reference',
        'Own Reference',
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
            'SAL ${line.beneficiaryName}', referenceMaxLength),
      ];
}
