from datetime import date, datetime
from typing import Optional

from fastapi import APIRouter, Header, HTTPException
from pydantic import BaseModel

from auth.service import decode_jwt
from database import Database

router = APIRouter()


def _uid(authorization: str) -> str:
    try:
        return decode_jwt(authorization.removeprefix("Bearer "))["sub"]
    except Exception:
        raise HTTPException(401, "Invalid token")


# ── Pydantic models ───────────────────────────────────────────────────────────

class ChallengeGoal(BaseModel):
    goal_type:          str             # 'weight' | 'body_fat' | 'waist' | 'composite'
    target_weight_kg:   Optional[float] = None
    target_body_fat:    Optional[float] = None
    target_waist_cm:    Optional[float] = None
    start_date:         date            # ISO date (YYYY-MM-DD)
    end_date:           date            # ISO date, typically start_date + 30 days


class ChallengeProgress(BaseModel):
    goal:             ChallengeGoal
    current_weight:   Optional[float]
    current_body_fat: Optional[float]
    current_waist:    Optional[float]
    progress_pct:     float   # 0.0 – 100.0
    days_remaining:   int
    is_completed:     bool
    discount_eligible: bool   # progress_pct >= 100


# ── Helpers ───────────────────────────────────────────────────────────────────

def _pct_single(start: Optional[float], current: Optional[float],
                target: Optional[float]) -> Optional[float]:
    """Return progress percentage for one metric (lower = better), or None if missing."""
    if start is None or current is None or target is None:
        return None
    total_delta = start - target
    if abs(total_delta) < 0.001:
        return 100.0
    actual_delta = start - current
    return (actual_delta / total_delta) * 100.0


# ── POST /challenge/goal ──────────────────────────────────────────────────────

@router.post("/goal")
async def set_goal(body: ChallengeGoal, authorization: str = Header(...)):
    uid  = _uid(authorization)
    pool = Database.pool()
    await pool.execute(
        "UPDATE users SET challenge_goal = $2, challenge_start_date = CURRENT_DATE"
        " WHERE id = $1",
        uid,
        body.model_dump(mode="json"),   # dates → ISO strings for the JSONB column
    )
    return {"ok": True}


# ── GET /challenge/progress ───────────────────────────────────────────────────

@router.get("/progress", response_model=ChallengeProgress)
async def get_progress(authorization: str = Header(...)):
    uid  = _uid(authorization)
    pool = Database.pool()

    # 1. Read saved goal
    user_row = await pool.fetchrow(
        "SELECT challenge_goal, challenge_start_date FROM users WHERE id = $1", uid)
    if not user_row or not user_row["challenge_goal"]:
        raise HTTPException(404, "未设定挑战目标")

    start_date = user_row["challenge_start_date"]   # Python date object
    goal       = ChallengeGoal(**user_row["challenge_goal"])

    # 2. Latest session body data (current values)
    latest_row = await pool.fetchrow(
        "SELECT body_data FROM sessions WHERE user_id = $1"
        " ORDER BY created_at DESC LIMIT 1",
        uid,
    )
    body_data: dict = latest_row["body_data"] if latest_row else {}

    current_weight   = body_data.get("weight_kg")
    current_body_fat = body_data.get("body_fat_pct")
    current_waist    = body_data.get("waist_cm")

    # 3. Start-day session body data (baseline values)
    start_row = await pool.fetchrow(
        "SELECT body_data FROM sessions WHERE user_id = $1"
        "   AND DATE(created_at) = $2"
        " ORDER BY created_at LIMIT 1",
        uid, start_date,
    )
    start_body: dict = start_row["body_data"] if start_row else {}

    start_weight   = start_body.get("weight_kg",   current_weight)
    start_body_fat = start_body.get("body_fat_pct", current_body_fat)
    start_waist    = start_body.get("waist_cm",    current_waist)

    # 4. Calculate progress_pct by goal_type
    gt = goal.goal_type
    if gt == "weight":
        raw = _pct_single(start_weight, current_weight, goal.target_weight_kg)
        pct = raw if raw is not None else 0.0
    elif gt == "body_fat":
        raw = _pct_single(start_body_fat, current_body_fat, goal.target_body_fat)
        pct = raw if raw is not None else 0.0
    elif gt == "waist":
        raw = _pct_single(start_waist, current_waist, goal.target_waist_cm)
        pct = raw if raw is not None else 0.0
    else:  # composite — average of available metrics
        parts = []
        pw = _pct_single(start_weight,   current_weight,   goal.target_weight_kg)
        pb = _pct_single(start_body_fat, current_body_fat, goal.target_body_fat)
        pw2 = _pct_single(start_waist,   current_waist,    goal.target_waist_cm)
        if pw  is not None: parts.append(pw)
        if pb  is not None: parts.append(pb)
        if pw2 is not None: parts.append(pw2)
        pct = sum(parts) / len(parts) if parts else 0.0

    pct = max(0.0, min(100.0, pct))

    # 5. Days remaining
    today    = date.today()
    days_remaining = max(0, (goal.end_date - today).days)

    return ChallengeProgress(
        goal             = goal,
        current_weight   = current_weight,
        current_body_fat = current_body_fat,
        current_waist    = current_waist,
        progress_pct     = round(pct, 2),
        days_remaining   = days_remaining,
        is_completed     = pct >= 100.0,
        discount_eligible = pct >= 100.0,
    )


# ── DELETE /challenge/goal ────────────────────────────────────────────────────

@router.delete("/goal")
async def abandon_goal(authorization: str = Header(...)):
    uid  = _uid(authorization)
    pool = Database.pool()
    await pool.execute(
        "UPDATE users SET challenge_goal = NULL, challenge_start_date = NULL"
        " WHERE id = $1",
        uid,
    )
    return {"ok": True}
