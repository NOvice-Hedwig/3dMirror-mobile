"""
One-shot migration: create workout_logs table.
Run from the backend/ directory:
  python scripts/add_workout_logs.py
"""
import asyncio
import os
import asyncpg

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://mirror:mirror@localhost/mirror_db",
)

_DDL = """
CREATE TABLE IF NOT EXISTS workout_logs (
    id             uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id        uuid        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    logged_at      timestamptz DEFAULT now(),
    type           text        NOT NULL,
    sub_type       text        NOT NULL,
    duration_min   int         NOT NULL,
    intensity      text        NOT NULL,
    with_weight    boolean     NOT NULL DEFAULT false,
    muscle_group   text,
    sets           jsonb,
    estimated_kcal int
);
CREATE INDEX IF NOT EXISTS idx_workout_user_date
    ON workout_logs (user_id, logged_at);
"""

_CHECK = "SELECT to_regclass('public.workout_logs') AS tbl;"


async def main() -> None:
    print(f"Connecting → {DATABASE_URL}\n")
    conn = await asyncpg.connect(DATABASE_URL)
    try:
        await conn.execute(_DDL)
        row = await conn.fetchrow(_CHECK)
        if row["tbl"]:
            print("[OK]  workout_logs table is present.")
        else:
            print("[MISSING]  workout_logs was NOT created!")
            raise SystemExit(1)
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(main())
