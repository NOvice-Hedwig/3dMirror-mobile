import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MirrorColors {
  MirrorColors._();
  static const Color bg       = Color(0xFFFAF8F5);  // Warm Ivory
  static const Color bg2      = Color(0xFFEFEDE8);
  static const Color surface  = Color(0xFFFFFFFF);
  static const Color text1    = Color(0xFF1A1A1A);  // Deep Ink
  static const Color text2    = Color(0x661A1A1A);  // 40% ink
  static const Color text3    = Color(0x331A1A1A);  // 20% ink
  static const Color divider  = Color(0x141A1A1A);  // 8% ink
  static const Color gold     = Color(0xFFC9A96E);  // Warm Gold — one use per screen max
  static const Color accent   = Color(0xFF1A1A1A);  // = text1 — CTA / primary interactive
  static const Color error    = Color(0xFFB00020);
  static const Color positive = Color(0xFF1A1A1A);
  static const Color viewport = Color(0xFFEFEDE8);
}

class MirrorText {
  MirrorText._();

  // ── Display (Cormorant Garamond serif) ────────────────────────────────────────

  /// 76px — hero number (weight main display)
  static final TextStyle displayHero = GoogleFonts.cormorantGaramond(
    fontSize: 76, fontWeight: FontWeight.w400,
    color: MirrorColors.text1, height: 0.9, letterSpacing: -2.0,
  );

  /// 52px — secondary hero numbers (body fat, lean mass)
  static final TextStyle displayXl = GoogleFonts.cormorantGaramond(
    fontSize: 52, fontWeight: FontWeight.w400,
    color: MirrorColors.text1, height: 0.95, letterSpacing: -1.2,
  );

  static final TextStyle display = GoogleFonts.cormorantGaramond(
    fontSize: 36, fontWeight: FontWeight.w400,
    color: MirrorColors.text1, height: 1.0, letterSpacing: -0.5,
  );

  static final TextStyle displayMd = GoogleFonts.cormorantGaramond(
    fontSize: 26, fontWeight: FontWeight.w400,
    color: MirrorColors.text1, height: 1.0, letterSpacing: -0.6,
  );

  static final TextStyle title = GoogleFonts.cormorantGaramond(
    fontSize: 34, fontWeight: FontWeight.w400,
    color: MirrorColors.text1, height: 1.05, letterSpacing: -0.3,
  );

  static final TextStyle titleSm = GoogleFonts.cormorantGaramond(
    fontSize: 28, fontWeight: FontWeight.w400,
    color: MirrorColors.text1, height: 1.05,
  );

  // ── Body / UI (Outfit sans-serif) ─────────────────────────────────────────────

  static final TextStyle body = GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.w300,
    color: MirrorColors.text2, height: 1.5,
  );

  static final TextStyle bodyS = GoogleFonts.outfit(
    fontSize: 12, fontWeight: FontWeight.w300,
    color: MirrorColors.text2, height: 1.5,
  );

  static final TextStyle label = GoogleFonts.outfit(
    fontSize: 9, fontWeight: FontWeight.w400,
    color: MirrorColors.text3, letterSpacing: 1.8, height: 1.0,
  );

  /// Editorial overline — large letter-spacing uppercase, magazine section titles
  static final TextStyle overline = GoogleFonts.outfit(
    fontSize: 10, fontWeight: FontWeight.w300,
    color: MirrorColors.text3, letterSpacing: 3.5, height: 1.0,
  );

  static final TextStyle labelMd = GoogleFonts.outfit(
    fontSize: 11, fontWeight: FontWeight.w400,
    color: MirrorColors.text3, letterSpacing: 2.2, height: 1.0,
  );

  static final TextStyle unit = GoogleFonts.outfit(
    fontSize: 11, fontWeight: FontWeight.w300,
    color: MirrorColors.text3,
  );

  /// displayHero companion unit (18px — avoid looking weightless next to 76px)
  static final TextStyle unitLg = GoogleFonts.outfit(
    fontSize: 18, fontWeight: FontWeight.w300,
    color: MirrorColors.text3, letterSpacing: 0.5,
  );

  static final TextStyle button = GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: MirrorColors.bg, letterSpacing: 0.6,
  );

  static final TextStyle caption = GoogleFonts.outfit(
    fontSize: 10, fontWeight: FontWeight.w300,
    color: MirrorColors.text3, letterSpacing: 0.3,
  );
}

class MirrorSpacing {
  MirrorSpacing._();
  static const double xs      = 4;
  static const double sm      = 8;
  static const double md      = 16;
  static const double lg      = 24;
  static const double xl      = 32;
  static const double xxl     = 48;
  static const double xxxl    = 72;
  static const double pagePad = 24;
}

class MirrorRadius {
  MirrorRadius._();
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double full = 999;
}

class MirrorDuration {
  MirrorDuration._();
  static const Duration fast   = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow   = Duration(milliseconds: 450);
  static const Duration xslow  = Duration(milliseconds: 650);
  static const Duration reveal  = Duration(milliseconds: 900);
  static const Duration stagger = Duration(milliseconds: 80);
}

/// Unified easing curves — all animations must use these, no hardcoded Curves.*
class MirrorCurve {
  MirrorCurve._();
  static const Curve enter     = Curves.easeOut;
  static const Curve countUp   = Curves.easeOutCubic;
  static const Curve snap      = Curves.easeInOut;
  static const Curve pageSlide = Curves.easeInOutCubic;
  static const Curve sparkDraw = Curves.easeInOutSine;
}
