"""
Timezone rule tests with a frozen clock, against a real Postgres database.

The app runs in-process (FastAPI TestClient) so clock.now_utc() can be frozen at exact
instants — e.g. 23:30 in New York, when the UTC date is already tomorrow, and 01:30 on the
2026-11-01 DST change, which happens twice. Every request carries X-Timezone, like the app.

Skipped unless INTEGRATION_DATABASE_URL points at a disposable database:
  INTEGRATION_DATABASE_URL=postgresql://mirror:mirror@localhost:5432/3dmirror_test \
  pytest tests/integration/test_timezone_rules.py -v
"""

import asyncio
import os
import sys
import uuid
from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import asyncpg
import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

DB_URL = os.getenv("INTEGRATION_DATABASE_URL")
EXPECTED_DB = "3dmirror_test"

pytestmark = pytest.mark.skipif(
    not DB_URL, reason="INTEGRATION_DATABASE_URL not set; needs a disposable Postgres database")

NY = ZoneInfo("America/New_York")
UTC = timezone.utc


def ny(*args) -> datetime:
    """A New York wall-clock time. fold=1 picks the second (EST) 01:30 on 2026-11-01."""
    *parts, fold = args if len(args) == 6 else (*args, 0)
    return datetime(*parts, tzinfo=NY, fold=fold).astimezone(UTC)


# 2026-10-12 23:30 EDT == 2026-10-13 03:30 UTC: local date and UTC date differ.
LATE_NIGHT = ny(2026, 10, 12, 23, 30)
# 2026-11-01 01:30 happens twice in New York: 05:30 UTC (EDT) and, an hour later, 06:30 UTC (EST).
DST_FIRST_0130 = ny(2026, 11, 1, 1, 30, 0)
DST_SECOND_0130 = ny(2026, 11, 1, 1, 30, 1)


def db_fetch(sql: str, *args):
    async def run():
        conn = await asyncpg.connect(DB_URL)
        try:
            return await conn.fetch(sql, *args)
        finally:
            await conn.close()
    return asyncio.run(run())


@pytest.fixture(scope="module")
def client():
    from fastapi.testclient import TestClient

    assert db_fetch("SELECT current_database() AS db")[0]["db"] == EXPECTED_DB, \
        f"refusing to run: INTEGRATION_DATABASE_URL must point at {EXPECTED_DB}"

    with pytest.MonkeyPatch.context() as mp:
        mp.setenv("DATABASE_URL", DB_URL)
        import main
        import auth.service
        mp.setattr(auth.service, "DEV_MODE", True)   # fixed OTP 123456, no SMS/email
        with TestClient(main.app) as c:
            yield c


@pytest.fixture(autouse=True)
def fresh_send_limits(monkeypatch):
    """Every test logs in a new user from the same test IP: reset counters, lift the IP limit."""
    from auth import rate_limit
    rate_limit.reset()
    monkeypatch.setattr(rate_limit, "IP_RULES", [(rate_limit.MINUTE, 1000), (rate_limit.HOUR, 1000)])
    yield
    rate_limit.reset()


@pytest.fixture
def freeze(monkeypatch):
    import clock

    def _freeze(instant: datetime):
        assert instant.tzinfo is not None
        monkeypatch.setattr(clock, "now_utc", lambda: instant)
    return _freeze


@pytest.fixture
def user(client):
    """A new user per test. Returns (headers, user_id)."""
    email = f"tz-{uuid.uuid4().hex[:12]}@example.com"
    tzh = {"X-Timezone": "America/New_York"}
    assert client.post("/auth/email/send", json={"email": email}, headers=tzh).status_code == 200
    r = client.post("/auth/email/verify", json={"email": email, "code": "123456"}, headers=tzh)
    assert r.status_code == 200, r.text
    body = r.json()
    return {"Authorization": f"Bearer {body['token']}", **tzh}, body["user_id"]


def session_payload(weight_kg: float = 62.5) -> dict:
    return {
        "user_id": "ignored",
        "body_data": {"weight_kg": weight_kg, "body_fat_pct": 24.0, "waist_cm": 72.0},
        "avatar_params": {
            "height_norm": 0.3, "weight_norm": 0.25, "body_fat_norm": 0.26, "waist_norm": 0.23,
            "hip_norm": 0.48, "shoulder_norm": 0.38, "muscle_norm": 0.35, "gender": "female"},
    }


# ── 23:30 America/New_York: stored under the local date, not the UTC date ────

def test_late_night_period_default_date_is_local(client, freeze, user):
    headers, uid = user
    freeze(LATE_NIGHT)
    r = client.post("/logs/period", json={"phase": "start", "symptoms": [], "intensity": 2},
                    headers=headers)
    assert r.status_code == 201, r.text
    rows = db_fetch("SELECT date FROM period_logs WHERE user_id = $1", uuid.UUID(uid))
    assert [row["date"] for row in rows] == [date(2026, 10, 12)]   # UTC date would be 10-13


def test_late_night_measurements_default_date_is_local(client, freeze, user):
    headers, uid = user
    freeze(LATE_NIGHT)
    r = client.put("/logs/measurements", json={"weight_kg": 61.8}, headers=headers)
    assert r.status_code == 200, r.text
    assert r.json()["date"] == "2026-10-12"
    rows = db_fetch("SELECT date FROM body_snapshots WHERE user_id = $1", uuid.UUID(uid))
    assert [row["date"] for row in rows] == [date(2026, 10, 12)]


def test_late_night_explicit_dates_are_kept(client, freeze, user):
    """Client-sent local dates are stored as sent, whatever the UTC date is."""
    headers, uid = user
    freeze(LATE_NIGHT)
    r = client.post("/logs/period", json={"date": "2026-10-12", "phase": "end",
                                          "symptoms": [], "intensity": 1}, headers=headers)
    assert r.status_code == 201, r.text
    r = client.put("/logs/measurements", json={"date": "2026-10-12", "waist_cm": 71.0},
                   headers=headers)
    assert r.json()["date"] == "2026-10-12"


def test_late_night_sleep_stored_under_local_date_with_correct_instants(client, freeze, user):
    headers, uid = user
    freeze(LATE_NIGHT)
    payload = {"date": "2026-10-12",
               "bedtime": "2026-10-12T23:30:00-04:00",      # offset-aware, as the app now sends
               "wake_time": "2026-10-13T11:00:00Z",         # 07:00 EDT, sent as UTC
               "quality": 4}
    r = client.post("/logs/sleep", json=payload, headers=headers)
    assert r.status_code == 201, r.text
    row = db_fetch("SELECT date, bedtime, wake_time FROM sleep_logs WHERE user_id = $1",
                   uuid.UUID(uid))[0]
    assert row["date"] == date(2026, 10, 12)
    assert row["bedtime"] == datetime(2026, 10, 13, 3, 30, tzinfo=UTC)
    assert row["wake_time"] == datetime(2026, 10, 13, 11, 0, tzinfo=UTC)


def test_late_night_today_stats_uses_local_day(client, freeze, user):
    headers, _ = user
    # Logged at 19:00 New York (23:00 UTC, still 10-12 in UTC) and at 23:30 New York
    # (03:30 UTC on 10-13). Both are "today" for the user at 23:30 New York.
    freeze(ny(2026, 10, 12, 19, 0))
    assert client.post("/logs/diet", json={"meal": "晚餐", "food_name": "三文鱼",
                                           "calories": 400.0}, headers=headers).status_code == 201
    freeze(LATE_NIGHT)
    assert client.post("/logs/diet", json={"meal": "加餐", "food_name": "酸奶",
                                           "calories": 120.0}, headers=headers).status_code == 201
    assert client.post("/logs/workout", json={"type": "有氧", "sub_type": "跑步",
                                              "duration_min": 30, "intensity": "medium"},
                       headers=headers).status_code == 201
    assert client.post("/logs/sleep", json={"date": "2026-10-12",
                                            "bedtime": "2026-10-11T23:00:00-04:00",
                                            "wake_time": "2026-10-12T06:30:00-04:00",
                                            "quality": 4}, headers=headers).status_code == 201

    r = client.get("/logs/today-stats", headers=headers)
    assert r.status_code == 200, r.text
    assert r.json() == {"total_kcal_in": 520.0, "sleep_hours": 7.5, "workout_minutes": 30}

    # 00:30 New York on 10-13 is a new local day: nothing logged yet.
    freeze(ny(2026, 10, 13, 0, 30))
    r = client.get("/logs/today-stats", headers=headers)
    assert r.json() == {"total_kcal_in": 0.0, "sleep_hours": 0.0, "workout_minutes": 0}


def test_late_night_session_created_at_is_exact_instant(client, freeze, user):
    headers, uid = user
    freeze(LATE_NIGHT)
    r = client.post("/sessions", json=session_payload(), headers=headers)
    assert r.status_code == 200, r.text
    assert datetime.fromisoformat(r.json()["created_at"]) == LATE_NIGHT
    row = db_fetch("SELECT created_at FROM sessions WHERE user_id = $1", uuid.UUID(uid))[0]
    assert row["created_at"] == datetime(2026, 10, 13, 3, 30, tzinfo=UTC)


def test_late_night_challenge_baseline_and_days_use_local_dates(client, freeze, user):
    headers, _ = user
    freeze(LATE_NIGHT)                                   # baseline session, local day 10-12
    assert client.post("/sessions", json=session_payload(62.5), headers=headers).status_code == 200
    r = client.post("/challenge/goal", json={"goal_type": "weight", "target_weight_kg": 60.0,
                                             "start_date": "2026-10-12",
                                             "end_date": "2026-10-22"}, headers=headers)
    assert r.status_code == 200, r.text

    r = client.get("/challenge/progress", headers=headers)
    assert r.status_code == 200, r.text
    assert r.json()["days_remaining"] == 10              # UTC date (10-13) would give 9

    freeze(ny(2026, 10, 14, 12, 0))
    assert client.post("/sessions", json=session_payload(61.5), headers=headers).status_code == 200
    body = client.get("/challenge/progress", headers=headers).json()
    # Baseline found on local 10-12 (62.5 kg) → (62.5-61.5)/(62.5-60) = 40 %.
    # A UTC-date lookup would miss it, fall back to the current weight, and report 0 %.
    assert body["progress_pct"] == 40.0
    assert body["days_remaining"] == 8


def test_coach_counts_training_days_in_local_calendar(client, freeze, user):
    headers, _ = user
    freeze(LATE_NIGHT)                                   # 10-12 local, 10-13 UTC
    assert client.post("/sessions", json=session_payload(), headers=headers).status_code == 200
    freeze(ny(2026, 10, 13, 0, 30))                      # 10-13 local, 10-13 UTC
    assert client.post("/sessions", json=session_payload(), headers=headers).status_code == 200
    freeze(ny(2026, 10, 13, 12, 0))
    r = client.get("/coach/suggestions", headers=headers)
    assert r.status_code == 200, r.text
    titles = [c["title"] for c in r.json()["cards"] if c["category"] == "training"]
    assert titles == ["本周已训练 2 天"]                   # UTC days would count 1


# ── DST: 01:30 on 2026-11-01 happens twice in New York ───────────────────────

def test_dst_0130_both_occurrences_map_to_local_nov_1(client, freeze, user):
    headers, uid = user
    assert DST_SECOND_0130 - DST_FIRST_0130 == timedelta(hours=1)

    freeze(DST_FIRST_0130)                               # 01:30 EDT = 05:30 UTC
    r1 = client.post("/logs/period", json={"phase": "start", "symptoms": [], "intensity": 1},
                     headers=headers)
    assert r1.status_code == 201, r1.text
    assert client.put("/logs/measurements", json={"weight_kg": 60.0},
                      headers=headers).json()["date"] == "2026-11-01"
    assert client.post("/logs/diet", json={"meal": "加餐", "food_name": "牛奶",
                                           "calories": 100.0}, headers=headers).status_code == 201

    freeze(DST_SECOND_0130)                              # 01:30 EST = 06:30 UTC, same local day
    r2 = client.post("/logs/period", json={"phase": "ongoing", "symptoms": [], "intensity": 2},
                     headers=headers)
    assert r2.status_code == 200, r2.text                # same local date → upsert, not new row
    assert r2.json()["id"] == r1.json()["id"]
    assert client.post("/logs/diet", json={"meal": "加餐", "food_name": "饼干",
                                           "calories": 50.0}, headers=headers).status_code == 201

    rows = db_fetch("SELECT date, phase FROM period_logs WHERE user_id = $1", uuid.UUID(uid))
    assert [(r["date"], r["phase"]) for r in rows] == [(date(2026, 11, 1), "ongoing")]
    logged = db_fetch("SELECT logged_at FROM diet_logs WHERE user_id = $1 ORDER BY logged_at",
                      uuid.UUID(uid))
    assert [r["logged_at"] for r in logged] == [
        datetime(2026, 11, 1, 5, 30, tzinfo=UTC), datetime(2026, 11, 1, 6, 30, tzinfo=UTC)]

    r = client.get("/logs/today-stats", headers=headers)
    assert r.json()["total_kcal_in"] == 150.0


def test_dst_sleep_duration_spans_the_repeated_hour(client, freeze, user):
    headers, _ = user
    freeze(ny(2026, 11, 1, 9, 0))
    # 00:30 EDT → 06:30 EST is 7 hours of real time (wall clock shows 6).
    r = client.post("/logs/sleep", json={"date": "2026-11-01",
                                         "bedtime": "2026-11-01T00:30:00-04:00",
                                         "wake_time": "2026-11-01T06:30:00-05:00",
                                         "quality": 3}, headers=headers)
    assert r.status_code == 201, r.text
    assert client.get("/logs/today-stats", headers=headers).json()["sleep_hours"] == 7.0
