// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appName => '3D Mirror';

  @override
  String get authSubtitle => 'Your body. Your mirror.';

  @override
  String get tabPhone => 'Phone';

  @override
  String get tabEmail => 'Email';

  @override
  String get sendCode => 'Send code';

  @override
  String get resendCode => 'Resend';

  @override
  String resendIn(int sec) {
    return 'RESEND  ·  ${sec}S';
  }

  @override
  String get codePlaceholder => '6-digit code';

  @override
  String get verifyLogin => 'Verify & sign in';

  @override
  String get orDivider => 'OR';

  @override
  String get appleLogin => 'Sign in with Apple';

  @override
  String get privacyNote => 'By signing in you agree to our';

  @override
  String get privacyLink => 'Privacy Policy';

  @override
  String get and => 'and';

  @override
  String get termsLink => 'Terms of Service';

  @override
  String get errorInvalidCode => 'Invalid or expired code';

  @override
  String get errorSendFailed => 'Failed to send. Please try again';

  @override
  String get errorNetwork => 'Network error. Check your connection';

  @override
  String get onboardingStep1Eyebrow => 'ABOUT YOU';

  @override
  String get onboardingStep1Title => 'Tell me\nyour ';

  @override
  String get onboardingStep1Italic => 'basics';

  @override
  String get onboardingStep2Eyebrow => 'YOUR GOAL';

  @override
  String get onboardingStep2Title => 'Your\n';

  @override
  String get onboardingStep2Italic => 'goal';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get labelAge => 'Age';

  @override
  String get labelHeight => 'Height';

  @override
  String get goalLoseFat => 'Lose fat';

  @override
  String get goalLoseFatSub => 'Reduce body fat, improve shape';

  @override
  String get goalBuildMuscle => 'Build muscle';

  @override
  String get goalBuildMuscleSub => 'Increase muscle mass and strength';

  @override
  String get goalRecomp => 'Body recomp';

  @override
  String get goalRecompSub => 'Lose fat and build muscle together';

  @override
  String get goalHealth => 'Wellness';

  @override
  String get goalHealthSub => 'Stay healthy, improve fitness';

  @override
  String get btnNext => 'Next';

  @override
  String get btnBack => 'Back';

  @override
  String get btnStart => 'Get started';

  @override
  String get inputEyebrow => 'Today\'s log';

  @override
  String get inputTitle => 'Tell me\nabout your';

  @override
  String get inputItalic => 'body';

  @override
  String get inputSubtitle => 'More data, better mirror';

  @override
  String get labelWeight => 'Weight';

  @override
  String get labelBodyFat => 'Body fat';

  @override
  String get labelWaist => 'Waist';

  @override
  String get labelWorkout => 'Today\'s workout';

  @override
  String get labelDuration => 'Duration';

  @override
  String get labelIntensity => 'Intensity';

  @override
  String get intensityLow => 'Low';

  @override
  String get intensityMed => 'Med';

  @override
  String get intensityHigh => 'High';

  @override
  String get workoutStrength => 'Strength';

  @override
  String get workoutCardio => 'Cardio';

  @override
  String get workoutHiit => 'HIIT';

  @override
  String get workoutWalk => 'Walk';

  @override
  String get workoutYoga => 'Yoga';

  @override
  String get workoutRest => 'Rest day';

  @override
  String get workoutSwim => 'Swim';

  @override
  String get workoutCycling => 'Cycling';

  @override
  String get ctaGenerate => 'Generate mirror';

  @override
  String get unitKg => 'kg';

  @override
  String get unitPct => '%';

  @override
  String get unitCm => 'cm';

  @override
  String get unitMin => 'min';

  @override
  String get confirmBtn => 'Confirm';

  @override
  String get cancelBtn => 'Cancel';

  @override
  String get resultBack => 'Back';

  @override
  String get resultItalic => 'body mirror';

  @override
  String get resultSubtitle => 'Generated from today\'s data';

  @override
  String get metricWeight => 'Weight';

  @override
  String get metricBodyFat => 'Body fat';

  @override
  String get metricLeanMass => 'Lean mass';

  @override
  String get compareTitle => 'COMPARE';

  @override
  String get compareNow => 'Now';

  @override
  String get rotateHint => 'Drag to rotate';

  @override
  String get saveShare => 'Save · Share';

  @override
  String get historyEyebrow => 'TRANSFORMATION';

  @override
  String get historyTitle => 'Every\n';

  @override
  String get historyItalic => 'session';

  @override
  String get historyEmpty => 'No sessions yet';

  @override
  String get historyEmptySub => 'Complete your first input to start';

  @override
  String get historyStart => 'Start logging';

  @override
  String get historyReplay => 'Tap to replay in 3D';

  @override
  String get vsLastWeek => 'vs last week';

  @override
  String get navHistory => 'History';

  @override
  String get navInput => 'Log';

  @override
  String get loadFailed => 'Load failed';

  @override
  String get retry => 'Retry';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get meTitle => 'ME';

  @override
  String get meUserName => '3D MIRROR USER';

  @override
  String get meChallenge => 'CHALLENGE  ·  MODE';

  @override
  String get meChallengeSub => 'Monthly goal · 20% off when you reach it';

  @override
  String get meSubscription => 'SUBSCRIPTION';

  @override
  String get meSubscriptionSub => 'Manage subscription';

  @override
  String get meLanguage => 'LANGUAGE';

  @override
  String get meSignOut => 'SIGN  ·  OUT';

  @override
  String get comingSoon => 'SOON';

  @override
  String get languageSheetTitle => 'Language';

  @override
  String get languageSystem => 'Follow system';

  @override
  String languageSystemCurrent(String language) {
    return 'Follow system · $language';
  }

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get brandMasthead => '3D MIRROR';

  @override
  String get authTitleLead => 'Start your\n';

  @override
  String get authTitleEmphasis => 'transformation';

  @override
  String get authContinueWith => 'CONTINUE WITH';

  @override
  String get phonePlaceholder => 'Phone number';

  @override
  String get countrySearchHint => 'Search country/region or dialing code';

  @override
  String get countryNoMatch => 'No matching country or region';

  @override
  String get errorPhoneEmpty => 'Enter your phone number';

  @override
  String get errorPhoneNeedsCountryCode => 'Choose a country code, e.g. +86';

  @override
  String get errorPhoneInvalid =>
      'Not a valid mobile number for this country/region';

  @override
  String get errorPhoneNotMobile =>
      'Only mobile numbers are supported, not landline, toll-free or similar numbers';

  @override
  String get errorEmailEmpty => 'Enter your email';

  @override
  String get errorEmailInvalid => 'Enter a valid email address';

  @override
  String get errorRateLimited => 'Too many requests. Please try again later';

  @override
  String get errorAppleSignIn => 'Sign in with Apple failed. Please try again';

  @override
  String errorNetworkStatus(int status) {
    return 'Network error ($status)';
  }

  @override
  String get sessionExpired => 'Your session has expired. Please sign in again';

  @override
  String get fabWorkout => 'Workout';

  @override
  String get fabDiet => 'Diet';

  @override
  String get fabSleep => 'Sleep';

  @override
  String get fabHealth => 'Health';

  @override
  String get fabSupplement => 'Supplements';

  @override
  String get sheetSave => 'SAVE  ·  RECORD';

  @override
  String saveFailedDetail(String error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String get logOptional => 'Optional';

  @override
  String get logIntensityTitle => 'INTENSITY';

  @override
  String get editBtn => 'Edit';

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
  String get workoutErrorMuscleGroup => 'Choose a muscle group';

  @override
  String get workoutErrorNoSets => 'Add at least one set';

  @override
  String get workoutErrorMinDuration => 'Duration must be at least 5 minutes';

  @override
  String get workoutSaved => 'Workout logged';

  @override
  String get workoutOtherNameField => 'Activity name';

  @override
  String get workoutExerciseSearch => 'Search exercises';

  @override
  String get unitMinutes => 'min';

  @override
  String get workoutWithWeight => 'Added weight';

  @override
  String get workoutWeightField => 'Weight kg';

  @override
  String get workoutAddSet => '+ Add a set';

  @override
  String get workoutReps => 'Reps';

  @override
  String get workoutEstimatedBurn => 'Estimated burn';

  @override
  String get workoutIntensityLow => 'Low';

  @override
  String get workoutIntensityMedium => 'Medium';

  @override
  String get workoutIntensityHigh => 'High';

  @override
  String get workoutTypeCardio => 'Cardio';

  @override
  String get workoutTypeStrength => 'Strength';

  @override
  String get workoutTypePilates => 'Pilates';

  @override
  String get workoutTypeBall => 'Ball sports';

  @override
  String get workoutTypeOther => 'Other';

  @override
  String get subTypeRunning => 'Running';

  @override
  String get subTypeJumpRope => 'Jump rope';

  @override
  String get subTypeAerobics => 'Dance aerobics';

  @override
  String get subTypeHiit => 'HIIT';

  @override
  String get subTypeSwimming => 'Swimming';

  @override
  String get subTypeHiking => 'Hiking';

  @override
  String get subTypeCycling => 'Cycling';

  @override
  String get subTypeOther => 'Other';

  @override
  String get subTypeMatPilates => 'Mat Pilates';

  @override
  String get subTypeReformerPilates => 'Reformer Pilates';

  @override
  String get subTypeBasketball => 'Basketball';

  @override
  String get subTypeBadminton => 'Badminton';

  @override
  String get subTypeTennis => 'Tennis';

  @override
  String get subTypeTableTennis => 'Table tennis';

  @override
  String get subTypeFootball => 'Soccer';

  @override
  String get muscleChest => 'Chest';

  @override
  String get muscleBack => 'Back';

  @override
  String get muscleLegs => 'Legs';

  @override
  String get muscleShoulders => 'Shoulders';

  @override
  String get muscleArms => 'Arms';

  @override
  String get muscleCore => 'Core';

  @override
  String get dietSheetTitle => 'MEAL  ·  LOG';

  @override
  String get dietMealTypeTitle => 'MEAL  ·  TYPE';

  @override
  String get dietEntryMethodTitle => 'ENTRY  ·  METHOD';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealSnack => 'Snack';

  @override
  String get dietMethodSearch => 'Search';

  @override
  String get dietMethodManual => 'Manual';

  @override
  String get dietSearchFood => 'Search food';

  @override
  String get dietSearchHint => 'Chicken breast, oats…';

  @override
  String get dietFoodName => 'Food name';

  @override
  String get dietGrams => 'Grams';

  @override
  String get dietCalories => 'Calories *';

  @override
  String get dietProtein => 'Protein g (optional)';

  @override
  String get dietErrorName => 'Enter a food name';

  @override
  String get dietErrorCalories => 'Enter the calories';

  @override
  String get dietSaved => 'Meal logged';

  @override
  String get healthSheetTitle => 'HEALTH  ·  LOG';

  @override
  String get healthMeasureTitle => 'BODY  ·  MEASURE';

  @override
  String get healthPeriodTitle => 'PERIOD  ·  LOG';

  @override
  String get healthSymptomsTitle => 'SYMPTOMS';

  @override
  String get measureWeightKg => 'Weight kg';

  @override
  String get measureWaistCm => 'Waist cm';

  @override
  String get measureHipCm => 'Hips cm';

  @override
  String get measureChestCm => 'Chest cm';

  @override
  String get measureThighCm => 'Thigh cm';

  @override
  String get periodStart => 'Period started';

  @override
  String get periodOngoing => 'Ongoing';

  @override
  String get periodEnd => 'Period ended';

  @override
  String get periodIntensityLight => 'Light';

  @override
  String get periodIntensityModerate => 'Moderate';

  @override
  String get periodIntensityHeavy => 'Heavy';

  @override
  String get symptomCramps => 'Cramps';

  @override
  String get symptomMoodSwings => 'Mood swings';

  @override
  String get symptomSwelling => 'Bloating';

  @override
  String get symptomAcne => 'Acne';

  @override
  String get symptomFatigue => 'Fatigue';

  @override
  String get symptomBackPain => 'Lower back pain';

  @override
  String get healthErrorEmpty => 'Fill in at least one field';

  @override
  String get healthSaved => 'Health data logged';

  @override
  String get sleepSheetTitle => 'SLEEP  ·  LOG';

  @override
  String get sleepTimeTitle => 'SLEEP  ·  TIME';

  @override
  String get sleepDurationTitle => 'DURATION  ·  CALC';

  @override
  String get sleepQualityTitle => 'SLEEP  ·  QUALITY';

  @override
  String get sleepBedtime => 'Bedtime';

  @override
  String get sleepWake => 'Wake up';

  @override
  String get sleepDuration => 'Sleep duration';

  @override
  String get sleepShortConfirm => 'Less than 1 hour of sleep. Save anyway?';

  @override
  String get sleepSaved => 'Sleep logged';

  @override
  String get supplementSheetTitle => 'SUPPLEMENT  ·  LOG';

  @override
  String get supplementSelectTitle => 'SUPPLEMENT  ·  SELECT';

  @override
  String get supplementCustomTitle => 'CUSTOM  ·  ADD';

  @override
  String get supplementReminderTitle => 'REMINDER  ·  TIME';

  @override
  String get supplementNameField => 'Name';

  @override
  String get supplementNameHint => 'e.g. glutamine';

  @override
  String get supplementDosageField => 'Dosage';

  @override
  String get supplementDosageHint => '30 g, 2 capsules';

  @override
  String get supplementPickTime => 'Choose a time';

  @override
  String get supplementErrorEmpty => 'Choose or enter at least one supplement';

  @override
  String get supplementSaved => 'Supplements logged';

  @override
  String get supplementProteinPowder => 'Protein powder';

  @override
  String get supplementCreatine => 'Creatine';

  @override
  String get supplementVitaminD => 'Vitamin D';

  @override
  String get supplementCollagen => 'Collagen';

  @override
  String get supplementFishOil => 'Fish oil';

  @override
  String get supplementVitaminC => 'Vitamin C';

  @override
  String get supplementIron => 'Iron';

  @override
  String get supplementFolicAcid => 'Folic acid';

  @override
  String get supplementMagnesium => 'Magnesium';

  @override
  String get supplementZinc => 'Zinc';

  @override
  String get onboardingConsentEyebrow => 'LEGAL & PRIVACY';

  @override
  String get onboardingConsentTitle => 'Terms &\n';

  @override
  String get onboardingConsentItalic => 'privacy';

  @override
  String get onboardingConsentIntro =>
      'Before you start using 3D Mirror, please confirm the following:';

  @override
  String get onboardingConsentBullet1 =>
      'Your body data (height, weight, measurements) is used to build your personal 3D body model';

  @override
  String get onboardingConsentBullet2 =>
      'Body photos are uploaded to our server, where AI analyzes your proportions. They are used only for modeling, nothing else';

  @override
  String get onboardingConsentBullet3 =>
      'All data is stored encrypted. We never sell or share your personal information';

  @override
  String get onboardingConsentBullet4 =>
      'AI predictions are for reference only and are not medical advice';

  @override
  String get onboardingAcceptTerms =>
      'I have read and agree to the Terms of Service';

  @override
  String get onboardingAcceptTermsSub => 'Required to use 3D Mirror';

  @override
  String get onboardingAcceptPrivacy =>
      'I have read and agree to the Privacy Policy';

  @override
  String get onboardingAcceptPrivacySub => 'Includes how AI uses your data';

  @override
  String onboardingAgeValue(int age) {
    return '$age yrs';
  }

  @override
  String get onboardingHeightPicker => 'Height (cm)';

  @override
  String get onboardingWeightPicker => 'Weight (kg)';

  @override
  String get photoScanEyebrow => 'BODY SCAN';

  @override
  String get photoTitleLead => 'Capture your\n';

  @override
  String get photoTitleEmphasis => 'shape';

  @override
  String get photoIntro =>
      'Take photos from three angles to help the AI build a more accurate 3D body model.';

  @override
  String get photoAllDone => 'All done ✓';

  @override
  String photoProgress(int count) {
    return '$count / 3 done';
  }

  @override
  String get photoLater => 'Later';

  @override
  String get photoUploadAndFinish => 'Upload and finish';

  @override
  String get photoSkipRestAndFinish => 'Skip the rest and finish';

  @override
  String get photoUploadFailed =>
      'Upload failed. Check your connection and try again.';

  @override
  String get photoAngleFront => 'Front';

  @override
  String get photoAngleSide => 'Side';

  @override
  String get photoAngleBack => 'Back';

  @override
  String get photoHintFront => 'Face the camera';

  @override
  String get photoHintSide => 'Stand side-on (90°)';

  @override
  String get photoHintBack => 'Face away from the camera';

  @override
  String get analysisStatusOk => 'Body analysis complete';

  @override
  String get analysisStatusUnavailable =>
      'Body analysis is currently unavailable';

  @override
  String get analysisStatusFailed =>
      'Body analysis failed. Please retake the photos later';

  @override
  String get workoutOther => 'Other';

  @override
  String get inputBodyDataTitle => 'BODY  ·  DATA';

  @override
  String get inputActivityTitle => 'TODAY\'S ACTIVITY';

  @override
  String inputDayLabel(int day, String date) {
    return 'DAY $day  ·  $date';
  }

  @override
  String get inputPickWeight => 'Weight (kg)';

  @override
  String get inputPickBodyFat => 'Body fat (%)';

  @override
  String get inputPickWaist => 'Waist (cm)';

  @override
  String get inputPickDuration => 'Workout duration (min)';

  @override
  String get historyTodayRecord => 'TODAY  ·  RECORD';

  @override
  String get historyRecordsTitle => 'RECORDS';

  @override
  String get historyCompareSelect => 'COMPARE  ·  SELECT';

  @override
  String get historySelectedTwo => '2 selected';

  @override
  String historySelectMore(int count) {
    return 'Select $count more';
  }

  @override
  String get historyCompareAction => 'Compare';

  @override
  String get historyVsPrev => 'vs prev';

  @override
  String get predictTag => 'PREDICT';

  @override
  String get snapshotMasthead => 'SNAPSHOTS';

  @override
  String snapshotRecordCount(int count) {
    return '$count RECORDS';
  }

  @override
  String get snapshotWeightTrend => 'WEIGHT  ·  TREND';

  @override
  String get snapshotSessions => 'SESSIONS';

  @override
  String get snapshotSessionsUnit => 'total';

  @override
  String get snapshotWeightChange => 'WEIGHT CHANGE';

  @override
  String get snapshotDaysActive => 'DAYS ACTIVE';

  @override
  String get snapshotDaysUnit => 'days';

  @override
  String get snapshotLatest => 'LATEST';

  @override
  String get compareBodyCompare => 'BODY  ·  COMPARE';

  @override
  String get compareOverlay => 'Overlay';

  @override
  String get compareDelta => 'DELTA';

  @override
  String comparePredictLabel(int weeks) {
    return 'Predicted · ${weeks}W';
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
  String get predictConfidence => 'Confidence';

  @override
  String predictBasedOn(int count) {
    return 'Based on $count records';
  }

  @override
  String get predictNotEnoughTitle => 'Not enough data';

  @override
  String get predictNotEnoughBody =>
      'Log your body data at least twice\nto unlock predictions';
}
