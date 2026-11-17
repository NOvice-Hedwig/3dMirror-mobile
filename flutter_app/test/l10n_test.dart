import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_3d/core/l10n/app_localizations.dart';
import 'package:mirror_3d/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Files whose user-facing text has been moved to the ARB files. Add each file here as its
// batch is migrated; the test then keeps Chinese string literals from creeping back in.
const migratedFiles = [
  'lib/features/me/me_screen.dart',
  'lib/features/auth/auth_screen.dart',
  'lib/core/validation/login_identity.dart',
  'lib/services/api/auth_api.dart',
  'lib/main.dart',
  // batch 2: home FAB and log sheets. models/log_values.dart is deliberately absent: it
  // holds the stored Chinese values (data, not display text).
  'lib/features/home/widgets/fab_button.dart',
  'lib/features/home/widgets/log_sheets/_sheet_base.dart',
  'lib/features/home/widgets/log_sheets/diet_log_sheet.dart',
  'lib/features/home/widgets/log_sheets/health_log_sheet.dart',
  'lib/features/home/widgets/log_sheets/sleep_log_sheet.dart',
  'lib/features/home/widgets/log_sheets/supplement_log_sheet.dart',
  'lib/features/home/widgets/log_sheets/workout_log_sheet.dart',
  'lib/models/log_models.dart',
  // batch 3: onboarding and photos
  'lib/features/onboarding/onboarding_screen.dart',
  'lib/features/onboarding/photo_capture_screen.dart',
  'lib/models/body_photo.dart',
  'lib/services/api/photo_api.dart',
  // batch 4: records
  'lib/features/input/input_screen.dart',
  'lib/features/history/history_screen.dart',
  'lib/features/snapshot/snapshot_screen.dart',
  'lib/features/compare/compare_screen.dart',
  'lib/features/predict/predict_screen.dart',
  'lib/services/api/predict_api.dart',
  'lib/core/l10n/session_labels.dart',
  // batch 5: me, challenge, coach and exercise library
  'lib/features/me/challenge_screen.dart',
  'lib/features/coach/coach_screen.dart',
  'lib/features/coach/exercise_library_screen.dart',
  'lib/core/l10n/coach_text.dart',
  'lib/models/coach_models.dart',
  'lib/services/api/api_http.dart',
];

Map<String, dynamic> readArb(String lang) =>
    json.decode(File('lib/core/l10n/app_$lang.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

final _placeholder = RegExp(r'\{(\w+)\}');
Set<String> placeholdersIn(String message) =>
    _placeholder.allMatches(message).map((m) => m.group(1)!).toSet();

final _cjk = RegExp(r'[㐀-鿿　-〿＀-￯]');
final _stringLiteral = RegExp(r'''r?'(?:[^'\\\n]|\\.)*'|r?"(?:[^"\\\n]|\\.)*"''');

/// Chinese text inside string literals, ignoring comments.
List<String> chineseLiterals(String source) {
  final hits = <String>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('//') || trimmed.startsWith('*') || trimmed.startsWith('/*')) continue;
    final comment = line.indexOf(RegExp(r'\s//\s'));
    if (comment >= 0) line = line.substring(0, comment);
    for (final m in _stringLiteral.allMatches(line)) {
      if (_cjk.hasMatch(m.group(0)!)) hits.add('${i + 1}: ${m.group(0)}');
    }
  }
  return hits;
}

void main() {
  group('ARB files', () {
    final zh = readArb('zh');
    final en = readArb('en');

    test('declare their locale', () {
      expect(zh['@@locale'], 'zh');
      expect(en['@@locale'], 'en');
    });

    test('have the same keys', () {
      final zk = messageKeys(zh), ek = messageKeys(en);
      expect(zk.difference(ek), isEmpty, reason: 'only in app_zh.arb');
      expect(ek.difference(zk), isEmpty, reason: 'only in app_en.arb');
    });

    test('have no empty messages', () {
      for (final arb in [zh, en]) {
        for (final k in messageKeys(arb)) {
          expect((arb[k] as String).trim(), isNotEmpty, reason: '${arb['@@locale']}.$k');
        }
      }
    });

    test('use the same placeholders in both languages, declared in the template', () {
      for (final k in messageKeys(zh)) {
        final pz = placeholdersIn(zh[k] as String);
        final pe = placeholdersIn(en[k] as String);
        expect(pe, pz, reason: k);
        if (pz.isNotEmpty) {
          final declared = ((zh['@$k'] as Map?)?['placeholders'] as Map?)?.keys.toSet() ?? {};
          expect(declared, pz, reason: '@$k placeholders in app_zh.arb');
        }
      }
    });

    test('English messages contain no Chinese', () {
      final allowed = {'languageZh'};   // the language's own name
      for (final k in messageKeys(en).difference(allowed)) {
        expect(_cjk.hasMatch(en[k] as String), isFalse, reason: 'app_en.arb $k: ${en[k]}');
      }
    });
  });

  test('migrated files have no Chinese string literals', () {
    for (final path in migratedFiles) {
      expect(chineseLiterals(File(path).readAsStringSync()), isEmpty, reason: path);
    }
  });

  test('the literal scan itself finds Chinese literals and skips comments', () {
    const src = "// 注释\nfinal a = '中文'; // 也是注释\nfinal b = 'ok';\n";
    expect(chineseLiterals(src), ["2: '中文'"]);
  });

  group('resolveAppLocale', () {
    test('uses the first supported device language', () {
      expect(resolveAppLocale(const [Locale('en', 'US')]), const Locale('en'));
      expect(resolveAppLocale(const [Locale('fr'), Locale('en', 'GB')]), const Locale('en'));
      expect(resolveAppLocale(const [Locale('zh', 'CN'), Locale('en')]), const Locale('zh'));
    });

    test('any Chinese variant gets Simplified Chinese', () {
      expect(resolveAppLocale(const [Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant',
          countryCode: 'TW')]), const Locale('zh'));
    });

    test('falls back to Chinese', () {
      expect(resolveAppLocale(const [Locale('ja'), Locale('de')]), const Locale('zh'));
      expect(resolveAppLocale(const []), const Locale('zh'));
      expect(resolveAppLocale(null), const Locale('zh'));
    });
  });

  test('AppLanguage parses stored values, unknown means follow the system', () {
    expect(AppLanguage.parse('zh'), AppLanguage.zh);
    expect(AppLanguage.parse('en'), AppLanguage.en);
    expect(AppLanguage.parse('system'), AppLanguage.system);
    expect(AppLanguage.parse(null), AppLanguage.system);
    expect(AppLanguage.parse('fr'), AppLanguage.system);
    expect(AppLanguage.system.locale, isNull);
  });

  group('language choice', () {
    test('persists across restarts', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await loadAppLanguage(), AppLanguage.system);

      final first = ProviderContainer();
      await first.read(appLanguageProvider.notifier).set(AppLanguage.en);
      first.dispose();

      // A fresh start: main() loads the saved value and seeds the provider with it.
      final saved = await loadAppLanguage();
      expect(saved, AppLanguage.en);
      final second = ProviderContainer(
          overrides: [initialAppLanguageProvider.overrideWithValue(saved)]);
      expect(second.read(appLanguageProvider), AppLanguage.en);
      second.dispose();
    });

    testWidgets('switching updates the text; follow system uses the device', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.platformDispatcher.localesTestValue = const [Locale('fr', 'FR')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: Consumer(builder: (context, ref, _) => MaterialApp(
          locale: ref.watch(appLanguageProvider).locale,
          supportedLocales: kSupportedLocales,
          localeListResolutionCallback: (preferred, _) => resolveAppLocale(preferred),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(builder: (c) => Text(S.of(c).languageSheetTitle)),
        )),
      ));
      await tester.pumpAndSettle();
      expect(find.text('语言'), findsOneWidget);           // French device → Chinese fallback

      await container.read(appLanguageProvider.notifier).set(AppLanguage.en);
      await tester.pumpAndSettle();
      expect(find.text('Language'), findsOneWidget);

      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      await container.read(appLanguageProvider.notifier).set(AppLanguage.zh);
      await tester.pumpAndSettle();
      expect(find.text('语言'), findsOneWidget);           // explicit choice beats the device

      await container.read(appLanguageProvider.notifier).set(AppLanguage.system);
      await tester.pumpAndSettle();
      expect(find.text('Language'), findsOneWidget);       // back to the (English) device
    });
  });
}
