"""
Photo analysis routes against real Postgres: results are stored in body_analyses and returned.

Runs the app in-process (FastAPI TestClient) with a fake Anthropic client (no network, no cost)
and uploads redirected to a temporary directory. Skipped unless INTEGRATION_DATABASE_URL points
at the disposable 3dmirror_test database:
  INTEGRATION_DATABASE_URL=postgresql://mirror:mirror@localhost:5432/3dmirror_test \
  pytest tests/integration/test_photo_analysis_api.py -v
"""

import asyncio
import os
import sys
import uuid
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import anthropic
import asyncpg
import httpx
import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

DB_URL = os.getenv("INTEGRATION_DATABASE_URL")
EXPECTED_DB = "3dmirror_test"

pytestmark = pytest.mark.skipif(
    not DB_URL, reason="INTEGRATION_DATABASE_URL not set; needs a disposable Postgres database")

JPEG = b"\xff\xd8\xff\xe0" + b"\x00" * 64
HEIC = b"\x00\x00\x00\x18ftypheic\x00\x00\x00\x00mif1heic" + b"\x00" * 16
GOOD_REPLY = '{"shoulder_width_norm": 0.42, "waist_norm": 0.3, "hip_norm": 0.55, "limb_proportion_norm": 0.6}'


def db(sql: str, *args):
    async def run():
        conn = await asyncpg.connect(DB_URL)
        try:
            return await conn.fetch(sql, *args)
        finally:
            await conn.close()
    return asyncio.run(run())


class FakeClient:
    calls: list = []
    result = None

    def __init__(self, **kwargs):
        self.messages = SimpleNamespace(create=self._create)

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc):
        return False

    async def _create(self, **kwargs):
        FakeClient.calls.append(kwargs)
        if isinstance(FakeClient.result, Exception):
            raise FakeClient.result
        return FakeClient.result


def reply(text: str):
    return SimpleNamespace(stop_reason="end_turn", content=[SimpleNamespace(type="text", text=text)])


# ── fixtures ──────────────────────────────────────────────────────────────────

@pytest.fixture(scope="module")
def client(tmp_path_factory):
    from fastapi.testclient import TestClient

    assert db("SELECT current_database() AS d")[0]["d"] == EXPECTED_DB, \
        f"refusing to run: INTEGRATION_DATABASE_URL must point at {EXPECTED_DB}"
    assert db("SELECT to_regclass('body_analyses') AS t")[0]["t"] is not None, \
        "apply backend/migration.sql to 3dmirror_test first (body_analyses is missing)"
    with pytest.MonkeyPatch.context() as mp:
        mp.setenv("DATABASE_URL", DB_URL)
        import main
        import auth.service
        from services import photo_service
        mp.setattr(auth.service, "DEV_MODE", True)
        mp.setattr(photo_service, "UPLOAD_DIR", tmp_path_factory.mktemp("uploads"))
        with TestClient(main.app) as c:
            yield c


@pytest.fixture(autouse=True)
def fresh_limits(monkeypatch):
    from auth import rate_limit
    rate_limit.reset()
    monkeypatch.setattr(rate_limit, "IP_RULES", [(rate_limit.MINUTE, 1000), (rate_limit.HOUR, 1000)])
    yield
    rate_limit.reset()


@pytest.fixture
def fake_claude(monkeypatch):
    from services import llm_service
    monkeypatch.setenv("ANTHROPIC_API_KEY", "test-key")
    monkeypatch.setattr(llm_service.anthropic, "AsyncAnthropic", FakeClient)
    FakeClient.calls = []
    FakeClient.result = reply(GOOD_REPLY)
    return FakeClient


@pytest.fixture
def user(client):
    email = f"pa-{uuid.uuid4().hex[:12]}@example.com"
    assert client.post("/auth/email/send", json={"email": email}).status_code == 200
    r = client.post("/auth/email/verify", json={"email": email, "code": "123456"})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['token']}"}, r.json()["user_id"]


def upload(client, headers, **files) -> list[str]:
    parts = {angle: (f"{angle}.jpg", data, ctype) for angle, (data, ctype) in files.items()}
    r = client.post("/photos/upload", files=parts, headers=headers)
    assert r.status_code == 200, r.text
    return r.json()["photo_ids"]


def analyze(client, headers, ids):
    return client.post("/photos/analyze", data={"photo_ids": ids}, headers=headers)


# ── tests ─────────────────────────────────────────────────────────────────────

def test_latest_is_404_before_any_analysis(client, user):
    headers, _ = user
    r = client.get("/photos/analysis/latest", headers=headers)
    assert r.status_code == 404
    assert r.json() == {"detail": "尚无体型分析结果"}


def test_ok_result_is_stored_and_returned(client, user, fake_claude):
    headers, uid = user
    ids = upload(client, headers, front=(JPEG, "image/jpeg"), side=(JPEG, "image/jpeg"))
    before = datetime.now(timezone.utc)
    r = analyze(client, headers, ids)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["status"] == "ok"
    assert (body["shoulder_width_norm"], body["waist_norm"], body["hip_norm"],
            body["limb_proportion_norm"]) == (0.42, 0.3, 0.55, 0.6)
    assert sorted(body["photo_ids"]) == sorted(ids)
    assert body["model"] and body["detail"] is None
    created = datetime.fromisoformat(body["created_at"])
    assert created.tzinfo is not None
    assert before - timedelta(seconds=5) <= created <= datetime.now(timezone.utc) + timedelta(seconds=5)

    row = db("SELECT * FROM body_analyses WHERE id = $1", uuid.UUID(body["id"]))[0]
    assert str(row["user_id"]) == uid and row["status"] == "ok"
    assert row["shoulder_width_norm"] == 0.42 and row["limb_proportion_norm"] == 0.6

    latest = client.get("/photos/analysis/latest", headers=headers).json()
    assert latest == body


def test_llm_analysis_column_is_no_longer_written(client, user, fake_claude):
    headers, _ = user
    ids = upload(client, headers, front=(JPEG, "image/jpeg"))
    assert analyze(client, headers, ids).json()["status"] == "ok"
    rows = db("SELECT llm_analysis FROM body_photos WHERE id = ANY($1::uuid[])", ids)
    assert [r["llm_analysis"] for r in rows] == [None]


def test_no_api_key_is_stored_as_unavailable(client, user, monkeypatch):
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)
    headers, _ = user
    ids = upload(client, headers, front=(JPEG, "image/jpeg"))
    r = analyze(client, headers, ids)
    assert r.status_code == 200, r.text
    body = r.json()
    assert (body["status"], body["model"], body["shoulder_width_norm"]) == ("unavailable", None, None)
    assert "ANTHROPIC_API_KEY" in body["detail"]


def test_api_error_is_stored_as_failed_not_500(client, user, fake_claude):
    req = httpx.Request("POST", "https://api.anthropic.com/v1/messages")
    fake_claude.result = anthropic.InternalServerError(
        "overloaded", response=httpx.Response(529, request=req), body=None)
    headers, _ = user
    ids = upload(client, headers, front=(JPEG, "image/jpeg"))
    r = analyze(client, headers, ids)
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "failed"
    assert r.json()["detail"] == "API error 529 (InternalServerError)"
    assert db("SELECT count(*) AS n FROM body_analyses WHERE id = $1",
              uuid.UUID(r.json()["id"]))[0]["n"] == 1


def test_heic_only_upload_fails_without_calling_the_api(client, user, fake_claude):
    headers, _ = user
    ids = upload(client, headers, front=(HEIC, "image/heic"))
    body = analyze(client, headers, ids).json()
    assert body["status"] == "failed" and "HEIC/HEIF" in body["detail"]
    assert fake_claude.calls == []


def test_latest_status_filter_skips_newer_failures(client, user, fake_claude):
    headers, _ = user
    ok = analyze(client, headers, upload(client, headers, front=(JPEG, "image/jpeg"))).json()
    fake_claude.result = reply("sorry, no")
    failed = analyze(client, headers, upload(client, headers, front=(JPEG, "image/jpeg"))).json()
    assert failed["status"] == "failed"

    assert client.get("/photos/analysis/latest", headers=headers).json()["id"] == failed["id"]
    assert client.get("/photos/analysis/latest?status=ok", headers=headers).json()["id"] == ok["id"]
    assert client.get("/photos/analysis/latest?status=bogus", headers=headers).status_code == 422


def test_users_cannot_analyze_or_see_each_others_photos(client, fake_claude):
    def login():
        email = f"pa-{uuid.uuid4().hex[:12]}@example.com"
        client.post("/auth/email/send", json={"email": email})
        r = client.post("/auth/email/verify", json={"email": email, "code": "123456"})
        return {"Authorization": f"Bearer {r.json()['token']}"}
    alice, bob = login(), login()
    ids = upload(client, alice, front=(JPEG, "image/jpeg"))
    assert analyze(client, alice, ids).status_code == 200

    r = analyze(client, bob, ids)
    assert r.status_code == 404 and r.json() == {"detail": "未找到对应的照片"}
    assert client.get("/photos/analysis/latest", headers=bob).status_code == 404


def test_malformed_photo_id_returns_422(client, user):
    headers, _ = user
    r = analyze(client, headers, ["not-a-uuid"])
    assert r.status_code == 422 and r.json() == {"detail": "照片编号格式不正确"}
