import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/body_photo.dart';
import '../services/api/photo_api.dart';

/// The user's most recent body-photo analysis (any status), or null if none yet.
///
/// Loaded from GET /photos/analysis/latest and replaced when a new analysis finishes.
/// Read `.valueOrNull?.values` for the proportions; for the avatar, use
/// `values.toAvatarOverrides()` (see ONBOARDING.md, "Photo analysis data contract").
/// Kept alive (not autoDispose) so a result that arrives after the capture screen closes
/// is not lost. Reset on sign-out by the app root (main.dart).
final latestBodyAnalysisProvider =
    AsyncNotifierProvider<LatestBodyAnalysisNotifier, BodyAnalysis?>(
  LatestBodyAnalysisNotifier.new,
);

class LatestBodyAnalysisNotifier extends AsyncNotifier<BodyAnalysis?> {
  @override
  Future<BodyAnalysis?> build() => PhotoApi.instance.fetchLatestAnalysis();

  /// Analyze freshly uploaded photos. Runs in the background; the screen that started it
  /// doesn't need to stay open. On a transport error the previous value is kept.
  Future<void> analyze(List<String> photoIds) async {
    if (photoIds.isEmpty) return;
    try {
      final result = await PhotoApi.instance.analyzePhotos(photoIds);
      state = AsyncData(result);
    } catch (_) {
      // Network/HTTP failure (401 is handled globally by ApiHttp): keep the last known value.
    }
  }
}
