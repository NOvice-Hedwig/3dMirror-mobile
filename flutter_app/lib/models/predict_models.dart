const kPredictId4  = '__predict_4w__';
const kPredictId8  = '__predict_8w__';
const kPredictId12 = '__predict_12w__';

class PredictedMetrics {
  final int    weeks;
  final double predictedWeightKg;
  final double weightDeltaKg;
  final double predictedBodyFatPct;
  final double bodyFatDeltaPct;
  final double predictedWaistCm;
  final double waistDeltaCm;
  final double confidence;
  final int    dataPoints;

  const PredictedMetrics({
    required this.weeks,
    required this.predictedWeightKg,
    required this.weightDeltaKg,
    required this.predictedBodyFatPct,
    required this.bodyFatDeltaPct,
    required this.predictedWaistCm,
    required this.waistDeltaCm,
    required this.confidence,
    required this.dataPoints,
  });

  factory PredictedMetrics.fromJson(Map<String, dynamic> j) => PredictedMetrics(
    weeks:               j['weeks']                  as int,
    predictedWeightKg:   (j['predicted_weight_kg']   as num).toDouble(),
    weightDeltaKg:       (j['weight_delta_kg']       as num).toDouble(),
    predictedBodyFatPct: (j['predicted_body_fat_pct'] as num).toDouble(),
    bodyFatDeltaPct:     (j['body_fat_delta_pct']    as num).toDouble(),
    predictedWaistCm:    (j['predicted_waist_cm']    as num).toDouble(),
    waistDeltaCm:        (j['waist_delta_cm']        as num).toDouble(),
    confidence:          (j['confidence']             as num).toDouble(),
    dataPoints:          j['data_points']             as int,
  );
}

class InsufficientDataException implements Exception {
  final String message;
  const InsufficientDataException(this.message);
}
