import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../../models/models.dart';

enum BodyStrokeStyle { fill, solidOutline, dashedOutline }

class BodyViewport extends StatelessWidget {
  const BodyViewport({
    super.key,
    required this.height,
    this.avatarParams,
    this.strokeStyle = BodyStrokeStyle.fill,
    this.color,
    this.showBackground = true,
  });

  final double        height;
  final AvatarParams? avatarParams;
  final BodyStrokeStyle strokeStyle;
  final Color?        color;
  final bool          showBackground;

  @override
  Widget build(BuildContext context) {
    final painter = _BodyPainter(
      avatarParams: avatarParams,
      strokeStyle:  strokeStyle,
      color:        color,
    );
    const radius = BorderRadius.only(
      topLeft:     Radius.circular(MirrorRadius.xl),
      topRight:    Radius.circular(MirrorRadius.xl),
      bottomLeft:  Radius.circular(MirrorRadius.sm),
      bottomRight: Radius.circular(MirrorRadius.sm),
    );
    final silhouette = Center(
      child: CustomPaint(painter: painter, size: const Size(90, 220)),
    );

    if (!showBackground) {
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(height: height, child: silhouette),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        color: MirrorColors.viewport,
        child: Stack(children: [
          silhouette,
          Positioned(
            bottom: 16, left: 0, right: 0,
            child: Text('拖动旋转',
                textAlign: TextAlign.center,
                style: MirrorText.caption),
          ),
        ]),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    this.avatarParams,
    this.strokeStyle = BodyStrokeStyle.fill,
    this.color,
  });

  final AvatarParams?   avatarParams;
  final BodyStrokeStyle strokeStyle;
  final Color?          color;

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.avatarParams != avatarParams ||
      old.strokeStyle  != strokeStyle  ||
      old.color        != color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color ?? MirrorColors.bg2;
    switch (strokeStyle) {
      case BodyStrokeStyle.fill:
        paint.style = PaintingStyle.fill;
      case BodyStrokeStyle.solidOutline:
        paint
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap   = StrokeCap.round;
      case BodyStrokeStyle.dashedOutline:
        paint
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap   = StrokeCap.round;
    }

    final cx = size.width / 2;
    final p  = avatarParams;

    // Scale factors: norm 0 → minimum, 0.5 → original size, 1 → maximum
    final waistScale    = p == null ? 1.0 : 0.80 + p.waistNorm    * 0.40;
    final shoulderScale = p == null ? 1.0 : 0.85 + p.shoulderNorm * 0.30;
    final hipScale      = p == null ? 1.0 : 0.85 + p.hipNorm      * 0.30;
    final muscleScale   = p == null ? 1.0 : 0.90 + p.muscleNorm   * 0.20;
    final weightScale   = p == null ? 1.0 : 0.85 + p.weightNorm   * 0.30;

    final waistW = 40.0 * waistScale * weightScale;
    final armW   = 10.0 * shoulderScale * muscleScale;
    final legW   = 14.0 * hipScale * muscleScale;

    // Head — fixed size
    final headOval = Rect.fromCenter(
        center: Offset(cx, 16), width: 26, height: 28);

    // Torso — waist-driven width
    final torso = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - waistW / 2, 32, waistW, 56),
        const Radius.circular(7));

    // Arms — hug torso edges with 2 px gap
    final armX    = waistW / 2 + 2;
    final leftArm = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - armX - armW, 34, armW, 42),
        const Radius.circular(5));
    final rightArm = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + armX, 34, armW, 42),
        const Radius.circular(5));

    // Legs — 4 px gap between, symmetric about cx
    final leftLeg = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 4 - legW, 90, legW, 58),
        const Radius.circular(6));
    final rightLeg = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 4, 90, legW, 58),
        const Radius.circular(6));

    // Feet — fixed 18×9, track leg centres
    const footW  = 18.0;
    final leftFoot = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 4 - legW / 2 - footW / 2, 145, footW, 9),
        const Radius.circular(4));
    final rightFoot = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 4 + legW / 2 - footW / 2, 145, footW, 9),
        const Radius.circular(4));

    if (strokeStyle == BodyStrokeStyle.dashedOutline) {
      _drawDashedOval(canvas, headOval, paint);
      _drawDashedRRect(canvas, torso,     paint);
      _drawDashedRRect(canvas, leftArm,   paint);
      _drawDashedRRect(canvas, rightArm,  paint);
      _drawDashedRRect(canvas, leftLeg,   paint);
      _drawDashedRRect(canvas, rightLeg,  paint);
      _drawDashedRRect(canvas, leftFoot,  paint);
      _drawDashedRRect(canvas, rightFoot, paint);
    } else {
      canvas.drawOval(headOval, paint);
      canvas.drawRRect(torso,     paint);
      canvas.drawRRect(leftArm,   paint);
      canvas.drawRRect(rightArm,  paint);
      canvas.drawRRect(leftLeg,   paint);
      canvas.drawRRect(rightLeg,  paint);
      canvas.drawRRect(leftFoot,  paint);
      canvas.drawRRect(rightFoot, paint);
    }
  }

  void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint) =>
      _drawDashedPath(canvas, Path()..addRRect(rrect), paint);

  void _drawDashedOval(Canvas canvas, Rect oval, Paint paint) =>
      _drawDashedPath(canvas, Path()..addOval(oval), paint);

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        final end = (d + 4).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, end), paint);
        d += 7; // 4 px dash + 3 px gap
      }
    }
  }
}
