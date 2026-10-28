"""Unit tests for login identifier normalization and the send rate limiter (no DB, no server)."""

import os
import sys
from datetime import datetime, timedelta, timezone

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import clock                                    # noqa: E402
from auth import rate_limit                     # noqa: E402
from auth.identity import (                     # noqa: E402
    MSG_EMAIL_EMPTY, MSG_EMAIL_INVALID, MSG_PHONE_EMPTY, MSG_PHONE_INVALID,
    MSG_PHONE_NEEDS_CODE, MSG_PHONE_NOT_MOBILE, IdentityError, legacy_phone_digits,
    normalize_email, normalize_phone,
)


# ── Phone: accepted ───────────────────────────────────────────────────────────

@pytest.mark.parametrize("raw,e164,region,national", [
    ("+8613812345678",      "+8613812345678", "CN", "13812345678"),
    ("+86 138 1234 5678",   "+8613812345678", "CN", "13812345678"),
    (" +86-138-1234-5678 ", "+8613812345678", "CN", "13812345678"),
    ("+1 (201) 555-0123",   "+12015550123",   "US", "2015550123"),    # FIXED_LINE_OR_MOBILE
    ("+44 7400 123456",     "+447400123456",  "GB", "7400123456"),
    ("+81 90-1234-5678",    "+819012345678",  "JP", "9012345678"),
    ("+49 1512 3456789",    "+4915123456789", "DE", "15123456789"),
    ("+91 81234 56789",     "+918123456789",  "IN", "8123456789"),
])
def test_valid_mobile_numbers_normalize_to_e164(raw, e164, region, national):
    p = normalize_phone(raw)
    assert (p.e164, p.region, p.national) == (e164, region, national)


# ── Phone: rejected ───────────────────────────────────────────────────────────

@pytest.mark.parametrize("raw,message", [
    ("",                 MSG_PHONE_EMPTY),
    ("   ",              MSG_PHONE_EMPTY),
    ("13812345678",      MSG_PHONE_NEEDS_CODE),   # no country code
    ("8613812345678",    MSG_PHONE_NEEDS_CODE),
    ("+86 123",          MSG_PHONE_INVALID),      # too short
    ("+8612345678901",   MSG_PHONE_INVALID),      # 11 digits but no CN range starts with 12
    ("+1 012 555 0123",  MSG_PHONE_INVALID),      # US area code can't start with 0
    ("+999 1234567",     MSG_PHONE_INVALID),      # unassigned country code
    ("+86 abc",          MSG_PHONE_INVALID),
    ("+18002345678",     MSG_PHONE_NOT_MOBILE),   # US toll-free
    ("+19002345678",     MSG_PHONE_NOT_MOBILE),   # US premium-rate
    ("+441212345678",    MSG_PHONE_NOT_MOBILE),   # UK fixed line (Birmingham)
    ("+4930123456",      MSG_PHONE_NOT_MOBILE),   # Germany fixed line (Berlin)
    ("+861012345678",    MSG_PHONE_NOT_MOBILE),   # China fixed line (Beijing)
    ("+448001234567",    MSG_PHONE_NOT_MOBILE),   # UK toll-free
])
def test_invalid_or_non_mobile_numbers_are_rejected(raw, message):
    with pytest.raises(IdentityError) as e:
        normalize_phone(raw)
    assert str(e.value) == message


# ── Legacy matching forms ─────────────────────────────────────────────────────

def test_legacy_digits_for_china_include_bare_national_number():
    forms = legacy_phone_digits(normalize_phone("+8613812345678"))
    assert set(forms) == {"8613812345678", "13812345678"}


def test_legacy_digits_outside_china_require_country_code():
    # A bare national number was always China in old builds; never match it for other countries.
    assert legacy_phone_digits(normalize_phone("+447400123456")) == ["447400123456"]
    assert legacy_phone_digits(normalize_phone("+12015550123")) == ["12015550123"]


# ── Email ─────────────────────────────────────────────────────────────────────

@pytest.mark.parametrize("raw,expected", [
    ("user@example.com",           "user@example.com"),
    ("  Foo.Bar@Example.COM  ",    "foo.bar@example.com"),
    ("A+tag@Sub.Example.co.uk",    "a+tag@sub.example.co.uk"),
])
def test_email_is_trimmed_lowercased_and_validated(raw, expected):
    assert normalize_email(raw) == expected


@pytest.mark.parametrize("raw,message", [
    ("",               MSG_EMAIL_EMPTY),
    ("   ",            MSG_EMAIL_EMPTY),
    ("foo",            MSG_EMAIL_INVALID),
    ("foo@",           MSG_EMAIL_INVALID),
    ("@example.com",   MSG_EMAIL_INVALID),
    ("foo bar@x.com",  MSG_EMAIL_INVALID),
    ("foo@bar",        MSG_EMAIL_INVALID),
    ("foo@@bar.com",   MSG_EMAIL_INVALID),
])
def test_invalid_emails_are_rejected(raw, message):
    with pytest.raises(IdentityError) as e:
        normalize_email(raw)
    assert str(e.value) == message


# ── SMS routing ───────────────────────────────────────────────────────────────

@pytest.mark.parametrize("raw,provider,sent_to", [
    ("+86 138 1234 5678", "aliyun", "13812345678"),     # national number, no "+86"
    ("+86 186 1234 5678", "aliyun", "18612345678"),
    ("+44 7400 123456",   "twilio", "+447400123456"),   # E.164
    ("+1 201 555 0123",   "twilio", "+12015550123"),
    ("+81 90 1234 5678",  "twilio", "+819012345678"),
])
def test_sms_routing_china_to_aliyun_national_others_to_twilio_e164(monkeypatch, raw, provider, sent_to):
    import asyncio
    from auth import service
    calls = []

    async def fake_aliyun(number, otp): calls.append(("aliyun", number))
    async def fake_twilio(number, otp): calls.append(("twilio", number))

    monkeypatch.setattr(service, "DEV_MODE", False)
    monkeypatch.setattr(service, "_aliyun", fake_aliyun)
    monkeypatch.setattr(service, "_twilio", fake_twilio)
    phone = normalize_phone(raw)
    otp = asyncio.run(service.send_sms_otp(phone))
    assert calls == [(provider, sent_to)]
    assert service.verify_code(phone.e164, otp)          # OTP keyed by E.164


# ── Rate limiter ──────────────────────────────────────────────────────────────

T0 = datetime(2026, 10, 27, 12, 0, tzinfo=timezone.utc)


@pytest.fixture
def at(monkeypatch):
    """at(seconds) moves the limiter's clock to T0 + seconds."""
    rate_limit.reset()
    monkeypatch.setattr(rate_limit, "IP_RULES",
                        [(rate_limit.MINUTE, 5), (rate_limit.HOUR, 20)])

    def _at(seconds: float):
        monkeypatch.setattr(clock, "now_utc", lambda: T0 + timedelta(seconds=seconds))
    yield _at
    rate_limit.reset()


def test_destination_limited_to_one_per_minute(at):
    at(0)
    rate_limit.check_and_record("phone:+8613812345678", "1.1.1.1")
    at(30)
    with pytest.raises(rate_limit.RateLimited) as e:
        rate_limit.check_and_record("phone:+8613812345678", "1.1.1.1")
    assert e.value.retry_after_s == 30
    at(60)
    rate_limit.check_and_record("phone:+8613812345678", "1.1.1.1")


def test_destination_limited_to_five_per_hour(at):
    for i in range(5):
        at(i * 61)
        rate_limit.check_and_record("email:a@example.com", f"10.0.0.{i}")
    at(5 * 61)
    with pytest.raises(rate_limit.RateLimited) as e:
        rate_limit.check_and_record("email:a@example.com", "10.0.0.9")
    assert e.value.retry_after_s == 3600 - 5 * 61       # until the first send is an hour old
    at(3600)
    rate_limit.check_and_record("email:a@example.com", "10.0.0.9")


def test_ip_limited_to_five_per_minute_and_twenty_per_hour(at):
    at(0)
    for i in range(5):
        rate_limit.check_and_record(f"email:u{i}@example.com", "2.2.2.2")
    with pytest.raises(rate_limit.RateLimited):
        rate_limit.check_and_record("email:u5@example.com", "2.2.2.2")
    rate_limit.check_and_record("email:u5@example.com", "3.3.3.3")   # other IP unaffected

    sent = 5
    t = 0
    while sent < 20:                                  # 15 more, spread out under 5/min
        t += 61
        at(t)
        for _ in range(min(5, 20 - sent)):
            rate_limit.check_and_record(f"email:v{sent}@example.com", "2.2.2.2")
            sent += 1
    at(t + 61)
    with pytest.raises(rate_limit.RateLimited):
        rate_limit.check_and_record("email:w@example.com", "2.2.2.2")


def test_rejected_attempts_do_not_use_quota(at):
    at(0)
    rate_limit.check_and_record("phone:+447400123456", "4.4.4.4")
    for s in (5, 10, 15):                            # three rejected retries within the minute
        at(s)
        with pytest.raises(rate_limit.RateLimited):
            rate_limit.check_and_record("phone:+447400123456", "4.4.4.4")
    at(60)
    rate_limit.check_and_record("phone:+447400123456", "4.4.4.4")
