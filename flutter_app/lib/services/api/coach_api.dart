import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/coach_models.dart';
import '../../models/models.dart';
import 'auth_api.dart';

class CoachApi {
  CoachApi._();
  static final CoachApi instance = CoachApi._();

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

  Future<CoachSuggestionsResponse> fetchSuggestions() async {
    final r = await http.get(
      Uri.parse('$_base/coach/suggestions'),
      headers: await _headers(),
    );
    _assert(r);
    return CoachSuggestionsResponse.fromJson(
        json.decode(r.body) as Map<String, dynamic>);
  }

  Future<void> saveTarget(AvatarParams target) async {
    final r = await http.put(
      Uri.parse('$_base/coach/target'),
      headers: await _headers(),
      body: json.encode(target.toJson()),
    );
    _assert(r);
  }

  void _assert(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('API error ${r.statusCode}: ${r.body}');
    }
  }
}
