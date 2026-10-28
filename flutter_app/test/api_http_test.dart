import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mirror_3d/services/api/api_http.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<SessionEndReason> events;
  late StreamSubscription<SessionEndReason> sub;

  setUp(() {
    // flutter_timezone's platform side, faked.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (call) async => call.method == 'getLocalTimezone' ? 'America/New_York' : null,
    );
    SharedPreferences.setMockInitialValues({'mirror_token': 'tok-A', 'mirror_user_id': 'u1'});
    events = [];
    sub = SessionEvents.stream.listen(events.add);
  });

  tearDown(() => sub.cancel());

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  ApiHttp clientReturning(int status, {void Function(http.Request)? onRequest}) =>
      ApiHttp.withInner(MockClient((req) async {
        onRequest?.call(req);
        return http.Response('{"detail":"Invalid or expired token"}', status);
      }));

  Future<String?> storedToken() async =>
      (await SharedPreferences.getInstance()).getString('mirror_token');

  test('non-401 responses pass through and carry X-Timezone', () async {
    http.Request? seen;
    final api = clientReturning(200, onRequest: (r) => seen = r);

    final r = await api.get(Uri.parse('http://x/sessions'),
        headers: {'Authorization': 'Bearer tok-A'});

    expect(r.statusCode, 200);
    expect(seen!.headers['X-Timezone'], 'America/New_York');
    expect(await storedToken(), 'tok-A');
    await flush();
    expect(events, isEmpty);
  });

  test('401 for the stored token clears the session, emits expired, throws', () async {
    final api = clientReturning(401);

    await expectLater(
      api.get(Uri.parse('http://x/sessions'), headers: {'Authorization': 'Bearer tok-A'}),
      throwsA(isA<UnauthorizedException>()),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('mirror_token'), isNull);
    expect(prefs.getString('mirror_user_id'), isNull);
    await flush();
    expect(events, [SessionEndReason.expired]);
  });

  test('parallel 401s (home loads several things) end the session once', () async {
    final api = clientReturning(401);
    final calls = List.generate(4, (i) => api
        .get(Uri.parse('http://x/$i'), headers: {'Authorization': 'Bearer tok-A'})
        .then<Object?>((r) => r, onError: (Object e) => e));

    final results = await Future.wait(calls);

    expect(results, everyElement(isA<UnauthorizedException>()));
    await flush();
    expect(events, [SessionEndReason.expired]);
  });

  test('a late 401 for an old token does not log out a newer session', () async {
    SharedPreferences.setMockInitialValues({'mirror_token': 'tok-NEW', 'mirror_user_id': 'u1'});
    final api = clientReturning(401);

    await expectLater(
      api.get(Uri.parse('http://x/sessions'), headers: {'Authorization': 'Bearer tok-OLD'}),
      throwsA(isA<UnauthorizedException>()),
    );

    expect(await storedToken(), 'tok-NEW');
    await flush();
    expect(events, isEmpty);
  });

  test('401 on a request without a token does not end the session', () async {
    final api = clientReturning(401);

    await expectLater(
      api.post(Uri.parse('http://x/auth/email/verify'), headers: {'Authorization': 'Bearer '}),
      throwsA(isA<UnauthorizedException>()),
    );

    expect(await storedToken(), 'tok-A');
    await flush();
    expect(events, isEmpty);
  });

  test('signOut clears the session and emits signedOut', () async {
    await SessionEvents.signOut();

    expect(await storedToken(), isNull);
    await flush();
    expect(events, [SessionEndReason.signedOut]);
  });
}
