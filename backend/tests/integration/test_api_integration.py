"""
Integration tests against a running backend + real Postgres.

These hit a live server over HTTP (no mocks). They are skipped unless
INTEGRATION_BASE_URL is set. The server must run with DEV_MODE=true so the
fixed OTP 123456 works, and must point at a disposable database, never the
real one.

Run:
  # terminal 1 (from backend/)
  DATABASE_URL=postgresql://mirror:mirror@localhost:5432/3dmirror_test \
  DEV_MODE=true uvicorn main:app --port 8765
  # terminal 2 (from backend/)
  INTEGRATION_BASE_URL=http://127.0.0.1:8765 pytest tests/integration -v

Payload shapes mirror what the Flutter client sends (see lib/models/*.dart
toJson()), including extra fields the server is expected to ignore.
"""

import os
import uuid
from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import httpx
import pytest

BASE_URL = os.getenv("INTEGRATION_BASE_URL")

# The simulated user lives in New York; every request carries this, like the Flutter client.
USER_TZ = "America/New_York"


def user_today() -> date:
    return datetime.now(ZoneInfo(USER_TZ)).date()

pytestmark = pytest.mark.skipif(
    not BASE_URL, reason="INTEGRATION_BASE_URL not set; integration tests need a live server"
)


def _describe(r: httpx.Response) -> str:
    return f"{r.request.method} {r.request.url.path} -> {r.status_code}: {r.text[:300]}"


@pytest.fixture(scope="module")
def client():
    with httpx.Client(base_url=BASE_URL, timeout=15) as c:
        yield c


def _login(client: httpx.Client) -> dict:
    """Log in a brand-new user via email OTP (DEV_MODE code 123456)."""
    email = f"it-{uuid.uuid4().hex[:12]}@example.com"
    tzh = {"X-Timezone": USER_TZ}
    r = client.post("/auth/email/send", json={"email": email}, headers=tzh)
    assert r.status_code == 200, _describe(r)
    r = client.post("/auth/email/verify", json={"email": email, "code": "123456"}, headers=tzh)
    assert r.status_code == 200, _describe(r)
    body = r.json()
    assert body["is_new_user"] is True
    return {"Authorization": f"Bearer {body['token']}", "X-User-Id": body["user_id"],
            "X-Timezone": USER_TZ, "_user_id": body["user_id"]}


@pytest.fixture(scope="module")
def auth(client):
    h = _login(client)
    h.pop("_user_id")
    return h


@pytest.fixture
def fresh_auth(client):
    """A separate user per test, for tests that depend on per-day uniqueness."""
    h = _login(client)
    h.pop("_user_id")
    return h


# ── Sanity ────────────────────────────────────────────────────────────────────

def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200, _describe(r)


# ── Session save flow (InputScreen._submit → POST /sessions → ResultScreen) ──

def _session_payload(user_id: str = "ignored-by-server") -> dict:
    now = datetime.now().isoformat()
    return {
        "id": str(int(datetime.now().timestamp() * 1000)),
        "user_id": user_id,
        "created_at": now,
        "body_data": {
            "id": "x", "user_id": user_id, "date": now,
            "weight_kg": 62.5, "body_fat_pct": 24.0, "waist_cm": 72.0,
            "hip_cm": None, "lean_mass_kg": 47.5, "fat_mass_kg": 15.0,
        },
        "avatar_params": {
            "height_norm": 0.3, "weight_norm": 0.25, "body_fat_norm": 0.26,
            "waist_norm": 0.23, "hip_norm": 0.48, "shoulder_norm": 0.38,
            "muscle_norm": 0.35, "gender": "female",
            "lighting_profile": "studio_minimal", "photo_enhanced": False,
        },
        "activity_data": {
            "id": "x", "user_id": user_id, "date": now,
            "workout_type": "cardio", "duration_min": 30, "intensity": "medium",
            "steps": None,
        },
        "thumbnail_url": None,
        "photo_ids": [],
    }


def test_session_create(client, auth):
    r = client.post("/sessions", json=_session_payload(), headers=auth)
    assert r.status_code == 200, _describe(r)
    body = r.json()
    assert body["body_data"]["weight_kg"] == 62.5
    assert body["avatar_params"]["gender"] == "female"


def test_session_list_and_get_roundtrip(client, fresh_auth):
    r = client.post("/sessions", json=_session_payload(), headers=fresh_auth)
    assert r.status_code == 200, _describe(r)
    sid = r.json()["id"]

    r = client.get("/sessions", headers=fresh_auth)
    assert r.status_code == 200, _describe(r)
    assert [s["id"] for s in r.json()] == [sid]

    r = client.get(f"/sessions/{sid}", headers=fresh_auth)
    assert r.status_code == 200, _describe(r)
    assert r.json()["body_data"]["waist_cm"] == 72.0


# ── Log endpoints (Home FAB log sheets) ──────────────────────────────────────

def test_log_workout_cardio(client, auth):
    payload = {
        "type": "有氧", "sub_type": "跑步", "duration_min": 30, "intensity": "medium",
        "with_weight": False, "estimated_kcal": 300,
    }
    r = client.post("/logs/workout", json=payload, headers=auth)
    assert r.status_code == 201, _describe(r)


def test_log_workout_strength_with_sets(client, auth):
    payload = {
        "type": "无氧", "sub_type": "深蹲", "duration_min": 0, "intensity": "high",
        "with_weight": True, "weight_kg": 40.0, "muscle_group": "腿部",
        "sets": [{"reps": 10, "weight_kg": 40.0, "is_drop_set": False},
                 {"reps": 8, "weight_kg": 45.0, "is_drop_set": False}],
    }
    r = client.post("/logs/workout", json=payload, headers=auth)
    assert r.status_code == 201, _describe(r)


def test_log_diet(client, auth):
    payload = {
        "meal": "午餐", "food_name": "鸡胸肉", "calories": 165.0, "grams": 100.0,
        "protein_g": 31.0, "carbs_g": 0.0, "fat_g": 3.6, "entry_method": "search",
    }
    r = client.post("/logs/diet", json=payload, headers=auth)
    assert r.status_code == 201, _describe(r)


def _utc_z(d: datetime) -> str:
    """Like Dart's DateTime.toUtc().toIso8601String(): '2026-10-13T03:30:00.000Z'."""
    return d.astimezone(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def _sleep_payload() -> dict:
    # SleepLogSheet._doSave: local wall times sent as UTC instants, date = local wake day
    tz = ZoneInfo(USER_TZ)
    today = user_today()
    bed = datetime.combine(today - timedelta(days=1), datetime.min.time(), tz) + timedelta(hours=23)
    wake = bed + timedelta(hours=8)
    return {
        "date": today.isoformat(),
        "bedtime": _utc_z(bed),
        "wake_time": _utc_z(wake),
        "quality": 4, "source": "manual",
    }


def test_log_sleep(client, fresh_auth):
    r = client.post("/logs/sleep", json=_sleep_payload(), headers=fresh_auth)
    assert r.status_code == 201, _describe(r)


def test_log_sleep_twice_same_day_upserts(client, fresh_auth):
    first = client.post("/logs/sleep", json=_sleep_payload(), headers=fresh_auth)
    assert first.status_code == 201, _describe(first)
    second = client.post("/logs/sleep", json={**_sleep_payload(), "quality": 2},
                         headers=fresh_auth)
    assert second.status_code == 200, _describe(second)
    assert second.json()["id"] == first.json()["id"]


def test_log_period(client, fresh_auth):
    payload = {"phase": "start", "symptoms": ["痛经", "疲劳"], "intensity": 2}
    r = client.post("/logs/period", json=payload, headers=fresh_auth)
    assert r.status_code == 201, _describe(r)


def test_log_period_twice_same_day_upserts(client, fresh_auth):
    payload = {"phase": "ongoing", "symptoms": [], "intensity": 1}
    first = client.post("/logs/period", json=payload, headers=fresh_auth)
    assert first.status_code == 201, _describe(first)
    second = client.post("/logs/period", json={**payload, "phase": "end", "intensity": 3},
                         headers=fresh_auth)
    assert second.status_code == 200, _describe(second)
    assert second.json()["id"] == first.json()["id"]


def test_session_bad_token_returns_401_before_body_validation(client):
    r = client.post("/sessions", json={}, headers={"Authorization": "Bearer bad"})
    assert r.status_code == 401, _describe(r)


def test_log_supplements_without_reminder(client, auth):
    payload = [{"name": "维生素D", "reminder_enabled": False},
               {"name": "鱼油", "dosage": "1粒", "reminder_enabled": False}]
    r = client.post("/logs/supplements", json=payload, headers=auth)
    assert r.status_code == 201, _describe(r)
    assert r.json()["count"] == 2


def test_log_supplements_with_reminder(client, auth):
    # SupplementLogSheet sends reminder_time as 'HH:MM'
    payload = [{"name": "维生素C", "reminder_time": "08:00", "reminder_enabled": True}]
    r = client.post("/logs/supplements", json=payload, headers=auth)
    assert r.status_code == 201, _describe(r)


def test_update_measurements(client, fresh_auth):
    r = client.put("/logs/measurements", json={"weight_kg": 61.8, "waist_cm": 71.5},
                   headers=fresh_auth)
    assert r.status_code == 200, _describe(r)
    # Same day again should merge, not fail
    r = client.put("/logs/measurements", json={"hip_cm": 95.0}, headers=fresh_auth)
    assert r.status_code == 200, _describe(r)


def test_log_period_with_explicit_date(client, fresh_auth):
    payload = {"date": (user_today() - timedelta(days=3)).isoformat(),
               "phase": "end", "symptoms": [], "intensity": 1}
    r = client.post("/logs/period", json=payload, headers=fresh_auth)
    assert r.status_code == 201, _describe(r)


# ── Validation at the API boundary: bad formats → 422, not 500 ───────────────

@pytest.mark.parametrize("bad_date", ["2026-13-01", "10/10/2026", "not-a-date", ""])
def test_log_sleep_invalid_date_returns_422(client, auth, bad_date):
    payload = {**_sleep_payload(), "date": bad_date}
    r = client.post("/logs/sleep", json=payload, headers=auth)
    assert r.status_code == 422, _describe(r)


@pytest.mark.parametrize("bad_time", ["25:00", "8am", "08:61", "tomorrow"])
def test_log_supplements_invalid_time_returns_422(client, auth, bad_time):
    payload = [{"name": "维生素C", "reminder_time": bad_time, "reminder_enabled": True}]
    r = client.post("/logs/supplements", json=payload, headers=auth)
    assert r.status_code == 422, _describe(r)


def test_log_period_invalid_date_returns_422(client, auth):
    payload = {"date": "2026-02-30", "phase": "start", "symptoms": [], "intensity": 1}
    r = client.post("/logs/period", json=payload, headers=auth)
    assert r.status_code == 422, _describe(r)


# ── JSONB round-trips through every endpoint that reads/writes JSON columns ──

def test_predict_and_coach_read_session_json(client, fresh_auth):
    for _ in range(2):
        r = client.post("/sessions", json=_session_payload(), headers=fresh_auth)
        assert r.status_code == 200, _describe(r)
    r = client.get("/predict?weeks=4", headers=fresh_auth)
    assert r.status_code == 200, _describe(r)
    assert r.json()["data_points"] == 2
    r = client.get("/coach/suggestions", headers=fresh_auth)
    assert r.status_code == 200, _describe(r)
    assert r.json()["data_points"] == 2


def test_coach_target_roundtrip_via_users_me(client, fresh_auth):
    target = {k: v for k, v in _session_payload()["avatar_params"].items()
              if k not in ("lighting_profile", "photo_enhanced")}
    r = client.put("/coach/target", json=target, headers=fresh_auth)
    assert r.status_code == 200, _describe(r)
    r = client.get("/users/me", headers=fresh_auth)
    assert r.status_code == 200, _describe(r)
    assert r.json()["target_avatar_params"] == target


def test_challenge_goal_roundtrip(client, fresh_auth):
    r = client.post("/sessions", json=_session_payload(), headers=fresh_auth)
    assert r.status_code == 200, _describe(r)
    start = user_today()
    goal = {"goal_type": "weight", "target_weight_kg": 60.0,
            "start_date": start.isoformat(),
            "end_date": (start + timedelta(days=30)).isoformat()}
    r = client.post("/challenge/goal", json=goal, headers=fresh_auth)
    assert r.status_code == 200, _describe(r)
    r = client.get("/challenge/progress", headers=fresh_auth)
    assert r.status_code == 200, _describe(r)
    body = r.json()
    assert body["goal"]["start_date"] == goal["start_date"]
    assert body["goal"]["end_date"] == goal["end_date"]
    assert body["days_remaining"] == 30


def test_challenge_goal_invalid_date_returns_422(client, auth):
    goal = {"goal_type": "weight", "start_date": "yesterday", "end_date": "2026-99-01"}
    r = client.post("/challenge/goal", json=goal, headers=auth)
    assert r.status_code == 422, _describe(r)


def test_today_stats(client, fresh_auth):
    r = client.post("/logs/workout", json={
        "type": "有氧", "sub_type": "跳绳", "duration_min": 20, "intensity": "high",
        "with_weight": False}, headers=fresh_auth)
    assert r.status_code == 201, _describe(r)
    r = client.post("/logs/diet", json={
        "meal": "早餐", "food_name": "燕麦", "calories": 150.0}, headers=fresh_auth)
    assert r.status_code == 201, _describe(r)

    r = client.get("/logs/today-stats", headers=fresh_auth)
    assert r.status_code == 200, _describe(r)
    body = r.json()
    assert body["workout_minutes"] == 20
    assert body["total_kcal_in"] == 150.0


# ── Timezone rule on the live server (real clock) ────────────────────────────

def test_session_created_at_is_real_utc_instant(client, fresh_auth):
    before = datetime.now(timezone.utc)
    r = client.post("/sessions", json=_session_payload(), headers=fresh_auth)
    after = datetime.now(timezone.utc)
    assert r.status_code == 200, _describe(r)
    stored = datetime.fromisoformat(r.json()["created_at"])
    assert stored.tzinfo is not None, "created_at must carry an offset"
    # Must equal the real UTC time — not shifted by the server host's UTC offset.
    assert before - timedelta(seconds=2) <= stored <= after + timedelta(seconds=2), \
        f"stored {stored.isoformat()} not within [{before.isoformat()}, {after.isoformat()}]"
    r = client.get(f"/sessions/{r.json()['id']}", headers=fresh_auth)
    assert datetime.fromisoformat(r.json()["created_at"]) == stored


@pytest.mark.parametrize("method,path,body", [
    ("POST", "/logs/period", {"phase": "start", "symptoms": [], "intensity": 1}),
    ("PUT",  "/logs/measurements", {"weight_kg": 60.0}),
    ("GET",  "/logs/today-stats", None),
    ("GET",  "/challenge/progress", None),
    ("GET",  "/coach/suggestions", None),
])
@pytest.mark.parametrize("tz_header", [None, "Mars/Olympus_Mons", "EDT"])
def test_missing_or_unknown_timezone_returns_422(client, fresh_auth, method, path, body, tz_header):
    headers = {k: v for k, v in fresh_auth.items() if k != "X-Timezone"}
    if tz_header is not None:
        headers["X-Timezone"] = tz_header
    r = client.request(method, path, json=body, headers=headers)
    assert r.status_code == 422, _describe(r)
    assert "X-Timezone" in r.text


@pytest.mark.parametrize("field", ["bedtime", "wake_time"])
def test_sleep_naive_datetime_returns_422(client, fresh_auth, field):
    payload = _sleep_payload()
    payload[field] = "2026-10-12T23:30:00"   # no offset
    r = client.post("/logs/sleep", json=payload, headers=fresh_auth)
    assert r.status_code == 422, _describe(r)
