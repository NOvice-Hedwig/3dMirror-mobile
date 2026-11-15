import 'dart:io';

enum PhotoAngle { front, side, back }

extension PhotoAngleLabel on PhotoAngle {
  String get label {
    switch (this) {
      case PhotoAngle.front: return '前视图';
      case PhotoAngle.side:  return '侧视图';
      case PhotoAngle.back:  return '后视图';
    }
  }

  String get hint {
    switch (this) {
      case PhotoAngle.front: return '面向镜头站立';
      case PhotoAngle.side:  return '侧身 90° 站立';
      case PhotoAngle.back:  return '背对镜头站立';
    }
  }

  String get apiValue {
    switch (this) {
      case PhotoAngle.front: return 'front';
      case PhotoAngle.side:  return 'side';
      case PhotoAngle.back:  return 'back';
    }
  }

  static PhotoAngle fromString(String s) {
    switch (s) {
      case 'front': return PhotoAngle.front;
      case 'side':  return PhotoAngle.side;
      case 'back':  return PhotoAngle.back;
      default:      return PhotoAngle.front;
    }
  }
}

// ─── PhotoAnalysisResult ──────────────────────────────────────────────────────

class PhotoAnalysisResult {
  final double? shoulderWidthNorm;
  final double? waistNorm;
  final double? hipNorm;
  final double? limbProportionNorm;
  final Map<String, dynamic> raw;

  const PhotoAnalysisResult({
    this.shoulderWidthNorm,
    this.waistNorm,
    this.hipNorm,
    this.limbProportionNorm,
    required this.raw,
  });

  factory PhotoAnalysisResult.fromJson(Map<String, dynamic> j) =>
      PhotoAnalysisResult(
        shoulderWidthNorm:   (j['shoulder_width_norm'] as num?)?.toDouble(),
        waistNorm:           (j['waist_norm']           as num?)?.toDouble(),
        hipNorm:             (j['hip_norm']             as num?)?.toDouble(),
        limbProportionNorm:  (j['limb_proportion_norm'] as num?)?.toDouble(),
        raw: j,
      );

  Map<String, dynamic> toJson() => {
    'shoulder_width_norm':  shoulderWidthNorm,
    'waist_norm':           waistNorm,
    'hip_norm':             hipNorm,
    'limb_proportion_norm': limbProportionNorm,
    ...raw,
  };

  bool get hasAnyValue =>
      shoulderWidthNorm != null || waistNorm != null || hipNorm != null ||
      limbProportionNorm != null;

  /// The values keyed the way `AvatarParams.applyPhotoAnalysis` (models.dart, owned by the
  /// avatar work) reads them: it expects `shoulder_norm`, while the analysis field is
  /// `shoulder_width_norm`. Pass this map, not [toJson], or the shoulder value is ignored.
  /// `limb_proportion_norm` has no avatar counterpart yet and is not included.
  Map<String, double?> toAvatarOverrides() => {
    'shoulder_norm': shoulderWidthNorm,
    'waist_norm':    waistNorm,
    'hip_norm':      hipNorm,
  };
}

// ─── BodyAnalysis ─────────────────────────────────────────────────────────────

/// 'ok' = at least one value estimated; 'unavailable' = analysis not configured on the server;
/// 'failed' = the run failed (see [BodyAnalysis.detail]).
enum AnalysisStatus { ok, unavailable, failed }

/// One stored analysis run (GET /photos/analysis/latest, POST /photos/analyze).
class BodyAnalysis {
  final String              id;
  final AnalysisStatus      status;
  final DateTime            createdAt;   // local time
  final String?             model;
  final List<String>        photoIds;
  final PhotoAnalysisResult values;      // all null unless status is ok
  final String?             detail;      // reason (unavailable/failed) or note (skipped photos)

  const BodyAnalysis({
    required this.id, required this.status, required this.createdAt,
    required this.photoIds, required this.values, this.model, this.detail,
  });

  factory BodyAnalysis.fromJson(Map<String, dynamic> j) => BodyAnalysis(
    id:        j['id'] as String,
    status:    AnalysisStatus.values.firstWhere(
        (s) => s.name == j['status'], orElse: () => AnalysisStatus.failed),
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
    model:     j['model'] as String?,
    photoIds:  (j['photo_ids'] as List<dynamic>).map((e) => e as String).toList(),
    values:    PhotoAnalysisResult.fromJson(j),
    detail:    j['detail'] as String?,
  );

  /// Short user-facing status text.
  String get statusLabel => switch (status) {
    AnalysisStatus.ok          => '体型分析已完成',
    AnalysisStatus.unavailable => '体型分析暂不可用',
    AnalysisStatus.failed      => '体型分析失败，请稍后重新拍照',
  };
}

// ─── BodyPhoto ────────────────────────────────────────────────────────────────

class BodyPhoto {
  final String                id;
  final String                userId;
  final PhotoAngle            angle;
  final File?                 localFile;   // before upload
  final String?               remoteUrl;   // after upload
  final PhotoAnalysisResult?  analysis;
  final DateTime              createdAt;

  const BodyPhoto({
    required this.id,
    required this.userId,
    required this.angle,
    this.localFile,
    this.remoteUrl,
    this.analysis,
    required this.createdAt,
  });

  factory BodyPhoto.fromJson(Map<String, dynamic> j) => BodyPhoto(
    id:        j['id']      as String,
    userId:    j['user_id'] as String,
    angle:     PhotoAngleLabel.fromString(j['angle'] as String),
    remoteUrl: j['file_path'] as String?,
    analysis:  j['llm_analysis'] != null
        ? PhotoAnalysisResult.fromJson(j['llm_analysis'] as Map<String, dynamic>)
        : null,
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
  );
}
