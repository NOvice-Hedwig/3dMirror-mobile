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
    return '${sec}S  ·  重发';
  }

  @override
  String get codePlaceholder => '6位验证码';

  @override
  String get verifyLogin => '验证并登录';

  @override
  String get orDivider => 'OR';

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
  String get onboardingStep1Eyebrow => 'ABOUT YOU';

  @override
  String get onboardingStep1Title => '告诉我\n你的';

  @override
  String get onboardingStep1Italic => '基本信息';

  @override
  String get onboardingStep2Eyebrow => 'YOUR GOAL';

  @override
  String get onboardingStep2Title => '你的\n';

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
  String get goalLoseFatSub => 'Fat Loss — 减少体脂，提升体型';

  @override
  String get goalBuildMuscle => '增肌';

  @override
  String get goalBuildMuscleSub => 'Muscle — 增加肌肉量，提升力量';

  @override
  String get goalRecomp => '塑形';

  @override
  String get goalRecompSub => 'Recomposition — 减脂增肌同步';

  @override
  String get goalHealth => '健康';

  @override
  String get goalHealthSub => 'Wellness — 保持健康，改善体能';

  @override
  String get btnNext => '下一步';

  @override
  String get btnBack => '返回';

  @override
  String get btnStart => '开始使用';

  @override
  String get inputEyebrow => '今日记录';

  @override
  String get inputTitle => '告诉我\n你的';

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
  String get ctaGenerate => '生成角色';

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
  String get compareTitle => 'COMPARE';

  @override
  String get compareNow => '现在';

  @override
  String get rotateHint => '拖动旋转';

  @override
  String get saveShare => '保存 · 分享';

  @override
  String get historyEyebrow => 'TRANSFORMATION';

  @override
  String get historyTitle => '每一次\n';

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

  @override
  String get meTitle => 'ME';

  @override
  String get meUserName => '3D MIRROR USER';

  @override
  String get meChallenge => 'CHALLENGE  ·  MODE';

  @override
  String get meChallengeSub => '月目标 · 达成享 8 折';

  @override
  String get meSubscription => 'SUBSCRIPTION';

  @override
  String get meSubscriptionSub => '管理订阅';

  @override
  String get meLanguage => 'LANGUAGE';

  @override
  String get meSignOut => 'SIGN  ·  OUT';

  @override
  String get comingSoon => 'SOON';

  @override
  String get languageSheetTitle => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String languageSystemCurrent(String language) {
    return '跟随系统 · $language';
  }

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get brandMasthead => '3D MIRROR';

  @override
  String get authTitleLead => '开始\n';

  @override
  String get authTitleEmphasis => '蜕变';

  @override
  String get authContinueWith => 'CONTINUE WITH';

  @override
  String get phonePlaceholder => '手机号';

  @override
  String get countrySearchHint => '搜索国家/地区或区号';

  @override
  String get countryNoMatch => '没有找到匹配的国家/地区';

  @override
  String get errorPhoneEmpty => '请输入手机号';

  @override
  String get errorPhoneNeedsCountryCode => '请选择国家/地区代码，例如 +86';

  @override
  String get errorPhoneInvalid => '该国家/地区的手机号格式不正确';

  @override
  String get errorPhoneNotMobile => '仅支持手机号，不支持座机、免费电话等号码';

  @override
  String get errorEmailEmpty => '请输入邮箱';

  @override
  String get errorEmailInvalid => '邮箱格式不正确';

  @override
  String get errorRateLimited => '请求过于频繁，请稍后再试';

  @override
  String get errorAppleSignIn => 'Apple 登录失败，请重试';

  @override
  String errorNetworkStatus(int status) {
    return '网络错误 ($status)';
  }

  @override
  String get sessionExpired => '登录已过期，请重新登录';

  @override
  String get fabWorkout => '运动';

  @override
  String get fabDiet => '饮食';

  @override
  String get fabSleep => '睡眠';

  @override
  String get fabHealth => '健康';

  @override
  String get fabSupplement => '补剂';

  @override
  String get sheetSave => 'SAVE  ·  RECORD';

  @override
  String saveFailedDetail(String error) {
    return '保存失败：$error';
  }

  @override
  String get logOptional => '选填';

  @override
  String get logIntensityTitle => 'INTENSITY';

  @override
  String get editBtn => '修改';

  @override
  String get workoutSheetTitle => 'TYPE  ·  LOG';

  @override
  String get workoutTypeSelect => 'TYPE  ·  SELECT';

  @override
  String get workoutCardioTypeTitle => 'CARDIO  ·  TYPE';

  @override
  String get workoutPilatesTypeTitle => 'PILATES  ·  TYPE';

  @override
  String get workoutSportTypeTitle => 'SPORT  ·  TYPE';

  @override
  String get workoutOtherNameTitle => 'OTHER  ·  NAME';

  @override
  String get workoutMuscleGroupTitle => 'MUSCLE  ·  GROUP';

  @override
  String get workoutDurationIntensityTitle => 'DURATION  ·  INTENSITY';

  @override
  String get workoutSetsTitle => 'SETS  ·  LOG';

  @override
  String get workoutCalorieTitle => 'CALORIE  ·  EST';

  @override
  String get workoutErrorMuscleGroup => '请选择训练部位';

  @override
  String get workoutErrorNoSets => '请至少添加一组';

  @override
  String get workoutErrorMinDuration => '时长至少 5 分钟';

  @override
  String get workoutSaved => '运动已记录';

  @override
  String get workoutOtherNameField => '运动名称';

  @override
  String get workoutExerciseSearch => '搜索动作';

  @override
  String get unitMinutes => '分钟';

  @override
  String get workoutWithWeight => '附加负重';

  @override
  String get workoutWeightField => '负重 kg';

  @override
  String get workoutAddSet => '+ 添加一组';

  @override
  String get workoutReps => '次数';

  @override
  String get workoutEstimatedBurn => '估算消耗';

  @override
  String get workoutIntensityLow => '低';

  @override
  String get workoutIntensityMedium => '中';

  @override
  String get workoutIntensityHigh => '高';

  @override
  String get workoutTypeCardio => '有氧';

  @override
  String get workoutTypeStrength => '无氧';

  @override
  String get workoutTypePilates => '普拉提';

  @override
  String get workoutTypeBall => '球类';

  @override
  String get workoutTypeOther => '其他';

  @override
  String get subTypeRunning => '跑步';

  @override
  String get subTypeJumpRope => '跳绳';

  @override
  String get subTypeAerobics => '跳操';

  @override
  String get subTypeHiit => 'HIIT';

  @override
  String get subTypeSwimming => '游泳';

  @override
  String get subTypeHiking => '爬山';

  @override
  String get subTypeCycling => '骑行';

  @override
  String get subTypeOther => '其他';

  @override
  String get subTypeMatPilates => '垫上普拉提';

  @override
  String get subTypeReformerPilates => '器械普拉提';

  @override
  String get subTypeBasketball => '篮球';

  @override
  String get subTypeBadminton => '羽毛球';

  @override
  String get subTypeTennis => '网球';

  @override
  String get subTypeTableTennis => '乒乓球';

  @override
  String get subTypeFootball => '足球';

  @override
  String get muscleChest => '胸';

  @override
  String get muscleBack => '背';

  @override
  String get muscleLegs => '腿';

  @override
  String get muscleShoulders => '肩';

  @override
  String get muscleArms => '手臂';

  @override
  String get muscleCore => '核心';

  @override
  String get dietSheetTitle => 'MEAL  ·  LOG';

  @override
  String get dietMealTypeTitle => 'MEAL  ·  TYPE';

  @override
  String get dietEntryMethodTitle => 'ENTRY  ·  METHOD';

  @override
  String get mealBreakfast => '早餐';

  @override
  String get mealLunch => '午餐';

  @override
  String get mealDinner => '晚餐';

  @override
  String get mealSnack => '加餐';

  @override
  String get dietMethodSearch => '搜索';

  @override
  String get dietMethodManual => '手动';

  @override
  String get dietSearchFood => '搜索食物';

  @override
  String get dietSearchHint => '鸡胸肉、燕麦…';

  @override
  String get dietFoodName => '食物名称';

  @override
  String get dietGrams => '克重';

  @override
  String get dietCalories => '卡路里 *';

  @override
  String get dietProtein => '蛋白质 g（选填）';

  @override
  String get dietErrorName => '请输入食物名称';

  @override
  String get dietErrorCalories => '请输入卡路里';

  @override
  String get dietSaved => '饮食已记录';

  @override
  String get healthSheetTitle => 'HEALTH  ·  LOG';

  @override
  String get healthMeasureTitle => 'BODY  ·  MEASURE';

  @override
  String get healthPeriodTitle => 'PERIOD  ·  LOG';

  @override
  String get healthSymptomsTitle => 'SYMPTOMS';

  @override
  String get measureWeightKg => '体重 kg';

  @override
  String get measureWaistCm => '腰围 cm';

  @override
  String get measureHipCm => '臀围 cm';

  @override
  String get measureChestCm => '胸围 cm';

  @override
  String get measureThighCm => '大腿围 cm';

  @override
  String get periodStart => '经期开始';

  @override
  String get periodOngoing => '进行中';

  @override
  String get periodEnd => '经期结束';

  @override
  String get periodIntensityLight => '轻';

  @override
  String get periodIntensityModerate => '中';

  @override
  String get periodIntensityHeavy => '重';

  @override
  String get symptomCramps => '痛经';

  @override
  String get symptomMoodSwings => '情绪波动';

  @override
  String get symptomSwelling => '水肿';

  @override
  String get symptomAcne => '长痘';

  @override
  String get symptomFatigue => '疲劳';

  @override
  String get symptomBackPain => '腰酸';

  @override
  String get healthErrorEmpty => '请至少填写一项数据';

  @override
  String get healthSaved => '健康数据已记录';

  @override
  String get sleepSheetTitle => 'SLEEP  ·  LOG';

  @override
  String get sleepTimeTitle => 'SLEEP  ·  TIME';

  @override
  String get sleepDurationTitle => 'DURATION  ·  CALC';

  @override
  String get sleepQualityTitle => 'SLEEP  ·  QUALITY';

  @override
  String get sleepBedtime => '入睡';

  @override
  String get sleepWake => '起床';

  @override
  String get sleepDuration => '睡眠时长';

  @override
  String get sleepShortConfirm => '睡眠时间不足 1 小时，是否确认保存？';

  @override
  String get sleepSaved => '睡眠已记录';

  @override
  String get supplementSheetTitle => 'SUPPLEMENT  ·  LOG';

  @override
  String get supplementSelectTitle => 'SUPPLEMENT  ·  SELECT';

  @override
  String get supplementCustomTitle => 'CUSTOM  ·  ADD';

  @override
  String get supplementReminderTitle => 'REMINDER  ·  TIME';

  @override
  String get supplementNameField => '名称';

  @override
  String get supplementNameHint => '如：谷氨酰胺';

  @override
  String get supplementDosageField => '剂量';

  @override
  String get supplementDosageHint => '30g、2粒';

  @override
  String get supplementPickTime => '选择时间';

  @override
  String get supplementErrorEmpty => '请至少选择或填写一种补剂';

  @override
  String get supplementSaved => '补剂已记录';

  @override
  String get supplementProteinPowder => '蛋白粉';

  @override
  String get supplementCreatine => '肌酸';

  @override
  String get supplementVitaminD => '维生素D';

  @override
  String get supplementCollagen => '胶原蛋白';

  @override
  String get supplementFishOil => '鱼油';

  @override
  String get supplementVitaminC => '维生素C';

  @override
  String get supplementIron => '铁';

  @override
  String get supplementFolicAcid => '叶酸';

  @override
  String get supplementMagnesium => '镁';

  @override
  String get supplementZinc => '锌';

  @override
  String get onboardingConsentEyebrow => 'LEGAL & PRIVACY';

  @override
  String get onboardingConsentTitle => '条款与\n';

  @override
  String get onboardingConsentItalic => '隐私协议';

  @override
  String get onboardingConsentIntro => '在开始使用 3D Mirror 之前，请确认以下内容：';

  @override
  String get onboardingConsentBullet1 => '你的身体数据（身高、体重、三围）将用于生成专属 3D 体型模型';

  @override
  String get onboardingConsentBullet2 => '体型照片将上传至服务器，由 AI 分析体型比例，仅用于建模，不作其他用途';

  @override
  String get onboardingConsentBullet3 => '所有数据经过加密存储，我们不会出售或共享你的个人信息';

  @override
  String get onboardingConsentBullet4 => 'AI 预测结果仅供参考，不构成医疗建议';

  @override
  String get onboardingAcceptTerms => '我已阅读并同意《服务条款》';

  @override
  String get onboardingAcceptTermsSub => 'Terms of Service';

  @override
  String get onboardingAcceptPrivacy => '我已阅读并同意《隐私政策》';

  @override
  String get onboardingAcceptPrivacySub => 'Privacy Policy — AI Data Usage';

  @override
  String onboardingAgeValue(int age) {
    return '$age 岁';
  }

  @override
  String get onboardingHeightPicker => '身高 (cm)';

  @override
  String get onboardingWeightPicker => '体重 (kg)';

  @override
  String get photoScanEyebrow => 'BODY SCAN';

  @override
  String get photoTitleLead => '记录你的\n';

  @override
  String get photoTitleEmphasis => '体型';

  @override
  String get photoIntro => '拍摄三个角度的照片，帮助 AI 建立更准确的 3D 体型模型。';

  @override
  String get photoAllDone => '全部完成 ✓';

  @override
  String photoProgress(int count) {
    return '已完成 $count / 3';
  }

  @override
  String get photoLater => '稍后再说';

  @override
  String get photoUploadAndFinish => '上传并完成';

  @override
  String get photoSkipRestAndFinish => '跳过剩余并完成';

  @override
  String get photoUploadFailed => '上传失败，请检查网络连接后重试。';

  @override
  String get photoAngleFront => '前视图';

  @override
  String get photoAngleSide => '侧视图';

  @override
  String get photoAngleBack => '后视图';

  @override
  String get photoHintFront => '面向镜头站立';

  @override
  String get photoHintSide => '侧身 90° 站立';

  @override
  String get photoHintBack => '背对镜头站立';

  @override
  String get analysisStatusOk => '体型分析已完成';

  @override
  String get analysisStatusUnavailable => '体型分析暂不可用';

  @override
  String get analysisStatusFailed => '体型分析失败，请稍后重新拍照';

  @override
  String get workoutOther => '其他';

  @override
  String get inputBodyDataTitle => 'BODY  ·  DATA';

  @override
  String get inputActivityTitle => 'TODAY\'S ACTIVITY';

  @override
  String inputDayLabel(int day, String date) {
    return 'DAY $day  ·  $date';
  }

  @override
  String get inputPickWeight => '体重 (kg)';

  @override
  String get inputPickBodyFat => '体脂率 (%)';

  @override
  String get inputPickWaist => '腰围 (cm)';

  @override
  String get inputPickDuration => '训练时长 (min)';

  @override
  String get historyTodayRecord => 'TODAY  ·  RECORD';

  @override
  String get historyRecordsTitle => 'RECORDS';

  @override
  String get historyCompareSelect => 'COMPARE  ·  SELECT';

  @override
  String get historySelectedTwo => '已选 2 项';

  @override
  String historySelectMore(int count) {
    return '再选 $count 项';
  }

  @override
  String get historyCompareAction => '对比';

  @override
  String get historyVsPrev => 'vs prev';

  @override
  String get predictTag => '预测';

  @override
  String get snapshotMasthead => 'SNAPSHOTS';

  @override
  String snapshotRecordCount(int count) {
    return '$count RECORDS';
  }

  @override
  String get snapshotWeightTrend => 'WEIGHT  ·  TREND';

  @override
  String get snapshotSessions => '记录次数';

  @override
  String get snapshotSessionsUnit => '次';

  @override
  String get snapshotWeightChange => '体重变化';

  @override
  String get snapshotDaysActive => '坚持天数';

  @override
  String get snapshotDaysUnit => '天';

  @override
  String get snapshotLatest => 'LATEST';

  @override
  String get compareBodyCompare => 'BODY  ·  COMPARE';

  @override
  String get compareOverlay => '叠加';

  @override
  String get compareDelta => 'DELTA';

  @override
  String comparePredictLabel(int weeks) {
    return '预测 · ${weeks}W';
  }

  @override
  String get predictMasthead => 'PREDICT';

  @override
  String get predictBodyFuture => 'BODY  ·  FUTURE';

  @override
  String get predictTimeRange => 'TIME  ·  RANGE';

  @override
  String predictWeeks(int weeks) {
    return '$weeks W';
  }

  @override
  String get predictHistoryCompare => 'HISTORY  ·  COMPARE';

  @override
  String get predictedWeight => 'PREDICTED  ·  WEIGHT';

  @override
  String get predictConfidence => '置信度';

  @override
  String predictBasedOn(int count) {
    return '基于 $count 条记录';
  }

  @override
  String get predictNotEnoughTitle => '数据不足';

  @override
  String get predictNotEnoughBody => '至少记录 2 次身体数据后\n预测功能将自动开启';
}
