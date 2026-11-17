// Text for the backend's coach cards (backend/routers/coach.py). Each card has a stable
// `code` and numeric `params`; the Chinese ARB text is exactly the server's `title`/`body`.
// A card whose code this build doesn't know, or that lacks a param, shows the server text.

import '../../models/coach_models.dart';
import 'app_localizations.dart';

abstract final class CoachCode {
  static const trainingNotStarted    = 'training_not_started';
  static const trainingFewDays       = 'training_few_days';
  static const trainingOnTrack       = 'training_on_track';
  static const weightStable          = 'weight_stable';
  static const weightUp              = 'weight_up';
  static const weightDown            = 'weight_down';
  static const dietStartLogging      = 'diet_start_logging';
  static const recoveryAfterStrength = 'recovery_after_strength';
  static const recoverySleep         = 'recovery_sleep';

  static const all = [
    trainingNotStarted, trainingFewDays, trainingOnTrack, weightStable, weightUp,
    weightDown, dietStartLogging, recoveryAfterStrength, recoverySleep,
  ];
}

/// (title, body) for [card] in the app language.
(String, String) coachCardText(S s, SuggestionCard card) {
  final days  = card.params['days']?.toInt();
  final delta = card.params['delta_kg']?.toStringAsFixed(1);
  final text = switch (card.code) {
    CoachCode.trainingNotStarted =>
      (s.coachTrainingNotStartedTitle, s.coachTrainingNotStartedBody),
    CoachCode.trainingFewDays when days != null =>
      (s.coachTrainingFewDaysTitle(days), s.coachTrainingFewDaysBody),
    CoachCode.trainingOnTrack when days != null =>
      (s.coachTrainingOnTrackTitle(days), s.coachTrainingOnTrackBody),
    CoachCode.weightStable =>
      (s.coachWeightStableTitle, s.coachWeightStableBody),
    CoachCode.weightUp when delta != null =>
      (s.coachWeightUpTitle(delta), s.coachWeightUpBody),
    CoachCode.weightDown when delta != null =>
      (s.coachWeightDownTitle(delta), s.coachWeightDownBody),
    CoachCode.dietStartLogging =>
      (s.coachDietStartLoggingTitle, s.coachDietStartLoggingBody),
    CoachCode.recoveryAfterStrength =>
      (s.coachRecoveryAfterStrengthTitle, s.coachRecoveryAfterStrengthBody),
    CoachCode.recoverySleep =>
      (s.coachRecoverySleepTitle, s.coachRecoverySleepBody),
    _ => null,
  };
  return text ?? (card.title, card.body);
}

String coachCategoryLabel(S s, String category) => switch (category) {
  'training'  => s.coachCategoryTraining,
  'nutrition' => s.coachCategoryNutrition,
  'recovery'  => s.coachCategoryRecovery,
  _           => category.toUpperCase(),
};
