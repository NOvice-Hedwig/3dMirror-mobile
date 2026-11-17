"""Coach cards carry a stable `code` + `params` for the app to translate; `title`/`body`
stay exactly the Chinese text older app builds display."""

from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import pytest

# Import the app first, as at startup: main.py loads .env before auth.service reads DEV_MODE
# at import time. Importing routers.coach (→ auth.service) first would leave DEV_MODE off for
# the rest of the session and break test_auth.py (see ONBOARDING §8.2 #5).
import main  # noqa: F401
from routers.coach import SuggestionCard, suggestion_cards

TZ = ZoneInfo("Asia/Shanghai")
NOW = datetime(2026, 11, 16, 4, 0, tzinfo=timezone.utc)   # 12:00 in Shanghai


def row(days_ago: float, weight=None, activity=None):
    return {"created_at": NOW - timedelta(days=days_ago),
            "body_data": {"weight_kg": weight} if weight is not None else {},
            "activity_data": activity}


def by_category(cards):
    return {c.category: c for c in cards}


def test_no_sessions():
    c = by_category(suggestion_cards([], TZ))
    assert (c["training"].code, c["training"].params) == ("training_not_started", {})
    assert c["training"].title == "本周尚未开始训练"
    assert c["training"].body == "建议本周完成 3 次训练，从 30 分钟有氧开始。"
    assert c["nutrition"].code == "diet_start_logging"
    assert c["nutrition"].title == "开始记录饮食"
    assert c["recovery"].code == "recovery_sleep"
    assert c["recovery"].title == "睡眠是最好的恢复"


@pytest.mark.parametrize("days,code,title", [
    (1, "training_few_days", "本周已训练 1 天"),
    (2, "training_few_days", "本周已训练 2 天"),
    (3, "training_on_track", "本周已训练 3 天，保持！"),
])
def test_training_days(days, code, title):
    rows = [row(i) for i in range(days)]
    t = by_category(suggestion_cards(rows, TZ))["training"]
    assert (t.code, t.params, t.title) == (code, {"days": days}, title)
    assert isinstance(t.params["days"], int)


@pytest.mark.parametrize("newest,oldest,code,params,title", [
    (60.1, 60.0, "weight_stable", {}, "体重保持稳定"),
    (61.26, 60.0, "weight_up", {"delta_kg": 1.3}, "本周体重上升 1.3kg"),
    (59.0, 60.5, "weight_down", {"delta_kg": 1.5}, "本周体重下降 1.5kg"),
])
def test_weight_trend(newest, oldest, code, params, title):
    rows = [row(0, newest), row(3, oldest)]   # newest first, as the query orders them
    n = by_category(suggestion_cards(rows, TZ))["nutrition"]
    assert (n.code, n.params, n.title) == (code, params, title)


def test_recovery_after_strength():
    r = by_category(suggestion_cards([row(0, activity={"type": "无氧"})], TZ))["recovery"]
    assert r.code == "recovery_after_strength"
    assert r.title == "力量训练后注意恢复"
    assert r.body == "训练后 30 分钟内补充蛋白质，睡眠 7-9 小时促进肌肉合成。"


def test_cards_are_sorted_by_priority():
    cards = suggestion_cards([row(0, 61.0), row(2, 60.0)], TZ)
    assert [c.priority for c in cards] == sorted(c.priority for c in cards)


def test_json_shape_keeps_old_fields_and_adds_code_and_params():
    card = suggestion_cards([row(0, 61.0), row(2, 60.0)], TZ)[0]
    j = card.model_dump(mode="json")
    assert set(j) == {"category", "code", "params", "title", "body", "priority"}
    assert j["code"] == "weight_up" and j["params"] == {"delta_kg": 1.0}


def test_every_code_is_known():
    # The full set the app translates (flutter_app/lib/core/l10n/coach_text.dart).
    known = {"training_not_started", "training_few_days", "training_on_track",
             "weight_stable", "weight_up", "weight_down", "diet_start_logging",
             "recovery_after_strength", "recovery_sleep"}
    seen = set()
    for rows in ([], [row(0)], [row(i) for i in range(4)],
                 [row(0, 60.1), row(1, 60.0)], [row(0, 62.0), row(1, 60.0)],
                 [row(0, 58.0), row(1, 60.0)], [row(0, activity={"type": "无氧"})]):
        seen |= {c.code for c in suggestion_cards(rows, TZ)}
    assert seen == known
    assert SuggestionCard.model_fields["code"].is_required()
