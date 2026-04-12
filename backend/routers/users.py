from fastapi import APIRouter, Header, HTTPException
from database import Database
from auth.service import decode_jwt

router = APIRouter()


@router.get("/me")
async def get_me(authorization: str = Header(...)):
    try:
        uid = decode_jwt(authorization.removeprefix("Bearer "))["sub"]
    except Exception:
        raise HTTPException(401, "Invalid token")
    pool = Database.pool()
    row  = await pool.fetchrow(
        "SELECT id, phone, email, display_name, locale, gender, height_cm, created_at"
        " FROM users WHERE id=$1", uid)
    if not row:
        raise HTTPException(404, "User not found")
    return dict(row)


@router.patch("/me")
async def update_me(body: dict, authorization: str = Header(...)):
    try:
        uid = decode_jwt(authorization.removeprefix("Bearer "))["sub"]
    except Exception:
        raise HTTPException(401, "Invalid token")

    allowed = {"display_name", "locale", "gender", "height_cm"}
    updates = {k: v for k, v in body.items() if k in allowed}
    if not updates:
        raise HTTPException(400, "No valid fields to update")

    pool = Database.pool()
    cols = ", ".join(f"{k}=${i+2}" for i, k in enumerate(updates))
    vals = list(updates.values())
    await pool.execute(
        f"UPDATE users SET {cols}, updated_at=NOW() WHERE id=$1",
        uid, *vals)
    return {"message": "updated"}
