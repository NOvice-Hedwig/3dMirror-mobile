import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/predict_models.dart';
import '../services/api/predict_api.dart';

final predictMetricsProvider = FutureProvider.autoDispose
    .family<PredictedMetrics, int>((ref, weeks) async {
  return PredictApi.instance.fetchPredict(weeks);
});
