# Project Brief — 3D Mirror

---

## 1. Product Overview

**Name:** 3D Mirror  
**Tagline (EN):** *Your body. Your archive. Your transformation.*  
**Tagline (CN):** *翻开属于你的私人健身档案。*

**Product Type:** AI fitness visualization tool — Mobile App (iOS first, Android TBD)  
**Category:** Health & Wellness / AI-powered / Body transformation tracking  
**Stage:** MVP

---

## 2. Positioning

> We help users going through fat loss and body recomposition reduce uncertainty about their results — through body change trend prediction and visual feedback — so they can stay consistent and succeed.

**Core Value:** 不是给你制定计划，而是让你**看见**自己的变化趋势，减少焦虑，提高执行力。

---

## 3. Target Users

### Primary (MVP Focus)
- 女性，20–35岁，减脂新手
- 没有系统健身经验，容易因看不到效果而放弃
- 审美敏感，在意界面质感，用过 Notion / Lemon8 / 小红书
- 渴望被"当作超模对待"的仪式感

### Secondary (Future Expansion)
- 有科学增肌需求的进阶男性/女性，25–40岁
- 关注身体数据、训练周期、营养摄入

---

## 4. Brand & Aesthetic Direction

### Three Core Words
**Editorial（编辑感）· Luxury（克制奢华）· Archive（档案仪式感）**

### Vibe
```
打开 App，像翻开一本只属于你的私人健身杂志。
每一个数字都是你的战绩，每一次记录都是新的封面。
```

### Visual References
- **Typography feel:** Vogue / System Magazine / AnOther Magazine
- **Color feel:** Off-white, warm ivory, deep charcoal, single metallic accent (gold or chrome)
- **UI feel:** Bottega Veneta website × Apple Health × A-COLD-WALL*
- **NOT:** Neon fitness apps / Bright gym-bro energy / Purple AI gradients / Generic health green

### Color Palette
- Background: `#FAF8F5` (Warm Ivory) / `#0E0E0E` (Deep Black) — support both light & dark
- Primary Text: `#1A1A1A` / `#F0EDE8`
- Accent: `#C9A96E` (Warm Gold) — used sparingly
- Data/Chart: Monochrome with single gold highlight

### Typography
- Display: Cormorant Garamond Italic or Playfair Display — for headings, names, dates
- Body: DM Sans or Neue Haas Grotesk — for data, labels, UI text
- Numbers: Tabular, elegant — data should feel like editorial statistics

### Motion & Interaction
- Transitions: slow, deliberate (300–500ms ease)
- Body model: smooth morphing / timeline scrubbing
- File/card reveals: like flipping a magazine page
- No bouncy animations, no confetti, no gamification pop-ups

---

## 5. MVP Feature Scope

### 5.1 Onboarding & Auth
- Login / Sign up
- **Legal consent screen** (below login): AI data usage agreement, privacy policy — required before proceeding (法律合规，规避AI数据使用风险)
- Language: 中英双语切换

### 5.2 First-Time Data Input
> Each data input step returns as an **archive card / file modal** — immersive, like filling in a model's profile sheet.

**Required:** (user can skip)
- Gender / 性别
- Height & Weight / 身高体重
- Body measurements / 三围
- Body shape type / 体型 (梨形 Pear / 苹果形 Apple / 沙漏形 Hourglass / H型 Rectangle)
- Other body image parameters (shoulder width, hip ratio, etc.)

**API Integrations (Import):**
- Apple Health
- Oura Ring

**Optional:**
- Body fat percentage / 体脂率
- Photo upload / 拍照上传

**Personalization:**
- System generates initial 3D body avatar based on inputs
- User can manually adjust / "sculpt" avatar to better match real body
- Goal setting: 塑形 / 减脂 / 增肌 / 养生 / ... → then refined (e.g., 减脂 5kg in 3 months)

### 5.3 Core Pages

#### Daily Log / 每日记录
- Diet / 饮食
- Sleep / 睡眠
- Exercise / 运动量，细化类型：
  - 有氧: 跳操 / 跳绳 / 跑步 / 骑行 / 游泳 / ... + 负重选项
  - 无氧: 按部位分类 + 动作 + 负重
  - 普拉提 / 瑜伽
  - 爬山 / 徒步
  - 球类运动

#### Trend & Prediction / 趋势与预测
- Positive feedback (on track) + Negative feedback (off track, corrective insight)
- AI-predicted body change timeline
- "If you keep this up, in 30 days..."

#### Visualization / 可视化对比
- Charts: weight, measurements, body fat over time
- 3D model timeline: drag to scrub through time
- Model overlay: superimpose past & present models to see delta
- "Archive cover" view: your best progress moment as a magazine cover

#### Recommendations / 科学建议
- Based on user's stated goal
- Simple, non-overwhelming
- Personalized to training history and trend data

---

## 6. Business Model

**Model:** Freemium (Free + Subscription)  
**Target:** C-end consumers

### Free Tier
- Basic body avatar
- Manual data logging
- Basic trend charts (30-day)

### Premium (Subscription)
- 高级预测 Advanced AI prediction
- 个性化反馈 Personalized insights
- 可视化报告 Visual progress reports (exportable, shareable as "magazine covers")
- 长期趋势分析 Long-term trend analysis (3–12 months)
- 方案对比 Plan comparison / decision support
- 饮食分析 Nutrition analysis & recommendations

---

## 7. Tech Stack (TBD — to be confirmed with dev team)

**Preferred:**
- Frontend: React Native (iOS first)
- Design system: Tailwind-equivalent / custom design tokens
- 3D Avatar: Three.js or Ready Player Me API (TBD)
- AI: OpenAI API or custom model (TBD)
- Health integrations: Apple HealthKit, Oura API

---

## 8. Must Avoid (Anti-Patterns)

- ❌ Neon colors / bright fitness-app energy
- ❌ AI purple/pink gradients
- ❌ Gamification badges, confetti, streak flames
- ❌ Overwhelming data dashboards (keep it editorial, not analytical)
- ❌ Generic sans-serif fonts (Inter, Roboto, SF Pro as primary display)
- ❌ Cluttered layouts — every screen should feel like it could be a magazine spread
- ❌ Aggressive upsell popups

---

## 9. Language

- **Primary:** 中英文双语 (Bilingual CN/EN)
- UI labels: English
- Marketing copy / taglines: 中英混排 acceptable
- Data & scientific terms: English preferred