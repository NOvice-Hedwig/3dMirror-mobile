import json, uuid
from datetime import datetime
from fastapi import APIRouter, HTTPException, Header
from database import Database
from schemas import SessionIn, SessionOut
from auth.service import decode_jwt

router = APIRouter()


def _uid(authorization: str) -> str:
    try:
        return decode_jwt(authorization.removeprefix("Bearer "))["sub"]
    except Exception:
        raise HTTPException(401, "Invalid token")


@router.post("", response_model=SessionOut)
async def create_session(body: SessionIn, authorization: str = Header(...)):
    uid = _uid(authorization)
    sid = str(uuid.uuid4())
    now = datetime.utcnow()
    pool = Database.pool()
    await pool.execute(
        """INSERT INTO sessions
           (id, user_id, body_data, avatar_params, activity_data, thumbnail_url, created_at)
           VALUES ($1,$2,$3,$4,$5,$6,$7)""",
        sid, uid,
        json.dumps(body.body_data.model_dump()),
        json.dumps(body.avatar_params.model_dump()),
        json.dumps(body.activity_data.model_dump()) if body.activity_data else None,
        body.thumbnail_url,
        now,
    )
    return SessionOut(
        id=sid, user_id=uid, created_at=now,
        body_data=body.body_data.model_dump(),
        avatar_params=body.avatar_params.model_dump(),
        activity_data=body.activity_data.model_dump() if body.activity_data else None,
        thumbnail_url=body.thumbnail_url,
    )


@router.get("", response_model=list[SessionOut])
async def list_sessions(limit: int = 30, authorization: str = Header(...)):
    uid  = _uid(authorization)
    pool = Database.pool()
    rows = await pool.fetch(
        "SELECT * FROM sessions WHERE user_id=$1 ORDER BY created_at DESC LIMIT $2",
        uid, limit)
    return [_to_out(r) for r in rows]


@router.get("/{sid}", response_model=SessionOut)
async def get_session(sid: str, authorization: str = Header(...)):
    uid  = _uid(authorization)
    pool = Database.pool()
    row  = await pool.fetchrow(
        "SELECT * FROM sessions WHERE id=$1 AND user_id=$2", sid, uid)
    if not row:
        raise HTTPException(404, "Session not found")
    return _to_out(row)


def _to_out(row) -> SessionOut:
    return SessionOut(
        id=str(row["id"]),
        user_id=str(row["user_id"]),
        created_at=row["created_at"],
        body_data=json.loads(row["body_data"]),
        avatar_params=json.loads(row["avatar_params"]),
        activity_data=json.loads(row["activity_data"]) if row["activity_data"] else None,
        thumbnail_url=row["thumbnail_url"],
    )
