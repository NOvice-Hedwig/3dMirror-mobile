import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Minimal scaffold used by all feature screens.
/// Handles safe area, background colour, and optional back button.
class MirrorScaffold extends StatelessWidget {
  const MirrorScaffold({
    super.key,
    required this.child,
    this.showBack = false,
    this.onBack,
    this.floatingButton,
  });

  final Widget      child;
  final bool        showBack;
  final VoidCallback? onBack;
  final Widget?     floatingButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:    MirrorColors.bg,
      extendBodyBehindAppBar: true,
      appBar: showBack
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation:        0,
              leading: GestureDetector(
                onTap: onBack ?? () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.only(left: MirrorSpacing.md),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: MirrorColors.text3),
                ),
              ),
            )
          : null,
      body: child,
      floatingActionButton: floatingButton,
    );
  }
}

/// Full-screen loading overlay
class MirrorLoader extends StatelessWidget {
  const MirrorLoader({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(
          color: MirrorColors.text1, strokeWidth: 1),
      if (message != null) ...[
        const SizedBox(height: 16),
        Text(message!, style: MirrorText.caption),
      ],
    ]),
  );
}

/// Empty state widget
class MirrorEmpty extends StatelessWidget {
  const MirrorEmpty({
    super.key, required this.title,
    this.subtitle, this.action, this.actionLabel,
  });
  final String    title;
  final String?   subtitle;
  final VoidCallback? action;
  final String?   actionLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(MirrorSpacing.xl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(title,
            style: MirrorText.body.copyWith(color: MirrorColors.text2),
            textAlign: TextAlign.center),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!,
              style: MirrorText.caption, textAlign: TextAlign.center),
        ],
        if (action != null && actionLabel != null) ...[
          const SizedBox(height: 24),
          ElevatedButton(onPressed: action, child: Text(actionLabel!)),
        ],
      ]),
    ),
  );
}
