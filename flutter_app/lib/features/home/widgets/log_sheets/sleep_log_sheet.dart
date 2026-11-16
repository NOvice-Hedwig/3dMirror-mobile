import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/animate_widgets.dart';
import '../../../../models/log_models.dart';
import '../../../../providers/log_provider.dart';
import '../../../../services/api/log_api.dart';
import '_sheet_base.dart';

class SleepLogSheet extends ConsumerStatefulWidget {
  const SleepLogSheet({super.key});

  @override
  ConsumerState<SleepLogSheet> createState() => _SleepLogSheetState();
}

class _SleepLogSheetState extends ConsumerState<SleepLogSheet> {
  TimeOfDay _bedtime  = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7,  minute: 0);
  int  _quality  = 3;
  bool _isSaving = false;

  double get _durationHours {
    final bedMins  = _bedtime.hour * 60 + _bedtime.minute;
    final wakeMins = _wakeTime.hour * 60 + _wakeTime.minute;
    final diff = wakeMins - bedMins;
    return (diff <= 0 ? diff + 24 * 60 : diff) / 60.0;
  }

  String get _durationStr {
    final h = _durationHours;
    final hours = h.floor();
    final mins  = ((h - hours) * 60).round();
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  Future<void> _pickTime(bool isBed) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isBed ? _bedtime : _wakeTime,
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
    if (picked == null) return;
    setState(() {
      if (isBed) { _bedtime  = picked; } else { _wakeTime = picked; }
    });
  }

  void _showSnack(String msg, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: MirrorText.bodyS),
      backgroundColor: MirrorColors.bg2,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      action: action,
    ));
  }

  S get _s => S.of(context);

  Future<void> _save() async {
    if (_durationHours < 1.0) {
      _showSnack(
        _s.sleepShortConfirm,
        action: SnackBarAction(
          label: _s.confirmBtn,
          textColor: MirrorColors.text1,
          onPressed: _doSave,
        ),
      );
      return;
    }
    await _doSave();
  }

  Future<void> _doSave() async {
    final s = _s;   // the sheet closes before the snack is shown
    setState(() => _isSaving = true);
    final now  = DateTime.now();
    final bed  = DateTime(now.year, now.month, now.day,
        _bedtime.hour, _bedtime.minute);
    var wake   = DateTime(now.year, now.month, now.day,
        _wakeTime.hour, _wakeTime.minute);
    if (wake.isBefore(bed)) wake = wake.add(const Duration(days: 1));

    final date = '${wake.year}-'
        '${wake.month.toString().padLeft(2, '0')}-'
        '${wake.day.toString().padLeft(2, '0')}';

    final entry = SleepLogEntry(
      id: '', userId: '', date: date,
      bedtime: bed, wakeTime: wake, quality: _quality,
    );
    try {
      await LogApi.instance.saveSleep(entry);
      ref.invalidate(todayStatsProvider);
      if (mounted) {
        Navigator.pop(context);
        _showSnack(s.sleepSaved);
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
      title:    _s.sleepSheetTitle,
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
          child: _buildTimeSection(),
        ),
        const EditorialDivider(topPad: 24, bottomPad: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: _buildDurationDisplay(),
        ),
        const EditorialDivider(topPad: 24, bottomPad: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          child: _buildQualitySection(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTimeSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_s.sleepTimeTitle, style: MirrorText.overline),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _TimeSelector(
          label: _s.sleepBedtime, time: _bedtime,
          onTap: () => _pickTime(true),
        )),
        const SizedBox(width: 16),
        Expanded(child: _TimeSelector(
          label: _s.sleepWake, time: _wakeTime,
          onTap: () => _pickTime(false),
        )),
      ]),
    ]);
  }

  Widget _buildDurationDisplay() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_s.sleepDurationTitle, style: MirrorText.overline),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MirrorColors.bg2,
          borderRadius: BorderRadius.circular(MirrorRadius.sm),
          border: Border.all(color: MirrorColors.divider, width: 0.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${_s.sleepDuration}   ', style: MirrorText.body),
          Text(_durationStr, style: MirrorText.displayMd),
        ]),
      ),
    ]);
  }

  Widget _buildQualitySection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_s.sleepQualityTitle, style: MirrorText.overline),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final filled = i < _quality;
          return GestureDetector(
            onTap: () => setState(() => _quality = i + 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 32,
                color: filled ? MirrorColors.text1 : MirrorColors.text3,
              ),
            ),
          );
        }),
      ),
    ]);
  }
}

// ── 时间选择器子组件 ───────────────────────────────────────────────────────────
class _TimeSelector extends StatelessWidget {
  const _TimeSelector({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String     label;
  final TimeOfDay  time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: MirrorText.overline),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: MirrorColors.bg2,
            borderRadius: BorderRadius.circular(MirrorRadius.sm),
            border: Border.all(color: MirrorColors.divider, width: 0.5),
          ),
          child: Center(
            child: Text(
              time.format(context),
              style: MirrorText.displayMd,
            ),
          ),
        ),
      ),
    ]);
  }
}
