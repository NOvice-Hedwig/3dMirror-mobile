import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/widgets/animate_widgets.dart';
import '../../core/widgets/delta_text.dart';
import '../../models/challenge_models.dart';
import '../../providers/challenge_provider.dart';
import '../../services/api/challenge_api.dart';
import '../home/widgets/log_sheets/_sheet_base.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  String _goalType = 'weight';

  final _weightCtrl  = TextEditingController();
  final _bodyFatCtrl = TextEditingController();
  final _waistCtrl   = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _bodyFatCtrl.dispose();
    _waistCtrl.dispose();
    super.dispose();
  }

  Future<void> _startChallenge() async {
    final wt = double.tryParse(_weightCtrl.text.trim());
    final bf = double.tryParse(_bodyFatCtrl.text.trim());
    final wc = double.tryParse(_waistCtrl.text.trim());

    // At least one target value must be filled
    if (_goalType == 'weight'    && wt == null) return;
    if (_goalType == 'body_fat'  && bf == null) return;
    if (_goalType == 'waist'     && wc == null) return;
    if (_goalType == 'composite' && wt == null && bf == null && wc == null) return;

    setState(() => _isSaving = true);
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final goal  = ChallengeGoal(
        goalType:       _goalType,
        targetWeightKg: wt,
        targetBodyFat:  bf,
        targetWaistCm:  wc,
        startDate:      today,
        endDate:        ChallengeGoal.defaultEndDate(today),
      );
      await ChallengeApi.instance.setGoal(goal);
      ref.invalidate(challengeProgressProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('挑战已开始！坚持到月底')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('设定失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _abandonChallenge() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MirrorColors.bg2,
        title:   Text('放弃挑战？', style: MirrorText.body),
        content: Text('本月进度将清空，下月可重新开始。',
            style: MirrorText.bodyS.copyWith(color: MirrorColors.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消',
                style: MirrorText.bodyS.copyWith(color: MirrorColors.text2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('确认放弃',
                style: MirrorText.bodyS.copyWith(color: MirrorColors.text2)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ChallengeApi.instance.abandonGoal();
      ref.invalidate(challengeProgressProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('操作失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MirrorColors.bg,
    body: SafeArea(
      child: Column(children: [
        _buildMasthead(),
        Expanded(
          child: ref.watch(challengeProgressProvider).when(
            loading: () => const Center(child: CircularProgressIndicator(
                color: MirrorColors.text1, strokeWidth: 1)),
            error: (_, __) => _buildSetupView(),
            data: (progress) => progress == null
                ? _buildSetupView()
                : _buildProgressView(progress),
          ),
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
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: MirrorColors.text3),
          ),
          const Expanded(
            child: Text('CHALLENGE',
              style: TextStyle(
                fontFamily: 'Barlow', fontSize: 11,
                fontWeight: FontWeight.w600, letterSpacing: 4.0,
                color: MirrorColors.gold),
              textAlign: TextAlign.center),
          ),
          const SizedBox(width: 16),
        ]),
      ),
      Container(
        height: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: MirrorSpacing.pagePad),
        color: MirrorColors.divider,
      ),
      const SizedBox(height: 4),
    ],
  );

  // ── Setup View ──────────────────────────────────────────────────────────────

  Widget _buildSetupView() => CustomScrollView(slivers: [

    // Description
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          MirrorSpacing.pagePad, 32, MirrorSpacing.pagePad, 0),
      sliver: SliverToBoxAdapter(
        child: FadeSlideIn(
          duration: const Duration(milliseconds: 400),
          offsetY: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MONTHLY  ·  CHALLENGE', style: MirrorText.overline),
              const SizedBox(height: 12),
              Text('设定本月目标，达成后下月订阅享 8 折优惠。',
                  style: MirrorText.bodyS.copyWith(color: MirrorColors.text2)),
              const SizedBox(height: 4),
              Text('目标设定后本月不可修改。',
                  style: MirrorText.caption),
            ],
          ),
        ),
      ),
    ),

    const SliverToBoxAdapter(child: EditorialDivider()),

    // Goal type selector
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          MirrorSpacing.pagePad, 0, MirrorSpacing.pagePad, 0),
      sliver: SliverToBoxAdapter(
        child: FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          duration: const Duration(milliseconds: 400),
          offsetY: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GOAL  ·  TYPE', style: MirrorText.overline),
              const SizedBox(height: 16),
              Row(
                children: [
                  ('weight',    '体重'),
                  ('body_fat',  '体脂率'),
                  ('waist',     '腰围'),
                  ('composite', '综合'),
                ].map((item) => MirrorChip(
                  label:    item.$2,
                  selected: _goalType == item.$1,
                  onTap:    () => setState(() => _goalType = item.$1),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    ),

    const SliverToBoxAdapter(child: EditorialDivider()),

    // Target value inputs
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          MirrorSpacing.pagePad, 0, MirrorSpacing.pagePad, 0),
      sliver: SliverToBoxAdapter(
        child: FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          duration: const Duration(milliseconds: 400),
          offsetY: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TARGET  ·  VALUE', style: MirrorText.overline),
              const SizedBox(height: 16),
              if (_goalType == 'weight' || _goalType == 'composite') ...[
                TextField(
                  controller: _weightCtrl,
                  decoration: sheetInputDecoration('目标体重 kg'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: MirrorText.body.copyWith(color: MirrorColors.text1),
                ),
                const SizedBox(height: 12),
              ],
              if (_goalType == 'body_fat' || _goalType == 'composite') ...[
                TextField(
                  controller: _bodyFatCtrl,
                  decoration: sheetInputDecoration('目标体脂率 %'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: MirrorText.body.copyWith(color: MirrorColors.text1),
                ),
                const SizedBox(height: 12),
              ],
              if (_goalType == 'waist' || _goalType == 'composite') ...[
                TextField(
                  controller: _waistCtrl,
                  decoration: sheetInputDecoration('目标腰围 cm'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: MirrorText.body.copyWith(color: MirrorColors.text1),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    ),

    // Start button
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          MirrorSpacing.pagePad, 24, MirrorSpacing.pagePad, 56),
      sliver: SliverToBoxAdapter(
        child: FadeSlideIn(
          delay: const Duration(milliseconds: 240),
          duration: const Duration(milliseconds: 400),
          offsetY: 8,
          child: OutlinedButton(
            onPressed: _isSaving ? null : _startChallenge,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: MirrorColors.divider, width: 0.5),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MirrorRadius.lg)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        color: MirrorColors.text1, strokeWidth: 1))
                : Text('START  ·  CHALLENGE',
                    style: MirrorText.overline.copyWith(
                        color: MirrorColors.text2, letterSpacing: 2.5)),
          ),
        ),
      ),
    ),
  ]);

  // ── Progress View ───────────────────────────────────────────────────────────

  Widget _buildProgressView(ChallengeProgress progress) =>
      CustomScrollView(slivers: [

    // Circular progress ring
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          MirrorSpacing.pagePad, 40, MirrorSpacing.pagePad, 0),
      sliver: SliverToBoxAdapter(
        child: FadeSlideIn(
          duration: const Duration(milliseconds: 450),
          offsetY: 12,
          child: Center(
            child: _CircularProgress(pct: progress.progressPct),
          ),
        ),
      ),
    ),

    // Days remaining
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          MirrorSpacing.pagePad, 24, MirrorSpacing.pagePad, 0),
      sliver: SliverToBoxAdapter(
        child: FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          duration: const Duration(milliseconds: 400),
          offsetY: 10,
          child: Column(
            children: [
              Text('${progress.daysRemaining}',
                  style: MirrorText.displayHero),
              const SizedBox(height: 4),
              Text('DAYS  ·  REMAINING', style: MirrorText.overline),
            ],
          ),
        ),
      ),
    ),

    const SliverToBoxAdapter(child: EditorialDivider()),

    // Metric comparison grid
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          MirrorSpacing.pagePad, 0, MirrorSpacing.pagePad, 0),
      sliver: SliverToBoxAdapter(
        child: FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          duration: const Duration(milliseconds: 400),
          offsetY: 10,
          child: _GoalMetricGrid(progress: progress),
        ),
      ),
    ),

    // Discount badge (shown when completed)
    if (progress.discountEligible)
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
            MirrorSpacing.pagePad, 24, MirrorSpacing.pagePad, 0),
        sliver: SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            duration: const Duration(milliseconds: 400),
            offsetY: 8,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: MirrorColors.gold, width: 0.5),
                borderRadius: BorderRadius.circular(MirrorRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GOAL  ·  ACHIEVED',
                      style: MirrorText.overline.copyWith(
                          color: MirrorColors.gold)),
                  const SizedBox(height: 8),
                  Text('下月订阅享 8 折优惠，续费时自动应用。',
                      style: MirrorText.bodyS.copyWith(
                          color: MirrorColors.text2)),
                ],
              ),
            ),
          ),
        ),
      ),

    // Abandon challenge
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          MirrorSpacing.pagePad, 32, MirrorSpacing.pagePad, 56),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: GestureDetector(
            onTap: _abandonChallenge,
            child: Text(
              '放弃本月挑战',
              style: MirrorText.caption.copyWith(
                color: MirrorColors.text3,
                decoration: TextDecoration.underline,
                decorationColor: MirrorColors.text3,
              ),
            ),
          ),
        ),
      ),
    ),
  ]);
}

// ── Circular Progress ─────────────────────────────────────────────────────────

class _CircularProgress extends StatelessWidget {
  const _CircularProgress({required this.pct});
  final double pct; // 0.0 – 100.0

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _CircularProgressPainter(pct: pct),
    size: const Size(160, 160),
  );
}

class _CircularProgressPainter extends CustomPainter {
  const _CircularProgressPainter({required this.pct});
  final double pct;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const startAngle = -math.pi / 2;

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0, math.pi * 2,
      false,
      Paint()
        ..color       = MirrorColors.divider
        ..strokeWidth = 2.0
        ..style       = PaintingStyle.stroke,
    );

    // Progress arc
    if (pct > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        math.pi * 2 * (pct / 100),
        false,
        Paint()
          ..color       = MirrorColors.text1
          ..strokeWidth = 2.0
          ..strokeCap   = StrokeCap.round
          ..style       = PaintingStyle.stroke,
      );
    }

    // Center percentage text
    final tp = TextPainter(
      text: TextSpan(
        text: '${pct.toStringAsFixed(0)}%',
        style: MirrorText.displayMd.copyWith(color: MirrorColors.text1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) => old.pct != pct;
}

// ── Goal Metric Grid ──────────────────────────────────────────────────────────

class _GoalMetricGrid extends StatelessWidget {
  const _GoalMetricGrid({required this.progress});
  final ChallengeProgress progress;

  @override
  Widget build(BuildContext context) {
    final rows = <_MetricRow>[];
    final goal = progress.goal;

    if (goal.targetWeightKg != null && progress.currentWeight != null) {
      rows.add(_MetricRow(
        label:   '体重',
        unit:    'kg',
        current: progress.currentWeight!,
        target:  goal.targetWeightKg!,
      ));
    }
    if (goal.targetBodyFat != null && progress.currentBodyFat != null) {
      rows.add(_MetricRow(
        label:   '体脂率',
        unit:    '%',
        current: progress.currentBodyFat!,
        target:  goal.targetBodyFat!,
      ));
    }
    if (goal.targetWaistCm != null && progress.currentWaist != null) {
      rows.add(_MetricRow(
        label:   '腰围',
        unit:    'cm',
        current: progress.currentWaist!,
        target:  goal.targetWaistCm!,
      ));
    }

    if (rows.isEmpty) {
      return Text('暂无数据', style: MirrorText.caption);
    }

    return Column(
      children: [
        // Header
        Row(children: [
          Expanded(child: Text('指标', style: MirrorText.overline)),
          SizedBox(width: 72,
              child: Text('当前', style: MirrorText.overline,
                  textAlign: TextAlign.end)),
          SizedBox(width: 72,
              child: Text('目标', style: MirrorText.overline,
                  textAlign: TextAlign.end)),
          SizedBox(width: 64,
              child: Text('差值', style: MirrorText.overline,
                  textAlign: TextAlign.end)),
        ]),
        const SizedBox(height: 12),
        ...rows.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Expanded(child: Text(r.label,
                style: MirrorText.bodyS.copyWith(color: MirrorColors.text2))),
            SizedBox(width: 72,
                child: Text('${r.current.toStringAsFixed(1)} ${r.unit}',
                    style: MirrorText.bodyS.copyWith(color: MirrorColors.text1),
                    textAlign: TextAlign.end)),
            SizedBox(width: 72,
                child: Text('${r.target.toStringAsFixed(1)} ${r.unit}',
                    style: MirrorText.bodyS.copyWith(color: MirrorColors.text3),
                    textAlign: TextAlign.end)),
            SizedBox(width: 64,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: DeltaText(
                    delta: r.current - r.target,
                    unit:  r.unit,
                  ),
                )),
          ]),
        )),
      ],
    );
  }
}

class _MetricRow {
  final String label;
  final String unit;
  final double current;
  final double target;
  const _MetricRow({
    required this.label,
    required this.unit,
    required this.current,
    required this.target,
  });
}
