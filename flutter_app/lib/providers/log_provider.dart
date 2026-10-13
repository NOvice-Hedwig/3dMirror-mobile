import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log_models.dart';
import '../services/api/log_api.dart';

final todayStatsProvider = FutureProvider<TodayStats>((ref) {
  return LogApi.instance.fetchTodayStats();
});
