// Login identifier rules for the auth screen (UX only — the backend re-checks the same rules
// in backend/auth/identity.py and is the source of truth).
//
// Phone: valid for the selected (or typed "+…") country and a mobile number; sent as E.164.
// Email: trimmed + lowercased, basic format check.

import 'dart:ui' show PlatformDispatcher;

import 'package:phone_numbers_parser/metadata.dart' show countryCodeToIsoCode;
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../data/country_names.dart';
import '../l10n/error_text.dart';

/// Result of checking a phone input: either an E.164 number or an error code
/// (ErrorCode.phone*, the backend's codes; show it with errorCodeText).
class PhoneCheck {
  final String? e164;
  final String? error;
  final IsoCode? typedCountry; // country taken from a "+…" input, for the picker to follow
  const PhoneCheck._({this.e164, this.error, this.typedCountry});
  bool get isValid => e164 != null;
}

final _formatting = RegExp(r'[\s\-.()]');

PhoneCheck checkPhone(String input, IsoCode selected) {
  final s = input.replaceAll(_formatting, '');
  if (s.isEmpty) return const PhoneCheck._(error: ErrorCode.phoneEmpty);
  final PhoneNumber n;
  try {
    n = s.startsWith('+')
        ? PhoneNumber.parse(s)
        : PhoneNumber.parse(s, destinationCountry: selected);
  } on PhoneNumberException {
    return const PhoneCheck._(error: ErrorCode.phoneInvalid);
  }
  final typed = s.startsWith('+') ? n.isoCode : null;
  if (!n.isValid()) return PhoneCheck._(error: ErrorCode.phoneInvalid, typedCountry: typed);
  // phone_numbers_parser has no FIXED_LINE_OR_MOBILE type; where the two can't be told apart
  // (e.g. US/CA) the mobile check passes, matching the backend's MOBILE | FIXED_LINE_OR_MOBILE.
  if (!n.isValid(type: PhoneNumberType.mobile)) {
    return PhoneCheck._(error: ErrorCode.phoneNotMobile, typedCountry: typed);
  }
  return PhoneCheck._(e164: n.international, typedCountry: typed);
}

final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String normalizeEmail(String input) => input.trim().toLowerCase();

/// Error code for an email input (ErrorCode.email*), or null when it looks valid.
String? emailError(String input) {
  final s = normalizeEmail(input);
  if (s.isEmpty) return ErrorCode.emailEmpty;
  if (!_email.hasMatch(s)) return ErrorCode.emailInvalid;
  return null;
}

// ── Countries ─────────────────────────────────────────────────────────────────

/// Dialing code without "+", e.g. "86".
String dialCode(IsoCode iso) => PhoneNumber(isoCode: iso, nsn: '').countryCode;

String countryNameZh(IsoCode iso) => kCountryNames[iso.name]?.zh ?? iso.name;
String countryNameEn(IsoCode iso) => kCountryNames[iso.name]?.en ?? iso.name;

/// Name in the app language ('en' → English, anything else → Chinese) and in the other one.
String countryName(IsoCode iso, String languageCode) =>
    languageCode == 'en' ? countryNameEn(iso) : countryNameZh(iso);
String countryNameOther(IsoCode iso, String languageCode) =>
    languageCode == 'en' ? countryNameZh(iso) : countryNameEn(iso);

/// Flag emoji from the ISO code (regional indicator symbols).
String flagEmoji(IsoCode iso) => String.fromCharCodes(
    iso.name.codeUnits.map((c) => 0x1F1E6 + c - 'A'.codeUnitAt(0)));

/// Country from the device locale (e.g. zh_CN → CN), falling back to China.
IsoCode defaultCountry([String? localeCountryCode]) {
  final code = (localeCountryCode ?? PlatformDispatcher.instance.locale.countryCode)?.toUpperCase();
  for (final iso in IsoCode.values) {
    if (iso.name == code) return iso;
  }
  return IsoCode.CN;
}

/// Countries matching [query] by Chinese name, English name, ISO code or dialing code
/// ("86", "+86"). Best matches first: exact ISO code or the main country of an exact dialing
/// code (e.g. +44 → United Kingdom before Guernsey), other countries sharing that code, then
/// name prefix, dialing-code prefix, name substring.
List<IsoCode> searchCountries(String query) {
  final all = IsoCode.values.toList()
    ..sort((a, b) => countryNameEn(a).compareTo(countryNameEn(b)));
  final q = query.trim().toLowerCase().replaceFirst(RegExp(r'^\+'), '');
  if (q.isEmpty) return all;

  int rank(IsoCode iso) {
    final zh = countryNameZh(iso).toLowerCase();
    final en = countryNameEn(iso).toLowerCase();
    final dial = dialCode(iso);
    if (iso.name.toLowerCase() == q) return 0;
    if (dial == q) return countryCodeToIsoCode[dial]?.first == iso ? 0 : 1;   // main country first
    if (zh.startsWith(q) || en.startsWith(q)) return 2;
    if (dial.startsWith(q)) return 3;
    if (zh.contains(q) || en.contains(q)) return 4;
    return -1;
  }

  // List.sort isn't stable, so break rank ties by English name explicitly.
  final ranked = [for (final iso in all) (iso, rank(iso))]
      .where((e) => e.$2 >= 0)
      .toList()
    ..sort((a, b) => a.$2 != b.$2
        ? a.$2.compareTo(b.$2)
        : countryNameEn(a.$1).compareTo(countryNameEn(b.$1)));
  return [for (final e in ranked) e.$1];
}
