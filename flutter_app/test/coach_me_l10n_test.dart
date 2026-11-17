// Batch 5 (Me and Coach): coach cards from code + params, and the coach, exercise library
// and challenge screens.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mirror_3d/core/l10n/app_localizations.dart';
import 'package:mirror_3d/core/l10n/coach_text.dart';
import 'package:mirror_3d/features/coach/coach_screen.dart';
import 'package:mirror_3d/features/coach/exercise_library_screen.dart';
import 'package:mirror_3d/features/me/challenge_screen.dart';
import 'package:mirror_3d/models/coach_models.dart';
import 'package:mirror_3d/services/api/api_http.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _cjk = RegExp(r'[㐀-鿿]');

// What backend/routers/coach.py sends for each code, with sample params: (params, title, body).
const serverCards = <String, (Map<String, num>, String, String)>{
  'training_not_started': ({}, '本周尚未开始训练', '建议本周完成 3 次训练，从 30 分钟有氧开始。'),
  'training_few_days': ({'days': 2}, '本周已训练 2 天', '距离目标还有差距，明天安排一次力量训练效果更佳。'),
  'training_on_track': ({'days': 4}, '本周已训练 4 天，保持！', '训练频率良好，注意保留至少1天恢复日。'),
  'weight_stable': ({}, '体重保持稳定', '若目标是减脂，可尝试每日增加 200kcal 热量缺口。'),
  'weight_up': ({'delta_kg': 1.3}, '本周体重上升 1.3kg', '检查近期饮食，减少精制碳水和夜间进食。'),
  'weight_down': ({'delta_kg': 1.0}, '本周体重下降 1.0kg', '进展良好！确保蛋白质摄入充足（每公斤体重 1.6g）。'),
  'diet_start_logging': ({}, '开始记录饮食', '记录饮食是减脂成功的关键，从今天的一餐开始。'),
  'recovery_after_strength': ({}, '力量训练后注意恢复', '训练后 30 分钟内补充蛋白质，睡眠 7-9 小时促进肌肉合成。'),
  'recovery_sleep': ({}, '睡眠是最好的恢复', '保持每晚 7-9 小时睡眠，有助于体脂代谢和体力恢复。'),
};

SuggestionCard card(String? code, Map<String, num> params, String title, String body) =>
    SuggestionCard(category: 'training', code: code, params: params,
        title: title, body: body, priority: 1);

http.Response Function(http.Request) respond = (_) => http.Response('{}', 200);
final fakeClient = MockClient((req) async => respond(req));

http.Response jsonResponse(Object body, [int status = 200]) => http.Response.bytes(
    utf8.encode(json.encode(body)), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  final zh = lookupS(const Locale('zh'));
  final en = lookupS(const Locale('en'));

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    http.runWithClient(() => ApiHttp.instance, () => fakeClient);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'mirror_token': 'tok'});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (call) async => call.method == 'getLocalTimezone' ? 'Europe/London' : null,
    );
  });

  group('coach card text', () {
    test('the app knows exactly the codes backend/routers/coach.py sends', () {
      final src = File('../backend/routers/coach.py').readAsStringSync();
      final sent = RegExp(r'code="(\w+)"').allMatches(src).map((m) => m[1]).toSet();
      expect(sent, CoachCode.all.toSet());
      expect(serverCards.keys.toSet(), CoachCode.all.toSet());
    });

    test('Chinese text is exactly what the server sends (title with params, and body)', () {
      final src = File('../backend/routers/coach.py').readAsStringSync();
      for (final e in serverCards.entries) {
        final (params, title, body) = e.value;
        expect(coachCardText(zh, card(e.key, params, title, body)), (title, body), reason: e.key);
        expect(src.contains(body), isTrue, reason: '${e.key} body not in coach.py');
      }
    });

    test('English text for every code, with the params filled in', () {
      for (final e in serverCards.entries) {
        final (params, title, body) = e.value;
        final (t, b) = coachCardText(en, card(e.key, params, title, body));
        expect(_cjk.hasMatch(t) || _cjk.hasMatch(b), isFalse, reason: e.key);
      }
      final (t, _) = coachCardText(en, card('weight_up', {'delta_kg': 1.26}, 'x', 'y'));
      expect(t, 'Up 1.3 kg this week');
      final (d, _) = coachCardText(en, card('training_few_days', {'days': 2}, 'x', 'y'));
      expect(d, 'Training days this week: 2');
    });

    test('unknown code, no code, or a missing param shows the server text', () {
      expect(coachCardText(en, card('sleep_debt', {}, '睡眠不足', '早点睡')), ('睡眠不足', '早点睡'));
      expect(coachCardText(en, card(null, {}, '旧版', '文本')), ('旧版', '文本'));
      expect(coachCardText(en, card('weight_up', {}, '本周体重上升 1.3kg', 'b')),
          ('本周体重上升 1.3kg', 'b'));
    });

    test('fromJson reads code and params; older responses without them still parse', () {
      final c = SuggestionCard.fromJson({'category': 'nutrition', 'code': 'weight_up',
          'params': {'delta_kg': 1.3}, 'title': 't', 'body': 'b', 'priority': 1});
      expect(c.code, 'weight_up');
      expect(c.params, {'delta_kg': 1.3});
      final old = SuggestionCard.fromJson(
          {'category': 'nutrition', 'title': 't', 'body': 'b', 'priority': 1});
      expect(old.code, isNull);
      expect(old.params, isEmpty);
    });
  });

  Future<void> pumpScreen(WidgetTester tester, Widget screen, String lang) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(ProviderScope(child: MaterialApp(
      locale: Locale(lang),
      supportedLocales: const [Locale('zh'), Locale('en')],
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: screen,
    )));
    await tester.pumpAndSettle();
  }

  group('screens', () {
    testWidgets('coach in English: cards from codes; an unknown code keeps the server text',
        (tester) async {
      respond = (req) => switch (req.url.path) {
        '/coach/suggestions' => jsonResponse({'data_points': 0, 'generated_at': 'x', 'cards': [
          {'category': 'training', 'code': 'training_few_days', 'params': {'days': 2},
           'title': '本周已训练 2 天', 'body': '…', 'priority': 2},
          {'category': 'recovery', 'code': 'brand_new_code', 'params': {},
           'title': '新卡片', 'body': '新内容', 'priority': 3},
        ]}),
        _ => jsonResponse([]),
      };
      await pumpScreen(tester, const CoachScreen(), 'en');
      expect(find.text('Log your body data once to set a goal'), findsOneWidget);
      expect(find.text('TRAINING'), findsOneWidget);
      expect(find.text('Training days this week: 2'), findsOneWidget);
      expect(find.text("You're short of your goal. A strength workout tomorrow would help."),
          findsOneWidget);
      expect(find.text('新卡片'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpScreen(tester, const CoachScreen(), 'zh');
      expect(find.text('本周已训练 2 天'), findsOneWidget);
      expect(find.text('先记录一次身体数据以开启目标设置'), findsOneWidget);
    });

    testWidgets('goal slider labels: English at normal size, Chinese column unchanged',
        (tester) async {
      respond = (req) => switch (req.url.path) {
        '/sessions' => jsonResponse([{
          'id': 's1', 'user_id': 'u1', 'created_at': '2026-11-10T09:00:00Z',
          'body_data': {'weight_kg': 60.0},
          'avatar_params': {'height_norm': .5, 'weight_norm': .5, 'body_fat_norm': .5,
              'waist_norm': .5, 'hip_norm': .5, 'shoulder_norm': .5, 'muscle_norm': .5,
              'gender': 'female'},
        }]),
        _ => jsonResponse({'data_points': 0, 'generated_at': 'x', 'cards': []}),
      };
      // The label column is the SizedBox around the FittedBox around the label.
      double column(String label) => tester.getSize(find.ancestor(
          of: find.text(label), matching: find.byType(SizedBox)).first).width;
      // Rendered width / layout width: 1.0 means the FittedBox didn't shrink the label.
      double scale(String label) =>
          tester.getRect(find.text(label)).width / tester.getSize(find.text(label)).width;

      // The column is the widest label's natural width + 8, kept within 52..120; a label
      // that fits is drawn at normal size. (The test font is wider than the real one, so
      // "Shoulders" may hit the cap here; the emulator check covers real metrics.)
      await pumpScreen(tester, const CoachScreen(), 'en');
      const labels = ['Weight', 'Body fat', 'Waist', 'Hips', 'Shoulders', 'Muscle'];
      final natural = {for (final l in labels) l: tester.getSize(find.text(l)).width};
      final widest  = natural.values.reduce((a, b) => a > b ? a : b);
      final col     = column('Body fat');
      expect(col, (widest + 8).clamp(52.0, 120.0));
      expect(col, greaterThan(52));                       // wider than the old fixed column
      for (final l in labels) {
        if (natural[l]! <= col) expect(scale(l), closeTo(1.0, 0.001), reason: l);
      }
      expect(tester.takeException(), isNull);

      await pumpScreen(tester, const CoachScreen(), 'zh');
      expect(column('体脂率'), 52);
      expect(scale('肌肉量'), closeTo(1.0, 0.001));
    });

    testWidgets('exercise library: English filter chips still filter by the stored group',
        (tester) async {
      await pumpScreen(tester, const ExerciseLibraryScreen(), 'en');
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Lower back pain'), findsNothing);
      // 'Back' is also the nav label and each back exercise's group label: tap the chip.
      await tester.tap(find.descendant(
          of: find.byType(SingleChildScrollView), matching: find.text('Back')));
      await tester.pumpAndSettle();
      expect(find.text('引体向上'), findsOneWidget);    // a back exercise (names stay Chinese)
      expect(find.text('卧推'), findsNothing);          // a chest exercise is filtered out
      expect(tester.takeException(), isNull);
    });

    testWidgets('challenge setup and progress in English', (tester) async {
      respond = (_) => jsonResponse(
          {'detail': '未设定挑战目标', 'code': 'challenge_not_set'}, 404);
      await pumpScreen(tester, const ChallengeScreen(), 'en');
      expect(find.text('MONTHLY  ·  CHALLENGE'), findsOneWidget);
      await tester.tap(find.text('Combined'));
      await tester.pumpAndSettle();
      expect(find.text('Target weight kg'), findsOneWidget);
      expect(find.text('Target body fat %'), findsOneWidget);
      expect(find.text('Target waist cm'), findsOneWidget);
      expect(tester.takeException(), isNull);   // the four goal chips fit (Wrap)

      respond = (_) => jsonResponse({
        'goal': {'goal_type': 'weight', 'target_weight_kg': 58.0,
                 'start_date': '2026-11-01', 'end_date': '2026-12-01'},
        'current_weight': 60.0, 'current_body_fat': null, 'current_waist': null,
        'progress_pct': 40.0, 'days_remaining': 15, 'is_completed': false,
        'discount_eligible': false,
      });
      await pumpScreen(tester, const ChallengeScreen(), 'en');
      expect(find.text('DAYS  ·  REMAINING'), findsOneWidget);
      expect(find.text('METRIC'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      await tester.tap(find.text("Give up this month's challenge"));
      await tester.pumpAndSettle();
      expect(find.text('Give up the challenge?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
