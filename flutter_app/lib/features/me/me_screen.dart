import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/animate_widgets.dart';
import '../../services/api/auth_api.dart';

class MeScreen extends ConsumerStatefulWidget {
  const MeScreen({super.key});

  @override
  ConsumerState<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends ConsumerState<MeScreen> {
  String? _phone;
  bool    _loadingUser = true;

  static const _base = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000');

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final token = await AuthApi.instance.getToken() ?? '';
      final r = await http.get(
        Uri.parse('$_base/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) {
        final data = json.decode(r.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _phone = (data['phone'] as String?) ??
                (data['email'] as String?);
          });
        }
      }
    } catch (_) {
      // leave _phone as null, shows '—'
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  String get _maskedPhone {
    final raw = _phone;
    if (raw == null || raw.isEmpty) return '—';
    // email: mask local part except first 2 chars
    if (raw.contains('@')) {
      final parts = raw.split('@');
      final local  = parts[0];
      final domain = parts[1];
      if (local.length <= 2) return raw;
      return '${local.substring(0, 2)}****@$domain';
    }
    // phone: keep first 3 and last 2 digits, mask middle
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6) return raw;
    final visible = digits.substring(digits.length - 2);
    return '****** $visible';
  }

  Future<void> _signOut() async {
    await AuthApi.instance.signOut();
    if (mounted) context.go(MirrorRoute.auth);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MirrorColors.bg,
    body: SafeArea(
      child: Column(children: [
        _buildMasthead(),
        Expanded(child: CustomScrollView(slivers: [

          // 用户信息卡
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                MirrorSpacing.pagePad, 32,
                MirrorSpacing.pagePad, 0),
            sliver: SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: Duration.zero,
                duration: const Duration(milliseconds: 400),
                offsetY: 10,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: MirrorColors.divider, width: 0.5),
                    borderRadius:
                        BorderRadius.circular(MirrorRadius.sm),
                  ),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: MirrorColors.bg2,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: MirrorColors.divider, width: 0.5),
                      ),
                      child: const Icon(Icons.person_outline_rounded,
                          size: 20, color: MirrorColors.text3),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('3D MIRROR USER',
                            style: MirrorText.body.copyWith(
                                color: MirrorColors.text1)),
                        const SizedBox(height: 4),
                        _loadingUser
                            ? const SizedBox(
                                width: 80, height: 10,
                                child: LinearProgressIndicator(
                                  color: MirrorColors.divider,
                                  backgroundColor:
                                      MirrorColors.bg2,
                                  minHeight: 1,
                                ))
                            : Text(_maskedPhone,
                                style: MirrorText.caption),
                      ],
                    ),
                  ]),
                ),
              ),
            ),
          ),

          // 分组列表
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                MirrorSpacing.pagePad, 0,
                MirrorSpacing.pagePad, 0),
            sliver: SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                duration: const Duration(milliseconds: 400),
                offsetY: 10,
                child: Column(children: [
                  const EditorialDivider(),
                  _MeRow(
                    label: 'CHALLENGE  ·  MODE',
                    sub: '月目标 · 达成享 8 折',
                    onTap: () => context.push(MirrorRoute.challenge),
                  ),
                  _MeRow(
                    label: 'SUBSCRIPTION',
                    sub: '管理订阅',
                    onTap: () {},
                    isComingSoon: true,
                  ),
                  const EditorialDivider(),
                  _MeRow(
                    label: 'SIGN  ·  OUT',
                    sub: '',
                    onTap: _signOut,
                    isDestructive: true,
                  ),
                ]),
              ),
            ),
          ),

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
          'ME',
          style: MirrorText.overline.copyWith(
              color: MirrorColors.gold,
              fontSize: 11,
              letterSpacing: 4.0),
          textAlign: TextAlign.center,
        ),
      ),
      Container(
        height: 1.5,
        margin: const EdgeInsets.symmetric(
            horizontal: MirrorSpacing.pagePad),
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
}

// ── Me Row ────────────────────────────────────────────────────────────────────

class _MeRow extends StatelessWidget {
  const _MeRow({
    required this.label,
    required this.sub,
    required this.onTap,
    this.isComingSoon  = false,
    this.isDestructive = false,
  });

  final String       label;
  final String       sub;
  final VoidCallback onTap;
  final bool         isComingSoon;
  final bool         isDestructive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: MirrorText.overline.copyWith(
                    color: isDestructive
                        ? MirrorColors.text2
                        : MirrorColors.text1,
                  ),
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(sub, style: MirrorText.caption),
                ],
              ],
            ),
          ),
          if (isComingSoon)
            Text('SOON', style: MirrorText.caption)
          else
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: MirrorColors.text3),
        ]),
      ),
    );
  }
}
