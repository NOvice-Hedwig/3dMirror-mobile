// User-facing text for error codes. The codes are the backend's (`{"detail", "code"}`,
// see backend/api_errors.py); the app's own login checks (core/validation/login_identity.dart)
// return the same codes, so one mapping covers both.

import 'app_localizations.dart';

abstract final class ErrorCode {
  static const phoneEmpty            = 'phone_empty';
  static const phoneNeedsCountryCode = 'phone_needs_country_code';
  static const phoneInvalid          = 'phone_invalid';
  static const phoneNotMobile        = 'phone_not_mobile';
  static const emailEmpty            = 'email_empty';
  static const emailInvalid          = 'email_invalid';
  static const rateLimited           = 'rate_limited';
  static const codeInvalid           = 'code_invalid';
  static const smsSendFailed         = 'sms_send_failed';
  static const emailSendFailed       = 'email_send_failed';
  static const appleTokenInvalid     = 'apple_token_invalid';
  static const predictNotEnoughData  = 'predict_not_enough_data';
}

/// Translated text for [code], or null if the app doesn't know it.
String? errorCodeText(S s, String? code) => switch (code) {
  ErrorCode.phoneEmpty            => s.errorPhoneEmpty,
  ErrorCode.phoneNeedsCountryCode => s.errorPhoneNeedsCountryCode,
  ErrorCode.phoneInvalid          => s.errorPhoneInvalid,
  ErrorCode.phoneNotMobile        => s.errorPhoneNotMobile,
  ErrorCode.emailEmpty            => s.errorEmailEmpty,
  ErrorCode.emailInvalid          => s.errorEmailInvalid,
  ErrorCode.rateLimited           => s.errorRateLimited,
  ErrorCode.codeInvalid           => s.errorInvalidCode,
  ErrorCode.smsSendFailed ||
  ErrorCode.emailSendFailed       => s.errorSendFailed,
  ErrorCode.appleTokenInvalid     => s.errorAppleSignIn,
  ErrorCode.predictNotEnoughData  => s.predictNotEnoughTitle,
  _                               => null,
};

/// An error response from the backend.
abstract interface class ServerError {
  int get status;
  String? get code;
  String? get detail;
}

/// Text for a server error: the translated code; for a code this build doesn't know, the
/// server's `detail` on statuses whose detail is written for users (400/422/429); otherwise
/// a generic network error with the status.
String serverErrorText(S s, ServerError e) =>
    errorCodeText(s, e.code) ??
    (const {400, 422, 429}.contains(e.status) ? e.detail : null) ??
    (e.status == 429 ? s.errorRateLimited : s.errorNetworkStatus(e.status));
