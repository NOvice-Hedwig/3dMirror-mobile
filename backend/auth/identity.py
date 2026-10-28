"""
Login identifier rules (phone and email). The backend is the source of truth; the app runs the
same checks only for UX.

Phone
- Input must include the country code ("+…"); spaces, dashes, dots and parentheses are ignored.
- Must be a valid number for its region and of type MOBILE or FIXED_LINE_OR_MOBILE
  (some countries, e.g. US/CA, cannot tell the two apart). Fixed line, toll-free, premium-rate,
  VoIP, etc. are rejected.
- Normalized to E.164 ("+8613800138000") for the OTP key, storage and lookup.

Email
- Trimmed, lowercased, then validated as EmailStr (format only, no DNS lookup).

Errors are IdentityError with a user-facing Chinese message; routers turn them into 422.
"""

import re
from dataclasses import dataclass

import phonenumbers
from phonenumbers import PhoneNumberFormat, PhoneNumberType
from pydantic import EmailStr, TypeAdapter, ValidationError

MSG_PHONE_EMPTY        = "请输入手机号"
MSG_PHONE_NEEDS_CODE   = "请选择国家/地区代码，例如 +86"
MSG_PHONE_INVALID      = "该国家/地区的手机号格式不正确"
MSG_PHONE_NOT_MOBILE   = "仅支持手机号，不支持座机、免费电话等号码"
MSG_EMAIL_EMPTY        = "请输入邮箱"
MSG_EMAIL_INVALID      = "邮箱格式不正确"

_ACCEPTED_TYPES = {PhoneNumberType.MOBILE, PhoneNumberType.FIXED_LINE_OR_MOBILE}
_FORMATTING = re.compile(r"[\s\-.()]")
_EMAIL = TypeAdapter(EmailStr)


class IdentityError(ValueError):
    """Invalid login identifier; str(error) is the message shown to the user."""


@dataclass(frozen=True)
class Phone:
    e164: str          # "+8613800138000"
    region: str        # ISO 3166-1 alpha-2, e.g. "CN"
    country_code: int  # 86
    national: str      # national significant number, e.g. "13800138000"


def normalize_phone(raw: str) -> Phone:
    s = _FORMATTING.sub("", raw or "")
    if not s:
        raise IdentityError(MSG_PHONE_EMPTY)
    if not s.startswith("+"):
        raise IdentityError(MSG_PHONE_NEEDS_CODE)
    try:
        n = phonenumbers.parse(s, None)
    except phonenumbers.NumberParseException:
        raise IdentityError(MSG_PHONE_INVALID)
    if not phonenumbers.is_valid_number(n):
        raise IdentityError(MSG_PHONE_INVALID)
    if phonenumbers.number_type(n) not in _ACCEPTED_TYPES:
        raise IdentityError(MSG_PHONE_NOT_MOBILE)
    return Phone(
        e164=phonenumbers.format_number(n, PhoneNumberFormat.E164),
        region=phonenumbers.region_code_for_number(n),
        country_code=n.country_code,
        national=phonenumbers.national_significant_number(n),
    )


def normalize_email(raw: str) -> str:
    s = (raw or "").strip().lower()
    if not s:
        raise IdentityError(MSG_EMAIL_EMPTY)
    try:
        return str(_EMAIL.validate_python(s))
    except ValidationError:
        raise IdentityError(MSG_EMAIL_INVALID)


def legacy_phone_digits(phone: Phone) -> list[str]:
    """Digit-only forms an older build may have stored for this number.

    Before 2026-10 the app sent whatever the user typed (no country picker, China assumed), so
    users.phone may hold e.g. "13800138000", "8613800138000" or "+86 138 0013 8000". Lookups
    compare these against the stored value with all non-digits removed.
    - country code + national number: any country.
    - national number alone (with or without trunk prefix): China only, because legacy input
      without a country code was always China; matching it for other countries could tie a
      number to the wrong person.
    """
    forms = {f"{phone.country_code}{phone.national}"}
    if phone.region == "CN":
        forms.add(phone.national)
        forms.add(re.sub(r"\D", "", phonenumbers.format_number(
            phonenumbers.parse(phone.e164), PhoneNumberFormat.NATIONAL)))
    return sorted(forms)
