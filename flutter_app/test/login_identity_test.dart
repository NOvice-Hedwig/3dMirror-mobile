import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_3d/core/data/country_names.dart';
import 'package:mirror_3d/core/validation/login_identity.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart' show IsoCode;

void main() {
  group('checkPhone — accepted (same numbers as backend tests/test_identity.py)', () {
    final cases = <(String, IsoCode, String)>[
      ('+86 138 1234 5678', IsoCode.US, '+8613812345678'),   // "+" wins over the picker
      ('138 1234 5678',     IsoCode.CN, '+8613812345678'),   // no "+": picker country
      ('+1 (201) 555-0123', IsoCode.CN, '+12015550123'),     // US: fixed line or mobile
      ('(201) 555-0123',    IsoCode.US, '+12015550123'),
      ('+44 7400 123456',   IsoCode.CN, '+447400123456'),
      ('07400 123456',      IsoCode.GB, '+447400123456'),    // national trunk prefix
      ('+81 90-1234-5678',  IsoCode.CN, '+819012345678'),
      ('+49 1512 3456789',  IsoCode.CN, '+4915123456789'),
      ('+91 81234 56789',   IsoCode.CN, '+918123456789'),
    ];
    for (final (input, selected, e164) in cases) {
      test('$input (picker ${selected.name}) → $e164', () {
        final r = checkPhone(input, selected);
        expect(r.error, isNull);
        expect(r.e164, e164);
      });
    }
  });

  group('checkPhone — rejected', () {
    final cases = <(String, IsoCode, String)>[
      ('',                 IsoCode.CN, msgPhoneEmpty),
      ('  ',               IsoCode.CN, msgPhoneEmpty),
      ('123',              IsoCode.CN, msgPhoneInvalid),
      ('+86 123',          IsoCode.CN, msgPhoneInvalid),
      ('+1 012 555 0123',  IsoCode.CN, msgPhoneInvalid),
      ('138 1234 5678',    IsoCode.GB, msgPhoneInvalid),     // a China number, UK picked
      ('+18002345678',     IsoCode.CN, msgPhoneNotMobile),   // US toll-free
      ('+441212345678',    IsoCode.CN, msgPhoneNotMobile),   // UK fixed line
      ('+4930123456',      IsoCode.CN, msgPhoneNotMobile),   // Germany fixed line
      ('010 1234 5678',    IsoCode.CN, msgPhoneNotMobile),   // China fixed line (Beijing)
    ];
    for (final (input, selected, message) in cases) {
      test('"$input" (picker ${selected.name}) → $message', () {
        final r = checkPhone(input, selected);
        expect(r.isValid, isFalse);
        expect(r.error, message);
      });
    }
  });

  test('a "+…" input reports its country so the picker can follow', () {
    expect(checkPhone('+44 7400', IsoCode.CN).typedCountry, IsoCode.GB);
    expect(checkPhone('+81 90 1234 5678', IsoCode.CN).typedCountry, IsoCode.JP);
    expect(checkPhone('138 1234 5678', IsoCode.GB).typedCountry, isNull);
  });

  group('email', () {
    test('trimmed and lowercased', () {
      expect(normalizeEmail('  Foo.Bar@Example.COM '), 'foo.bar@example.com');
    });
    test('valid', () {
      for (final e in ['user@example.com', 'a+tag@sub.example.co.uk', ' X@Y.ORG ']) {
        expect(emailError(e), isNull, reason: e);
      }
    });
    test('invalid', () {
      expect(emailError(''), msgEmailEmpty);
      for (final e in ['foo', 'foo@', '@example.com', 'foo bar@x.com', 'foo@bar', 'foo@@bar.com']) {
        expect(emailError(e), msgEmailInvalid, reason: e);
      }
    });
  });

  group('countries', () {
    test('every IsoCode has a Chinese and English name', () {
      final missing = IsoCode.values.where((c) => !kCountryNames.containsKey(c.name)).toList();
      expect(missing, isEmpty);
    });
    test('search by Chinese name, English name, ISO code and dialing code', () {
      expect(searchCountries('德国').first, IsoCode.DE);
      expect(searchCountries('germany').first, IsoCode.DE);
      expect(searchCountries('Japan').first, IsoCode.JP);
      expect(searchCountries('jp').first, IsoCode.JP);
      expect(searchCountries('+44').first, IsoCode.GB);
      expect(searchCountries('86').first, IsoCode.CN);
      // "+1" is shared: US, Canada and several Caribbean countries
      expect(searchCountries('+1').first, IsoCode.US);              // main country of +1
      expect(searchCountries('+1').take(30), contains(IsoCode.CA));
      expect(searchCountries('zzzz'), isEmpty);
      expect(searchCountries('').length, IsoCode.values.length);
    });
    test('dialing codes and flags', () {
      expect(dialCode(IsoCode.CN), '86');
      expect(dialCode(IsoCode.GB), '44');
      expect(flagEmoji(IsoCode.CN), '🇨🇳');
    });
    test('default country follows the device locale, falling back to China', () {
      expect(defaultCountry('US'), IsoCode.US);
      expect(defaultCountry('gb'), IsoCode.GB);
      expect(defaultCountry(''), IsoCode.CN);
      expect(defaultCountry('ZZ'), IsoCode.CN);
    });
  });
}
