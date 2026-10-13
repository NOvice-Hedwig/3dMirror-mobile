import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constants/food_library.dart';
import '../../../../providers/log_provider.dart';
import '../../../../services/api/log_api.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/animate_widgets.dart';
import '../../../../models/log_models.dart';
import '_sheet_base.dart';

class DietLogSheet extends ConsumerStatefulWidget {
  const DietLogSheet({super.key});

  @override
  ConsumerState<DietLogSheet> createState() => _DietLogSheetState();
}

class _DietLogSheetState extends ConsumerState<DietLogSheet> {
  late String _meal;
  String  _method      = 'search';
  String  _foodSearch  = '';
  FoodItem? _selectedFood;

  final _nameCtrl     = TextEditingController();
  final _gramsCtrl    = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl  = TextEditingController();
  final _searchCtrl   = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final h = DateTime.now().hour;
    _meal = h < 10 ? '早餐' : h < 14 ? '午餐' : h < 18 ? '晚餐' : '加餐';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gramsCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onFoodSelected(FoodItem food) {
    _selectedFood = food;
    _nameCtrl.text = food.name;
    final g = double.tryParse(_gramsCtrl.text);
    if (g != null && g > 0) {
      _caloriesCtrl.text = food.kcalFor(g).toStringAsFixed(0);
      _proteinCtrl.text  = food.proteinFor(g).toStringAsFixed(1);
    }
    setState(() {
      _foodSearch = '';
      _searchCtrl.clear();
    });
  }

  void _onGramsChanged(String v) {
    final g = double.tryParse(v);
    if (g != null && _selectedFood != null) {
      _caloriesCtrl.text = _selectedFood!.kcalFor(g).toStringAsFixed(0);
      _proteinCtrl.text  = _selectedFood!.proteinFor(g).toStringAsFixed(1);
    }
  }

  bool _validate() {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('请输入食物名称');
      return false;
    }
    if (_caloriesCtrl.text.trim().isEmpty) {
      _showSnack('请输入卡路里');
      return false;
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

    final entry = DietLogEntry(
      id:          '',
      userId:      '',
      loggedAt:    DateTime.now(),
      meal:        _meal,
      foodName:    _nameCtrl.text.trim(),
      grams:       double.tryParse(_gramsCtrl.text),
      calories:    double.parse(_caloriesCtrl.text),
      proteinG:    double.tryParse(_proteinCtrl.text),
      entryMethod: _selectedFood != null ? 'search' : 'manual',
    );
    try {
      await LogApi.instance.saveDiet(entry);
      ref.invalidate(todayStatsProvider);
      if (mounted) {
        Navigator.pop(context);
        _showSnack('饮食已记录');
      }
    } catch (e) {
      if (mounted) _showSnack('保存失败：$e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetBase(
      title:    'MEAL  ·  LOG',
      isSaving: _isSaving,
      onSave:   _save,
      body:     _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1 — 餐次
        FadeSlideIn(
          delay: Duration.zero,
          child: _buildMealSection(),
        ),
        const EditorialDivider(topPad: 24, bottomPad: 24),

        // Section 2 — 录入方式
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: _buildMethodSection(),
        ),
        const SizedBox(height: 20),

        // Section 3 — 搜索/表单
        FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          child: _buildFormSection(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMealSection() {
    const meals = ['早餐', '午餐', '晚餐', '加餐'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('MEAL  ·  TYPE', style: MirrorText.overline),
      const SizedBox(height: 12),
      Row(children: meals.map((m) => MirrorChip(
        label: m, selected: _meal == m,
        onTap: () => setState(() => _meal = m),
      )).toList()),
    ]);
  }

  Widget _buildMethodSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ENTRY  ·  METHOD', style: MirrorText.overline),
      const SizedBox(height: 12),
      Row(children: [
        MirrorChip(
          label: '搜索', selected: _method == 'search',
          onTap: () => setState(() => _method = 'search'),
        ),
        MirrorChip(
          label: '手动', selected: _method == 'manual',
          onTap: () => setState(() => _method = 'manual'),
        ),
      ]),
    ]);
  }

  Widget _buildFormSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_method == 'search') ...[
        TextField(
          controller: _searchCtrl,
          decoration: sheetInputDecoration('搜索食物', hint: '鸡胸肉、燕麦…'),
          onChanged: (v) => setState(() => _foodSearch = v),
        ),
        if (_foodSearch.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSearchResults(),
        ],
        const SizedBox(height: 16),
      ],

      // 食物表单（搜索选中或手动模式时显示）
      TextField(
        controller: _nameCtrl,
        decoration: sheetInputDecoration('食物名称'),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(
          controller: _gramsCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: sheetInputDecoration('克重'),
          onChanged: _onGramsChanged,
        )),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: _caloriesCtrl,
          keyboardType: TextInputType.number,
          decoration: sheetInputDecoration('卡路里 *'),
        )),
      ]),
      const SizedBox(height: 10),
      TextField(
        controller: _proteinCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: sheetInputDecoration('蛋白质 g（选填）'),
      ),
    ]);
  }

  Widget _buildSearchResults() {
    final results = searchFood(_foodSearch).take(8).toList();
    if (results.isEmpty) return const SizedBox.shrink();
    return Column(
      children: results.map((food) {
        final isLast = food == results.last;
        return InkWell(
          onTap: () => _onFoodSelected(food),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.name, style: MirrorText.body),
                    Text('${food.per100gKcal.toStringAsFixed(0)} kcal / 100g',
                        style: MirrorText.caption),
                  ],
                )),
              ]),
            ),
            if (!isLast) Container(height: 0.5, color: MirrorColors.divider),
          ]),
        );
      }).toList(),
    );
  }
}
