# 3D Mirror — Developer Onboarding

> Last updated 2026-10-12 (first written 2026-10-10). Reflects the code on `main`.
> Product context lives in [brief.md](brief.md), visual rules in [design-system/MASTER.md](design-system/MASTER.md).
> The original [README.md](README.md) (Chinese) is **out of date**. Where they disagree, trust this file.

**What it is:** a mobile app for women aged 20–35 who are new to fat loss. Users log body metrics, workouts, diet and sleep. The app shows a stylised body avatar, simple trend predictions and coaching cards. The look is "editorial luxury": ivory, charcoal and a gold accent.

**State of the build:** an MVP in progress. Auth, session logging, daily logs, prediction, coach and challenge all have backend and UI, and the full stack runs end to end on the Android emulator. The 3D avatar is **not connected**: a Flutter `CustomPaint` silhouette stands in for it, and the Unity side is just five C# scripts.

---

## ⚠️ Read first

- **Resolved this week (2026-10-10 → 10-12):** the DB-layer runtime failures (JSON, dates, period date, duplicate-day logs), the incomplete `migration.sql`, the failing 401 test, the tracked `backend/.env`, and timezone handling of log dates. The `JWT_SECRET` was rotated and `backend/.env` is no longer tracked. Details in [§8.1](#81-resolved-this-week).
- **Time rule:** calendar dates are always the user's local date. The app sends its IANA timezone in an `X-Timezone` header, and instants are timezone-aware UTC. See [§6 "Time rule"](#time-rule-since-2026-10-12) before touching anything date-related.
- **Still open, most important first:** the Unity avatar isn't wired up, photo analysis results are unused, i18n strings aren't used, supplement reminders aren't scheduled, and two test problems remain. See [§8.2](#82-open-issues).

---

## 1. Tech stack and key dependencies

### Monorepo layout

| Part | Tech | Status |
|---|---|---|
| `flutter_app/` | Flutter (Dart), Riverpod, GoRouter | Main client. iOS first; Android, web and desktop scaffolds exist |
| `backend/` | FastAPI + asyncpg on Postgres 16 | Working API, raw SQL, no ORM |
| `unity_project/` | Unity C# scripts only | **Not a Unity project.** No `ProjectSettings/`, scenes or packages |
| `design-system/` | Markdown design spec | Source of truth for UI tokens |

### Backend: `backend/requirements.txt` (pinned)

| Package | Version | Used for |
|---|---|---|
| fastapi | 0.115.12 | HTTP API |
| uvicorn[standard] | 0.30.0 | ASGI server |
| asyncpg | 0.31.0 | Postgres driver (raw SQL, connection pool) |
| pydantic[email] | 2.13.4 | Request and response models |
| python-dotenv | 1.0.0 | Loads `.env` in `main.py` |
| httpx | 0.27.0 | Outbound calls to Aliyun, Twilio, SendGrid, Apple |
| PyJWT[crypto] | 2.8.0 | HS256 app tokens, RS256 Apple identity tokens |
| cryptography | 42.0.0 | Needed by PyJWT for RSA |
| anthropic | 0.40.0 | Claude vision analysis of body photos (old SDK) |
| python-multipart | 0.0.9 | Photo uploads, form fields |
| tzdata | 2026.5 | IANA timezone database for `zoneinfo` (Windows and slim Docker images ship none) |

Runtime: **Python 3.12** in the [Dockerfile](backend/Dockerfile). Both local venvs were built with **Python 3.14.2**. Postgres image: `postgres:16-alpine`. Not in requirements but needed for tests: `pytest` and `pytest-asyncio`.

### Flutter: `flutter_app/pubspec.yaml` (resolved versions from `pubspec.lock`)

| Package | Constraint | Resolved | Notes |
|---|---|---|---|
| flutter_riverpod | ^2.5.0 | 2.6.1 | State management |
| go_router | ^14.0.0 | 14.8.1 | Routing with auth redirect |
| http | ^1.2.0 | 1.6.0 | All API calls (no Dio) |
| http_parser | ^4.0.0 | 4.1.2 | Multipart content types |
| shared_preferences | ^2.3.0 | 2.5.5 | Token, onboarding flags, profile, locale |
| sign_in_with_apple | ^6.1.0 | 6.1.4 | Apple login |
| image_picker | ^1.1.0 | 1.2.2 | Body photo capture |
| flutter_animate | ^4.5.0 | 4.5.2 | Motion |
| google_fonts | ^6.2.1 | 6.3.3 | Cormorant Garamond + Outfit (fetched at runtime) |
| intl / flutter_localizations | ^0.20.2 / SDK | 0.20.2 | i18n (generated `S` class) |
| path_provider | ^2.1.0 | 2.1.5 | |
| flutter_timezone | ^5.1.1 | 5.1.1 | Device IANA timezone for the `X-Timezone` header (native plugin; needs a full rebuild, not hot reload) |
| riverpod_annotation, riverpod_generator, build_runner | — | 2.6.1 / 2.6.5 / 2.5.4 | **Declared but unused.** No `@riverpod` or `.g.dart` anywhere |
| flutter_lints | ^4.0.0 | 4.0.0 | |

SDK: the lockfile needs **Flutter ≥ 3.38.4 / Dart ≥ 3.10.3**. The local toolchain is Flutter 3.41.3. README says "3.22+", which is wrong.
Not present: `flutter_unity_widget`. [BRIDGE_SPEC.md](unity_project/BRIDGE_SPEC.md) assumes it.

### External services

| Service | Purpose | Needed when |
|---|---|---|
| Postgres 16 | Primary datastore | Always |
| Aliyun SMS | OTP to +86 numbers | `DEV_MODE=false` and phone login for CN |
| Twilio | OTP to international numbers | `DEV_MODE=false` and phone login outside CN |
| SendGrid | Email OTP | `DEV_MODE=false` and email login |
| Apple Sign-In (`appleid.apple.com/auth/keys`) | Verify identity tokens | Apple login. Always live, no dev bypass |
| Anthropic API | Estimate body proportions from photos | Optional. Without a key the analysis returns `{}` silently |

---

## 2. Local setup

### 2.1 Backend

```bash
cd backend
python -m venv .venv && source .venv/bin/activate     # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env                                   # then set JWT_SECRET; set DEV_MODE=true for local
```

> Older local checkouts may contain stray virtualenvs at `backend/fastapi/` and `backend/venv/`. They're gitignored and not part of the repo; build your own as above.

**Database.** `migration.sql` alone creates the full schema (all nine tables plus the `session_summary` view):

```bash
docker run -d --name mirror-db -e POSTGRES_USER=mirror -e POSTGRES_PASSWORD=mirror \
  -e POSTGRES_DB=mirror_db -p 5432:5432 postgres:16-alpine

python scripts/run_migration.py        # applies migration.sql and checks the tables exist
```

The other scripts in `backend/scripts/` are superseded by `migration.sql`. They're only relevant for upgrading a database created before 2026-10-12:
- `add_missing_columns.py` adds the `users` JSONB/date columns.
- `add_workout_logs.py` creates `workout_logs`.
- `create_log_tables.py` creates the five daily-log tables.

All use `IF NOT EXISTS`, so running them against an up-to-date database is harmless.

**Run.**

```bash
uvicorn main:app --reload --port 8000     # Swagger at http://localhost:8000/docs
```

There's also a VS Code compound launch, "Full stack", in [3dmirror.code-workspace](3dmirror.code-workspace). Its `python.defaultInterpreterPath` is the POSIX `./backend/venv/bin/python`; on Windows, change it to `Scripts\python.exe`.

**Docker Compose** (`docker-compose up --build`). This runs `migration.sql` on first DB init, which now creates every table. The container uses `--reload`, bind-mounts `./backend`, and loads your local `backend/.env` (so `DEV_MODE` is whatever you set there). There's no `.dockerignore`, so any local venvs and `uploads/` get copied into the image.

### 2.2 Environment variables (backend)

All of these are listed in [backend/.env.example](backend/.env.example).

| Var | Default in code | Required | Notes |
|---|---|---|---|
| `DATABASE_URL` | `postgresql://mirror:mirror@localhost/mirror_db` | yes | Compose overrides with host `db` |
| `JWT_SECRET` | `dev-secret-change-in-prod` | yes | HS256, 90-day tokens, no revocation |
| `DEV_MODE` | off | dev only | `true/1/yes` means no SMS or email is sent and **every** OTP is `123456` |
| `ALIYUN_ACCESS_KEY_ID`, `ALIYUN_ACCESS_KEY_SEC`, `ALIYUN_SMS_SIGN`, `ALIYUN_SMS_TEMPLATE` | empty / `3D Mirror` / `SMS_000000` | CN phone login | |
| `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER` | empty | intl phone login | |
| `SENDGRID_API_KEY`, `EMAIL_FROM` | empty / `noreply@3dmirror.app` | email login | |
| `APPLE_BUNDLE_ID` | `com.yourcompany.3dmirror` | Apple login | JWT audience check |
| `ANTHROPIC_API_KEY` | — | optional | Without it, photo analysis returns `{}` |
| `VISION_MODEL` | `claude-haiku-4-5-20251001` | optional | Model id for photo analysis |
| `UPLOAD_DIR` | `uploads` | optional | Photos go on local disk, relative to the CWD |

### 2.3 Flutter app

```bash
cd flutter_app
flutter pub get
flutter gen-l10n                     # also runs automatically because pubspec has `generate: true`
flutter run --dart-define=API_BASE_URL=http://localhost:8000     # iOS simulator
flutter run                                                       # Android emulator → defaults to http://10.0.2.2:8000
```

- `API_BASE_URL` is read via `String.fromEnvironment` in **eight places**: seven `services/api/*_api.dart` files plus `features/me/me_screen.dart`. They all default to the Android-emulator host.
- Fonts come from `google_fonts` at runtime, so you **don't** need the `assets/fonts/` steps in the README. A device needs network on first launch.
- Apple Sign-In: add the capability in Xcode (`ios/Runner.xcworkspace`) and match `APPLE_BUNDLE_ID`. The Android `applicationId` is still the template `com.example.mirror_3d` ([build.gradle.kts](flutter_app/android/app/build.gradle.kts) TODOs).
- **Logging in locally:** set `DEV_MODE=true`, enter any phone or email, then use code `123456`.

---

## 3. Directory structure and architecture

```
3dmirror_full/                     ← git root (remote: NOvice-Hedwig/3dMirror-mobile)
├── .gitignore                     Secrets, venvs, caches, build output, uploads/, dumps, local tool settings
├── backend/
│   ├── main.py                    App factory: lifespan opens the DB pool, CORS *, mounts routers
│   ├── database.py                Database class: global asyncpg pool with JSON/JSONB codecs
│   ├── clock.py                   now_utc(), X-Timezone dependency, local_today(): the only time source
│   ├── schemas.py                 Pydantic models for sessions and photos
│   ├── auth/
│   │   ├── service.py             OTP store (in-memory), SMS/email/Apple providers, JWT
│   │   └── router.py              /auth/* + `current_user` dependency (used by /auth/me and /sessions)
│   ├── routers/                   One file per resource; SQL inline in handlers
│   │   ├── users.py  sessions.py  photos.py  logs.py  predict.py  coach.py  challenge.py
│   ├── services/
│   │   ├── photo_service.py       Disk writes + body_photos SQL
│   │   └── llm_service.py         Claude vision call + JSON parsing
│   ├── scripts/                   run_migration.py, one-off upgrade scripts for old DBs,
│   │                              report_timezone_skew.py (read-only audit of pre-fix timestamps)
│   ├── tests/
│   │   ├── test_auth.py           Unit tests (mocked DB)
│   │   └── integration/           Live-server HTTP tests + frozen-clock timezone tests (see §7)
│   ├── migration.sql              Full schema
│   ├── api.http                   VS Code REST Client samples
│   └── uploads/                   User body photos (gitignored; keep it that way)
├── flutter_app/lib/
│   ├── main.dart                  ProviderScope → MaterialApp.router
│   ├── core/
│   │   ├── router/app_router.dart Routes + redirect guard (reads SharedPreferences directly)
│   │   ├── theme/                 design_tokens.dart (MirrorColors/Text/Duration/Curve), app_theme.dart
│   │   ├── l10n/                  ARB files (zh template, en) + generated S class
│   │   ├── widgets/               RootShell (3-tab bar), MirrorScaffold, BodyViewport, animations
│   │   └── enums/
│   ├── features/<feature>/        Screens. Mostly StatefulWidgets that call *Api directly
│   │   ├── auth  onboarding  input  result  history  compare  predict  snapshot
│   │   ├── home/ (+ widgets/: HUD, FAB, week dots, unity_view_wrapper, log_sheets/*)
│   │   ├── coach/ (+ exercise library)   me/ (+ challenge)
│   ├── models/                    Hand-written fromJson/toJson classes (no freezed/json_serializable)
│   ├── providers/                 Riverpod providers (a mix of APIs, see §6)
│   ├── services/api/              One singleton per backend resource: XxxApi.instance;
│   │                              local_time.dart adds X-Timezone and formats local dates
│   ├── services/unity_bridge/     MethodChannel/EventChannel wrapper (no native side)
│   └── constants/                 exercise_library.dart, food_library.dart (static data)
├── unity_project/
│   ├── BRIDGE_SPEC.md             Intended Flutter↔Unity contract
│   └── Assets/Scripts/{Avatar,Bridge,Camera,Lighting}/*.cs
├── design-system/MASTER.md  brief.md  README.md  CLAUDE.md
└── docker-compose.yml  3dmirror.code-workspace
```

### Architectural pattern

**Backend: a thin "router does everything" layering.**
`router (FastAPI handler)` → *(sometimes)* `services/*` → `Database.pool()` raw SQL.
- Only photos go through a service layer. Every other router mixes validation, business rules (prediction maths, challenge progress, coach heuristics) and SQL in the handler.
- JSON/JSONB columns are converted once, by codecs registered on every pooled connection in `database.py`. Routers pass and receive plain dicts and lists; **never** call `json.dumps`/`json.loads` on DB values.
- Time comes only from `clock.py` (see §6, "Time rule"). Never use `datetime.utcnow()`, naive `datetime.now()`, `date.today()` or SQL `CURRENT_DATE` in request handling.
- Auth: `sessions.py` uses `Depends(current_user)`. The other routers still define their own `_uid(authorization)` helper, so on those endpoints a bad token plus an invalid body returns 422 rather than 401.
- No ORM, no migrations tool (Alembic etc.), no repository layer.

**Flutter: feature-first folders with a thin service layer.**
`Screen (features/*)` → `XxxApi.instance` (http + SharedPreferences token) → backend.
Riverpod sits beside this rather than mediating it. Home, coach, predict, challenge and logs use providers. Input, result, history, compare, snapshot, me and onboarding call APIs from `initState` and hold results in `setState`.

**Unity: intended as an embedded view** driven over `MethodChannel('com.3dmirror.unity_bridge')` and `EventChannel('com.3dmirror.unity_events')`. None of the plumbing exists yet (see §8.2).

---

## 4. Entry points and one core flow end to end

### Entry points

| Layer | Entry |
|---|---|
| Backend | [backend/main.py](backend/main.py): `app`; run with `uvicorn main:app`. `GET /health` |
| Flutter | [flutter_app/lib/main.dart](flutter_app/lib/main.dart): `main()` → `MirrorApp` → `appRouter` |
| Routing guard | [app_router.dart:41](flutter_app/lib/core/router/app_router.dart#L41): `/auth` → `/onboarding` → `/photo-capture` → `/` (home), gated by the prefs keys `mirror_token`, `mirror_onboarded` and `mirror_photo_captured` |
| Unity | `BridgeReceiver.cs` (GameObject must be named `BridgeReceiver`) |

### Screen map

`/auth` → `/onboarding` (terms, then gender/age/height/weight, then goal; stored **only locally**) → `/photo-capture` (front/side/back, upload, analysis in the background) → **shell with 3 tabs**: `/` Mirror (home), `/coach`, `/me`.
From home: FAB log sheets (workout, diet, sleep, health, supplements), `/predict`, `/history` → `/compare?a=&b=`, `/snapshots`, `/photo-capture`. Also `/input` → `/result?id=`, `/me` → `/challenge`, `/coach` → `/exercise-library`.

### Trace: "record today's body data and see the result"

**1. UI.** [input_screen.dart:318](flutter_app/lib/features/input/input_screen.dart#L318) `_submit()`
- Reads `mirror_gender` (fallback `'male'`) and `mirror_height` (fallback 170) from SharedPreferences. Onboarding wrote these at [onboarding_screen.dart:383](flutter_app/lib/features/onboarding/onboarding_screen.dart#L383).
- Builds `BodyData` (weight, optional body-fat and waist) and `ActivityData` (if not rest).
- **Client-side business logic:** [`AvatarParams.fromBodyData`](flutter_app/lib/models/models.dart#L98) turns kg/cm into 0–1 "norm" values. It computes BMI, estimates body fat from BMI when missing, derives lean mass, then shoulder, hip and muscle heuristics by gender. *The avatar model is computed on the client and stored by the server as-is.*
- Wraps everything in a `SessionRecord` and calls `SessionApi.instance.create()`.

**2. API client.** [session_api.dart:23](flutter_app/lib/services/api/session_api.dart#L23)
`POST {API_BASE_URL}/sessions` with headers `Authorization: Bearer <jwt>` and `X-User-Id` (the backend ignores this one). The body is `SessionRecord.toJson()`. It leaves three `print()` debug lines behind.

**3. API.** [routers/sessions.py](backend/routers/sessions.py) `create_session`
- `Depends(current_user)` validates the JWT first (401 on a bad token) and yields `sub`, the user id. The `user_id` in the body is required by the schema but ignored.
- FastAPI validates `SessionIn` ([schemas.py:34](backend/schemas.py#L34)): `weight_kg` 20–300, `body_fat_pct` 3–70, `waist_cm` 40–200. Extra client fields (`id`, `date`, `photo_ids`, `photo_enhanced`…) are dropped silently.

**4. Data.** `INSERT INTO sessions (id, user_id, body_data, avatar_params, activity_data, thumbnail_url, created_at)`. The three JSONB columns receive `model_dump()` dicts, which the pool's JSON codec encodes. `created_at` is `clock.now_utc()`, a timezone-aware UTC instant.
Returns `SessionOut`. Flutter then does `context.push('/result?id=<id>')`.

**5. Result.** [result_screen.dart:31](flutter_app/lib/features/result/result_screen.dart#L31): `GET /sessions/{id}`, then `UnityBridge.loadAvatar('<gender>_base')` and `applyBodyParams(...)`. Those throw `MissingPluginException` (no native handler), which is caught and ignored.

**Downstream readers of `sessions`:** `GET /predict` (linear extrapolation over the last 30 sessions), `GET /coach/suggestions` (7-day heuristics), `GET /challenge/progress`, and the home providers `latestSessionProvider`, `streakProvider` and `weekWorkoutMinutesProvider`.

---

## 5. Data model and API contracts

### 5.1 Database schema

[migration.sql](backend/migration.sql) is the single source of truth. A fresh database built from it alone is identical to the live development database (verified 2026-10-12).

| Table | Key columns | Notes |
|---|---|---|
| `users` | `id UUID`, `phone UNIQUE`, `email CITEXT UNIQUE`, `apple_id UNIQUE`, `display_name`, `locale DEFAULT 'zh'`, `gender`, `height_cm`, `target_avatar_params JSONB`, `challenge_goal JSONB`, `challenge_start_date DATE`, timestamps | CHECK: at least one of phone/email/apple_id. Gender and height are **never written** by the app |
| `sessions` | `user_id → users`, `body_data JSONB NOT NULL`, `avatar_params JSONB NOT NULL`, `activity_data JSONB`, `thumbnail_url`, `created_at` | Index `(user_id, created_at DESC)`. The core "check-in" record |
| `body_photos` | `user_id`, `session_id → sessions (nullable)`, `angle ∈ {front,side,back}`, `file_path`, `llm_analysis JSONB` | `session_id` is never set |
| `session_summary` (view) | flattens weight/body-fat/waist/workout_type | Unused by code |
| `workout_logs` | `type`, `sub_type`, `duration_min`, `intensity`, `with_weight`, `muscle_group`, `sets JSONB`, `estimated_kcal`, `logged_at` | |
| `diet_logs` | `meal ∈ {早餐,午餐,晚餐,加餐}`, `food_name`, `grams`, `calories`, `protein_g`, `entry_method` | Enum values are Chinese literals |
| `sleep_logs` | `date`, `bedtime`, `wake_time`, `quality 1–5`, `source`; `UNIQUE(user_id,date)` | Upserted: a repeat log for the same day overwrites it |
| `period_logs` | `date NOT NULL`, `phase ∈ {start,ongoing,end}`, `symptoms text[]`, `intensity 1–3`; `UNIQUE(user_id,date)` | Upserted. `date` is the user's local date; optional in the API, defaulting to today in `X-Timezone` |
| `supplement_logs` | `name`, `dosage`, `reminder_time time`, `reminder_enabled` | `reminder_time` is a wall-clock time; nothing schedules it yet (§8.2) |
| `body_snapshots` | `date`, `measurements JSONB`; `UNIQUE(user_id,date)` | Upsert merges JSON; `date` defaults like period. Nothing reads it |

`DATE` columns hold the **user's local** calendar date. `TIMESTAMPTZ` columns hold UTC instants; `logged_at` and `sessions.created_at` are written by the backend from `clock.now_utc()` (the `DEFAULT NOW()` remains only as a fallback).

**JSON shapes stored in `sessions`:**
- `body_data`: `{weight_kg, body_fat_pct?, waist_cm?, hip_cm?, lean_mass_kg?, fat_mass_kg?}`
- `avatar_params`: `{height_norm, weight_norm, body_fat_norm, waist_norm, hip_norm, shoulder_norm, muscle_norm, gender, lighting_profile}` (all norms 0–1)
- `activity_data`: `{workout_type, duration_min?, intensity?, steps?}`

Workout data lives in **two places**: `sessions.activity_data` (Input screen) and `workout_logs` (FAB sheet). Home streaks and week dots read the former; `/logs/today-stats` reads the latter.

### 5.2 HTTP API

All endpoints except `/health` and `/auth/*/send|verify|apple` need `Authorization: Bearer <jwt>`. Errors use FastAPI's `{"detail": ...}`, and some messages are in Chinese.

The app sends **`X-Timezone: <IANA name>`** (e.g. `America/New_York`) on every request. It is **required (422 if missing or unknown)** on every endpoint that decides a calendar date: `/logs/period`, `/logs/measurements`, `/logs/today-stats`, `/challenge/progress` and `/coach/suggestions`. Other endpoints ignore it.

Formats:
- Dates are the user's local `YYYY-MM-DD`.
- Times of day are `HH:MM[:SS]`.
- Datetimes **must carry an offset** (`Z` or `±HH:MM`); a naive datetime returns 422.
- Any malformed value returns **422**.

| Method & path | Body / query | Response |
|---|---|---|
| `GET /health` | — | `{status, version}` |
| `POST /auth/phone/send` | `{phone}` | `{message}` |
| `POST /auth/phone/verify` | `{phone, code(6)}` | `AuthOut {user_id, token, is_new_user}` |
| `POST /auth/email/send` | `{email}` | `{message}` |
| `POST /auth/email/verify` | `{email, code(6)}` | `AuthOut` |
| `POST /auth/apple` | `{identity_token, full_name?}` | `AuthOut` |
| `GET /auth/me` | — | `{id, phone, email, display_name, created_at}` |
| `GET /users/me` | — | the above plus `locale, gender, height_cm, target_avatar_params` (duplicates `/auth/me`) |
| `PATCH /users/me` | any of `display_name, locale, gender, height_cm, target_avatar_params` | `{message}` (not called by the app) |
| `POST /sessions` | `SessionIn {user_id, body_data, avatar_params, activity_data?, thumbnail_url?}` | `SessionOut` |
| `GET /sessions?limit=30` | — | `SessionOut[]` newest first |
| `GET /sessions/{id}` | — | `SessionOut` / 404 |
| `POST /photos/upload` | multipart, `front`/`side`/`back` files (≤10 MB, jpeg/png/webp/heic) | `{photo_ids[]}` |
| `POST /photos/analyze` | form `photo_ids` (repeated) | `{analysis{shoulder_width_norm, waist_norm, hip_norm, limb_proportion_norm}, photo_ids}` |
| `GET /photos?session_id=` | — | `{photos[]}` (`file_path` is a server-local path; no static serving) |
| `POST /logs/workout` | `{type, sub_type, duration_min, intensity, with_weight, muscle_group?, sets?, estimated_kcal?}` | 201 `{id}` |
| `POST /logs/diet` | `{meal, food_name, grams?, calories, protein_g?, entry_method}` | 201 `{id}` |
| `POST /logs/sleep` | `{date, bedtime, wake_time, quality, source}`; `bedtime`/`wake_time` offset-aware | 201 `{id}` created / 200 `{id}` same-day row updated |
| `POST /logs/period` | `{date?, phase, symptoms[], intensity}` + `X-Timezone` | 201 `{id}` created / 200 `{id}` same-day row updated |
| `POST /logs/supplements` | `[{name, dosage?, reminder_time?, reminder_enabled}]` | 201 `{count}` |
| `PUT /logs/measurements` | `{date?, weight_kg?, waist_cm?, hip_cm?, chest_cm?, thigh_cm?}` + `X-Timezone` | `{date}` |
| `GET /logs/today-stats` | `X-Timezone` | `{total_kcal_in, sleep_hours, workout_minutes}` for the user's local today |
| `GET /predict?weeks=4` | — | `{weeks, predicted_weight_kg, weight_delta_kg, predicted_body_fat_pct, body_fat_delta_pct, predicted_waist_cm, waist_delta_cm, confidence, data_points}`; 400 if fewer than 2 sessions |
| `GET /coach/suggestions` | — | `{cards[{category, title, body, priority}], data_points, generated_at}` |
| `PUT /coach/target` | `AvatarParams` (no lighting) | `{ok}` |
| `POST /challenge/goal` | `{goal_type, target_*?, start_date, end_date}` | `{ok}` |
| `GET /challenge/progress` | — | `{goal, current_*, progress_pct, days_remaining, is_completed, discount_eligible}`; 404 if no goal |
| `DELETE /challenge/goal` | — | `{ok}` |

Contract drift between client and server (fields the server drops silently): `WorkoutLogEntry.weight_kg`, `DietLogEntry.carbs_g/fat_g`, `AvatarParams.photo_enhanced`, `SessionRecord.photo_ids`, and the `X-User-Id` header.

---

## 6. State management and configuration

### Flutter state

| Concern | Where | Mechanism |
|---|---|---|
| Auth token and user id | SharedPreferences `mirror_token`, `mirror_user_id` (plain, **not** secure storage) | Read directly by every `XxxApi._headers()` and by the router |
| Onboarding progress | prefs `mirror_onboarded`, `mirror_photo_captured`, `mirror_terms_accepted` | Router redirect |
| Profile | prefs `mirror_gender`, `mirror_age`, `mirror_height`, `mirror_weight`, `mirror_goal` | Local only; never sent to the backend |
| Locale | prefs `locale` → `localeProvider` (StateNotifier) | Drives `MaterialApp.locale` |
| Sessions | `sessionsProvider` (AsyncNotifier) and the derived `latestSessionProvider`, `streakProvider`, `weekWorkoutMinutesProvider`, `todayWorkoutMinProvider` | home_provider.dart |
| Logs | `todayStatsProvider` (FutureProvider); log sheets `ref.invalidate` it after saving | |
| Predict, coach, challenge | `predictMetricsProvider.family(weeks)`, `coachSuggestionsProvider`, `challengeProgressProvider` (autoDispose FutureProviders) | |
| Target avatar | `targetParamsNotifierProvider` (StateNotifier, in-memory) | Saved to the server but **never loaded back**, so it's lost on restart |
| Screen-local data | `setState` in result, history, compare, snapshot, me, coach, input and onboarding | |

Riverpod API styles are mixed: legacy `StateNotifier`, `Notifier`, `AsyncNotifier` and `FutureProvider`. `authProvider`, `currentUserIdProvider`, `sessionDetailProvider` and `inputDraftProvider` are defined but **unused**.

**Theming.** Tokens live in `core/theme/design_tokens.dart` (`MirrorColors`, `MirrorText`, `MirrorDuration`, `MirrorCurve`) and the home-specific `features/home/home_design.dart` (`kHomeBg`, `kGold`…). There's only a light theme, while the home screen is a dark "immersive" page. The brief asks for light and dark.

**i18n.** `l10n.yaml` generates `S` from `lib/core/l10n/app_{zh,en}.arb`, and the delegate is registered. **However, no screen calls `S.of(context)`.** All UI copy is hard-coded, mostly Chinese, so switching locale has no visible effect.

### Backend configuration

Environment variables only (§2.2), read at **import time** as module globals in `auth/service.py`, `llm_service.py` and `photo_service.py`. `load_dotenv()` runs at the top of `main.py`, before those imports. There is no settings object, no per-environment config and no logging configuration.

### Time rule (since 2026-10-12)

- **Calendar dates are the user's local date**, never the server's or the database's.
  - The client sends the date explicitly where it matters (sleep, period, measurements, challenge start/end).
  - Server-side defaults use `clock.local_today(tz)`, with `tz` taken from the `X-Timezone` header via the `clock.user_timezone` dependency.
  - "Today" queries compare `(ts AT TIME ZONE <user tz>)::date`.
- **Instants are timezone-aware UTC.** The backend takes "now" only from `clock.now_utc()`, so tests can freeze it, and accepts only offset-aware datetimes (`AwareDatetime`).
- **Client side:**
  - `lib/services/api/local_time.dart` adds `X-Timezone` (from `flutter_timezone`) to every request and formats local dates.
  - Instants are sent with `toUtc().toIso8601String()`.
  - Server timestamps are parsed with `.toLocal()` so `.day`/`.month` are local.
  - Date arithmetic uses calendar math (`DateTime(y, m, d + n)`), not `Duration(days: n)`, which breaks across DST.
- **Why:** asyncpg treats a naive datetime as the backend host's local time. Before this rule, sessions written from `datetime.utcnow()` on a New York host were stored 4 h (EDT) / 5 h (EST) in the future, and "today" meant a UTC day in SQL but a host-local day in Python.
- **Pre-fix data:** `scripts/report_timezone_skew.py` is a read-only audit of rows written before the fix. On 2026-10-12 it found the 17 dev sessions correct (written by a UTC backend) and no sleep logs.

---

## 7. Tests

| Suite | Location | Status (run 2026-10-12) |
|---|---|---|
| Backend unit | `backend/tests/test_auth.py`, 5 tests | **5 pass** with `DEV_MODE=true`. **3 pass, 2 fail** with `DEV_MODE=false` (open, see §8.2) |
| Backend integration | `backend/tests/integration/test_api_integration.py`, 47 tests | **47 pass** against a live server and a disposable Postgres database |
| Backend timezone rules | `backend/tests/integration/test_timezone_rules.py`, 10 tests | **10 pass** in-process with a frozen clock against the same disposable database |
| Flutter | `flutter_app/test/widget_test.dart` | **Does not compile.** It's the default counter template and references `MyApp`, which doesn't exist (the app class is `MirrorApp`). Open, see §8.2 |
| iOS/macOS | `RunnerTests.swift` | Xcode template stubs |

**Run backend unit tests:**

```bash
cd backend
pip install pytest pytest-asyncio          # not in requirements.txt
pytest tests/ -v                           # integration tests are skipped unless INTEGRATION_BASE_URL is set
```

**Run backend integration tests.** These need a running server pointed at a **disposable** database, never your real one:

```bash
# create a scratch DB once:  CREATE DATABASE "3dmirror_test";  then apply migration.sql to it
# terminal 1 (backend/)
DATABASE_URL=postgresql://mirror:mirror@localhost:5432/3dmirror_test DEV_MODE=true uvicorn main:app --port 8765
# terminal 2 (backend/)
INTEGRATION_BASE_URL=http://127.0.0.1:8765 \
INTEGRATION_DATABASE_URL=postgresql://mirror:mirror@localhost:5432/3dmirror_test \
pytest tests -v                            # runs unit + live-server + frozen-clock suites
```

**Live-server suite** covers:
- every `/logs/*` endpoint and the session save/read flow
- JSON round-trips through predict, coach, challenge and `/users/me`
- 422 for bad dates, times, offset-less datetimes, and missing or unknown `X-Timezone`
- same-day upserts, the 401-before-422 auth order, and `sessions.created_at` equal to the real UTC time

**Frozen-clock suite** (`test_timezone_rules.py`) runs the app in-process with `clock.now_utc()` pinned. It refuses to run unless the database is `3dmirror_test`. It covers:
- 23:30 in New York, when the UTC date is already tomorrow: default dates, explicit dates, sleep instants, today-stats, session `created_at`, the challenge baseline and `days_remaining`, and coach day counting
- 01:30 on 2026-11-01, the DST change, which occurs twice: both occurrences map to the same local day, and sleep duration across the repeated hour

Mutation checks confirmed that each old behaviour (UTC dates, UTC "today" in SQL, naive `utcnow()`) makes at least one test fail.

**Coverage gaps:** photos and the LLM call, auth providers (SMS, email, Apple), predict's date maths, and all Flutter code (including `local_time.dart` and the `.toLocal()` parsing). There's no CI config in the repo.

**Run the Flutter suite** (once it's fixed): `cd flutter_app && flutter test`. Lints: `flutter analyze` (`flutter_lints` + `avoid_print`; `session_api.dart` violates it).

---

## 8. TODOs, incomplete features, bugs and inconsistencies

### 8.0 Explicit TODO/FIXME comments

| Location | Comment |
|---|---|
| [auth_screen.dart:258](flutter_app/lib/features/auth/auth_screen.dart#L258) | `TODO: launch privacy policy / terms URL when available`. The legal consent the brief requires has no actual documents |
| [android/app/build.gradle.kts:23](flutter_app/android/app/build.gradle.kts#L23) | `TODO: Specify your own unique Application ID` (still `com.example.mirror_3d`) |
| [android/app/build.gradle.kts:35](flutter_app/android/app/build.gradle.kts#L35) | `TODO: Add your own signing config for the release build` |
| `linux/` and `windows/flutter/CMakeLists.txt:9` | Flutter template TODOs (ignore) |
| README "下一步开发 (Week 4-5)" | Unity integration, `BridgeReceiver` channel, `UnityWidget` in result, history replay. **All still open** |

Placeholder markers (占位 / placeholder): [unity_view_wrapper.dart:2](flutter_app/lib/features/home/widgets/unity_view_wrapper.dart#L2) (gold CustomPaint silhouette standing in for Unity), [predict_screen.dart:155](flutter_app/lib/features/predict/predict_screen.dart#L155) (static 3D viewport), `ProceduralAvatar.cs` / `AvatarController.cs` (placeholder mesh).

### 8.1 Resolved this week

All verified by the integration tests in §7.

| Issue | How it was fixed |
|---|---|
| **JSON/JSONB handling.** Dicts were passed to JSONB columns with no codec, causing 500s on session save/read, coach, challenge and `/users/me` | JSON/JSONB codecs are registered on every pool connection in `database.py`, and all manual `json.dumps`/`json.loads` for DB columns were removed |
| **Date/time typing.** Strings were passed to `date`/`time` columns in sleep, measurements and supplements, causing 500s | Request models use `datetime.date`/`datetime.time` (also challenge goal dates), so bad formats return 422 at the API boundary |
| **Period log date.** It was never inserted into a `NOT NULL` column | `date` is now optional in the request and defaults to the user's local today (from `X-Timezone`) |
| **Duplicate same-day sleep/period logs** returned 500 on `UNIQUE(user_id, date)` | `INSERT … ON CONFLICT (user_id, date) DO UPDATE`: 201 when created, 200 with the existing `id` when updated |
| **401 test** (`test_create_session_requires_auth` got 422) | `/sessions` endpoints use `Depends(current_user)`, so auth runs before body validation |
| **Tracked `backend/.env`** | `JWT_SECRET` was rotated; `backend/.env` is no longer tracked and is covered by the root `.gitignore`, along with caches, venvs, build output, `uploads/` and local tool settings |
| **`migration.sql` incomplete** (missing the five daily-log tables) | They were added to `migration.sql`; a fresh database built from it alone matches the live schema exactly |
| **Log dates mixed timezones.** They used the backend host's local time, UTC in Postgres, offset-less device times, and UTC days in Flutter; sessions were stored 4 h (EDT) / 5 h (EST) in the future from naive `utcnow()` | One rule (§6 "Time rule"): the app sends `X-Timezone`, dates are the user's local date, and instants are aware UTC from `clock.now_utc()`. Applied to logs, sessions, challenge and coach, plus Flutter parsing and a DST-safe challenge end date |

### 8.2 Open issues

**Most important first:**

1. **Unity avatar is not wired up.**
   - There's no `flutter_unity_widget`, and no native MethodChannel handler in `MainActivity.kt` or `AppDelegate.swift`. Every `UnityBridge` call throws `MissingPluginException`, which the callers swallow silently.
   - `BridgeReceiver.SendToFlutter` only `Debug.Log`s, and there's no Unity project, scene, prefab or asset.
   - A stray directory `unity_project/Assets/{Scripts/{Bridge,Avatar,Camera,Lighting},Materials,Models,Prefabs,Scenes}` was left by an unexpanded shell brace; delete it.
   - Naming mismatch: Dart sends lighting as `studioMinimal` (enum name) while `AvatarParams.lighting_profile` is `studio_minimal`.
   - Screenshot/share (`result_screen._shareScreenshot`) depends on Unity, so it's a no-op.
2. **Photo analysis is unused, and the shoulder field name is wrong.**
   - [photo_capture_screen.dart:234](flutter_app/lib/features/onboarding/photo_capture_screen.dart#L234) calls `analyzePhotos(...).ignore()`, discarding the result, and `AvatarParams.applyPhotoAnalysis` is never called.
   - Even if it were, it reads `'shoulder_norm'` ([models.dart:137](flutter_app/lib/models/models.dart#L137)) while the LLM returns `shoulder_width_norm`. `limb_proportion_norm` has no consumer.
3. **i18n is scaffolded but unused.** No screen calls `S.of(context)`; all UI copy is hard-coded (mostly Chinese), so switching locale has no visible effect. Backend responses (coach cards, error details) are hard-coded Chinese too.
4. **Supplement reminders are not implemented.** The supplement sheet lets the user switch a reminder on and pick a time, and the backend stores `reminder_time`/`reminder_enabled`, but **nothing schedules a reminder**. There's no notification package, no Android notification permission, and no server scheduler or push.
   - **Preferred approach:** schedule on the device (e.g. `flutter_local_notifications`) at the chosen wall-clock time. The phone's own timezone handles it, so **no server-side timezone** (`users.timezone`) is needed. That's only required if reminders are ever sent by server push.
   - **Data model:** reminders are currently stored per log entry (`supplement_logs`). They should become a **standing reminder per supplement** (e.g. a `supplements` or `supplement_reminders` table: user, supplement, time, enabled), separate from the log of doses taken.
5. **Two unit tests fail with `DEV_MODE=false`.** `test_phone_send_called` and `test_email_send_called` patch `auth.service.send_*_otp`, but the router imported those names directly, so the patch has no effect. They pass only when `DEV_MODE` skips the real Aliyun and SendGrid calls; otherwise they get a 500.
6. **Default Flutter widget test.** `flutter_app/test/widget_test.dart` is the counter template, references a non-existent `MyApp`, and doesn't compile.

**Other logic bugs:**
- **`llm_service.analyze_body_photos`** uses the **sync** `anthropic.Anthropic` client inside an async route, which blocks the event loop for the whole call. Its docstring says it "falls back to empty dict on any error", but API errors aren't caught and surface as a 500. HEIC uploads are allowed but sent to Claude as `image/jpeg`. The same analysis is written to every photo in the batch.
- **Coach recovery card never triggers:** it checks `activity_data.get("type") == "无氧"`, but `sessions.activity_data` uses `workout_type` with English enum values (`strength`…). Workouts logged via the FAB go to `workout_logs`, which coach doesn't read. "Training days" counts distinct session days, not workouts.
- **Challenge:**
  - The baseline needs a session on exactly the (local) start date. Otherwise it falls back to *current* values, which gives 0% progress.
  - `_pct_single` assumes lower is better, so gain goals (muscle) clamp to 0.
- **Predict:** missing body-fat or waist values are filled with made-up defaults (20 % / 75 cm) and still returned as predictions. `days_span` uses whole days, so two same-day sessions get treated as 1 day apart and extrapolate wildly. `body_snapshots` measurements are never used.
- **Router onboarding state is device-local.** A returning user on a new device (`is_new_user=false`) gets sent back through onboarding by the redirect. `signOut()` clears only the token, so a different account on the same device skips onboarding and inherits the previous user's gender and height.
- **Onboarding profile is never synced:** `users.gender` and `height_cm` stay NULL, and `PATCH /users/me` is unused. `input_screen` falls back to `'male'` while onboarding defaults to `'female'`.
- **Target avatar** is saved via `PUT /coach/target` but never loaded back. `/users/me` returns it and nothing reads it.
- **Workout duplication:** strength workouts from the FAB send `duration_min: 0`. Home streak and week dots ignore FAB workouts entirely because they read sessions.
- `me_screen` masking comment says "keep first 3 and last 2" but the code shows only the last 2.
- `photo_service.link_photos_to_session` is never called, so `body_photos.session_id` is always NULL and `GET /photos?session_id=` never matches. Photos are stored but never served (no static route); `BodyPhoto.remoteUrl` holds a server filesystem path.
- `GET /sessions/{id}` with a non-UUID id returns a 500 (asyncpg cast error) instead of a 404.

### 8.3 Incomplete features

- **Legal consent:** checkboxes exist but no policy URLs (TODO above). Acceptance is stored only locally and never server-side, despite the brief's compliance requirement.
- **Brief features not started:** Apple Health / Oura import, avatar "sculpting" at onboarding, 3D timeline scrubbing, exportable "magazine cover" reports, subscription/freemium gating (`discount_eligible` is computed but unused).
- **No read endpoints for logs** apart from `today-stats`, so history only shows sessions.

### 8.4 Security and ops smells

- `DEV_MODE=true` in a local `backend/.env` reaches Docker Compose through `env_file`. If that config is ever deployed, **anyone can log in as any phone or email with `123456`.** Keep it false outside local development.
- OTPs: no rate limiting or attempt counter (6 digits brute-forceable within 5 minutes); in-memory store isn't shared across workers and is lost on restart; `random` instead of `secrets`.
- JWT: 90-day expiry, no refresh or revocation, stored in plain SharedPreferences.
- `CORS allow_origins=["*"]`.
- Body photos (sensitive biometric data) sit unencrypted on local disk, with no delete endpoint and no retention policy. `uploads/` is gitignored; keep real images out of the repo.

### 8.5 Code smells and inconsistencies

- Only `/sessions` uses `Depends(current_user)`; the other routers still copy a `_uid()` helper. `/auth/me` and `/users/me` overlap.
- `API_BASE_URL` plus header-building is duplicated in 8 Flutter files. There's no shared HTTP client, retry handling, 401 auto-logout, or common error type (`AuthException`, `PhotoException`, bare `Exception`).
- Business logic is split across client and server: avatar norms on the client, prediction and coach on the server, and predict-to-avatar mapping on the client again in `predict_screen._avatarParamsFromMetrics`.
- `log_models.dart:87` comment says workouts are "stored as activity_data JSON in the existing sessions table (no new table)". That's false; they go to `workout_logs`.
- Unused: `BodySnapshot` model, the `session_summary` view, riverpod codegen deps, `authProvider` and friends, `link_photos_to_session`.
- Docs drift:
  - README's tree, endpoint list, font instructions, Flutter version and "edit defaultValue in auth_api/session_api" advice are all stale.
  - `brief.md` §7 says React Native / Three.js / OpenAI; the actual stack is Flutter / Unity / Anthropic.
  - The design system says "no streaks" and "no gamification", but the home HUD shows a streak badge (`mirror_hud.dart:44`) and the challenge has a discount mechanic.
  - The brief asks for dark mode support; only a light theme exists.
- No `.dockerignore`, so local venvs and `uploads/` are copied into the backend image.
- `CLAUDE.md` holds the team's working rules for AI assistants, in Chinese. They say: describe the plan and get approval before coding; ask when requirements are unclear; write a reproduction test before fixing a bug; split work touching more than 3 files into smaller tasks; no backward-compatibility code unless asked. Human contributors should follow the same flow.

---

## 9. Suggested next steps

1. Decide the 3D path (flutter_unity_widget vs. a lighter in-Flutter renderer) before investing more in `UnityBridge`.
2. Wire the photo analysis result into the avatar (fix the `shoulder_width_norm` key) or drop the feature.
3. Build supplement reminders on-device with a per-supplement reminder model (§8.2 #4).
4. Fix the two `DEV_MODE`-dependent unit tests by patching `auth.router.send_*_otp`; replace `widget_test.dart` with a real smoke test; add a CI workflow that runs unit tests plus the integration suite against a Postgres service container.
5. Move the remaining routers to `Depends(current_user)`; centralise `API_BASE_URL` and the HTTP client in Flutter.
6. Wire up i18n (`S.of(context)`) before the copy grows further.
