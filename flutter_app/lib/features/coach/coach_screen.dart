import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/coach_text.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/animate_widgets.dart';
import '../../models/coach_models.dart';
import '../../models/models.dart';
import '../../providers/coach_provider.dart';
import '../../services/api/session_api.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  AvatarParams? _targetParams;
  bool _isDirty  = false;
  bool _isSaving = false;
  bool _loading  = true;

  S get _s => S.of(context);

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      // Use saved target if available; otherwise fall back to latest session
      final saved = ref.read(targetParamsNotifierProvider);
      if (saved != null) {
        if (mounted) setState(() { _targetParams = saved; _loading = false; });
        return;
      }
      final sessions = await SessionApi.instance.list(limit: 1);
      if (mounted) {
        setState(() {
          _targetParams = sessions.isNotEmpty
              ? sessions.first.avatarParams : null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSliderChanged(double v, String field) {
    if (_targetParams == null) return;
    final p = _targetParams!;
    setState(() {
      _isDirty = true;
      _targetParams = AvatarParams(
        heightNorm:   field == 'height'   ? v : p.heightNorm,
        weightNorm:   field == 'weight'   ? v : p.weightNorm,
        bodyFatNorm:  field == 'bodyFat'  ? v : p.bodyFatNorm,
        waistNorm:    field == 'waist'    ? v : p.waistNorm,
        hipNorm:      field == 'hip'      ? v : p.hipNorm,
        shoulderNorm: field == 'shoulder' ? v : p.shoulderNorm,
        muscleNorm:   field == 'muscle'   ? v : p.muscleNorm,
        gender:       p.gender,
        lightingProfile: p.lightingProfile,
        photoEnhanced:   p.photoEnhanced,
      );
    });
  }

  Future<void> _saveTarget() async {
    if (_targetParams == null || _isSaving) return;
    setState(() => _isSaving = true);
    final s = _s;
    try {
      await ref
          .read(targetParamsNotifierProvider.notifier)
          .save(_targetParams!);
      if (mounted) {
        setState(() => _isDirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.coachTargetSaved)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.saveFailedDetail('$e'))));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MirrorColors.bg,
    body: SafeArea(
      child: Column(children: [
        _buildMasthead(),
        Expanded(child: CustomScrollView(slivers: [
          _buildGoalSection(),
          _buildSuggestionsSection(),
          _buildLibraryEntry(),
          const SliverToBoxAdapter(child: SizedBox(height: 56)),
        ])),
      ]),
    ),
  );

  Widget _buildMasthead() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            MirrorSpacing.pagePad, 20, MirrorSpacing.pagePad, 12),
        child: Text(
          _s.coachMasthead,
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

  Widget _buildGoalSection() => SliverPadding(
    padding: const EdgeInsets.fromLTRB(
        MirrorSpacing.pagePad, 32, MirrorSpacing.pagePad, 0),
    sliver: SliverToBoxAdapter(
      child: FadeSlideIn(
        delay: const Duration(milliseconds: 80),
        duration: const Duration(milliseconds: 450),
        offsetY: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_s.coachGoalTarget, style: MirrorText.overline),
            const SizedBox(height: 20),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(
                    color: MirrorColors.text1, strokeWidth: 1),
              ))
            else if (_targetParams == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(_s.coachNeedsSession,
                    style: MirrorText.caption),
              )
            else ...[
              ..._goalSliders(_targetParams!),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: _isDirty ? 1.0 : 0.0,
                duration: MirrorDuration.fast,
                child: IgnorePointer(
                  ignoring: !_isDirty,
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _saveTarget,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: MirrorColors.divider, width: 0.5),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(MirrorRadius.lg)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                color: MirrorColors.text2, strokeWidth: 1.5))
                        : Text(_s.coachSaveTarget,
                            style: MirrorText.overline.copyWith(
                                color: MirrorColors.text2,
                                letterSpacing: 2.5)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  List<Widget> _goalSliders(AvatarParams p) {
    final rows = [
      (_s.labelWeight,   p.weightNorm,   'weight'),
      (_s.labelBodyFat,  p.bodyFatNorm,  'bodyFat'),
      (_s.labelWaist,    p.waistNorm,    'waist'),
      (_s.labelHip,      p.hipNorm,      'hip'),
      (_s.labelShoulder, p.shoulderNorm, 'shoulder'),
      (_s.labelMuscle,   p.muscleNorm,   'muscle'),
    ];
    final labelWidth = _sliderLabelWidth(context, [for (final r in rows) r.$1]);
    return [
      for (final (label, value, field) in rows)
        _GoalSlider(
          label: label,
          labelWidth: labelWidth,
          value: value,
          onChanged: (v) => _onSliderChanged(v, field),
        ),
    ];
  }

  Widget _buildSuggestionsSection() => SliverPadding(
    padding: const EdgeInsets.fromLTRB(
        MirrorSpacing.pagePad, 0, MirrorSpacing.pagePad, 0),
    sliver: SliverToBoxAdapter(
      child: FadeSlideIn(
        delay: const Duration(milliseconds: 200),
        duration: const Duration(milliseconds: 400),
        offsetY: 10,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EditorialDivider(),
            Text(_s.coachInsights, style: MirrorText.overline),
            const SizedBox(height: 16),
            ref.watch(coachSuggestionsProvider).when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(
                    color: MirrorColors.text1, strokeWidth: 1),
              )),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(_s.loadFailed, style: MirrorText.body),
              ),
              data: (resp) => Column(
                children: resp.cards
                    .map((card) => _SuggestionCard(card: card))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildLibraryEntry() => SliverPadding(
    padding: const EdgeInsets.fromLTRB(
        MirrorSpacing.pagePad, 0, MirrorSpacing.pagePad, 0),
    sliver: SliverToBoxAdapter(
      child: FadeSlideIn(
        delay: const Duration(milliseconds: 320),
        duration: const Duration(milliseconds: 400),
        offsetY: 8,
        child: Column(children: [
          const EditorialDivider(),
          GestureDetector(
            onTap: () => context.push(MirrorRoute.exerciseLibrary),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Text(_s.coachLibraryEntry, style: MirrorText.overline),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: MirrorColors.text3),
              ]),
            ),
          ),
        ]),
      ),
    ),
  );
}

// ── Goal Slider ───────────────────────────────────────────────────────────────

/// Label column width for the goal sliders: the widest label at its normal size plus a
/// gap, at least the original 52 (so Chinese is unchanged) and at most 120 so the sliders
/// keep most of the row. English needs about 100.
double _sliderLabelWidth(BuildContext context, List<String> labels) {
  final scaler = MediaQuery.textScalerOf(context);
  // Same style the label Text resolves to (it inherits the default text style).
  final style  = DefaultTextStyle.of(context).style.merge(MirrorText.overline);
  var widest = 0.0;
  for (final l in labels) {
    final tp = TextPainter(
      text: TextSpan(text: l, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    widest = math.max(widest, tp.width);
    tp.dispose();
  }
  return (widest + 8).clamp(52.0, 120.0);
}


class _GoalSlider extends StatelessWidget {
  const _GoalSlider({
    required this.label,
    required this.labelWidth,
    required this.value,
    required this.onChanged,
  });

  final String                 label;
  final double                 labelWidth;
  final double                 value;
  final ValueChanged<double>   onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        SizedBox(
          width: labelWidth,
          child: FittedBox(   // only shrinks past the width cap (very large system font)
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label, style: MirrorText.overline),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              thumbColor:         MirrorColors.text1,
              activeTrackColor:   MirrorColors.text1,
              inactiveTrackColor: MirrorColors.divider,
              trackHeight:        1.0,
              thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: MirrorText.bodyS,
            textAlign: TextAlign.end,
          ),
        ),
      ]),
    );
  }
}

// ── Suggestion Card ───────────────────────────────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.card});
  final SuggestionCard card;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (title, body) = coachCardText(s, card);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: MirrorColors.divider, width: 0.5),
        borderRadius: BorderRadius.circular(MirrorRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(coachCategoryLabel(s, card.category), style: MirrorText.overline),
          const SizedBox(height: 8),
          Text(title,
              style: MirrorText.body.copyWith(
                  color: MirrorColors.text1,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(body,
              style: MirrorText.bodyS.copyWith(
                  color: MirrorColors.text2)),
        ],
      ),
    );
  }
}
