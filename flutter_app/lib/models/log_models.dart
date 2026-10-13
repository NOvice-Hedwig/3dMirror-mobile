// ─── DietLogEntry ─────────────────────────────────────────────────────────────
class DietLogEntry {
  final String   id;
  final String   userId;
  final DateTime loggedAt;
  final String   meal;        // '早餐'|'午餐'|'晚餐'|'加餐'
  final String   foodName;
  final double?  grams;
  final double   calories;
  final double?  proteinG;
  final double?  carbsG;
  final double?  fatG;
  final String   entryMethod; // 'manual'|'search'|'photo'

  const DietLogEntry({
    required this.id, required this.userId, required this.loggedAt,
    required this.meal, required this.foodName, required this.calories,
    this.grams, this.proteinG, this.carbsG, this.fatG,
    this.entryMethod = 'manual',
  });

  factory DietLogEntry.fromJson(Map<String, dynamic> j) => DietLogEntry(
    id:          j['id']          as String,
    userId:      j['user_id']     as String,
    loggedAt:    DateTime.parse(j['logged_at'] as String),
    meal:        j['meal']        as String,
    foodName:    j['food_name']   as String,
    calories:    (j['calories']   as num).toDouble(),
    grams:       (j['grams']      as num?)?.toDouble(),
    proteinG:    (j['protein_g']  as num?)?.toDouble(),
    carbsG:      (j['carbs_g']    as num?)?.toDouble(),
    fatG:        (j['fat_g']      as num?)?.toDouble(),
    entryMethod: j['entry_method'] as String? ?? 'manual',
  );

  Map<String, dynamic> toJson() => {
    'meal': meal,
    'food_name': foodName,
    'calories': calories,
    if (grams != null)    'grams': grams,
    if (proteinG != null) 'protein_g': proteinG,
    if (carbsG != null)   'carbs_g': carbsG,
    if (fatG != null)     'fat_g': fatG,
    'entry_method': entryMethod,
  };
}

// ─── SleepLogEntry ────────────────────────────────────────────────────────────
class SleepLogEntry {
  final String   id;
  final String   userId;
  final String   date;      // 'YYYY-MM-DD'
  final DateTime bedtime;
  final DateTime wakeTime;
  final int      quality;   // 1–5
  final String   source;    // 'manual'

  double get durationHours =>
      wakeTime.difference(bedtime).inMinutes / 60.0;

  const SleepLogEntry({
    required this.id, required this.userId, required this.date,
    required this.bedtime, required this.wakeTime, required this.quality,
    this.source = 'manual',
  });

  factory SleepLogEntry.fromJson(Map<String, dynamic> j) => SleepLogEntry(
    id:       j['id']       as String,
    userId:   j['user_id']  as String,
    date:     j['date']     as String,
    bedtime:  DateTime.parse(j['bedtime']   as String),
    wakeTime: DateTime.parse(j['wake_time'] as String),
    quality:  j['quality']  as int,
    source:   j['source']   as String? ?? 'manual',
  );

  Map<String, dynamic> toJson() => {
    'date': date,
    'bedtime':   bedtime.toIso8601String(),
    'wake_time': wakeTime.toIso8601String(),
    'quality': quality,
    'source':  source,
  };
}

// ─── WorkoutLogEntry ──────────────────────────────────────────────────────────
// Stored as activity_data JSON in the existing sessions table (no new table).
class WorkoutLogEntry {
  final String           type;       // '有氧'|'无氧'|'普拉提'|'球类'|'其他'
  final String           subType;
  final int              durationMin;
  final String           intensity;  // 'low'|'medium'|'high'
  final bool             withWeight;
  final double?          weightKg;
  final String?          muscleGroup;
  final List<StrengthSet>? sets;
  final int?             estimatedKcal;

  const WorkoutLogEntry({
    required this.type, required this.subType,
    required this.durationMin, required this.intensity,
    this.withWeight = false, this.weightKg,
    this.muscleGroup, this.sets, this.estimatedKcal,
  });

  static int estimateCalories({
    required String subType,
    required int durationMin,
    required String intensity,
  }) {
    final base = subType == '跑步' ? 10.0
        : subType == '跳绳' ? 12.0
        : subType == 'HIIT' ? 11.0
        : 8.0;
    final factor = intensity == 'low' ? 0.75
        : intensity == 'high' ? 1.3 : 1.0;
    return (durationMin * base * factor).round();
  }

  Map<String, dynamic> toJson() => {
    'type': type, 'sub_type': subType,
    'duration_min': durationMin, 'intensity': intensity,
    'with_weight': withWeight,
    if (muscleGroup != null)   'muscle_group': muscleGroup,
    if (weightKg != null)      'weight_kg': weightKg,
    if (sets != null)          'sets': sets!.map((s) => s.toJson()).toList(),
    if (estimatedKcal != null) 'estimated_kcal': estimatedKcal,
  };

  factory WorkoutLogEntry.fromJson(Map<String, dynamic> j) => WorkoutLogEntry(
    type:         j['type']         as String,
    subType:      j['sub_type']     as String,
    durationMin:  j['duration_min'] as int,
    intensity:    j['intensity']    as String,
    withWeight:   j['with_weight']  as bool? ?? false,
    weightKg:     (j['weight_kg']   as num?)?.toDouble(),
    muscleGroup:  j['muscle_group'] as String?,
    estimatedKcal: j['estimated_kcal'] as int?,
    sets: (j['sets'] as List<dynamic>?)
        ?.map((e) => StrengthSet.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class StrengthSet {
  final int    reps;
  final double weightKg;
  final bool   isDropSet;

  const StrengthSet({
    required this.reps, required this.weightKg, this.isDropSet = false,
  });

  StrengthSet copyWith({int? reps, double? weightKg, bool? isDropSet}) =>
      StrengthSet(
        reps:      reps      ?? this.reps,
        weightKg:  weightKg  ?? this.weightKg,
        isDropSet: isDropSet ?? this.isDropSet,
      );

  Map<String, dynamic> toJson() => {
    'reps': reps, 'weight_kg': weightKg, 'is_drop_set': isDropSet,
  };

  factory StrengthSet.fromJson(Map<String, dynamic> j) => StrengthSet(
    reps:      j['reps']       as int,
    weightKg:  (j['weight_kg'] as num).toDouble(),
    isDropSet: j['is_drop_set'] as bool? ?? false,
  );
}

// ─── PeriodLogEntry ───────────────────────────────────────────────────────────
class PeriodLogEntry {
  final String       phase;     // 'start'|'end'|'ongoing'
  final List<String> symptoms;  // ['痛经','情绪波动','水肿','长痘','疲劳']
  final int          intensity; // 1–3

  const PeriodLogEntry({
    required this.phase, required this.symptoms, required this.intensity,
  });

  Map<String, dynamic> toJson() => {
    'phase': phase, 'symptoms': symptoms, 'intensity': intensity,
  };
}

// ─── SupplementLogEntry ───────────────────────────────────────────────────────
class SupplementLogEntry {
  final String  name;
  final String? dosage;
  final String? reminderTime;   // 'HH:MM'
  final bool    reminderEnabled;

  const SupplementLogEntry({
    required this.name, this.dosage,
    this.reminderTime, this.reminderEnabled = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (dosage != null)       'dosage': dosage,
    if (reminderTime != null) 'reminder_time': reminderTime,
    'reminder_enabled': reminderEnabled,
  };
}

// ─── BodySnapshot ─────────────────────────────────────────────────────────────
class BodySnapshot {
  final double? weightKg;
  final double? waistCm;
  final double? hipCm;
  final double? chestCm;

  const BodySnapshot({this.weightKg, this.waistCm, this.hipCm, this.chestCm});

  Map<String, dynamic> toJson() => {
    if (weightKg != null) 'weight_kg': weightKg,
    if (waistCm  != null) 'waist_cm':  waistCm,
    if (hipCm    != null) 'hip_cm':    hipCm,
    if (chestCm  != null) 'chest_cm':  chestCm,
  };
}

// ─── BodyMeasurementUpdate ────────────────────────────────────────────────────
class BodyMeasurementUpdate {
  final double? weightKg;
  final double? waistCm;
  final double? hipCm;
  final double? chestCm;
  final double? thighCm;

  const BodyMeasurementUpdate({
    this.weightKg, this.waistCm, this.hipCm, this.chestCm, this.thighCm,
  });

  bool get hasAnyValue =>
      weightKg != null || waistCm != null || hipCm != null ||
      chestCm != null || thighCm != null;

  Map<String, dynamic> toJson() => {
    if (weightKg != null) 'weight_kg': weightKg,
    if (waistCm  != null) 'waist_cm':  waistCm,
    if (hipCm    != null) 'hip_cm':    hipCm,
    if (chestCm  != null) 'chest_cm':  chestCm,
    if (thighCm  != null) 'thigh_cm':  thighCm,
  };
}

// ─── TodayStats ───────────────────────────────────────────────────────────────
class TodayStats {
  final double totalKcalIn;
  final double sleepHours;
  final int    workoutMinutes;

  const TodayStats({
    required this.totalKcalIn,
    required this.sleepHours,
    this.workoutMinutes = 0,
  });

  factory TodayStats.fromJson(Map<String, dynamic> j) => TodayStats(
    totalKcalIn:    (j['total_kcal_in']   as num).toDouble(),
    sleepHours:     (j['sleep_hours']     as num).toDouble(),
    workoutMinutes: (j['workout_minutes'] as num?)?.toInt() ?? 0,
  );

  static const zero = TodayStats(totalKcalIn: 0, sleepHours: 0);
}
