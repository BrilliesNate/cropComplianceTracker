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
        'Account Number',
        'Branch Code',
        'Account Type',
        'Amount',
        'Beneficiary Name',
        'Beneficiary Reference',
        'Own Reference',
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
            'SAL ${line.beneficiaryName}', referenceMaxLength),
      ];
}
