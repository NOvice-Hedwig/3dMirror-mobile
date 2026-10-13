-- 3D Mirror — Postgres Schema
-- Run: psql $DATABASE_URL -f migration.sql

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "citext";

-- ── Users ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone         TEXT        UNIQUE,
    email         CITEXT      UNIQUE,
    apple_id      TEXT        UNIQUE,
    display_name  TEXT,
    locale        TEXT        NOT NULL DEFAULT 'zh',
    gender        TEXT,
    height_cm     NUMERIC(5,1),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT at_least_one_auth
        CHECK (phone IS NOT NULL OR email IS NOT NULL OR apple_id IS NOT NULL)
);

-- ── Sessions ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sessions (
    id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    body_data     JSONB       NOT NULL,
    avatar_params JSONB       NOT NULL,
    activity_data JSONB,
    thumbnail_url TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS sessions_user_date
    ON sessions (user_id, created_at DESC);

-- ── Body Photos ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS body_photos (
    id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id      UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id   UUID        REFERENCES sessions(id) ON DELETE SET NULL,
    angle        TEXT        NOT NULL CHECK (angle IN ('front', 'side', 'back')),
    file_path    TEXT        NOT NULL,
    llm_analysis JSONB,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS body_photos_user
    ON body_photos (user_id, created_at DESC);

-- ── Summary view ──────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW session_summary AS
SELECT
    s.id,
    s.user_id,
    s.created_at,
    (s.body_data->>'weight_kg')::FLOAT     AS weight_kg,
    (s.body_data->>'body_fat_pct')::FLOAT  AS body_fat_pct,
    (s.body_data->>'waist_cm')::FLOAT      AS waist_cm,
    s.activity_data->>'workout_type'        AS workout_type,
    s.thumbnail_url
FROM sessions s;

-- ── Workout Logs ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS workout_logs (
    id             UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id        UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    logged_at      TIMESTAMPTZ DEFAULT NOW(),
    type           TEXT        NOT NULL,
    sub_type       TEXT        NOT NULL,
    duration_min   INT         NOT NULL,
    intensity      TEXT        NOT NULL,
    with_weight    BOOLEAN     NOT NULL DEFAULT FALSE,
    muscle_group   TEXT,
    sets           JSONB,
    estimated_kcal INT
);

CREATE INDEX IF NOT EXISTS idx_workout_user_date
    ON workout_logs (user_id, logged_at);

-- ── Patch columns (归档自临时执行的 ALTER TABLE) ───────────────────────────────
ALTER TABLE users ADD COLUMN IF NOT EXISTS target_avatar_params  JSONB;
ALTER TABLE users ADD COLUMN IF NOT EXISTS challenge_goal        JSONB;
ALTER TABLE users ADD COLUMN IF NOT EXISTS challenge_start_date  DATE;

-- ── Daily log tables (same DDL as scripts/create_log_tables.py) ──────────────
CREATE TABLE IF NOT EXISTS diet_logs (
    id           UUID          DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id      UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    logged_at    TIMESTAMPTZ   DEFAULT NOW(),
    meal         TEXT          NOT NULL CHECK (meal IN ('早餐','午餐','晚餐','加餐')),
    food_name    TEXT          NOT NULL,
    grams        NUMERIC(6,1),
    calories     NUMERIC(7,1)  NOT NULL,
    protein_g    NUMERIC(6,1),
    entry_method TEXT          NOT NULL DEFAULT 'manual'
);

CREATE INDEX IF NOT EXISTS idx_diet_user_date
    ON diet_logs (user_id, logged_at);

CREATE TABLE IF NOT EXISTS sleep_logs (
    id        UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id   UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date      DATE        NOT NULL,
    bedtime   TIMESTAMPTZ NOT NULL,
    wake_time TIMESTAMPTZ NOT NULL,
    quality   SMALLINT    CHECK (quality BETWEEN 1 AND 5),
    source    TEXT        NOT NULL DEFAULT 'manual',
    UNIQUE (user_id, date)
);

CREATE TABLE IF NOT EXISTS period_logs (
    id        UUID     DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id   UUID     NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date      DATE     NOT NULL,
    phase     TEXT     NOT NULL CHECK (phase IN ('start','ongoing','end')),
    symptoms  TEXT[]   NOT NULL DEFAULT '{}',
    intensity SMALLINT CHECK (intensity BETWEEN 1 AND 3),
    UNIQUE (user_id, date)
);

CREATE TABLE IF NOT EXISTS supplement_logs (
    id               UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id          UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    logged_at        TIMESTAMPTZ DEFAULT NOW(),
    name             TEXT        NOT NULL,
    dosage           TEXT,
    reminder_time    TIME,
    reminder_enabled BOOLEAN     NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_supplement_user_date
    ON supplement_logs (user_id, logged_at);

CREATE TABLE IF NOT EXISTS body_snapshots (
    id           UUID  DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id      UUID  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date         DATE  NOT NULL,
    measurements JSONB NOT NULL,
    UNIQUE (user_id, date)
);
