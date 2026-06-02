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
