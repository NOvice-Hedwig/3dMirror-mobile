// lib/features/home/widgets/week_dots.dart
// 7 日打卡热力圆点
//
// 颜色映射（当日运动分钟数）：
//   0 min      → kGoldGhost（8% 透明度）— 未打卡
//   1–29 min   → kGold 40% — 轻量打卡
//   ≥ 30 min   → kGold 实色 — 达标打卡
//
// 数据来源：weekWorkoutMinutesProvider（Map<DateTime, int>）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/home_provider.dart';
import '../home_design.dart';

class WeekDots extends ConsumerWidget {
  const WeekDots({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekMap = ref.watch(weekWorkoutMinutesProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        // i = 0 → 6 天前，i = 6 → 今天
        final date = today.subtract(Duration(days: 6 - i));
        final minutes = weekMap[date] ?? 0;
        return Padding(
          padding: EdgeInsets.only(right: i < 6 ? 8.0 : 0.0),
          child: _Dot(minutes: minutes),
        );
      }),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.minutes});
  final int minutes;

  Color get _color {
    if (minutes == 0)  return kGoldGhost;
    if (minutes < 30)  return kGold.withValues(alpha: 0.4);
    return kGold;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
