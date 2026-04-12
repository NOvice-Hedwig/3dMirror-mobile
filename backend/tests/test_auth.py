"""
Basic smoke tests for auth endpoints.
Run: pytest tests/ -v
Requires: pip install pytest httpx
"""

import pytest
from httpx import AsyncClient, ASGITransport
from unittest.mock import patch, AsyncMock

# Patch DB before importing app
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))


@pytest.fixture
def mock_db(monkeypatch):
    """Replace asyncpg pool with a simple mock."""
    class FakeRow(dict):
        def __getitem__(self, k): return super().__getitem__(k)

    class FakePool:
        async def fetchrow(self, *a): return None   # simulate new user
        async def execute(self, *a):  return None
        async def fetch(self, *a):    return []

    from database import Database
    monkeypatch.setattr(Database, '_pool', FakePool())
    monkeypatch.setattr(Database, 'pool', lambda: FakePool())


@pytest.mark.asyncio
async def test_health():
    from main import app
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        r = await c.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


@pytest.mark.asyncio
async def test_phone_send_called(mock_db):
    from main import app
    with patch("auth.service.send_sms_otp", new=AsyncMock(return_value="123456")):
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
            r = await c.post("/auth/phone/send", json={"phone": "+8613800138000"})
    assert r.status_code == 200


@pytest.mark.asyncio
async def test_email_send_called(mock_db):
    from main import app
    with patch("auth.service.send_email_otp", new=AsyncMock(return_value="654321")):
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
            r = await c.post("/auth/email/send", json={"email": "test@example.com"})
    assert r.status_code == 200


@pytest.mark.asyncio
async def test_invalid_code_returns_400(mock_db):
    from main import app
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        r = await c.post("/auth/phone/verify",
                         json={"phone": "+8613800138000", "code": "000000"})
    assert r.status_code == 400


@pytest.mark.asyncio
async def test_create_session_requires_auth(mock_db):
    from main import app
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        r = await c.post("/sessions", json={}, headers={"Authorization": "Bearer bad"})
    assert r.status_code == 401
