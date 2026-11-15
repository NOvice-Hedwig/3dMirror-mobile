"""Unit tests for services/llm_service.py (no DB, no network: the Anthropic client is faked)."""

import asyncio
import os
import sys
from types import SimpleNamespace

import anthropic
import httpx
import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services import llm_service                         # noqa: E402
from services.llm_service import parse_values, sniff_media_type  # noqa: E402

JPEG = b"\xff\xd8\xff\xe0" + b"\x00" * 32
PNG  = b"\x89PNG\r\n\x1a\n" + b"\x00" * 32
GIF  = b"GIF89a" + b"\x00" * 32
WEBP = b"RIFF\x00\x00\x00\x00WEBPVP8 " + b"\x00" * 32
HEIC = b"\x00\x00\x00\x18ftypheic\x00\x00\x00\x00mif1heic" + b"\x00" * 16
GOOD_REPLY = '{"shoulder_width_norm": 0.42, "waist_norm": 0.3, "hip_norm": 0.55, "limb_proportion_norm": 0.6}'


# ── Media type from bytes ────────────────────────────────────────────────────

@pytest.mark.parametrize("data,expected", [
    (JPEG, "image/jpeg"), (PNG, "image/png"), (GIF, "image/gif"), (WEBP, "image/webp"),
    (HEIC, None), (b"not an image", None), (b"", None),
])
def test_sniff_media_type(data, expected):
    assert sniff_media_type(data) == expected


# ── Reply parsing ────────────────────────────────────────────────────────────

def test_parse_values_reads_all_four_keys():
    assert parse_values(GOOD_REPLY) == {
        "shoulder_width_norm": 0.42, "waist_norm": 0.3, "hip_norm": 0.55, "limb_proportion_norm": 0.6}


def test_parse_values_clamps_and_nulls_bad_values():
    v = parse_values('Here: {"shoulder_width_norm": 1.7, "waist_norm": -0.2, "hip_norm": "wide",'
                     ' "limb_proportion_norm": true}')
    assert v == {"shoulder_width_norm": 1.0, "waist_norm": 0.0, "hip_norm": None,
                 "limb_proportion_norm": None}


def test_parse_values_missing_keys_are_none():
    assert parse_values('{"waist_norm": 0.5}')["shoulder_width_norm"] is None


@pytest.mark.parametrize("text", ["no json here", "{not: valid json}"])
def test_parse_values_rejects_non_json(text):
    with pytest.raises(ValueError):
        parse_values(text)


# ── analyze_body_photos with a fake client ───────────────────────────────────

class FakeClient:
    """Stands in for anthropic.AsyncAnthropic; records the request, returns or raises."""
    calls: list = []
    result = None   # a SimpleNamespace message, or an exception instance to raise

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


def reply(text: str, stop_reason: str = "end_turn"):
    return SimpleNamespace(stop_reason=stop_reason,
                           content=[SimpleNamespace(type="text", text=text)])


@pytest.fixture
def fake(monkeypatch, tmp_path):
    monkeypatch.setenv("ANTHROPIC_API_KEY", "test-key")
    monkeypatch.setattr(llm_service.anthropic, "AsyncAnthropic", FakeClient)
    FakeClient.calls = []
    FakeClient.result = reply(GOOD_REPLY)

    def write(name: str, data: bytes) -> str:
        p = tmp_path / name
        p.write_bytes(data)
        return str(p)
    return write


def run(paths):
    return asyncio.run(llm_service.analyze_body_photos(paths))


def test_ok_sends_detected_media_types_not_extensions(fake):
    # The app names every upload "<angle>.jpg"; a PNG must still be sent as image/png.
    out = run([fake("front.jpg", JPEG), fake("side.jpg", PNG)])
    assert out.status == "ok"
    assert out.values["shoulder_width_norm"] == 0.42
    assert out.detail is None
    sent = [b["source"]["media_type"] for b in FakeClient.calls[0]["messages"][0]["content"]
            if b["type"] == "image"]
    assert sent == ["image/jpeg", "image/png"]


def test_heic_is_skipped_not_sent_and_noted(fake):
    out = run([fake("front.jpg", JPEG), fake("side.jpg", HEIC)])
    assert out.status == "ok"
    assert "skipped 1 photo(s): HEIC/HEIF" in out.detail
    images = [b for b in FakeClient.calls[0]["messages"][0]["content"] if b["type"] == "image"]
    assert len(images) == 1 and images[0]["source"]["media_type"] == "image/jpeg"


def test_only_unsupported_photos_fail_without_calling_the_api(fake):
    out = run([fake("front.jpg", HEIC), fake("missing.jpg", b"")])
    assert out.status == "failed"
    assert "no photo in a supported format" in out.detail and "HEIC/HEIF" in out.detail
    assert FakeClient.calls == []


def test_missing_file_counts_as_unreadable(fake, tmp_path):
    out = run([fake("front.jpg", JPEG), str(tmp_path / "gone.jpg")])
    assert out.status == "ok" and "unreadable file" in out.detail


def test_no_api_key_is_unavailable(fake, monkeypatch):
    monkeypatch.delenv("ANTHROPIC_API_KEY")
    out = run([fake("front.jpg", JPEG)])
    assert (out.status, out.model) == ("unavailable", None)
    assert all(v is None for v in out.values.values())
    assert FakeClient.calls == []


REQ = httpx.Request("POST", "https://api.anthropic.com/v1/messages")


@pytest.mark.parametrize("error,detail_part", [
    (anthropic.RateLimitError("rate limited", response=httpx.Response(429, request=REQ), body=None),
     "API error 429 (RateLimitError)"),
    (anthropic.InternalServerError("boom", response=httpx.Response(500, request=REQ), body=None),
     "API error 500 (InternalServerError)"),
    (anthropic.BadRequestError("bad image", response=httpx.Response(400, request=REQ), body=None),
     "API error 400 (BadRequestError)"),
    (anthropic.APIConnectionError(request=REQ), "connection error (APIConnectionError)"),
    (anthropic.APITimeoutError(request=REQ), "connection error (APITimeoutError)"),
])
def test_api_errors_become_failed_outcomes(fake, error, detail_part):
    FakeClient.result = error
    out = run([fake("front.jpg", JPEG)])
    assert out.status == "failed"
    assert out.detail == detail_part
    assert all(v is None for v in out.values.values())


@pytest.mark.parametrize("message,detail_part", [
    (reply("I can't estimate that."), "unparseable reply"),
    (reply('{"shoulder_width_norm": 0.4', stop_reason="max_tokens"), "unparseable reply"),
    (reply('{"foo": 1}'), "reply had no usable values"),
    (reply("", stop_reason="refusal"), "model declined the request"),
])
def test_bad_replies_become_failed_outcomes(fake, message, detail_part):
    FakeClient.result = message
    out = run([fake("front.jpg", JPEG)])
    assert out.status == "failed"
    assert detail_part in out.detail
