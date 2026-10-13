import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/design_tokens.dart';
import '../../features/home/home_design.dart';

class RootShell extends StatelessWidget {
  const RootShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabItem(label: 'MIRROR', labelEn: 'Mirror', route: '/'),
    _TabItem(label: 'COACH',  labelEn: 'Coach',  route: '/coach'),
    _TabItem(label: 'ME',     labelEn: 'Me',     route: '/me'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx    = location.startsWith('/coach') ? 1
                 : location.startsWith('/me')    ? 2
                 : 0;
    final isHome = location == '/';

    return Scaffold(
      // HomeScreen 是深色沉浸式页面，背景跟随切换
      backgroundColor: isHome ? kHomeBg : MirrorColors.bg,
      body: child,
      bottomNavigationBar: _MirrorTabBar(
        currentIndex: idx,
        tabs: _tabs,
        isDark: isHome,
        onTap: (i) => context.go(_tabs[i].route),
      ),
    );
  }
}

class _TabItem {
  final String label, labelEn, route;
  const _TabItem(
      {required this.label, required this.labelEn, required this.route});
}

class _MirrorTabBar extends StatelessWidget {
  const _MirrorTabBar({
    required this.currentIndex,
    required this.tabs,
    required this.isDark,
    required this.onTap,
  });
  final int currentIndex;
  final List<_TabItem> tabs;
  final bool isDark;
  final ValueChanged<int> onTap;

  // 深色（HomeScreen）主题颜色
  static const _darkBg       = kHomeBg;
  static const _darkBorder   = kBorderColor;
  static const _darkActive   = kGold;
  static const _darkInactive = kTextDim;

  // 浅色（其余页面）主题颜色
  static const _lightBg       = MirrorColors.bg;
  static const _lightBorder   = MirrorColors.divider;
  static const _lightActive   = MirrorColors.text1;
  static const _lightInactive = MirrorColors.text3;

  @override
  Widget build(BuildContext context) {
    final bg       = isDark ? _darkBg       : _lightBg;
    final border   = isDark ? _darkBorder   : _lightBorder;
    final active   = isDark ? _darkActive   : _lightActive;
    final inactive = isDark ? _darkInactive : _lightInactive;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: MirrorDuration.fast,
                        width: 20,
                        height: 2,
                        decoration: BoxDecoration(
                          color: selected ? active : Colors.transparent,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tabs[i].label,
                        style: MirrorText.label.copyWith(
                          color: selected ? active : inactive,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
