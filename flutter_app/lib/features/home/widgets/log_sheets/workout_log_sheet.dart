import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constants/exercise_library.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/animate_widgets.dart';
import '../../../../models/log_models.dart';
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

// ── 子类型映射 ─────────────────────────────────────────────────────────────────
const _kSubTypes = {
  '有氧':  ['跑步', '跳绳', '跳操', 'HIIT', '游泳', '爬山', '骑行', '其他'],
  '普拉提': ['垫上普拉提', '器械普拉提'],
  '球类':  ['篮球', '羽毛球', '网球', '乒乓球', '足球', '其他'],
};
const _kMuscleGroups = ['胸', '背', '腿', '肩', '手臂', '核心'];

// ─────────────────────────────────────────────────────────────────────────────
class WorkoutLogSheet extends ConsumerStatefulWidget {
  const WorkoutLogSheet({super.key});

  @override
  ConsumerState<WorkoutLogSheet> createState() => _WorkoutLogSheetState();
}

class _WorkoutLogSheetState extends ConsumerState<WorkoutLogSheet> {
  String  _type        = '有氧';
  String  _subType     = '跑步';
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
      if (t == '有氧') {
        _subType = '跑步';
      } else if (t == '普拉提') {
        _subType = '垫上普拉提';
      } else if (t == '球类') {
        _subType = '篮球';
      } else {
        _subType = t;
      }
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
    if (_type == '无氧') {
      if (_muscleGroup == null) {
        _showSnack('请选择训练部位');
        return false;
      }
      if (_sets.isEmpty) {
        _showSnack('请至少添加一组');
        return false;
      }
    } else {
      if (_durationMin < 5) {
        _showSnack('时长至少 5 分钟');
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
    setState(() => _isSaving = true);

    final entry = WorkoutLogEntry(
      type:         _type,
      subType:      _type == '其他' ? _customCtrl.text.trim() : _subType,
      durationMin:  _type == '无氧' ? 0 : _durationMin,
      intensity:    _intensity,
      withWeight:   _withWeight,
      weightKg:     _withWeight ? double.tryParse(_weightKgCtrl.text) : null,
      muscleGroup:  _muscleGroup,
      sets:         _type == '无氧'
          ? _sets.map((s) => s.toStrengthSet()).toList()
          : null,
      estimatedKcal: _type != '无氧' ? _estimatedCalories : null,
    );
    try {
      await LogApi.instance.saveWorkout(entry);
      ref.invalidate(todayStatsProvider);
      ref.invalidate(sessionsProvider);
      if (mounted) {
        Navigator.pop(context);
        _showSnack('运动已记录');
      }
    } catch (e) {
      if (mounted) _showSnack('保存失败：$e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SheetBase(
      title:    'TYPE  ·  LOG',
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

        if (_type != '无氧') ...[
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
    const types = ['有氧', '无氧', '普拉提', '球类', '其他'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TYPE  ·  SELECT', style: MirrorText.overline),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: types.map((t) => MirrorChip(
              label:    t,
              selected: _type == t,
              onTap:    () => _switchType(t),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubSection() {
    if (_type == '有氧') return _buildChipRow('CARDIO  ·  TYPE', _kSubTypes['有氧']!);
    if (_type == '普拉提') return _buildChipRow('PILATES  ·  TYPE', _kSubTypes['普拉提']!);
    if (_type == '球类') return _buildChipRow('SPORT  ·  TYPE', _kSubTypes['球类']!);
    if (_type == '其他') {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('OTHER  ·  NAME', style: MirrorText.overline),
        const SizedBox(height: 10),
        TextField(controller: _customCtrl, decoration: sheetInputDecoration('运动名称')),
      ]);
    }
    // 无氧
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
          label: o, selected: _subType == o,
          onTap: () => setState(() => _subType = o),
        )).toList(),
      ),
    ]);
  }

  Widget _buildStrengthSubSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('MUSCLE  ·  GROUP', style: MirrorText.overline),
      const SizedBox(height: 12),
      Wrap(
        spacing: 0,
        runSpacing: 8,
        children: _kMuscleGroups.map((g) => MirrorChip(
          label: g, selected: _muscleGroup == g,
          onTap: () => setState(() => _muscleGroup = g),
        )).toList(),
      ),
      if (_muscleGroup != null) ...[
        const SizedBox(height: 16),
        TextField(
          controller: _searchCtrl,
          decoration: sheetInputDecoration('搜索动作'),
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
    const intensities = [('低', 'low'), ('中', 'medium'), ('高', 'high')];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('DURATION  ·  INTENSITY', style: MirrorText.overline),
      const SizedBox(height: 16),

      // 时长大字 + Slider
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('$_durationMin', style: MirrorText.displayMd),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text('分钟', style: MirrorText.unitLg),
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
      Text('INTENSITY', style: MirrorText.overline),
      const SizedBox(height: 10),
      Row(children: intensities.map<Widget>((item) => MirrorChip(
        label: item.$1, selected: _intensity == item.$2,
        onTap: () => setState(() => _intensity = item.$2),
      )).toList()),
      const SizedBox(height: 16),

      // 附加负重
      Row(children: [
        Text('附加负重', style: MirrorText.body),
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
          decoration: sheetInputDecoration('负重 kg'),
        ),
      ],
    ]);
  }

  Widget _buildSetsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('SETS  ·  LOG', style: MirrorText.overline),
      const SizedBox(height: 12),
      ...List.generate(_sets.length, (i) => _buildSetRow(i)),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: _addSet,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('+ 添加一组',
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
          decoration: sheetInputDecoration('次数'),
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
      Text('CALORIE  ·  EST', style: MirrorText.overline),
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
            child: Text('取消', style: MirrorText.caption),
          ),
        ])
      else
        Row(children: [
          Text('估算消耗', style: MirrorText.body),
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
            child: Text('修改',
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
