// lib/features/home/home_design.dart
// HomeScreen 专属深色 design token
// 与全局 MirrorColors（暖米色浅色）平行，仅在 lib/features/home/ 目录内引用

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── 颜色 ───────────────────────────────────────────────────────────────────────

const kHomeBg      = Color(0xFF0C0A06);
const kGold        = Color(0xFFD4A843);
const kGoldDim     = Color(0x4DD4A843);   // 30% opacity — glow / shadow
const kGoldGhost   = Color(0x14D4A843);   // 8%  opacity — card bg
const kTextPrimary = Color(0xFFFAF3DC);
const kTextMid     = Color(0xFFC8B888);
const kTextDim     = Color(0xFF6B5C3E);
const kBorderColor = Color(0x2DD4A843);   // 18% opacity — card border
const kTeal        = Color(0xFF0F9E84);

// ── 字体工厂 ──────────────────────────────────────────────────────────────────

/// Logo / 大标题：Playfair Display
TextStyle kLogoText({double size = 14}) => GoogleFonts.playfairDisplay(
  fontSize: size, fontWeight: FontWeight.w700,
  color: kGold, letterSpacing: 4.5,
);

/// 正文 / 数据：Barlow
TextStyle kBarlow({
  double size = 12,
  FontWeight weight = FontWeight.w400,
  Color? color,
  double? letterSpacing,
  double? height,
}) =>
    GoogleFonts.barlow(
      fontSize: size,
      fontWeight: weight,
      color: color ?? kTextMid,
      letterSpacing: letterSpacing,
      height: height,
    );
