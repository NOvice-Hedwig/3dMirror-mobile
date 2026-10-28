import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_3d/models/models.dart';
import 'package:mirror_3d/providers/home_provider.dart';
import 'package:mirror_3d/providers/session_provider.dart';
import 'package:mirror_3d/services/api/api_http.dart';

class _FailingSessions extends SessionsNotifier {
  @override
  Future<List<SessionRecord>> build() async => throw const UnauthorizedException();
}

void main() {
  // Regression test for the red error screen: when sessionsProvider fails (e.g. 401 after the
  // JWT secret rotation), the providers HomeScreen's widgets watch must not rethrow in build.
  test('home providers fall back to empty values when sessions fail to load', () async {
    final container = ProviderContainer(overrides: [
      sessionsProvider.overrideWith(_FailingSessions.new),
    ]);
    addTearDown(container.dispose);

    await expectLater(container.read(sessionsProvider.future), throwsA(isA<UnauthorizedException>()));
    expect(container.read(sessionsProvider).hasError, isTrue);

    expect(container.read(latestSessionProvider), isNull);
    expect(container.read(streakProvider), 0);
    expect(container.read(todayWorkoutMinProvider), 0);
    expect(container.read(weekWorkoutMinutesProvider), isEmpty);
  });
}
