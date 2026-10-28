import logging
import uuid
from typing import Optional

import asyncpg
from fastapi import APIRouter, HTTPException, Depends, Header, Request
from pydantic import BaseModel, Field

from database import Database
from auth import rate_limit
from auth.identity import (
    IdentityError, Phone, legacy_phone_digits, normalize_email, normalize_phone,
)
from auth.service import (
    send_sms_otp, send_email_otp, verify_apple_token,
    verify_code, create_jwt, decode_jwt,
)

router = APIRouter()
log = logging.getLogger("auth")

MSG_TOO_MANY = "请求过于频繁，请稍后再试"


# ── Schemas ───────────────────────────────────────────────────────────────────
# phone/email are plain strings here and normalized in the handlers, so a bad value
# returns 422 with one readable Chinese message instead of Pydantic's error list.

class PhoneSendReq(BaseModel):
    phone: str

class PhoneVerifyReq(BaseModel):
    phone: str
    code:  str = Field(..., min_length=6, max_length=6)

class EmailSendReq(BaseModel):
    email: str

class EmailVerifyReq(BaseModel):
    email: str
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


# ── Helpers ───────────────────────────────────────────────────────────────────

def _phone(raw: str) -> Phone:
    try:
        return normalize_phone(raw)
    except IdentityError as e:
        raise HTTPException(422, str(e))


def _email(raw: str) -> str:
    try:
        return normalize_email(raw)
    except IdentityError as e:
        raise HTTPException(422, str(e))


def _limit(destination: str, request: Request) -> None:
    try:
        rate_limit.check_and_record(destination, request.client.host if request.client else None)
    except rate_limit.RateLimited as e:
        raise HTTPException(429, MSG_TOO_MANY, headers={"Retry-After": str(e.retry_after_s)})


def _mask(e164: str) -> str:
    return e164[:4] + "*" * max(0, len(e164) - 6) + e164[-2:]


async def _find_phone_user(pool, phone: Phone) -> Optional[str]:
    """User id for this number, matching E.164 rows and rows stored by older builds.

    A legacy row ("13800138000", "+86 138 0013 8000", …) is rewritten to E.164 on login,
    unless another row already holds the E.164 value: then nothing is rewritten or merged,
    the collision is logged, and the E.164 row wins.
    """
    rows = await pool.fetch(
        "SELECT id, phone FROM users"
        " WHERE phone = $1 OR regexp_replace(phone, '[^0-9]', '', 'g') = ANY($2::text[])"
        " ORDER BY created_at",
        phone.e164, legacy_phone_digits(phone))
    if not rows:
        return None
    exact = [r for r in rows if r["phone"] == phone.e164]
    legacy = [r for r in rows if r["phone"] != phone.e164]
    if exact:
        if legacy:
            log.warning("phone collision %s: E.164 row %s also matches legacy rows %s; not merged",
                        _mask(phone.e164), exact[0]["id"], [str(r["id"]) for r in legacy])
        return str(exact[0]["id"])
    if len(legacy) > 1:
        log.warning("phone collision %s: several legacy rows %s; using the oldest, not rewritten",
                    _mask(phone.e164), [str(r["id"]) for r in legacy])
        return str(legacy[0]["id"])
    uid = str(legacy[0]["id"])
    try:
        await pool.execute(
            "UPDATE users SET phone = $2, updated_at = NOW() WHERE id = $1", uid, phone.e164)
    except asyncpg.UniqueViolationError:   # another row took the E.164 value meanwhile
        log.warning("phone collision %s: could not rewrite legacy row %s to E.164; kept as is",
                    _mask(phone.e164), uid)
    return uid


# ── Phone ─────────────────────────────────────────────────────────────────────

@router.post("/phone/send")
async def phone_send(req: PhoneSendReq, request: Request):
    phone = _phone(req.phone)
    _limit(f"phone:{phone.e164}", request)
    try:
        await send_sms_otp(phone)
    except Exception as e:
        raise HTTPException(500, f"SMS failed: {e}")
    return {"message": "OTP sent"}


@router.post("/phone/verify", response_model=AuthOut)
async def phone_verify(req: PhoneVerifyReq):
    phone = _phone(req.phone)
    if not verify_code(phone.e164, req.code):
        raise HTTPException(400, "Invalid or expired code")
    pool = Database.pool()
    uid = await _find_phone_user(pool, phone)
    is_new = uid is None
    if is_new:
        uid = str(uuid.uuid4())
        await pool.execute(
            "INSERT INTO users (id, phone, created_at) VALUES ($1,$2,NOW())",
            uid, phone.e164)
    return AuthOut(user_id=uid, token=create_jwt(uid), is_new_user=is_new)


# ── Email ─────────────────────────────────────────────────────────────────────

@router.post("/email/send")
async def email_send(req: EmailSendReq, request: Request):
    email = _email(req.email)
    _limit(f"email:{email}", request)
    try:
        await send_email_otp(email)
    except Exception as e:
        raise HTTPException(500, f"Email failed: {e}")
    return {"message": "OTP sent"}


@router.post("/email/verify", response_model=AuthOut)
async def email_verify(req: EmailVerifyReq):
    email = _email(req.email)
    if not verify_code(email, req.code):
        raise HTTPException(400, "Invalid or expired code")
    pool = Database.pool()
    # users.email is CITEXT, so rows stored with uppercase letters by older builds still match.
    row  = await pool.fetchrow("SELECT id FROM users WHERE email=$1", email)
    is_new = row is None
    if is_new:
        uid = str(uuid.uuid4())
        await pool.execute(
            "INSERT INTO users (id, email, created_at) VALUES ($1,$2,NOW())",
            uid, email)
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
    email    = (payload.get("email") or "").strip().lower() or None
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
