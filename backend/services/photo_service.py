"""
Photo persistence: save uploaded files to disk and manage DB records.
"""

import os
import uuid
from pathlib import Path

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


async def update_photo_analysis(
    pool, *, photo_id: str, analysis: dict
) -> None:
    import json
    await pool.execute(
        "UPDATE body_photos SET llm_analysis=$1 WHERE id=$2",
        json.dumps(analysis), photo_id,
    )


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
