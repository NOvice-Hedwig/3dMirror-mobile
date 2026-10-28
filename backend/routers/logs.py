import uuid
import datetime as dt
from typing import Optional
from zoneinfo import ZoneInfo
from fastapi import APIRouter, Depends, HTTPException, Header, Response
from pydantic import AwareDatetime, BaseModel
from database import Database
from auth.service import decode_jwt
import clock

router = APIRouter()


def _uid(authorization: str) -> str:
    try:
        return decode_jwt(authorization.removeprefix("Bearer "))["sub"]
    except Exception:
        raise HTTPException(401, "Invalid token")


# ── Pydantic schemas ──────────────────────────────────────────────────────────

class WorkoutPayload(BaseModel):
    type: str
    sub_type: str
    duration_min: int
    intensity: str
    with_weight: bool = False
    muscle_group: Optional[str] = None
    sets: Optional[list[dict]] = None
    estimated_kcal: Optional[int] = None


class DietPayload(BaseModel):
    meal: str
    food_name: str
    grams: Optional[float] = None
    calories: float
    protein_g: Optional[float] = None
    entry_method: str = 'manual'


class SleepPayload(BaseModel):
    date: dt.date                 # user's local date (the wake-up day)
    bedtime: AwareDatetime        # must carry a UTC offset; naive → 422
    wake_time: AwareDatetime
    quality: int
    source: str = 'manual'


class PeriodPayload(BaseModel):
    date: Optional[dt.date] = None   # user's local date; omitted → today in X-Timezone
    phase: str
    symptoms: list[str]
    intensity: int


class SupplementPayload(BaseModel):
    name: str
    dosage: Optional[str] = None
    reminder_time: Optional[dt.time] = None   # wall-clock 'HH:MM' or 'HH:MM:SS'
    reminder_enabled: bool = False


class MeasurementPayload(BaseModel):
    date: Optional[dt.date] = None   # user's local date; omitted → today in X-Timezone
    weight_kg: Optional[float] = None
    waist_cm: Optional[float] = None
    hip_cm: Optional[float] = None
    chest_cm: Optional[float] = None
    thigh_cm: Optional[float] = None


# ── Routes ────────────────────────────────────────────────────────────────────

@router.post("/workout", status_code=201)
async def log_workout(body: WorkoutPayload, authorization: str = Header(...)):
    uid = _uid(authorization)
    pool = Database.pool()
    wid = str(uuid.uuid4())
    await pool.execute(
        """INSERT INTO workout_logs
           (id, user_id, logged_at, type, sub_type, duration_min, intensity,
            with_weight, muscle_group, sets, estimated_kcal)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)""",
        wid, uid, clock.now_utc(), body.type, body.sub_type, body.duration_min,
        body.intensity, body.with_weight, body.muscle_group,
        body.sets,
        body.estimated_kcal,
    )
    return {"id": wid}


@router.post("/diet", status_code=201)
async def log_diet(body: DietPayload, authorization: str = Header(...)):
    uid = _uid(authorization)
    pool = Database.pool()
    row_id = str(uuid.uuid4())
    await pool.execute(
        """INSERT INTO diet_logs
           (id, user_id, logged_at, meal, food_name, grams, calories, protein_g, entry_method)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)""",
        row_id, uid, clock.now_utc(), body.meal, body.food_name, body.grams,
        body.calories, body.protein_g, body.entry_method,
    )
    return {"id": row_id}


# Sleep and period are one-per-day (UNIQUE (user_id, date)): a repeat log for the
# same day overwrites the existing row. 201 = created, 200 = existing row updated.
# `xmax = 0` is true only for a freshly inserted row.

@router.post("/sleep", status_code=201)
async def log_sleep(body: SleepPayload, response: Response,
                    authorization: str = Header(...)):
    uid = _uid(authorization)
    pool = Database.pool()
    row = await pool.fetchrow(
        """INSERT INTO sleep_logs (id, user_id, date, bedtime, wake_time, quality, source)
           VALUES ($1,$2,$3,$4,$5,$6,$7)
           ON CONFLICT (user_id, date) DO UPDATE SET
             bedtime   = EXCLUDED.bedtime,
             wake_time = EXCLUDED.wake_time,
             quality   = EXCLUDED.quality,
             source    = EXCLUDED.source
           RETURNING id, (xmax = 0) AS inserted""",
        str(uuid.uuid4()), uid, body.date, body.bedtime, body.wake_time,
        body.quality, body.source,
    )
    if not row["inserted"]:
        response.status_code = 200
    return {"id": str(row["id"])}


@router.post("/period", status_code=201)
async def log_period(body: PeriodPayload, response: Response,
                     authorization: str = Header(...),
                     tz: ZoneInfo = Depends(clock.user_timezone)):
    uid = _uid(authorization)
    pool = Database.pool()
    row = await pool.fetchrow(
        """INSERT INTO period_logs (id, user_id, date, phase, symptoms, intensity)
           VALUES ($1,$2,$3,$4,$5,$6)
           ON CONFLICT (user_id, date) DO UPDATE SET
             phase     = EXCLUDED.phase,
             symptoms  = EXCLUDED.symptoms,
             intensity = EXCLUDED.intensity
           RETURNING id, (xmax = 0) AS inserted""",
        str(uuid.uuid4()), uid, body.date or clock.local_today(tz),
        body.phase, body.symptoms, body.intensity,
    )
    if not row["inserted"]:
        response.status_code = 200
    return {"id": str(row["id"])}


@router.post("/supplements", status_code=201)
async def log_supplements(body: list[SupplementPayload], authorization: str = Header(...)):
    uid = _uid(authorization)
    pool = Database.pool()
    logged_at = clock.now_utc()
    rows = [
        (str(uuid.uuid4()), uid, logged_at, item.name, item.dosage,
         item.reminder_time, item.reminder_enabled)
        for item in body
    ]
    await pool.executemany(
        "INSERT INTO supplement_logs"
        " (id, user_id, logged_at, name, dosage, reminder_time, reminder_enabled)"
        " VALUES ($1,$2,$3,$4,$5,$6,$7)",
        rows,
    )
    return {"count": len(rows)}


@router.put("/measurements", status_code=200)
async def update_measurements(body: MeasurementPayload, authorization: str = Header(...),
                              tz: ZoneInfo = Depends(clock.user_timezone)):
    uid = _uid(authorization)
    pool = Database.pool()
    day = body.date or clock.local_today(tz)
    snap_id = str(uuid.uuid4())
    measurements = {k: v for k, v in body.model_dump(exclude={"date"}).items() if v is not None}
    await pool.execute(
        """INSERT INTO body_snapshots (id, user_id, date, measurements)
           VALUES ($1,$2,$3,$4)
           ON CONFLICT (user_id, date) DO UPDATE SET
             measurements = body_snapshots.measurements || EXCLUDED.measurements""",
        snap_id, uid, day, measurements,
    )
    return {"date": day.isoformat()}


@router.get("/today-stats")
async def today_stats(authorization: str = Header(...),
                      tz: ZoneInfo = Depends(clock.user_timezone)):
    uid = _uid(authorization)
    pool = Database.pool()
    today = clock.local_today(tz)

    # logged_at is a UTC instant; convert it to the user's local date before comparing.
    kcal_row = await pool.fetchrow(
        "SELECT COALESCE(SUM(calories), 0) AS total FROM diet_logs "
        "WHERE user_id=$1 AND (logged_at AT TIME ZONE $2)::date = $3",
        uid, tz.key, today,
    )

    sleep_row = await pool.fetchrow(
        "SELECT bedtime, wake_time FROM sleep_logs "
        "WHERE user_id=$1 AND date = $2 LIMIT 1",
        uid, today,
    )
    sleep_hours = 0.0
    if sleep_row and sleep_row["bedtime"] and sleep_row["wake_time"]:
        delta = sleep_row["wake_time"] - sleep_row["bedtime"]
        sleep_hours = round(delta.total_seconds() / 3600, 2)

    workout_row = await pool.fetchrow(
        "SELECT COALESCE(SUM(duration_min), 0) AS total FROM workout_logs "
        "WHERE user_id=$1 AND (logged_at AT TIME ZONE $2)::date = $3",
        uid, tz.key, today,
    )

    return {
        "total_kcal_in":   float(kcal_row["total"]),
        "sleep_hours":     sleep_hours,
        "workout_minutes": int(workout_row["total"]),
    }
