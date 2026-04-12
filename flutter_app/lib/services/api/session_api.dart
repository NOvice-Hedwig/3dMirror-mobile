import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/models.dart';
import 'auth_api.dart';

class SessionApi {
  SessionApi._();
  static final SessionApi instance = SessionApi._();

  static const _base = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://localhost:8000');

  Future<Map<String, String>> _headers() async {
    final token  = await AuthApi.instance.getToken() ?? '';
    final userId = await AuthApi.instance.getUserId() ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-User-Id': userId,
    };
  }

  Future<SessionRecord> create(SessionRecord s) async {
    final r = await http.post(
      Uri.parse('$_base/sessions'),
      headers: await _headers(),
      body: json.encode(s.toJson()),
    );
    _assert(r);
    return SessionRecord.fromJson(json.decode(r.body) as Map<String, dynamic>);
  }

  Future<List<SessionRecord>> list({int limit = 30}) async {
    final r = await http.get(
      Uri.parse('$_base/sessions?limit=$limit'),
      headers: await _headers(),
    );
    _assert(r);
    return (json.decode(r.body) as List)
        .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SessionRecord> get(String id) async {
    final r = await http.get(
      Uri.parse('$_base/sessions/$id'),
      headers: await _headers(),
    );
    _assert(r);
    return SessionRecord.fromJson(json.decode(r.body) as Map<String, dynamic>);
  }

  void _assert(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('API error ${r.statusCode}: ${r.body}');
    }
  }
}
