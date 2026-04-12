import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/router/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int    _step         = 0;
  bool   _goingForward = true;
  String _gender  = 'male';
  double _height  = 170;
  int    _age     = 25;
  bool   _saving  = false;

  static const _steps = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MirrorColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar（AnimatedContainer 填充）──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  MirrorSpacing.pagePad, 20, MirrorSpacing.pagePad, 0),
              child: Row(
                children: List.generate(_steps, (i) => Expanded(
                  child: AnimatedContainer(
                    duration: MirrorDuration.normal,
                    curve: MirrorCurve.snap,
                    height: 2,
                    margin: EdgeInsets.only(right: i < _steps - 1 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: i <= _step
                          ? MirrorColors.text1 : MirrorColors.divider,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                )),
              ),
            ),

            // ── 步骤内容（方向感知 AnimatedSwitcher）──────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: MirrorDuration.slow,
                switchInCurve: MirrorCurve.pageSlide,
                switchOutCurve: MirrorCurve.pageSlide,
                transitionBuilder: (child, animation) {
                  final slideIn = Tween(
                    begin: Offset(_goingForward ? 0.08 : -0.08, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slideIn,
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildStep(),
                ),
              ),
            ),

            _buildNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    if (_step == 0) return _stepOne();
    return _stepTwo();
  }

  Widget _stepOne() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
        MirrorSpacing.pagePad, 36, MirrorSpacing.pagePad, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 入场错位
      const Text('ABOUT YOU', style: MirrorText.overline)
          .animate().fadeIn(duration: const Duration(milliseconds: 400), curve: MirrorCurve.enter),
      const SizedBox(height: 12),
      Text.rich(TextSpan(style: MirrorText.title, children: [
        const TextSpan(text: '告诉我\n你的'),
        TextSpan(text: '基本信息',
            style: MirrorText.title.copyWith(fontStyle: FontStyle.italic)),
      ]))
      .animate(delay: const Duration(milliseconds: 80))
      .fadeIn(duration: MirrorDuration.slow, curve: MirrorCurve.enter)
      .slideY(begin: 0.06, end: 0, duration: MirrorDuration.slow, curve: MirrorCurve.enter),
      const SizedBox(height: 36),

      // Gender toggle
      Container(
        height: 44,
        decoration: BoxDecoration(
            color: MirrorColors.bg2,
            borderRadius: BorderRadius.circular(MirrorRadius.md)),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: ['male', 'female'].map((g) {
            final sel = _gender == g;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = g),
                child: AnimatedContainer(
                  duration: MirrorDuration.fast,
                  curve: MirrorCurve.snap,
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
      )
      .animate(delay: const Duration(milliseconds: 160))
      .fadeIn(duration: const Duration(milliseconds: 400), curve: MirrorCurve.enter)
      .slideY(begin: 0.05, end: 0, duration: const Duration(milliseconds: 400), curve: MirrorCurve.enter),
      const SizedBox(height: 8),

      _pickRow(label: '年龄', value: '$_age 岁',
          onTap: () => _pickInt('年龄', 10, 80, _age,
              (v) => setState(() => _age = v)))
      .animate(delay: const Duration(milliseconds: 240))
      .fadeIn(duration: const Duration(milliseconds: 400), curve: MirrorCurve.enter),

      _pickRow(label: '身高', value: '${_height.toStringAsFixed(0)} cm', isLast: true,
          onTap: () => _pickDec('身高 (cm)', 130, 220, _height, 0.5,
              (v) => setState(() => _height = v)))
      .animate(delay: const Duration(milliseconds: 320))
      .fadeIn(duration: const Duration(milliseconds: 400), curve: MirrorCurve.enter),
    ]),
  );

  Widget _stepTwo() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
        MirrorSpacing.pagePad, 36, MirrorSpacing.pagePad, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('FINAL STEP', style: MirrorText.overline)
          .animate().fadeIn(duration: const Duration(milliseconds: 400), curve: MirrorCurve.enter),
      const SizedBox(height: 12),
      Text.rich(TextSpan(style: MirrorText.title, children: [
        const TextSpan(text: '你的\n'),
        TextSpan(text: '目标',
            style: MirrorText.title.copyWith(fontStyle: FontStyle.italic)),
      ]))
      .animate(delay: const Duration(milliseconds: 80))
      .fadeIn(duration: MirrorDuration.slow, curve: MirrorCurve.enter)
      .slideY(begin: 0.06, end: 0, duration: MirrorDuration.slow, curve: MirrorCurve.enter),
      const SizedBox(height: 36),
      ...[
        ('lose_fat',     '减脂',   '减少体脂，提升体型'),
        ('build_muscle', '增肌',   '增加肌肉量，提升力量'),
        ('recomp',       '塑形',   '减脂增肌同步进行'),
        ('health',       '健康管理','保持健康，改善体能'),
      ].asMap().entries.map((e) {
        final i    = e.key;
        final item = e.value;
        return _GoalCard(
          key: ValueKey(item.$1),
          label: item.$2,
          sub:   item.$3,
          isLast: i == 3,
        )
        .animate(delay: Duration(milliseconds: 160 + i * 80))
        .fadeIn(duration: const Duration(milliseconds: 350), curve: MirrorCurve.enter)
        .slideY(begin: 0.04, end: 0, duration: const Duration(milliseconds: 350), curve: MirrorCurve.enter);
      }),
    ]),
  );

  Widget _pickRow({
    required String label, required String value,
    required VoidCallback onTap, bool isLast = false,
  }) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(children: [
          Text(label, style: MirrorText.body),
          const Spacer(),
          Text(value,
              style: MirrorText.displayMd.copyWith(
                  fontSize: 22, color: MirrorColors.text1)),
        ]),
      ),
      if (!isLast) const Divider(),
    ]),
  );

  Widget _buildNav() => Padding(
    padding: const EdgeInsets.fromLTRB(
        MirrorSpacing.pagePad, 16, MirrorSpacing.pagePad, 32),
    child: Row(children: [
      if (_step > 0) ...[
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() { _goingForward = false; _step--; });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: MirrorColors.divider, width: 0.5),
              minimumSize: const Size(0, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MirrorRadius.lg)),
            ),
            child: Text('返回',
                style: MirrorText.button.copyWith(color: MirrorColors.text2)),
          ),
        ),
        const SizedBox(width: 12),
      ],
      Expanded(
        flex: 2,
        child: ElevatedButton(
          onPressed: _saving ? null : _next,
          child: _saving
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: MirrorColors.bg, strokeWidth: 1.5))
              : Text(_step < _steps - 1 ? '下一步' : '开始使用'),
        ),
      ),
    ]),
  );

  Future<void> _next() async {
    if (_step < _steps - 1) {
      setState(() { _goingForward = true; _step++; });
      return;
    }
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mirror_onboarded', true);
    await prefs.setString('mirror_gender', _gender);
    await prefs.setDouble('mirror_height', _height);
    await prefs.setInt('mirror_age', _age);
    if (!mounted) return;
    context.go(MirrorRoute.home);
  }

  Future<void> _pickInt(String label, int min, int max, int cur,
      ValueChanged<int> cb) async {
    int val = cur;
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => _Sheet(
        label: label,
        child: CupertinoPicker(
          itemExtent: 40,
          scrollController: FixedExtentScrollController(initialItem: cur - min),
          onSelectedItemChanged: (i) => val = min + i,
          children: List.generate(max - min + 1, (i) =>
              Center(child: Text('${min + i}',
                  style: MirrorText.body.copyWith(color: MirrorColors.text1)))),
        ),
        onConfirm: () => cb(val),
      ),
    );
  }

  Future<void> _pickDec(String label, double min, double max, double cur,
      double step, ValueChanged<double> cb) async {
    double val = cur;
    final count = ((max - min) / step).round() + 1;
    final init  = ((cur - min) / step).round().clamp(0, count - 1);
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => _Sheet(
        label: label,
        child: CupertinoPicker(
          itemExtent: 40,
          scrollController: FixedExtentScrollController(initialItem: init),
          onSelectedItemChanged: (i) => val = min + i * step,
          children: List.generate(count, (i) =>
              Center(child: Text((min + i * step).toStringAsFixed(step < 1 ? 1 : 0),
                  style: MirrorText.body.copyWith(color: MirrorColors.text1)))),
        ),
        onConfirm: () => cb(val),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    super.key, required this.label, required this.sub, this.isLast = false});
  final String label, sub;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: MirrorText.body.copyWith(
              color: MirrorColors.text1, fontWeight: FontWeight.w400)),
          const SizedBox(height: 2),
          Text(sub, style: MirrorText.caption),
        ]),
        const Spacer(),
        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: MirrorColors.text3),
      ]),
    ),
    if (!isLast) const Divider(),
  ]);
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.label, required this.child, required this.onConfirm});
  final String label;
  final Widget child;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Container(
    height: 280,
    color: MirrorColors.surface,
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        CupertinoButton(
          child: Text('取消', style: MirrorText.body.copyWith(color: MirrorColors.text3)),
          onPressed: () => Navigator.pop(context),
        ),
        Text(label, style: MirrorText.bodyS.copyWith(color: MirrorColors.text2)),
        CupertinoButton(
          child: Text('确认', style: MirrorText.body.copyWith(
              color: MirrorColors.text1, fontWeight: FontWeight.w500)),
          onPressed: () { onConfirm(); Navigator.pop(context); },
        ),
      ]),
      Expanded(child: child),
    ]),
  );
}
