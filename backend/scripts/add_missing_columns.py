"""
One-shot migration: add columns that were applied to a previous DB instance
but are missing from the current container.
Run from the backend/ directory:
  python scripts/add_missing_columns.py
"""
import asyncio
import os
import asyncpg

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://mirror:mirror@localhost/mirror_db",
)

_DDL = """
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_avatar_params  JSONB;
ALTER TABLE users ADD COLUMN IF NOT EXISTS challenge_goal        JSONB;
ALTER TABLE users ADD COLUMN IF NOT EXISTS challenge_start_date  DATE;
"""

EXPECTED = [
    ("users", "target_avatar_params"),
    ("users", "challenge_goal"),
    ("users", "challenge_start_date"),
]

_CHECK = """
SELECT table_name, column_name
FROM information_schema.columns
WHERE (table_name, column_name) = ANY($1::text[][])
"""


async def main() -> None:
    print(f"Connecting → {DATABASE_URL}\n")
    conn = await asyncpg.connect(DATABASE_URL)
    try:
        print("Applying ALTER TABLE statements …")
        await conn.execute(_DDL)
        print("Done.\n")

        rows = await conn.fetch(
            """
            SELECT table_name, column_name
            FROM information_schema.columns
            WHERE table_name   = ANY($1::text[])
              AND column_name  = ANY($2::text[])
            """,
            list({t for t, _ in EXPECTED}),
            list({c for _, c in EXPECTED}),
        )
        found = {(r["table_name"], r["column_name"]) for r in rows}

        print("=== Column status ===")
        for tbl, col in EXPECTED:
            mark = "[OK]     " if (tbl, col) in found else "[MISSING]"
            print(f"  {mark}  {tbl}.{col}")

        ok = len(found)
        total = len(EXPECTED)
        print(f"\n{ok}/{total} columns present.")
        if ok < total:
            raise SystemExit(1)
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(main())
