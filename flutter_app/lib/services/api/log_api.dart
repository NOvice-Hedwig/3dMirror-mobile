import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/log_models.dart';
import 'auth_api.dart';
import 'api_http.dart';

class LogApi {
  LogApi._();
  static final LogApi instance = LogApi._();

  static const _base = String.fromEnvironment(
    'API_BASE_URL', defaultValue: 'http://10.0.2.2:8000',
  );

  Future<Map<String, String>> _headers() async {
    final token  = await AuthApi.instance.getToken()  ?? '';
    final userId = await AuthApi.instance.getUserId() ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-User-Id': userId,
    };
  }

  void _assert(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('API error ${r.statusCode}: ${r.body}');
    }
  }

  Future<void> saveWorkout(WorkoutLogEntry entry) async {
    final r = await ApiHttp.instance.post(
      Uri.parse('$_base/logs/workout'),
      headers: await _headers(),
      body: json.encode(entry.toJson()),
    );
    _assert(r);
  }

  Future<void> saveDiet(DietLogEntry entry) async {
    final r = await ApiHttp.instance.post(
      Uri.parse('$_base/logs/diet'),
      headers: await _headers(),
      body: json.encode(entry.toJson()),
    );
    _assert(r);
  }

  Future<void> saveSleep(SleepLogEntry entry) async {
    final r = await ApiHttp.instance.post(
      Uri.parse('$_base/logs/sleep'),
      headers: await _headers(),
      body: json.encode(entry.toJson()),
    );
    _assert(r);
  }

  Future<void> savePeriod(PeriodLogEntry entry) async {
    final r = await ApiHttp.instance.post(
      Uri.parse('$_base/logs/period'),
      headers: await _headers(),
      body: json.encode(entry.toJson()),
    );
    _assert(r);
  }

  Future<void> saveSupplements(List<SupplementLogEntry> items) async {
    final r = await ApiHttp.instance.post(
      Uri.parse('$_base/logs/supplements'),
      headers: await _headers(),
      body: json.encode(items.map((e) => e.toJson()).toList()),
    );
    _assert(r);
  }

  Future<void> updateMeasurements(BodyMeasurementUpdate m) async {
    final r = await ApiHttp.instance.put(
      Uri.parse('$_base/logs/measurements'),
      headers: await _headers(),
      body: json.encode(m.toJson()),
    );
    _assert(r);
  }

  Future<TodayStats> fetchTodayStats() async {
    final r = await ApiHttp.instance.get(
      Uri.parse('$_base/logs/today-stats'),
      headers: await _headers(),
    );
    _assert(r);
    return TodayStats.fromJson(json.decode(r.body) as Map<String, dynamic>);
  }
}
