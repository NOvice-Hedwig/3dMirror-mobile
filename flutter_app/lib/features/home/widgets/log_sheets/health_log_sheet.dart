import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/animate_widgets.dart';
import '../../../../models/log_models.dart';
import '../../../../providers/log_provider.dart';
import '../../../../services/api/log_api.dart';
import '_sheet_base.dart';

class HealthLogSheet extends ConsumerStatefulWidget {
  const HealthLogSheet({super.key});

  @override
  ConsumerState<HealthLogSheet> createState() => _HealthLogSheetState();
}

class _HealthLogSheetState extends ConsumerState<HealthLogSheet> {
  final _weightCtrl = TextEditingController();
  final _waistCtrl  = TextEditingController();
  final _hipCtrl    = TextEditingController();
  final _chestCtrl  = TextEditingController();
  final _thighCtrl  = TextEditingController();

  String?       _periodPhase;
  final List<String>  _symptoms  = [];
  int           _intensity = 2;
  bool          _isSaving  = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _waistCtrl.dispose();
    _hipCtrl.dispose();
    _chestCtrl.dispose();
    _thighCtrl.dispose();
    super.dispose();
  }

  BodyMeasurementUpdate get _measurement => BodyMeasurementUpdate(
    weightKg: double.tryParse(_weightCtrl.text),
    waistCm:  double.tryParse(_waistCtrl.text),
    hipCm:    double.tryParse(_hipCtrl.text),
    chestCm:  double.tryParse(_chestCtrl.text),
    thighCm:  double.tryParse(_thighCtrl.text),
  );

  void _toggleSymptom(String s) {
    setState(() {
      _symptoms.contains(s) ? _symptoms.remove(s) : _symptoms.add(s);
    });
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
    final m = _measurement;
    if (!m.hasAnyValue && _periodPhase == null) {
      _showSnack('请至少填写一项数据');
      return;
    }
    setState(() => _isSaving = true);

    try {
      if (m.hasAnyValue) {
        await LogApi.instance.updateMeasurements(m);
      }
      if (_periodPhase != null) {
        final period = PeriodLogEntry(
          phase: _periodPhase!, symptoms: List.from(_symptoms),
          intensity: _intensity,
        );
        await LogApi.instance.savePeriod(period);
        ref.invalidate(todayStatsProvider);
      }
      if (mounted) {
        Navigator.pop(context);
        _showSnack('健康数据已记录');
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
      title:    'HEALTH  ·  LOG',
      isSaving: _isSaving,
      onSave:   _save,
      body:     _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeSlideIn(
          delay: Duration.zero,
          child: _buildMeasureSection(),
        ),
        const EditorialDivider(topPad: 24, bottomPad: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: _buildPeriodSection(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMeasureSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('BODY  ·  MEASURE', style: MirrorText.overline),
      const SizedBox(height: 16),
      _measureRow(_weightCtrl, '体重 kg', _waistCtrl, '腰围 cm'),
      const SizedBox(height: 10),
      _measureRow(_hipCtrl,   '臀围 cm', _chestCtrl, '胸围 cm'),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(
          controller: _thighCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: sheetInputDecoration('大腿围 cm'),
        )),
        const Expanded(child: SizedBox()),
      ]),
    ]);
  }

  Widget _measureRow(
    TextEditingController c1, String l1,
    TextEditingController c2, String l2,
  ) {
    return Row(children: [
      Expanded(child: TextField(
        controller: c1,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: sheetInputDecoration(l1),
      )),
      const SizedBox(width: 10),
      Expanded(child: TextField(
        controller: c2,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: sheetInputDecoration(l2),
      )),
    ]);
  }

  Widget _buildPeriodSection() {
    const phases = [('经期开始', 'start'), ('进行中', 'ongoing'), ('经期结束', 'end')];
    const symptoms = ['痛经', '情绪波动', '水肿', '长痘', '疲劳', '腰酸'];
    const intensityLabels = [('轻', 1), ('中', 2), ('重', 3)];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('PERIOD  ·  LOG', style: MirrorText.overline),
        const Spacer(),
        Text('选填', style: MirrorText.caption),
      ]),
      const SizedBox(height: 16),

      // 相位选择
      Row(children: phases.map<Widget>((item) => MirrorChip(
        label: item.$1,
        selected: _periodPhase == item.$2,
        onTap: () => setState(() =>
          _periodPhase = _periodPhase == item.$2 ? null : item.$2),
      )).toList()),

      if (_periodPhase != null) ...[
        const SizedBox(height: 20),
        Text('SYMPTOMS', style: MirrorText.overline),
        const SizedBox(height: 10),
        Wrap(
          spacing: 0,
          runSpacing: 8,
          children: symptoms.map((s) => MirrorChip(
            label: s,
            selected: _symptoms.contains(s),
            onTap: () => _toggleSymptom(s),
          )).toList(),
        ),
        const SizedBox(height: 20),
        Text('INTENSITY', style: MirrorText.overline),
        const SizedBox(height: 10),
        Row(children: intensityLabels.map<Widget>((item) => MirrorChip(
          label: item.$1,
          selected: _intensity == item.$2,
          onTap: () => setState(() => _intensity = item.$2),
        )).toList()),
      ],
    ]);
  }
}
