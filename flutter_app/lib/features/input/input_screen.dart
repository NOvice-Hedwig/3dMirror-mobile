import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/animate_widgets.dart';
import '../../models/models.dart';
import '../../services/api/session_api.dart';
import '../../services/api/auth_api.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});
  @override State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  double  _weight   = 0, _bodyFat = 0, _waist = 0;
  bool    _hasBf    = false, _hasWaist = false;
  WorkoutType _workout = WorkoutType.rest;
  int     _duration = 0;
  Intensity? _intensity;
  bool    _loading    = false;
  bool    _ctaPressed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MirrorColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildMasthead(),
            Expanded(
              child: CustomScrollView(slivers: [

                // ── Header ──────────────────────────────────────────────────
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
                        child: Text(_dayLabel(), style: MirrorText.overline),
                      ),
                      const SizedBox(height: 12),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 80),
                        duration: MirrorDuration.slow,
                        offsetY: 16,
                        child: Text.rich(TextSpan(style: MirrorText.title, children: [
                          const TextSpan(text: '告诉我\n你的'),
                          TextSpan(text: '身体',
                              style: MirrorText.title.copyWith(fontStyle: FontStyle.italic)),
                        ])),
                      ),
                      const SizedBox(height: 6),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 160),
                        duration: const Duration(milliseconds: 400),
                        offsetY: 8,
                        child: Text('数据越多，镜像越准', style: MirrorText.body),
                      ),
                      const SizedBox(height: 32),
                    ],
                  )),
                ),

                // ── Gender toggle ────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: MirrorSpacing.pagePad),
                  sliver: SliverToBoxAdapter(child: FadeSlideIn(
                    delay: const Duration(milliseconds: 240),
                    duration: const Duration(milliseconds: 400),
                    offsetY: 8,
                    child: _genderToggle(),
                  )),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── "BODY · DATA" section label ──────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: MirrorSpacing.pagePad),
                  sliver: SliverToBoxAdapter(child: FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 400),
                    offsetY: 6,
                    child: Text('BODY  ·  DATA', style: MirrorText.overline),
                  )),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Body fields ──────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: MirrorSpacing.pagePad),
                  sliver: SliverToBoxAdapter(child: FadeSlideIn(
                    delay: const Duration(milliseconds: 360),
                    duration: const Duration(milliseconds: 400),
                    offsetY: 8,
                    child: Column(children: [
                      _Row(label: '体重', value: _weight > 0 ? _weight.toStringAsFixed(1) : null,
                          unit: 'kg', onTap: () => _dec('体重 (kg)', 30, 200, _weight.clamp(30,200), 0.1,
                              (v) => setState(() => _weight = v))),
                      _Row(label: '体脂率', value: _hasBf ? _bodyFat.toStringAsFixed(1) : null,
                          unit: '%', onTap: () => _dec('体脂率 (%)', 3, 60, _hasBf ? _bodyFat : 20, 0.1,
                              (v) => setState(() { _bodyFat = v; _hasBf = true; }))),
                      _Row(label: '腰围', value: _hasWaist ? _waist.toStringAsFixed(1) : null,
                          unit: 'cm', isLast: true,
                          onTap: () => _dec('腰围 (cm)', 50, 160, _hasWaist ? _waist : 80, 0.5,
                              (v) => setState(() { _waist = v; _hasWaist = true; }))),
                    ]),
                  )),
                ),

                // ── Editorial divider ────────────────────────────────────────
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: MirrorSpacing.pagePad),
                  sliver: SliverToBoxAdapter(child: FadeSlideIn(
                    delay: Duration(milliseconds: 440),
                    duration: Duration(milliseconds: 350),
                    offsetY: 0,
                    child: EditorialDivider(topPad: 24, bottomPad: 0),
                  )),
                ),

                // ── Activity ─────────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      MirrorSpacing.pagePad, 24, MirrorSpacing.pagePad, 0),
                  sliver: SliverToBoxAdapter(child: FadeSlideIn(
                    delay: const Duration(milliseconds: 480),
                    duration: const Duration(milliseconds: 400),
                    offsetY: 8,
                    child: _activitySection(),
                  )),
                ),

                // ── CTA ──────────────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      MirrorSpacing.pagePad, 32, MirrorSpacing.pagePad, 48),
                  sliver: SliverToBoxAdapter(child: _cta()),
                ),
              ]),
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

  Widget _genderToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
          color: MirrorColors.bg2,
          borderRadius: BorderRadius.circular(MirrorRadius.md)),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: ['female', 'male'].map((g) {
          final sel = _gender == g;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _gender = g),
              child: AnimatedContainer(
                duration: MirrorDuration.fast,
                decoration: BoxDecoration(
                  color: sel ? MirrorColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(MirrorRadius.sm),
                ),
                alignment: Alignment.center,
                child: Text(g == 'male' ? '男' : '女',
                    style: MirrorText.body.copyWith(
                      color: sel ? MirrorColors.text1 : MirrorColors.text3,
                      fontWeight: sel ? FontWeight.w500 : FontWeight.w300,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _gender = 'female';

  Widget _activitySection() {
    final types = [
      (WorkoutType.strength, '力量'), (WorkoutType.cardio, '有氧'),
      (WorkoutType.hiit, 'HIIT'),    (WorkoutType.walk, '步行'),
      (WorkoutType.yoga, '瑜伽'),    (WorkoutType.rest, '休息日'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("TODAY'S ACTIVITY", style: MirrorText.overline),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: types.map((t) {
        final sel = _workout == t.$1;
        return GestureDetector(
          onTap: () => setState(() => _workout = t.$1),
          child: AnimatedContainer(
            duration: MirrorDuration.fast,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: sel ? MirrorColors.text1 : MirrorColors.bg2,
              borderRadius: BorderRadius.circular(MirrorRadius.full),
            ),
            child: Text(t.$2,
                style: MirrorText.bodyS.copyWith(
                    color: sel ? MirrorColors.bg : MirrorColors.text2)),
          ),
        );
      }).toList()),

      if (_workout != WorkoutType.rest) ...[
        const SizedBox(height: 20),
        _Row(label: '时长',
            value: _duration > 0 ? '$_duration' : null, unit: 'min',
            onTap: () => _int('训练时长 (min)', 5, 240, _duration > 0 ? _duration : 45,
                (v) => setState(() => _duration = v))),
        const SizedBox(height: 14),
        Row(children: [
          Text('强度', style: MirrorText.body),
          const Spacer(),
          ...Intensity.values.map((iv) {
            final lbl = {Intensity.low:'轻',Intensity.medium:'中',Intensity.high:'强'}[iv]!;
            final sel = _intensity == iv;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () => setState(() => _intensity = iv),
                child: AnimatedContainer(
                  duration: MirrorDuration.fast,
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: sel ? MirrorColors.text1 : MirrorColors.bg2,
                    borderRadius: BorderRadius.circular(MirrorRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: Text(lbl, style: MirrorText.bodyS.copyWith(
                      color: sel ? MirrorColors.bg : MirrorColors.text2)),
                ),
              ),
            );
          }),
        ]),
      ],
    ]);
  }

  Widget _cta() => Column(children: [
    Row(children: List.generate(3, (i) => Expanded(
      child: Container(
        height: 2, margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
        decoration: BoxDecoration(
          color: i < 2 ? MirrorColors.text1 : MirrorColors.divider,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    ))),
    const SizedBox(height: 20),
    GestureDetector(
      onTapDown: (_) => setState(() => _ctaPressed = true),
      onTapUp: (_) => setState(() => _ctaPressed = false),
      onTapCancel: () => setState(() => _ctaPressed = false),
      child: AnimatedScale(
        scale: (_ctaPressed && _weight > 0 && !_loading) ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: MirrorCurve.snap,
        child: ElevatedButton(
          onPressed: (_weight > 0 && !_loading) ? _submit : null,
          child: _loading
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: MirrorColors.bg, strokeWidth: 1.5))
              : const Text('生成角色'),
        ),
      ),
    ),
  ]);

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final userId = await AuthApi.instance.getUserId() ?? '';
      final prefs  = await SharedPreferences.getInstance();
      final gender = prefs.getString('mirror_gender') ?? 'male';
      final height = prefs.getDouble('mirror_height') ?? 170;
      final id     = DateTime.now().millisecondsSinceEpoch.toString();

      final body = BodyData(
        id: id, userId: userId,
        date: DateTime.now(), weightKg: _weight,
        bodyFatPct: _hasBf ? _bodyFat : null,
        waistCm: _hasWaist ? _waist : null,
      );
      final params = AvatarParams.fromBodyData(body,
          heightCm: height, gender: gender);
      final activity = _workout != WorkoutType.rest
          ? ActivityData(id: id, userId: userId, date: DateTime.now(),
              workoutType: _workout,
              durationMin: _duration > 0 ? _duration : null,
              intensity: _intensity)
          : null;

      final session = SessionRecord(
        id: id, userId: userId, createdAt: DateTime.now(),
        bodyData: body, avatarParams: params, activityData: activity,
      );
      final saved = await SessionApi.instance.create(session);
      if (!mounted) return;
      context.push('${MirrorRoute.result}?id=${saved.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e'), backgroundColor: MirrorColors.text1));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _dec(String lbl, double mn, double mx, double cur,
      double step, ValueChanged<double> cb) async {
    double val = cur;
    final count = ((mx - mn) / step).round() + 1;
    final init  = ((cur - mn) / step).round().clamp(0, count - 1);
    await _sheet(lbl, CupertinoPicker(
      itemExtent: 40,
      scrollController: FixedExtentScrollController(initialItem: init),
      onSelectedItemChanged: (i) => val = mn + i * step,
      children: List.generate(count, (i) => Center(child: Text(
          (mn + i * step).toStringAsFixed(step < 1 ? 1 : 0),
          style: MirrorText.body.copyWith(color: MirrorColors.text1)))),
    ), () => cb(val));
  }

  Future<void> _int(String lbl, int mn, int mx, int cur,
      ValueChanged<int> cb) async {
    int val = cur;
    await _sheet(lbl, CupertinoPicker(
      itemExtent: 40,
      scrollController: FixedExtentScrollController(initialItem: cur - mn),
      onSelectedItemChanged: (i) => val = mn + i,
      children: List.generate(mx - mn + 1, (i) => Center(child: Text(
          '${mn + i}',
          style: MirrorText.body.copyWith(color: MirrorColors.text1)))),
    ), () => cb(val));
  }

  Future<void> _sheet(String lbl, Widget picker, VoidCallback onOk) =>
      showCupertinoModalPopup(context: context, builder: (ctx) =>
          Container(height: 280, color: MirrorColors.surface, child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              CupertinoButton(
                child: Text('取消',
                    style: MirrorText.body.copyWith(color: MirrorColors.text3)),
                onPressed: () => Navigator.pop(ctx)),
              Text(lbl, style: MirrorText.bodyS.copyWith(color: MirrorColors.text2)),
              CupertinoButton(
                child: Text('确认', style: MirrorText.body.copyWith(
                    color: MirrorColors.text1, fontWeight: FontWeight.w500)),
                onPressed: () { onOk(); Navigator.pop(ctx); }),
            ]),
            Expanded(child: picker),
          ])));

  String _dayLabel() {
    final n = DateTime.now();
    return 'DAY ${n.difference(DateTime(n.year, 1, 1)).inDays + 1}'
        '  ·  ${n.year}.${n.month.toString().padLeft(2,'0')}'
        '.${n.day.toString().padLeft(2,'0')}';
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.unit,
      required this.onTap, this.isLast = false});
  final String label; final String? value;
  final String unit; final VoidCallback onTap; final bool isLast;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap, behavior: HitTestBehavior.opaque,
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(children: [
          Text(label, style: MirrorText.body),
          const Spacer(),
          if (value != null) ...[
            Text(value!, style: MirrorText.displayMd.copyWith(fontSize: 24)),
            const SizedBox(width: 3),
            Text(unit, style: MirrorText.unit),
          ] else
            Text('—', style: MirrorText.body.copyWith(color: MirrorColors.text3)),
        ]),
      ),
      if (!isLast) const Divider(color: MirrorColors.divider, thickness: 0.5, height: 0),
    ]),
  );
}
