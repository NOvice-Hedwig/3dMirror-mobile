// lib/features/home/home_screen.dart
// 3D Mirror 主场景页 — MVP
// 路由 '/' ，继承自 ShellRoute（RootShell 渲染底部 Tab 栏）
//
// Stack 三层（从底到顶）：
//   1. UnityViewWrapper — 全屏 3D 视口，手势绑定在此层
//   2. MirrorHUD       — IgnorePointer 包裹，不拦截任何触摸
//   3. HomeFABButton   — Positioned，独立接收 Tap

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/avatar_view_mode.dart';
import '../../core/router/app_router.dart';
import '../../providers/coach_provider.dart';
import 'home_design.dart';
import 'widgets/fab_button.dart';
import 'widgets/mirror_hud.dart';
import 'widgets/unity_view_wrapper.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  double _rotationY = 0;
  AvatarViewMode _viewMode = AvatarViewMode.current;

  void _toggleViewMode() => setState(() {
    _viewMode = _viewMode == AvatarViewMode.current
        ? AvatarViewMode.target
        : AvatarViewMode.current;
  });

  // 单指拖动 → 旋转模型（Y 轴，灵敏度 0.005 rad/px）
  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _rotationY += d.delta.dx * 0.005);
  }

  // 拖动结束 → 速度超阈值触发页面导航
  void _onPanEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond;

    if (v.dy < -800) {
      // 上滑 → Predict 视图
      context.push(MirrorRoute.predict);
      return;
    }
    if (v.dy > 800) {
      // 下滑 → 历史对比
      context.push(MirrorRoute.history);
      return;
    }
    if (v.dx < -800) {
      // 左滑 → 重新拍照 / 更新目标体型
      context.push(MirrorRoute.photoCapture);
      return;
    }
    if (v.dx > 800) {
      // 右滑 → Snapshots 快照页
      context.push(MirrorRoute.snapshots);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      // extendBody 让视口内容延伸到 RootShell 的 BottomNav 下方，产生沉浸感
      extendBody: true,
      body: SafeArea(
        bottom: false, // 底部留给 BottomNav 自行处理 SafeArea
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Layer 1: Unity 视口（手势附着）────────────────────────────────
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: UnityViewWrapper(
                rotationY: _rotationY,
                viewMode:  _viewMode,
              ),
            ),

            // ── Layer 2: HUD 浮层（非交互部分内部 IgnorePointer，Toggle 可交互）──
            MirrorHUD(
              viewMode:         _viewMode,
              onToggleViewMode: _toggleViewMode,
              hasTarget: ref.watch(targetParamsNotifierProvider) != null,
            ),

            // ── Layer 3: 悬浮 + 按钮（可交互，脱离手势竞争区域）─────────────────
            const Positioned(
              bottom: 88,
              right: 115,
              child: HomeFABButton(),
            ),
          ],
        ),
      ),
    );
  }
}
