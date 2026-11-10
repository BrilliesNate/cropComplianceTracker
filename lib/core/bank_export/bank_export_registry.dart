import 'bank_export_template.dart';
import 'templates/absa_template.dart';
import 'templates/capitec_template.dart';
import 'templates/fnb_template.dart';
import 'templates/generic_template.dart';
import 'templates/nedbank_template.dart';
import 'templates/standard_bank_template.dart';

export 'bank_export_template.dart';

/// All bulk-payment templates. To add a bank: write one
/// [BankExportTemplate] subclass and add it to [all].
class BankExportRegistry {
  BankExportRegistry._();

  /// Picker order: named banks alphabetically, generic fallback last.
  static const List<BankExportTemplate> all = [
    AbsaTemplate(),
    CapitecTemplate(),
    FnbTemplate(),
    NedbankTemplate(),
    StandardBankTemplate(),
    GenericTemplate(),
  ];

  /// The template with [id], or null if unknown / not set (e.g. a template
  /// that was removed, or first use).
  static BankExportTemplate? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
