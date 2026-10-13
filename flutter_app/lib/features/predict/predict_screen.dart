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
import '../../providers/home_provider.dart';
import '../../providers/predict_provider.dart';

class PredictScreen extends ConsumerStatefulWidget {
  const PredictScreen({super.key});

  @override
  ConsumerState<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends ConsumerState<PredictScreen> {
  int _weeks = 4;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: MirrorColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildMasthead(),
            Expanded(child: _buildContent(screenH)),
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
          'PREDICT',
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

  Widget _buildContent(double screenH) {
    final metrics = ref.watch(predictMetricsProvider(_weeks)).valueOrNull;
    return CustomScrollView(
      slivers: [
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
                  Text('BODY  ·  FUTURE', style: MirrorText.overline),
                ],
              ),
            ),
          ),
        ),

        // 周期选择
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              MirrorSpacing.pagePad, 28, MirrorSpacing.pagePad, 0),
          sliver: SliverToBoxAdapter(
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              duration: const Duration(milliseconds: 400),
              offsetY: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TIME  ·  RANGE', style: MirrorText.overline),
                  const SizedBox(height: 16),
                  Row(
                    children: [4, 8, 12].map((w) {
                      final sel = _weeks == w;
                      return GestureDetector(
                        onTap: () => setState(() => _weeks = w),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: AnimatedDefaultTextStyle(
                            duration: MirrorDuration.fast,
                            curve: MirrorCurve.snap,
                            style: MirrorText.bodyS.copyWith(
                              color: sel
                                  ? MirrorColors.text1
                                  : MirrorColors.text3,
                              fontWeight: sel
                                  ? FontWeight.w500
                                  : FontWeight.w300,
                              decoration: sel
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                              decorationColor: MirrorColors.text1,
                            ),
                            child: Text('$w W'),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3D Viewport（静态占位）
        SliverPadding(
          padding: const EdgeInsets.only(
              top: 20, left: MirrorSpacing.pagePad,
              right: MirrorSpacing.pagePad),
          sliver: SliverToBoxAdapter(
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              duration: const Duration(milliseconds: 550),
              offsetY: 24,
              child: BodyViewport(
                height: screenH * 0.42,
                avatarParams: metrics != null
                    ? _avatarParamsFromMetrics(metrics)
                    : null,
                strokeStyle: BodyStrokeStyle.dashedOutline,
                color: MirrorColors.gold,
              ),
            ),
          ),
        ),

        // 预测数据区
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              MirrorSpacing.pagePad, 28, MirrorSpacing.pagePad, 0),
          sliver: SliverToBoxAdapter(
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 240),
              duration: const Duration(milliseconds: 400),
              offsetY: 12,
              child: ref.watch(predictMetricsProvider(_weeks)).when(
                loading: _buildLoading,
                error:   _buildError,
                data:    _buildMetrics,
              ),
            ),
          ),
        ),

        // 底部按钮
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              MirrorSpacing.pagePad, 24, MirrorSpacing.pagePad, 56),
          sliver: SliverToBoxAdapter(
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 400),
              duration: const Duration(milliseconds: 300),
              offsetY: 0,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: MirrorColors.divider, width: 0.5),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MirrorRadius.lg)),
                ),
                child: Text('HISTORY  ·  COMPARE',
                    style: MirrorText.overline.copyWith(
                        color: MirrorColors.text2,
                        letterSpacing: 2.5)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() => const Center(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: CircularProgressIndicator(
          color: MirrorColors.text1, strokeWidth: 1),
    ),
  );

  Widget _buildError(Object e, StackTrace _) {
    if (e is InsufficientDataException) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          Text('数据不足', style: MirrorText.body),
          const SizedBox(height: 8),
          Text(
            '至少记录 2 次身体数据后\n预测功能将自动开启',
            style: MirrorText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Text('加载失败', style: MirrorText.body),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () =>
              ref.invalidate(predictMetricsProvider(_weeks)),
          child: const Text('重试'),
        ),
      ],
    );
  }

  Widget _buildMetrics(PredictedMetrics m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 英雄数字 — 预测体重
        Text('PREDICTED  ·  WEIGHT', style: MirrorText.overline),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CountUpText(
              value: m.predictedWeightKg,
              style: MirrorText.displayHero,
              fractionDigits: 1,
              duration: MirrorDuration.xslow,
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('kg', style: MirrorText.unitLg),
            ),
          ],
        ),
        const SizedBox(height: 4),
        DeltaText(delta: m.weightDeltaKg, unit: 'kg'),

        const EditorialDivider(topPad: 28, bottomPad: 24),

        // 非对称指标网格
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左列 — 体脂率
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
                        CountUpText(
                          value: m.predictedBodyFatPct,
                          style: MirrorText.displayXl,
                          fractionDigits: 1,
                          duration: MirrorDuration.xslow,
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('%', style: MirrorText.unitLg),
                        ),
                      ],
                    ),
                    DeltaText(delta: m.bodyFatDeltaPct, unit: '%'),
                  ],
                ),
              ),

              // 垂直分隔线
              Container(
                width: 0.5,
                color: MirrorColors.divider,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),

              // 右列 — 腰围 + 置信度
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('腰围', style: MirrorText.overline),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        CountUpText(
                          value: m.predictedWaistCm,
                          style: MirrorText.displayMd,
                          fractionDigits: 1,
                          duration: MirrorDuration.xslow,
                        ),
                        const SizedBox(width: 3),
                        Text('cm', style: MirrorText.unit),
                      ],
                    ),
                    DeltaText(delta: m.waistDeltaCm, unit: 'cm'),

                    Container(
                      height: 0.5,
                      color: MirrorColors.divider,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                    ),

                    Text('置信度', style: MirrorText.overline),
                    const SizedBox(height: 8),
                    Text(
                      '${(m.confidence * 100).toStringAsFixed(0)}%',
                      style: MirrorText.displayMd,
                    ),
                    Text('基于 ${m.dataPoints} 条记录',
                        style: MirrorText.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 用当前 session 体型作模板，叠加预测的 weight/waist 偏移生成轮廓参数
  AvatarParams? _avatarParamsFromMetrics(PredictedMetrics m) {
    final current = ref.read(latestSessionProvider)?.avatarParams;
    if (current == null) return null;
    final weightDeltaNorm = (m.weightDeltaKg / 60.0).clamp(-0.3, 0.3);
    final waistDeltaNorm  = (m.waistDeltaCm  / 30.0).clamp(-0.3, 0.3);
    return current.copyWith(
      weightNorm: (current.weightNorm + weightDeltaNorm).clamp(0.0, 1.0),
      waistNorm:  (current.waistNorm  + waistDeltaNorm).clamp(0.0, 1.0),
    );
  }
}


