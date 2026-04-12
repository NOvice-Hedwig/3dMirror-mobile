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
  String get authTitle => 'Start your\ntransformation';

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
    return 'Resend in ${sec}s';
  }

  @override
  String get codePlaceholder => '6-digit code';

  @override
  String get verifyLogin => 'Verify & sign in';

  @override
  String get orDivider => 'or';

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
  String get onboardingStep1Eyebrow => 'About you';

  @override
  String get onboardingStep1Title => 'Tell me your';

  @override
  String get onboardingStep1Italic => 'basics';

  @override
  String get onboardingStep2Eyebrow => 'Last step';

  @override
  String get onboardingStep2Title => 'Your';

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
  String get goalHealth => 'General health';

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
  String get inputTitle => 'Tell me about your';

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
  String get intensityLow => 'Easy';

  @override
  String get intensityMed => 'Moderate';

  @override
  String get intensityHigh => 'Hard';

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
  String get compareTitle => 'Compare';

  @override
  String get compareNow => 'Now';

  @override
  String get rotateHint => 'Drag to rotate';

  @override
  String get saveShare => 'Save · Share';

  @override
  String get historyEyebrow => 'Your journey';

  @override
  String get historyTitle => 'Every';

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
}
