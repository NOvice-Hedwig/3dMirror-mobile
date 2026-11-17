import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../constants/exercise_library.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/log_value_labels.dart';
import '../../core/theme/design_tokens.dart';
import '../../models/log_values.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String  _search        = '';
  String? _selectedGroup;   // a stored muscle-group value (MuscleGroupValue); null = all

  S get _s => S.of(context);

  List<ExerciseItem> get _filtered =>
      searchExercises(_search, muscleGroup: _selectedGroup);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MirrorColors.bg,
    body: SafeArea(
      child: Column(children: [
        _buildMasthead(),

        // 搜索框
        Padding(
          padding: const EdgeInsets.fromLTRB(
              MirrorSpacing.pagePad, 16, MirrorSpacing.pagePad, 0),
          child: TextField(
            style: MirrorText.body.copyWith(color: MirrorColors.text1),
            decoration: InputDecoration(
              hintText: _s.librarySearchHint,
              hintStyle: MirrorText.body,
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 18, color: MirrorColors.text3),
              filled: true,
              fillColor: MirrorColors.bg2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MirrorRadius.sm),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),

        // 部位筛选 Chip
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
              MirrorSpacing.pagePad, 12, MirrorSpacing.pagePad, 0),
          child: Row(
            children: <String?>[null, ...MuscleGroupValue.all]
                .map((g) {
              final isAll = g == null;
              final selected = isAll
                  ? _selectedGroup == null
                  : _selectedGroup == g;
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                  onTap: () => setState(() =>
                      _selectedGroup = isAll ? null : g),
                  child: AnimatedDefaultTextStyle(
                    duration: MirrorDuration.fast,
                    curve: MirrorCurve.snap,
                    style: MirrorText.bodyS.copyWith(
                      color: selected
                          ? MirrorColors.text1
                          : MirrorColors.text3,
                      fontWeight: selected
                          ? FontWeight.w500 : FontWeight.w300,
                      decoration: selected
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: MirrorColors.text1,
                    ),
                    child: Text(isAll ? _s.libraryAll : muscleGroupLabel(_s, g)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // 动作列表
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                MirrorSpacing.pagePad, 16, MirrorSpacing.pagePad, 56),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const Divider(
                color: MirrorColors.divider, height: 1, thickness: 0.5),
            itemBuilder: (_, i) {
              final ex = _filtered[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ex.name, style: MirrorText.body.copyWith(
                            color: MirrorColors.text1)),
                        const SizedBox(height: 2),
                        Text(ex.equipment, style: MirrorText.caption),
                      ],
                    ),
                  ),
                  Text(muscleGroupLabel(_s, ex.group), style: MirrorText.overline),
                ]),
              );
            },
          ),
        ),
      ]),
    ),
  );

  Widget _buildMasthead() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            MirrorSpacing.pagePad, 20, MirrorSpacing.pagePad, 12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              _s.libraryMasthead,
              style: MirrorText.overline.copyWith(
                  color: MirrorColors.gold,
                  fontSize: 11,
                  letterSpacing: 4.0),
              textAlign: TextAlign.center,
            ),
            Positioned(
              left: 0,
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 13, color: MirrorColors.text3),
                  const SizedBox(width: 4),
                  Text(_s.btnBack, style: MirrorText.bodyS.copyWith(
                      color: MirrorColors.text3)),
                ]),
              ),
            ),
          ],
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
