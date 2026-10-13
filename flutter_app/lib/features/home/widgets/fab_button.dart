import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home_design.dart';
import 'log_sheets/workout_log_sheet.dart';
import 'log_sheets/diet_log_sheet.dart';
import 'log_sheets/sleep_log_sheet.dart';
import 'log_sheets/health_log_sheet.dart';
import 'log_sheets/supplement_log_sheet.dart';

// ── 子按钮数据 ─────────────────────────────────────────────────────────────────
class _FabItem {
  final String emoji;
  final String label;
  final String sheet; // batch-2: matched in _openSheet()
  const _FabItem(this.emoji, this.label, this.sheet);
}

const _kItems = [
  _FabItem('🏃', '运动', 'workout'),
  _FabItem('🥗', '饮食', 'diet'),
  _FabItem('🌙', '睡眠', 'sleep'),
  _FabItem('❤️',  '健康', 'health'),
  _FabItem('💊', '补剂', 'supplement'),
];

// ── 扇形角度（顺时针，以12点方向为0°，负数 = 向左）─────────────────────────────
// -90°=纯左, -60°/−30°=左上, 0°=正上, +30°=右上
// 屏幕右边缘 clamp 由 _FanOverlay 处理。
const _kAngles = [-72.0, -36.0, 0.0, 36.0, 72.0];
const _kRadius = 110.0;

// ─────────────────────────────────────────────────────────────────────────────
class HomeFABButton extends StatefulWidget {
  const HomeFABButton({super.key});

  @override
  State<HomeFABButton> createState() => _HomeFABButtonState();
}

class _HomeFABButtonState extends State<HomeFABButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _removeEntry();
    _ctrl.dispose();
    super.dispose();
  }

  // ── 开 / 关 ──────────────────────────────────────────────────────────────────
  void _toggle() => _entry == null ? _open() : _close();

  void _open() {
    final box    = context.findRenderObject() as RenderBox;
    final center = box.localToGlobal(box.size.center(Offset.zero));

    _entry = OverlayEntry(
      builder: (_) => _FanOverlay(
        controller:  _ctrl,
        fabCenter:   center,
        onCollapse:  _close,
        onItemTap:   _onItemTap,
      ),
    );
    Overlay.of(context).insert(_entry!);
    _ctrl.forward();
  }

  void _close() {
    _ctrl.reverse().then((_) {
      if (mounted) _removeEntry();
    });
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  // ── 子按钮点击 ────────────────────────────────────────────────────────────────
  void _onItemTap(int index) {
    _close();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _sheetForType(_kItems[index].sheet),
        ),
      );
    });
  }

  Widget _sheetForType(String sheet) => switch (sheet) {
    'workout'    => const WorkoutLogSheet(),
    'diet'       => const DietLogSheet(),
    'sleep'      => const SleepLogSheet(),
    'health'     => const HealthLogSheet(),
    'supplement' => const SupplementLogSheet(),
    _            => const SizedBox.shrink(),
  };

  // ── 渲染：金色圆形 + "+" 旋转 45°→变成 "×" ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: kGold,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: kGoldDim, blurRadius: 16, spreadRadius: 2),
            ],
          ),
          child: Center(
            child: Transform.rotate(
              angle: _ctrl.value * (math.pi / 4), // 0° → 45°
              child: Text(
                '+',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                  color: kHomeBg,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 全屏蒙层 + 扇形子按钮（Overlay 中渲染）────────────────────────────────────
class _FanOverlay extends StatefulWidget {
  const _FanOverlay({
    required this.controller,
    required this.fabCenter,
    required this.onCollapse,
    required this.onItemTap,
  });

  final AnimationController   controller;
  final Offset                fabCenter;
  final VoidCallback          onCollapse;
  final void Function(int)    onItemTap;

  @override
  State<_FanOverlay> createState() => _FanOverlayState();
}

class _FanOverlayState extends State<_FanOverlay> {
  late final List<CurvedAnimation> _itemAnims;

  @override
  void initState() {
    super.initState();
    // 逐级错开：每个按钮延迟 ~25ms，动画时长覆盖控制器 70%
    _itemAnims = List.generate(_kItems.length, (i) {
      final start = i * 0.07;
      final end   = math.min(start + 0.72, 1.0);
      return CurvedAnimation(
        parent: widget.controller,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      );
    });
  }

  @override
  void dispose() {
    for (final a in _itemAnims) {
      a.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) => Stack(
        children: [
          // ── 深色蒙层 ──────────────────────────────────────────────────────────
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onCollapse,
              behavior: HitTestBehavior.opaque,
              child: ColoredBox(
                color: Color.fromRGBO(
                  12, 10, 6, 0.85 * widget.controller.value),
              ),
            ),
          ),

          // ── 5 个扇形按钮 ──────────────────────────────────────────────────────
          ...List.generate(_kItems.length, (i) {
            final rad = _kAngles[i] * math.pi / 180;
            final dx  = math.sin(rad) * _kRadius;
            final dy  = -math.cos(rad) * _kRadius;

            // 防止按钮溢出屏幕左右边缘（8px 安全边距）
            final rawLeft = widget.fabCenter.dx + dx - 24;
            final left    = rawLeft.clamp(8.0, screenW - 56.0);

            return Positioned(
              left: left,
              top:  widget.fabCenter.dy + dy - 24,
              child: FadeTransition(
                opacity: _itemAnims[i],
                child: ScaleTransition(
                  scale: _itemAnims[i],
                  child: _FanButton(
                    emoji: _kItems[i].emoji,
                    label: _kItems[i].label,
                    onTap: () => widget.onItemTap(i),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── 单个扇形子按钮 ─────────────────────────────────────────────────────────────
class _FanButton extends StatelessWidget {
  const _FanButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String       emoji;
  final String       label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kGoldGhost,
              shape: BoxShape.circle,
              border: Border.all(color: kBorderColor, width: 0.5),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: kBarlow(size: 9, color: kTextDim)),
        ],
      ),
    );
  }
}
