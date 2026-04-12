import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api/session_api.dart';

// ── Sessions list ─────────────────────────────────────────────────────────────

final sessionsProvider =
    AsyncNotifierProvider<SessionsNotifier, List<SessionRecord>>(
  SessionsNotifier.new,
);

class SessionsNotifier extends AsyncNotifier<List<SessionRecord>> {
  @override
  Future<List<SessionRecord>> build() => SessionApi.instance.list();

  Future<SessionRecord> create(SessionRecord session) async {
    final saved = await SessionApi.instance.create(session);
    state = AsyncData([saved, ...state.value ?? []]);
    return saved;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => SessionApi.instance.list());
  }
}

// ── Single session ────────────────────────────────────────────────────────────

final sessionDetailProvider =
    FutureProvider.family<SessionRecord, String>((ref, id) {
  return SessionApi.instance.get(id);
});

// ── Current input draft (in-memory) ──────────────────────────────────────────

class InputDraft {
  final double  weight;
  final double? bodyFat;
  final double? waist;
  final String  gender;
  final WorkoutType workout;
  final int?    durationMin;
  final Intensity? intensity;

  const InputDraft({
    required this.weight,
    required this.gender,
    this.bodyFat,
    this.waist,
    this.workout = WorkoutType.rest,
    this.durationMin,
    this.intensity,
  });

  InputDraft copyWith({
    double?       weight,
    double?       bodyFat,
    double?       waist,
    String?       gender,
    WorkoutType?  workout,
    int?          durationMin,
    Intensity?    intensity,
  }) =>
      InputDraft(
        weight:      weight      ?? this.weight,
        bodyFat:     bodyFat     ?? this.bodyFat,
        waist:       waist       ?? this.waist,
        gender:      gender      ?? this.gender,
        workout:     workout     ?? this.workout,
        durationMin: durationMin ?? this.durationMin,
        intensity:   intensity   ?? this.intensity,
      );
}

final inputDraftProvider =
    NotifierProvider<InputDraftNotifier, InputDraft?>(InputDraftNotifier.new);

class InputDraftNotifier extends Notifier<InputDraft?> {
  @override
  InputDraft? build() => null;

  void update(InputDraft draft) => state = draft;
  void clear()                  => state = null;
}
