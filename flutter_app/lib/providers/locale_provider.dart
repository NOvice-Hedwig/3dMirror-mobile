import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's language choice on the Me screen. [system] follows the device locale.
enum AppLanguage {
  system, zh, en;

  /// The locale passed to MaterialApp: null lets the device locale decide.
  Locale? get locale => switch (this) {
    AppLanguage.system => null,
    AppLanguage.zh     => const Locale('zh'),
    AppLanguage.en     => const Locale('en'),
  };

  static AppLanguage parse(String? s) =>
      AppLanguage.values.firstWhere((l) => l.name == s, orElse: () => AppLanguage.system);
}

const kSupportedLocales = [Locale('zh'), Locale('en')];
const kFallbackLocale   = Locale('zh');

/// Picks the app language from the device's preferred locales, in order: the first one
/// whose language is Chinese (any script or region, shown as Simplified) or English.
/// Anything else falls back to Chinese.
Locale resolveAppLocale(List<Locale>? preferred) {
  for (final l in preferred ?? const <Locale>[]) {
    for (final s in kSupportedLocales) {
      if (l.languageCode == s.languageCode) return s;
    }
  }
  return kFallbackLocale;
}

const _prefsKey = 'locale';

/// Reads the saved choice. Called in main() before runApp so the first frame is
/// already in the right language.
Future<AppLanguage> loadAppLanguage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return AppLanguage.parse(prefs.getString(_prefsKey));
  } catch (_) {
    return AppLanguage.system;
  }
}

/// The saved choice at startup; main() overrides it with [loadAppLanguage]'s result.
final initialAppLanguageProvider = Provider<AppLanguage>((_) => AppLanguage.system);

final appLanguageProvider =
    NotifierProvider<AppLanguageNotifier, AppLanguage>(AppLanguageNotifier.new);

class AppLanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => ref.watch(initialAppLanguageProvider);

  Future<void> set(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.name);
  }
}
