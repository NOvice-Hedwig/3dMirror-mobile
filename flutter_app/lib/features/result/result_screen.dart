import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/animate_widgets.dart';
import '../../models/models.dart';
import '../../services/api/session_api.dart';
import '../../services/unity_bridge/unity_bridge.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.sessionId});
  final String sessionId;
  @override State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  SessionRecord? _session;
  bool    _loading      = true;
  double  _sliderVal    = 0;
  int     _compareWeeks = 4;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await SessionApi.instance.get(widget.sessionId);
      setState(() { _session = s; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
      return;
    }
    try {
      await UnityBridge.instance.loadAvatar('${_session!.avatarParams.gender}_base');
      await UnityBridge.instance.applyBodyParams(_session!.avatarParams);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MirrorColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildMasthead(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                      color: MirrorColors.text1, strokeWidth: 1))
                  : _error != null
                      ? _buildError()
                      : _buildContent(),
            ),
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

  Widget _buildError() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('加载失败', style: MirrorText.body),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
        child: const Text('重试'),
      ),
    ]),
  );

  Widget _buildContent() {
    final s  = _session!;
    final bd = s.bodyData;
    final screenH = MediaQuery.of(context).size.height;

    return CustomScrollView(slivers: [

      // ── Zone 1: Hero ─────────────────────────────────────────────────────────

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
                    Text('返回', style: MirrorText.bodyS.copyWith(
                        color: MirrorColors.text3)),
                  ]),
                ),
                Text(
                  '#${widget.sessionId.substring(0, 8).toUpperCase()}  ·  ${_formatDate(s.createdAt)}',
                  style: MirrorText.overline,
                ),
              ],
            ),
          ),
        ),
      ),

      // 3D Viewport — 全出血，仅顶角圆弧
      SliverPadding(
        padding: const EdgeInsets.only(top: 16, bottom: 0,
            left: MirrorSpacing.pagePad, right: MirrorSpacing.pagePad),
        sliver: SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            duration: const Duration(milliseconds: 550),
            offsetY: 24,
            child: _Viewport(height: screenH * 0.50),
          ),
        ),
      ),

      // 英雄数字区 — BODY · METRICS + 体重 count-up
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
            MirrorSpacing.pagePad, 28, MirrorSpacing.pagePad, 0),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 400),
                offsetY: 0,
                child: Text('BODY  ·  METRICS', style: MirrorText.overline),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                duration: MirrorDuration.xslow,
                offsetY: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CountUpText(
                      value: bd.weightKg,
                      style: MirrorText.displayHero,
                      fractionDigits: 1,
                      duration: MirrorDuration.xslow,
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 400),
                        duration: const Duration(milliseconds: 300),
                        offsetY: 0,
                        child: Text('kg', style: MirrorText.unitLg),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              FadeSlideIn(
                delay: const Duration(milliseconds: 440),
                duration: const Duration(milliseconds: 350),
                offsetY: 0,
                child: Text('你的体重', style: MirrorText.body),
              ),
            ],
          ),
        ),
      ),

      // ── Zone 2: 非对称指标网格 ───────────────────────────────────────────────

      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
            MirrorSpacing.pagePad, 32, MirrorSpacing.pagePad, 0),
        sliver: SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 480),
            duration: const Duration(milliseconds: 400),
            offsetY: 12,
            child: _EditorialMetricGrid(bd: bd),
          ),
        ),
      ),

      // ── Zone 3: 时间对比 ─────────────────────────────────────────────────────

      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: MirrorSpacing.pagePad),
        sliver: SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 640),
            duration: const Duration(milliseconds: 350),
            offsetY: 8,
            child: Column(children: [
              const EditorialDivider(topPad: 36, bottomPad: 32),
              _buildCompare(),
            ]),
          ),
        ),
      ),

      // 分享按钮
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
            MirrorSpacing.pagePad, 24, MirrorSpacing.pagePad, 56),
        sliver: SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 720),
            duration: const Duration(milliseconds: 300),
            offsetY: 0,
            child: OutlinedButton(
              onPressed: _shareScreenshot,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: MirrorColors.divider, width: 0.5),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MirrorRadius.lg)),
              ),
              child: Text('SAVE  ·  SHARE',
                  style: MirrorText.overline.copyWith(
                      color: MirrorColors.text2, letterSpacing: 2.5)),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildCompare() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Text('TIME · COMPARE', style: MirrorText.overline),
        const Spacer(),
        ...[4, 8, 12].map((w) {
          final sel = _compareWeeks == w;
          return GestureDetector(
            onTap: () => setState(() => _compareWeeks = w),
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: AnimatedDefaultTextStyle(
                duration: MirrorDuration.fast,
                curve: MirrorCurve.snap,
                style: MirrorText.bodyS.copyWith(
                  color: sel ? MirrorColors.text1 : MirrorColors.text3,
                  fontWeight: sel ? FontWeight.w500 : FontWeight.w300,
                  decoration: sel ? TextDecoration.underline : TextDecoration.none,
                  decorationColor: MirrorColors.text1,
                ),
                child: Text('$w W'),
              ),
            ),
          );
        }),
      ]),
      const SizedBox(height: 20),
      SliderTheme(
        data: SliderThemeData(
          thumbColor:         MirrorColors.text1,
          activeTrackColor:   MirrorColors.text1,
          inactiveTrackColor: MirrorColors.divider,
          trackHeight:        1.0,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: SliderComponentShape.noOverlay,
        ),
        child: Slider(
          value: _sliderVal,
          onChanged: (v) => setState(() => _sliderVal = v),
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('NOW', style: MirrorText.caption),
        Text('$_compareWeeks W', style: MirrorText.caption),
      ]),
    ],
  );

  Future<void> _shareScreenshot() async {
    try {
      await UnityBridge.instance.captureAndFetch();
    } catch (_) {}
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2,'0')}.${d.day.toString().padLeft(2,'0')}';
}

// ── 3D Viewport ────────────────────────────────────────────────────────────────

class _Viewport extends StatelessWidget {
  const _Viewport({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      // 仅顶角圆弧，底部平齐产生出血效果
      borderRadius: const BorderRadius.only(
        topLeft:     Radius.circular(MirrorRadius.xl),
        topRight:    Radius.circular(MirrorRadius.xl),
        bottomLeft:  Radius.circular(MirrorRadius.sm),
        bottomRight: Radius.circular(MirrorRadius.sm),
      ),
      child: Container(
        height: height,
        color: MirrorColors.viewport,
        child: Stack(children: [
          Center(child: CustomPaint(
              painter: _BodyPainter(), size: const Size(90, 220))),
          Positioned(
            bottom: 16, left: 0, right: 0,
            child: Text('拖动旋转', textAlign: TextAlign.center,
                style: MirrorText.caption),
          ),
        ]),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = MirrorColors.bg2
      ..style  = PaintingStyle.fill;
    final cx = size.width / 2;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, 16), width: 26, height: 28), p);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 20, 32, 40, 56), const Radius.circular(7)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 31, 34, 10, 42), const Radius.circular(5)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 21, 34, 10, 42), const Radius.circular(5)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 18, 90, 14, 58), const Radius.circular(6)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 4, 90, 14, 58), const Radius.circular(6)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 20, 145, 18, 9), const Radius.circular(4)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 2, 145, 18, 9), const Radius.circular(4)), p);
  }

  @override bool shouldRepaint(_) => false;
}

// ── 非对称指标网格 ─────────────────────────────────────────────────────────────

class _EditorialMetricGrid extends StatelessWidget {
  const _EditorialMetricGrid({required this.bd});
  final BodyData bd;

  @override
  Widget build(BuildContext context) {
    final fatVal  = bd.bodyFatPct;
    final leanVal = bd.derivedLeanMass;
    final waistVal = bd.waistCm;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左列 — 体脂率（大字）
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('体脂率', style: MirrorText.overline),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    fatVal != null
                        ? CountUpText(
                            value: fatVal,
                            style: MirrorText.displayXl,
                            fractionDigits: 1,
                            duration: MirrorDuration.xslow,
                          )
                        : Text('—', style: MirrorText.displayXl),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('%', style: MirrorText.unitLg),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 垂直分隔线
          Container(
            width: 0.5,
            color: MirrorColors.divider,
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),

          // 右列 — 瘦体重 + 腰围（堆叠）
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 瘦体重
                Text('瘦体重', style: MirrorText.overline),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    leanVal != null
                        ? CountUpText(
                            value: leanVal,
                            style: MirrorText.displayMd,
                            fractionDigits: 1,
                            duration: MirrorDuration.xslow,
                          )
                        : Text('—', style: MirrorText.displayMd),
                    const SizedBox(width: 3),
                    Text('kg', style: MirrorText.unit),
                  ],
                ),

                // 分隔线
                Container(
                  height: 0.5, color: MirrorColors.divider,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                ),

                // 腰围
                Text('腰围', style: MirrorText.overline),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    waistVal != null
                        ? CountUpText(
                            value: waistVal,
                            style: MirrorText.displayMd,
                            fractionDigits: 1,
                            duration: MirrorDuration.xslow,
                          )
                        : Text('—', style: MirrorText.displayMd),
                    const SizedBox(width: 3),
                    Text('cm', style: MirrorText.unit),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
