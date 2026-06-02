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
  bool   _saving       = false;

  // Step 0 — consent
  bool _termsAccepted   = false;
  bool _privacyAccepted = false;

  // Step 1 — basic info
  String _gender = 'female';
  int    _age    = 25;
  double _height = 165;
  double _weight = 60;

  // Step 2 — goal
  String _goal = '';

  // Animation state
  bool _ctaPressed = false;

  static const _steps = 3;

  bool get _canProceed {
    if (_step == 0) return _termsAccepted && _privacyAccepted;
    if (_step == 2) return _goal.isNotEmpty;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MirrorColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildMasthead(),
            _buildProgressBar(),
            Expanded(
              child: AnimatedSwitcher(
                duration: MirrorDuration.slow,
                switchInCurve: MirrorCurve.pageSlide,
                switchOutCurve: MirrorCurve.pageSlide,
                transitionBuilder: (child, animation) {
                  final slide = Tween(
                    begin: Offset(_goingForward ? 0.08 : -0.08, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
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

  // ── Masthead ─────────────────────────────────────────────────────────────

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

  // ── Progress bar ──────────────────────────────────────────────────────────

  Widget _buildProgressBar() => Padding(
    padding: const EdgeInsets.fromLTRB(
        MirrorSpacing.pagePad, 12, MirrorSpacing.pagePad, 0),
    child: Row(
      children: List.generate(_steps, (i) => Expanded(
        child: AnimatedContainer(
          duration: MirrorDuration.normal,
          curve: MirrorCurve.snap,
          height: 2,
          margin: EdgeInsets.only(right: i < _steps - 1 ? 4 : 0),
          decoration: BoxDecoration(
            color: i <= _step ? MirrorColors.text1 : MirrorColors.divider,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      )),
    ),
  );

  // ── Step router ───────────────────────────────────────────────────────────

  Widget _buildStep() {
    switch (_step) {
      case 0:  return _stepConsent();
      case 1:  return _stepBasicInfo();
      default: return _stepGoal();
    }
  }

  // ── Step 0: Legal Consent ─────────────────────────────────────────────────

  Widget _stepConsent() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
        MirrorSpacing.pagePad, 32, MirrorSpacing.pagePad, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('LEGAL & PRIVACY', style: MirrorText.overline)
          .animate().fadeIn(duration: const Duration(milliseconds: 400), curve: MirrorCurve.enter),
      const SizedBox(height: 12),
      Text.rich(TextSpan(style: MirrorText.title, children: [
        const TextSpan(text: '条款与\n'),
        TextSpan(text: '隐私协议',
            style: MirrorText.title.copyWith(fontStyle: FontStyle.italic)),
      ]))
      .animate(delay: 80.ms)
      .fadeIn(duration: MirrorDuration.slow, curve: MirrorCurve.enter)
      .slideY(begin: 0.06, end: 0, duration: MirrorDuration.slow, curve: MirrorCurve.enter),
      const SizedBox(height: 28),

      Text(
        '在开始使用 3D Mirror 之前，请确认以下内容：',
        style: MirrorText.body,
      )
      .animate(delay: 160.ms)
      .fadeIn(duration: 400.ms, curve: MirrorCurve.enter),
      const SizedBox(height: 16),

      ..._consentBullets.asMap().entries.map((e) =>
        _BulletItem(text: e.value)
        .animate(delay: Duration(milliseconds: 240 + e.key * 60))
        .fadeIn(duration: 350.ms, curve: MirrorCurve.enter)
        .slideY(begin: 0.04, end: 0, duration: 350.ms, curve: MirrorCurve.enter),
      ),
      const SizedBox(height: 28),

      _ConsentRow(
        label: '我已阅读并同意《服务条款》',
        sublabel: 'Terms of Service',
        value: _termsAccepted,
        onChanged: (v) => setState(() => _termsAccepted = v),
      )
      .animate(delay: 480.ms)
      .fadeIn(duration: 350.ms, curve: MirrorCurve.enter),
      const SizedBox(height: 12),

      _ConsentRow(
        label: '我已阅读并同意《隐私政策》',
        sublabel: 'Privacy Policy — AI Data Usage',
        value: _privacyAccepted,
        onChanged: (v) => setState(() => _privacyAccepted = v),
      )
      .animate(delay: 540.ms)
      .fadeIn(duration: 350.ms, curve: MirrorCurve.enter),
    ]),
  );

  static const _consentBullets = [
    '你的身体数据（身高、体重、三围）将用于生成专属 3D 体型模型',
    '体型照片将上传至服务器，由 AI 分析体型比例，仅用于建模，不作其他用途',
    '所有数据经过加密存储，我们不会出售或共享你的个人信息',
    'AI 预测结果仅供参考，不构成医疗建议',
  ];

  // ── Step 1: Basic Info ────────────────────────────────────────────────────

  Widget _stepBasicInfo() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
        MirrorSpacing.pagePad, 32, MirrorSpacing.pagePad, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ABOUT YOU', style: MirrorText.overline)
          .animate().fadeIn(duration: 400.ms, curve: MirrorCurve.enter),
      const SizedBox(height: 12),
      Text.rich(TextSpan(style: MirrorText.title, children: [
        const TextSpan(text: '告诉我\n你的'),
        TextSpan(text: '基本信息',
            style: MirrorText.title.copyWith(fontStyle: FontStyle.italic)),
      ]))
      .animate(delay: 80.ms)
      .fadeIn(duration: MirrorDuration.slow, curve: MirrorCurve.enter)
      .slideY(begin: 0.06, end: 0, duration: MirrorDuration.slow, curve: MirrorCurve.enter),
      const SizedBox(height: 32),

      // Gender toggle
      Container(
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
                  curve: MirrorCurve.snap,
                  decoration: BoxDecoration(
                    color: sel ? MirrorColors.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(MirrorRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: Text(g == 'female' ? '女' : '男',
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
      .animate(delay: 160.ms)
      .fadeIn(duration: 400.ms, curve: MirrorCurve.enter)
      .slideY(begin: 0.05, end: 0, duration: 400.ms, curve: MirrorCurve.enter),
      const SizedBox(height: 8),

      _PickRow(label: '年龄', value: '$_age 岁',
          onTap: () => _pickInt('年龄', 10, 80, _age,
              (v) => setState(() => _age = v)))
      .animate(delay: 240.ms).fadeIn(duration: 400.ms, curve: MirrorCurve.enter),

      _PickRow(label: '身高', value: '${_height.toStringAsFixed(0)} cm',
          onTap: () => _pickDec('身高 (cm)', 130, 220, _height, 0.5,
              (v) => setState(() => _height = v)))
      .animate(delay: 320.ms).fadeIn(duration: 400.ms, curve: MirrorCurve.enter),

      _PickRow(label: '体重', value: '${_weight.toStringAsFixed(1)} kg',
          isLast: true,
          onTap: () => _pickDec('体重 (kg)', 30, 150, _weight, 0.5,
              (v) => setState(() => _weight = v)))
      .animate(delay: 400.ms).fadeIn(duration: 400.ms, curve: MirrorCurve.enter),
    ]),
  );

  // ── Step 2: Goal ──────────────────────────────────────────────────────────

  Widget _stepGoal() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
        MirrorSpacing.pagePad, 32, MirrorSpacing.pagePad, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('YOUR GOAL', style: MirrorText.overline)
          .animate().fadeIn(duration: 400.ms, curve: MirrorCurve.enter),
      const SizedBox(height: 12),
      Text.rich(TextSpan(style: MirrorText.title, children: [
        const TextSpan(text: '你的\n'),
        TextSpan(text: '目标',
            style: MirrorText.title.copyWith(fontStyle: FontStyle.italic)),
      ]))
      .animate(delay: 80.ms)
      .fadeIn(duration: MirrorDuration.slow, curve: MirrorCurve.enter)
      .slideY(begin: 0.06, end: 0, duration: MirrorDuration.slow, curve: MirrorCurve.enter),
      const SizedBox(height: 32),
      ...[
        ('lose_fat',     '减脂',   'Fat Loss — 减少体脂，提升体型'),
        ('build_muscle', '增肌',   'Muscle — 增加肌肉量，提升力量'),
        ('recomp',       '塑形',   'Recomposition — 减脂增肌同步'),
        ('health',       '健康',   'Wellness — 保持健康，改善体能'),
      ].asMap().entries.map((e) {
        final i    = e.key;
        final item = e.value;
        final selected = _goal == item.$1;
        return _GoalCard(
          key: ValueKey(item.$1),
          id: item.$1,
          label: item.$2,
          sub: item.$3,
          selected: selected,
          isLast: i == 3,
          onTap: () => setState(() => _goal = item.$1),
        )
        .animate(delay: Duration(milliseconds: 160 + i * 80))
        .fadeIn(duration: 350.ms, curve: MirrorCurve.enter)
        .slideY(begin: 0.04, end: 0, duration: 350.ms, curve: MirrorCurve.enter);
      }),
    ]),
  );

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildNav() => Padding(
    padding: const EdgeInsets.fromLTRB(
        MirrorSpacing.pagePad, 16, MirrorSpacing.pagePad, 32),
    child: Row(children: [
      if (_step > 0) ...[
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() { _goingForward = false; _step--; }),
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
        child: AnimatedOpacity(
          opacity: _canProceed ? 1.0 : 0.3,
          duration: MirrorDuration.fast,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _ctaPressed = true),
            onTapUp: (_) => setState(() => _ctaPressed = false),
            onTapCancel: () => setState(() => _ctaPressed = false),
            child: AnimatedScale(
              scale: (_ctaPressed && _canProceed) ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: MirrorCurve.snap,
              child: ElevatedButton(
                onPressed: (_canProceed && !_saving) ? _next : null,
                child: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: MirrorColors.bg, strokeWidth: 1.5))
                    : Text(_step < _steps - 1 ? '下一步' : '开始使用'),
              ),
            ),
          ),
        ),
      ),
    ]),
  );

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _next() async {
    if (_step < _steps - 1) {
      setState(() { _goingForward = true; _step++; });
      return;
    }
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mirror_onboarded', true);
    await prefs.setBool('mirror_terms_accepted', true);
    await prefs.setString('mirror_gender', _gender);
    await prefs.setInt('mirror_age', _age);
    await prefs.setDouble('mirror_height', _height);
    await prefs.setDouble('mirror_weight', _weight);
    await prefs.setString('mirror_goal', _goal);
    if (!mounted) return;
    context.go(MirrorRoute.photoCapture);
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

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 5, right: 10),
        child: Container(
          width: 4, height: 4,
          decoration: const BoxDecoration(
            color: MirrorColors.text3, shape: BoxShape.circle),
        ),
      ),
      Expanded(child: Text(text, style: MirrorText.body)),
    ]),
  );
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.label, required this.sublabel,
    required this.value, required this.onChanged,
  });
  final String label, sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    behavior: HitTestBehavior.opaque,
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AnimatedContainer(
        duration: MirrorDuration.fast,
        curve: MirrorCurve.snap,
        width: 20, height: 20,
        decoration: BoxDecoration(
          color: value ? MirrorColors.text1 : Colors.transparent,
          border: Border.all(
            color: value ? MirrorColors.text1 : MirrorColors.text3,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(MirrorRadius.sm),
        ),
        child: AnimatedScale(
          scale: value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 180),
          curve: MirrorCurve.enter,
          child: const Icon(Icons.check, size: 13, color: MirrorColors.bg),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: MirrorText.body.copyWith(
              color: MirrorColors.text1, height: 1.4)),
          const SizedBox(height: 2),
          Text(sublabel, style: MirrorText.caption),
        ]),
      ),
    ]),
  );
}

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.label, required this.value,
    required this.onTap, this.isLast = false,
  });
  final String label, value;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(children: [
          Text(label, style: MirrorText.body),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Text(
              value,
              key: ValueKey(value),
              style: MirrorText.displayMd.copyWith(
                  fontSize: 22, color: MirrorColors.text1),
            ),
          ),
        ]),
      ),
      if (!isLast) const Divider(color: MirrorColors.divider, thickness: 0.5, height: 0),
    ]),
  );
}

class _GoalCard extends StatefulWidget {
  const _GoalCard({
    super.key,
    required this.id,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
    this.isLast = false,
  });
  final String id, label, sub;
  final bool selected, isLast;
  final VoidCallback onTap;

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  bool _pressed = false;

  void _handleTap() {
    setState(() => _pressed = true);
    Future.delayed(const Duration(milliseconds: 150),
        () { if (mounted) setState(() => _pressed = false); });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _handleTap,
    behavior: HitTestBehavior.opaque,
    child: AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: MirrorCurve.snap,
      child: Column(children: [
        AnimatedContainer(
          duration: MirrorDuration.fast,
          curve: MirrorCurve.snap,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: widget.selected ? MirrorColors.text1 : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.label, style: MirrorText.body.copyWith(
                    color: widget.selected ? MirrorColors.text1 : MirrorColors.text2,
                    fontWeight: widget.selected ? FontWeight.w500 : FontWeight.w300)),
                const SizedBox(height: 2),
                Text(widget.sub, style: MirrorText.caption),
              ]),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  widget.selected
                      ? Icons.check_rounded
                      : Icons.arrow_forward_ios_rounded,
                  key: ValueKey(widget.selected),
                  size: 12,
                  color: widget.selected ? MirrorColors.text1 : MirrorColors.text3,
                ),
              ),
            ]),
          ),
        ),
        if (!widget.isLast) const Divider(color: MirrorColors.divider, thickness: 0.5, height: 0),
      ]),
    ),
  );
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
