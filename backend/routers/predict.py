from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel
from database import Database
from auth.service import decode_jwt

router = APIRouter()


class PredictedMetrics(BaseModel):
    weeks: int
    predicted_weight_kg: float
    weight_delta_kg: float
    predicted_body_fat_pct: float
    body_fat_delta_pct: float
    predicted_waist_cm: float
    waist_delta_cm: float
    confidence: float
    data_points: int


def _uid(authorization: str) -> str:
    try:
        return decode_jwt(authorization.removeprefix("Bearer "))["sub"]
    except Exception:
        raise HTTPException(401, "Invalid token")


@router.get("", response_model=PredictedMetrics)
async def get_predict(weeks: int = 4, authorization: str = Header(...)):
    uid  = _uid(authorization)
    pool = Database.pool()
    rows = await pool.fetch(
        """SELECT body_data, created_at FROM sessions
           WHERE user_id = $1
           ORDER BY created_at DESC LIMIT 30""",
        uid,
    )

    if len(rows) < 2:
        raise HTTPException(400, "数据不足，请至少记录 2 次")

    newest = rows[0]
    oldest = rows[-1]

    days_span = (newest["created_at"] - oldest["created_at"]).days
    if days_span == 0:
        days_span = 1

    target_days = weeks * 7

    weight_now = float(newest["body_data"].get("weight_kg", 0))
    weight_old = float(oldest["body_data"].get("weight_kg", weight_now))
    daily_weight = (weight_now - weight_old) / days_span
    predicted_weight = round(weight_now + daily_weight * target_days, 1)

    fat_now = float(newest["body_data"].get("body_fat_pct") or 20.0)
    fat_old = float(oldest["body_data"].get("body_fat_pct") or fat_now)
    daily_fat = (fat_now - fat_old) / days_span
    predicted_fat = round(fat_now + daily_fat * target_days, 1)

    waist_now = float(newest["body_data"].get("waist_cm") or 75.0)
    waist_old = float(oldest["body_data"].get("waist_cm") or waist_now)
    daily_waist = (waist_now - waist_old) / days_span
    predicted_waist = round(waist_now + daily_waist * target_days, 1)

    confidence = min(0.95, (len(rows) / 10) * 0.5 + (min(days_span, 90) / 90) * 0.5)

    return PredictedMetrics(
        weeks=weeks,
        predicted_weight_kg=predicted_weight,
        weight_delta_kg=round(predicted_weight - weight_now, 1),
        predicted_body_fat_pct=predicted_fat,
        body_fat_delta_pct=round(predicted_fat - fat_now, 1),
        predicted_waist_cm=predicted_waist,
        waist_delta_cm=round(predicted_waist - waist_now, 1),
        confidence=round(confidence, 2),
        data_points=len(rows),
    )
