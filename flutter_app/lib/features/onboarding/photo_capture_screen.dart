import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/photo_labels.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../models/body_photo.dart';
import '../../providers/photo_analysis_provider.dart';
import '../../services/api/photo_api.dart';

class PhotoCaptureScreen extends ConsumerStatefulWidget {
  const PhotoCaptureScreen({super.key});

  @override
  ConsumerState<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends ConsumerState<PhotoCaptureScreen> {
  final _picker = ImagePicker();
  final _photos = <PhotoAngle, File>{};

  bool _uploading = false;
  bool _uploadFailed = false;

  static const _angles = [PhotoAngle.front, PhotoAngle.side, PhotoAngle.back];

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: MirrorColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildMasthead(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    MirrorSpacing.pagePad, 24, MirrorSpacing.pagePad, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.photoScanEyebrow, style: MirrorText.overline)
                        .animate()
                        .fadeIn(duration: 400.ms, curve: MirrorCurve.enter),
                    const SizedBox(height: 12),
                    Text.rich(TextSpan(style: MirrorText.title, children: [
                      TextSpan(text: s.photoTitleLead),
                      TextSpan(
                          text: s.photoTitleEmphasis,
                          style:
                              MirrorText.title.copyWith(fontStyle: FontStyle.italic)),
                    ]))
                        .animate(delay: 80.ms)
                        .fadeIn(duration: MirrorDuration.slow, curve: MirrorCurve.enter)
                        .slideY(
                            begin: 0.06,
                            end: 0,
                            duration: MirrorDuration.slow,
                            curve: MirrorCurve.enter),
                    const SizedBox(height: 8),
                    Text(
                      s.photoIntro,
                      style: MirrorText.body.copyWith(color: MirrorColors.text2),
                    )
                        .animate(delay: 160.ms)
                        .fadeIn(duration: 400.ms, curve: MirrorCurve.enter),
                    const SizedBox(height: 32),

                    // Progress chip
                    _buildProgressChip()
                        .animate(delay: 240.ms)
                        .fadeIn(duration: 400.ms, curve: MirrorCurve.enter),
                    const SizedBox(height: 24),

                    // Photo cards row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _angles.asMap().entries.map((e) {
                        final delay = Duration(milliseconds: 320 + e.key * 80);
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: e.key < _angles.length - 1 ? 10 : 0),
                            child: _AngleCard(
                              angle: e.value,
                              capturedFile: _photos[e.value],
                              onTap: () => _capture(e.value),
                            )
                                .animate(delay: delay)
                                .fadeIn(duration: 400.ms, curve: MirrorCurve.enter)
                                .slideY(
                                    begin: 0.05,
                                    end: 0,
                                    duration: 400.ms,
                                    curve: MirrorCurve.enter),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    if (_uploadFailed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(s.photoUploadFailed,
                            style: MirrorText.body
                                .copyWith(color: MirrorColors.gold)),
                      ),
                  ],
                ),
              ),
            ),
            _buildNav(),
          ],
        ),
      ),
    );
  }

  // ── Masthead ───────────────────────────────────────────────────────────────

  Widget _buildMasthead() => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              MirrorSpacing.pagePad, 20, MirrorSpacing.pagePad, 12),
          child: Text(
            S.of(context).brandMasthead,
            style: MirrorText.overline.copyWith(
                color: MirrorColors.gold, fontSize: 11, letterSpacing: 4.0),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          height: 1.5,
          margin:
              const EdgeInsets.symmetric(horizontal: MirrorSpacing.pagePad),
          color: MirrorColors.divider,
        )
            .animate()
            .scale(
                begin: const Offset(0, 1),
                end: const Offset(1, 1),
                alignment: Alignment.centerLeft,
                duration: 600.ms,
                curve: MirrorCurve.enter),
        const SizedBox(height: 4),
      ]);

  // ── Progress chip ─────────────────────────────────────────────────────────

  Widget _buildProgressChip() {
    final count = _photos.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: count == 3 ? MirrorColors.text1 : MirrorColors.bg2,
        borderRadius: BorderRadius.circular(MirrorRadius.full),
      ),
      child: Text(
        count == 3 ? S.of(context).photoAllDone : S.of(context).photoProgress(count),
        style: MirrorText.overline.copyWith(
            color: count == 3 ? MirrorColors.bg : MirrorColors.text2,
            fontSize: 10),
      ),
    );
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────────

  Widget _buildNav() => Padding(
        padding: const EdgeInsets.fromLTRB(
            MirrorSpacing.pagePad, 16, MirrorSpacing.pagePad, 32),
        child: Row(children: [
          TextButton(
            onPressed: _uploading ? null : _skip,
            child: Text(S.of(context).photoLater,
                style:
                    MirrorText.body.copyWith(color: MirrorColors.text3)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedOpacity(
              opacity: _photos.isNotEmpty ? 1.0 : 0.3,
              duration: MirrorDuration.fast,
              child: ElevatedButton(
                onPressed: (_photos.isNotEmpty && !_uploading) ? _submit : null,
                child: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: MirrorColors.bg, strokeWidth: 1.5))
                    : Text(_photos.length == 3
                        ? S.of(context).photoUploadAndFinish
                        : S.of(context).photoSkipRestAndFinish),
              ),
            ),
          ),
        ]),
      );

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _capture(PhotoAngle angle) async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (xFile == null) return;
    setState(() {
      _photos[angle] = File(xFile.path);
      _uploadFailed = false;
    });
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mirror_photo_captured', true);
    if (!mounted) return;
    context.go(MirrorRoute.home);
  }

  Future<void> _submit() async {
    setState(() { _uploading = true; _uploadFailed = false; });
    try {
      final photoIds = await PhotoApi.instance.uploadPhotos(_photos);

      // Analyze in the background without blocking the user. The provider outlives this
      // screen, so the result is stored in latestBodyAnalysisProvider when it arrives.
      if (photoIds.isNotEmpty) {
        ref.read(latestBodyAnalysisProvider.notifier).analyze(photoIds).ignore();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mirror_photo_captured', true);
      if (!mounted) return;
      context.go(MirrorRoute.home);
    } catch (e) {
      setState(() {
        _uploadFailed = true;
        _uploading = false;
      });
    }
  }
}

// ─── _AngleCard ───────────────────────────────────────────────────────────────

class _AngleCard extends StatefulWidget {
  const _AngleCard({
    required this.angle,
    required this.capturedFile,
    required this.onTap,
  });

  final PhotoAngle angle;
  final File?      capturedFile;
  final VoidCallback onTap;

  @override
  State<_AngleCard> createState() => _AngleCardState();
}

class _AngleCardState extends State<_AngleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final captured = widget.capturedFile != null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: MirrorCurve.snap,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: AnimatedContainer(
            duration: MirrorDuration.fast,
            curve: MirrorCurve.snap,
            decoration: BoxDecoration(
              color: captured ? Colors.transparent : MirrorColors.bg2,
              borderRadius: BorderRadius.circular(MirrorRadius.md),
              border: Border.all(
                color: captured ? MirrorColors.text1 : MirrorColors.divider,
                width: captured ? 1.5 : 0.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: captured
                ? Stack(fit: StackFit.expand, children: [
                    Image.file(widget.capturedFile!, fit: BoxFit.cover),
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          photoAngleLabel(S.of(context), widget.angle),
                          style: MirrorText.overline.copyWith(
                              color: Colors.white, fontSize: 9),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                            color: MirrorColors.text1,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            size: 13, color: MirrorColors.bg),
                      ),
                    ),
                  ])
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined,
                          size: 26, color: MirrorColors.text3),
                      const SizedBox(height: 8),
                      Text(photoAngleLabel(S.of(context), widget.angle),
                          style: MirrorText.bodyS
                              .copyWith(color: MirrorColors.text2)),
                      const SizedBox(height: 4),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          photoAngleHint(S.of(context), widget.angle),
                          style: MirrorText.caption,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
