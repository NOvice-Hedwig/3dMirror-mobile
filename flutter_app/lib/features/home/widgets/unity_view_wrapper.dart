// lib/features/home/widgets/unity_view_wrapper.dart
// Unity Bridge 视口封装 — MVP 阶段使用 CustomPaint 金色人形轮廓占位
// Unity Platform View 接入后，将 _GoldBodyPainter 替换为真实 UnityWidget()
//
// 数据流：sessionsProvider → latest SessionRecord → UnityBridge.applyBodyParams()

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/avatar_view_mode.dart';
import '../../../models/models.dart';
import '../../../providers/coach_provider.dart';
import '../../../providers/home_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../services/unity_bridge/unity_bridge.dart';
import '../home_design.dart';

class UnityViewWrapper extends ConsumerStatefulWidget {
  const UnityViewWrapper({
    super.key,
    required this.rotationY,
    required this.viewMode,
  });

  /// Y 轴旋转弧度，由 HomeScreen 的 onPanUpdate 驱动
  final double rotationY;
  final AvatarViewMode viewMode;

  @override
  ConsumerState<UnityViewWrapper> createState() => _UnityViewWrapperState();
}

class _UnityViewWrapperState extends ConsumerState<UnityViewWrapper> {
  bool _unityReady = false;

  @override
  void initState() {
    super.initState();
    // 延迟到首帧后执行，此时 sessionsProvider 可能已有缓存数据
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryInitUnity());
  }

  Future<void> _tryInitUnity() async {
    final session = ref.read(latestSessionProvider);
    if (session != null) await _initUnity(session);
  }

  Future<void> _initUnity(SessionRecord session) async {
    if (_unityReady || !mounted) return;
    try {
      await UnityBridge.instance
          .loadAvatar('${session.avatarParams.gender}_base');
      await UnityBridge.instance.applyBodyParams(
        session.avatarParams,
        durationMs: 800,
      );
      if (mounted) setState(() => _unityReady = true);
      // 初始化完成后，若已处于 target 模式，立即切换
      if (widget.viewMode == AvatarViewMode.target) {
        final target = ref.read(targetParamsNotifierProvider);
        if (target != null) await _applyTarget(target);
      }
    } catch (_) {
      // Unity 未运行（模拟器 / CI / 首次启动）→ 静默失败，
      // Flutter CustomPaint 占位持续显示
    }
  }

  @override
  void didUpdateWidget(UnityViewWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewMode != widget.viewMode && _unityReady) {
      _onViewModeChanged(widget.viewMode);
    }
  }

  Future<void> _onViewModeChanged(AvatarViewMode mode) async {
    switch (mode) {
      case AvatarViewMode.current:
        final session = ref.read(latestSessionProvider);
        if (session == null) return;
        try {
          await UnityBridge.instance
              .applyBodyParams(session.avatarParams, durationMs: 600);
        } catch (_) {}
      case AvatarViewMode.target:
        final target = ref.read(targetParamsNotifierProvider);
        if (target == null) return;
        await _applyTarget(target);
    }
  }

  Future<void> _applyTarget(AvatarParams target) async {
    try {
      await UnityBridge.instance.applyBodyParams(target, durationMs: 800);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // 当 sessionsProvider 数据到达时补初始化（首帧若 provider 尚未就绪）
    ref.listen<AsyncValue<List<SessionRecord>>>(sessionsProvider, (_, next) {
      if (next.hasValue && !_unityReady) {
        final session = next.value?.firstOrNull;
        if (session != null) _initUnity(session);
      }
    });

    ref.listen<AvatarParams?>(targetParamsNotifierProvider, (_, next) {
      if (!_unityReady || next == null) return;
      if (widget.viewMode == AvatarViewMode.target) _applyTarget(next);
    });

    return SizedBox.expand(
      child: Container(
        color: kHomeBg,
        child: Stack(
          children: [
            // 地面径向金色光晕（模拟 3D 场景地面反光）
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 220,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.bottomCenter,
                    radius: 0.85,
                    colors: [kGoldDim, Colors.transparent],
                  ),
                ),
              ),
            ),

            // 顶部暗角渐变
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kHomeBg,
                      kHomeBg.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),

            // 人形金色轮廓（MVP 占位，随 rotationY 做 Y 轴透视变换）
            Center(
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)        // 透视系数
                  ..rotateY(widget.rotationY),
                alignment: Alignment.center,
                child: CustomPaint(
                  painter: _GoldBodyPainter(),
                  size: const Size(110, 280),
                ),
              ),
            ),

            // 开发期 Unity 就绪标记（上线前删除）
            if (_unityReady)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: kGoldGhost,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'UNITY ✓',
                    style: kBarlow(
                        size: 8, color: kGold, letterSpacing: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 金色发光人形轮廓 ──────────────────────────────────────────────────────────────
// 三层绘制：散光（高斯模糊）→ 实心金色 → 边缘高光细线
// AvatarParams 的 waist/hip/shoulder norm 会在 Unity 接入后通过
// applyBodyParams() 真正驱动 glTF morph targets；MVP 阶段此 Painter 不响应形变

class _GoldBodyPainter extends CustomPainter {
  static const _glow   = Color(0x55D4A843);
  static const _solid  = Color(0xFFD4A843);
  static const _hilight = Color(0xFFFFECB3);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // 散光层（高斯模糊，模拟金属材质环境光）
    _drawBody(canvas, cx, Paint()
      ..color = _glow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
      ..style = PaintingStyle.fill);

    // 实心填充层
    _drawBody(canvas, cx, Paint()
      ..color = _solid
      ..style = PaintingStyle.fill);

    // 边缘高光细线（增加金属感）
    _drawBody(canvas, cx, Paint()
      ..color = _hilight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2));
  }

  void _drawBody(Canvas canvas, double cx, Paint paint) {
    // 头部
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, 18), width: 28, height: 30),
        paint);

    // 颈部
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - 6, 32, 12, 10), const Radius.circular(4)),
        paint);

    // 躯干（使用 quadraticBezierTo 模拟腰线弧度）
    final torso = Path()
      ..moveTo(cx - 24, 42)
      ..quadraticBezierTo(cx - 20, 64, cx - 16, 100)
      ..lineTo(cx + 16, 100)
      ..quadraticBezierTo(cx + 20, 64, cx + 24, 42)
      ..close();
    canvas.drawPath(torso, paint);

    // 左臂
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - 37, 42, 13, 52), const Radius.circular(7)),
        paint);

    // 右臂
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + 24, 42, 13, 52), const Radius.circular(7)),
        paint);

    // 左腿
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - 22, 100, 16, 76), const Radius.circular(8)),
        paint);

    // 右腿
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + 6, 100, 16, 76), const Radius.circular(8)),
        paint);

    // 左脚
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - 24, 174, 22, 10), const Radius.circular(5)),
        paint);

    // 右脚
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + 4, 174, 22, 10), const Radius.circular(5)),
        paint);
  }

  // Painter 本身无状态，Transform 层会在 rotationY 变化时触发外层 rebuild
  @override
  bool shouldRepaint(_GoldBodyPainter old) => false;
}
