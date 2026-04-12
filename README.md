# 3D Mirror

简约风格的 3D 身体可视化应用。Flutter + FastAPI + Postgres。

---

## 目录结构

```
3dmirror_full/
├── flutter_app/          # Flutter iOS/Android App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── theme/       design_tokens.dart, app_theme.dart
│   │   │   ├── router/      app_router.dart
│   │   │   ├── widgets/     root_shell.dart
│   │   │   └── l10n/        app_zh.arb, app_en.arb
│   │   ├── features/
│   │   │   ├── auth/        auth_screen.dart
│   │   │   ├── onboarding/  onboarding_screen.dart
│   │   │   ├── input/       input_screen.dart
│   │   │   ├── result/      result_screen.dart
│   │   │   └── history/     history_screen.dart
│   │   ├── models/          models.dart
│   │   ├── providers/       locale_provider.dart
│   │   └── services/
│   │       ├── api/         auth_api.dart, session_api.dart
│   │       └── unity_bridge/ unity_bridge.dart
│   ├── pubspec.yaml
│   └── l10n.yaml
├── backend/              # FastAPI + Postgres
│   ├── main.py
│   ├── database.py
│   ├── schemas.py
│   ├── migration.sql
│   ├── requirements.txt
│   ├── Dockerfile
│   ├── .env.example
│   ├── auth/
│   │   ├── service.py     SMS + Email + Apple + JWT
│   │   └── router.py      /auth/* endpoints
│   └── routers/
│       ├── users.py
│       └── sessions.py
└── docker-compose.yml
```

---

## 快速开始

### 1. 后端（本地开发）

```bash
cd backend

# 安装依赖
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt

# 配置环境变量
cp .env.example .env
# 编辑 .env 填入真实的 key

# 启动 Postgres（需要 Docker）
docker run -d \
  --name mirror-db \
  -e POSTGRES_USER=mirror \
  -e POSTGRES_PASSWORD=mirror \
  -e POSTGRES_DB=mirror_db \
  -p 5432:5432 \
  postgres:16-alpine

# 初始化数据库
psql postgresql://mirror:mirror@localhost/mirror_db -f migration.sql

# 启动 API
uvicorn main:app --reload --port 8000
# → http://localhost:8000
# → http://localhost:8000/docs  (Swagger UI)
```

或者直接用 Docker Compose 一键启动（自动建表）：
```bash
docker-compose up --build
```

---

### 2. Flutter App

#### 前置要求
- Flutter SDK 3.22+（`flutter --version` 检查）
- Xcode 15+（iOS 开发）
- CocoaPods（`sudo gem install cocoapods`）

#### 字体文件
从 Google Fonts 下载以下字体放入 `flutter_app/assets/fonts/`：
- [DM Serif Display](https://fonts.google.com/specimen/DM+Serif+Display) → Regular + Italic
- [Outfit](https://fonts.google.com/specimen/Outfit) → Light (300) + Regular (400) + Medium (500)

#### 安装和运行

```bash
cd flutter_app

# 安装依赖
flutter pub get

# 生成 i18n 代码
flutter gen-l10n

# 配置后端地址（开发环境）
# 在 lib/services/api/auth_api.dart 和 session_api.dart 中
# defaultValue 改为你的后端地址

# iOS 模拟器运行
flutter run -d "iPhone 15"

# 真机运行（需要 Apple Developer 账号）
flutter run --dart-define=API_BASE_URL=http://你的IP:8000
```

#### Sign in with Apple 配置
1. 在 Xcode 中打开 `flutter_app/ios/Runner.xcworkspace`
2. 选择 Runner target → Signing & Capabilities
3. 添加 "Sign in with Apple" capability
4. 配置你的 Bundle ID（与 `.env` 中 `APPLE_BUNDLE_ID` 一致）

---

## 环境变量说明

| 变量 | 说明 | 必须 |
|------|------|------|
| `DATABASE_URL` | Postgres 连接串 | ✓ |
| `JWT_SECRET` | JWT 签名密钥（64字节随机串） | ✓ |
| `ALIYUN_ACCESS_KEY_ID` | 阿里云 AccessKey | 中国手机号 |
| `ALIYUN_ACCESS_KEY_SEC` | 阿里云 AccessKey Secret | 中国手机号 |
| `ALIYUN_SMS_SIGN` | 短信签名 | 中国手机号 |
| `ALIYUN_SMS_TEMPLATE` | 短信模板 ID | 中国手机号 |
| `TWILIO_ACCOUNT_SID` | Twilio Account SID | 国际手机号 |
| `TWILIO_AUTH_TOKEN` | Twilio Auth Token | 国际手机号 |
| `TWILIO_FROM_NUMBER` | Twilio 发号 | 国际手机号 |
| `SENDGRID_API_KEY` | SendGrid API Key | 邮件登录 |
| `EMAIL_FROM` | 发件人地址 | 邮件登录 |
| `APPLE_BUNDLE_ID` | App Bundle ID | Apple 登录 |

---

## API 文档

启动后访问 http://localhost:8000/docs 查看完整 Swagger 文档。

主要端点：
```
POST /auth/phone/send      发送手机验证码
POST /auth/phone/verify    验证 → 返回 JWT
POST /auth/email/send      发送邮件验证码
POST /auth/email/verify    验证 → 返回 JWT
POST /auth/apple           Apple 登录
GET  /auth/me              当前用户信息

POST /sessions             创建会话（保存一次记录）
GET  /sessions             历史列表
GET  /sessions/{id}        单条会话详情
```

---

## 下一步开发（Week 4-5）

- [ ] Unity 项目接入（占位模型 → 真实人体资产）
- [ ] `BridgeReceiver.cs` 实现 Method Channel
- [ ] Flutter `result_screen.dart` 嵌入 `UnityWidget`
- [ ] 历史回放：点击记录 → Unity 复现参数

---

## 技术栈

| 层 | 技术 |
|----|------|
| App | Flutter 3.22 + Riverpod + GoRouter |
| 字体 | DM Serif Display + Outfit |
| 3D | Unity（Method Channel 嵌入） |
| 后端 | FastAPI + asyncpg |
| 数据库 | Postgres 16 |
| Auth | OTP + Apple Sign-In + JWT |
| SMS | 阿里云（CN）+ Twilio（国际） |
| 邮件 | SendGrid |
