import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/body_photo.dart';
import 'api_http.dart';

/// A failed photo request. Not shown to users (screens show their own translated text),
/// so the message is a technical English description.
class PhotoException implements Exception {
  final String message;
  final int? status;
  const PhotoException(this.message, [this.status]);
  @override String toString() =>
      status == null ? 'PhotoException: $message' : 'PhotoException($status): $message';
}

class PhotoApi {
  PhotoApi._();
  static final PhotoApi instance = PhotoApi._();

  static const _base = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000');

  // ── Upload ─────────────────────────────────────────────────────────────────

  Future<List<String>> uploadPhotos(Map<PhotoAngle, File> photos) async {
    final token = await _token();
    final request = http.MultipartRequest('POST', Uri.parse('$_base/photos/upload'))
      ..headers['Authorization'] = 'Bearer $token';

    for (final entry in photos.entries) {
      final angle = entry.key.apiValue;
      final file  = entry.value;
      request.files.add(await http.MultipartFile.fromPath(
        angle, file.path,
        filename: '$angle.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    final streamed = await ApiHttp.instance.send(request);
    final body     = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200 && streamed.statusCode != 201) {
      throw PhotoException('upload failed', streamed.statusCode);
    }

    final decoded = json.decode(body) as Map<String, dynamic>;
    return (decoded['photo_ids'] as List<dynamic>)
        .map((e) => e as String)
        .toList();
  }

  // ── Analyze ────────────────────────────────────────────────────────────────

  /// Runs the analysis and returns the stored record. A failed or unavailable analysis is
  /// still a record (HTTP 200, check [BodyAnalysis.status]); throws only on transport errors.
  Future<BodyAnalysis> analyzePhotos(List<String> photoIds) async {
    final token = await _token();
    // Form-encoded, repeated field: matches FastAPI's `photo_ids: list[str] = Form(...)`.
    final formBody = photoIds.map((id) => 'photo_ids=${Uri.encodeComponent(id)}').join('&');
    final r = await ApiHttp.instance.post(
      Uri.parse('$_base/photos/analyze'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: formBody,
    );
    if (r.statusCode != 200) throw PhotoException('analysis request failed', r.statusCode);
    return BodyAnalysis.fromJson(json.decode(r.body) as Map<String, dynamic>);
  }

  /// The user's most recent analysis, or null if there is none.
  /// [okOnly] returns the most recent one with values (status ok).
  Future<BodyAnalysis?> fetchLatestAnalysis({bool okOnly = false}) async {
    final token = await _token();
    final uri = Uri.parse('$_base/photos/analysis/latest')
        .replace(queryParameters: okOnly ? {'status': 'ok'} : null);
    final r = await ApiHttp.instance.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) throw PhotoException('fetching the latest analysis failed', r.statusCode);
    return BodyAnalysis.fromJson(json.decode(r.body) as Map<String, dynamic>);
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Future<List<BodyPhoto>> listPhotos({String? sessionId}) async {
    final token = await _token();
    final uri   = Uri.parse('$_base/photos').replace(
        queryParameters: sessionId != null ? {'session_id': sessionId} : null);
    final r = await ApiHttp.instance.get(uri,
        headers: {'Authorization': 'Bearer $token'});
    if (r.statusCode != 200) throw PhotoException('listing photos failed', r.statusCode);
    final decoded = json.decode(r.body) as Map<String, dynamic>;
    return (decoded['photos'] as List<dynamic>)
        .map((e) => BodyPhoto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('mirror_token');
    if (t == null) throw const PhotoException('not signed in');
    return t;
  }
}
