"""
Vision LLM integration: sends body photos to Claude and parses body proportion estimates.

Never raises for expected failures: every call returns an AnalysisOutcome whose status is
'ok', 'unavailable' (no ANTHROPIC_API_KEY) or 'failed' (API/network error, refusal,
unparseable reply, or no photo in a format Claude accepts), with a short reason in `detail`.
"""

import base64
import json
import logging
import os
import re
from dataclasses import dataclass, field
from pathlib import Path

import anthropic

log = logging.getLogger("photo_analysis")

_MODEL = os.getenv("VISION_MODEL", "claude-haiku-4-5-20251001")
_TIMEOUT_S = 60.0

VALUE_KEYS = ("shoulder_width_norm", "waist_norm", "hip_norm", "limb_proportion_norm")

_SYSTEM_PROMPT = """\
You are a body composition analysis assistant. Given one or more full-body photos
(front, side, or back views) of a person, estimate the following body proportion
parameters as floating-point values in the range [0.0, 1.0]:

- shoulder_width_norm: relative shoulder width (0=narrow, 1=very broad)
- waist_norm: relative waist circumference (0=very slim, 1=very wide)
- hip_norm: relative hip width (0=narrow, 1=very wide)
- limb_proportion_norm: relative limb length vs torso (0=short limbs, 1=long limbs)

Output ONLY valid JSON, no explanation:
{"shoulder_width_norm": float, "waist_norm": float, "hip_norm": float, "limb_proportion_norm": float}
"""


@dataclass(frozen=True)
class AnalysisOutcome:
    status: str                                   # 'ok' | 'unavailable' | 'failed'
    model: str | None = None
    values: dict[str, float | None] = field(default_factory=lambda: dict.fromkeys(VALUE_KEYS))
    detail: str | None = None


# ── Images ────────────────────────────────────────────────────────────────────
# Claude accepts only JPEG, PNG, GIF and WebP. The type is read from the file's bytes, not its
# name: the app names every upload "<angle>.jpg", and HEIC/HEIF is uploadable but not accepted
# by the API, so it is skipped instead of being sent mislabelled.

def sniff_media_type(data: bytes) -> str | None:
    """Claude-supported media type for these image bytes, or None if unsupported/unknown."""
    if data[:3] == b"\xff\xd8\xff":
        return "image/jpeg"
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return "image/png"
    if data[:6] in (b"GIF87a", b"GIF89a"):
        return "image/gif"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    return None


def _describe_unsupported(data: bytes) -> str:
    if data[4:8] == b"ftyp" and data[8:12] in (b"heic", b"heix", b"hevc", b"heim", b"heis",
                                               b"mif1", b"msf1"):
        return "HEIC/HEIF"
    return "unknown format"


def _image_blocks(file_paths: list[str]) -> tuple[list[dict], list[str]]:
    """(image content blocks, human-readable notes about skipped files)."""
    blocks, skipped = [], []
    for path in file_paths:
        try:
            data = Path(path).read_bytes()
        except OSError:
            skipped.append("unreadable file")
            continue
        media_type = sniff_media_type(data)
        if media_type is None:
            skipped.append(_describe_unsupported(data))
            continue
        blocks.append({
            "type": "image",
            "source": {"type": "base64", "media_type": media_type,
                       "data": base64.standard_b64encode(data).decode("ascii")},
        })
    return blocks, skipped


# ── Reply parsing ─────────────────────────────────────────────────────────────

def parse_values(text: str) -> dict[str, float | None]:
    """Extract the four proportions from the model's reply; missing or non-numeric → None,
    numbers clamped to [0, 1]. Raises ValueError when the reply contains no JSON object."""
    match = re.search(r"\{[^{}]+\}", text, re.DOTALL)
    if not match:
        raise ValueError("no JSON object in reply")
    raw = json.loads(match.group())
    if not isinstance(raw, dict):
        raise ValueError("reply JSON is not an object")
    values: dict[str, float | None] = {}
    for k in VALUE_KEYS:
        v = raw.get(k)
        values[k] = (float(max(0.0, min(1.0, v)))
                     if isinstance(v, (int, float)) and not isinstance(v, bool) else None)
    return values


# ── Main entry point ──────────────────────────────────────────────────────────

async def analyze_body_photos(file_paths: list[str]) -> AnalysisOutcome:
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        return AnalysisOutcome(status="unavailable", detail="ANTHROPIC_API_KEY is not configured")

    blocks, skipped = _image_blocks(file_paths)
    skipped_note = f"skipped {len(skipped)} photo(s): {', '.join(skipped)}" if skipped else None
    if not blocks:
        return AnalysisOutcome(
            status="failed", model=_MODEL,
            detail="no photo in a supported format (JPEG, PNG, GIF, WebP); " + (skipped_note or "no photos"))

    content = [*blocks, {"type": "text", "text": "Analyze the body in these photos."}]
    try:
        async with anthropic.AsyncAnthropic(api_key=api_key, timeout=_TIMEOUT_S) as client:
            message = await client.messages.create(
                model=_MODEL,
                max_tokens=256,
                system=_SYSTEM_PROMPT,
                messages=[{"role": "user", "content": content}],
            )
    except anthropic.APIStatusError as e:          # 4xx/5xx after the SDK's retries
        log.warning("photo analysis API error %s (request %s)", e.status_code, e.request_id)
        return AnalysisOutcome(status="failed", model=_MODEL,
                               detail=f"API error {e.status_code} ({type(e).__name__})")
    except anthropic.APIConnectionError as e:      # network failure or timeout
        log.warning("photo analysis connection error: %s", type(e).__name__)
        return AnalysisOutcome(status="failed", model=_MODEL,
                               detail=f"connection error ({type(e).__name__})")

    if message.stop_reason == "refusal":
        return AnalysisOutcome(status="failed", model=_MODEL, detail="model declined the request")
    text = "".join(b.text for b in message.content if b.type == "text")
    try:
        values = parse_values(text)
    except ValueError as e:                        # includes json.JSONDecodeError
        log.warning("photo analysis reply not parseable (stop_reason=%s): %s",
                    message.stop_reason, e)
        return AnalysisOutcome(status="failed", model=_MODEL, detail=f"unparseable reply: {e}")
    if all(v is None for v in values.values()):
        return AnalysisOutcome(status="failed", model=_MODEL, detail="reply had no usable values")
    return AnalysisOutcome(status="ok", model=_MODEL, values=values, detail=skipped_note)
