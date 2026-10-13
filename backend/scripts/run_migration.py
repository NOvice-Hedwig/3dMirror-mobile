"""
Run migration.sql against the configured database.
Usage (from backend/ directory):
  python scripts/run_migration.py
"""
import asyncio
import os
from pathlib import Path

import asyncpg

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://mirror:mirror@localhost/mirror_db",
)

_CHECK = """
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name = ANY($1::text[])
ORDER BY table_name;
"""

EXPECTED = [
    "body_photos",
    "body_snapshots",
    "diet_logs",
    "period_logs",
    "sessions",
    "sleep_logs",
    "supplement_logs",
    "users",
]


async def main() -> None:
    sql_path = Path(__file__).parent.parent / "migration.sql"
    migration_sql = sql_path.read_text(encoding="utf-8")

    print(f"Connecting → {DATABASE_URL}\n")
    conn = await asyncpg.connect(DATABASE_URL)
    try:
        print(f"Executing {sql_path.name} …")
        await conn.execute(migration_sql)
        print("Done.\n")

        rows = await conn.fetch(_CHECK, EXPECTED)
        found = {r["table_name"] for r in rows}

        print("=== Table status ===")
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
