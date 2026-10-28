"""
READ-ONLY report: rows written before the timezone fix (2026-10-12) whose instants may be wrong.

Background
- sessions.created_at was written from naive datetime.utcnow(). asyncpg treats a naive
  datetime as the *backend host's* local time, so on a host in America/New_York every session
  was stored 4 h (EDT) / 5 h (EST) in the future. Rows written by a backend running in UTC
  (e.g. the Docker api container) are correct.
- sleep_logs.bedtime/wake_time were sent by the app without an offset, so they were interpreted
  in the backend host's timezone, not the phone's.

For each session this prints the stored value, the likely corrected value (assuming the backend
host was in --host-tz), and the closest event recorded by Postgres's own clock (users.created_at,
body_photos.created_at, workout_logs.logged_at), which was always correct. A session is "likely
skewed" when the stored value is implausibly late versus that event and the corrected value fits.

Nothing is modified: all queries run inside a READ ONLY transaction.

Usage (from backend/):
  DATABASE_URL=postgresql://mirror:mirror@localhost/mirror_db \
  python scripts/report_timezone_skew.py [--host-tz America/New_York]
"""

import argparse
import asyncio
import os
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import asyncpg

UTC = timezone.utc


def corrected(stored: datetime, host_tz: ZoneInfo) -> datetime:
    """Undo 'naive UTC wall time interpreted as host-local time'."""
    return stored.astimezone(host_tz).replace(tzinfo=UTC)


def fmt(d: datetime | None) -> str:
    return d.astimezone(UTC).strftime("%Y-%m-%d %H:%M:%SZ") if d else "—"


def hours(td: timedelta) -> str:
    return f"{td.total_seconds() / 3600:+.2f}h"


async def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--host-tz", default="America/New_York",
                    help="timezone of the machine that ran the backend (default: America/New_York)")
    host_tz = ZoneInfo(ap.parse_args().host_tz)

    conn = await asyncpg.connect(os.getenv("DATABASE_URL",
                                           "postgresql://mirror:mirror@localhost/mirror_db"))
    try:
        async with conn.transaction(readonly=True):
            ro = await conn.fetchval("SHOW transaction_read_only")
            db = await conn.fetchval("SELECT current_database()")
            print(f"database: {db}   transaction_read_only: {ro}   assumed backend host tz: {host_tz.key}\n")
            if ro != "on":
                raise SystemExit("refusing to continue: transaction is not read-only")

            sessions = await conn.fetch(
                "SELECT s.id, s.user_id, s.created_at, u.created_at AS user_created"
                " FROM sessions s JOIN users u ON u.id = s.user_id ORDER BY s.created_at")
            # Events stamped by Postgres's own clock (always correct), per user.
            events = await conn.fetch(
                "SELECT id AS user_id, created_at AS at, 'user created' AS kind FROM users"
                " UNION ALL SELECT user_id, created_at, 'photo upload' FROM body_photos"
                " UNION ALL SELECT user_id, logged_at, 'workout log' FROM workout_logs")
            by_user: dict = {}
            for e in events:
                by_user.setdefault(e["user_id"], []).append((e["at"], e["kind"]))

            print(f"=== sessions: {len(sessions)} rows ===")
            print(f"{'session':8}  {'stored created_at':20}  {'likely corrected':20}  {'shift':>7}  "
                  f"{'nearest DB-clock event':36}  verdict")
            counts = {"likely skewed": 0, "likely correct": 0, "unclear": 0}
            for s in sessions:
                st, fix = s["created_at"], corrected(s["created_at"], host_tz)
                evs = by_user.get(s["user_id"], [])
                near = min(evs, key=lambda e: abs(e[0] - fix)) if evs else None
                if fix < s["user_created"]:
                    verdict = "likely correct"         # correction would predate the account
                elif near and abs(near[0] - fix) <= timedelta(minutes=30) \
                        and abs(near[0] - st) >= timedelta(hours=3):
                    verdict = "likely skewed"          # corrected value lines up with a real event
                elif near and abs(near[0] - st) <= timedelta(minutes=30):
                    verdict = "likely correct"
                else:
                    verdict = "unclear"
                counts[verdict] += 1
                ev = f"{fmt(near[0])} {near[1]}" if near else "—"
                print(f"{str(s['id'])[:8]}  {fmt(st):20}  {fmt(fix):20}  {hours(fix - st):>7}  "
                      f"{ev:36}  {verdict}")
            print(f"\nsummary: {counts}")

            sleep = await conn.fetch(
                "SELECT id, user_id, date, bedtime, wake_time FROM sleep_logs ORDER BY date")
            print(f"\n=== sleep_logs: {len(sleep)} rows (all written before the fix) ===")
            for r in sleep:
                local_bed = r["bedtime"].astimezone(host_tz)
                print(f"{str(r['id'])[:8]}  date {r['date']}  bedtime {fmt(r['bedtime'])}"
                      f" (= {local_bed:%H:%M} {host_tz.key})  wake {fmt(r['wake_time'])}"
                      "  — times were read as backend-host local; correct only if the phone"
                      " was in the same timezone")
            if not sleep:
                print("none — no sleep logs are affected")
    finally:
        await conn.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
