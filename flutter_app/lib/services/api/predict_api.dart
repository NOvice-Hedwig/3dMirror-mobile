import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/predict_models.dart';
import 'auth_api.dart';

class PredictApi {
  PredictApi._();
  static final PredictApi instance = PredictApi._();

  static const _base = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  Future<Map<String, String>> _headers() async {
    final token  = await AuthApi.instance.getToken() ?? '';
    final userId = await AuthApi.instance.getUserId() ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-User-Id': userId,
    };
  }

  Future<PredictedMetrics> fetchPredict(int weeks) async {
    final r = await http.get(
      Uri.parse('$_base/predict?weeks=$weeks'),
      headers: await _headers(),
    );
    if (r.statusCode == 400) {
      final body = json.decode(r.body) as Map<String, dynamic>;
      throw InsufficientDataException(
          (body['detail'] as String?) ?? '数据不足');
    }
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('API error ${r.statusCode}: ${r.body}');
    }
    return PredictedMetrics.fromJson(
        json.decode(r.body) as Map<String, dynamic>);
  }
}
