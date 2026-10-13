import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coach_models.dart';
import '../models/models.dart';
import '../services/api/coach_api.dart';

final coachSuggestionsProvider =
    FutureProvider.autoDispose<CoachSuggestionsResponse>((ref) =>
        CoachApi.instance.fetchSuggestions());

final targetParamsNotifierProvider =
    StateNotifierProvider<TargetParamsNotifier, AvatarParams?>(
        (ref) => TargetParamsNotifier());

class TargetParamsNotifier extends StateNotifier<AvatarParams?> {
  TargetParamsNotifier() : super(null);

  Future<void> save(AvatarParams params) async {
    await CoachApi.instance.saveTarget(params);
    state = params;
  }
}
