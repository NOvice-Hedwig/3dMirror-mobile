import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mirror_3d/core/l10n/app_localizations.dart';
import 'package:mirror_3d/core/router/app_router.dart';
import 'package:mirror_3d/features/onboarding/onboarding_screen.dart';
import 'package:mirror_3d/features/onboarding/photo_capture_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpScreen(WidgetTester tester, Widget screen, String lang) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => screen),
    GoRoute(path: MirrorRoute.photoCapture,
        builder: (_, __) => const Scaffold(body: Text('photo-capture'))),
    GoRoute(path: MirrorRoute.home, builder: (_, __) => const Scaffold(body: Text('home'))),
  ]);
  await tester.pumpWidget(ProviderScope(child: MaterialApp.router(
    routerConfig: router,
    locale: Locale(lang),
    supportedLocales: const [Locale('zh'), Locale('en')],
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  )));
  await tester.pumpAndSettle();
}

/// Text inside Text.rich spans (titles) is not found by find.text.
Finder richText(String text) => find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText().contains(text));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('onboarding in English: every step translated; the goal id is stored',
      (tester) async {
    await pumpScreen(tester, const OnboardingScreen(), 'en');

    expect(find.text('LEGAL & PRIVACY'), findsOneWidget);
    expect(richText('Terms &'), findsOneWidget);
    expect(find.text('AI predictions are for reference only and are not medical advice'),
        findsOneWidget);
    await tester.tap(find.text('I have read and agree to the Terms of Service'));
    await tester.tap(find.text('I have read and agree to the Privacy Policy'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(richText('basics'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('25 yrs'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR GOAL'), findsOneWidget);
    await tester.tap(find.text('Build muscle'));
    await tester.pump();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('mirror_goal'), 'build_muscle');
    expect(prefs.getString('mirror_gender'), 'female');
    expect(find.text('photo-capture'), findsOneWidget);
  });

  testWidgets('onboarding in Chinese reads as before', (tester) async {
    await pumpScreen(tester, const OnboardingScreen(), 'zh');
    expect(richText('隐私协议'), findsOneWidget);
    expect(find.text('我已阅读并同意《服务条款》'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);   // the English gloss under it
    expect(find.text('下一步'), findsOneWidget);
  });

  testWidgets('photo capture in English and Chinese', (tester) async {
    await pumpScreen(tester, const PhotoCaptureScreen(), 'en');
    expect(find.text('BODY SCAN'), findsOneWidget);
    expect(find.text('0 / 3 done'), findsOneWidget);
    expect(find.text('Front'), findsOneWidget);
    expect(find.text('Stand side-on (90°)'), findsOneWidget);
    expect(find.text('Face away from the camera'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(find.text('Skip the rest and finish'), findsOneWidget);

    await pumpScreen(tester, const PhotoCaptureScreen(), 'zh');
    expect(find.text('已完成 0 / 3'), findsOneWidget);
    expect(find.text('前视图'), findsOneWidget);
    expect(find.text('稍后再说'), findsOneWidget);
  });
}
