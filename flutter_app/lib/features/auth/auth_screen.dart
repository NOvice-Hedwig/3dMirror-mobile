import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/router/app_router.dart';
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

  bool   _codeSent    = false;
  bool   _loading     = false;
  bool   _ctaPressed  = false;
  int    _resendSecs  = 0;
  Timer? _timer;
  String? _error;

  @override
  void dispose() {
    _tab.dispose();
    _phoneCtrl.dispose(); _emailCtrl.dispose(); _codeCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _id => _tab.index == 0
      ? _phoneCtrl.text.trim() : _emailCtrl.text.trim();

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
                            onPressed: _loading ? null : (_codeSent ? _verify : _send),
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
      onTap: (_) => setState(() { _codeSent = false; _error = null; _codeCtrl.clear(); }),
      tabs: const [Tab(text: '手机号'), Tab(text: '邮箱')],
    ),
  );

Widget _identifierField() => SizedBox(
  key: const ValueKey('identifier'),
  height: 72,
  child: TabBarView(
    controller: _tab,
    children: [
      _Field(
        controller: _phoneCtrl,
        placeholder: '+86 138 0000 0000',
        keyboardType: TextInputType.phone,
        formatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[+\d\s\-]')),
        ],
      ),
      _Field(
        controller: _emailCtrl,
        placeholder: 'your@email.com',
        keyboardType: TextInputType.emailAddress,
      ),
    ],
  ),
);

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
    if (_id.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (_tab.index == 0) {
        await AuthApi.instance.sendPhoneOtp(_id);
      } else {
        await AuthApi.instance.sendEmailOtp(_id);
      }
      setState(() { _codeSent = true; });
      _startTimer();
    } on AuthException catch (e) {
      setState(() { _error = e.message; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _verify() async {
    if (_codeCtrl.text.length != 6) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = _tab.index == 0
          ? await AuthApi.instance.verifyPhoneOtp(_id, _codeCtrl.text)
          : await AuthApi.instance.verifyEmailOtp(_id, _codeCtrl.text);
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
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final int? maxLength;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: formatters,
    maxLength: maxLength,
    autofocus: autofocus,
    style: MirrorText.body.copyWith(
      color: MirrorColors.text1,
      fontSize: 16,
      fontWeight: FontWeight.w300,
    ),
    decoration: InputDecoration(
      hintText: placeholder,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
    ),
  );
}
