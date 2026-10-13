import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/widgets/animate_widgets.dart';
import '../../core/widgets/body_viewport.dart';
import '../../core/widgets/delta_text.dart';
import '../../models/models.dart';
import '../../models/predict_models.dart';
import '../../services/api/predict_api.dart';
import '../../services/api/session_api.dart';

class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key, required this.idA, required this.idB});
  final String idA;
  final String idB;

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  _CompareData? _data;
  bool    _loading = true;
  String? _error;
  double  _sliderVal = 0.0; // 0 = A fully visible, 1 = B fully visible

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isPredict(String id) => id.startsWith('__predict_');

  int _weeksOf(String id) {
    if (id == kPredictId4) return 4;
    if (id == kPredictId8) return 8;
    return 12;
  }

  Future<SessionRecord?> _fetchSession(String id) async {
    if (_isPredict(id)) return null;
    return SessionApi.instance.get(id);
  }

  Future<PredictedMetrics?> _fetchPredict(String id) async {
    if (!_isPredict(id)) return null;
    return PredictApi.instance.fetchPredict(_weeksOf(id));
  }

  Future<void> _load() async {
    try {
      final sessionsFuture = Future.wait<SessionRecord?>([
        _fetchSession(widget.idA),
        _fetchSession(widget.idB),
      ]);
      final predictsFuture = Future.wait<PredictedMetrics?>([
        _fetchPredict(widget.idA),
        _fetchPredict(widget.idB),
      ]);
      final sessions = await sessionsFuture;
      final predicts = await predictsFuture;
      if (!mounted) return;
      setState(() {
        _data = _CompareData(
          sessionA: sessions[0], sessionB: sessions[1],
          predictA: predicts[0], predictB: predicts[1],
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  double? _weightA() => _data?.sessionA?.bodyData.weightKg
      ?? _data?.predictA?.predictedWeightKg;
  double? _weightB() => _data?.sessionB?.bodyData.weightKg
      ?? _data?.predictB?.predictedWeightKg;
  double? _fatA() => _data?.sessionA?.bodyData.bodyFatPct
      ?? _data?.predictA?.predictedBodyFatPct;
  double? _fatB() => _data?.sessionB?.bodyData.bodyFatPct
      ?? _data?.predictB?.predictedBodyFatPct;
  double? _waistA() => _data?.sessionA?.bodyData.waistCm
      ?? _data?.predictA?.predictedWaistCm;
  double? _waistB() => _data?.sessionB?.bodyData.waistCm
      ?? _data?.predictB?.predictedWaistCm;

  String _labelA() {
    if (_isPredict(widget.idA)) return '预测 · ${_weeksOf(widget.idA)}W';
    final s = _data?.sessionA;
    return s != null ? _fmtDate(s.createdAt) : '…';
  }

  String _labelB() {
    if (_isPredict(widget.idB)) return '预测 · ${_weeksOf(widget.idB)}W';
    final s = _data?.sessionB;
    return s != null ? _fmtDate(s.createdAt) : '…';
  }

  String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}'
      '.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MirrorColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildMasthead(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildMasthead() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            MirrorSpacing.pagePad, 20, MirrorSpacing.pagePad, 12),
        child: Text(
          'COMPARE',
          style: MirrorText.overline.copyWith(
            color: MirrorColors.gold, fontSize: 11, letterSpacing: 4.0),
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
        begin: const Offset(0, 1), end: const Offset(1, 1),
        alignment: Alignment.centerLeft,
        duration: 600.ms, curve: MirrorCurve.enter,
      ),
      const SizedBox(height: 4),
    ],
  );

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(
          color: MirrorColors.text1, strokeWidth: 1));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('加载失败', style: MirrorText.body),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            setState(() { _loading = true; _error = null; });
            _load();
          },
          child: const Text('重试'),
        ),
      ]));
    }
    return _buildScrollContent();
  }

  Widget _buildScrollContent() {
    final screenH = MediaQuery.of(context).size.height;
    return CustomScrollView(slivers: [

      // 导航栏
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
            MirrorSpacing.pagePad, 20, MirrorSpacing.pagePad, 0),
        sliver: SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: Duration.zero,
            duration: const Duration(milliseconds: 450),
            offsetY: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 13, color: MirrorColors.text3),
                    const SizedBox(width: 4),
                    Text('返回',
                        style: MirrorText.bodyS.copyWith(
                            color: MirrorColors.text3)),
                  ]),
                ),
                Text('BODY  ·  COMPARE', style: MirrorText.overline),
              ],
            ),
          ),
        ),
      ),

      // 时间标签行
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
            MirrorSpacing.pagePad, 20, MirrorSpacing.pagePad, 0),
        sliver: SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            duration: const Duration(milliseconds: 400),
            offsetY: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TimeLabel(
                  label: _labelA(),
                  isPredict: _isPredict(widget.idA),
                ),
                _TimeLabel(
                  label: _labelB(),
                  isPredict: _isPredict(widget.idB),
                ),
              ],
            ),
          ),
        ),
      ),

      // 叠加对比区
      SliverPadding(
        padding: const EdgeInsets.only(
            top: 16,
            left: MirrorSpacing.pagePad,
            right: MirrorSpacing.pagePad),
        sliver: SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            duration: const Duration(milliseconds: 550),
            offsetY: 24,
            child: _OverlayCompare(
              alphaA: 1.0 - _sliderVal,
              height: screenH * 0.42,
              paramsA: _data?.sessionA?.avatarParams
                  ?? _avatarParamsFromPredict(_data?.predictA),
              paramsB: _data?.sessionB?.avatarParams
                  ?? _avatarParamsFromPredict(_data?.predictB),
            ),
          ),
        ),
      ),

      // Slider
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
            MirrorSpacing.pagePad, 12, MirrorSpacing.pagePad, 0),
        sliver: SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            duration: const Duration(milliseconds: 400),
            offsetY: 8,
            child: Column(children: [
              SliderTheme(
                data: SliderThemeData(
                  thumbColor:         MirrorColors.text1,
                  activeTrackColor:   MirrorColors.text1,
                  inactiveTrackColor: MirrorColors.divider,
                  trackHeight:        1.0,
                  thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: _sliderVal,
                  onChanged: (v) => setState(() => _sliderVal = v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('叠加', style: MirrorText.caption),
                  Text(_labelA(), style: MirrorText.caption),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: MirrorColors.bg2,
                      border: Border.all(
                          color: MirrorColors.divider, width: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(_labelA(), style: MirrorText.caption),
                  const SizedBox(width: 24),
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: MirrorColors.gold, width: 1.0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(_labelB(),
                      style: MirrorText.caption.copyWith(
                          color: MirrorColors.gold)),
                ],
              ),
            ]),
          ),
        ),
      ),

      // 分隔线
      const SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: MirrorSpacing.pagePad),
        sliver: SliverToBoxAdapter(
          child: EditorialDivider(topPad: 28, bottomPad: 24),
        ),
      ),

      // 指标对比区
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
            MirrorSpacing.pagePad, 0, MirrorSpacing.pagePad, 0),
        sliver: SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 280),
            duration: const Duration(milliseconds: 400),
            offsetY: 8,
            child: _MetricCompareGrid(
              labelA: _labelA(), labelB: _labelB(),
              weightA: _weightA(), weightB: _weightB(),
              fatA: _fatA(),     fatB: _fatB(),
              waistA: _waistA(), waistB: _waistB(),
            ),
          ),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 56)),
    ]);
  }

  // predict 侧：用 A/B session 作为体型模板，叠加预测的 weight/waist 偏移
  AvatarParams? _avatarParamsFromPredict(PredictedMetrics? m) {
    if (m == null) return null;
    final template = _data?.sessionA?.avatarParams
        ?? _data?.sessionB?.avatarParams;
    if (template == null) return null;
    final weightDeltaNorm = (m.weightDeltaKg / 60.0).clamp(-0.3, 0.3);
    final waistDeltaNorm  = (m.waistDeltaCm  / 30.0).clamp(-0.3, 0.3);
    return template.copyWith(
      weightNorm: (template.weightNorm + weightDeltaNorm).clamp(0.0, 1.0),
      waistNorm:  (template.waistNorm  + waistDeltaNorm).clamp(0.0, 1.0),
    );
  }
}

// ── 数据容器 ──────────────────────────────────────────────────────────────────

class _CompareData {
  final SessionRecord?    sessionA;
  final SessionRecord?    sessionB;
  final PredictedMetrics? predictA;
  final PredictedMetrics? predictB;

  const _CompareData({
    this.sessionA, this.sessionB,
    this.predictA, this.predictB,
  });
}

// ── 时间标签 ──────────────────────────────────────────────────────────────────

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.label, required this.isPredict});
  final String label;
  final bool   isPredict;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: MirrorText.overline.copyWith(
        color: isPredict ? MirrorColors.gold : MirrorColors.text2,
      ),
    );
  }
}

// ── 叠加对比视口 ──────────────────────────────────────────────────────────────

class _OverlayCompare extends StatelessWidget {
  const _OverlayCompare({
    required this.alphaA,
    required this.height,
    required this.paramsA,
    required this.paramsB,
  });
  final double alphaA;
  final double height;
  final AvatarParams? paramsA;
  final AvatarParams? paramsB;

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [
      // A 层（底，实心填充，带背景）
      Opacity(
        opacity: alphaA.clamp(0.0, 1.0),
        child: BodyViewport(
          height: height,
          avatarParams: paramsA,
          strokeStyle: BodyStrokeStyle.fill,
          color: MirrorColors.bg2,
          showBackground: true,
        ),
      ),
      // B 层（顶，金色虚线，无背景，真叠加）
      Opacity(
        opacity: (1.0 - alphaA).clamp(0.15, 1.0),
        child: BodyViewport(
          height: height,
          avatarParams: paramsB,
          strokeStyle: BodyStrokeStyle.dashedOutline,
          color: MirrorColors.gold,
          showBackground: false,
        ),
      ),
    ]);
  }
}

// ── 指标对比网格（行式布局，保证三列对齐） ────────────────────────────────────

class _MetricCompareGrid extends StatelessWidget {
  const _MetricCompareGrid({
    required this.labelA,  required this.labelB,
    required this.weightA, required this.weightB,
    required this.fatA,    required this.fatB,
    required this.waistA,  required this.waistB,
  });

  final String  labelA,  labelB;
  final double? weightA, weightB;
  final double? fatA,    fatB;
  final double? waistA,  waistB;

  static const _divider = _ColDivider();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 列标题行
        Row(children: [
          Expanded(flex: 4,
              child: Text(labelA, style: MirrorText.overline)),
          _divider,
          Expanded(flex: 4,
              child: Text(labelB, style: MirrorText.overline)),
          _divider,
          Expanded(flex: 3,
              child: Text('DELTA', style: MirrorText.overline)),
        ]),
        const SizedBox(height: 16),

        // 体重行
        _MetricRow(
          label: '体重',
          valueA: weightA, valueB: weightB, unit: 'kg',
        ),
        const SizedBox(height: 20),

        // 体脂率行
        _MetricRow(
          label: '体脂率',
          valueA: fatA, valueB: fatB, unit: '%',
        ),
        const SizedBox(height: 20),

        // 腰围行
        _MetricRow(
          label: '腰围',
          valueA: waistA, valueB: waistB, unit: 'cm',
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.valueA, required this.valueB,
    required this.unit,
  });
  final String  label;
  final double? valueA, valueB;
  final String  unit;

  static const _divider = _ColDivider();

  @override
  Widget build(BuildContext context) {
    final delta = (valueA != null && valueB != null)
        ? valueB! - valueA!
        : 0.0;

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 4, child: _MetricItem(
          label: label, value: valueA, unit: unit)),
      _divider,
      Expanded(flex: 4, child: _MetricItem(
          label: label, value: valueB, unit: unit)),
      _divider,
      Expanded(flex: 3, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MirrorText.caption),
          const SizedBox(height: 4),
          DeltaText(delta: delta, unit: unit),
        ],
      )),
    ]);
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label, required this.value, required this.unit});
  final String  label;
  final double? value;
  final String  unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: MirrorText.caption),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            value != null
                ? CountUpText(
                    value: value!,
                    style: MirrorText.displayMd,
                    fractionDigits: 1,
                    duration: MirrorDuration.xslow,
                  )
                : Text('—', style: MirrorText.displayMd),
            if (value != null) ...[
              const SizedBox(width: 3),
              Text(unit, style: MirrorText.unit),
            ],
          ],
        ),
      ],
    );
  }
}

class _ColDivider extends StatelessWidget {
  const _ColDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 60,
      color: MirrorColors.divider,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}
