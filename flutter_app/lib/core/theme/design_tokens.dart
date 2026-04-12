import 'package:flutter/material.dart';

class MirrorColors {
  MirrorColors._();
  static const Color bg       = Color(0xFFF7F6F3);
  static const Color bg2      = Color(0xFFEFEDE8);
  static const Color surface  = Color(0xFFFFFFFF);
  static const Color text1    = Color(0xFF021024);
  static const Color text2    = Color(0x66021024);
  static const Color text3    = Color(0x33021024);
  static const Color divider  = Color(0x14021024);
  static const Color accent   = Color(0xFF021024);
  static const Color positive = Color(0xFF021024);
  static const Color viewport = Color(0xFFEFEDE8);
}

class MirrorText {
  MirrorText._();
  static const String serif = 'DMSerifDisplay';
  static const String sans  = 'Outfit';

  /// 76px — 杂志封面英雄数字（体重主展示）
  static const TextStyle displayHero = TextStyle(
    fontFamily: serif, fontSize: 76, fontWeight: FontWeight.w400,
    color: MirrorColors.text1, height: 0.9, letterSpacing: -2.0,
  );
  /// 52px — 次级英雄数字（体脂率、瘦体重）
  static const TextStyle displayXl = TextStyle(
    fontFamily: serif, fontSize: 52, fontWeight: FontWeight.w400,
    color: MirrorColors.text1, height: 0.95, letterSpacing: -1.2,
  );
  static const TextStyle display = TextStyle(
    fontFamily: serif, fontSize: 36, fontWeight: FontWeight.w400,
    color: MirrorColors.text1, height: 1.0, letterSpacing: -0.5,
  );
  static const TextStyle displayMd = TextStyle(
    fontFamily: serif, fontSize: 26, fontWeight: FontWeight.w400,
    color: MirrorColors.text1, height: 1.0, letterSpacing: -0.6,
  );
  static const TextStyle title = TextStyle(
    fontFamily: serif, fontSize: 34, fontWeight: FontWeight.w400,
    color: MirrorColors.text1, height: 1.05, letterSpacing: -0.3,
  );
  static const TextStyle titleSm = TextStyle(
    fontFamily: serif, fontSize: 28, fontWeight: FontWeight.w400,
    color: MirrorColors.text1, height: 1.05,
  );
  static const TextStyle body = TextStyle(
    fontFamily: sans, fontSize: 14, fontWeight: FontWeight.w300,
    color: MirrorColors.text2, height: 1.5,
  );
  static const TextStyle bodyS = TextStyle(
    fontFamily: sans, fontSize: 12, fontWeight: FontWeight.w300,
    color: MirrorColors.text2, height: 1.5,
  );
  static const TextStyle label = TextStyle(
    fontFamily: sans, fontSize: 9, fontWeight: FontWeight.w400,
    color: MirrorColors.text3, letterSpacing: 1.8, height: 1.0,
  );
  /// 编辑级 overline — 大字间距大写小字，杂志分区标题
  static const TextStyle overline = TextStyle(
    fontFamily: sans, fontSize: 10, fontWeight: FontWeight.w300,
    color: MirrorColors.text3, letterSpacing: 3.5, height: 1.0,
  );
  /// 中等 section label
  static const TextStyle labelMd = TextStyle(
    fontFamily: sans, fontSize: 11, fontWeight: FontWeight.w400,
    color: MirrorColors.text3, letterSpacing: 2.2, height: 1.0,
  );
  static const TextStyle unit = TextStyle(
    fontFamily: sans, fontSize: 11, fontWeight: FontWeight.w300,
    color: MirrorColors.text3,
  );
  /// displayHero 配套单位（18px，避免在 76px 旁边失重）
  static const TextStyle unitLg = TextStyle(
    fontFamily: sans, fontSize: 18, fontWeight: FontWeight.w300,
    color: MirrorColors.text3, letterSpacing: 0.5,
  );
  static const TextStyle button = TextStyle(
    fontFamily: sans, fontSize: 14, fontWeight: FontWeight.w400,
    color: MirrorColors.bg, letterSpacing: 0.6,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: sans, fontSize: 10, fontWeight: FontWeight.w300,
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
  static const double xxxl    = 72;  // result 屏 hero 顶部留白
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
  static const Duration xslow  = Duration(milliseconds: 650);  // 数字 count-up
  static const Duration reveal  = Duration(milliseconds: 900); // hero 入场序列
  static const Duration stagger = Duration(milliseconds: 80);  // 列表错位基准
}

/// 统一缓动曲线 — 所有动画必须使用此处定义的曲线，禁止硬编码 Curves.*
class MirrorCurve {
  MirrorCurve._();
  /// 入场减速：权威感，减速到位
  static const Curve enter     = Curves.easeOut;
  /// 数字滚动：快速起步，精确落地
  static const Curve countUp   = Curves.easeOutCubic;
  /// 交互反馈：对称平滑
  static const Curve snap      = Curves.easeInOut;
  /// 页面切换：胶片感
  static const Curve pageSlide = Curves.easeInOutCubic;
  /// 抖线绘制：正弦缓入缓出
  static const Curve sparkDraw = Curves.easeInOutSine;
}
