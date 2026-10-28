"""
Login identifier validation, legacy-number matching and send rate limits, against real Postgres.

Runs the app in-process (FastAPI TestClient) so the rate limiter can be reset and its clock
frozen, and seeds legacy-format rows directly in the database.

Skipped unless INTEGRATION_DATABASE_URL points at the disposable 3dmirror_test database:
  INTEGRATION_DATABASE_URL=postgresql://mirror:mirror@localhost:5432/3dmirror_test \
  pytest tests/integration/test_auth_identity.py -v
"""

import asyncio
import logging
import os
import random
import sys
import uuid
from datetime import datetime, timedelta, timezone

import asyncpg
import phonenumbers
import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

DB_URL = os.getenv("INTEGRATION_DATABASE_URL")
EXPECTED_DB = "3dmirror_test"

pytestmark = pytest.mark.skipif(
    not DB_URL, reason="INTEGRATION_DATABASE_URL not set; needs a disposable Postgres database")

from auth.identity import (  # noqa: E402
    MSG_EMAIL_INVALID, MSG_PHONE_INVALID, MSG_PHONE_NEEDS_CODE, MSG_PHONE_NOT_MOBILE,
)

MSG_TOO_MANY = "请求过于频繁，请稍后再试"


# ── helpers ───────────────────────────────────────────────────────────────────

def db(sql: str, *args):
    async def run():
        conn = await asyncpg.connect(DB_URL)
        try:
            return await conn.fetch(sql, *args)
        finally:
            await conn.close()
    return asyncio.run(run())


def random_cn_mobile() -> str:
    """A fresh valid China mobile number in E.164 (138 + 8 random digits)."""
    return "+86138" + "".join(random.choices("0123456789", k=8))


def insert_user(phone: str, created_at: datetime | None = None) -> str:
    uid = str(uuid.uuid4())
    db("INSERT INTO users (id, phone, created_at) VALUES ($1, $2, $3)",
       uuid.UUID(uid), phone, created_at or datetime.now(timezone.utc))
    return uid


def stored_phone(uid: str) -> str | None:
    rows = db("SELECT phone FROM users WHERE id = $1", uuid.UUID(uid))
    return rows[0]["phone"] if rows else None


def login_phone(client, send_as: str, verify_as: str | None = None):
    r = client.post("/auth/phone/send", json={"phone": send_as})
    assert r.status_code == 200, r.text
    return client.post("/auth/phone/verify", json={"phone": verify_as or send_as, "code": "123456"})


# ── fixtures ──────────────────────────────────────────────────────────────────

@pytest.fixture(scope="module")
def client():
    from fastapi.testclient import TestClient

    assert db("SELECT current_database() AS d")[0]["d"] == EXPECTED_DB, \
        f"refusing to run: INTEGRATION_DATABASE_URL must point at {EXPECTED_DB}"
    with pytest.MonkeyPatch.context() as mp:
        mp.setenv("DATABASE_URL", DB_URL)
        import main
        import auth.service
        mp.setattr(auth.service, "DEV_MODE", True)   # fixed OTP 123456, no SMS/email sent
        with TestClient(main.app) as c:
            yield c


@pytest.fixture(autouse=True)
def fresh_limits(monkeypatch):
    """Each test starts with empty counters and a generous per-IP limit (all requests come from
    one test IP); the 429 tests tighten it explicitly."""
    from auth import rate_limit
    rate_limit.reset()
    monkeypatch.setattr(rate_limit, "IP_RULES", [(rate_limit.MINUTE, 1000), (rate_limit.HOUR, 1000)])
    yield rate_limit
    rate_limit.reset()


# ── valid numbers, many countries ─────────────────────────────────────────────

@pytest.mark.parametrize("formatted", [
    "+86 138 1234 5678",   # China
    "+1 (201) 555-0123",   # US (FIXED_LINE_OR_MOBILE)
    "+44 7400 123456",     # UK
    "+81 90-1234-5678",    # Japan
    "+49 1512 3456789",    # Germany
    "+91 81234 56789",     # India
])
def test_send_and_verify_accept_mobile_numbers_worldwide(client, formatted):
    e164 = phonenumbers.format_number(phonenumbers.parse(formatted),
                                      phonenumbers.PhoneNumberFormat.E164)
    r = login_phone(client, formatted, e164)          # format differs between send and verify
    assert r.status_code == 200, r.text
    assert stored_phone(r.json()["user_id"]) == e164


def test_new_user_is_stored_in_e164(client):
    e164 = random_cn_mobile()
    spaced = f"{e164[:3]} {e164[3:6]} {e164[6:10]} {e164[10:]}"
    r = login_phone(client, spaced)
    assert r.status_code == 200, r.text
    assert r.json()["is_new_user"] is True
    assert stored_phone(r.json()["user_id"]) == e164


# ── rejected input → 422 with a readable message ──────────────────────────────

@pytest.mark.parametrize("phone,message", [
    ("13812345678",     MSG_PHONE_NEEDS_CODE),
    ("+86 123",         MSG_PHONE_INVALID),
    ("+1 012 555 0123", MSG_PHONE_INVALID),
    ("+18002345678",    MSG_PHONE_NOT_MOBILE),    # US toll-free
    ("+441212345678",   MSG_PHONE_NOT_MOBILE),    # UK fixed line
    ("+861012345678",   MSG_PHONE_NOT_MOBILE),    # China fixed line
])
@pytest.mark.parametrize("endpoint", ["/auth/phone/send", "/auth/phone/verify"])
def test_bad_phone_returns_422_with_message(client, endpoint, phone, message):
    r = client.post(endpoint, json={"phone": phone, "code": "123456"})
    assert r.status_code == 422, r.text
    assert r.json() == {"detail": message}


@pytest.mark.parametrize("endpoint", ["/auth/email/send", "/auth/email/verify"])
@pytest.mark.parametrize("email", ["foo", "foo@", "foo bar@example.com", ""])
def test_bad_email_returns_422_with_message(client, endpoint, email):
    r = client.post(endpoint, json={"email": email, "code": "123456"})
    assert r.status_code == 422, r.text
    assert r.json()["detail"] in (MSG_EMAIL_INVALID, "请输入邮箱")


# ── email: OTP key and storage are normalized ─────────────────────────────────

def test_email_case_and_whitespace_do_not_matter(client, fresh_limits):
    local = f"Mixed.Case.{uuid.uuid4().hex[:8]}"
    assert client.post("/auth/email/send",
                       json={"email": f"  {local}@Example.COM "}).status_code == 200
    r = client.post("/auth/email/verify",
                    json={"email": f"{local.lower()}@example.com", "code": "123456"})
    assert r.status_code == 200, r.text
    first = r.json()
    assert first["is_new_user"] is True
    row = db("SELECT email::text AS e FROM users WHERE id = $1", uuid.UUID(first["user_id"]))
    assert row[0]["e"] == f"{local.lower()}@example.com"

    fresh_limits.reset()        # second login to the same address would otherwise be rate-limited
    assert client.post("/auth/email/send", json={"email": f"{local.upper()}@EXAMPLE.COM"}).status_code == 200
    again = client.post("/auth/email/verify", json={"email": f"{local}@example.com", "code": "123456"})
    assert again.json()["user_id"] == first["user_id"]
    assert again.json()["is_new_user"] is False


# ── legacy rows written by older builds ───────────────────────────────────────

@pytest.mark.parametrize("legacy_form", [
    lambda e: e[3:],                                       # "13812345678"
    lambda e: e[1:],                                       # "8613812345678"
    lambda e: f"+86 {e[3:6]} {e[6:10]} {e[10:]}",          # "+86 138 1234 5678"
    lambda e: f"{e[3:6]}-{e[6:10]}-{e[10:]}",              # "138-1234-5678"
])
def test_legacy_china_row_matches_and_is_rewritten_to_e164(client, fresh_limits, legacy_form):
    e164 = random_cn_mobile()
    uid = insert_user(legacy_form(e164))
    r = login_phone(client, e164)
    assert r.status_code == 200, r.text
    assert r.json() == {**r.json(), "user_id": uid, "is_new_user": False}
    assert stored_phone(uid) == e164

    fresh_limits.reset()                                   # same number again within a minute
    again = login_phone(client, e164)                      # second login: plain E.164 match
    assert again.json()["user_id"] == uid


def test_bare_national_number_never_matches_outside_china(client):
    national = "74001" + "".join(random.choices("0123456789", k=5))
    e164 = "+44" + national
    assert phonenumbers.is_valid_number(phonenumbers.parse(e164))
    legacy_uid = insert_user(national)                     # old builds assumed China for this
    r = login_phone(client, e164)
    assert r.status_code == 200, r.text
    assert r.json()["user_id"] != legacy_uid
    assert r.json()["is_new_user"] is True
    assert stored_phone(legacy_uid) == national             # untouched


def test_legacy_row_with_country_code_matches_outside_china(client):
    national = "74001" + "".join(random.choices("0123456789", k=5))
    uid = insert_user(f"44 {national[:4]} {national[4:]}")
    r = login_phone(client, "+44" + national)
    assert r.json()["user_id"] == uid
    assert stored_phone(uid) == "+44" + national


def test_collision_with_existing_e164_row_is_not_rewritten_or_merged(client, caplog):
    e164 = random_cn_mobile()
    old = datetime.now(timezone.utc) - timedelta(days=30)
    legacy_uid = insert_user(e164[3:], created_at=old)     # older row, legacy format
    e164_uid = insert_user(e164)                           # newer row, already E.164
    with caplog.at_level(logging.WARNING, logger="auth"):
        r = login_phone(client, e164)
    assert r.json()["user_id"] == e164_uid                 # existing E.164 match wins
    assert stored_phone(legacy_uid) == e164[3:]            # not rewritten
    assert stored_phone(e164_uid) == e164
    assert any("collision" in m and legacy_uid in m for m in caplog.messages)
    assert e164 not in " ".join(caplog.messages)           # number is masked in logs


def test_several_legacy_rows_use_the_oldest_without_rewriting(client, caplog):
    e164 = random_cn_mobile()
    older = insert_user(e164[3:], created_at=datetime.now(timezone.utc) - timedelta(days=9))
    newer = insert_user(e164[1:], created_at=datetime.now(timezone.utc) - timedelta(days=1))
    with caplog.at_level(logging.WARNING, logger="auth"):
        r = login_phone(client, e164)
    assert r.json()["user_id"] == older
    assert (stored_phone(older), stored_phone(newer)) == (e164[3:], e164[1:])
    assert any("several legacy rows" in m for m in caplog.messages)


# ── rate limits → 429 ─────────────────────────────────────────────────────────

@pytest.mark.parametrize("endpoint,field,value", [
    ("/auth/phone/send", "phone", None),
    ("/auth/email/send", "email", None),
])
def test_same_destination_twice_within_a_minute_returns_429(client, endpoint, field, value):
    value = random_cn_mobile() if field == "phone" else f"rl-{uuid.uuid4().hex[:8]}@example.com"
    assert client.post(endpoint, json={field: value}).status_code == 200
    # a different formatting of the same destination counts as the same destination
    again = value.upper() if field == "email" else f"{value[:3]} {value[3:]}"
    r = client.post(endpoint, json={field: again})
    assert r.status_code == 429, r.text
    assert r.json() == {"detail": MSG_TOO_MANY}
    assert 1 <= int(r.headers["Retry-After"]) <= 60


def test_destination_allowed_again_after_60_seconds(client, monkeypatch):
    import clock
    t0 = datetime(2026, 10, 27, 12, 0, tzinfo=timezone.utc)
    phone = random_cn_mobile()
    monkeypatch.setattr(clock, "now_utc", lambda: t0)
    assert client.post("/auth/phone/send", json={"phone": phone}).status_code == 200
    monkeypatch.setattr(clock, "now_utc", lambda: t0 + timedelta(seconds=59))
    assert client.post("/auth/phone/send", json={"phone": phone}).status_code == 429
    monkeypatch.setattr(clock, "now_utc", lambda: t0 + timedelta(seconds=60))
    assert client.post("/auth/phone/send", json={"phone": phone}).status_code == 200


def test_per_ip_limit_returns_429(client, fresh_limits, monkeypatch):
    monkeypatch.setattr(fresh_limits, "IP_RULES",
                        [(fresh_limits.MINUTE, 5), (fresh_limits.HOUR, 20)])   # production defaults
    for i in range(5):
        r = client.post("/auth/email/send", json={"email": f"ip{i}-{uuid.uuid4().hex[:6]}@example.com"})
        assert r.status_code == 200, r.text
    r = client.post("/auth/email/send", json={"email": f"ip6-{uuid.uuid4().hex[:6]}@example.com"})
    assert r.status_code == 429
    assert r.json() == {"detail": MSG_TOO_MANY}


def test_invalid_input_does_not_use_rate_limit_quota(client):
    for _ in range(3):
        assert client.post("/auth/phone/send", json={"phone": "+86 123"}).status_code == 422
    assert client.post("/auth/phone/send", json={"phone": random_cn_mobile()}).status_code == 200
