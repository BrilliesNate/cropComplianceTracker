import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cropCompliance/core/offline/offline_write.dart';
import 'package:cropCompliance/l10n/generated/app_localizations.dart';
import 'package:cropCompliance/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app language (English / Afrikaans).
///
/// The choice is saved on the user's account (`users/{id}.language`) so it
/// follows them between the phone app and the website, and on the device so
/// the app starts in the right language before anyone has signed in.
///
/// Also sets `Intl.defaultLocale`, so every DateFormat in the app (month and
/// day names) follows the language without each call passing a locale.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider._();
  static final LocaleProvider instance = LocaleProvider._();

  static const supported = [Locale('en'), Locale('af')];
  static const _prefsKey = 'app.language';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  bool get isAfrikaans => _locale.languageCode == 'af';
  String get code => _locale.languageCode;

  /// Texts for code that has no BuildContext (services, PDF builders).
  AppLocalizations get l10n => lookupAppLocalizations(_locale);

  String? _userId;

  /// Call once in main() before runApp: loads date names for both languages
  /// and the device's last choice.
  Future<void> init() async {
    await initializeDateFormatting();
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved == 'af' || saved == 'en') _apply(saved!, notify: false);
    } catch (e) {
      debugPrint('Language: could not read device setting: $e');
    }
    Intl.defaultLocale = code;
  }

  /// Follow the signed-in user's saved language (if they've chosen one).
  void adoptUser(UserModel? user) {
    _userId = user?.id;
    final lang = user?.language;
    if ((lang == 'en' || lang == 'af') && lang != code) {
      _apply(lang!);
      _saveOnDevice();
    }
  }

  /// The user picked a language: switch now, remember it on this device and
  /// on their account (queued if offline).
  Future<void> setLanguage(String lang) async {
    if (lang != 'en' && lang != 'af') return;
    if (lang == code) return;
    _apply(lang);
    _saveOnDevice();
    final uid = _userId;
    if (uid != null && uid.isNotEmpty) {
      await commitWrite(
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'language': lang}),
        label: 'language',
      ).catchError((Object e) {
        debugPrint('Language: could not save to account: $e');
      });
    }
  }

  void _apply(String lang, {bool notify = true}) {
    _locale = Locale(lang);
    Intl.defaultLocale = lang;
    if (notify) notifyListeners();
  }

  Future<void> _saveOnDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, code);
    } catch (e) {
      debugPrint('Language: could not save device setting: $e');
    }
  }
}

/// `context.l10n.someText` — the current language's texts.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
