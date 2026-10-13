import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class DeltaText extends StatelessWidget {
  const DeltaText({super.key, required this.delta, required this.unit});
  final double delta;
  final String unit;

  @override
  Widget build(BuildContext context) {
    if (delta == 0) {
      return Text('—',
          style: MirrorText.bodyS.copyWith(color: MirrorColors.text3));
    }
    final sign  = delta > 0 ? '+' : '';
    final color = delta < 0 ? MirrorColors.text1 : MirrorColors.text2;
    return Text(
      '$sign${delta.toStringAsFixed(1)} $unit',
      style: MirrorText.bodyS.copyWith(color: color),
    );
  }
}
