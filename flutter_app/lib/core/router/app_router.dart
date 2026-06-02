import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/auth_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/photo_capture_screen.dart';
import '../../features/input/input_screen.dart';
import '../../features/result/result_screen.dart';
import '../../features/history/history_screen.dart';
import '../theme/design_tokens.dart';
import '../widgets/root_shell.dart';

class MirrorRoute {
  static const String auth         = '/auth';
  static const String onboarding   = '/onboarding';
  static const String photoCapture = '/photo-capture';
  static const String home         = '/';
  static const String input        = '/input';
  static const String result       = '/result';
  static const String history      = '/history';
}

final GoRouter appRouter = GoRouter(
  initialLocation: MirrorRoute.auth,
  redirect: (context, state) async {
    final prefs          = await SharedPreferences.getInstance();
    final token          = prefs.getString('mirror_token');
    final onboarded      = prefs.getBool('mirror_onboarded')      ?? false;
    final photoCaptured  = prefs.getBool('mirror_photo_captured') ?? false;

    final path           = state.fullPath ?? '';
    final isAuth         = path == MirrorRoute.auth;
    final isOnboarding   = path == MirrorRoute.onboarding;
    final isPhotoCapture = path == MirrorRoute.photoCapture;

    // 1. 未登录：只能留在 auth
    if (token == null) {
      return isAuth ? null : MirrorRoute.auth;
    }

    // 2. 已登录但未完成 onboarding
    if (!onboarded) {
      return isOnboarding ? null : MirrorRoute.onboarding;
    }

    // 3. 完成 onboarding 但未拍照：引导到拍照页
    if (!photoCaptured) {
      return isPhotoCapture ? null : MirrorRoute.photoCapture;
    }

    // 4. 全部完成：不该再去 auth / onboarding / photo-capture
    if (isAuth || isOnboarding || isPhotoCapture) {
      return MirrorRoute.home;
    }

    // 5. 其他正常放行
    return null;
  },

  routes: [
    GoRoute(
      path:
     MirrorRoute.auth,
      pageBuilder: (c, s) => _fade(s, const AuthScreen()),
    ),
    GoRoute(
      path: MirrorRoute.onboarding,
      pageBuilder: (c, s) => _fade(s, const OnboardingScreen()),
    ),
    GoRoute(
      path: MirrorRoute.photoCapture,
      pageBuilder: (c, s) => _fade(s, const PhotoCaptureScreen()),
    ),
    ShellRoute(
      builder: (c, s, child) => RootShell(child: child),
      routes: [
        GoRoute(
          path: MirrorRoute.home,
          pageBuilder: (c, s) => _fade(s, const HistoryScreen()),
        ),
        GoRoute(
          path: MirrorRoute.input,
          pageBuilder: (c, s) => _fade(s, const InputScreen()),
        ),
        GoRoute(
          path: MirrorRoute.result,
          // Result 用电影感 reveal，其他用 fade
          pageBuilder: (c, s) => _revealUp(s,
            ResultScreen(sessionId: s.uri.queryParameters['id'] ?? '')),
        ),
        GoRoute(
          path: MirrorRoute.history,
          pageBuilder: (c, s) => _fade(s, const HistoryScreen()),
        ),
      ],
    ),
  ],
);

/// 常规页面过渡：fade，280ms
CustomTransitionPage<void> _fade(GoRouterState s, Widget child) =>
    CustomTransitionPage(
      key: s.pageKey, child: child,
      transitionDuration: MirrorDuration.normal,
      transitionsBuilder: (_, a, __, c) {
        final curve = CurvedAnimation(parent: a, curve: MirrorCurve.enter);
        return FadeTransition(opacity: curve, child: c);
      },
    );

/// Result 页专属：电影感向上揭幕，500ms 入场 / 350ms 退出
CustomTransitionPage<void> _revealUp(GoRouterState s, Widget child) =>
    CustomTransitionPage(
      key: s.pageKey, child: child,
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, a, __, c) {
        final curve = CurvedAnimation(parent: a, curve: MirrorCurve.pageSlide);
        return FadeTransition(
          opacity: Tween(begin: 0.0, end: 1.0).animate(curve),
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curve),
            child: c,
          ),
        );
      },
    );
