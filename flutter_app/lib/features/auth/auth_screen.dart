import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart' show IsoCode;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/router/app_router.dart';
import '../../core/validation/login_identity.dart';
import '../../core/widgets/animate_widgets.dart';
import '../../services/api/auth_api.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final _tab = TabController(length: 2, vsync: this);
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _codeCtrl  = TextEditingController();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  bool   _codeSent    = false;
  bool   _loading     = false;
  bool   _ctaPressed  = false;
  int    _resendSecs  = 0;
  Timer? _timer;
  String? _error;

  IsoCode _country = defaultCountry();
  // Inline errors appear only after the field first loses focus or a submit attempt.
  bool _phoneTouched = false;
  bool _emailTouched = false;
  String? _sentTo;   // normalized identifier the code was sent to (E.164 or lowercased email)

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_onPhoneChanged);
    _emailCtrl.addListener(_refresh);
    _codeCtrl.addListener(_refresh);
    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus) setState(() => _phoneTouched = true);
    });
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) setState(() => _emailTouched = true);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _phoneCtrl.dispose(); _emailCtrl.dispose(); _codeCtrl.dispose();
    _phoneFocus.dispose(); _emailFocus.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _refresh() => setState(() {});

  /// A "+…" input decides the country; the picker follows it.
  void _onPhoneChanged() {
    final typed = checkPhone(_phoneCtrl.text, _country).typedCountry;
    setState(() { if (typed != null) _country = typed; });
  }

  PhoneCheck get _phoneCheck => checkPhone(_phoneCtrl.text, _country);
  String? get _emailError => emailError(_emailCtrl.text);
  bool get _isPhoneTab => _tab.index == 0;

  bool get _identifierValid => _isPhoneTab ? _phoneCheck.isValid : _emailError == null;

  /// What is sent to the backend: E.164 phone or trimmed + lowercased email.
  String get _normalizedId =>
      _isPhoneTab ? _phoneCheck.e164! : normalizeEmail(_emailCtrl.text);

  VoidCallback? get _ctaAction {
    if (_loading) return null;
    if (_codeSent) return _codeCtrl.text.length == 6 ? _verify : null;
    return _identifierValid ? _send : null;
  }

  void _submitIdentifier() {
    setState(() { if (_isPhoneTab) { _phoneTouched = true; } else { _emailTouched = true; } });
    if (_identifierValid) _send();
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
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: MirrorSpacing.pagePad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // ── 标题入场（错位 fade + slideY）──────────────────────
                      Text.rich(TextSpan(
                        style: MirrorText.title,
                        children: [
                          const TextSpan(text: '开始\n'),
                          TextSpan(text: '蜕变',
                              style: MirrorText.title.copyWith(fontStyle: FontStyle.italic)),
                        ],
                      ))
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 600), curve: MirrorCurve.enter)
                      .slideY(begin: 0.1, end: 0, duration: const Duration(milliseconds: 600), curve: MirrorCurve.enter),

                      const SizedBox(height: 8),

                      Text('你的身体，你来定义', style: MirrorText.body)
                      .animate(delay: const Duration(milliseconds: 120))
                      .fadeIn(duration: const Duration(milliseconds: 500), curve: MirrorCurve.enter)
                      .slideY(begin: 0.08, end: 0, duration: const Duration(milliseconds: 500), curve: MirrorCurve.enter),

                      // ── Editorial divider: hero zone → form zone ────────────
                      const EditorialDivider(topPad: 32, bottomPad: 24),

                      // ── Form zone label ─────────────────────────────────────
                      Text('CONTINUE WITH', style: MirrorText.overline)
                      .animate(delay: const Duration(milliseconds: 200))
                      .fadeIn(duration: const Duration(milliseconds: 400), curve: MirrorCurve.enter),

                      const SizedBox(height: 14),

                      // ── Tab bar ─────────────────────────────────────────────
                      _buildTabBar()
                      .animate(delay: const Duration(milliseconds: 280))
                      .fadeIn(duration: const Duration(milliseconds: 400), curve: MirrorCurve.enter),

                      const SizedBox(height: 24),

                      // ── Input ───────────────────────────────────────────────
                      AnimatedSwitcher(
                        duration: MirrorDuration.normal,
                        switchInCurve: MirrorCurve.enter,
                        switchOutCurve: MirrorCurve.snap,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, -0.05),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: _codeSent ? _codeField() : _identifierField(),
                      )
                      .animate(delay: const Duration(milliseconds: 400))
                      .fadeIn(duration: const Duration(milliseconds: 400), curve: MirrorCurve.enter)
                      .slideY(begin: 0.06, end: 0, duration: const Duration(milliseconds: 400), curve: MirrorCurve.enter),

                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!,
                            style: MirrorText.bodyS.copyWith(
                                color: MirrorColors.error)),
                      ],
                      const SizedBox(height: 20),

                      // ── 主 CTA ─────────────────────────────────────────────
                      GestureDetector(
                        onTapDown: (_) => setState(() => _ctaPressed = true),
                        onTapUp: (_) => setState(() => _ctaPressed = false),
                        onTapCancel: () => setState(() => _ctaPressed = false),
                        child: AnimatedScale(
                          scale: _ctaPressed && !_loading ? 0.97 : 1.0,
                          duration: const Duration(milliseconds: 120),
                          curve: MirrorCurve.snap,
                          child: ElevatedButton(
                            onPressed: _ctaAction,
                            child: _loading
                                ? const SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        color: MirrorColors.bg, strokeWidth: 1.5))
                                : Text(_codeSent ? '验证并登录' : '发送验证码'),
                          ),
                        ),
                      )
                      .animate(delay: const Duration(milliseconds: 500))
                      .fadeIn(duration: const Duration(milliseconds: 400), curve: MirrorCurve.enter)
                      .slideY(begin: 0.05, end: 0, duration: const Duration(milliseconds: 400), curve: MirrorCurve.enter),

                      const SizedBox(height: 20),

                      // ── 分隔线 + Apple（仅 iOS / macOS 显示）───────────────
                      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) ...[
                        Row(children: [
                          const Expanded(child: Divider(color: MirrorColors.divider)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR', style: MirrorText.overline),
                          ),
                          const Expanded(child: Divider(color: MirrorColors.divider)),
                        ])
                        .animate(delay: const Duration(milliseconds: 600))
                        .fadeIn(duration: const Duration(milliseconds: 350), curve: MirrorCurve.enter),

                        const SizedBox(height: 16),

                        SignInWithAppleButton(
                          onPressed: _appleSignIn,
                          style: SignInWithAppleButtonStyle.black,
                          borderRadius: const BorderRadius.all(Radius.circular(MirrorRadius.lg)),
                          height: 54,
                        )
                        .animate(delay: const Duration(milliseconds: 640))
                        .fadeIn(duration: const Duration(milliseconds: 350), curve: MirrorCurve.enter),
                      ],

                      // ── 隐私说明（链接可点击）──────────────────────────────
                      const EditorialDivider(topPad: 32, bottomPad: 20),

                      Center(
                        child: Text.rich(TextSpan(
                          style: MirrorText.caption,
                          children: [
                            const TextSpan(text: '登录即表示同意 '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: () => _openUrl('privacy'),
                                child: Text('隐私政策',
                                    style: MirrorText.caption.copyWith(
                                        decoration: TextDecoration.underline,
                                        color: MirrorColors.text2)),
                              ),
                            ),
                            const TextSpan(text: ' 和 '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: () => _openUrl('terms'),
                                child: Text('用户协议',
                                    style: MirrorText.caption.copyWith(
                                        decoration: TextDecoration.underline,
                                        color: MirrorColors.text2)),
                              ),
                            ),
                          ],
                        )),
                      )
                      .animate(delay: const Duration(milliseconds: 700))
                      .fadeIn(duration: const Duration(milliseconds: 300), curve: MirrorCurve.enter),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
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

  void _openUrl(String type) {
    // TODO: launch privacy policy / terms URL when available
  }

  Widget _buildTabBar() => Container(
    height: 40,
    decoration: BoxDecoration(
        color: MirrorColors.bg2,
        borderRadius: BorderRadius.circular(MirrorRadius.md)),
    padding: const EdgeInsets.all(3),
    child: TabBar(
      controller: _tab,
      indicator: BoxDecoration(
        color: MirrorColors.surface,
        borderRadius: BorderRadius.circular(MirrorRadius.sm),
        boxShadow: [BoxShadow(
            color: MirrorColors.text1.withValues(alpha: 0.05),
            blurRadius: 4, offset: const Offset(0, 1))],
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelStyle: MirrorText.bodyS.copyWith(
          fontWeight: FontWeight.w500, color: MirrorColors.text1),
      unselectedLabelStyle: MirrorText.bodyS.copyWith(color: MirrorColors.text3),
      onTap: (_) => setState(() {
        _codeSent = false; _sentTo = null; _error = null; _codeCtrl.clear();
      }),
      tabs: const [Tab(text: '手机号'), Tab(text: '邮箱')],
    ),
  );

  Widget _identifierField() => SizedBox(
    key: const ValueKey('identifier'),
    height: 96,   // room for the inline error under the field
    child: TabBarView(
      controller: _tab,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CountryButton(country: _country, onTap: _pickCountry),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(
                controller: _phoneCtrl,
                focusNode: _phoneFocus,
                placeholder: '手机号',
                keyboardType: TextInputType.phone,
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'[+\d\s\-()]'))],
                errorText: _phoneTouched ? _phoneCheck.error : null,
                onSubmitted: (_) => _submitIdentifier(),
              ),
            ),
          ],
        ),
        _Field(
          controller: _emailCtrl,
          focusNode: _emailFocus,
          placeholder: 'your@email.com',
          keyboardType: TextInputType.emailAddress,
          errorText: _emailTouched ? _emailError : null,
          onSubmitted: (_) => _submitIdentifier(),
        ),
      ],
    ),
  );

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<IsoCode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MirrorColors.bg,
      builder: (_) => const _CountryPickerSheet(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _country = picked;
      // A "+…" number that contradicts the new choice would snap the picker back; drop the prefix.
      if (_phoneCtrl.text.trimLeft().startsWith('+')) _phoneCtrl.clear();
    });
  }

  Widget _codeField() => Column(
    key: const ValueKey('code'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Field(controller: _codeCtrl, placeholder: '6位验证码',
          keyboardType: TextInputType.number, maxLength: 6, autofocus: true,
          formatters: [FilteringTextInputFormatter.digitsOnly]),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: _resendSecs == 0 ? _send : null,
        child: Text(
          _resendSecs > 0 ? '${_resendSecs}S  ·  重发' : '重新发送',
          style: MirrorText.overline.copyWith(
            color: _resendSecs > 0 ? MirrorColors.text3 : MirrorColors.text2,
            decoration: _resendSecs == 0 ? TextDecoration.underline : null,
            decorationColor: MirrorColors.text2,
          ),
        ),
      ),
    ],
  );

  Future<void> _send() async {
    // Resend reuses the destination the first code went to.
    final to = _codeSent ? _sentTo! : _normalizedId;
    setState(() { _loading = true; _error = null; });
    try {
      if (_isPhoneTab) {
        await AuthApi.instance.sendPhoneOtp(to);
      } else {
        await AuthApi.instance.sendEmailOtp(to);
      }
      if (!mounted) return;
      setState(() { _codeSent = true; _sentTo = to; });
      _startTimer();
    } on AuthException catch (e) {
      if (mounted) setState(() { _error = e.message; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _verify() async {
    if (_codeCtrl.text.length != 6 || _sentTo == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = _isPhoneTab
          ? await AuthApi.instance.verifyPhoneOtp(_sentTo!, _codeCtrl.text)
          : await AuthApi.instance.verifyEmailOtp(_sentTo!, _codeCtrl.text);
      await AuthApi.instance.persistToken(res.token, res.userId);
      if (!mounted) return;
      context.go(res.isNewUser ? MirrorRoute.onboarding : MirrorRoute.home);
    } on AuthException catch (e) {
      setState(() { _error = e.message; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _appleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await SignInWithApple.getAppleIDCredential(scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ]);
      final name = [cred.givenName, cred.familyName]
          .where((s) => s?.isNotEmpty == true).join(' ');
      final res = await AuthApi.instance.appleSignIn(
        identityToken: cred.identityToken ?? '',
        fullName: name.isEmpty ? null : name,
      );
      await AuthApi.instance.persistToken(res.token, res.userId);
      if (!mounted) return;
      context.go(res.isNewUser ? MirrorRoute.onboarding : MirrorRoute.home);
    } on AuthorizationErrorCode catch (_) {
      // user cancelled
    } on AuthException catch (e) {
      setState(() { _error = e.message; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _startTimer() {
    _resendSecs = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { _resendSecs--; });
      if (_resendSecs == 0) t.cancel();
    });
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller, required this.placeholder,
    this.keyboardType, this.formatters, this.maxLength,
    this.autofocus = false, this.focusNode, this.errorText, this.onSubmitted,
  });
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final int? maxLength;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    focusNode: focusNode,
    keyboardType: keyboardType,
    inputFormatters: formatters,
    maxLength: maxLength,
    autofocus: autofocus,
    textInputAction: onSubmitted != null ? TextInputAction.done : null,
    onSubmitted: onSubmitted,
    style: MirrorText.body.copyWith(
      color: MirrorColors.text1,
      fontSize: 16,
      fontWeight: FontWeight.w300,
    ),
    decoration: InputDecoration(
      hintText: placeholder,
      counterText: '',
      errorText: errorText,
      errorStyle: MirrorText.bodyS.copyWith(color: MirrorColors.error),
      errorMaxLines: 2,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
    ),
  );
}

/// Flag + dialing code; opens the country picker.
class _CountryButton extends StatelessWidget {
  const _CountryButton({required this.country, required this.onTap});
  final IsoCode country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(MirrorRadius.sm),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(flagEmoji(country), style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text('+${dialCode(country)}',
            style: MirrorText.body.copyWith(color: MirrorColors.text1, fontSize: 16)),
        const Icon(Icons.expand_more, size: 18, color: MirrorColors.text3),
      ]),
    ),
  );
}

/// Searchable list of all countries: Chinese name, English name, ISO code or dialing code.
class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();
  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = searchCountries(_query);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                MirrorSpacing.pagePad, 20, MirrorSpacing.pagePad, 8),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              style: MirrorText.body.copyWith(color: MirrorColors.text1),
              decoration: InputDecoration(
                hintText: '搜索国家/地区或区号',
                prefixIcon: const Icon(Icons.search, color: MirrorColors.text3),
                hintStyle: MirrorText.body.copyWith(color: MirrorColors.text3),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(child: Text('没有找到匹配的国家/地区', style: MirrorText.caption))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (_, i) {
                      final iso = results[i];
                      return ListTile(
                        leading: Text(flagEmoji(iso), style: const TextStyle(fontSize: 22)),
                        title: Text(countryNameZh(iso),
                            style: MirrorText.body.copyWith(color: MirrorColors.text1)),
                        subtitle: Text(countryNameEn(iso), style: MirrorText.caption),
                        trailing: Text('+${dialCode(iso)}',
                            style: MirrorText.bodyS.copyWith(color: MirrorColors.text2)),
                        onTap: () => Navigator.of(context).pop(iso),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
