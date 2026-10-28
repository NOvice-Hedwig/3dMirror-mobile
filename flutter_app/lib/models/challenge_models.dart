class ChallengeGoal {
  final String  goalType;       // 'weight' | 'body_fat' | 'waist' | 'composite'
  final double? targetWeightKg;
  final double? targetBodyFat;
  final double? targetWaistCm;
  final String  startDate;      // ISO date YYYY-MM-DD
  final String  endDate;

  const ChallengeGoal({
    required this.goalType,
    this.targetWeightKg,
    this.targetBodyFat,
    this.targetWaistCm,
    required this.startDate,
    required this.endDate,
  });

  factory ChallengeGoal.fromJson(Map<String, dynamic> j) => ChallengeGoal(
    goalType:       j['goal_type']        as String,
    targetWeightKg: (j['target_weight_kg'] as num?)?.toDouble(),
    targetBodyFat:  (j['target_body_fat']  as num?)?.toDouble(),
    targetWaistCm:  (j['target_waist_cm']  as num?)?.toDouble(),
    startDate:      j['start_date']        as String,
    endDate:        j['end_date']          as String,
  );

  Map<String, dynamic> toJson() => {
    'goal_type':        goalType,
    'target_weight_kg': targetWeightKg,
    'target_body_fat':  targetBodyFat,
    'target_waist_cm':  targetWaistCm,
    'start_date':       startDate,
    'end_date':         endDate,
  };

  static String defaultEndDate(String startDate) {
    final d = DateTime.parse(startDate);
    // Calendar arithmetic, not Duration: adding 30×24h to local midnight lands on
    // 23:00 of the previous day when the range crosses the November DST change.
    final end = DateTime(d.year, d.month, d.day + 30);
    return end.toIso8601String().substring(0, 10);
  }
}

class ChallengeProgress {
  final ChallengeGoal goal;
  final double?       currentWeight;
  final double?       currentBodyFat;
  final double?       currentWaist;
  final double        progressPct;    // 0.0 – 100.0
  final int           daysRemaining;
  final bool          isCompleted;
  final bool          discountEligible;

  const ChallengeProgress({
    required this.goal,
    this.currentWeight,
    this.currentBodyFat,
    this.currentWaist,
    required this.progressPct,
    required this.daysRemaining,
    required this.isCompleted,
    required this.discountEligible,
  });

  factory ChallengeProgress.fromJson(Map<String, dynamic> j) =>
      ChallengeProgress(
        goal:             ChallengeGoal.fromJson(j['goal'] as Map<String, dynamic>),
        currentWeight:    (j['current_weight']   as num?)?.toDouble(),
        currentBodyFat:   (j['current_body_fat'] as num?)?.toDouble(),
        currentWaist:     (j['current_waist']    as num?)?.toDouble(),
        progressPct:      (j['progress_pct']     as num).toDouble(),
        daysRemaining:    j['days_remaining']    as int,
        isCompleted:      j['is_completed']      as bool,
        discountEligible: j['discount_eligible'] as bool,
      );
}
