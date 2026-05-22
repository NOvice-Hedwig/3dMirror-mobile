import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'3D Mirror'**
  String get appName;

  /// No description provided for @authTitle.
  ///
  /// In zh, this message translates to:
  /// **'开始蜕变'**
  String get authTitle;

  /// No description provided for @authSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'你的身体，你来定义'**
  String get authSubtitle;

  /// No description provided for @tabPhone.
  ///
  /// In zh, this message translates to:
  /// **'手机号'**
  String get tabPhone;

  /// No description provided for @tabEmail.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get tabEmail;

  /// No description provided for @sendCode.
  ///
  /// In zh, this message translates to:
  /// **'发送验证码'**
  String get sendCode;

  /// No description provided for @resendCode.
  ///
  /// In zh, this message translates to:
  /// **'重新发送'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In zh, this message translates to:
  /// **'{sec}s 后重发'**
  String resendIn(int sec);

  /// No description provided for @codePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'6位验证码'**
  String get codePlaceholder;

  /// No description provided for @verifyLogin.
  ///
  /// In zh, this message translates to:
  /// **'验证并登录'**
  String get verifyLogin;

  /// No description provided for @orDivider.
  ///
  /// In zh, this message translates to:
  /// **'或'**
  String get orDivider;

  /// No description provided for @appleLogin.
  ///
  /// In zh, this message translates to:
  /// **'使用 Apple 登录'**
  String get appleLogin;

  /// No description provided for @privacyNote.
  ///
  /// In zh, this message translates to:
  /// **'登录即表示同意'**
  String get privacyNote;

  /// No description provided for @privacyLink.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get privacyLink;

  /// No description provided for @and.
  ///
  /// In zh, this message translates to:
  /// **'和'**
  String get and;

  /// No description provided for @termsLink.
  ///
  /// In zh, this message translates to:
  /// **'用户协议'**
  String get termsLink;

  /// No description provided for @errorInvalidCode.
  ///
  /// In zh, this message translates to:
  /// **'验证码错误或已过期'**
  String get errorInvalidCode;

  /// No description provided for @errorSendFailed.
  ///
  /// In zh, this message translates to:
  /// **'发送失败，请稍后重试'**
  String get errorSendFailed;

  /// No description provided for @errorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络错误，请检查连接'**
  String get errorNetwork;

  /// No description provided for @onboardingStep1Eyebrow.
  ///
  /// In zh, this message translates to:
  /// **'关于你'**
  String get onboardingStep1Eyebrow;

  /// No description provided for @onboardingStep1Title.
  ///
  /// In zh, this message translates to:
  /// **'告诉我你的'**
  String get onboardingStep1Title;

  /// No description provided for @onboardingStep1Italic.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get onboardingStep1Italic;

  /// No description provided for @onboardingStep2Eyebrow.
  ///
  /// In zh, this message translates to:
  /// **'最后一步'**
  String get onboardingStep2Eyebrow;

  /// No description provided for @onboardingStep2Title.
  ///
  /// In zh, this message translates to:
  /// **'你的'**
  String get onboardingStep2Title;

  /// No description provided for @onboardingStep2Italic.
  ///
  /// In zh, this message translates to:
  /// **'目标'**
  String get onboardingStep2Italic;

  /// No description provided for @genderMale.
  ///
  /// In zh, this message translates to:
  /// **'男'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In zh, this message translates to:
  /// **'女'**
  String get genderFemale;

  /// No description provided for @labelAge.
  ///
  /// In zh, this message translates to:
  /// **'年龄'**
  String get labelAge;

  /// No description provided for @labelHeight.
  ///
  /// In zh, this message translates to:
  /// **'身高'**
  String get labelHeight;

  /// No description provided for @goalLoseFat.
  ///
  /// In zh, this message translates to:
  /// **'减脂'**
  String get goalLoseFat;

  /// No description provided for @goalLoseFatSub.
  ///
  /// In zh, this message translates to:
  /// **'减少体脂，提升体型'**
  String get goalLoseFatSub;

  /// No description provided for @goalBuildMuscle.
  ///
  /// In zh, this message translates to:
  /// **'增肌'**
  String get goalBuildMuscle;

  /// No description provided for @goalBuildMuscleSub.
  ///
  /// In zh, this message translates to:
  /// **'增加肌肉量，提升力量'**
  String get goalBuildMuscleSub;

  /// No description provided for @goalRecomp.
  ///
  /// In zh, this message translates to:
  /// **'塑形'**
  String get goalRecomp;

  /// No description provided for @goalRecompSub.
  ///
  /// In zh, this message translates to:
  /// **'减脂增肌同步进行'**
  String get goalRecompSub;

  /// No description provided for @goalHealth.
  ///
  /// In zh, this message translates to:
  /// **'健康管理'**
  String get goalHealth;

  /// No description provided for @goalHealthSub.
  ///
  /// In zh, this message translates to:
  /// **'保持健康，改善体能'**
  String get goalHealthSub;

  /// No description provided for @btnNext.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get btnNext;

  /// No description provided for @btnBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get btnBack;

  /// No description provided for @btnStart.
  ///
  /// In zh, this message translates to:
  /// **'开始使用'**
  String get btnStart;

  /// No description provided for @inputEyebrow.
  ///
  /// In zh, this message translates to:
  /// **'今日记录'**
  String get inputEyebrow;

  /// No description provided for @inputTitle.
  ///
  /// In zh, this message translates to:
  /// **'告诉我你的'**
  String get inputTitle;

  /// No description provided for @inputItalic.
  ///
  /// In zh, this message translates to:
  /// **'身体'**
  String get inputItalic;

  /// No description provided for @inputSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'数据越多，镜像越准'**
  String get inputSubtitle;

  /// No description provided for @labelWeight.
  ///
  /// In zh, this message translates to:
  /// **'体重'**
  String get labelWeight;

  /// No description provided for @labelBodyFat.
  ///
  /// In zh, this message translates to:
  /// **'体脂率'**
  String get labelBodyFat;

  /// No description provided for @labelWaist.
  ///
  /// In zh, this message translates to:
  /// **'腰围'**
  String get labelWaist;

  /// No description provided for @labelWorkout.
  ///
  /// In zh, this message translates to:
  /// **'今日运动'**
  String get labelWorkout;

  /// No description provided for @labelDuration.
  ///
  /// In zh, this message translates to:
  /// **'时长'**
  String get labelDuration;

  /// No description provided for @labelIntensity.
  ///
  /// In zh, this message translates to:
  /// **'强度'**
  String get labelIntensity;

  /// No description provided for @intensityLow.
  ///
  /// In zh, this message translates to:
  /// **'轻'**
  String get intensityLow;

  /// No description provided for @intensityMed.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get intensityMed;

  /// No description provided for @intensityHigh.
  ///
  /// In zh, this message translates to:
  /// **'强'**
  String get intensityHigh;

  /// No description provided for @workoutStrength.
  ///
  /// In zh, this message translates to:
  /// **'力量'**
  String get workoutStrength;

  /// No description provided for @workoutCardio.
  ///
  /// In zh, this message translates to:
  /// **'有氧'**
  String get workoutCardio;

  /// No description provided for @workoutHiit.
  ///
  /// In zh, this message translates to:
  /// **'HIIT'**
  String get workoutHiit;

  /// No description provided for @workoutWalk.
  ///
  /// In zh, this message translates to:
  /// **'步行'**
  String get workoutWalk;

  /// No description provided for @workoutYoga.
  ///
  /// In zh, this message translates to:
  /// **'瑜伽'**
  String get workoutYoga;

  /// No description provided for @workoutRest.
  ///
  /// In zh, this message translates to:
  /// **'休息日'**
  String get workoutRest;

  /// No description provided for @workoutSwim.
  ///
  /// In zh, this message translates to:
  /// **'游泳'**
  String get workoutSwim;

  /// No description provided for @workoutCycling.
  ///
  /// In zh, this message translates to:
  /// **'骑行'**
  String get workoutCycling;

  /// No description provided for @ctaGenerate.
  ///
  /// In zh, this message translates to:
  /// **'生成角色'**
  String get ctaGenerate;

  /// No description provided for @unitKg.
  ///
  /// In zh, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitPct.
  ///
  /// In zh, this message translates to:
  /// **'%'**
  String get unitPct;

  /// No description provided for @unitCm.
  ///
  /// In zh, this message translates to:
  /// **'cm'**
  String get unitCm;

  /// No description provided for @unitMin.
  ///
  /// In zh, this message translates to:
  /// **'min'**
  String get unitMin;

  /// No description provided for @confirmBtn.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirmBtn;

  /// No description provided for @cancelBtn.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancelBtn;

  /// No description provided for @resultBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get resultBack;

  /// No description provided for @resultItalic.
  ///
  /// In zh, this message translates to:
  /// **'身体镜像'**
  String get resultItalic;

  /// No description provided for @resultSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'基于今日数据生成'**
  String get resultSubtitle;

  /// No description provided for @metricWeight.
  ///
  /// In zh, this message translates to:
  /// **'体重'**
  String get metricWeight;

  /// No description provided for @metricBodyFat.
  ///
  /// In zh, this message translates to:
  /// **'体脂率'**
  String get metricBodyFat;

  /// No description provided for @metricLeanMass.
  ///
  /// In zh, this message translates to:
  /// **'瘦体重'**
  String get metricLeanMass;

  /// No description provided for @compareTitle.
  ///
  /// In zh, this message translates to:
  /// **'时间对比'**
  String get compareTitle;

  /// No description provided for @compareNow.
  ///
  /// In zh, this message translates to:
  /// **'现在'**
  String get compareNow;

  /// No description provided for @rotateHint.
  ///
  /// In zh, this message translates to:
  /// **'拖动旋转'**
  String get rotateHint;

  /// No description provided for @saveShare.
  ///
  /// In zh, this message translates to:
  /// **'保存 · 分享'**
  String get saveShare;

  /// No description provided for @historyEyebrow.
  ///
  /// In zh, this message translates to:
  /// **'蜕变轨迹'**
  String get historyEyebrow;

  /// No description provided for @historyTitle.
  ///
  /// In zh, this message translates to:
  /// **'每一次'**
  String get historyTitle;

  /// No description provided for @historyItalic.
  ///
  /// In zh, this message translates to:
  /// **'记录'**
  String get historyItalic;

  /// No description provided for @historyEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有记录'**
  String get historyEmpty;

  /// No description provided for @historyEmptySub.
  ///
  /// In zh, this message translates to:
  /// **'完成第一次输入开始追踪'**
  String get historyEmptySub;

  /// No description provided for @historyStart.
  ///
  /// In zh, this message translates to:
  /// **'开始记录'**
  String get historyStart;

  /// No description provided for @historyReplay.
  ///
  /// In zh, this message translates to:
  /// **'点击复现 3D 形体'**
  String get historyReplay;

  /// No description provided for @vsLastWeek.
  ///
  /// In zh, this message translates to:
  /// **'vs 上周'**
  String get vsLastWeek;

  /// No description provided for @navHistory.
  ///
  /// In zh, this message translates to:
  /// **'历史'**
  String get navHistory;

  /// No description provided for @navInput.
  ///
  /// In zh, this message translates to:
  /// **'记录'**
  String get navInput;

  /// No description provided for @loadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get loadFailed;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @saveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败'**
  String get saveFailed;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
