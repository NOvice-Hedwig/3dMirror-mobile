import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'local_time.dart';

/// Thrown instead of a generic API error when the server rejects the stored token (401).
///
/// By the time a caller sees it, the session has already been cleared and the app root
/// is navigating to the login screen, so screens can treat it like any other error.
class UnauthorizedException implements Exception {
  const UnauthorizedException();
  @override
  String toString() => '登录已过期，请重新登录';
}

enum SessionEndReason { expired, signedOut }

/// The single place a session ends. Clears the stored token and user id, then notifies
/// the app root (main.dart), which resets per-user providers and navigates to /auth.
class SessionEvents {
  SessionEvents._();

  static final _controller = StreamController<SessionEndReason>.broadcast();
  static Stream<SessionEndReason> get stream => _controller.stream;

  /// Ends the session only if [usedToken] is still the stored token: a late 401 for an
  /// old token (after re-login), or a second parallel 401, must not end the new session.
  static Future<void> expire(String usedToken) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('mirror_token') != usedToken) return;
    await _clear(prefs);
    _controller.add(SessionEndReason.expired);
  }

  static Future<void> signOut() async {
    await _clear(await SharedPreferences.getInstance());
    _controller.add(SessionEndReason.signedOut);
  }

  static Future<void> _clear(SharedPreferences prefs) async {
    await prefs.remove('mirror_token');
    await prefs.remove('mirror_user_id');
  }
}

/// Shared HTTP client for every backend call.
///
/// - Adds the X-Timezone header (see local_time.dart).
/// - On 401 for a request that carried the stored token, ends the session and throws
///   [UnauthorizedException], so no screen has to handle expired tokens itself.
class ApiHttp extends http.BaseClient {
  ApiHttp._(this._inner);
  static final ApiHttp instance = ApiHttp._(http.Client());

  /// Wraps a fake inner client (e.g. package:http/testing.dart MockClient) in tests.
  @visibleForTesting
  factory ApiHttp.withInner(http.Client inner) => ApiHttp._(inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers.addAll(await timezoneHeader());
    final response = await _inner.send(request);
    if (response.statusCode != 401) return response;

    await response.stream.drain<void>();
    final usedToken = _bearerToken(request.headers['Authorization']);
    if (usedToken != null) {
      await SessionEvents.expire(usedToken);
    }
    throw const UnauthorizedException();
  }

  static String? _bearerToken(String? header) {
    if (header == null || !header.startsWith('Bearer ')) return null;
    final token = header.substring('Bearer '.length).trim();
    return token.isEmpty ? null : token;
  }
}
