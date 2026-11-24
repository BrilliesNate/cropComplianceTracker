import '../bank_export_template.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// Bank-agnostic fallback: a labelled CSV with every useful column, for
/// banks without a dedicated template (the user maps columns on import).
class GenericTemplate extends BankExportTemplate {
  const GenericTemplate();

  @override
  String get id => 'generic';
  @override
  String get displayName => LocaleProvider.instance.l10n.bankGenericName;
  @override
  bool get verified => false;
  @override
  bool get isGeneric => true;

  @override
  int get nameMaxLength => 40;

  @override
  String fileName(String companyName, String periodLabel) =>
      LocaleProvider.instance.l10n.bankFileNameGeneric(companyName, periodLabel, fileExtension);

  @override
  List<String> get headerRow => const [
        'Beneficiary Name', // l10n-ignore: bank file format
        'Bank', // l10n-ignore: bank file format
        'Branch Code', // l10n-ignore: bank file format
        'Account Number', // l10n-ignore: bank file format
        'Account Type', // l10n-ignore: bank file format
        'Account Type Code', // l10n-ignore: bank file format
        'Amount', // l10n-ignore: bank file format
        'Beneficiary Reference', // l10n-ignore: bank file format
        'Own Reference', // l10n-ignore: bank file format
        'Employee ID Number', // l10n-ignore: bank file format
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
                'SAL ${line.beneficiaryName}', referenceMaxLength) // l10n-ignore: bank file format
            .toUpperCase(),
        BankExportTemplate.cleanText(line.idNumber, 20),
      ];
}
