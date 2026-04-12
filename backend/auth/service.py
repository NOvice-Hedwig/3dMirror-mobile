"""
auth/service.py
Handles: Aliyun SMS (CN), Twilio SMS (intl), Email OTP, Apple JWT, JWT tokens
"""

import os, re, random, string, time, hashlib, hmac, base64
import urllib.parse
from datetime import datetime, timedelta, timezone
from typing import Optional

import httpx
import jwt

# ── Config ────────────────────────────────────────────────────────────────────

JWT_SECRET      = os.environ.get("JWT_SECRET", "dev-secret-change-in-prod")
JWT_ALGORITHM   = "HS256"
JWT_EXPIRE_DAYS = 90

ALIYUN_KEY_ID   = os.getenv("ALIYUN_ACCESS_KEY_ID",  "")
ALIYUN_KEY_SEC  = os.getenv("ALIYUN_ACCESS_KEY_SEC",  "")
ALIYUN_SIGN     = os.getenv("ALIYUN_SMS_SIGN",        "3D Mirror")
ALIYUN_TEMPLATE = os.getenv("ALIYUN_SMS_TEMPLATE",    "SMS_000000")

TWILIO_SID      = os.getenv("TWILIO_ACCOUNT_SID",  "")
TWILIO_TOKEN    = os.getenv("TWILIO_AUTH_TOKEN",    "")
TWILIO_FROM     = os.getenv("TWILIO_FROM_NUMBER",   "+10000000000")

SENDGRID_KEY    = os.getenv("SENDGRID_API_KEY", "")
EMAIL_FROM      = os.getenv("EMAIL_FROM", "noreply@3dmirror.app")

APPLE_BUNDLE_ID = os.getenv("APPLE_BUNDLE_ID", "com.yourcompany.3dmirror")

OTP_TTL = 300   # 5 minutes

# In-memory store (swap for Redis in production)
_otps: dict[str, tuple[str, float]] = {}


# ── OTP ───────────────────────────────────────────────────────────────────────

def _gen_otp() -> str:
    return "".join(random.choices(string.digits, k=6))

def _save_otp(key: str, otp: str):
    _otps[key] = (otp, time.time() + OTP_TTL)

def verify_code(key: str, code: str) -> bool:
    entry = _otps.get(key)
    if not entry:
        return False
    stored, expires = entry
    if time.time() > expires:
        del _otps[key]
        return False
    if stored != code:
        return False
    del _otps[key]
    return True


# ── SMS ───────────────────────────────────────────────────────────────────────

def _is_cn(phone: str) -> bool:
    return phone.startswith("+86") or bool(re.match(r"^1[3-9]\d{9}$", phone))

async def send_sms_otp(phone: str) -> str:
    otp = _gen_otp()
    _save_otp(phone, otp)
    if _is_cn(phone):
        await _aliyun(phone.lstrip("+86").lstrip("+"), otp)
    else:
        await _twilio(phone, otp)
    return otp


async def _aliyun(number: str, otp: str):
    nonce = "".join(random.choices(string.ascii_letters + string.digits, k=16))
    ts    = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    params = {
        "AccessKeyId":     ALIYUN_KEY_ID,
        "Action":          "SendSms",
        "Format":          "JSON",
        "PhoneNumbers":    number,
        "SignName":        ALIYUN_SIGN,
        "SignatureMethod": "HMAC-SHA1",
        "SignatureNonce":  nonce,
        "SignatureVersion":"1.0",
        "TemplateCode":    ALIYUN_TEMPLATE,
        "TemplateParam":   f'{{"code":"{otp}"}}',
        "Timestamp":       ts,
        "Version":         "2017-05-25",
    }
    qs = "&".join(f"{urllib.parse.quote(k,'~')}={urllib.parse.quote(str(v),'~')}"
                  for k, v in sorted(params.items()))
    sts = f"GET&%2F&{urllib.parse.quote(qs,'~')}"
    sig = base64.b64encode(
        hmac.new((ALIYUN_KEY_SEC + "&").encode(), sts.encode(), hashlib.sha1).digest()
    ).decode()
    params["Signature"] = sig
    async with httpx.AsyncClient() as c:
        r = await c.get("https://dysmsapi.aliyuncs.com", params=params, timeout=8)
        data = r.json()
        if data.get("Code") != "OK":
            raise RuntimeError(f"Aliyun error: {data}")


async def _twilio(phone: str, otp: str):
    url = f"https://api.twilio.com/2010-04-01/Accounts/{TWILIO_SID}/Messages.json"
    async with httpx.AsyncClient() as c:
        r = await c.post(url,
            auth=(TWILIO_SID, TWILIO_TOKEN),
            data={"From": TWILIO_FROM, "To": phone,
                  "Body": f"【3D Mirror】Your code: {otp}. Valid 5 min."},
            timeout=8)
        if r.status_code not in (200, 201):
            raise RuntimeError(f"Twilio error: {r.text}")


# ── Email ─────────────────────────────────────────────────────────────────────

async def send_email_otp(email: str) -> str:
    otp = _gen_otp()
    _save_otp(email, otp)
    async with httpx.AsyncClient() as c:
        r = await c.post(
            "https://api.sendgrid.com/v3/mail/send",
            headers={"Authorization": f"Bearer {SENDGRID_KEY}"},
            json={
                "personalizations": [{"to": [{"email": email}]}],
                "from": {"email": EMAIL_FROM, "name": "3D Mirror"},
                "subject": "Your 3D Mirror verification code",
                "content": [{"type": "text/plain",
                              "value": f"Your code is {otp}. Valid for 5 minutes.\n\n— 3D Mirror"}],
            },
            timeout=8)
        if r.status_code not in (200, 202):
            raise RuntimeError(f"SendGrid error: {r.text}")
    return otp


# ── Apple ─────────────────────────────────────────────────────────────────────

async def verify_apple_token(identity_token: str) -> dict:
    async with httpx.AsyncClient() as c:
        r = await c.get("https://appleid.apple.com/auth/keys", timeout=8)
        keys = r.json()["keys"]

    from jwt.algorithms import RSAAlgorithm
    kid = jwt.get_unverified_header(identity_token)["kid"]
    matching = next((k for k in keys if k["kid"] == kid), None)
    if not matching:
        raise ValueError("Apple public key not found")
    public_key = RSAAlgorithm.from_jwk(matching)
    return jwt.decode(
        identity_token, public_key,
        algorithms=["RS256"], audience=APPLE_BUNDLE_ID,
    )


# ── JWT ───────────────────────────────────────────────────────────────────────

def create_jwt(user_id: str) -> str:
    return jwt.encode(
        {"sub": user_id,
         "iat": datetime.now(timezone.utc),
         "exp": datetime.now(timezone.utc) + timedelta(days=JWT_EXPIRE_DAYS)},
        JWT_SECRET, algorithm=JWT_ALGORITHM,
    )

def decode_jwt(token: str) -> dict:
    return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
