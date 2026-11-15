import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mirror_3d/core/l10n/app_localizations.dart';
import 'package:mirror_3d/core/l10n/error_text.dart';
import 'package:mirror_3d/services/api/auth_api.dart';

// Every code the backend sends today (backend/api_errors.py users; see ONBOARDING.md §6).
const backendCodes = [
  'phone_empty', 'phone_needs_country_code', 'phone_invalid', 'phone_not_mobile',
  'email_empty', 'email_invalid', 'rate_limited', 'code_invalid',
  'sms_send_failed', 'email_send_failed', 'apple_token_invalid',
];

/// A response shaped like the backend's, encoded as UTF-8 with no charset header.
http.Response serverResponse(int status, Map<String, Object?> body) =>
    http.Response.bytes(utf8.encode(json.encode(body)), status,
        headers: {'content-type': 'application/json'});

void main() {
  final zh = lookupS(const Locale('zh'));
  final en = lookupS(const Locale('en'));

  test('every backend code has text in both languages', () {
    for (final code in backendCodes) {
      expect(errorCodeText(zh, code), isNotNull, reason: code);
      expect(errorCodeText(en, code), isNotNull, reason: code);
      expect(errorCodeText(en, code), isNot(errorCodeText(zh, code)), reason: code);
    }
  });

  test('the Chinese text matches the backend detail word for word', () {
    // backend/auth/identity.py and auth/router.py
    expect(errorCodeText(zh, 'phone_empty'), '请输入手机号');
    expect(errorCodeText(zh, 'phone_needs_country_code'), '请选择国家/地区代码，例如 +86');
    expect(errorCodeText(zh, 'phone_invalid'), '该国家/地区的手机号格式不正确');
    expect(errorCodeText(zh, 'phone_not_mobile'), '仅支持手机号，不支持座机、免费电话等号码');
    expect(errorCodeText(zh, 'email_empty'), '请输入邮箱');
    expect(errorCodeText(zh, 'email_invalid'), '邮箱格式不正确');
    expect(errorCodeText(zh, 'rate_limited'), '请求过于频繁，请稍后再试');
  });

  test('unknown or missing code gives null', () {
    expect(errorCodeText(en, 'something_new'), isNull);
    expect(errorCodeText(en, null), isNull);
  });

  group('AuthException.fromResponse + serverErrorText', () {
    test('422 with a code is translated', () {
      final e = AuthException.fromResponse(
          serverResponse(422, {'detail': '邮箱格式不正确', 'code': 'email_invalid'}));
      expect(e.status, 422);
      expect(e.code, 'email_invalid');
      expect(e.detail, '邮箱格式不正确');                   // UTF-8 decoded, not mangled
      expect(serverErrorText(en, e), 'Enter a valid email address');
      expect(serverErrorText(zh, e), '邮箱格式不正确');
    });

    test('400 wrong OTP: English detail no longer shown to Chinese users', () {
      final e = AuthException.fromResponse(
          serverResponse(400, {'detail': 'Invalid or expired code', 'code': 'code_invalid'}));
      expect(serverErrorText(zh, e), '验证码错误或已过期');
      expect(serverErrorText(en, e), 'Invalid or expired code');
    });

    test('429 is translated, with or without a code', () {
      final coded = AuthException.fromResponse(
          serverResponse(429, {'detail': '请求过于频繁，请稍后再试', 'code': 'rate_limited'}));
      expect(serverErrorText(en, coded), 'Too many requests. Please try again later');
      final bare = AuthException.fromResponse(http.Response('', 429));
      expect(serverErrorText(en, bare), 'Too many requests. Please try again later');
    });

    test('a code this build does not know falls back to detail on 400/422/429', () {
      final e = AuthException.fromResponse(
          serverResponse(422, {'detail': '新的错误', 'code': 'added_later'}));
      expect(serverErrorText(en, e), '新的错误');
    });

    test('an old server without codes still shows its detail', () {
      final e = AuthException.fromResponse(serverResponse(422, {'detail': '邮箱格式不正确'}));
      expect(e.code, isNull);
      expect(serverErrorText(en, e), '邮箱格式不正确');
    });

    test('send failures (500) are translated; their technical detail is never shown', () {
      final e = AuthException.fromResponse(
          serverResponse(500, {'detail': 'SMS failed: timeout', 'code': 'sms_send_failed'}));
      expect(serverErrorText(en, e), 'Failed to send. Please try again');
    });

    test('other statuses without a known code give a network error with the status', () {
      final html = AuthException.fromResponse(http.Response('<html>bad gateway</html>', 502));
      expect(html.detail, isNull);
      expect(serverErrorText(en, html), 'Network error (502)');
      expect(serverErrorText(zh, html), '网络错误 (502)');
      final pydantic = AuthException.fromResponse(serverResponse(422, {'detail': [{'msg': 'x'}]}));
      expect(serverErrorText(en, pydantic), 'Network error (422)');
    });
  });
}
