"""
Vision LLM integration: sends body photos to Claude and parses body proportion estimates.
Requires ANTHROPIC_API_KEY in environment.
"""

import os
import base64
import json
import re
from pathlib import Path

import anthropic

_MODEL = os.getenv("VISION_MODEL", "claude-haiku-4-5-20251001")

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


def _encode_image(file_path: str) -> tuple[str, str]:
    """Return (base64_data, media_type) for a local image file."""
    path = Path(file_path)
    ext = path.suffix.lower()
    media_type_map = {
        ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
        ".png": "image/png", ".webp": "image/webp",
        ".gif": "image/gif",
    }
    media_type = media_type_map.get(ext, "image/jpeg")
    data = base64.standard_b64encode(path.read_bytes()).decode("utf-8")
    return data, media_type


def _parse_response(text: str) -> dict:
    """Extract JSON from Claude's response text."""
    match = re.search(r'\{[^{}]+\}', text, re.DOTALL)
    if not match:
        raise ValueError(f"No JSON found in LLM response: {text[:200]}")
    result = json.loads(match.group())
    keys = ("shoulder_width_norm", "waist_norm", "hip_norm", "limb_proportion_norm")
    for k in keys:
        if k in result:
            result[k] = float(max(0.0, min(1.0, result[k])))
    return result


async def analyze_body_photos(file_paths: list[str]) -> dict:
    """
    Send up to 3 body photos to Claude vision and return normalized body params.
    Falls back to empty dict on any error so the caller can degrade gracefully.
    """
    if not file_paths:
        return {}

    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        return {}

    content: list[dict] = []
    for path in file_paths:
        try:
            data, media_type = _encode_image(path)
            content.append({
                "type": "image",
                "source": {"type": "base64", "media_type": media_type, "data": data},
            })
        except Exception:
            continue

    if not content:
        return {}

    content.append({"type": "text", "text": "Analyze the body in these photos."})

    client = anthropic.Anthropic(api_key=api_key)
    message = client.messages.create(
        model=_MODEL,
        max_tokens=256,
        system=_SYSTEM_PROMPT,
        messages=[{"role": "user", "content": content}],
    )
    response_text = message.content[0].text
    return _parse_response(response_text)
