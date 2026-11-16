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

class SupplementLogSheet extends ConsumerStatefulWidget {
  const SupplementLogSheet({super.key});

  @override
  ConsumerState<SupplementLogSheet> createState() => _SupplementLogSheetState();
}

class _SupplementLogSheetState extends ConsumerState<SupplementLogSheet> {
  final Set<String> _selected = {};   // stored values (SupplementValue)
  final _customCtrl  = TextEditingController();
  final _dosageCtrl  = TextEditingController();
  TimeOfDay? _reminderTime;
  bool _reminderEnabled = false;
  bool _isSaving        = false;

  S get _s => S.of(context);

  @override
  void dispose() {
    _customCtrl.dispose();
    _dosageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: MirrorColors.text1,
            surface: MirrorColors.bg2,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _reminderTime = picked);
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
    final customName = _customCtrl.text.trim();
    if (_selected.isEmpty && customName.isEmpty) {
      _showSnack(_s.supplementErrorEmpty);
      return;
    }
    final s = _s;   // the sheet closes before the snack is shown
    setState(() => _isSaving = true);

    final reminderStr = (_reminderEnabled && _reminderTime != null)
        ? '${_reminderTime!.hour.toString().padLeft(2,'0')}:'
          '${_reminderTime!.minute.toString().padLeft(2,'0')}'
        : null;

    final items = [
      ..._selected.map((name) => SupplementLogEntry(
        name: name, reminderTime: reminderStr,
        reminderEnabled: _reminderEnabled,
      )),
      if (customName.isNotEmpty)
        SupplementLogEntry(
          name: customName,
          dosage: _dosageCtrl.text.trim().isEmpty ? null : _dosageCtrl.text.trim(),
          reminderTime: reminderStr,
          reminderEnabled: _reminderEnabled,
        ),
    ];

    try {
      await LogApi.instance.saveSupplements(items);
      ref.invalidate(todayStatsProvider);
      if (mounted) {
        Navigator.pop(context);
        _showSnack(s.supplementSaved);
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
      title:    _s.supplementSheetTitle,
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
          child: _buildPresetsSection(),
        ),
        const EditorialDivider(topPad: 24, bottomPad: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: _buildCustomSection(),
        ),
        const EditorialDivider(topPad: 24, bottomPad: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          child: _buildReminderSection(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPresetsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_s.supplementSelectTitle, style: MirrorText.overline),
      const SizedBox(height: 12),
      Wrap(
        spacing: 0,
        runSpacing: 8,
        children: SupplementValue.all.map((v) => MirrorChip(
          label: supplementLabel(_s, v),
          selected: _selected.contains(v),
          onTap: () => setState(() {
            _selected.contains(v) ? _selected.remove(v) : _selected.add(v);
          }),
        )).toList(),
      ),
    ]);
  }

  Widget _buildCustomSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_s.supplementCustomTitle, style: MirrorText.overline),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextField(
          controller: _customCtrl,
          decoration: sheetInputDecoration(_s.supplementNameField, hint: _s.supplementNameHint),
        )),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: _dosageCtrl,
          decoration: sheetInputDecoration(_s.supplementDosageField,
              hint: _s.supplementDosageHint),
        )),
      ]),
    ]);
  }

  Widget _buildReminderSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(_s.supplementReminderTitle, style: MirrorText.overline),
        const Spacer(),
        Switch(
          value: _reminderEnabled,
          activeThumbColor: MirrorColors.text1,
          onChanged: (v) => setState(() => _reminderEnabled = v),
        ),
      ]),
      if (_reminderEnabled) ...[
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickReminderTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: MirrorColors.bg2,
              borderRadius: BorderRadius.circular(MirrorRadius.sm),
              border: Border.all(color: MirrorColors.divider, width: 0.5),
            ),
            child: Row(children: [
              const Icon(Icons.schedule_outlined,
                  size: 14, color: MirrorColors.text3),
              const SizedBox(width: 8),
              Text(
                _reminderTime != null
                    ? _reminderTime!.format(context)
                    : _s.supplementPickTime,
                style: MirrorText.body,
              ),
            ]),
          ),
        ),
      ],
    ]);
  }
}
