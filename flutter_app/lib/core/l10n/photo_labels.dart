// Display text for photo angles and body-analysis outcomes. Kept out of the models
// (models/body_photo.dart) so they stay data-only and the text follows the app language.

import '../../models/body_photo.dart';
import 'app_localizations.dart';

String photoAngleLabel(S s, PhotoAngle angle) => switch (angle) {
  PhotoAngle.front => s.photoAngleFront,
  PhotoAngle.side  => s.photoAngleSide,
  PhotoAngle.back  => s.photoAngleBack,
};

String photoAngleHint(S s, PhotoAngle angle) => switch (angle) {
  PhotoAngle.front => s.photoHintFront,
  PhotoAngle.side  => s.photoHintSide,
  PhotoAngle.back  => s.photoHintBack,
};

/// Short user-facing status of a stored analysis (was BodyAnalysis.statusLabel).
String bodyAnalysisStatusLabel(S s, AnalysisStatus status) => switch (status) {
  AnalysisStatus.ok          => s.analysisStatusOk,
  AnalysisStatus.unavailable => s.analysisStatusUnavailable,
  AnalysisStatus.failed      => s.analysisStatusFailed,
};
