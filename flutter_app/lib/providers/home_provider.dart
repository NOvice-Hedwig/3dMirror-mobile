// lib/providers/home_provider.dart
// HomeScreen 数据聚合 — 全部派生自已有的 sessionsProvider
// 不访问新 API，不新建 DB 表
//
// Read sessions with valueOrNull, never .value: on AsyncError, .value rethrows, which
// made every widget watching these providers throw during build (red error screen).
// Load errors are shown by HomeScreen from sessionsProvider directly.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'session_provider.dart';

// ── helpers ───────────────────────────────────────────────────────────────────

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

DateTime _dateOf(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

// ── 最新一条 SessionRecord（Unity AvatarParams 来源）────────────────────────────
// sessionsProvider 已按 created_at DESC 排序，first = 最新

final latestSessionProvider = Provider<SessionRecord?>((ref) {
  final sessions = ref.watch(sessionsProvider).valueOrNull;
  if (sessions == null || sessions.isEmpty) return null;
  return sessions.first;
});

// ── 最近 7 天各日期 → 当日运动分钟数合计 ─────────────────────────────────────────

final weekWorkoutMinutesProvider = Provider<Map<DateTime, int>>((ref) {
  final sessions = ref.watch(sessionsProvider).valueOrNull ?? [];
  final cutoff = _today().subtract(const Duration(days: 6));

  final Map<DateTime, int> map = {};
  for (final s in sessions) {
    final day = _dateOf(s.createdAt);
    if (!day.isBefore(cutoff)) {
      map[day] = (map[day] ?? 0) + (s.activityData?.durationMin ?? 0);
    }
  }
  return map;
});

// ── 连续打卡天数（从今天往前逐日检查，有 session 的天计入）───────────────────────
// 使用 sessionsProvider 中最多 30 条数据，约覆盖 30 天，满足常见场景

final streakProvider = Provider<int>((ref) {
  final sessions = ref.watch(sessionsProvider).valueOrNull ?? [];
  if (sessions.isEmpty) return 0;

  final days = sessions
      .map((s) => _dateOf(s.createdAt))
      .toSet()
      .toList()
    ..sort();

  int streak = 0;
  DateTime checking = _today();

  for (int i = days.length - 1; i >= 0; i--) {
    if (days[i] == checking) {
      streak++;
      checking = checking.subtract(const Duration(days: 1));
    } else if (days[i].isBefore(checking)) {
      break; // 断链即终止
    }
  }
  return streak;
});

// ── 今日运动分钟数合计 ────────────────────────────────────────────────────────

final todayWorkoutMinProvider = Provider<int>((ref) {
  final sessions = ref.watch(sessionsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return sessions
      .where((s) =>
          s.createdAt.year == now.year &&
          s.createdAt.month == now.month &&
          s.createdAt.day == now.day)
      .fold<int>(0, (acc, s) => acc + (s.activityData?.durationMin ?? 0));
});
