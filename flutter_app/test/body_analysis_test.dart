import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_3d/models/body_photo.dart';
import 'package:mirror_3d/models/models.dart';

// Shape returned by POST /photos/analyze and GET /photos/analysis/latest.
Map<String, dynamic> record({
  String status = 'ok',
  double? shoulder = 0.42, double? waist = 0.3, double? hip = 0.55, double? limb = 0.6,
  String? detail,
}) => {
  'id': '11111111-2222-3333-4444-555555555555',
  'status': status,
  'created_at': '2026-11-14T03:30:00Z',
  'model': status == 'unavailable' ? null : 'claude-haiku-4-5-20251001',
  'photo_ids': ['aaaaaaaa-0000-0000-0000-000000000001'],
  'shoulder_width_norm': shoulder,
  'waist_norm': waist,
  'hip_norm': hip,
  'limb_proportion_norm': limb,
  'detail': detail,
};

const base = AvatarParams(
  heightNorm: 0.3, weightNorm: 0.25, bodyFatNorm: 0.26, waistNorm: 0.10,
  hipNorm: 0.20, shoulderNorm: 0.30, muscleNorm: 0.35, gender: 'female',
);

void main() {
  group('BodyAnalysis.fromJson', () {
    test('ok record', () {
      final a = BodyAnalysis.fromJson(record());
      expect(a.status, AnalysisStatus.ok);
      expect(a.values.shoulderWidthNorm, 0.42);
      expect(a.values.limbProportionNorm, 0.6);
      expect(a.values.hasAnyValue, isTrue);
      expect(a.photoIds, hasLength(1));
      expect(a.createdAt.isUtc, isFalse);                          // converted to local
      expect(a.createdAt.toUtc(), DateTime.utc(2026, 11, 14, 3, 30));
      expect(a.statusLabel, '体型分析已完成');
    });

    test('unavailable and failed records carry no values and a Chinese label', () {
      final u = BodyAnalysis.fromJson(record(status: 'unavailable',
          shoulder: null, waist: null, hip: null, limb: null,
          detail: 'ANTHROPIC_API_KEY is not configured'));
      expect(u.status, AnalysisStatus.unavailable);
      expect(u.values.hasAnyValue, isFalse);
      expect(u.model, isNull);
      expect(u.statusLabel, '体型分析暂不可用');

      final f = BodyAnalysis.fromJson(record(status: 'failed',
          shoulder: null, waist: null, hip: null, limb: null, detail: 'API error 529'));
      expect(f.status, AnalysisStatus.failed);
      expect(f.detail, 'API error 529');
      expect(f.statusLabel, '体型分析失败，请稍后重新拍照');
    });

    test('an unknown status is treated as failed', () {
      expect(BodyAnalysis.fromJson(record(status: 'mystery')).status, AnalysisStatus.failed);
    });
  });

  group('toAvatarOverrides bridges to the unchanged AvatarParams.applyPhotoAnalysis', () {
    final values = BodyAnalysis.fromJson(record()).values;

    test('maps shoulder_width_norm to the shoulder_norm key the avatar reads', () {
      expect(values.toAvatarOverrides(), {
        'shoulder_norm': 0.42, 'waist_norm': 0.3, 'hip_norm': 0.55,
      });
    });

    test('applyPhotoAnalysis picks up the shoulder value through the adapter', () {
      final p = base.applyPhotoAnalysis(values.toAvatarOverrides());
      expect(p.shoulderNorm, 0.42);
      expect(p.waistNorm, 0.3);
      expect(p.hipNorm, 0.55);
      expect(p.photoEnhanced, isTrue);
      expect(p.heightNorm, base.heightNorm);                       // untouched fields kept
    });

    test('without the adapter the shoulder value is silently ignored (the mismatch)', () {
      // The analysis fields as named by the API (shoulder_width_norm, waist_norm, …).
      final raw = <String, double?>{
        for (final e in values.toJson().entries)
          if (e.value is num) e.key: (e.value as num).toDouble(),
      };
      expect(raw, containsPair('shoulder_width_norm', 0.42));
      final p = base.applyPhotoAnalysis(raw);
      expect(p.shoulderNorm, base.shoulderNorm);                   // 0.30, not 0.42
      expect(p.waistNorm, 0.3);
    });

    test('values the model did not estimate keep the current avatar value', () {
      final partial = BodyAnalysis.fromJson(record(shoulder: null, hip: null)).values;
      final p = base.applyPhotoAnalysis(partial.toAvatarOverrides());
      expect(p.shoulderNorm, base.shoulderNorm);
      expect(p.hipNorm, base.hipNorm);
      expect(p.waistNorm, 0.3);
    });
  });
}
