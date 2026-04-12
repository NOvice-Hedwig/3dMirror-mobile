import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/models.dart';

enum CameraPreset  { front, side, quarter, top }
enum LightingProfile { studioMinimal, softDaylight, dramatic }
enum UnityEventType  { ready, screenshot, morphComplete, error }

class UnityEvent {
  final UnityEventType type;
  final Uint8List? screenshotBytes;
  final String?    errorMessage;
  const UnityEvent({required this.type, this.screenshotBytes, this.errorMessage});

  factory UnityEvent.fromJson(Map<String, dynamic> j) {
    final type = UnityEventType.values.firstWhere(
      (e) => e.name == j['type'], orElse: () => UnityEventType.error);
    return UnityEvent(
      type: type,
      screenshotBytes: j['screenshot'] != null
          ? base64Decode(j['screenshot'] as String) : null,
      errorMessage: j['error'] as String?,
    );
  }
}

class UnityBridge {
  UnityBridge._();
  static final UnityBridge instance = UnityBridge._();

  static const _mc = MethodChannel('com.3dmirror.unity_bridge');
  static const _ec = EventChannel('com.3dmirror.unity_events');

  Stream<UnityEvent>? _stream;
  Stream<UnityEvent> get events {
    _stream ??= _ec.receiveBroadcastStream().map((raw) =>
        UnityEvent.fromJson(json.decode(raw as String) as Map<String, dynamic>));
    return _stream!;
  }

  Future<void> loadAvatar(String avatarId) =>
      _mc.invokeMethod('LoadAvatar', {'avatar_id': avatarId});

  Future<void> applyBodyParams(AvatarParams p, {int durationMs = 600}) =>
      _mc.invokeMethod('ApplyBodyParams', {...p.toJson(), 'duration_ms': durationMs});

  Future<void> setCamera(CameraPreset preset) =>
      _mc.invokeMethod('SetCameraPreset', {'preset': preset.name});

  Future<void> setLighting(LightingProfile profile) =>
      _mc.invokeMethod('SetLightingProfile', {'profile': profile.name});

  Future<void> captureScreenshot() =>
      _mc.invokeMethod('ExportScreenshot');

  Future<void> playAnimation(String name) =>
      _mc.invokeMethod('PlayAnimation', {'name': name});

  Future<void> reset() => _mc.invokeMethod('Reset');

  Future<void> waitForReady({Duration timeout = const Duration(seconds: 10)}) =>
      events.where((e) => e.type == UnityEventType.ready)
          .first.timeout(timeout);

  Future<Uint8List> captureAndFetch() async {
    await captureScreenshot();
    final e = await events.where((e) => e.type == UnityEventType.screenshot)
        .first.timeout(const Duration(seconds: 5));
    return e.screenshotBytes!;
  }
}
