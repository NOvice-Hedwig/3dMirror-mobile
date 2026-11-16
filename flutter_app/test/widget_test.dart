// Smoke test: the real app root (MirrorApp: router, theme, localizations, session
// listener) starts and, with no stored session, shows the login screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mirror_3d/main.dart';
import 'package:mirror_3d/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Tests have no network; fall back to the default font instead of fetching.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpApp(WidgetTester tester, AppLanguage language) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [initialAppLanguageProvider.overrideWithValue(language)],
      child: const MirrorApp(),
    ));
    // Router redirect (async prefs read) and the entrance animations.
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('signed out: the app opens on the login screen, in Chinese by default',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.platformDispatcher.localesTestValue = const [Locale('zh', 'CN')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await pumpApp(tester, AppLanguage.system);

    expect(find.text('发送验证码'), findsOneWidget);        // send-code button
    expect(find.text('手机号'), findsWidgets);              // phone tab and placeholder
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed out with English chosen: the login screen is in English',
      (tester) async {
    SharedPreferences.setMockInitialValues({'locale': 'en'});

    await pumpApp(tester, AppLanguage.en);

    expect(find.text('Send code'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
