# 3D Mirror — Design System
**Plan A · Editorial Luxury**
*Version 1.0 · 2024.12*

---

## 设计哲学

> 打开 App，像翻开一本只属于你的私人健身杂志。
> 每一个数字都是你的战绩，每一次记录都是新的封面。

三个核心词：**Editorial**（编辑感）· **Luxury**（克制奢华）· **Archive**（档案仪式感）

参照：Whoop × 032c 杂志 × FocusFlight × Arc Browser

---

## 色彩系统 Color System

### 基础色板

| Token | Hex | 用途 |
|-------|-----|------|
| `--paper` | `#F5F3EE` | 主背景，所有页面底色 |
| `--cream` | `#EAE6DC` | 次级背景，Viewport 底色，输入框填充 |
| `--ink` | `#0C0B09` | 主文字，按钮背景，所有强调元素 |
| `--ink70` | `rgba(12,11,9,0.70)` | 次级文字 |
| `--ink40` | `rgba(12,11,9,0.40)` | 辅助标签，Mono 元数据 |
| `--ink20` | `rgba(12,11,9,0.20)` | 占位符，禁用态 |
| `--ink08` | `rgba(12,11,9,0.08)` | 分隔线，背景填充 |
| `--ink04` | `rgba(12,11,9,0.04)` | hover 状态背景 |
| `--gold` | `#BF9B5A` | 正向数据（减脂进展 / ON TRACK / 负delta） |
| `--gold20` | `rgba(191,155,90,0.20)` | 金色背景 pill |
| `--sienna` | `#A84830` | 脂肪量 / 正 delta（体重上升） |

### 语义色使用规则

```
正向变化（体重下降、脂肪减少）→ --gold  #BF9B5A
负向变化（体重上升、脂肪增加）→ --sienna #A84830
中性/持平                      → --ink40
脂肪量数据                     → --sienna（始终）
瘦体重数据                     → --ink（始终）
ON TRACK / 进度达标            → --gold + pulse 动效
```

### 严禁使用

- ❌ 任何蓝色、绿色、紫色 accent
- ❌ 渐变色（除 CTA 按钮内部光感层）
- ❌ 高饱和度颜色
- ❌ 黑色（用 `--ink` #0C0B09 替代）
- ❌ 纯白色文字（底色不够深时用 paper 替代）

---

## 字体系统 Typography

### 字体家族

```
Display:  Playfair Display  （数字标题 / 英雄数据 / 页面大标题）
UI Mono:  DM Mono           （所有元数据标签 / 状态文字 / SESSION ID）
Body:     Outfit            （中文正文 / 描述 / 次要信息）
```

### 字重规则

```
Playfair Display 900 Italic  → 英雄数字（68.4 / 结果页主数据）
Playfair Display 900         → 页面大标题（每一次 / 记录）
Playfair Display 700         → 数据行数值（历史列表体重数字）
Playfair Display 400 Italic  → 标题斜体装饰词（身体 / 记录）

DM Mono 300                  → 所有 ALL CAPS 元数据标签
DM Mono 400                  → SESSION ID / 期号 / 日期

Outfit 200                   → 中文描述性文字
Outfit 300                   → 中文正文 / 副标题
Outfit 400                   → 操作按钮文字
Outfit 500                   → 强调正文
```

### 字号规范

| 场景 | 字体 | 字号 | 字重 |
|------|------|------|------|
| 英雄数字（结果页体重） | Playfair | 76–80px | 900 Italic |
| 页面大标题 | Playfair | 34–40px | 900 |
| 历史列表数字 | Playfair | 20–22px | 700 |
| 卡片数据值 | Playfair | 18–20px | 600 |
| ALL CAPS 标签 | DM Mono | 7.5–9px | 300 |
| SESSION ID | DM Mono | 7.5–8px | 400 |
| 期刊号/日期 | DM Mono | 8–9px | 300 |
| 中文正文 | Outfit | 11–12px | 200–300 |
| 按钮文字 | DM Mono | 10–11px | 400 |

### 特殊排版规则

```
字母间距（letter-spacing）：
  ALL CAPS Mono 标签  → 0.16–0.22em
  英雄数字            → -3 to -4px（紧排）
  页面大标题          → -1 to -1.5px
  按钮文字            → 0.20–0.22em

行高（line-height）：
  英雄数字            → 0.85–0.88
  页面大标题          → 0.88–0.95
  正文                → 1.5–1.6
```

---

## 间距系统 Spacing

### 基础单位

```dart
// design_tokens.dart
static const double pagePad = 22.0;   // 页面左右边距
static const double xs  =  4.0;
static const double sm  =  8.0;
static const double md  = 14.0;
static const double lg  = 20.0;
static const double xl  = 28.0;
static const double xxl = 40.0;
```

### 组件内间距

```
字段行 padding          → 13–14px 上下
卡片内 padding          → 16–18px
页面顶部 padding-top    → 20–22px
底部安全区 padding-bot  → 28–32px
分隔线高度              → 0.5px
```

---

## 圆角系统 Border Radius

```dart
static const double chip   =  2.0;   // 运动类型 chips，CTA 按钮，ledger badge
static const double card   =  0.0;   // 表格行无圆角（ledger 风格）
static const double input  =  6.0;   // gender toggle
static const double badge  =  4.0;   // 小标签 badge
static const double panel  = 20.0;   // 暂不使用圆角面板（平铺设计）
static const double phone  = 42.0;   // 手机壳（仅设计稿展示用）
```

**核心原则：** 圆角极少使用，大量使用直角。Ledger/档案感来自于方正的边界，不是圆润的卡片。

---

## 线条与边框 Strokes

```
所有分隔线    → 0.5px  rgba(12,11,9,0.08)
字段 hover 线 → 0.5px  #BF9B5A（金色，from bottom，lineGrow 动效）
历史行竖线    → 2px    #BF9B5A（左侧，scaleY from bottom，hover 触发）
Archive 顶线  → 1.5px  #0C0B09（历史页 masthead 底部粗线，全宽）
进度条        → 1.5px  height
滑杆 track    → 1px    height
```

---

## 动效系统 Motion System

### 动效原则

1. **每个动效必须传达语义**，不是装饰
2. **入场用 stagger**，不同元素错开 80–100ms，建立层次
3. **Easing 统一用弹性曲线** `cubic-bezier(0.16, 1, 0.3, 1)`
4. **Loop 动效保持克制**，幅度小、周期长

### 入场动效

```css
/* 页面/组件入场 */
fadeUp: translateY(18px) → none, opacity 0→1
duration: 0.6–0.7s
easing: cubic-bezier(0.16, 1, 0.3, 1)

/* 卡片/手机壳 */
scaleIn: scale(0.93) → scale(1), opacity 0→1
duration: 0.7s
easing: cubic-bezier(0.16, 1, 0.3, 1)

/* 历史列表行（stagger）*/
slideIn: translateX(-16px) → none, opacity 0→1
duration: 0.5s per row
delay: row_index × 80ms
```

### Flutter 实现

```dart
// 入场动效封装
class FadeUpWidget extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeUpWidget({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 650),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutExpo,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
```

### 持续动效（Loop）

```
3D 模型浮动      floatUp    4s ease-in-out infinite  幅度 ±5px
Delta pill 脉冲  pulse      3s ease-in-out 1.5s inf  opacity 0.5→1
状态点闪烁       dotBlink   1.5s ease-in-out inf
CTA shimmer     shimmer    2.5s linear 1s inf        光扫过按钮
```

### 交互动效

```
字段行 hover    → 金色线从底部 scaleY(0→1)  duration: 0.3s
历史行 hover    → 左侧金竖线 scaleY(0→1)    duration: 0.25s
                  背景 → ink04               duration: 0.15s
Back nav hover  → translateX(-2px)           duration: 0.15s
Gender toggle   → 切换 all 0.2s var(--ease)
Chip 选中       → background + border 0.15s
Slider thumb    → left transition 0.3s ease  拖动时关闭
```

---

## 组件规范 Components

### 01 · 字段行 Field Row

```
高度：       自适应，padding 13px 上下
左：         DM Mono 8.5px 300 ink40 ALL CAPS 标签，fixed width 56px
右：         Playfair 数值 + DM Mono 单位 + chevron ›
分隔线：     0.5px ink08，最后一行无
hover 效果：金色线从底部展开
```

```dart
class FieldRow extends StatelessWidget {
  final String label;
  final String? value;
  final String unit;
  final VoidCallback onTap;
  final bool isLast;
  // ...
}
```

### 02 · Gender Toggle

```
高度：       44px
圆角：       6px（整体）/ 5px（内部选中态）
选中态：     background ink，color paper，无圆角 → 方正
未选：       transparent
字体：       DM Mono 9px 400 0.14em spacing
```

### 03 · Workout Chip

```
圆角：       2px（刻意方正，非 pill）
边框：       0.5px ink20
字体：       DM Mono 8px 300 0.1em
选中：       background ink，color paper，border ink
hover：      ::before ink opacity 0→0.04
```

### 04 · CTA Button

```
高度：       56px（padding 17px）
圆角：       4px
背景：       ink
字体：       DM Mono 10–11px 400 0.22em ALL CAPS
光感层：     ::before top 50% rgba(255,255,255,0.05)
Shimmer：   ::after 横扫光带 2.5s loop
hover：      translateY(-1px) + box-shadow 增强
```

### 05 · Masthead（历史页顶部）

```
标题字体：   Playfair 36px 900 italic
数字字体：   Playfair 52px 900
底边：       1.5px solid ink（全宽粗线，是档案感的核心）
```

### 06 · Ledger Row（历史列表行）

```
Grid：       40px | 1fr | auto（日期 | 数据 | delta）
左侧竖线：   2px gold，position absolute，scaleY(0→1) on hover
日期列：     Playfair 22px 700 + DM Mono 7.5px 300
体重列：     Playfair 20px 700 + DM Mono 8.5px 300 unit
运动标签：   DM Mono 7.5px 300 ink40 0.06em
Delta：      Playfair 18px 700，颜色按语义（gold/sienna/ink40）
```

### 07 · Delta Pill（结果页状态）

```
背景：       gold20 rgba(191,155,90,0.20)
边框：       0.5px gold
圆角：       2px
字体：       DM Mono 8px ink40 0.1em
左侧圆点：   4px gold，dotBlink animation
整体：       pulse 3s opacity loop
```

### 08 · Viewport（3D 展示区）

```
圆角：       8px
背景：       cream → ink08 渐变
高光线：     repeating horizontal lines 0.5px ink04（横格纸质感）
模型：       floatUp 4s loop
相机点：     右上角 4 个 4px 圆点竖排
提示文字：   DM Mono 7.5–8px ink40 0.18em spacing
```

### 09 · Metrics Strip（结果页数据行）

```
Grid：       1fr 0.5px 1fr 0.5px 1fr
竖分隔：     0.5px ink08，自然高度
标签：       DM Mono 7.5px 300 ink40 0.14em
数值：       Playfair 19–20px 700
单位：       DM Mono 8px ink40
Delta：      DM Mono 8.5px，语义色
最后列：     text-align right
```

### 10 · Projection Slider

```
Track：      1px ink08
Fill：       1px ink
Thumb：      13px 圆形，paper 背景，1.5px ink border
             box-shadow: 0 2px 6px rgba(12,11,9,0.2)
拖动交互：   thumb left 跟随，fill width 跟随
时间选择：   3 个 inline text，选中态 underline 0.5px + ink color
```

---

## 页面规范 Screen Specs

### 输入页 Input Screen

```
Section 1 — Masthead（顶部）
  期号：     DM Mono 8.5px 300 ink40  "3D MIRROR / NO.XXX"
  日期：     DM Mono 8.5px 300 ink40  右对齐
  标题：     Playfair 50px 900
             第1行：正体  "今天，"
             第2行：斜体  "身体"
  副标题：   DM Mono 9px 300 ink40 0.14em
  右上 badge：ink 背景，paper 文字，Playfair 数字，DM Mono 标签

Section 2 — Gender Toggle
  margin-top: 16px，margin: 0 22px

Section 3 — Data Fields（玻璃感表单）
  列：       标签 + 值 + 单位，参见 Field Row 规范
  字段顺序：体重 → 体脂率 → 腰围

Section 4 — Workout Chips
  padding:   0 22px 14px

Section 5 — CTA Area
  Progress dots（2px 高，3 段）
  CTA Button（全宽）
```

### 结果页 Result Screen

```
Section 1 — Nav（返回）
  "← BACK"  DM Mono 8.5px ink40，hover 左移 2px

Section 2 — Session ID
  "SESSION #XXX · YYYY.MM.DD · DAY"  DM Mono 7.5px 300

Section 3 — Hero Number（英雄数字）
  体重：     Playfair 80px 900 italic
  小数点后：  font-size: 52px（相对缩小）
  单位：      DM Mono 14px 300 ink40，bottom-aligned
  标签：      DM Mono 8px ink40 0.2em
  Delta Pill：紧跟标签下方 margin-top: 8px

Section 4 — Viewport（3D 区域）
  margin:    0 22px，height: 188–210px

Section 5 — Metrics Strip
  margin:    14px 22px 0

Section 6 — Hairline Rule
  0.5px ink08，margin: 14px 22px

Section 7 — Projection Compare
  padding:   0 22px

Section 8 — Share Buttons
  两个按钮，左：outline，右：ink 实底
  margin:    14px 22px 28px
```

### 历史页 History Screen

```
Section 1 — Masthead
  左：       archive 标签 + 大标题（Playfair italic）
  右：       会话总数（Playfair 52px 900）+ 标签
  底边：     1.5px ink（全宽粗线）

Section 2 — Sparkline（趋势折线）
  height:    48–52px，margin: 0 22px
  线：       1px ink20，无 fill
  终点圆：   2.5px ink，+ 扩散圆 5px ink15
  标注：     DM Mono 7px 终点值 + 左下角趋势说明

Section 3 — Ledger Header
  background: ink04
  padding:   7px 22px
  字体：     DM Mono 7.5px 300 ink40 0.16em

Section 4 — Session Rows（stagger animation）
  参见 Ledger Row 规范

底部提示：  DM Mono 7.5px 0.16em ink20
```

---

## 暗色模式 Dark Mode

**MVP 阶段不支持暗色模式。**

如后续支持，色彩映射：
```
--paper  → #0F0E0C
--cream  → #1A1916
--ink    → #F5F3EE（翻转）
--gold   → #D4AA68（略亮）
--sienna → #C85A3A（略亮）
```

---

## Flutter 实现备注

### 字体加载

```yaml
# pubspec.yaml
fonts:
  - family: PlayfairDisplay
    fonts:
      - asset: assets/fonts/PlayfairDisplay-Regular.ttf
      - asset: assets/fonts/PlayfairDisplay-Italic.ttf
        style: italic
      - asset: assets/fonts/PlayfairDisplay-Bold.ttf
        weight: 700
      - asset: assets/fonts/PlayfairDisplay-Black.ttf
        weight: 900
      - asset: assets/fonts/PlayfairDisplay-BlackItalic.ttf
        weight: 900
        style: italic
  - family: DMMono
    fonts:
      - asset: assets/fonts/DMMono-Light.ttf
        weight: 300
      - asset: assets/fonts/DMMono-Regular.ttf
        weight: 400
      - asset: assets/fonts/DMMono-Medium.ttf
        weight: 500
  - family: Outfit
    fonts:
      - asset: assets/fonts/Outfit-ExtraLight.ttf
        weight: 200
      - asset: assets/fonts/Outfit-Light.ttf
        weight: 300
      - asset: assets/fonts/Outfit-Regular.ttf
        weight: 400
      - asset: assets/fonts/Outfit-Medium.ttf
        weight: 500
```

### 关键动效 Curve

```dart
// 统一弹性曲线
static const Curve mirrorEase = Cubic(0.16, 1.0, 0.3, 1.0);

// 等价于 CSS cubic-bezier(0.16, 1, 0.3, 1)
// Flutter 内置最接近：Curves.easeOutExpo
```

### 颜色常量

```dart
class MirrorColors {
  static const Color paper   = Color(0xFFF5F3EE);
  static const Color cream   = Color(0xFFEAE6DC);
  static const Color ink     = Color(0xFF0C0B09);
  static const Color ink70   = Color(0xB30C0B09);
  static const Color ink40   = Color(0x660C0B09);
  static const Color ink20   = Color(0x330C0B09);
  static const Color ink08   = Color(0x140C0B09);
  static const Color ink04   = Color(0x0A0C0B09);
  static const Color gold    = Color(0xFFBF9B5A);
  static const Color gold20  = Color(0x33BF9B5A);
  static const Color sienna  = Color(0xFFA84830);
}
```

---

## 不可逾越的红线

1. **字体** — 只能用 Playfair Display + DM Mono + Outfit，三者缺一不可
2. **颜色** — 除系统色外，只有 paper / cream / ink / gold / sienna 五色
3. **圆角** — 主要元素最大 6px，CTA 按钮 4px，不允许大圆角卡片
4. **装饰** — 没有图标库图标（用文字替代），没有插图，没有色彩图形
5. **分隔** — 只有 0.5px 线，不允许色块分隔
6. **Archive 粗线** — 历史页 masthead 底部 1.5px ink 全宽线，是品牌识别核心，不可删除
7. **新增功能** — 任何新页面必须同时更新 app_zh.arb 和 app_en.arb

