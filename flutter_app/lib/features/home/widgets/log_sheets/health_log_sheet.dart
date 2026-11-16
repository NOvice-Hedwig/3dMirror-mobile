import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/log_value_labels.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/animate_widgets.dart';
import '../../../../models/log_models.dart';
import '../../../../models/log_values.dart';
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
  final List<String>  _symptoms  = [];   // stored values (SymptomValue)
  int           _intensity = 2;
  bool          _isSaving  = false;

  S get _s => S.of(context);

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
      _showSnack(_s.healthErrorEmpty);
      return;
    }
    final s = _s;   // the sheet closes before the snack is shown
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
        _showSnack(s.healthSaved);
      }
    } catch (e) {
      if (mounted) _showSnack(s.saveFailedDetail('$e'));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetBase(
      title:    _s.healthSheetTitle,
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
      Text(_s.healthMeasureTitle, style: MirrorText.overline),
      const SizedBox(height: 16),
      _measureRow(_weightCtrl, _s.measureWeightKg, _waistCtrl, _s.measureWaistCm),
      const SizedBox(height: 10),
      _measureRow(_hipCtrl,   _s.measureHipCm, _chestCtrl, _s.measureChestCm),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(
          controller: _thighCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: sheetInputDecoration(_s.measureThighCm),
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
    final phases = [
      (_s.periodStart, 'start'), (_s.periodOngoing, 'ongoing'), (_s.periodEnd, 'end'),
    ];
    final intensityLabels = [
      (_s.periodIntensityLight, 1), (_s.periodIntensityModerate, 2),
      (_s.periodIntensityHeavy, 3),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(_s.healthPeriodTitle, style: MirrorText.overline),
        const Spacer(),
        Text(_s.logOptional, style: MirrorText.caption),
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
        Text(_s.healthSymptomsTitle, style: MirrorText.overline),
        const SizedBox(height: 10),
        Wrap(
          spacing: 0,
          runSpacing: 8,
          children: SymptomValue.all.map((v) => MirrorChip(
            label: symptomLabel(_s, v),
            selected: _symptoms.contains(v),
            onTap: () => _toggleSymptom(v),
          )).toList(),
        ),
        const SizedBox(height: 20),
        Text(_s.logIntensityTitle, style: MirrorText.overline),
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
