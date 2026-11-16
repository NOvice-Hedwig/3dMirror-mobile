// Display labels for the stored log values in models/log_values.dart. The stored value is
// what the backend keeps; only the label changes with the language. In Chinese the label
// is the stored value itself. Values not listed (custom names, old data) are shown as is.

import '../../models/log_values.dart';
import 'app_localizations.dart';

String mealLabel(S s, String value) => switch (value) {
  MealValue.breakfast => s.mealBreakfast,
  MealValue.lunch     => s.mealLunch,
  MealValue.dinner    => s.mealDinner,
  MealValue.snack     => s.mealSnack,
  _                   => value,
};

String workoutTypeLabel(S s, String value) => switch (value) {
  WorkoutLogType.cardio   => s.workoutTypeCardio,
  WorkoutLogType.strength => s.workoutTypeStrength,
  WorkoutLogType.pilates  => s.workoutTypePilates,
  WorkoutLogType.ball     => s.workoutTypeBall,
  WorkoutLogType.other    => s.workoutTypeOther,
  _                       => value,
};

String workoutSubTypeLabel(S s, String value) => switch (value) {
  WorkoutSubType.running         => s.subTypeRunning,
  WorkoutSubType.jumpRope        => s.subTypeJumpRope,
  WorkoutSubType.aerobics        => s.subTypeAerobics,
  WorkoutSubType.hiit            => s.subTypeHiit,
  WorkoutSubType.swimming        => s.subTypeSwimming,
  WorkoutSubType.hiking          => s.subTypeHiking,
  WorkoutSubType.cycling         => s.subTypeCycling,
  WorkoutSubType.other           => s.subTypeOther,
  WorkoutSubType.matPilates      => s.subTypeMatPilates,
  WorkoutSubType.reformerPilates => s.subTypeReformerPilates,
  WorkoutSubType.basketball      => s.subTypeBasketball,
  WorkoutSubType.badminton       => s.subTypeBadminton,
  WorkoutSubType.tennis          => s.subTypeTennis,
  WorkoutSubType.tableTennis     => s.subTypeTableTennis,
  WorkoutSubType.football        => s.subTypeFootball,
  _                              => value,
};

String muscleGroupLabel(S s, String value) => switch (value) {
  MuscleGroupValue.chest     => s.muscleChest,
  MuscleGroupValue.back      => s.muscleBack,
  MuscleGroupValue.legs      => s.muscleLegs,
  MuscleGroupValue.shoulders => s.muscleShoulders,
  MuscleGroupValue.arms      => s.muscleArms,
  MuscleGroupValue.core      => s.muscleCore,
  _                          => value,
};

String symptomLabel(S s, String value) => switch (value) {
  SymptomValue.cramps     => s.symptomCramps,
  SymptomValue.moodSwings => s.symptomMoodSwings,
  SymptomValue.swelling   => s.symptomSwelling,
  SymptomValue.acne       => s.symptomAcne,
  SymptomValue.fatigue    => s.symptomFatigue,
  SymptomValue.backPain   => s.symptomBackPain,
  _                       => value,
};

String supplementLabel(S s, String value) => switch (value) {
  SupplementValue.proteinPowder => s.supplementProteinPowder,
  SupplementValue.creatine      => s.supplementCreatine,
  SupplementValue.vitaminD      => s.supplementVitaminD,
  SupplementValue.collagen      => s.supplementCollagen,
  SupplementValue.fishOil       => s.supplementFishOil,
  SupplementValue.vitaminC      => s.supplementVitaminC,
  SupplementValue.iron          => s.supplementIron,
  SupplementValue.folicAcid     => s.supplementFolicAcid,
  SupplementValue.magnesium     => s.supplementMagnesium,
  SupplementValue.zinc          => s.supplementZinc,
  _                             => value,
};
