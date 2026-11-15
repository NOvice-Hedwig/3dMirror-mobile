"""
Photo persistence: save uploaded files to disk and manage DB records.
"""

import os
import uuid
from pathlib import Path

import clock

UPLOAD_DIR = Path(os.getenv("UPLOAD_DIR", "uploads"))
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


def save_file(file_bytes: bytes, original_filename: str) -> str:
    """Write bytes to uploads/ and return the relative file path."""
    ext = Path(original_filename).suffix or ".jpg"
    filename = f"{uuid.uuid4()}{ext}"
    path = UPLOAD_DIR / filename
    path.write_bytes(file_bytes)
    return str(path)


async def create_photo_record(
    pool, *, user_id: str, angle: str, file_path: str
) -> str:
    photo_id = str(uuid.uuid4())
    await pool.execute(
        """INSERT INTO body_photos (id, user_id, angle, file_path)
           VALUES ($1, $2, $3, $4)""",
        photo_id, user_id, angle, file_path,
    )
    return photo_id


# ── Analyses ─────────────────────────────────────────────────────────────────
# Results live in body_analyses (one row per run). body_photos.llm_analysis is no longer
# written: nothing reads it, and old rows are kept unchanged.

_ANALYSIS_COLUMNS = (
    "id, status, created_at, model, photo_ids, shoulder_width_norm, waist_norm,"
    " hip_norm, limb_proportion_norm, detail"
)


def _analysis_dict(row) -> dict:
    d = dict(row)
    d["id"] = str(d["id"])
    d["photo_ids"] = [str(p) for p in d["photo_ids"]]
    return d


async def create_analysis_record(
    pool, *, user_id: str, photo_ids: list[str], outcome
) -> dict:
    """Store one analysis run (an llm_service.AnalysisOutcome) and return it as a dict."""
    row = await pool.fetchrow(
        f"""INSERT INTO body_analyses
              (id, user_id, created_at, status, model, photo_ids,
               shoulder_width_norm, waist_norm, hip_norm, limb_proportion_norm, detail)
            VALUES ($1,$2,$3,$4,$5,$6::uuid[],$7,$8,$9,$10,$11)
            RETURNING {_ANALYSIS_COLUMNS}""",
        str(uuid.uuid4()), user_id, clock.now_utc(), outcome.status, outcome.model, photo_ids,
        outcome.values["shoulder_width_norm"], outcome.values["waist_norm"],
        outcome.values["hip_norm"], outcome.values["limb_proportion_norm"], outcome.detail,
    )
    return _analysis_dict(row)


async def get_latest_analysis(pool, *, user_id: str, status: str | None = None) -> dict | None:
    row = await pool.fetchrow(
        f"""SELECT {_ANALYSIS_COLUMNS} FROM body_analyses
            WHERE user_id = $1 AND ($2::text IS NULL OR status = $2)
            ORDER BY created_at DESC LIMIT 1""",
        user_id, status,
    )
    return _analysis_dict(row) if row else None


async def link_photos_to_session(
    pool, *, photo_ids: list[str], session_id: str
) -> None:
    await pool.executemany(
        "UPDATE body_photos SET session_id=$1 WHERE id=$2",
        [(session_id, pid) for pid in photo_ids],
    )


async def get_user_photos(pool, *, user_id: str, session_id: str | None = None):
    if session_id:
        rows = await pool.fetch(
            """SELECT * FROM body_photos
               WHERE user_id=$1 AND session_id=$2
               ORDER BY created_at""",
            user_id, session_id,
        )
    else:
        rows = await pool.fetch(
            """SELECT * FROM body_photos
               WHERE user_id=$1
               ORDER BY created_at DESC LIMIT 50""",
            user_id,
        )
    return [dict(r) for r in rows]
