import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    try {
      await ref
          .read(targetParamsNotifierProvider.notifier)
          .save(_targetParams!);
      if (mounted) {
        setState(() => _isDirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('目标已保存 · 前往 Mirror 查看')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: $e')));
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
          'COACH',
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
            Text('GOAL  ·  TARGET', style: MirrorText.overline),
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
                child: Text('先记录一次身体数据以开启目标设置',
                    style: MirrorText.caption),
              )
            else ...[
              _GoalSlider(
                label: '体重',
                value: _targetParams!.weightNorm,
                onChanged: (v) => _onSliderChanged(v, 'weight'),
              ),
              _GoalSlider(
                label: '体脂率',
                value: _targetParams!.bodyFatNorm,
                onChanged: (v) => _onSliderChanged(v, 'bodyFat'),
              ),
              _GoalSlider(
                label: '腰围',
                value: _targetParams!.waistNorm,
                onChanged: (v) => _onSliderChanged(v, 'waist'),
              ),
              _GoalSlider(
                label: '臀围',
                value: _targetParams!.hipNorm,
                onChanged: (v) => _onSliderChanged(v, 'hip'),
              ),
              _GoalSlider(
                label: '肩宽',
                value: _targetParams!.shoulderNorm,
                onChanged: (v) => _onSliderChanged(v, 'shoulder'),
              ),
              _GoalSlider(
                label: '肌肉量',
                value: _targetParams!.muscleNorm,
                onChanged: (v) => _onSliderChanged(v, 'muscle'),
              ),
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
                        : Text('SAVE  ·  TARGET',
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
            Text('THIS WEEK  ·  INSIGHTS', style: MirrorText.overline),
            const SizedBox(height: 16),
            ref.watch(coachSuggestionsProvider).when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(
                    color: MirrorColors.text1, strokeWidth: 1),
              )),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('加载失败', style: MirrorText.body),
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
                Text('EXERCISE  ·  LIBRARY', style: MirrorText.overline),
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

class _GoalSlider extends StatelessWidget {
  const _GoalSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String                 label;
  final double                 value;
  final ValueChanged<double>   onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        SizedBox(
          width: 52,
          child: Text(label, style: MirrorText.overline),
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

  String _categoryLabel(String cat) => switch (cat) {
    'training'  => 'TRAINING',
    'nutrition' => 'NUTRITION',
    'recovery'  => 'RECOVERY',
    _           => cat.toUpperCase(),
  };

  @override
  Widget build(BuildContext context) {
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
          Text(_categoryLabel(card.category), style: MirrorText.overline),
          const SizedBox(height: 8),
          Text(card.title,
              style: MirrorText.body.copyWith(
                  color: MirrorColors.text1,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(card.body,
              style: MirrorText.bodyS.copyWith(
                  color: MirrorColors.text2)),
        ],
      ),
    );
  }
}
