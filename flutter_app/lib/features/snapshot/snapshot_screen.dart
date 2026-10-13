import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/animate_widgets.dart';
import '../../core/widgets/delta_text.dart';
import '../../models/models.dart';
import '../../services/api/session_api.dart';

class SnapshotScreen extends ConsumerStatefulWidget {
  const SnapshotScreen({super.key});

  @override
  ConsumerState<SnapshotScreen> createState() => _SnapshotScreenState();
}

class _SnapshotScreenState extends ConsumerState<SnapshotScreen> {
  List<SessionRecord> _sessions = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await SessionApi.instance.list(limit: 50);
      if (mounted) setState(() { _sessions = s; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MirrorColors.bg,
    body: SafeArea(
      child: Column(children: [
        _buildMasthead(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
                  color: MirrorColors.text1, strokeWidth: 1))
              : _error != null
                  ? _buildError()
                  : _buildContent(),
        ),
      ]),
    ),
  );

  // ── Masthead ────────────────────────────────────────────────────────────────

  Widget _buildMasthead() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            MirrorSpacing.pagePad, 20, MirrorSpacing.pagePad, 12),
        child: Text(
          'SNAPSHOTS',
          style: MirrorText.overline.copyWith(
              color: MirrorColors.gold, fontSize: 11, letterSpacing: 4.0),
          textAlign: TextAlign.center,
        ),
      ),
      Container(
        height: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: MirrorSpacing.pagePad),
        color: MirrorColors.divider,
      ),
      const SizedBox(height: 4),
    ],
  );

  // ── Error ───────────────────────────────────────────────────────────────────

  Widget _buildError() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('加载失败', style: MirrorText.body),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: () {
          setState(() { _loading = true; _error = null; });
          _load();
        },
        child: const Text('重试'),
      ),
    ]),
  );

  // ── Content ─────────────────────────────────────────────────────────────────

  Widget _buildContent() => CustomScrollView(slivers: [

    // ── 导航栏 ───────────────────────────────────────────────────────────────
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          MirrorSpacing.pagePad, 20, MirrorSpacing.pagePad, 0),
      sliver: SliverToBoxAdapter(
        child: FadeSlideIn(
          duration: const Duration(milliseconds: 450),
          offsetY: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                behavior: HitTestBehavior.opaque,
                child: Row(children: [
                  const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 13, color: MirrorColors.text3),
                  const SizedBox(width: 4),
                  Text('返回', style: MirrorText.bodyS),
                ]),
              ),
              Text('${_sessions.length} RECORDS',
                  style: MirrorText.overline),
            ],
          ),
        ),
      ),
    ),

    // ── Sparkline 趋势图 ──────────────────────────────────────────────────────
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          MirrorSpacing.pagePad, 28, MirrorSpacing.pagePad, 0),
      sliver: SliverToBoxAdapter(
        child: FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          duration: const Duration(milliseconds: 500),
          offsetY: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WEIGHT  ·  TREND', style: MirrorText.overline),
              const SizedBox(height: 16),
              AnimatedSparkline(
                values: _sessions
                    .map((s) => s.bodyData.weightKg)
                    .toList()
                    .reversed
                    .toList(),
                drawDuration: MirrorDuration.reveal,
                delay: const Duration(milliseconds: 300),
              ),
              const SizedBox(height: 8),
              if (_sessions.length >= 2)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDate(_sessions.last.createdAt),
                        style: MirrorText.caption),
                    Text(_formatDate(_sessions.first.createdAt),
                        style: MirrorText.caption),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),

    // ── 统计摘要 ──────────────────────────────────────────────────────────────
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          MirrorSpacing.pagePad, 24, MirrorSpacing.pagePad, 0),
      sliver: SliverToBoxAdapter(
        child: FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          duration: const Duration(milliseconds: 400),
          offsetY: 0,
          child: _buildSummaryRow(),
        ),
      ),
    ),

    // ── 分隔线 ────────────────────────────────────────────────────────────────
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: MirrorSpacing.pagePad),
      sliver: const SliverToBoxAdapter(
        child: EditorialDivider(topPad: 24, bottomPad: 0),
      ),
    ),

    // ── 快照卡片列表 ──────────────────────────────────────────────────────────
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          MirrorSpacing.pagePad, 24, MirrorSpacing.pagePad, 56),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final animDuration = Duration(
                milliseconds: i < 10 ? 350 : 0);
            return FadeSlideIn(
              delay: Duration(milliseconds: 200 + i * 40),
              duration: animDuration,
              offsetY: 8,
              child: _SnapshotCard(
                session:  _sessions[i],
                isLatest: i == 0,
                onTap: () => context.push(
                    '${MirrorRoute.result}?id=${_sessions[i].id}'),
              ),
            );
          },
          childCount: _sessions.length,
        ),
      ),
    ),
  ]);

  // ── 统计摘要行 ───────────────────────────────────────────────────────────────

  Widget _buildSummaryRow() {
    if (_sessions.isEmpty) return const SizedBox.shrink();

    final first       = _sessions.last;
    final last        = _sessions.first;
    final weightDelta = last.bodyData.weightKg - first.bodyData.weightKg;
    final daySpan     = last.createdAt.difference(first.createdAt).inDays;

    return IntrinsicHeight(
      child: Row(children: [
        // 记录次数
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('记录次数', style: MirrorText.overline),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CountUpText(
                    value: _sessions.length.toDouble(),
                    style: MirrorText.displayMd,
                    fractionDigits: 0,
                    duration: MirrorDuration.xslow,
                  ),
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('次', style: MirrorText.unit),
                  ),
                ],
              ),
            ],
          ),
        ),

        Container(
          width: 0.5,
          color: MirrorColors.divider,
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),

        // 体重变化
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('体重变化', style: MirrorText.overline),
              const SizedBox(height: 8),
              DeltaText(delta: weightDelta, unit: 'kg'),
            ],
          ),
        ),

        Container(
          width: 0.5,
          color: MirrorColors.divider,
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),

        // 坚持天数
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('坚持天数', style: MirrorText.overline),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CountUpText(
                    value: daySpan.toDouble(),
                    style: MirrorText.displayMd,
                    fractionDigits: 0,
                    duration: MirrorDuration.xslow,
                  ),
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('天', style: MirrorText.unit),
                  ),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── 日期格式化 ─────────────────────────────────────────────────────────────────

String _formatDate(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

// ── Snapshot Card ─────────────────────────────────────────────────────────────

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({
    required this.session,
    required this.isLatest,
    required this.onTap,
  });

  final SessionRecord session;
  final bool          isLatest;
  final VoidCallback  onTap;

  String _workoutLabel(WorkoutType t) => {
    WorkoutType.strength: '力量', WorkoutType.cardio: '有氧',
    WorkoutType.hiit:     'HIIT', WorkoutType.walk:   '步行',
    WorkoutType.yoga:     '瑜伽', WorkoutType.swim:   '游泳',
    WorkoutType.cycling:  '骑行', WorkoutType.rest:   '休息日',
    WorkoutType.other:    '其他',
  }[t] ?? '其他';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isLatest ? MirrorColors.text3 : MirrorColors.divider,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(MirrorRadius.sm),
        ),
        child: Row(children: [

          // 左侧：日期 + 标签
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(session.createdAt),
                    style: MirrorText.overline),
                const SizedBox(height: 6),
                if (isLatest)
                  Text('LATEST',
                      style: MirrorText.caption.copyWith(
                          color: MirrorColors.text2)),
                if (session.activityData != null)
                  Text(
                    _workoutLabel(session.activityData!.workoutType),
                    style: MirrorText.caption,
                  ),
              ],
            ),
          ),

          // 右侧：体重 + 体脂率
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    session.bodyData.weightKg.toStringAsFixed(1),
                    style: MirrorText.displayMd,
                  ),
                  const SizedBox(width: 3),
                  Text('kg', style: MirrorText.unit),
                ],
              ),
              if (session.bodyData.bodyFatPct != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${session.bodyData.bodyFatPct!.toStringAsFixed(1)}%',
                  style: MirrorText.caption,
                ),
              ],
            ],
          ),

          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 12, color: MirrorColors.text3),
        ]),
      ),
    );
  }
}
