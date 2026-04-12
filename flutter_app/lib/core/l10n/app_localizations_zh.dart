// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '3D Mirror';

  @override
  String get authTitle => '开始蜕变';

  @override
  String get authSubtitle => '你的身体，你来定义';

  @override
  String get tabPhone => '手机号';

  @override
  String get tabEmail => '邮箱';

  @override
  String get sendCode => '发送验证码';

  @override
  String get resendCode => '重新发送';

  @override
  String resendIn(int sec) {
    return '${sec}s 后重发';
  }

  @override
  String get codePlaceholder => '6位验证码';

  @override
  String get verifyLogin => '验证并登录';

  @override
  String get orDivider => '或';

  @override
  String get appleLogin => '使用 Apple 登录';

  @override
  String get privacyNote => '登录即表示同意';

  @override
  String get privacyLink => '隐私政策';

  @override
  String get and => '和';

  @override
  String get termsLink => '用户协议';

  @override
  String get errorInvalidCode => '验证码错误或已过期';

  @override
  String get errorSendFailed => '发送失败，请稍后重试';

  @override
  String get errorNetwork => '网络错误，请检查连接';

  @override
  String get onboardingStep1Eyebrow => '关于你';

  @override
  String get onboardingStep1Title => '告诉我你的';

  @override
  String get onboardingStep1Italic => '基本信息';

  @override
  String get onboardingStep2Eyebrow => '最后一步';

  @override
  String get onboardingStep2Title => '你的';

  @override
  String get onboardingStep2Italic => '目标';

  @override
  String get genderMale => '男';

  @override
  String get genderFemale => '女';

  @override
  String get labelAge => '年龄';

  @override
  String get labelHeight => '身高';

  @override
  String get goalLoseFat => '减脂';

  @override
  String get goalLoseFatSub => '减少体脂，提升体型';

  @override
  String get goalBuildMuscle => '增肌';

  @override
  String get goalBuildMuscleSub => '增加肌肉量，提升力量';

  @override
  String get goalRecomp => '塑形';

  @override
  String get goalRecompSub => '减脂增肌同步进行';

  @override
  String get goalHealth => '健康管理';

  @override
  String get goalHealthSub => '保持健康，改善体能';

  @override
  String get btnNext => '下一步';

  @override
  String get btnBack => '返回';

  @override
  String get btnStart => '开始使用';

  @override
  String get inputEyebrow => '今日记录';

  @override
  String get inputTitle => '告诉我你的';

  @override
  String get inputItalic => '身体';

  @override
  String get inputSubtitle => '数据越多，镜像越准';

  @override
  String get labelWeight => '体重';

  @override
  String get labelBodyFat => '体脂率';

  @override
  String get labelWaist => '腰围';

  @override
  String get labelWorkout => '今日运动';

  @override
  String get labelDuration => '时长';

  @override
  String get labelIntensity => '强度';

  @override
  String get intensityLow => '轻';

  @override
  String get intensityMed => '中';

  @override
  String get intensityHigh => '强';

  @override
  String get workoutStrength => '力量';

  @override
  String get workoutCardio => '有氧';

  @override
  String get workoutHiit => 'HIIT';

  @override
  String get workoutWalk => '步行';

  @override
  String get workoutYoga => '瑜伽';

  @override
  String get workoutRest => '休息日';

  @override
  String get workoutSwim => '游泳';

  @override
  String get workoutCycling => '骑行';

  @override
  String get ctaGenerate => '生成镜像';

  @override
  String get unitKg => 'kg';

  @override
  String get unitPct => '%';

  @override
  String get unitCm => 'cm';

  @override
  String get unitMin => 'min';

  @override
  String get confirmBtn => '确认';

  @override
  String get cancelBtn => '取消';

  @override
  String get resultBack => '返回';

  @override
  String get resultItalic => '身体镜像';

  @override
  String get resultSubtitle => '基于今日数据生成';

  @override
  String get metricWeight => '体重';

  @override
  String get metricBodyFat => '体脂率';

  @override
  String get metricLeanMass => '瘦体重';

  @override
  String get compareTitle => '时间对比';

  @override
  String get compareNow => '现在';

  @override
  String get rotateHint => '拖动旋转';

  @override
  String get saveShare => '保存 · 分享';

  @override
  String get historyEyebrow => '蜕变轨迹';

  @override
  String get historyTitle => '每一次';

  @override
  String get historyItalic => '记录';

  @override
  String get historyEmpty => '还没有记录';

  @override
  String get historyEmptySub => '完成第一次输入开始追踪';

  @override
  String get historyStart => '开始记录';

  @override
  String get historyReplay => '点击复现 3D 形体';

  @override
  String get vsLastWeek => 'vs 上周';

  @override
  String get navHistory => '历史';

  @override
  String get navInput => '记录';

  @override
  String get loadFailed => '加载失败';

  @override
  String get retry => '重试';

  @override
  String get saveFailed => '保存失败';
}
