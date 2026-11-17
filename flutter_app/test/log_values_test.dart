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
import 'package:mirror_3d/core/l10n/log_value_labels.dart';
import 'package:mirror_3d/features/home/widgets/log_sheets/diet_log_sheet.dart';
import 'package:mirror_3d/features/home/widgets/log_sheets/health_log_sheet.dart';
import 'package:mirror_3d/features/home/widgets/log_sheets/supplement_log_sheet.dart';
import 'package:mirror_3d/features/home/widgets/log_sheets/workout_log_sheet.dart';
import 'package:mirror_3d/models/log_models.dart';
import 'package:mirror_3d/models/log_values.dart';
import 'package:mirror_3d/services/api/api_http.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The values the sheets sent before i18n. They are stored by the backend, so they must
// never change; this list is the contract.
const storedBefore = {
  'meal':       ['早餐', '午餐', '晚餐', '加餐'],
  'type':       ['有氧', '无氧', '普拉提', '球类', '其他'],
  'cardio':     ['跑步', '跳绳', '跳操', 'HIIT', '游泳', '爬山', '骑行', '其他'],
  'pilates':    ['垫上普拉提', '器械普拉提'],
  'ball':       ['篮球', '羽毛球', '网球', '乒乓球', '足球', '其他'],
  'muscle':     ['胸', '背', '腿', '肩', '手臂', '核心'],
  'symptom':    ['痛经', '情绪波动', '水肿', '长痘', '疲劳', '腰酸'],
  'supplement': ['蛋白粉', '肌酸', '维生素D', '胶原蛋白', '鱼油', '维生素C', '铁', '叶酸', '镁', '锌'],
};

final _cjk = RegExp(r'[㐀-鿿]');

// Every HTTP request in this file goes through one fake client; the handler records bodies.
final requests = <http.Request>[];
final fakeClient = MockClient((req) async {
  requests.add(req);
  return http.Response('{}', 200);
});

void main() {
  final zh = lookupS(const Locale('zh'));
  final en = lookupS(const Locale('en'));

  final sets = <String, (List<String>, String Function(S, String))>{
    'meal':       (MealValue.all, mealLabel),
    'type':       (WorkoutLogType.all, workoutTypeLabel),
    'cardio':     (WorkoutSubType.byType[WorkoutLogType.cardio]!, workoutSubTypeLabel),
    'pilates':    (WorkoutSubType.byType[WorkoutLogType.pilates]!, workoutSubTypeLabel),
    'ball':       (WorkoutSubType.byType[WorkoutLogType.ball]!, workoutSubTypeLabel),
    'muscle':     (MuscleGroupValue.all, muscleGroupLabel),
    'symptom':    (SymptomValue.all, symptomLabel),
    'supplement': (SupplementValue.all, supplementLabel),
  };

  group('stored values', () {
    test('are exactly the values sent before i18n', () {
      for (final e in sets.entries) {
        expect(e.value.$1, storedBefore[e.key], reason: e.key);
      }
    });

    test('meal values match the CHECK constraint in backend/migration.sql', () {
      final sql = File('../backend/migration.sql').readAsStringSync();
      final m = RegExp(r"CHECK \(meal IN \(([^)]*)\)\)").firstMatch(sql)!;
      final values = RegExp(r"'([^']*)'").allMatches(m.group(1)!).map((x) => x.group(1)).toList();
      expect(values, MealValue.all);
    });

    test("the strength type matches what backend/routers/coach.py compares", () {
      final coach = File('../backend/routers/coach.py').readAsStringSync();
      expect(coach, contains('get("type") == "${WorkoutLogType.strength}"'));
    });

    test('model serialization sends the stored values unchanged', () {
      final diet = DietLogEntry(id: '', userId: '', loggedAt: DateTime(2026),
          meal: MealValue.snack, foodName: 'x', calories: 1);
      expect(diet.toJson()['meal'], '加餐');
      const workout = WorkoutLogEntry(type: WorkoutLogType.pilates,
          subType: WorkoutSubType.matPilates, durationMin: 30, intensity: 'low');
      expect(workout.toJson()['type'], '普拉提');
      expect(workout.toJson()['sub_type'], '垫上普拉提');
      const period = PeriodLogEntry(phase: 'start',
          symptoms: [SymptomValue.cramps], intensity: 2, date: '2026-11-15');
      expect(period.toJson()['symptoms'], ['痛经']);
    });

    test('calorie estimate still recognises the stored sub types', () {
      int kcal(String sub) => WorkoutLogEntry.estimateCalories(
          subType: sub, durationMin: 10, intensity: 'medium');
      expect(kcal(WorkoutSubType.running), 100);
      expect(kcal(WorkoutSubType.jumpRope), 120);
      expect(kcal(WorkoutSubType.hiit), 110);
      expect(kcal(WorkoutSubType.swimming), 80);
    });
  });

  group('labels', () {
    test('in Chinese the label is the stored value, so the Chinese UI is unchanged', () {
      for (final e in sets.entries) {
        for (final v in e.value.$1) {
          expect(e.value.$2(zh, v), v, reason: '${e.key}: $v');
        }
      }
    });

    test('in English every value has an English label', () {
      for (final e in sets.entries) {
        for (final v in e.value.$1) {
          final label = e.value.$2(en, v);
          expect(_cjk.hasMatch(label), isFalse, reason: '${e.key}: $v → $label');
        }
      }
    });

    test('unknown values (custom names, old data) are shown as they are', () {
      expect(mealLabel(en, '夜宵'), '夜宵');
      expect(workoutSubTypeLabel(en, '攀岩'), '攀岩');
      expect(supplementLabel(en, 'Glutamine'), 'Glutamine');
    });

    test('English wording chosen for 水肿 and 足球', () {
      expect(symptomLabel(en, SymptomValue.swelling), 'Bloating');
      expect(workoutSubTypeLabel(en, WorkoutSubType.football), 'Soccer');
    });
  });

  group('log sheets in English send the stored Chinese values', () {
    setUpAll(() {
      GoogleFonts.config.allowRuntimeFetching = false;
      // ApiHttp.instance is created on first use; create it inside the fake-client zone.
      http.runWithClient(() => ApiHttp.instance, () => fakeClient);
    });

    setUp(() {
      requests.clear();
      SharedPreferences.setMockInitialValues({'mirror_token': 'tok'});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'),
        (call) async => call.method == 'getLocalTimezone' ? 'Europe/London' : null,
      );
    });

    Future<void> openSheet(WidgetTester tester, Widget sheet) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('zh'), Locale('en')],
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: Builder(builder: (context) => TextButton(
          onPressed: () => showModalBottomSheet<void>(
              context: context, isScrollControlled: true, builder: (_) => sheet),
          child: const Text('open'),
        ))),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Future<Map<String, dynamic>> saveAndCapture(WidgetTester tester, String path) async {
      await tester.tap(find.text('SAVE  ·  RECORD'));
      await tester.pumpAndSettle();
      final req = requests.singleWhere((r) => r.url.path == path);
      return json.decode(req.body) as Map<String, dynamic>;
    }

    testWidgets('diet: "Lunch" sends 午餐', (tester) async {
      await openSheet(tester, const DietLogSheet());
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('早餐'), findsNothing);
      await tester.tap(find.text('Lunch'));
      await tester.tap(find.text('Manual'));
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextField, 'Food name'), 'Oats');
      await tester.enterText(find.widgetWithText(TextField, 'Calories *'), '150');
      final body = await saveAndCapture(tester, '/logs/diet');
      expect(body['meal'], '午餐');
      expect(find.text('Meal logged'), findsOneWidget);
    });

    testWidgets('workout: "Ball sports" / "Table tennis" sends 球类 / 乒乓球', (tester) async {
      await openSheet(tester, const WorkoutLogSheet());
      expect(find.text('Running'), findsOneWidget);
      await tester.tap(find.text('Ball sports'));
      await tester.pumpAndSettle();
      expect(find.text('Basketball'), findsOneWidget);
      await tester.tap(find.text('Table tennis'));
      final body = await saveAndCapture(tester, '/logs/workout');
      expect(body['type'], '球类');
      expect(body['sub_type'], '乒乓球');
    });

    testWidgets('health: "Cramps" and "Bloating" send 痛经 and 水肿', (tester) async {
      await openSheet(tester, const HealthLogSheet());
      await tester.tap(find.text('Period started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cramps'));
      await tester.tap(find.text('Bloating'));
      await tester.pump();
      final body = await saveAndCapture(tester, '/logs/period');
      expect(body['phase'], 'start');
      expect(body['symptoms'], ['痛经', '水肿']);
    });

    testWidgets('supplements: "Creatine" sends 肌酸; a custom name is sent as typed',
        (tester) async {
      await openSheet(tester, const SupplementLogSheet());
      await tester.tap(find.text('Creatine'));
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Glutamine');
      await tester.pump();
      final req = await saveAndCaptureList(tester, '/logs/supplements');
      expect(req.map((e) => e['name']), ['肌酸', 'Glutamine']);
    });
  });
}

Future<List<Map<String, dynamic>>> saveAndCaptureList(WidgetTester tester, String path) async {
  await tester.tap(find.text('SAVE  ·  RECORD'));
  await tester.pumpAndSettle();
  final req = requests.singleWhere((r) => r.url.path == path);
  return (json.decode(req.body) as List).cast<Map<String, dynamic>>();
}
