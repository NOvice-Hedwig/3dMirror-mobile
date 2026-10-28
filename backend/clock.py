"""
Time rules for the whole backend:

- Instants are timezone-aware UTC, taken from now_utc() (never datetime.utcnow(),
  naive datetime.now(), CURRENT_DATE or the DB's now()), so tests can freeze the clock.
- A calendar date is always the user's local date: sent by the client, or derived from
  the IANA timezone in the X-Timezone header. Never the server's or the database's timezone.
"""

from datetime import date, datetime, timezone
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from fastapi import Header, HTTPException


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def user_timezone(x_timezone: str | None = Header(None)) -> ZoneInfo:
    """Dependency: the caller's IANA timezone from X-Timezone; 422 if missing or unknown."""
    if not x_timezone:
        raise HTTPException(
            422, "X-Timezone header is required (IANA name, e.g. America/New_York)")
    try:
        return ZoneInfo(x_timezone)
    except (ZoneInfoNotFoundError, ValueError):
        raise HTTPException(422, f"Unknown timezone in X-Timezone: {x_timezone!r}")


def local_today(tz: ZoneInfo) -> date:
    return now_utc().astimezone(tz).date()
