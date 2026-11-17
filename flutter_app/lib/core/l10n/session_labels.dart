// Display text for body-session data (models/models.dart). The enums are stored by name,
// so only the label follows the app language.

import '../../models/models.dart';
import 'app_localizations.dart';

String workoutKindLabel(S s, WorkoutType t) => switch (t) {
  WorkoutType.strength => s.workoutStrength,
  WorkoutType.cardio   => s.workoutCardio,
  WorkoutType.hiit     => s.workoutHiit,
  WorkoutType.walk     => s.workoutWalk,
  WorkoutType.yoga     => s.workoutYoga,
  WorkoutType.swim     => s.workoutSwim,
  WorkoutType.cycling  => s.workoutCycling,
  WorkoutType.rest     => s.workoutRest,
  WorkoutType.other    => s.workoutOther,
};

String intensityLabel(S s, Intensity i) => switch (i) {
  Intensity.low    => s.intensityLow,
  Intensity.medium => s.intensityMed,
  Intensity.high   => s.intensityHigh,
};

/// yyyy.MM.dd — the same in every language.
String dotDate(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
