# 3D Mirror — Design System Master

> **Global Source of Truth.** All screens and components must conform to this document unless a page-specific override exists in `design-system/pages/[page].md`.

---

## 1. Philosophy

**Three words:** Editorial · Luxury · Archive

打开 App，像翻开一本只属于你的私人健身杂志。  
每一个数字都是你的战绩，每一次记录都是新的封面。

### Tone
- Authority without arrogance — every screen feels curated, not crowded
- Data as art — numbers are editorial statistics, not analytics dashboards
- Ritual over gamification — no streaks, no badges, no confetti
- Restraint is the luxury — maximum one gold element per screen

### NOT This App
- ❌ Neon fitness-bro energy
- ❌ Purple/pink AI gradients
- ❌ Gamification badges, streak flames, confetti
- ❌ Overwhelming data dashboards
- ❌ Generic sans-serif as display font
- ❌ Cluttered layouts — every screen should feel like a magazine spread
- ❌ Aggressive upsell popups

---

## 2. Color System

### Light Mode (Primary)

| Token | Hex | Dart | Usage |
|-------|-----|------|-------|
| `bg` | `#FAF8F5` | `Color(0xFFFAF8F5)` | Page background — warm ivory |
| `bg2` | `#EFEDE8` | `Color(0xFFEFEDE8)` | Secondary bg, pickers, toggles |
| `surface` | `#FFFFFF` | `Color(0xFFFFFFFF)` | Cards, sheets, modals |
| `text1` | `#1A1A1A` | `Color(0xFF1A1A1A)` | Primary text — near-black ink |
| `text2` | `#1A1A1A @ 40%` | `Color(0x661A1A1A)` | Secondary text, body copy |
| `text3` | `#1A1A1A @ 20%` | `Color(0x331A1A1A)` | Labels, hints, placeholders |
| `divider` | `#1A1A1A @ 8%` | `Color(0x141A1A1A)` | Hairline dividers |
| `gold` | `#C9A96E` | `Color(0xFFC9A96E)` | **Accent — one use per screen max** |

### Dark Mode (Support)

| Token | Hex | Usage |
|-------|-----|-------|
| `bg-dark` | `#0E0E0E` | Deep black — OLED-safe |
| `surface-dark` | `#181818` | Cards, modals |
| `text1-dark` | `#F0EDE8` | Primary text |
| `text2-dark` | `#F0EDE8 @ 40%` | Secondary text |
| `gold` | `#C9A96E` | Same gold — no change in dark mode |

### Gold Usage Rules
- One gold element per screen — masthead rule, selected state, or single accent CTA
- Never use gold on dark backgrounds below 4.5:1 contrast (ink #1A1A1A on gold = 4.6:1 ✓)
- Gold is for: masthead app name, selected goal border, active progress dot, premium badge
- Never use gold for body text or labels

---

## 3. Typography

### Fonts
| Role | Family | Fallback |
|------|--------|----------|
| Display / Serif | `DMSerifDisplay` | Georgia, serif |
| Body / UI | `Outfit` | system-ui, sans-serif |

### Type Scale

| Token | Size | Weight | Family | Letter-Spacing | Usage |
|-------|------|--------|--------|----------------|-------|
| `displayHero` | 76px | 400 | serif | -2.0 | Hero number (weight, body fat) |
| `displayXl` | 52px | 400 | serif | -1.2 | Secondary hero numbers |
| `display` | 36px | 400 | serif | -0.5 | Section heroes |
| `displayMd` | 26px | 400 | serif | -0.6 | Field values in pickers |
| `title` | 34px | 400 | serif | -0.3 | Screen titles — use italic for emphasis |
| `titleSm` | 28px | 400 | serif | 0 | Sub-titles |
| `body` | 14px | 300 | sans | 0 | All body copy |
| `bodyS` | 12px | 300 | sans | 0 | Secondary body, captions in sheets |
| `label` | 9px | 400 | sans | +1.8 | UI labels — always UPPERCASE |
| `overline` | 10px | 300 | sans | +3.5 | Editorial section headers — UPPERCASE, gold |
| `labelMd` | 11px | 400 | sans | +2.2 | Medium section labels |
| `unit` | 11px | 300 | sans | 0 | Unit suffixes next to data |
| `unitLg` | 18px | 300 | sans | +0.5 | Units next to 76px displayHero |
| `button` | 14px | 400 | sans | +0.6 | Button labels — bg color |
| `caption` | 10px | 300 | sans | +0.3 | Fine print, timestamps |

### Typography Rules
- Serif italic = emphasis. Use `fontStyle: FontStyle.italic` on one word in a title for editorial feel.
- Numbers are editorial statistics: use `displayMd` or larger for values, `unit` for suffixes.
- Body line height: 1.5 minimum. Display line height: 0.9–1.05 (tight, magazine-style).
- NEVER use Inter, Roboto, or SF Pro as display fonts.

---

## 4. Spacing System

```
xs      =  4px   micro gaps, icon padding
sm      =  8px   tight element gaps
md      = 16px   default element spacing
lg      = 24px   pagePad (horizontal page margin)
xl      = 32px   section gaps
xxl     = 48px   major section separation
xxxl    = 72px   hero top breathing room
pagePad = 24px   horizontal screen padding (constant)
```

---

## 5. Border Radius

```
sm   =  8px   chips, small tags
md   = 12px   toggles, input rows
lg   = 16px   buttons, cards
xl   = 20px   large cards, sheets
full = 999px  pills, avatar rings
```

---

## 6. Motion System

### Durations
| Token | ms | Usage |
|-------|-----|-------|
| `fast` | 150ms | Toggle switches, checkbox tap feedback |
| `normal` | 280ms | Page transitions (fade), standard interactions |
| `slow` | 450ms | Onboarding step transitions, content reveals |
| `xslow` | 650ms | Count-up number animations |
| `reveal` | 900ms | Hero entry sequence (result screen) |
| `stagger` | 80ms | List item stagger base interval |

### Curves
| Token | Curve | Character |
|-------|-------|-----------|
| `enter` | `easeOut` | Authority — decelerates to a stop |
| `countUp` | `easeOutCubic` | Fast start, precise landing |
| `snap` | `easeInOut` | Symmetric, satisfying toggle |
| `pageSlide` | `easeInOutCubic` | Film-reel page change |
| `sparkDraw` | `easeInOutSine` | Sinusoidal chart line draw |

### Motion Rules
- Transitions: 300–500ms range (deliberate, not bouncy)
- No spring physics, no bounce easing, no confetti
- Page slide: 8% offset (`Offset(0.08, 0)`) — subtle, not dramatic
- Staggered lists: 80ms base, max 5 items staggered (400ms total max)
- `prefers-reduced-motion`: disable all translate/slide animations, keep fade only

---

## 7. Component Specifications

### ArchiveMasthead
The brand identifier. Present on key screens (onboarding consent, result cover).

```
Layout:   [                    3D MIRROR                    ]
          [─────────────────────────────────────────────────]
Style:    overline, gold color, centered, 1.5px bottom border in divider color
Spacing:  paddingH: pagePad, paddingV: 20px top / 12px bottom
```

### OverlineLabel
Section divider in editorial style.

```
Text:    UPPERCASE, overline style (10px, +3.5 letterSpacing, text3)
Usage:   "ABOUT YOU", "LEGAL & PRIVACY", "YOUR GOAL", "FINAL STEP"
```

### FieldRow
Tappable data input row with label + large value.

```
Layout:  [label (body, text2)]  [value (displayMd, text1)] [→]
Height:  56px minimum (comfortable touch target)
Divider: hairline below, except isLast = true
Tap:     opens Cupertino picker sheet
```

### GenderToggle
Segmented control for gender selection.

```
Container:  bg2, md radius, 3px padding, 44px height
Segments:   animated white bg on selected (surface color), sm radius
Text:       Chinese characters (男/女), body style
```

### GoalCard
Goal selection row. One per goal option.

```
Layout:  [label + subtitle (left)]  [selected indicator (right)]
Selected: 1px gold border on left edge (Container decoration), label in text1
Unselected: label in text2, no border
Height:  56px minimum
```

### ConsentRow
Checkbox + label for legal consent.

```
Layout:  [checkbox (20×20, rounded-sm)]  [label text (body, text2)]
Checked: checkbox fill text1, checkmark in surface
Unchecked: checkbox border text3
```

### CTAButton (Primary)
```
Height:    54px
BgColor:   text1 (ink)
TextColor: bg (ivory)
Radius:    lg (16px)
Disabled:  opacity 0.3
```

### OutlineButton (Secondary / Back)
```
Height:    54px
Border:    0.5px divider
TextColor: text2
Radius:    lg (16px)
```

### ProgressBar
Segmented, hairline weight.

```
Height:    2px
Gap:       4px between segments
Active:    text1 fill
Inactive:  divider fill
Animation: normal duration, snap curve
```

### CupertinoPicker Sheet
```
Height:    280px
BgColor:   surface
Header:    [cancel] [label (bodyS, text2)] [confirm]
Item:      body style, text1 color, 40px itemExtent
```

---

## 8. Screen Layout Rules

- **Every screen should feel like it could be a magazine spread**
- Horizontal padding: `pagePad` (24px) on both sides, always
- Safe area: respect top and bottom safe areas
- Hero content sits at ~35% from top (not dead center)
- Bottom nav / CTA: fixed, 16px above bottom safe area + 32px bottom padding
- Scroll: always `SingleChildScrollView` for form content; hero data can be non-scrolling

---

## 9. Onboarding Screen Spec

### Flow
```
[Auth / Login]
     ↓
[Step 0: Legal & Privacy Consent]  ← gate: both checkboxes required
     ↓
[Step 1: Basic Info]               ← gender, age, height, weight
     ↓
[Step 2: Goal Selection]           ← goal required to proceed
     ↓
[Home / History]
```

### Step 0 — Legal Consent
- Masthead: `3D MIRROR` (gold overline, centered, 1.5px bottom border)
- Overline: `LEGAL & PRIVACY`
- Title: `条款与隐私` (serif, italic on second word)
- Body copy: bullet list of what data is collected and how it's used
- Two ConsentRows: Terms of Service + Privacy Policy
- CTA disabled until both checked

### Step 1 — Basic Info
- Overline: `ABOUT YOU`
- Title: `告诉我\n你的基本信息` (italic on "基本信息")
- Fields: Gender toggle, Age, Height, Weight
- All via Cupertino picker sheets

### Step 2 — Goal
- Overline: `YOUR GOAL`
- Title: `你的\n目标` (italic on "目标")
- Four GoalCards: 减脂, 增肌, 塑形, 健康管理
- Selection persisted in state; gold left-border on selected card
- CTA disabled until a goal is selected

---

## 10. Localization

- UI labels: English
- Chinese body copy/titles: acceptable for intimacy
- Mixed CN/EN in marketing copy and titles: ✓
- Data & scientific terms: English preferred
- All strings should be externalized to `l10n/app_*.arb` files eventually

---

## 11. Implementation Reference

**Design tokens:** `flutter_app/lib/core/theme/design_tokens.dart`  
**App theme:** `flutter_app/lib/core/theme/app_theme.dart`  
**Animation utilities:** `flutter_app/lib/core/widgets/animate_widgets.dart`  
**Router:** `flutter_app/lib/core/router/app_router.dart`

---

*Last updated: 2026-04-26 — Editorial × Luxury × Archive*
