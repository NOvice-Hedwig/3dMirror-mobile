"""
One-shot migration: create the 5 log tables required by batch-3.
Run from the backend/ directory:
  python scripts/create_log_tables.py
"""
import asyncio
import os
import asyncpg

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://mirror:mirror@localhost/mirror_db",
)

_DDL = """
CREATE TABLE IF NOT EXISTS diet_logs (
  id           uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  logged_at    timestamptz DEFAULT now(),
  meal         text NOT NULL CHECK (meal IN ('早餐','午餐','晚餐','加餐')),
  food_name    text NOT NULL,
  grams        numeric(6,1),
  calories     numeric(7,1) NOT NULL,
  protein_g    numeric(6,1),
  entry_method text NOT NULL DEFAULT 'manual'
);
CREATE INDEX IF NOT EXISTS idx_diet_user_date
  ON diet_logs (user_id, logged_at);

CREATE TABLE IF NOT EXISTS sleep_logs (
  id        uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date      date NOT NULL,
  bedtime   timestamptz NOT NULL,
  wake_time timestamptz NOT NULL,
  quality   smallint CHECK (quality BETWEEN 1 AND 5),
  source    text NOT NULL DEFAULT 'manual',
  UNIQUE (user_id, date)
);

CREATE TABLE IF NOT EXISTS period_logs (
  id        uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date      date NOT NULL,
  phase     text NOT NULL CHECK (phase IN ('start','ongoing','end')),
  symptoms  text[] NOT NULL DEFAULT '{}',
  intensity smallint CHECK (intensity BETWEEN 1 AND 3),
  UNIQUE (user_id, date)
);

CREATE TABLE IF NOT EXISTS supplement_logs (
  id               uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id          uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  logged_at        timestamptz DEFAULT now(),
  name             text NOT NULL,
  dosage           text,
  reminder_time    time,
  reminder_enabled boolean NOT NULL DEFAULT false
);
CREATE INDEX IF NOT EXISTS idx_supplement_user_date
  ON supplement_logs (user_id, logged_at);

CREATE TABLE IF NOT EXISTS body_snapshots (
  id           uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date         date NOT NULL,
  measurements jsonb NOT NULL,
  UNIQUE (user_id, date)
);
"""

_CHECK = """
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name = ANY($1::text[])
ORDER BY table_name;
"""

EXPECTED = [
    "body_snapshots",
    "diet_logs",
    "period_logs",
    "sleep_logs",
    "supplement_logs",
]


async def main() -> None:
    print(f"Connecting → {DATABASE_URL}\n")
    conn = await asyncpg.connect(DATABASE_URL)
    try:
        await conn.execute(_DDL)
        rows = await conn.fetch(_CHECK, EXPECTED)
        found = {r["table_name"] for r in rows}

        print("=== Table creation results ===")
        for name in EXPECTED:
            mark = "[OK]     " if name in found else "[MISSING]"
            print(f"  {mark}  {name}")

        ok = len(found)
        total = len(EXPECTED)
        print(f"\n{ok}/{total} tables present in public schema.")
        if ok < total:
            raise SystemExit(1)
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(main())
