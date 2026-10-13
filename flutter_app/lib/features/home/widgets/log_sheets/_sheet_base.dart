import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_tokens.dart';

// ── 共用输入框装饰 ──────────────────────────────────────────────────────────────
InputDecoration sheetInputDecoration(String label, {String? hint}) =>
    InputDecoration(
      labelText: label,
      hintText:  hint,
      labelStyle: MirrorText.caption,
      hintStyle:  MirrorText.caption,
      filled:     true,
      fillColor:  MirrorColors.bg2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MirrorRadius.sm),
        borderSide: const BorderSide(color: MirrorColors.divider, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MirrorRadius.sm),
        borderSide: const BorderSide(color: MirrorColors.divider, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MirrorRadius.sm),
        borderSide: const BorderSide(color: MirrorColors.text1, width: 0.5),
      ),
    );

// ── Sheet 骨架 ─────────────────────────────────────────────────────────────────
class SheetBase extends StatelessWidget {
  const SheetBase({
    super.key,
    required this.title,
    required this.body,
    required this.onSave,
    this.isSaving = false,
  });

  final String       title;
  final Widget       body;
  final VoidCallback onSave;
  final bool         isSaving;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MirrorColors.bg,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(MirrorRadius.lg),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // 拖动条
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 1.5,
              decoration: BoxDecoration(
                color: MirrorColors.divider,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 16),

            // 标题
            Text(
              title,
              style: MirrorText.overline.copyWith(letterSpacing: 4.0),
            ),
            const SizedBox(height: 16),

            // 分隔线（带 scale 入场，同 result_screen masthead）
            Container(
              height: 0.5,
              margin: const EdgeInsets.symmetric(
                  horizontal: MirrorSpacing.pagePad),
              color: MirrorColors.divider,
            )
                .animate()
                .scale(
                  begin: const Offset(0, 1),
                  end: const Offset(1, 1),
                  alignment: Alignment.centerLeft,
                  duration: const Duration(milliseconds: 500),
                  curve: MirrorCurve.enter,
                ),

            // Body（滚动区）
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  MirrorSpacing.pagePad, 20,
                  MirrorSpacing.pagePad, 0,
                ),
                child: body,
              ),
            ),

            // 保存按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  MirrorSpacing.pagePad, 12, MirrorSpacing.pagePad, 20),
              child: OutlinedButton(
                onPressed: isSaving ? null : onSave,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: MirrorColors.divider, width: 0.5),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(MirrorRadius.lg)),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: MirrorColors.text1, strokeWidth: 1),
                      )
                    : Text(
                        'SAVE  ·  RECORD',
                        style: MirrorText.overline.copyWith(
                          color: MirrorColors.text2, letterSpacing: 2.5),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 选择 Chip（参考 result_screen 时间段选择器风格）─────────────────────────────
class MirrorChip extends StatelessWidget {
  const MirrorChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailingPad = 20.0,
  });

  final String       label;
  final bool         selected;
  final VoidCallback onTap;
  final double       trailingPad;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(right: trailingPad),
        child: AnimatedDefaultTextStyle(
          duration: MirrorDuration.fast,
          curve: MirrorCurve.snap,
          style: MirrorText.bodyS.copyWith(
            color:       selected ? MirrorColors.text1 : MirrorColors.text3,
            fontWeight:  selected ? FontWeight.w500    : FontWeight.w300,
            decoration:  selected
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: MirrorColors.text1,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
