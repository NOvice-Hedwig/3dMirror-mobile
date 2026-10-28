import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_http.dart';

class AuthResponse {
  final String userId, token;
  final bool isNewUser;
  const AuthResponse({required this.userId, required this.token, required this.isNewUser});
  factory AuthResponse.fromJson(Map<String, dynamic> j) => AuthResponse(
    userId: j['user_id'] as String,
    token: j['token'] as String,
    isNewUser: j['is_new_user'] as bool,
  );
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override String toString() => message;
}

class AuthApi {
  AuthApi._();
  static final AuthApi instance = AuthApi._();

  static const _base = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000');

  Future<void> sendPhoneOtp(String phone) =>
      _post('/auth/phone/send', {'phone': phone});

  Future<AuthResponse> verifyPhoneOtp(String phone, String code) async {
    final r = await _postRaw('/auth/phone/verify', {'phone': phone, 'code': code});
    return AuthResponse.fromJson(r);
  }

  Future<void> sendEmailOtp(String email) =>
      _post('/auth/email/send', {'email': email});

  Future<AuthResponse> verifyEmailOtp(String email, String code) async {
    final r = await _postRaw('/auth/email/verify', {'email': email, 'code': code});
    return AuthResponse.fromJson(r);
  }

  Future<AuthResponse> appleSignIn({required String identityToken, String? fullName}) async {
    final r = await _postRaw('/auth/apple', {
      'identity_token': identityToken,
      if (fullName != null) 'full_name': fullName,
    });
    return AuthResponse.fromJson(r);
  }

  Future<void> persistToken(String token, String userId) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('mirror_token', token);
    await p.setString('mirror_user_id', userId);
  }

  Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString('mirror_token');

  Future<String?> getUserId() async =>
      (await SharedPreferences.getInstance()).getString('mirror_user_id');

  Future<bool> isLoggedIn() async => (await getToken()) != null;

  /// Clears the stored session and notifies the app root (see [SessionEvents]).
  Future<void> signOut() => SessionEvents.signOut();

  // ── internals ──────────────────────────────────────────────────────────────
  Future<void> _post(String path, Map<String, dynamic> body) async {
    final r = await ApiHttp.instance.post(Uri.parse('$_base$path'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body));
    _assert(r);
  }

  Future<Map<String, dynamic>> _postRaw(String path, Map<String, dynamic> body) async {
    final r = await ApiHttp.instance.post(Uri.parse('$_base$path'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body));
    _assert(r);
    return json.decode(r.body) as Map<String, dynamic>;
  }

  /// 400 (wrong code), 422 (bad phone/email format) and 429 (too many requests) carry a
  /// user-facing Chinese `detail`; show it as is.
  void _assert(http.Response r) {
    if (r.statusCode == 200 || r.statusCode == 201) return;
    String? detail;
    try {
      final b = json.decode(r.body);
      if (b is Map && b['detail'] is String) detail = b['detail'] as String;
    } on FormatException {
      // not JSON
    }
    if (r.statusCode == 429) throw AuthException(detail ?? '请求过于频繁，请稍后再试');
    if ((r.statusCode == 400 || r.statusCode == 422) && detail != null) {
      throw AuthException(detail);
    }
    throw AuthException('网络错误 (${r.statusCode})');
  }
}
