// Values the log sheets send to the backend. They are DATA, not display text: the backend
// stores them as is, and some are checked or compared there —
//   diet_logs.meal has a CHECK on exactly these four strings (migration.sql);
//   routers/coach.py compares the workout type with '无氧';
//   exercise_library.dart is keyed by the muscle-group strings.
// Never translate or rename them. Show them with core/l10n/log_value_labels.dart, which
// translates for display and leaves unknown values (custom names, old data) as they are.

abstract final class MealValue {
  static const breakfast = '早餐';
  static const lunch     = '午餐';
  static const dinner    = '晚餐';
  static const snack     = '加餐';
  static const all = [breakfast, lunch, dinner, snack];
}

/// `type` of a workout log (sessions.activity_data). Not the session WorkoutType enum.
abstract final class WorkoutLogType {
  static const cardio   = '有氧';
  static const strength = '无氧';
  static const pilates  = '普拉提';
  static const ball     = '球类';
  static const other    = '其他';
  static const all = [cardio, strength, pilates, ball, other];
}

/// `sub_type` of a workout log. For [WorkoutLogType.other] the sub type is the user's text.
abstract final class WorkoutSubType {
  static const running         = '跑步';
  static const jumpRope        = '跳绳';
  static const aerobics        = '跳操';
  static const hiit            = 'HIIT';
  static const swimming        = '游泳';
  static const hiking          = '爬山';
  static const cycling         = '骑行';
  static const other           = '其他';
  static const matPilates      = '垫上普拉提';
  static const reformerPilates = '器械普拉提';
  static const basketball      = '篮球';
  static const badminton       = '羽毛球';
  static const tennis          = '网球';
  static const tableTennis     = '乒乓球';
  static const football        = '足球';

  /// Choices per type; the first is the default when the type is picked.
  static const byType = {
    WorkoutLogType.cardio:  [running, jumpRope, aerobics, hiit, swimming, hiking, cycling, other],
    WorkoutLogType.pilates: [matPilates, reformerPilates],
    WorkoutLogType.ball:    [basketball, badminton, tennis, tableTennis, football, other],
  };
}

abstract final class MuscleGroupValue {
  static const chest     = '胸';
  static const back      = '背';
  static const legs      = '腿';
  static const shoulders = '肩';
  static const arms      = '手臂';
  static const core      = '核心';
  static const all = [chest, back, legs, shoulders, arms, core];
}

/// period_logs.symptoms entries.
abstract final class SymptomValue {
  static const cramps     = '痛经';
  static const moodSwings = '情绪波动';
  static const swelling   = '水肿';
  static const acne       = '长痘';
  static const fatigue    = '疲劳';
  static const backPain   = '腰酸';
  static const all = [cramps, moodSwings, swelling, acne, fatigue, backPain];
}

/// Preset supplement names (supplement_logs.name); a custom name is stored as typed.
abstract final class SupplementValue {
  static const proteinPowder = '蛋白粉';
  static const creatine      = '肌酸';
  static const vitaminD      = '维生素D';
  static const collagen      = '胶原蛋白';
  static const fishOil       = '鱼油';
  static const vitaminC      = '维生素C';
  static const iron          = '铁';
  static const folicAcid     = '叶酸';
  static const magnesium     = '镁';
  static const zinc          = '锌';
  static const all = [proteinPowder, creatine, vitaminD, collagen, fishOil,
                      vitaminC, iron, folicAcid, magnesium, zinc];
}
