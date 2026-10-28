"""
Rate limits for sending verification codes (/auth/phone/send, /auth/email/send).

- Per destination (phone number or email): at most 1 per 60 s and 5 per hour.
- Per client IP: at most AUTH_SEND_LIMIT_IP_PER_MINUTE (default 5) per minute and
  AUTH_SEND_LIMIT_IP_PER_HOUR (default 20) per hour. Destination limits are fixed; the IP
  limits are configurable so automated test runs from one IP can raise them.

A send is counted only if every limit allows it, so rejected requests don't use up quota.

In-memory and per process: correct only while the backend runs as ONE instance. With several
instances (or uvicorn --workers > 1) the counters must move to a shared store such as Redis.
The client IP is the direct peer (request.client.host); behind a reverse proxy that becomes
the proxy's IP unless the proxy's forwarded-for header is trusted explicitly.
"""

import math
import os
from collections import defaultdict, deque
from datetime import datetime, timedelta

import clock

MINUTE = timedelta(minutes=1)
HOUR = timedelta(hours=1)

DESTINATION_RULES: list[tuple[timedelta, int]] = [(MINUTE, 1), (HOUR, 5)]
IP_RULES: list[tuple[timedelta, int]] = [
    (MINUTE, int(os.getenv("AUTH_SEND_LIMIT_IP_PER_MINUTE", "5"))),
    (HOUR,   int(os.getenv("AUTH_SEND_LIMIT_IP_PER_HOUR", "20"))),
]

_hits: dict[str, deque[datetime]] = defaultdict(deque)


class RateLimited(Exception):
    def __init__(self, retry_after_s: int):
        super().__init__(retry_after_s)
        self.retry_after_s = retry_after_s


def _retry_after(key: str, rules: list[tuple[timedelta, int]], now: datetime) -> float:
    """Seconds until `key` may send again under `rules` (0 if allowed now)."""
    q = _hits.get(key)
    if not q:
        return 0.0
    while q and now - q[0] >= HOUR:          # HOUR is the longest window
        q.popleft()
    if not q:
        del _hits[key]                       # keep memory bounded to the last hour
        return 0.0
    wait = 0.0
    for window, limit in rules:
        recent = [t for t in q if now - t < window]
        if len(recent) >= limit:
            wait = max(wait, (recent[-limit] + window - now).total_seconds())
    return wait


def check_and_record(destination: str, client_ip: str | None) -> None:
    """Raise RateLimited if any limit is exceeded; otherwise count this send."""
    now = clock.now_utc()
    keys = [(f"dest:{destination}", DESTINATION_RULES)]
    if client_ip:
        keys.append((f"ip:{client_ip}", IP_RULES))
    wait = max(_retry_after(k, rules, now) for k, rules in keys)
    if wait > 0:
        raise RateLimited(max(1, math.ceil(wait)))
    for k, _ in keys:
        _hits[k].append(now)


def reset() -> None:
    """Forget all counters (tests)."""
    _hits.clear()
