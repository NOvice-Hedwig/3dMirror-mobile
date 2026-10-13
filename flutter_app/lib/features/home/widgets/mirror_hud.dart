// lib/features/home/widgets/mirror_hud.dart
// HUD 浮层 — 叠加在 Unity 视口上方
// 非交互部分（Logo / HudCard / WeekDots）内部包 IgnorePointer，
// NOW·TARGET Toggle 可交互。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/avatar_view_mode.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../providers/home_provider.dart';
import '../../../providers/log_provider.dart';
import '../home_design.dart';
import 'week_dots.dart';

class MirrorHUD extends ConsumerWidget {
  const MirrorHUD({
    super.key,
    required this.viewMode,
    required this.onToggleViewMode,
    required this.hasTarget,
  });

  final AvatarViewMode viewMode;
  final VoidCallback   onToggleViewMode;
  final bool           hasTarget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak     = ref.watch(streakProvider);
    final workoutMin = ref.watch(todayWorkoutMinProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 顶部栏：Logo + 连续打卡（非交互）────────────────────────────────
        Positioned(
          top: 16, left: 20, right: 20,
          child: IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('3D MIRROR', style: kLogoText()),
                _StreakBadge(streak: streak),
              ],
            ),
          ),
        ),

        // ── NOW · TARGET Toggle（hasTarget 时显示，可交互）──────────────────
        if (hasTarget)
          Positioned(
            top: 52, left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onToggleViewMode,
                child: AnimatedContainer(
                  duration: MirrorDuration.fast,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: MirrorColors.divider, width: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: MirrorDuration.fast,
                        curve: MirrorCurve.snap,
                        style: MirrorText.overline.copyWith(
                          color: viewMode == AvatarViewMode.current
                              ? MirrorColors.text1
                              : MirrorColors.text3,
                          fontSize: 9,
                          letterSpacing: 1.5,
                        ),
                        child: const Text('NOW'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('·',
                            style: MirrorText.caption.copyWith(
                                color: MirrorColors.divider)),
                      ),
                      AnimatedDefaultTextStyle(
                        duration: MirrorDuration.fast,
                        curve: MirrorCurve.snap,
                        style: MirrorText.overline.copyWith(
                          color: viewMode == AvatarViewMode.target
                              ? MirrorColors.gold
                              : MirrorColors.text3,
                          fontSize: 9,
                          letterSpacing: 1.5,
                        ),
                        child: const Text('TARGET'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── 左侧：摄入 / 消耗（非交互）──────────────────────────────────────
        Positioned(
          top: 110, left: 16,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HudCard(
                  label: '摄入',
                  value: ref.watch(todayStatsProvider).when(
                    data: (s) => s.totalKcalIn > 0
                        ? s.totalKcalIn.toStringAsFixed(0) : '--',
                    loading: () => '--',
                    error: (_, __) => '--',
                  ),
                  unit: 'kcal',
                ),
                const SizedBox(height: 10),
                const _HudCard(label: '消耗', value: '--', unit: 'kcal'),
              ],
            ),
          ),
        ),

        // ── 右侧：运动 / 睡眠（非交互）──────────────────────────────────────
        Positioned(
          top: 110, right: 16,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HudCard(
                  label: '运动',
                  value: workoutMin > 0 ? '$workoutMin' : '--',
                  unit: 'min',
                ),
                const SizedBox(height: 10),
                _HudCard(
                  label: '睡眠',
                  value: ref.watch(todayStatsProvider).when(
                    data: (s) => s.sleepHours > 0
                        ? s.sleepHours.toStringAsFixed(1) : '--',
                    loading: () => '--',
                    error: (_, __) => '--',
                  ),
                  unit: 'h',
                ),
              ],
            ),
          ),
        ),

        // ── 底部：7日打卡热力圆点（非交互）──────────────────────────────────
        Positioned(
          bottom: 72, left: 0, right: 0,
          child: IgnorePointer(
            child: const Center(child: WeekDots()),
          ),
        ),
      ],
    );
  }
}

// ── 连续打卡徽章 ──────────────────────────────────────────────────────────────

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🔥', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          '连续 $streak 天',
          style: kBarlow(
              size: 12,
              weight: FontWeight.w500,
              color: kGold),
        ),
      ],
    );
  }
}

// ── HUD 数据卡片 ──────────────────────────────────────────────────────────────

class _HudCard extends StatelessWidget {
  const _HudCard({
    required this.label,
    required this.value,
    this.unit,
  });

  final String  label;
  final String  value;
  final String? unit;

  static const double _labelSpacing = 1.08;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: kGoldGhost,
        border: Border.all(color: kBorderColor, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: kBarlow(
                size: 9, color: kTextDim, letterSpacing: _labelSpacing),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: kBarlow(size: 14, weight: FontWeight.w500, color: kGold),
          ),
          if (unit != null) ...[
            const SizedBox(height: 1),
            Text(
              unit!,
              style: kBarlow(
                  size: 9, color: kTextDim, letterSpacing: _labelSpacing),
            ),
          ],
        ],
      ),
    );
  }
}
