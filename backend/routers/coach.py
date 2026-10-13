from datetime import datetime
from fastapi import APIRouter, Header, HTTPException
from pydantic import BaseModel
from database import Database
from auth.service import decode_jwt

router = APIRouter()


def _uid(authorization: str) -> str:
    try:
        return decode_jwt(authorization.removeprefix("Bearer "))["sub"]
    except Exception:
        raise HTTPException(401, "Invalid token")


class TargetAvatarParams(BaseModel):
    height_norm:   float
    weight_norm:   float
    body_fat_norm: float
    waist_norm:    float
    hip_norm:      float
    shoulder_norm: float
    muscle_norm:   float
    gender:        str


class SuggestionCard(BaseModel):
    category: str   # 'training' | 'nutrition' | 'recovery'
    title:    str
    body:     str
    priority: int   # 1=高 2=中 3=低


class CoachSuggestionsResponse(BaseModel):
    cards:        list[SuggestionCard]
    data_points:  int
    generated_at: str


@router.get("/suggestions", response_model=CoachSuggestionsResponse)
async def get_suggestions(authorization: str = Header(...)):
    uid  = _uid(authorization)
    pool = Database.pool()
    rows = await pool.fetch(
        "SELECT body_data, activity_data, created_at"
        " FROM sessions"
        " WHERE user_id = $1"
        "   AND created_at >= now() - interval '7 days'"
        " ORDER BY created_at DESC",
        uid,
    )

    cards: list[SuggestionCard] = []

    # 运动频率
    workout_days = len({r["created_at"].date() for r in rows})
    if workout_days == 0:
        cards.append(SuggestionCard(
            category="training",
            title="本周尚未开始训练",
            body="建议本周完成 3 次训练，从 30 分钟有氧开始。",
            priority=1,
        ))
    elif workout_days <= 2:
        cards.append(SuggestionCard(
            category="training",
            title=f"本周已训练 {workout_days} 天",
            body="距离目标还有差距，明天安排一次力量训练效果更佳。",
            priority=2,
        ))
    else:
        cards.append(SuggestionCard(
            category="training",
            title=f"本周已训练 {workout_days} 天，保持！",
            body="训练频率良好，注意保留至少1天恢复日。",
            priority=3,
        ))

    # 体重趋势
    weights = [
        r["body_data"].get("weight_kg")
        for r in rows
        if r["body_data"].get("weight_kg")
    ]
    if len(weights) >= 2:
        delta = weights[0] - weights[-1]
        if abs(delta) < 0.3:
            cards.append(SuggestionCard(
                category="nutrition",
                title="体重保持稳定",
                body="若目标是减脂，可尝试每日增加 200kcal 热量缺口。",
                priority=2,
            ))
        elif delta > 0:
            cards.append(SuggestionCard(
                category="nutrition",
                title=f"本周体重上升 {delta:.1f}kg",
                body="检查近期饮食，减少精制碳水和夜间进食。",
                priority=1,
            ))
        else:
            cards.append(SuggestionCard(
                category="nutrition",
                title=f"本周体重下降 {abs(delta):.1f}kg",
                body="进展良好！确保蛋白质摄入充足（每公斤体重 1.6g）。",
                priority=3,
            ))
    else:
        cards.append(SuggestionCard(
            category="nutrition",
            title="开始记录饮食",
            body="记录饮食是减脂成功的关键，从今天的一餐开始。",
            priority=2,
        ))

    # 恢复建议
    has_strength = any(
        r["activity_data"] and r["activity_data"].get("type") == "无氧"
        for r in rows
    )
    if has_strength:
        cards.append(SuggestionCard(
            category="recovery",
            title="力量训练后注意恢复",
            body="训练后 30 分钟内补充蛋白质，睡眠 7-9 小时促进肌肉合成。",
            priority=2,
        ))
    else:
        cards.append(SuggestionCard(
            category="recovery",
            title="睡眠是最好的恢复",
            body="保持每晚 7-9 小时睡眠，有助于体脂代谢和体力恢复。",
            priority=3,
        ))

    return CoachSuggestionsResponse(
        cards=sorted(cards, key=lambda c: c.priority),
        data_points=len(rows),
        generated_at=datetime.utcnow().isoformat(),
    )


@router.put("/target")
async def put_target(
    body: TargetAvatarParams,
    authorization: str = Header(...),
):
    uid  = _uid(authorization)
    pool = Database.pool()
    await pool.execute(
        "UPDATE users SET target_avatar_params = $2 WHERE id = $1",
        uid,
        body.model_dump(),
    )
    return {"ok": True}
