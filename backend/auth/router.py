from fastapi import APIRouter, HTTPException, Depends, Header
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
import uuid

from database import Database
from auth.service import (
    send_sms_otp, send_email_otp, verify_apple_token,
    verify_code, create_jwt, decode_jwt,
)

router = APIRouter()


# ── Schemas ───────────────────────────────────────────────────────────────────

class PhoneSendReq(BaseModel):
    phone: str

class PhoneVerifyReq(BaseModel):
    phone: str
    code:  str = Field(..., min_length=6, max_length=6)

class EmailSendReq(BaseModel):
    email: EmailStr

class EmailVerifyReq(BaseModel):
    email: EmailStr
    code:  str = Field(..., min_length=6, max_length=6)

class AppleReq(BaseModel):
    identity_token: str
    full_name:      Optional[str] = None

class AuthOut(BaseModel):
    user_id:      str
    token:        str
    is_new_user:  bool


# ── Dependency ────────────────────────────────────────────────────────────────

async def current_user(authorization: str = Header(...)) -> str:
    if not authorization.startswith("Bearer "):
        raise HTTPException(401, "Missing Bearer token")
    try:
        return decode_jwt(authorization.removeprefix("Bearer "))["sub"]
    except Exception:
        raise HTTPException(401, "Invalid or expired token")


# ── Phone ─────────────────────────────────────────────────────────────────────

@router.post("/phone/send")
async def phone_send(req: PhoneSendReq):
    try:
        await send_sms_otp(req.phone)
    except Exception as e:
        raise HTTPException(500, f"SMS failed: {e}")
    return {"message": "OTP sent"}


@router.post("/phone/verify", response_model=AuthOut)
async def phone_verify(req: PhoneVerifyReq):
    if not verify_code(req.phone, req.code):
        raise HTTPException(400, "Invalid or expired code")
    pool = Database.pool()
    row  = await pool.fetchrow("SELECT id FROM users WHERE phone=$1", req.phone)
    is_new = row is None
    if is_new:
        uid = str(uuid.uuid4())
        await pool.execute(
            "INSERT INTO users (id, phone, created_at) VALUES ($1,$2,NOW())",
            uid, req.phone)
    else:
        uid = str(row["id"])
    return AuthOut(user_id=uid, token=create_jwt(uid), is_new_user=is_new)


# ── Email ─────────────────────────────────────────────────────────────────────

@router.post("/email/send")
async def email_send(req: EmailSendReq):
    try:
        await send_email_otp(str(req.email))
    except Exception as e:
        raise HTTPException(500, f"Email failed: {e}")
    return {"message": "OTP sent"}


@router.post("/email/verify", response_model=AuthOut)
async def email_verify(req: EmailVerifyReq):
    if not verify_code(str(req.email), req.code):
        raise HTTPException(400, "Invalid or expired code")
    pool = Database.pool()
    row  = await pool.fetchrow("SELECT id FROM users WHERE email=$1", str(req.email))
    is_new = row is None
    if is_new:
        uid = str(uuid.uuid4())
        await pool.execute(
            "INSERT INTO users (id, email, created_at) VALUES ($1,$2,NOW())",
            uid, str(req.email))
    else:
        uid = str(row["id"])
    return AuthOut(user_id=uid, token=create_jwt(uid), is_new_user=is_new)


# ── Apple ─────────────────────────────────────────────────────────────────────

@router.post("/apple", response_model=AuthOut)
async def apple_sign_in(req: AppleReq):
    try:
        payload = await verify_apple_token(req.identity_token)
    except Exception as e:
        raise HTTPException(400, f"Apple token invalid: {e}")
    apple_id = payload["sub"]
    email    = payload.get("email")
    pool = Database.pool()
    row  = await pool.fetchrow("SELECT id FROM users WHERE apple_id=$1", apple_id)
    is_new = row is None
    if is_new:
        uid = str(uuid.uuid4())
        await pool.execute(
            "INSERT INTO users (id, apple_id, email, display_name, created_at)"
            " VALUES ($1,$2,$3,$4,NOW())",
            uid, apple_id, email, req.full_name)
    else:
        uid = str(row["id"])
    return AuthOut(user_id=uid, token=create_jwt(uid), is_new_user=is_new)


# ── Me ────────────────────────────────────────────────────────────────────────

@router.get("/me")
async def me(uid: str = Depends(current_user)):
    pool = Database.pool()
    row  = await pool.fetchrow(
        "SELECT id, phone, email, display_name, created_at FROM users WHERE id=$1", uid)
    if not row:
        raise HTTPException(404, "User not found")
    return dict(row)
