"""
Photo routes:
  POST /photos/upload   — multipart upload of 1-3 angle photos
  POST /photos/analyze  — trigger LLM analysis for a set of photo_ids
  GET  /photos          — list photos for the current user (optionally by session)
"""

import json
from fastapi import APIRouter, HTTPException, Header, UploadFile, File, Form
from typing import Optional

from database import Database
from auth.service import decode_jwt
from services import photo_service, llm_service

router = APIRouter()

_ALLOWED_ANGLES = {"front", "side", "back"}
_ALLOWED_MIME   = {"image/jpeg", "image/png", "image/webp", "image/heic"}
_MAX_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB per photo


def _uid(authorization: str) -> str:
    try:
        return decode_jwt(authorization.removeprefix("Bearer "))["sub"]
    except Exception:
        raise HTTPException(401, "Invalid token")


@router.post("/upload")
async def upload_photos(
    authorization: str = Header(...),
    front: Optional[UploadFile] = File(None),
    side:  Optional[UploadFile] = File(None),
    back:  Optional[UploadFile] = File(None),
):
    """
    Accept up to three photos keyed by angle name.
    Returns list of created photo_ids.
    """
    uid  = _uid(authorization)
    pool = Database.pool()

    uploads = [f for f in [("front", front), ("side", side), ("back", back)] if f[1]]
    if not uploads:
        raise HTTPException(400, "At least one photo file is required")

    photo_ids: list[str] = []

    for angle, upload in uploads:
        if upload.content_type and upload.content_type not in _ALLOWED_MIME:
            raise HTTPException(415, f"Unsupported file type: {upload.content_type}")

        file_bytes = await upload.read()
        if len(file_bytes) > _MAX_SIZE_BYTES:
            raise HTTPException(413, f"{angle} photo exceeds 10 MB limit")

        file_path = photo_service.save_file(file_bytes, upload.filename or f"{angle}.jpg")
        pid = await photo_service.create_photo_record(
            pool, user_id=uid, angle=angle, file_path=file_path
        )
        photo_ids.append(pid)

    return {"photo_ids": photo_ids}


@router.post("/analyze")
async def analyze_photos(
    authorization: str = Header(...),
    photo_ids: list[str] = Form(...),
):
    """
    Trigger Claude vision analysis for the given photo_ids.
    Returns the structured body parameter estimates.
    """
    uid  = _uid(authorization)
    pool = Database.pool()

    rows = await pool.fetch(
        "SELECT id, file_path FROM body_photos WHERE id = ANY($1::uuid[]) AND user_id=$2",
        photo_ids, uid,
    )
    if not rows:
        raise HTTPException(404, "No matching photos found")

    file_paths = [r["file_path"] for r in rows]
    analysis   = await llm_service.analyze_body_photos(file_paths)

    for row in rows:
        await photo_service.update_photo_analysis(
            pool, photo_id=str(row["id"]), analysis=analysis
        )

    return {"analysis": analysis, "photo_ids": [str(r["id"]) for r in rows]}


@router.get("")
async def list_photos(
    authorization: str = Header(...),
    session_id: Optional[str] = None,
):
    uid  = _uid(authorization)
    pool = Database.pool()
    photos = await photo_service.get_user_photos(pool, user_id=uid, session_id=session_id)

    for p in photos:
        for k, v in p.items():
            if hasattr(v, 'isoformat'):
                p[k] = v.isoformat()
            elif not isinstance(v, (str, int, float, bool, dict, list, type(None))):
                p[k] = str(v)
        if isinstance(p.get('llm_analysis'), str):
            try:
                p['llm_analysis'] = json.loads(p['llm_analysis'])
            except Exception:
                pass

    return {"photos": photos}
