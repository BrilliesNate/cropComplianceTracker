import '../bank_export_template.dart';

/// Bank-agnostic fallback: a labelled CSV with every useful column, for
/// banks without a dedicated template (the user maps columns on import).
class GenericTemplate extends BankExportTemplate {
  const GenericTemplate();

  @override
  String get id => 'generic';
  @override
  String get displayName => 'Other bank (generic CSV)';
  @override
  bool get verified => false;
  @override
  bool get isGeneric => true;

  @override
  int get nameMaxLength => 40;

  @override
  String fileName(String companyName, String periodLabel) =>
      '$companyName Bank Payments $periodLabel.$fileExtension';

  @override
  List<String> get headerRow => const [
        'Beneficiary Name',
        'Bank',
        'Branch Code',
        'Account Number',
        'Account Type',
        'Account Type Code',
        'Amount',
        'Beneficiary Reference',
        'Own Reference',
        'Employee ID Number',
      ];

  @override
  List<String> formatRow(BankPaymentLine line, BankExportContext ctx) => [
        BankExportTemplate.cleanText(line.beneficiaryName, nameMaxLength),
        BankExportTemplate.cleanText(line.bankName, 40),
        BankExportTemplate.digitsOnly(line.branchCode),
        BankExportTemplate.digitsOnly(line.accountNumber),
        line.accountTypeLabel,
        line.accountTypeCode,
        BankExportTemplate.fixedAmount(line.amountCents),
        reference(line, ctx),
        BankExportTemplate.cleanText(
                'SAL ${line.beneficiaryName}', referenceMaxLength)
            .toUpperCase(),
        BankExportTemplate.cleanText(line.idNumber, 20),
      ];
}
