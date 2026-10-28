import uuid
from fastapi import APIRouter, HTTPException, Depends
from database import Database
from schemas import SessionIn, SessionOut
from auth.router import current_user
import clock

router = APIRouter()


# Auth runs as a dependency so a bad token is rejected (401) before body validation (422).
@router.post("", response_model=SessionOut)
async def create_session(body: SessionIn, uid: str = Depends(current_user)):
    sid = str(uuid.uuid4())
    now = clock.now_utc()   # aware UTC; a naive utcnow() was stored shifted by the host's offset
    pool = Database.pool()
    await pool.execute(
        """INSERT INTO sessions
           (id, user_id, body_data, avatar_params, activity_data, thumbnail_url, created_at)
           VALUES ($1,$2,$3,$4,$5,$6,$7)""",
        sid, uid,
        body.body_data.model_dump(),
        body.avatar_params.model_dump(),
        body.activity_data.model_dump() if body.activity_data else None,
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
async def list_sessions(limit: int = 30, uid: str = Depends(current_user)):
    pool = Database.pool()
    rows = await pool.fetch(
        "SELECT * FROM sessions WHERE user_id=$1 ORDER BY created_at DESC LIMIT $2",
        uid, limit)
    return [_to_out(r) for r in rows]


@router.get("/{sid}", response_model=SessionOut)
async def get_session(sid: str, uid: str = Depends(current_user)):
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
        body_data=row["body_data"],
        avatar_params=row["avatar_params"],
        activity_data=row["activity_data"],
        thumbnail_url=row["thumbnail_url"],
    )
