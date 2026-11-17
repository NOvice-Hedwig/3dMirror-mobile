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
  /// **'{sec}S  ·  重发'**
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
  /// **'OR'**
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
  /// **'ABOUT YOU'**
  String get onboardingStep1Eyebrow;

  /// No description provided for @onboardingStep1Title.
  ///
  /// In zh, this message translates to:
  /// **'告诉我\n你的'**
  String get onboardingStep1Title;

  /// No description provided for @onboardingStep1Italic.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get onboardingStep1Italic;

  /// No description provided for @onboardingStep2Eyebrow.
  ///
  /// In zh, this message translates to:
  /// **'YOUR GOAL'**
  String get onboardingStep2Eyebrow;

  /// No description provided for @onboardingStep2Title.
  ///
  /// In zh, this message translates to:
  /// **'你的\n'**
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
  /// **'Fat Loss — 减少体脂，提升体型'**
  String get goalLoseFatSub;

  /// No description provided for @goalBuildMuscle.
  ///
  /// In zh, this message translates to:
  /// **'增肌'**
  String get goalBuildMuscle;

  /// No description provided for @goalBuildMuscleSub.
  ///
  /// In zh, this message translates to:
  /// **'Muscle — 增加肌肉量，提升力量'**
  String get goalBuildMuscleSub;

  /// No description provided for @goalRecomp.
  ///
  /// In zh, this message translates to:
  /// **'塑形'**
  String get goalRecomp;

  /// No description provided for @goalRecompSub.
  ///
  /// In zh, this message translates to:
  /// **'Recomposition — 减脂增肌同步'**
  String get goalRecompSub;

  /// No description provided for @goalHealth.
  ///
  /// In zh, this message translates to:
  /// **'健康'**
  String get goalHealth;

  /// No description provided for @goalHealthSub.
  ///
  /// In zh, this message translates to:
  /// **'Wellness — 保持健康，改善体能'**
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
  /// **'告诉我\n你的'**
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
  /// **'COMPARE'**
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
  /// **'TRANSFORMATION'**
  String get historyEyebrow;

  /// No description provided for @historyTitle.
  ///
  /// In zh, this message translates to:
  /// **'每一次\n'**
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

  /// No description provided for @meTitle.
  ///
  /// In zh, this message translates to:
  /// **'ME'**
  String get meTitle;

  /// No description provided for @meUserName.
  ///
  /// In zh, this message translates to:
  /// **'3D MIRROR USER'**
  String get meUserName;

  /// No description provided for @meChallenge.
  ///
  /// In zh, this message translates to:
  /// **'CHALLENGE  ·  MODE'**
  String get meChallenge;

  /// No description provided for @meChallengeSub.
  ///
  /// In zh, this message translates to:
  /// **'月目标 · 达成享 8 折'**
  String get meChallengeSub;

  /// No description provided for @meSubscription.
  ///
  /// In zh, this message translates to:
  /// **'SUBSCRIPTION'**
  String get meSubscription;

  /// No description provided for @meSubscriptionSub.
  ///
  /// In zh, this message translates to:
  /// **'管理订阅'**
  String get meSubscriptionSub;

  /// No description provided for @meLanguage.
  ///
  /// In zh, this message translates to:
  /// **'LANGUAGE'**
  String get meLanguage;

  /// No description provided for @meSignOut.
  ///
  /// In zh, this message translates to:
  /// **'SIGN  ·  OUT'**
  String get meSignOut;

  /// No description provided for @comingSoon.
  ///
  /// In zh, this message translates to:
  /// **'SOON'**
  String get comingSoon;

  /// No description provided for @languageSheetTitle.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get languageSheetTitle;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get languageSystem;

  /// No description provided for @languageSystemCurrent.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统 · {language}'**
  String languageSystemCurrent(String language);

  /// No description provided for @languageZh.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageZh;

  /// No description provided for @languageEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @brandMasthead.
  ///
  /// In zh, this message translates to:
  /// **'3D MIRROR'**
  String get brandMasthead;

  /// No description provided for @authTitleLead.
  ///
  /// In zh, this message translates to:
  /// **'开始\n'**
  String get authTitleLead;

  /// No description provided for @authTitleEmphasis.
  ///
  /// In zh, this message translates to:
  /// **'蜕变'**
  String get authTitleEmphasis;

  /// No description provided for @authContinueWith.
  ///
  /// In zh, this message translates to:
  /// **'CONTINUE WITH'**
  String get authContinueWith;

  /// No description provided for @phonePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'手机号'**
  String get phonePlaceholder;

  /// No description provided for @countrySearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索国家/地区或区号'**
  String get countrySearchHint;

  /// No description provided for @countryNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有找到匹配的国家/地区'**
  String get countryNoMatch;

  /// No description provided for @errorPhoneEmpty.
  ///
  /// In zh, this message translates to:
  /// **'请输入手机号'**
  String get errorPhoneEmpty;

  /// No description provided for @errorPhoneNeedsCountryCode.
  ///
  /// In zh, this message translates to:
  /// **'请选择国家/地区代码，例如 +86'**
  String get errorPhoneNeedsCountryCode;

  /// No description provided for @errorPhoneInvalid.
  ///
  /// In zh, this message translates to:
  /// **'该国家/地区的手机号格式不正确'**
  String get errorPhoneInvalid;

  /// No description provided for @errorPhoneNotMobile.
  ///
  /// In zh, this message translates to:
  /// **'仅支持手机号，不支持座机、免费电话等号码'**
  String get errorPhoneNotMobile;

  /// No description provided for @errorEmailEmpty.
  ///
  /// In zh, this message translates to:
  /// **'请输入邮箱'**
  String get errorEmailEmpty;

  /// No description provided for @errorEmailInvalid.
  ///
  /// In zh, this message translates to:
  /// **'邮箱格式不正确'**
  String get errorEmailInvalid;

  /// No description provided for @errorRateLimited.
  ///
  /// In zh, this message translates to:
  /// **'请求过于频繁，请稍后再试'**
  String get errorRateLimited;

  /// No description provided for @errorAppleSignIn.
  ///
  /// In zh, this message translates to:
  /// **'Apple 登录失败，请重试'**
  String get errorAppleSignIn;

  /// No description provided for @errorNetworkStatus.
  ///
  /// In zh, this message translates to:
  /// **'网络错误 ({status})'**
  String errorNetworkStatus(int status);

  /// No description provided for @sessionExpired.
  ///
  /// In zh, this message translates to:
  /// **'登录已过期，请重新登录'**
  String get sessionExpired;

  /// No description provided for @fabWorkout.
  ///
  /// In zh, this message translates to:
  /// **'运动'**
  String get fabWorkout;

  /// No description provided for @fabDiet.
  ///
  /// In zh, this message translates to:
  /// **'饮食'**
  String get fabDiet;

  /// No description provided for @fabSleep.
  ///
  /// In zh, this message translates to:
  /// **'睡眠'**
  String get fabSleep;

  /// No description provided for @fabHealth.
  ///
  /// In zh, this message translates to:
  /// **'健康'**
  String get fabHealth;

  /// No description provided for @fabSupplement.
  ///
  /// In zh, this message translates to:
  /// **'补剂'**
  String get fabSupplement;

  /// No description provided for @sheetSave.
  ///
  /// In zh, this message translates to:
  /// **'SAVE  ·  RECORD'**
  String get sheetSave;

  /// No description provided for @saveFailedDetail.
  ///
  /// In zh, this message translates to:
  /// **'保存失败：{error}'**
  String saveFailedDetail(String error);

  /// No description provided for @logOptional.
  ///
  /// In zh, this message translates to:
  /// **'选填'**
  String get logOptional;

  /// No description provided for @logIntensityTitle.
  ///
  /// In zh, this message translates to:
  /// **'INTENSITY'**
  String get logIntensityTitle;

  /// No description provided for @editBtn.
  ///
  /// In zh, this message translates to:
  /// **'修改'**
  String get editBtn;

  /// No description provided for @workoutSheetTitle.
  ///
  /// In zh, this message translates to:
  /// **'TYPE  ·  LOG'**
  String get workoutSheetTitle;

  /// No description provided for @workoutTypeSelect.
  ///
  /// In zh, this message translates to:
  /// **'TYPE  ·  SELECT'**
  String get workoutTypeSelect;

  /// No description provided for @workoutCardioTypeTitle.
  ///
  /// In zh, this message translates to:
  /// **'CARDIO  ·  TYPE'**
  String get workoutCardioTypeTitle;

  /// No description provided for @workoutPilatesTypeTitle.
  ///
  /// In zh, this message translates to:
  /// **'PILATES  ·  TYPE'**
  String get workoutPilatesTypeTitle;

  /// No description provided for @workoutSportTypeTitle.
  ///
  /// In zh, this message translates to:
  /// **'SPORT  ·  TYPE'**
  String get workoutSportTypeTitle;

  /// No description provided for @workoutOtherNameTitle.
  ///
  /// In zh, this message translates to:
  /// **'OTHER  ·  NAME'**
  String get workoutOtherNameTitle;

  /// No description provided for @workoutMuscleGroupTitle.
  ///
  /// In zh, this message translates to:
  /// **'MUSCLE  ·  GROUP'**
  String get workoutMuscleGroupTitle;

  /// No description provided for @workoutDurationIntensityTitle.
  ///
  /// In zh, this message translates to:
  /// **'DURATION  ·  INTENSITY'**
  String get workoutDurationIntensityTitle;

  /// No description provided for @workoutSetsTitle.
  ///
  /// In zh, this message translates to:
  /// **'SETS  ·  LOG'**
  String get workoutSetsTitle;

  /// No description provided for @workoutCalorieTitle.
  ///
  /// In zh, this message translates to:
  /// **'CALORIE  ·  EST'**
  String get workoutCalorieTitle;

  /// No description provided for @workoutErrorMuscleGroup.
  ///
  /// In zh, this message translates to:
  /// **'请选择训练部位'**
  String get workoutErrorMuscleGroup;

  /// No description provided for @workoutErrorNoSets.
  ///
  /// In zh, this message translates to:
  /// **'请至少添加一组'**
  String get workoutErrorNoSets;

  /// No description provided for @workoutErrorMinDuration.
  ///
  /// In zh, this message translates to:
  /// **'时长至少 5 分钟'**
  String get workoutErrorMinDuration;

  /// No description provided for @workoutSaved.
  ///
  /// In zh, this message translates to:
  /// **'运动已记录'**
  String get workoutSaved;

  /// No description provided for @workoutOtherNameField.
  ///
  /// In zh, this message translates to:
  /// **'运动名称'**
  String get workoutOtherNameField;

  /// No description provided for @workoutExerciseSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索动作'**
  String get workoutExerciseSearch;

  /// No description provided for @unitMinutes.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get unitMinutes;

  /// No description provided for @workoutWithWeight.
  ///
  /// In zh, this message translates to:
  /// **'附加负重'**
  String get workoutWithWeight;

  /// No description provided for @workoutWeightField.
  ///
  /// In zh, this message translates to:
  /// **'负重 kg'**
  String get workoutWeightField;

  /// No description provided for @workoutAddSet.
  ///
  /// In zh, this message translates to:
  /// **'+ 添加一组'**
  String get workoutAddSet;

  /// No description provided for @workoutReps.
  ///
  /// In zh, this message translates to:
  /// **'次数'**
  String get workoutReps;

  /// No description provided for @workoutEstimatedBurn.
  ///
  /// In zh, this message translates to:
  /// **'估算消耗'**
  String get workoutEstimatedBurn;

  /// No description provided for @workoutIntensityLow.
  ///
  /// In zh, this message translates to:
  /// **'低'**
  String get workoutIntensityLow;

  /// No description provided for @workoutIntensityMedium.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get workoutIntensityMedium;

  /// No description provided for @workoutIntensityHigh.
  ///
  /// In zh, this message translates to:
  /// **'高'**
  String get workoutIntensityHigh;

  /// No description provided for @workoutTypeCardio.
  ///
  /// In zh, this message translates to:
  /// **'有氧'**
  String get workoutTypeCardio;

  /// No description provided for @workoutTypeStrength.
  ///
  /// In zh, this message translates to:
  /// **'无氧'**
  String get workoutTypeStrength;

  /// No description provided for @workoutTypePilates.
  ///
  /// In zh, this message translates to:
  /// **'普拉提'**
  String get workoutTypePilates;

  /// No description provided for @workoutTypeBall.
  ///
  /// In zh, this message translates to:
  /// **'球类'**
  String get workoutTypeBall;

  /// No description provided for @workoutTypeOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get workoutTypeOther;

  /// No description provided for @subTypeRunning.
  ///
  /// In zh, this message translates to:
  /// **'跑步'**
  String get subTypeRunning;

  /// No description provided for @subTypeJumpRope.
  ///
  /// In zh, this message translates to:
  /// **'跳绳'**
  String get subTypeJumpRope;

  /// No description provided for @subTypeAerobics.
  ///
  /// In zh, this message translates to:
  /// **'跳操'**
  String get subTypeAerobics;

  /// No description provided for @subTypeHiit.
  ///
  /// In zh, this message translates to:
  /// **'HIIT'**
  String get subTypeHiit;

  /// No description provided for @subTypeSwimming.
  ///
  /// In zh, this message translates to:
  /// **'游泳'**
  String get subTypeSwimming;

  /// No description provided for @subTypeHiking.
  ///
  /// In zh, this message translates to:
  /// **'爬山'**
  String get subTypeHiking;

  /// No description provided for @subTypeCycling.
  ///
  /// In zh, this message translates to:
  /// **'骑行'**
  String get subTypeCycling;

  /// No description provided for @subTypeOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get subTypeOther;

  /// No description provided for @subTypeMatPilates.
  ///
  /// In zh, this message translates to:
  /// **'垫上普拉提'**
  String get subTypeMatPilates;

  /// No description provided for @subTypeReformerPilates.
  ///
  /// In zh, this message translates to:
  /// **'器械普拉提'**
  String get subTypeReformerPilates;

  /// No description provided for @subTypeBasketball.
  ///
  /// In zh, this message translates to:
  /// **'篮球'**
  String get subTypeBasketball;

  /// No description provided for @subTypeBadminton.
  ///
  /// In zh, this message translates to:
  /// **'羽毛球'**
  String get subTypeBadminton;

  /// No description provided for @subTypeTennis.
  ///
  /// In zh, this message translates to:
  /// **'网球'**
  String get subTypeTennis;

  /// No description provided for @subTypeTableTennis.
  ///
  /// In zh, this message translates to:
  /// **'乒乓球'**
  String get subTypeTableTennis;

  /// No description provided for @subTypeFootball.
  ///
  /// In zh, this message translates to:
  /// **'足球'**
  String get subTypeFootball;

  /// No description provided for @muscleChest.
  ///
  /// In zh, this message translates to:
  /// **'胸'**
  String get muscleChest;

  /// No description provided for @muscleBack.
  ///
  /// In zh, this message translates to:
  /// **'背'**
  String get muscleBack;

  /// No description provided for @muscleLegs.
  ///
  /// In zh, this message translates to:
  /// **'腿'**
  String get muscleLegs;

  /// No description provided for @muscleShoulders.
  ///
  /// In zh, this message translates to:
  /// **'肩'**
  String get muscleShoulders;

  /// No description provided for @muscleArms.
  ///
  /// In zh, this message translates to:
  /// **'手臂'**
  String get muscleArms;

  /// No description provided for @muscleCore.
  ///
  /// In zh, this message translates to:
  /// **'核心'**
  String get muscleCore;

  /// No description provided for @dietSheetTitle.
  ///
  /// In zh, this message translates to:
  /// **'MEAL  ·  LOG'**
  String get dietSheetTitle;

  /// No description provided for @dietMealTypeTitle.
  ///
  /// In zh, this message translates to:
  /// **'MEAL  ·  TYPE'**
  String get dietMealTypeTitle;

  /// No description provided for @dietEntryMethodTitle.
  ///
  /// In zh, this message translates to:
  /// **'ENTRY  ·  METHOD'**
  String get dietEntryMethodTitle;

  /// No description provided for @mealBreakfast.
  ///
  /// In zh, this message translates to:
  /// **'早餐'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In zh, this message translates to:
  /// **'午餐'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In zh, this message translates to:
  /// **'晚餐'**
  String get mealDinner;

  /// No description provided for @mealSnack.
  ///
  /// In zh, this message translates to:
  /// **'加餐'**
  String get mealSnack;

  /// No description provided for @dietMethodSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get dietMethodSearch;

  /// No description provided for @dietMethodManual.
  ///
  /// In zh, this message translates to:
  /// **'手动'**
  String get dietMethodManual;

  /// No description provided for @dietSearchFood.
  ///
  /// In zh, this message translates to:
  /// **'搜索食物'**
  String get dietSearchFood;

  /// No description provided for @dietSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'鸡胸肉、燕麦…'**
  String get dietSearchHint;

  /// No description provided for @dietFoodName.
  ///
  /// In zh, this message translates to:
  /// **'食物名称'**
  String get dietFoodName;

  /// No description provided for @dietGrams.
  ///
  /// In zh, this message translates to:
  /// **'克重'**
  String get dietGrams;

  /// No description provided for @dietCalories.
  ///
  /// In zh, this message translates to:
  /// **'卡路里 *'**
  String get dietCalories;

  /// No description provided for @dietProtein.
  ///
  /// In zh, this message translates to:
  /// **'蛋白质 g（选填）'**
  String get dietProtein;

  /// No description provided for @dietErrorName.
  ///
  /// In zh, this message translates to:
  /// **'请输入食物名称'**
  String get dietErrorName;

  /// No description provided for @dietErrorCalories.
  ///
  /// In zh, this message translates to:
  /// **'请输入卡路里'**
  String get dietErrorCalories;

  /// No description provided for @dietSaved.
  ///
  /// In zh, this message translates to:
  /// **'饮食已记录'**
  String get dietSaved;

  /// No description provided for @healthSheetTitle.
  ///
  /// In zh, this message translates to:
  /// **'HEALTH  ·  LOG'**
  String get healthSheetTitle;

  /// No description provided for @healthMeasureTitle.
  ///
  /// In zh, this message translates to:
  /// **'BODY  ·  MEASURE'**
  String get healthMeasureTitle;

  /// No description provided for @healthPeriodTitle.
  ///
  /// In zh, this message translates to:
  /// **'PERIOD  ·  LOG'**
  String get healthPeriodTitle;

  /// No description provided for @healthSymptomsTitle.
  ///
  /// In zh, this message translates to:
  /// **'SYMPTOMS'**
  String get healthSymptomsTitle;

  /// No description provided for @measureWeightKg.
  ///
  /// In zh, this message translates to:
  /// **'体重 kg'**
  String get measureWeightKg;

  /// No description provided for @measureWaistCm.
  ///
  /// In zh, this message translates to:
  /// **'腰围 cm'**
  String get measureWaistCm;

  /// No description provided for @measureHipCm.
  ///
  /// In zh, this message translates to:
  /// **'臀围 cm'**
  String get measureHipCm;

  /// No description provided for @measureChestCm.
  ///
  /// In zh, this message translates to:
  /// **'胸围 cm'**
  String get measureChestCm;

  /// No description provided for @measureThighCm.
  ///
  /// In zh, this message translates to:
  /// **'大腿围 cm'**
  String get measureThighCm;

  /// No description provided for @periodStart.
  ///
  /// In zh, this message translates to:
  /// **'经期开始'**
  String get periodStart;

  /// No description provided for @periodOngoing.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get periodOngoing;

  /// No description provided for @periodEnd.
  ///
  /// In zh, this message translates to:
  /// **'经期结束'**
  String get periodEnd;

  /// No description provided for @periodIntensityLight.
  ///
  /// In zh, this message translates to:
  /// **'轻'**
  String get periodIntensityLight;

  /// No description provided for @periodIntensityModerate.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get periodIntensityModerate;

  /// No description provided for @periodIntensityHeavy.
  ///
  /// In zh, this message translates to:
  /// **'重'**
  String get periodIntensityHeavy;

  /// No description provided for @symptomCramps.
  ///
  /// In zh, this message translates to:
  /// **'痛经'**
  String get symptomCramps;

  /// No description provided for @symptomMoodSwings.
  ///
  /// In zh, this message translates to:
  /// **'情绪波动'**
  String get symptomMoodSwings;

  /// No description provided for @symptomSwelling.
  ///
  /// In zh, this message translates to:
  /// **'水肿'**
  String get symptomSwelling;

  /// No description provided for @symptomAcne.
  ///
  /// In zh, this message translates to:
  /// **'长痘'**
  String get symptomAcne;

  /// No description provided for @symptomFatigue.
  ///
  /// In zh, this message translates to:
  /// **'疲劳'**
  String get symptomFatigue;

  /// No description provided for @symptomBackPain.
  ///
  /// In zh, this message translates to:
  /// **'腰酸'**
  String get symptomBackPain;

  /// No description provided for @healthErrorEmpty.
  ///
  /// In zh, this message translates to:
  /// **'请至少填写一项数据'**
  String get healthErrorEmpty;

  /// No description provided for @healthSaved.
  ///
  /// In zh, this message translates to:
  /// **'健康数据已记录'**
  String get healthSaved;

  /// No description provided for @sleepSheetTitle.
  ///
  /// In zh, this message translates to:
  /// **'SLEEP  ·  LOG'**
  String get sleepSheetTitle;

  /// No description provided for @sleepTimeTitle.
  ///
  /// In zh, this message translates to:
  /// **'SLEEP  ·  TIME'**
  String get sleepTimeTitle;

  /// No description provided for @sleepDurationTitle.
  ///
  /// In zh, this message translates to:
  /// **'DURATION  ·  CALC'**
  String get sleepDurationTitle;

  /// No description provided for @sleepQualityTitle.
  ///
  /// In zh, this message translates to:
  /// **'SLEEP  ·  QUALITY'**
  String get sleepQualityTitle;

  /// No description provided for @sleepBedtime.
  ///
  /// In zh, this message translates to:
  /// **'入睡'**
  String get sleepBedtime;

  /// No description provided for @sleepWake.
  ///
  /// In zh, this message translates to:
  /// **'起床'**
  String get sleepWake;

  /// No description provided for @sleepDuration.
  ///
  /// In zh, this message translates to:
  /// **'睡眠时长'**
  String get sleepDuration;

  /// No description provided for @sleepShortConfirm.
  ///
  /// In zh, this message translates to:
  /// **'睡眠时间不足 1 小时，是否确认保存？'**
  String get sleepShortConfirm;

  /// No description provided for @sleepSaved.
  ///
  /// In zh, this message translates to:
  /// **'睡眠已记录'**
  String get sleepSaved;

  /// No description provided for @supplementSheetTitle.
  ///
  /// In zh, this message translates to:
  /// **'SUPPLEMENT  ·  LOG'**
  String get supplementSheetTitle;

  /// No description provided for @supplementSelectTitle.
  ///
  /// In zh, this message translates to:
  /// **'SUPPLEMENT  ·  SELECT'**
  String get supplementSelectTitle;

  /// No description provided for @supplementCustomTitle.
  ///
  /// In zh, this message translates to:
  /// **'CUSTOM  ·  ADD'**
  String get supplementCustomTitle;

  /// No description provided for @supplementReminderTitle.
  ///
  /// In zh, this message translates to:
  /// **'REMINDER  ·  TIME'**
  String get supplementReminderTitle;

  /// No description provided for @supplementNameField.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get supplementNameField;

  /// No description provided for @supplementNameHint.
  ///
  /// In zh, this message translates to:
  /// **'如：谷氨酰胺'**
  String get supplementNameHint;

  /// No description provided for @supplementDosageField.
  ///
  /// In zh, this message translates to:
  /// **'剂量'**
  String get supplementDosageField;

  /// No description provided for @supplementDosageHint.
  ///
  /// In zh, this message translates to:
  /// **'30g、2粒'**
  String get supplementDosageHint;

  /// No description provided for @supplementPickTime.
  ///
  /// In zh, this message translates to:
  /// **'选择时间'**
  String get supplementPickTime;

  /// No description provided for @supplementErrorEmpty.
  ///
  /// In zh, this message translates to:
  /// **'请至少选择或填写一种补剂'**
  String get supplementErrorEmpty;

  /// No description provided for @supplementSaved.
  ///
  /// In zh, this message translates to:
  /// **'补剂已记录'**
  String get supplementSaved;

  /// No description provided for @supplementProteinPowder.
  ///
  /// In zh, this message translates to:
  /// **'蛋白粉'**
  String get supplementProteinPowder;

  /// No description provided for @supplementCreatine.
  ///
  /// In zh, this message translates to:
  /// **'肌酸'**
  String get supplementCreatine;

  /// No description provided for @supplementVitaminD.
  ///
  /// In zh, this message translates to:
  /// **'维生素D'**
  String get supplementVitaminD;

  /// No description provided for @supplementCollagen.
  ///
  /// In zh, this message translates to:
  /// **'胶原蛋白'**
  String get supplementCollagen;

  /// No description provided for @supplementFishOil.
  ///
  /// In zh, this message translates to:
  /// **'鱼油'**
  String get supplementFishOil;

  /// No description provided for @supplementVitaminC.
  ///
  /// In zh, this message translates to:
  /// **'维生素C'**
  String get supplementVitaminC;

  /// No description provided for @supplementIron.
  ///
  /// In zh, this message translates to:
  /// **'铁'**
  String get supplementIron;

  /// No description provided for @supplementFolicAcid.
  ///
  /// In zh, this message translates to:
  /// **'叶酸'**
  String get supplementFolicAcid;

  /// No description provided for @supplementMagnesium.
  ///
  /// In zh, this message translates to:
  /// **'镁'**
  String get supplementMagnesium;

  /// No description provided for @supplementZinc.
  ///
  /// In zh, this message translates to:
  /// **'锌'**
  String get supplementZinc;

  /// No description provided for @onboardingConsentEyebrow.
  ///
  /// In zh, this message translates to:
  /// **'LEGAL & PRIVACY'**
  String get onboardingConsentEyebrow;

  /// No description provided for @onboardingConsentTitle.
  ///
  /// In zh, this message translates to:
  /// **'条款与\n'**
  String get onboardingConsentTitle;

  /// No description provided for @onboardingConsentItalic.
  ///
  /// In zh, this message translates to:
  /// **'隐私协议'**
  String get onboardingConsentItalic;

  /// No description provided for @onboardingConsentIntro.
  ///
  /// In zh, this message translates to:
  /// **'在开始使用 3D Mirror 之前，请确认以下内容：'**
  String get onboardingConsentIntro;

  /// No description provided for @onboardingConsentBullet1.
  ///
  /// In zh, this message translates to:
  /// **'你的身体数据（身高、体重、三围）将用于生成专属 3D 体型模型'**
  String get onboardingConsentBullet1;

  /// No description provided for @onboardingConsentBullet2.
  ///
  /// In zh, this message translates to:
  /// **'体型照片将上传至服务器，由 AI 分析体型比例，仅用于建模，不作其他用途'**
  String get onboardingConsentBullet2;

  /// No description provided for @onboardingConsentBullet3.
  ///
  /// In zh, this message translates to:
  /// **'所有数据经过加密存储，我们不会出售或共享你的个人信息'**
  String get onboardingConsentBullet3;

  /// No description provided for @onboardingConsentBullet4.
  ///
  /// In zh, this message translates to:
  /// **'AI 预测结果仅供参考，不构成医疗建议'**
  String get onboardingConsentBullet4;

  /// No description provided for @onboardingAcceptTerms.
  ///
  /// In zh, this message translates to:
  /// **'我已阅读并同意《服务条款》'**
  String get onboardingAcceptTerms;

  /// No description provided for @onboardingAcceptTermsSub.
  ///
  /// In zh, this message translates to:
  /// **'Terms of Service'**
  String get onboardingAcceptTermsSub;

  /// No description provided for @onboardingAcceptPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'我已阅读并同意《隐私政策》'**
  String get onboardingAcceptPrivacy;

  /// No description provided for @onboardingAcceptPrivacySub.
  ///
  /// In zh, this message translates to:
  /// **'Privacy Policy — AI Data Usage'**
  String get onboardingAcceptPrivacySub;

  /// No description provided for @onboardingAgeValue.
  ///
  /// In zh, this message translates to:
  /// **'{age} 岁'**
  String onboardingAgeValue(int age);

  /// No description provided for @onboardingHeightPicker.
  ///
  /// In zh, this message translates to:
  /// **'身高 (cm)'**
  String get onboardingHeightPicker;

  /// No description provided for @onboardingWeightPicker.
  ///
  /// In zh, this message translates to:
  /// **'体重 (kg)'**
  String get onboardingWeightPicker;

  /// No description provided for @photoScanEyebrow.
  ///
  /// In zh, this message translates to:
  /// **'BODY SCAN'**
  String get photoScanEyebrow;

  /// No description provided for @photoTitleLead.
  ///
  /// In zh, this message translates to:
  /// **'记录你的\n'**
  String get photoTitleLead;

  /// No description provided for @photoTitleEmphasis.
  ///
  /// In zh, this message translates to:
  /// **'体型'**
  String get photoTitleEmphasis;

  /// No description provided for @photoIntro.
  ///
  /// In zh, this message translates to:
  /// **'拍摄三个角度的照片，帮助 AI 建立更准确的 3D 体型模型。'**
  String get photoIntro;

  /// No description provided for @photoAllDone.
  ///
  /// In zh, this message translates to:
  /// **'全部完成 ✓'**
  String get photoAllDone;

  /// No description provided for @photoProgress.
  ///
  /// In zh, this message translates to:
  /// **'已完成 {count} / 3'**
  String photoProgress(int count);

  /// No description provided for @photoLater.
  ///
  /// In zh, this message translates to:
  /// **'稍后再说'**
  String get photoLater;

  /// No description provided for @photoUploadAndFinish.
  ///
  /// In zh, this message translates to:
  /// **'上传并完成'**
  String get photoUploadAndFinish;

  /// No description provided for @photoSkipRestAndFinish.
  ///
  /// In zh, this message translates to:
  /// **'跳过剩余并完成'**
  String get photoSkipRestAndFinish;

  /// No description provided for @photoUploadFailed.
  ///
  /// In zh, this message translates to:
  /// **'上传失败，请检查网络连接后重试。'**
  String get photoUploadFailed;

  /// No description provided for @photoAngleFront.
  ///
  /// In zh, this message translates to:
  /// **'前视图'**
  String get photoAngleFront;

  /// No description provided for @photoAngleSide.
  ///
  /// In zh, this message translates to:
  /// **'侧视图'**
  String get photoAngleSide;

  /// No description provided for @photoAngleBack.
  ///
  /// In zh, this message translates to:
  /// **'后视图'**
  String get photoAngleBack;

  /// No description provided for @photoHintFront.
  ///
  /// In zh, this message translates to:
  /// **'面向镜头站立'**
  String get photoHintFront;

  /// No description provided for @photoHintSide.
  ///
  /// In zh, this message translates to:
  /// **'侧身 90° 站立'**
  String get photoHintSide;

  /// No description provided for @photoHintBack.
  ///
  /// In zh, this message translates to:
  /// **'背对镜头站立'**
  String get photoHintBack;

  /// No description provided for @analysisStatusOk.
  ///
  /// In zh, this message translates to:
  /// **'体型分析已完成'**
  String get analysisStatusOk;

  /// No description provided for @analysisStatusUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'体型分析暂不可用'**
  String get analysisStatusUnavailable;

  /// No description provided for @analysisStatusFailed.
  ///
  /// In zh, this message translates to:
  /// **'体型分析失败，请稍后重新拍照'**
  String get analysisStatusFailed;

  /// No description provided for @workoutOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get workoutOther;

  /// No description provided for @inputBodyDataTitle.
  ///
  /// In zh, this message translates to:
  /// **'BODY  ·  DATA'**
  String get inputBodyDataTitle;

  /// No description provided for @inputActivityTitle.
  ///
  /// In zh, this message translates to:
  /// **'TODAY\'S ACTIVITY'**
  String get inputActivityTitle;

  /// No description provided for @inputDayLabel.
  ///
  /// In zh, this message translates to:
  /// **'DAY {day}  ·  {date}'**
  String inputDayLabel(int day, String date);

  /// No description provided for @inputPickWeight.
  ///
  /// In zh, this message translates to:
  /// **'体重 (kg)'**
  String get inputPickWeight;

  /// No description provided for @inputPickBodyFat.
  ///
  /// In zh, this message translates to:
  /// **'体脂率 (%)'**
  String get inputPickBodyFat;

  /// No description provided for @inputPickWaist.
  ///
  /// In zh, this message translates to:
  /// **'腰围 (cm)'**
  String get inputPickWaist;

  /// No description provided for @inputPickDuration.
  ///
  /// In zh, this message translates to:
  /// **'训练时长 (min)'**
  String get inputPickDuration;

  /// No description provided for @historyTodayRecord.
  ///
  /// In zh, this message translates to:
  /// **'TODAY  ·  RECORD'**
  String get historyTodayRecord;

  /// No description provided for @historyRecordsTitle.
  ///
  /// In zh, this message translates to:
  /// **'RECORDS'**
  String get historyRecordsTitle;

  /// No description provided for @historyCompareSelect.
  ///
  /// In zh, this message translates to:
  /// **'COMPARE  ·  SELECT'**
  String get historyCompareSelect;

  /// No description provided for @historySelectedTwo.
  ///
  /// In zh, this message translates to:
  /// **'已选 2 项'**
  String get historySelectedTwo;

  /// No description provided for @historySelectMore.
  ///
  /// In zh, this message translates to:
  /// **'再选 {count} 项'**
  String historySelectMore(int count);

  /// No description provided for @historyCompareAction.
  ///
  /// In zh, this message translates to:
  /// **'对比'**
  String get historyCompareAction;

  /// No description provided for @historyVsPrev.
  ///
  /// In zh, this message translates to:
  /// **'vs prev'**
  String get historyVsPrev;

  /// No description provided for @predictTag.
  ///
  /// In zh, this message translates to:
  /// **'预测'**
  String get predictTag;

  /// No description provided for @snapshotMasthead.
  ///
  /// In zh, this message translates to:
  /// **'SNAPSHOTS'**
  String get snapshotMasthead;

  /// No description provided for @snapshotRecordCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} RECORDS'**
  String snapshotRecordCount(int count);

  /// No description provided for @snapshotWeightTrend.
  ///
  /// In zh, this message translates to:
  /// **'WEIGHT  ·  TREND'**
  String get snapshotWeightTrend;

  /// No description provided for @snapshotSessions.
  ///
  /// In zh, this message translates to:
  /// **'记录次数'**
  String get snapshotSessions;

  /// No description provided for @snapshotSessionsUnit.
  ///
  /// In zh, this message translates to:
  /// **'次'**
  String get snapshotSessionsUnit;

  /// No description provided for @snapshotWeightChange.
  ///
  /// In zh, this message translates to:
  /// **'体重变化'**
  String get snapshotWeightChange;

  /// No description provided for @snapshotDaysActive.
  ///
  /// In zh, this message translates to:
  /// **'坚持天数'**
  String get snapshotDaysActive;

  /// No description provided for @snapshotDaysUnit.
  ///
  /// In zh, this message translates to:
  /// **'天'**
  String get snapshotDaysUnit;

  /// No description provided for @snapshotLatest.
  ///
  /// In zh, this message translates to:
  /// **'LATEST'**
  String get snapshotLatest;

  /// No description provided for @compareBodyCompare.
  ///
  /// In zh, this message translates to:
  /// **'BODY  ·  COMPARE'**
  String get compareBodyCompare;

  /// No description provided for @compareOverlay.
  ///
  /// In zh, this message translates to:
  /// **'叠加'**
  String get compareOverlay;

  /// No description provided for @compareDelta.
  ///
  /// In zh, this message translates to:
  /// **'DELTA'**
  String get compareDelta;

  /// No description provided for @comparePredictLabel.
  ///
  /// In zh, this message translates to:
  /// **'预测 · {weeks}W'**
  String comparePredictLabel(int weeks);

  /// No description provided for @predictMasthead.
  ///
  /// In zh, this message translates to:
  /// **'PREDICT'**
  String get predictMasthead;

  /// No description provided for @predictBodyFuture.
  ///
  /// In zh, this message translates to:
  /// **'BODY  ·  FUTURE'**
  String get predictBodyFuture;

  /// No description provided for @predictTimeRange.
  ///
  /// In zh, this message translates to:
  /// **'TIME  ·  RANGE'**
  String get predictTimeRange;

  /// No description provided for @predictWeeks.
  ///
  /// In zh, this message translates to:
  /// **'{weeks} W'**
  String predictWeeks(int weeks);

  /// No description provided for @predictHistoryCompare.
  ///
  /// In zh, this message translates to:
  /// **'HISTORY  ·  COMPARE'**
  String get predictHistoryCompare;

  /// No description provided for @predictedWeight.
  ///
  /// In zh, this message translates to:
  /// **'PREDICTED  ·  WEIGHT'**
  String get predictedWeight;

  /// No description provided for @predictConfidence.
  ///
  /// In zh, this message translates to:
  /// **'置信度'**
  String get predictConfidence;

  /// No description provided for @predictBasedOn.
  ///
  /// In zh, this message translates to:
  /// **'基于 {count} 条记录'**
  String predictBasedOn(int count);

  /// No description provided for @predictNotEnoughTitle.
  ///
  /// In zh, this message translates to:
  /// **'数据不足'**
  String get predictNotEnoughTitle;

  /// No description provided for @predictNotEnoughBody.
  ///
  /// In zh, this message translates to:
  /// **'至少记录 2 次身体数据后\n预测功能将自动开启'**
  String get predictNotEnoughBody;
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
