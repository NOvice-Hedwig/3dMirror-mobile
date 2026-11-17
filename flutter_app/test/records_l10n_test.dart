// Batch 4 (records): input, history, snapshot, compare and predict screens, and the
// predict "not enough data" error code.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mirror_3d/core/l10n/app_localizations.dart';
import 'package:mirror_3d/core/l10n/error_text.dart';
import 'package:mirror_3d/core/l10n/session_labels.dart';
import 'package:mirror_3d/features/history/history_screen.dart';
import 'package:mirror_3d/features/input/input_screen.dart';
import 'package:mirror_3d/features/predict/predict_screen.dart';
import 'package:mirror_3d/features/snapshot/snapshot_screen.dart';
import 'package:mirror_3d/models/models.dart';
import 'package:mirror_3d/models/predict_models.dart';
import 'package:mirror_3d/services/api/api_http.dart';
import 'package:mirror_3d/services/api/predict_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _cjk = RegExp(r'[㐀-鿿]');

const _metrics = {
  'weeks': 4, 'predicted_weight_kg': 59.0, 'weight_delta_kg': -1.0,
  'predicted_body_fat_pct': 21.0, 'body_fat_delta_pct': -1.0, 'predicted_waist_cm': 70.0,
  'waist_delta_cm': -1.0, 'confidence': 0.6, 'data_points': 2,
};

const _notEnough = {'detail': '数据不足，请至少记录 2 次', 'code': 'predict_not_enough_data'};

Map<String, dynamic> _session(String id, String createdAt, double kg, String? workout) => {
  'id': id, 'user_id': 'u1', 'created_at': createdAt,
  'body_data': {'weight_kg': kg, 'body_fat_pct': 22.0},
  'avatar_params': {
    'height_norm': .5, 'weight_norm': .5, 'body_fat_norm': .5, 'waist_norm': .5,
    'hip_norm': .5, 'shoulder_norm': .5, 'muscle_norm': .5, 'gender': 'female',
  },
  'activity_data': workout == null ? null : {'workout_type': workout, 'duration_min': 40},
};

// One fake backend for the whole file; each test sets the responses it needs.
http.Response Function(http.Request) respond = (_) => http.Response('{}', 200);
final fakeClient = MockClient((req) async => respond(req));

/// Global y of the alphabetic baseline of the single Text matched by [f].
double baselineY(WidgetTester tester, Finder f) {
  final box = tester.renderObject<RenderBox>(f);
  final top = box.getDryBaseline(box.constraints, TextBaseline.alphabetic)!;
  return box.localToGlobal(Offset(0, top)).dy;
}

Finder richText(String text) => find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText() == text);

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

  group('labels', () {
    test('workout types read as before in Chinese and have English labels', () {
      const before = {
        WorkoutType.strength: '力量', WorkoutType.cardio: '有氧', WorkoutType.hiit: 'HIIT',
        WorkoutType.walk: '步行', WorkoutType.yoga: '瑜伽', WorkoutType.swim: '游泳',
        WorkoutType.cycling: '骑行', WorkoutType.rest: '休息日', WorkoutType.other: '其他',
      };
      for (final t in WorkoutType.values) {
        expect(workoutKindLabel(zh, t), before[t], reason: t.name);
        expect(_cjk.hasMatch(workoutKindLabel(en, t)), isFalse, reason: t.name);
      }
      expect(workoutKindLabel(en, WorkoutType.rest), 'Rest day');
    });

    test('intensity labels: Chinese as before, English short enough for the 36px chips', () {
      expect(Intensity.values.map((i) => intensityLabel(zh, i)), ['轻', '中', '强']);
      for (final i in Intensity.values) {
        expect(intensityLabel(en, i).length, lessThanOrEqualTo(4), reason: i.name);
      }
    });

    test('the predict error code has a translation', () {
      expect(errorCodeText(en, ErrorCode.predictNotEnoughData), 'Not enough data');
      expect(errorCodeText(zh, ErrorCode.predictNotEnoughData), '数据不足');
    });
  });

  group('PredictApi', () {
    test('400 with predict_not_enough_data becomes InsufficientDataException', () async {
      respond = (_) => jsonResponse(_notEnough, 400);
      await expectLater(PredictApi.instance.fetchPredict(4),
          throwsA(isA<InsufficientDataException>()));
    });

    test('another 400 is not mistaken for "not enough data"', () async {
      respond = (_) => jsonResponse({'detail': 'weeks must be positive'}, 400);
      await expectLater(PredictApi.instance.fetchPredict(4),
          throwsA(isNot(isA<InsufficientDataException>())));
    });
  });

  Future<void> pumpScreen(WidgetTester tester, Widget screen, String lang) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox());   // fresh state: screens load in initState
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
    testWidgets('predict without enough data, in English and Chinese', (tester) async {
      respond = (req) => req.url.path == '/predict'
          ? jsonResponse(_notEnough, 400)
          : jsonResponse([]);
      await pumpScreen(tester, const PredictScreen(), 'en');
      expect(find.text('Not enough data'), findsOneWidget);
      expect(find.text('Log your body data at least twice\nto unlock predictions'), findsOneWidget);
      expect(find.text('4 W'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      await pumpScreen(tester, const PredictScreen(), 'zh');
      expect(find.text('数据不足'), findsOneWidget);
      expect(find.text('返回'), findsOneWidget);
    });

    testWidgets('history in English: empty state, then a list', (tester) async {
      respond = (_) => jsonResponse([]);
      await pumpScreen(tester, const HistoryScreen(), 'en');
      expect(find.text('No sessions yet'), findsOneWidget);
      expect(find.text('Start logging'), findsOneWidget);

      final sessions = [
        _session('b', '2026-11-10T09:00:00Z', 60.0, 'strength'),
        _session('a', '2026-11-03T09:00:00Z', 61.2, null),
      ];
      // Selecting shows a predict row per range, with the predicted weight.
      respond = (req) => req.url.path == '/predict' ? jsonResponse(_metrics) : jsonResponse(sessions);
      await pumpScreen(tester, const HistoryScreen(), 'en');
      expect(find.text('RECORDS'), findsOneWidget);
      expect(find.text('Strength  ·  40 min'), findsOneWidget);
      expect(find.text('vs prev'), findsOneWidget);
      await tester.tap(find.text('COMPARE  ·  SELECT'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);
      expect(find.text('Compare'), findsOneWidget);
      expect(find.text('PREDICT'), findsNWidgets(3));
      expect(find.text('59.0'), findsNWidgets(3));
      expect(tester.takeException(), isNull);   // no overflow, e.g. the PREDICT tag

      await pumpScreen(tester, const HistoryScreen(), 'zh');
      expect(find.text('力量  ·  40 min'), findsOneWidget);
    });

    testWidgets('history compare mode without a prediction (one session)', (tester) async {
      // Was ONBOARDING §8.2 #16: the predict rows threw in build when predict failed.
      respond = (req) => req.url.path == '/predict'
          ? jsonResponse(_notEnough, 400)
          : jsonResponse([_session('a', '2026-11-03T09:00:00Z', 61.2, null)]);
      await pumpScreen(tester, const HistoryScreen(), 'en');
      await tester.tap(find.text('COMPARE  ·  SELECT'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('PREDICT'), findsNWidgets(3));
      expect(find.text('—'), findsNWidgets(3));        // no predicted weight
      expect(find.text('Select 2 more'), findsOneWidget);
    });

    testWidgets('snapshots in English; the summary values share one baseline', (tester) async {
      respond = (_) => jsonResponse([
        _session('b', '2026-11-10T09:00:00Z', 60.0, 'yoga'),
        _session('a', '2026-11-03T09:00:00Z', 61.2, null),
      ]);
      await pumpScreen(tester, const SnapshotScreen(), 'en');
      // "WEIGHT CHANGE" / "DAYS ACTIVE" may wrap; the values must still line up.
      final values = [find.text('2'), find.text('-1.2 kg'), find.text('7')];
      expect(values.map((f) => baselineY(tester, f)).toSet(), hasLength(1));
      expect(find.text('2 RECORDS'), findsOneWidget);
      expect(find.text('SESSIONS'), findsOneWidget);
      expect(find.text('WEIGHT CHANGE'), findsOneWidget);
      expect(find.text('DAYS ACTIVE'), findsOneWidget);
      expect(find.text('Yoga'), findsOneWidget);
      expect(find.text('LATEST'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpScreen(tester, const SnapshotScreen(), 'zh');
      expect(values.map((f) => baselineY(tester, f)).toSet(), hasLength(1));
      expect(find.text('次'), findsOneWidget);
    });

    testWidgets('input in English and Chinese', (tester) async {
      await pumpScreen(tester, const InputScreen(), 'en');
      expect(find.text('BODY  ·  DATA'), findsOneWidget);
      expect(richText('Tell me\nabout your body'), findsOneWidget);   // space before the italic word
      expect(find.text('Body fat'), findsOneWidget);
      expect(find.text('Rest day'), findsOneWidget);
      await tester.tap(find.text('Strength'));
      await tester.pumpAndSettle();
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Med'), findsOneWidget);
      await tester.tap(find.text('Body fat'));
      await tester.pumpAndSettle();
      expect(find.text('Body fat (%)'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpScreen(tester, const InputScreen(), 'zh');
      expect(richText('告诉我\n你的身体'), findsOneWidget);
      expect(find.text('体脂率'), findsOneWidget);
      expect(find.text('休息日'), findsOneWidget);
      expect(find.text('生成角色'), findsOneWidget);
    });
  });
}
