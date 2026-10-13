import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/challenge_models.dart';
import '../services/api/challenge_api.dart';

final challengeProgressProvider =
    FutureProvider.autoDispose<ChallengeProgress?>((ref) =>
        ChallengeApi.instance.fetchProgress());
