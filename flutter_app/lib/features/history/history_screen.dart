import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/animate_widgets.dart';
import '../../models/models.dart';
import '../../services/api/session_api.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SessionRecord> _sessions = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final s = await SessionApi.instance.list();
      setState(() { _sessions = s; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MirrorColors.bg,
    bottomNavigationBar: _sessions.isNotEmpty ? Container(
      padding: const EdgeInsets.fromLTRB(
          MirrorSpacing.pagePad, 12, MirrorSpacing.pagePad, 28),
      color: MirrorColors.bg,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(height: 0.5, color: MirrorColors.divider),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => context.go(MirrorRoute.input),
          child: Text('TODAY  ·  RECORD',
              style: MirrorText.overline.copyWith(
                  color: MirrorColors.bg, letterSpacing: 2.5)),
        ),
      ]),
    ) : null,
    body: SafeArea(
      child: Column(
        children: [
          _buildMasthead(),
          Expanded(
            child: CustomScrollView(slivers: [

      // ── Header（入场错位） ────────────────────────────────────────────────────
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
            MirrorSpacing.pagePad, 40, MirrorSpacing.pagePad, 0),
        sliver: SliverToBoxAdapter(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeSlideIn(
              delay: Duration.zero,
              duration: const Duration(milliseconds: 400),
              offsetY: 10,
              child: Text('TRANSFORMATION',
                  style: MirrorText.overline),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              duration: MirrorDuration.slow,
              offsetY: 16,
              child: Text.rich(TextSpan(style: MirrorText.titleSm, children: [
                const TextSpan(text: '每一次\n'),
                TextSpan(text: '记录',
                    style: MirrorText.titleSm.copyWith(fontStyle: FontStyle.italic)),
              ])),
            ),
            const SizedBox(height: 24),
          ],
        )),
      ),

      if (_loading)
        const SliverFillRemaining(child: Center(
          child: CircularProgressIndicator(
              color: MirrorColors.text1, strokeWidth: 1)))
      else if (_error != null)
        SliverFillRemaining(child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('加载失败', style: MirrorText.body),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
              child: const Text('重试'),
            ),
          ]),
        ))
      else if (_sessions.isEmpty)
        SliverFillRemaining(child: Center(child: Column(
          mainAxisSize: MainAxisSize.min, children: [
            Text('还没有记录', style: MirrorText.body.copyWith(color: MirrorColors.text2)),
            const SizedBox(height: 6),
            Text('完成第一次输入开始追踪', style: MirrorText.caption),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(MirrorRoute.input),
              child: const Text('开始记录'),
            ),
          ],
        )))
      else ...[

        // ── Sparkline（绘制动画） ───────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: MirrorSpacing.pagePad),
          sliver: SliverToBoxAdapter(
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              duration: const Duration(milliseconds: 500),
              offsetY: 8,
              child: AnimatedSparkline(
                values: _sessions.map((s) => s.bodyData.weightKg)
                    .toList().reversed.toList(),
                drawDuration: MirrorDuration.reveal,
                delay: const Duration(milliseconds: 300),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Section label
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              MirrorSpacing.pagePad, 24, MirrorSpacing.pagePad, 6),
          sliver: SliverToBoxAdapter(
            child: Text('RECORDS', style: MirrorText.overline),
          ),
        ),

        // ── Session list（错位入场） ────────────────────────────────────────────
        SliverList(delegate: SliverChildBuilderDelegate(
          (ctx, i) => staggeredItem(
            index: i,
            child: _SessionRow(
              session: _sessions[i],
              prevWeight: i + 1 < _sessions.length
                  ? _sessions[i + 1].bodyData.weightKg : null,
              onTap: () => context.push(
                  '${MirrorRoute.result}?id=${_sessions[i].id}'),
            ),
          ),
          childCount: _sessions.length,
        )),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
            ]),
          ),
        ],
      ),
    ),
  );

  Widget _buildMasthead() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            MirrorSpacing.pagePad, 20, MirrorSpacing.pagePad, 12),
        child: Text(
          '3D MIRROR',
          style: MirrorText.overline.copyWith(
            color: MirrorColors.gold,
            fontSize: 11,
            letterSpacing: 4.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      Container(
        height: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: MirrorSpacing.pagePad),
        color: MirrorColors.divider,
      )
      .animate()
      .scale(
        begin: const Offset(0, 1),
        end: const Offset(1, 1),
        alignment: Alignment.centerLeft,
        duration: 600.ms,
        curve: MirrorCurve.enter,
      ),
      const SizedBox(height: 4),
    ],
  );
}

// ── Session row ────────────────────────────────────────────────────────────────

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.session, required this.prevWeight, required this.onTap});
  final SessionRecord session;
  final double?       prevWeight;
  final VoidCallback  onTap;

  @override
  Widget build(BuildContext context) {
    final bd    = session.bodyData;
    final delta = prevWeight != null ? bd.weightKg - prevWeight! : null;
    final d     = session.createdAt;
    const monthNames = ['', 'JAN','FEB','MAR','APR','MAY','JUN',
        'JUL','AUG','SEP','OCT','NOV','DEC'];

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MirrorSpacing.pagePad),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(children: [
              // Date — 用 displayMd 风格提升分量感
              SizedBox(width: 44, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${d.day}',
                      style: MirrorText.displayMd.copyWith(
                          fontSize: 22, letterSpacing: -0.8)),
                  Text(monthNames[d.month], style: MirrorText.overline),
                ],
              )),
              // 细分隔线
              Container(width: 0.5, height: 40, color: MirrorColors.divider,
                  margin: const EdgeInsets.symmetric(horizontal: 16)),
              // Weight + activity
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(bd.weightKg.toStringAsFixed(1),
                            style: MirrorText.displayMd),
                        const SizedBox(width: 3),
                        Text('kg', style: MirrorText.unit),
                      ]),
                  if (session.activityData != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      _workoutLabel(session.activityData!.workoutType) +
                          (session.activityData!.durationMin != null
                              ? '  ·  ${session.activityData!.durationMin} min' : ''),
                      style: MirrorText.caption,
                    ),
                  ],
                ],
              )),
              // Delta
              if (delta != null) Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                    style: MirrorText.displayMd.copyWith(
                        fontSize: 16,
                        color: delta < 0 ? MirrorColors.text1 : MirrorColors.text3),
                  ),
                  const SizedBox(height: 2),
                  Text('vs prev', style: MirrorText.caption),
                ],
              ),
            ]),
          ),
          const Divider(color: MirrorColors.divider, thickness: 0.5, height: 0),
        ]),
      ),
    );
  }

  String _workoutLabel(WorkoutType t) => {
    WorkoutType.strength: '力量', WorkoutType.cardio: '有氧',
    WorkoutType.hiit: 'HIIT',   WorkoutType.walk: '步行',
    WorkoutType.yoga: '瑜伽',   WorkoutType.swim: '游泳',
    WorkoutType.cycling: '骑行', WorkoutType.rest: '休息日',
    WorkoutType.other: '其他',
  }[t] ?? '其他';
}
