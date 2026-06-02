import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/body_photo.dart';

class PhotoException implements Exception {
  final String message;
  const PhotoException(this.message);
  @override String toString() => message;
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
      ));
    }

    final streamed = await request.send();
    final body     = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200 && streamed.statusCode != 201) {
      throw PhotoException('上传失败 (${streamed.statusCode})');
    }

    final decoded = json.decode(body) as Map<String, dynamic>;
    return (decoded['photo_ids'] as List<dynamic>)
        .map((e) => e as String)
        .toList();
  }

  // ── Analyze ────────────────────────────────────────────────────────────────

  Future<PhotoAnalysisResult?> analyzePhotos(List<String> photoIds) async {
    if (photoIds.isEmpty) return null;
    final token = await _token();

    final request = http.MultipartRequest('POST', Uri.parse('$_base/photos/analyze'))
      ..headers['Authorization'] = 'Bearer $token';

    for (final id in photoIds) {
      request.fields['photo_ids'] = id;
    }

    // Use form-encoded body instead to match FastAPI Form(...) list
    final formBody = photoIds.map((id) => 'photo_ids=${Uri.encodeComponent(id)}').join('&');
    final r = await http.post(
      Uri.parse('$_base/photos/analyze'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: formBody,
    );

    if (r.statusCode != 200) return null;

    final decoded  = json.decode(r.body) as Map<String, dynamic>;
    final analysis = decoded['analysis'] as Map<String, dynamic>?;
    if (analysis == null || analysis.isEmpty) return null;
    return PhotoAnalysisResult.fromJson(analysis);
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Future<List<BodyPhoto>> listPhotos({String? sessionId}) async {
    final token = await _token();
    final uri   = Uri.parse('$_base/photos').replace(
        queryParameters: sessionId != null ? {'session_id': sessionId} : null);
    final r = await http.get(uri,
        headers: {'Authorization': 'Bearer $token'});
    if (r.statusCode != 200) throw PhotoException('获取失败 (${r.statusCode})');
    final decoded = json.decode(r.body) as Map<String, dynamic>;
    return (decoded['photos'] as List<dynamic>)
        .map((e) => BodyPhoto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('mirror_token');
    if (t == null) throw const PhotoException('未登录');
    return t;
  }
}
