import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/design_tokens.dart';

class RootShell extends StatelessWidget {
  const RootShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabItem(label: '历史', labelEn: 'History', route: '/'),
    _TabItem(label: '记录', labelEn: 'Input',   route: '/input'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = location.startsWith('/input') ? 1 : 0;

    return Scaffold(
      backgroundColor: MirrorColors.bg,
      body: child,
      bottomNavigationBar: _MirrorTabBar(
        currentIndex: idx,
        tabs: _tabs,
        onTap: (i) => context.go(_tabs[i].route),
      ),
    );
  }
}

class _TabItem {
  final String label, labelEn, route;
  const _TabItem({required this.label, required this.labelEn, required this.route});
}

class _MirrorTabBar extends StatelessWidget {
  const _MirrorTabBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });
  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: MirrorColors.bg,
        border: Border(top: BorderSide(color: MirrorColors.divider, width: 0.5)),
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
                        width: 20, height: 2,
                        decoration: BoxDecoration(
                          color: selected
                              ? MirrorColors.text1
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tabs[i].label,
                        style: MirrorText.label.copyWith(
                          color: selected
                              ? MirrorColors.text1
                              : MirrorColors.text3,
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
