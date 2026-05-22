// ─── BodyData ─────────────────────────────────────────────────────────────────
class BodyData {
  final String    id;
  final String    userId;
  final DateTime  date;
  final double    weightKg;
  final double?   bodyFatPct;
  final double?   waistCm;
  final double?   hipCm;
  final double?   leanMassKg;
  final double?   fatMassKg;

  const BodyData({
    required this.id, required this.userId, required this.date,
    required this.weightKg, this.bodyFatPct, this.waistCm,
    this.hipCm, this.leanMassKg, this.fatMassKg,
  });

  double? get derivedLeanMass => bodyFatPct != null
      ? weightKg * (1 - bodyFatPct! / 100) : leanMassKg;
  double? get derivedFatMass => bodyFatPct != null
      ? weightKg * (bodyFatPct! / 100) : fatMassKg;

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'date': date.toIso8601String(),
    'weight_kg': weightKg, 'body_fat_pct': bodyFatPct,
    'waist_cm': waistCm, 'hip_cm': hipCm,
    'lean_mass_kg': derivedLeanMass, 'fat_mass_kg': derivedFatMass,
  };

  factory BodyData.fromJson(Map<String, dynamic> j) => BodyData(
    id: (j['id'] as String?) ?? '',
    userId: (j['user_id'] as String?) ?? '',
    date: j['date'] != null ? DateTime.parse(j['date'] as String) : DateTime.now(),
    weightKg: (j['weight_kg'] as num).toDouble(),
    bodyFatPct: (j['body_fat_pct'] as num?)?.toDouble(),
    waistCm: (j['waist_cm'] as num?)?.toDouble(),
    hipCm: (j['hip_cm'] as num?)?.toDouble(),
    leanMassKg: (j['lean_mass_kg'] as num?)?.toDouble(),
    fatMassKg: (j['fat_mass_kg'] as num?)?.toDouble(),
  );
}

// ─── ActivityData ─────────────────────────────────────────────────────────────
enum WorkoutType { strength, cardio, hiit, yoga, walk, swim, cycling, rest, other }
enum Intensity   { low, medium, high }

class ActivityData {
  final String       id, userId;
  final DateTime     date;
  final WorkoutType  workoutType;
  final int?         durationMin;
  final Intensity?   intensity;
  final int?         steps;

  const ActivityData({
    required this.id, required this.userId, required this.date,
    required this.workoutType, this.durationMin, this.intensity, this.steps,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'date': date.toIso8601String(),
    'workout_type': workoutType.name, 'duration_min': durationMin,
    'intensity': intensity?.name, 'steps': steps,
  };

  factory ActivityData.fromJson(Map<String, dynamic> j) => ActivityData(
    id: (j['id'] as String?) ?? '',
    userId: (j['user_id'] as String?) ?? '',
    date: j['date'] != null ? DateTime.parse(j['date'] as String) : DateTime.now(),
    workoutType: WorkoutType.values.firstWhere(
      (e) => e.name == j['workout_type'], orElse: () => WorkoutType.other),
    durationMin: j['duration_min'] as int?,
    intensity: j['intensity'] != null
        ? Intensity.values.firstWhere((e) => e.name == j['intensity'])
        : null,
    steps: j['steps'] as int?,
  );
}

// ─── AvatarParams ─────────────────────────────────────────────────────────────
class AvatarParams {
  final double heightNorm, weightNorm, bodyFatNorm;
  final double waistNorm, hipNorm, shoulderNorm, muscleNorm;
  final String gender;
  final String lightingProfile;

  const AvatarParams({
    required this.heightNorm, required this.weightNorm,
    required this.bodyFatNorm, required this.waistNorm,
    required this.hipNorm, required this.shoulderNorm,
    required this.muscleNorm, required this.gender,
    this.lightingProfile = 'studio_minimal',
  });

  factory AvatarParams.fromBodyData(BodyData d,
      {required double heightCm, required String gender}) {
    double clamp(double v) => v.clamp(0.0, 1.0);
    final bmi = d.weightKg / ((heightCm / 100) * (heightCm / 100));
    final bf  = d.bodyFatPct ?? _estimateBf(bmi, gender);
    final lean = d.weightKg * (1 - bf / 100);
    final fatMin = gender == 'male' ? 5.0 : 15.0;
    final fatMax = gender == 'male' ? 40.0 : 50.0;
    final fatN   = clamp((bf - fatMin) / (fatMax - fatMin));
    return AvatarParams(
      heightNorm:   clamp((heightCm - 150) / 50),
      weightNorm:   clamp((bmi - 17) / 23),
      bodyFatNorm:  fatN,
      waistNorm:    clamp(fatN * 0.9),
      hipNorm:      gender == 'male'
          ? clamp(fatN * 0.6) : clamp(fatN * 0.7 + 0.3),
      shoulderNorm: gender == 'male'
          ? clamp(clamp((lean - 40) / 40) * 0.6 + 0.4)
          : clamp(clamp((lean - 30) / 30) * 0.3 + 0.3),
      muscleNorm:   clamp((lean - 30) / 50),
      gender:       gender,
    );
  }

  static double _estimateBf(double bmi, String gender) => gender == 'male'
      ? (1.20 * bmi + 0.23 * 30 - 16.2).clamp(5, 45)
      : (1.20 * bmi + 0.23 * 30 - 5.4).clamp(15, 55);

  Map<String, dynamic> toJson() => {
    'height_norm': heightNorm, 'weight_norm': weightNorm,
    'body_fat_norm': bodyFatNorm, 'waist_norm': waistNorm,
    'hip_norm': hipNorm, 'shoulder_norm': shoulderNorm,
    'muscle_norm': muscleNorm, 'gender': gender,
    'lighting_profile': lightingProfile,
  };

  factory AvatarParams.fromJson(Map<String, dynamic> j) => AvatarParams(
    heightNorm:   (j['height_norm']   as num).toDouble(),
    weightNorm:   (j['weight_norm']   as num).toDouble(),
    bodyFatNorm:  (j['body_fat_norm'] as num).toDouble(),
    waistNorm:    (j['waist_norm']    as num).toDouble(),
    hipNorm:      (j['hip_norm']      as num).toDouble(),
    shoulderNorm: (j['shoulder_norm'] as num).toDouble(),
    muscleNorm:   (j['muscle_norm']   as num).toDouble(),
    gender:       j['gender']         as String,
    lightingProfile: j['lighting_profile'] as String? ?? 'studio_minimal',
  );
}

// ─── SessionRecord ────────────────────────────────────────────────────────────
class SessionRecord {
  final String        id, userId;
  final DateTime      createdAt;
  final BodyData      bodyData;
  final AvatarParams  avatarParams;
  final ActivityData? activityData;
  final String?       thumbnailUrl;

  const SessionRecord({
    required this.id, required this.userId, required this.createdAt,
    required this.bodyData, required this.avatarParams,
    this.activityData, this.thumbnailUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId,
    'created_at': createdAt.toIso8601String(),
    'body_data': bodyData.toJson(),
    'avatar_params': avatarParams.toJson(),
    'activity_data': activityData?.toJson(),
    'thumbnail_url': thumbnailUrl,
  };

  factory SessionRecord.fromJson(Map<String, dynamic> j) => SessionRecord(
    id:           j['id']       as String,
    userId:       j['user_id']  as String,
    createdAt:    DateTime.parse(j['created_at'] as String),
    bodyData:     BodyData.fromJson(j['body_data']         as Map<String, dynamic>),
    avatarParams: AvatarParams.fromJson(j['avatar_params'] as Map<String, dynamic>),
    activityData: j['activity_data'] != null
        ? ActivityData.fromJson(j['activity_data'] as Map<String, dynamic>)
        : null,
    thumbnailUrl: j['thumbnail_url'] as String?,
  );
}
