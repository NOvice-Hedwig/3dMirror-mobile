import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/challenge_models.dart';
import 'auth_api.dart';

class ChallengeApi {
  ChallengeApi._();
  static final ChallengeApi instance = ChallengeApi._();

  static const _base = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000');

  Future<Map<String, String>> _headers() async {
    final token  = await AuthApi.instance.getToken() ?? '';
    final userId = await AuthApi.instance.getUserId() ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-User-Id': userId,
    };
  }

  Future<void> setGoal(ChallengeGoal goal) async {
    final r = await http.post(
      Uri.parse('$_base/challenge/goal'),
      headers: await _headers(),
      body: json.encode(goal.toJson()),
    );
    _assert(r);
  }

  // Returns null when 404 (no goal set); throws on other errors.
  Future<ChallengeProgress?> fetchProgress() async {
    final r = await http.get(
      Uri.parse('$_base/challenge/progress'),
      headers: await _headers(),
    );
    if (r.statusCode == 404) return null;
    _assert(r);
    return ChallengeProgress.fromJson(
        json.decode(r.body) as Map<String, dynamic>);
  }

  Future<void> abandonGoal() async {
    final r = await http.delete(
      Uri.parse('$_base/challenge/goal'),
      headers: await _headers(),
    );
    _assert(r);
  }

  void _assert(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('API error ${r.statusCode}: ${r.body}');
    }
  }
}
