import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constants/exercise_library.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/log_value_labels.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/animate_widgets.dart';
import '../../../../models/log_models.dart';
import '../../../../models/log_values.dart';
import '../../../../providers/log_provider.dart';
import '../../../../providers/session_provider.dart';
import '../../../../services/api/log_api.dart';
import '_sheet_base.dart';

// ── Sets 行内部可变状态（持有 TextEditingController）──────────────────────────
class _MutableSet {
  final TextEditingController repsCtrl;
  final TextEditingController weightCtrl;

  _MutableSet({int reps = 10, double weight = 0})
      : repsCtrl   = TextEditingController(text: reps.toString()),
        weightCtrl = TextEditingController(text: weight.toStringAsFixed(1));

  void dispose() {
    repsCtrl.dispose();
    weightCtrl.dispose();
  }

  StrengthSet toStrengthSet() => StrengthSet(
    reps:     int.tryParse(repsCtrl.text)     ?? 10,
    weightKg: double.tryParse(weightCtrl.text) ?? 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
class WorkoutLogSheet extends ConsumerStatefulWidget {
  const WorkoutLogSheet({super.key});

  @override
  ConsumerState<WorkoutLogSheet> createState() => _WorkoutLogSheetState();
}

class _WorkoutLogSheetState extends ConsumerState<WorkoutLogSheet> {
  // Stored values (models/log_values.dart); shown through log_value_labels.dart.
  String  _type        = WorkoutLogType.cardio;
  String  _subType     = WorkoutSubType.running;
  int     _durationMin = 30;
  String  _intensity   = 'medium';
  bool    _withWeight  = false;
  String? _muscleGroup;
  final   _searchCtrl  = TextEditingController();
  String  _exerciseSearch = '';
  String? _selectedExercise;
  final   _customCtrl  = TextEditingController();
  final   _weightKgCtrl = TextEditingController();
  final   List<_MutableSet> _sets = [];
  int?    _manualCalories;
  bool    _showCalorieEditor = false;
  final   _calorieEditCtrl  = TextEditingController();
  bool    _isSaving = false;

  S get _s => S.of(context);

  @override
  void dispose() {
    _searchCtrl.dispose();
    _customCtrl.dispose();
    _weightKgCtrl.dispose();
    _calorieEditCtrl.dispose();
    for (final s in _sets) { s.dispose(); }
    super.dispose();
  }

  int get _estimatedCalories => _manualCalories ??
      WorkoutLogEntry.estimateCalories(
        subType:     _subType,
        durationMin: _durationMin,
        intensity:   _intensity,
      );

  void _switchType(String t) {
    setState(() {
      _type        = t;
      _muscleGroup = null;
      _selectedExercise = null;
      _exerciseSearch   = '';
      _searchCtrl.clear();
      _sets.clear();
      _subType = WorkoutSubType.byType[t]?.first ?? t;
    });
  }

  void _addSet() => setState(() => _sets.add(_MutableSet()));

  void _removeSet(int i) {
    setState(() {
      _sets[i].dispose();
      _sets.removeAt(i);
    });
  }

  bool _validate() {
    if (_type == WorkoutLogType.strength) {
      if (_muscleGroup == null) {
        _showSnack(_s.workoutErrorMuscleGroup);
        return false;
      }
      if (_sets.isEmpty) {
        _showSnack(_s.workoutErrorNoSets);
        return false;
      }
    } else {
      if (_durationMin < 5) {
        _showSnack(_s.workoutErrorMinDuration);
        return false;
      }
    }
    return true;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: MirrorText.bodyS),
      backgroundColor: MirrorColors.bg2,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final s = _s;   // the sheet closes before the snack is shown
    setState(() => _isSaving = true);

    final entry = WorkoutLogEntry(
      type:         _type,
      subType:      _type == WorkoutLogType.other ? _customCtrl.text.trim() : _subType,
      durationMin:  _type == WorkoutLogType.strength ? 0 : _durationMin,
      intensity:    _intensity,
      withWeight:   _withWeight,
      weightKg:     _withWeight ? double.tryParse(_weightKgCtrl.text) : null,
      muscleGroup:  _muscleGroup,
      sets:         _type == WorkoutLogType.strength
          ? _sets.map((s) => s.toStrengthSet()).toList()
          : null,
      estimatedKcal: _type != WorkoutLogType.strength ? _estimatedCalories : null,
    );
    try {
      await LogApi.instance.saveWorkout(entry);
      ref.invalidate(todayStatsProvider);
      ref.invalidate(sessionsProvider);
      if (mounted) {
        Navigator.pop(context);
        _showSnack(s.workoutSaved);
      }
    } catch (e) {
      if (mounted) _showSnack(s.saveFailedDetail('$e'));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SheetBase(
      title:    _s.workoutSheetTitle,
      isSaving: _isSaving,
      onSave:   _save,
      body:     _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1 — 类型
        FadeSlideIn(
          delay: Duration.zero,
          child: _buildTypeRow(),
        ),
        const EditorialDivider(topPad: 24, bottomPad: 24),

        // Section 2 — 子类型
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: _buildSubSection(),
        ),

        if (_type != WorkoutLogType.strength) ...[
          const EditorialDivider(topPad: 24, bottomPad: 24),
          // Section 3A — 时长 + 强度 + 负重
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: _buildDurationSection(),
          ),
          const EditorialDivider(topPad: 24, bottomPad: 24),
          // Section 4 — 卡路里
          FadeSlideIn(
            delay: const Duration(milliseconds: 240),
            child: _buildCalorieSection(),
          ),
        ] else ...[
          const EditorialDivider(topPad: 24, bottomPad: 24),
          // Section 3B — Sets
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: _buildSetsSection(),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTypeRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_s.workoutTypeSelect, style: MirrorText.overline),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: WorkoutLogType.all.map((t) => MirrorChip(
              label:    workoutTypeLabel(_s, t),
              selected: _type == t,
              onTap:    () => _switchType(t),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubSection() {
    final subTypes = WorkoutSubType.byType[_type];
    if (_type == WorkoutLogType.cardio) return _buildChipRow(_s.workoutCardioTypeTitle, subTypes!);
    if (_type == WorkoutLogType.pilates) return _buildChipRow(_s.workoutPilatesTypeTitle, subTypes!);
    if (_type == WorkoutLogType.ball) return _buildChipRow(_s.workoutSportTypeTitle, subTypes!);
    if (_type == WorkoutLogType.other) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_s.workoutOtherNameTitle, style: MirrorText.overline),
        const SizedBox(height: 10),
        TextField(controller: _customCtrl,
            decoration: sheetInputDecoration(_s.workoutOtherNameField)),
      ]);
    }
    // strength
    return _buildStrengthSubSection();
  }

  Widget _buildChipRow(String title, List<String> options) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: MirrorText.overline),
      const SizedBox(height: 12),
      Wrap(
        spacing: 0,
        runSpacing: 8,
        children: options.map((o) => MirrorChip(
          label: workoutSubTypeLabel(_s, o), selected: _subType == o,
          onTap: () => setState(() => _subType = o),
        )).toList(),
      ),
    ]);
  }

  Widget _buildStrengthSubSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_s.workoutMuscleGroupTitle, style: MirrorText.overline),
      const SizedBox(height: 12),
      Wrap(
        spacing: 0,
        runSpacing: 8,
        children: MuscleGroupValue.all.map((g) => MirrorChip(
          label: muscleGroupLabel(_s, g), selected: _muscleGroup == g,
          onTap: () => setState(() => _muscleGroup = g),
        )).toList(),
      ),
      if (_muscleGroup != null) ...[
        const SizedBox(height: 16),
        TextField(
          controller: _searchCtrl,
          decoration: sheetInputDecoration(_s.workoutExerciseSearch),
          onChanged: (v) => setState(() => _exerciseSearch = v),
        ),
        const SizedBox(height: 8),
        _buildExerciseList(),
        if (_selectedExercise != null) ...[
          const SizedBox(height: 8),
          Text(_selectedExercise!, style: MirrorText.body.copyWith(
              color: MirrorColors.text1, fontWeight: FontWeight.w500)),
        ],
      ],
    ]);
  }

  Widget _buildExerciseList() {
    final results = _exerciseSearch.isEmpty
        ? exercisesByGroup(_muscleGroup!).take(5).toList()
        : searchExercises(_exerciseSearch, muscleGroup: _muscleGroup).take(8).toList();
    if (results.isEmpty) return const SizedBox.shrink();
    return Column(
      children: results.map((e) {
        final isLast = e == results.last;
        return InkWell(
          onTap: () => setState(() {
            _selectedExercise = e.name;
            _exerciseSearch   = '';
            _searchCtrl.clear();
          }),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Expanded(child: Text(e.name, style: MirrorText.body)),
                Text(e.equipment, style: MirrorText.caption),
              ]),
            ),
            if (!isLast) Container(height: 0.5, color: MirrorColors.divider),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildDurationSection() {
    final intensities = [
      (_s.workoutIntensityLow, 'low'), (_s.workoutIntensityMedium, 'medium'),
      (_s.workoutIntensityHigh, 'high'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_s.workoutDurationIntensityTitle, style: MirrorText.overline),
      const SizedBox(height: 16),

      // 时长大字 + Slider
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('$_durationMin', style: MirrorText.displayMd),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(_s.unitMinutes, style: MirrorText.unitLg),
        ),
      ]),
      const SizedBox(height: 8),
      SliderTheme(
        data: SliderThemeData(
          thumbColor:         MirrorColors.text1,
          activeTrackColor:   MirrorColors.text1,
          inactiveTrackColor: MirrorColors.divider,
          trackHeight:        1.0,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape:       SliderComponentShape.noOverlay,
        ),
        child: Slider(
          min: 5, max: 180, divisions: 35,
          value: _durationMin.toDouble(),
          onChanged: (v) => setState(() => _durationMin = v.round()),
        ),
      ),
      Row(children: [
        Text('5 min',   style: MirrorText.caption),
        const Spacer(),
        Text('180 min', style: MirrorText.caption),
      ]),
      const SizedBox(height: 20),

      // 强度
      Text(_s.logIntensityTitle, style: MirrorText.overline),
      const SizedBox(height: 10),
      Row(children: intensities.map<Widget>((item) => MirrorChip(
        label: item.$1, selected: _intensity == item.$2,
        onTap: () => setState(() => _intensity = item.$2),
      )).toList()),
      const SizedBox(height: 16),

      // 附加负重
      Row(children: [
        Text(_s.workoutWithWeight, style: MirrorText.body),
        const Spacer(),
        Switch(
          value: _withWeight,
          activeThumbColor: MirrorColors.text1,
          onChanged: (v) => setState(() => _withWeight = v),
        ),
      ]),
      if (_withWeight) ...[
        const SizedBox(height: 8),
        TextField(
          controller: _weightKgCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: sheetInputDecoration(_s.workoutWeightField),
        ),
      ],
    ]);
  }

  Widget _buildSetsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_s.workoutSetsTitle, style: MirrorText.overline),
      const SizedBox(height: 12),
      ...List.generate(_sets.length, (i) => _buildSetRow(i)),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: _addSet,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(_s.workoutAddSet,
              style: MirrorText.bodyS.copyWith(color: MirrorColors.text2)),
        ),
      ),
    ]);
  }

  Widget _buildSetRow(int i) {
    final s = _sets[i];
    return Column(children: [
      Row(children: [
        Text('${i + 1}', style: MirrorText.caption),
        const SizedBox(width: 12),
        Expanded(child: TextField(
          controller: s.repsCtrl,
          keyboardType: TextInputType.number,
          decoration: sheetInputDecoration(_s.workoutReps),
        )),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          controller: s.weightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: sheetInputDecoration('kg'),
        )),
        IconButton(
          onPressed: () => _removeSet(i),
          icon: const Icon(Icons.close, size: 14, color: MirrorColors.text3),
        ),
      ]),
      Container(height: 0.5, color: MirrorColors.divider,
          margin: const EdgeInsets.only(top: 8, bottom: 4)),
    ]);
  }

  Widget _buildCalorieSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_s.workoutCalorieTitle, style: MirrorText.overline),
      const SizedBox(height: 12),
      if (_showCalorieEditor)
        Row(children: [
          Expanded(child: TextField(
            controller: _calorieEditCtrl,
            keyboardType: TextInputType.number,
            decoration: sheetInputDecoration('kcal'),
            autofocus: true,
            onSubmitted: (v) => setState(() {
              _manualCalories    = int.tryParse(v);
              _showCalorieEditor = false;
            }),
          )),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _showCalorieEditor = false),
            child: Text(_s.cancelBtn, style: MirrorText.caption),
          ),
        ])
      else
        Row(children: [
          Text(_s.workoutEstimatedBurn, style: MirrorText.body),
          const Spacer(),
          Text('$_estimatedCalories', style: MirrorText.displayMd),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(' kcal', style: MirrorText.unitLg),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() {
              _calorieEditCtrl.text =
                  (_manualCalories ?? _estimatedCalories).toString();
              _showCalorieEditor = true;
            }),
            child: Text(_s.editBtn,
                style: MirrorText.caption.copyWith(
                  color: MirrorColors.text2,
                  decoration: TextDecoration.underline,
                  decorationColor: MirrorColors.text2,
                )),
          ),
        ]),
    ]);
  }
}
