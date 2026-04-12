import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/design_tokens.dart';

// ── FadeSlideIn ────────────────────────────────────────────────────────────────
/// 统一入场动画：fade + 向上 slide。所有屏幕的入场序列均使用此组件。
/// [delay] 控制错位时序，[offsetY] 为起始偏移像素（正值 = 从下方进入）。
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration,
    this.offsetY = 18.0,
  });

  final Widget child;
  final Duration delay;
  final Duration? duration;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    final d = duration ?? MirrorDuration.slow;
    return child
        .animate(delay: delay)
        .fadeIn(duration: d, curve: MirrorCurve.enter)
        .slideY(
          begin: offsetY / 200, // flutter_animate 用比例单位，除以 200 ≈ 18px
          end: 0,
          duration: d,
          curve: MirrorCurve.enter,
        );
  }
}

// ── CountUpText ────────────────────────────────────────────────────────────────
/// 数字滚动组件：从 0 滚动到 [value]，配合 [FadeSlideIn] 的 delay 使用。
/// 使用 TweenAnimationBuilder 以精确控制数字格式。
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.style,
    this.fractionDigits = 1,
    this.duration = const Duration(milliseconds: 650),
    this.prefix = '',
    this.suffix = '',
  });

  final double value;
  final TextStyle style;
  final int fractionDigits;
  final Duration duration;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: value),
      duration: duration,
      curve: MirrorCurve.countUp,
      builder: (_, v, __) => Text(
        '$prefix${v.toStringAsFixed(fractionDigits)}$suffix',
        style: style,
      ),
    );
  }
}

// ── AnimatedSparkline ──────────────────────────────────────────────────────────
/// 抖线从左向右绘制动画。替代原 _Sparkline 组件在 history_screen.dart 中使用。
class AnimatedSparkline extends StatefulWidget {
  const AnimatedSparkline({
    super.key,
    required this.values,
    this.drawDuration = const Duration(milliseconds: 900),
    this.delay = const Duration(milliseconds: 200),
    this.height = 60.0,
  });

  final List<double> values;
  final Duration drawDuration;
  final Duration delay;
  final double height;

  @override
  State<AnimatedSparkline> createState() => _AnimatedSparklineState();
}

class _AnimatedSparklineState extends State<AnimatedSparkline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.drawDuration);
    _anim = CurvedAnimation(parent: _ctrl, curve: MirrorCurve.sparkDraw);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.values.length < 2) return SizedBox(height: widget.height);
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => CustomPaint(
          painter: _AnimatedSparkPainter(
            values: widget.values,
            progress: _anim.value,
          ),
          size: Size(double.infinity, widget.height),
        ),
      ),
    );
  }
}

class _AnimatedSparkPainter extends CustomPainter {
  _AnimatedSparkPainter({required this.values, required this.progress});
  final List<double> values;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final mn  = values.reduce((a, b) => a < b ? a : b);
    final mx  = values.reduce((a, b) => a > b ? a : b);
    final rng = (mx - mn).abs() < 0.01 ? 1.0 : mx - mn;

    final pts = List.generate(values.length, (i) => Offset(
      i / (values.length - 1) * size.width,
      size.height - 8 - (values[i] - mn) / rng * (size.height - 16),
    ));

    // 根据 progress 决定渲染多少个点
    final visibleCount = (pts.length * progress).clamp(1.0, pts.length.toDouble()).round();

    final linePaint = Paint()
      ..color       = MirrorColors.text1.withValues(alpha: 0.15)
      ..strokeWidth = 1
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.sublist(1, visibleCount)) { path.lineTo(p.dx, p.dy); }
    canvas.drawPath(path, linePaint);

    // 终点圆点随 progress 移动
    canvas.drawCircle(
      pts[visibleCount - 1], 3,
      Paint()..color = MirrorColors.text1,
    );
  }

  @override
  bool shouldRepaint(_AnimatedSparkPainter o) =>
      o.progress != progress || o.values != values;
}

// ── EditorialDivider ───────────────────────────────────────────────────────────
/// 0.5px 高档分隔线，带可配置的上下留白。替代普通 Divider 用于杂志分区分隔。
class EditorialDivider extends StatelessWidget {
  const EditorialDivider({
    super.key,
    this.topPad = 40.0,
    this.bottomPad = 40.0,
  });

  final double topPad;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPad, bottom: bottomPad),
      child: Container(
        height: 0.5,
        color: MirrorColors.divider,
      ),
    );
  }
}

// ── StaggerList ────────────────────────────────────────────────────────────────
/// 为列表项提供错位入场的工具函数。在 SliverChildBuilderDelegate 中调用。
/// [index] 为列表索引，超过 5 后 stagger 不再增加（避免长列表等待过久）。
Widget staggeredItem({required Widget child, required int index}) {
  return child
      .animate(
        delay: Duration(milliseconds: min(index, 5) * MirrorDuration.stagger.inMilliseconds),
      )
      .fadeIn(duration: MirrorDuration.slow, curve: MirrorCurve.enter)
      .slideY(begin: 0.04, end: 0, duration: MirrorDuration.slow, curve: MirrorCurve.enter);
}
