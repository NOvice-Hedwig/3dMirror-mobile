import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/animate_widgets.dart';
import '../../models/models.dart';
import '../../models/predict_models.dart';
import '../../providers/predict_provider.dart';
import '../../services/api/session_api.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<SessionRecord> _sessions = [];
  bool    _loading = true;
  String? _error;

  bool           _selectMode  = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final s = await SessionApi.instance.list();
      if (mounted) setState(() { _sessions = s; _loading = false; });
    } catch (e) {
      // On 401 the app root has already redirected to login and this screen may be gone.
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else if (_selectedIds.length < 2) {
        _selectedIds.add(id);
      }
    });
  }

  void _goCompare() {
    final ids = _selectedIds.toList();
    context.push('${MirrorRoute.compare}?a=${ids[0]}&b=${ids[1]}');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MirrorColors.bg,
    bottomNavigationBar: (_sessions.isNotEmpty && !_selectMode)
        ? Container(
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
          )
        : null,
    body: SafeArea(
      child: Column(
        children: [
          _buildMasthead(),
          Expanded(
            child: CustomScrollView(slivers: [

              // ── Header ──────────────────────────────────────────────────────
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
                      child: Text.rich(TextSpan(
                          style: MirrorText.titleSm, children: [
                        const TextSpan(text: '每一次\n'),
                        TextSpan(text: '记录',
                            style: MirrorText.titleSm.copyWith(
                                fontStyle: FontStyle.italic)),
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
                      onPressed: () {
                        setState(() { _loading = true; _error = null; });
                        _load();
                      },
                      child: const Text('重试'),
                    ),
                  ]),
                ))
              else if (_sessions.isEmpty)
                SliverFillRemaining(child: Center(child: Column(
                  mainAxisSize: MainAxisSize.min, children: [
                    Text('还没有记录',
                        style: MirrorText.body.copyWith(
                            color: MirrorColors.text2)),
                    const SizedBox(height: 6),
                    Text('完成第一次输入开始追踪',
                        style: MirrorText.caption),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go(MirrorRoute.input),
                      child: const Text('开始记录'),
                    ),
                  ],
                )))
              else ...[

                // ── Sparkline ────────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: MirrorSpacing.pagePad),
                  sliver: SliverToBoxAdapter(
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 180),
                      duration: const Duration(milliseconds: 500),
                      offsetY: 8,
                      child: AnimatedSparkline(
                        values: _sessions
                            .map((s) => s.bodyData.weightKg)
                            .toList()
                            .reversed
                            .toList(),
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
                      MirrorSpacing.pagePad, 24,
                      MirrorSpacing.pagePad, 6),
                  sliver: SliverToBoxAdapter(
                    child: Text('RECORDS', style: MirrorText.overline),
                  ),
                ),

                // ── Session list ─────────────────────────────────────────────
                SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) => staggeredItem(
                    index: i,
                    child: _SessionRow(
                      session:    _sessions[i],
                      prevWeight: i + 1 < _sessions.length
                          ? _sessions[i + 1].bodyData.weightKg : null,
                      selectMode:  _selectMode,
                      isSelected:  _selectedIds.contains(_sessions[i].id),
                      onLongPress: _selectMode ? null : () => setState(() {
                        _selectMode = true;
                        if (_sessions.length >= 2) {
                          _selectedIds
                            ..add(_sessions.last.id)
                            ..add(_sessions.first.id);
                        }
                      }),
                      onToggleSelect: () => _toggleSelect(_sessions[i].id),
                      onTap: () => context.push(
                          '${MirrorRoute.result}?id=${_sessions[i].id}'),
                    ),
                  ),
                  childCount: _sessions.length,
                )),

                // ── 预测行（仅在选择模式） ─────────────────────────────────────
                if (_selectMode)
                  SliverToBoxAdapter(
                    child: Column(children: [
                      _PredictRow(
                        weeks: 4,
                        isSelected: _selectedIds.contains(kPredictId4),
                        onToggleSelect: () => _toggleSelect(kPredictId4),
                      ),
                      _PredictRow(
                        weeks: 8,
                        isSelected: _selectedIds.contains(kPredictId8),
                        onToggleSelect: () => _toggleSelect(kPredictId8),
                      ),
                      _PredictRow(
                        weeks: 12,
                        isSelected: _selectedIds.contains(kPredictId12),
                        onToggleSelect: () => _toggleSelect(kPredictId12),
                      ),
                    ]),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ]),
          ),

          // ── 底部对比栏 ────────────────────────────────────────────────────
          if (_sessions.isNotEmpty)
            AnimatedContainer(
              duration: MirrorDuration.fast,
              height: 64,
              color: MirrorColors.bg,
              child: _selectMode
                  ? _buildCompareBar()
                  : _buildCompareEntry(),
            ),
        ],
      ),
    ),
  );

  Widget _buildCompareEntry() => Padding(
    padding: const EdgeInsets.symmetric(
        horizontal: MirrorSpacing.pagePad, vertical: 12),
    child: OutlinedButton(
      onPressed: () => setState(() {
        _selectMode = true;
        if (_sessions.length >= 2) {
          _selectedIds
            ..add(_sessions.last.id)
            ..add(_sessions.first.id);
        }
      }),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: MirrorColors.divider, width: 0.5),
        minimumSize: const Size(double.infinity, 40),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MirrorRadius.lg)),
      ),
      child: Text('COMPARE  ·  SELECT',
          style: MirrorText.overline.copyWith(
              color: MirrorColors.text2, letterSpacing: 2.5)),
    ),
  );

  Widget _buildCompareBar() => Padding(
    padding: const EdgeInsets.symmetric(
        horizontal: MirrorSpacing.pagePad, vertical: 8),
    child: Row(children: [
      Text(
        _selectedIds.length == 2 ? '已选 2 项' : '再选 ${2 - _selectedIds.length} 项',
        style: MirrorText.bodyS.copyWith(color: MirrorColors.text3),
      ),
      const Spacer(),
      GestureDetector(
        onTap: () => setState(() {
          _selectMode = false;
          _selectedIds.clear();
        }),
        child: Text('取消',
            style: MirrorText.bodyS.copyWith(color: MirrorColors.text3)),
      ),
      const SizedBox(width: 24),
      AnimatedOpacity(
        opacity: _selectedIds.length == 2 ? 1.0 : 0.3,
        duration: MirrorDuration.fast,
        child: GestureDetector(
          onTap: _selectedIds.length == 2 ? _goCompare : null,
          child: Text('对比',
              style: MirrorText.bodyS.copyWith(
                color: MirrorColors.text1,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: MirrorColors.text1,
              )),
        ),
      ),
    ]),
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
    required this.session,
    required this.prevWeight,
    required this.selectMode,
    required this.isSelected,
    required this.onTap,
    required this.onToggleSelect,
    this.onLongPress,
  });

  final SessionRecord session;
  final double?       prevWeight;
  final bool          selectMode;
  final bool          isSelected;
  final VoidCallback  onTap;
  final VoidCallback  onToggleSelect;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final bd    = session.bodyData;
    final delta = prevWeight != null ? bd.weightKg - prevWeight! : null;
    final d     = session.createdAt;
    const monthNames = ['', 'JAN','FEB','MAR','APR','MAY','JUN',
        'JUL','AUG','SEP','OCT','NOV','DEC'];

    return GestureDetector(
      onTap:      selectMode ? onToggleSelect : onTap,
      onLongPress: onLongPress,
      behavior:   HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: MirrorSpacing.pagePad),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(children: [
              // Date
              SizedBox(width: 44, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${d.day}',
                      style: MirrorText.displayMd.copyWith(
                          fontSize: 22, letterSpacing: -0.8)),
                  Text(monthNames[d.month], style: MirrorText.overline),
                ],
              )),
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
                              ? '  ·  ${session.activityData!.durationMin} min'
                              : ''),
                      style: MirrorText.caption,
                    ),
                  ],
                ],
              )),
              // Delta 或 选中图标
              if (selectMode)
                AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.3,
                  duration: MirrorDuration.fast,
                  child: const Icon(Icons.check_circle_outline_rounded,
                      size: 18, color: MirrorColors.text1),
                )
              else if (delta != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                      style: MirrorText.displayMd.copyWith(
                          fontSize: 16,
                          color: delta < 0
                              ? MirrorColors.text1
                              : MirrorColors.text3),
                    ),
                    const SizedBox(height: 2),
                    Text('vs prev', style: MirrorText.caption),
                  ],
                ),
            ]),
          ),
          const Divider(
              color: MirrorColors.divider, thickness: 0.5, height: 0),
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

// ── 预测行（ConsumerWidget，读取 predictMetricsProvider） ───────────────────────

class _PredictRow extends ConsumerWidget {
  const _PredictRow({
    required this.weeks,
    required this.isSelected,
    required this.onToggleSelect,
  });

  final int          weeks;
  final bool         isSelected;
  final VoidCallback onToggleSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weight = ref
        .watch(predictMetricsProvider(weeks))
        .whenData((m) => m.predictedWeightKg)
        .value;

    return GestureDetector(
      onTap:    onToggleSelect,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: MirrorSpacing.pagePad),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(children: [
              // 预测标签（左侧日期位置）
              SizedBox(width: 44, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('预测',
                      style: MirrorText.overline.copyWith(
                          color: MirrorColors.gold, fontSize: 9)),
                  Text('${weeks}W',
                      style: MirrorText.overline.copyWith(
                          color: MirrorColors.gold)),
                ],
              )),
              Container(width: 0.5, height: 40, color: MirrorColors.divider,
                  margin: const EdgeInsets.symmetric(horizontal: 16)),
              // 预测体重
              Expanded(child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    weight != null
                        ? weight.toStringAsFixed(1) : '—',
                    style: MirrorText.displayMd,
                  ),
                  const SizedBox(width: 3),
                  Text('kg', style: MirrorText.unit),
                ],
              )),
              // 选中图标
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.3,
                duration: MirrorDuration.fast,
                child: const Icon(Icons.check_circle_outline_rounded,
                    size: 18, color: MirrorColors.text1),
              ),
            ]),
          ),
          const Divider(
              color: MirrorColors.divider, thickness: 0.5, height: 0),
        ]),
      ),
    );
  }
}
