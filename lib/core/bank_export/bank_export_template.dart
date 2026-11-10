/// Bulk-payment export templates for South African online banking.
///
/// Each bank's import file is described by one [BankExportTemplate]
/// subclass and listed in `BankExportRegistry`. Templates are pure Dart (no
/// Flutter / Firestore) so they can be unit tested directly.
library;

/// One payment, already resolved from a payslip + employee record.
class BankPaymentLine {
  /// Name on the receiving account (account holder, else employee name).
  final String beneficiaryName;

  /// Employee's first name — used for "Salaries Willem"-style references.
  final String firstName;
  final String accountNumber;
  final String branchCode;

  /// Free-text bank name as captured on the employee (may be empty).
  final String bankName;

  /// ACB account-type code: 1 = Current/Cheque, 2 = Savings, 3 = Transmission.
  final String accountTypeCode;
  final String accountTypeLabel;
  final String idNumber;

  /// Amount in cents, to avoid floating-point rounding in the file.
  final int amountCents;

  const BankPaymentLine({
    required this.beneficiaryName,
    required this.firstName,
    required this.accountNumber,
    required this.branchCode,
    required this.amountCents,
    this.bankName = '',
    this.accountTypeCode = '2',
    this.accountTypeLabel = 'Savings',
    this.idNumber = '',
  });
}

/// Values shared by every row of one export.
class BankExportContext {
  /// The paying farm / company.
  final String payerName;

  /// Reference prefix — each row's reference is prefix + first name.
  final String referencePrefix;

  const BankExportContext({
    required this.payerName,
    this.referencePrefix = BankExportTemplate.defaultReferencePrefix,
  });
}

abstract class BankExportTemplate {
  const BankExportTemplate();

  static const defaultReferencePrefix = 'Salaries';

  /// Stable key persisted in payroll settings — never change once shipped.
  String get id;

  /// Shown in the bank picker, e.g. "Capitec".
  String get displayName;

  /// True only once the layout has been checked against a real import file
  /// accepted by that bank.
  bool get verified;

  /// True for the bank-agnostic fallback layout.
  bool get isGeneric => false;

  String get fileExtension => 'csv';
  String get mimeType => 'text/csv';
  String get lineEnding => '\r\n';
  bool get trailingNewline => true;

  /// Column headings, or null when the bank expects no header row.
  List<String>? get headerRow => null;

  int get referenceMaxLength => 20;
  int get nameMaxLength => 30;
  int get payerNameMaxLength => 30;

  /// One file row for [line].
  List<String> formatRow(BankPaymentLine line, BankExportContext ctx);

  /// Short note for the export dialog, or null when nothing needs saying.
  String? get userNote {
    if (isGeneric) {
      return 'Generic layout with column headings — map the columns in '
          'your bank\'s import screen and test a small upload first.';
    }
    if (!verified) {
      return 'Template not yet confirmed with $displayName — test a small '
          'upload first.';
    }
    return null;
  }

  /// Why [line] can't be exported with this template; empty = OK.
  List<String> validate(BankPaymentLine line) {
    final issues = <String>[];
    if (!RegExp(r'^\d{6,16}$').hasMatch(digitsOnly(line.accountNumber))) {
      issues.add('account number must be 6–16 digits');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(digitsOnly(line.branchCode))) {
      issues.add('branch code must be 6 digits');
    }
    if (line.amountCents <= 0) issues.add('net pay is R 0.00 or less');
    return issues;
  }

  /// Prefix + first name (e.g. "Salaries Willem"), cleaned and cut to
  /// [referenceMaxLength].
  String reference(BankPaymentLine line, BankExportContext ctx) {
    final prefix = ctx.referencePrefix.trim().isEmpty
        ? defaultReferencePrefix
        : ctx.referencePrefix.trim();
    return cleanText('$prefix ${line.firstName}', referenceMaxLength);
  }

  /// The complete file contents.
  String build(List<BankPaymentLine> lines, BankExportContext ctx) {
    final rows = <List<String>>[
      if (headerRow != null) headerRow!,
      for (final l in lines) formatRow(l, ctx),
    ];
    final body =
        rows.map((r) => r.map(csvCell).join(',')).join(lineEnding);
    return trailingNewline && body.isNotEmpty ? '$body$lineEnding' : body;
  }

  String fileName(String companyName, String periodLabel) =>
      '$companyName Bank Payments $displayName $periodLabel.$fileExtension';

  // ── Shared formatting helpers ───────────────────────────────────────────

  static String digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

  static const _diacritics = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e',
    'ë': 'e', 'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ó': 'o', 'ò': 'o',
    'ô': 'o', 'ö': 'o', 'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c',
    'ñ': 'n', 'Á': 'A', 'À': 'A', 'Â': 'A', 'Ä': 'A', 'É': 'E', 'È': 'E',
    'Ê': 'E', 'Ë': 'E', 'Í': 'I', 'Î': 'I', 'Ï': 'I', 'Ó': 'O', 'Ô': 'O',
    'Ö': 'O', 'Ú': 'U', 'Û': 'U', 'Ü': 'U', 'Ç': 'C', 'Ñ': 'N',
  };

  /// Letters, digits and single spaces only (accents folded, e.g.
  /// "Hendrië" → "Hendrie"), cut to [max] characters. Case is preserved.
  static String cleanText(String s, int max) {
    final folded = s.split('').map((c) => _diacritics[c] ?? c).join();
    final cleaned = folded
        .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.length > max ? cleaned.substring(0, max).trim() : cleaned;
  }

  /// Plain number with up to 2 decimals and no trailing zeros:
  /// 694500 → "6945", 137214 → "1372.14", 123450 → "1234.5".
  static String plainAmount(int cents) {
    final whole = cents ~/ 100;
    final frac = cents % 100;
    if (frac == 0) return '$whole';
    final f = frac.toString().padLeft(2, '0');
    return '$whole.${f.endsWith('0') ? f.substring(0, 1) : f}';
  }

  /// Always 2 decimals: 694500 → "6945.00".
  static String fixedAmount(int cents) =>
      '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

  /// Quotes a cell only if it contains a comma, quote or newline. Values from
  /// [cleanText] never do, so bank rows stay unquoted.
  static String csvCell(String v) => v.contains(RegExp(r'[",\r\n]'))
      ? '"${v.replaceAll('"', '""')}"'
      : v;
}
