class ExerciseItem {
  final String name;
  final String group;      // '胸'|'背'|'腿'|'肩'|'手臂'|'核心'
  final String equipment;  // '杠铃'|'哑铃'|'自重'|'器械'|'绳索'

  const ExerciseItem({
    required this.name, required this.group, required this.equipment,
  });
}

const List<ExerciseItem> kExerciseLibrary = [
  // ── 胸 ──────────────────────────────────────────────────────────────────────
  ExerciseItem(name: '卧推',       group: '胸', equipment: '杠铃'),
  ExerciseItem(name: '哑铃卧推',   group: '胸', equipment: '哑铃'),
  ExerciseItem(name: '上斜卧推',   group: '胸', equipment: '杠铃'),
  ExerciseItem(name: '下斜卧推',   group: '胸', equipment: '杠铃'),
  ExerciseItem(name: '哑铃飞鸟',   group: '胸', equipment: '哑铃'),
  ExerciseItem(name: '绳索飞鸟',   group: '胸', equipment: '绳索'),
  ExerciseItem(name: '蝴蝶机夹胸', group: '胸', equipment: '器械'),
  ExerciseItem(name: '坐姿推胸',   group: '胸', equipment: '器械'),
  ExerciseItem(name: '俯卧撑',     group: '胸', equipment: '自重'),
  ExerciseItem(name: '钻石俯卧撑', group: '胸', equipment: '自重'),

  // ── 背 ──────────────────────────────────────────────────────────────────────
  ExerciseItem(name: '引体向上',   group: '背', equipment: '自重'),
  ExerciseItem(name: '杠铃划船',   group: '背', equipment: '杠铃'),
  ExerciseItem(name: '哑铃划船',   group: '背', equipment: '哑铃'),
  ExerciseItem(name: 'T杠划船',    group: '背', equipment: '杠铃'),
  ExerciseItem(name: '坐姿划船',   group: '背', equipment: '器械'),
  ExerciseItem(name: '高位下拉',   group: '背', equipment: '器械'),
  ExerciseItem(name: '绳索划船',   group: '背', equipment: '绳索'),
  ExerciseItem(name: '直臂下压',   group: '背', equipment: '绳索'),
  ExerciseItem(name: '俯身飞鸟',   group: '背', equipment: '哑铃'),
  ExerciseItem(name: '硬拉',       group: '背', equipment: '杠铃'),

  // ── 腿 ──────────────────────────────────────────────────────────────────────
  ExerciseItem(name: '深蹲',         group: '腿', equipment: '杠铃'),
  ExerciseItem(name: '腿举',         group: '腿', equipment: '器械'),
  ExerciseItem(name: '腿屈伸',       group: '腿', equipment: '器械'),
  ExerciseItem(name: '腿弯举',       group: '腿', equipment: '器械'),
  ExerciseItem(name: '臀推',         group: '腿', equipment: '杠铃'),
  ExerciseItem(name: '保加利亚深蹲', group: '腿', equipment: '哑铃'),
  ExerciseItem(name: '哑铃弓步蹲',   group: '腿', equipment: '哑铃'),
  ExerciseItem(name: '相扑深蹲',     group: '腿', equipment: '哑铃'),
  ExerciseItem(name: '站姿提踵',     group: '腿', equipment: '器械'),
  ExerciseItem(name: '箱式深蹲',     group: '腿', equipment: '自重'),

  // ── 肩 ──────────────────────────────────────────────────────────────────────
  ExerciseItem(name: '哑铃肩推',  group: '肩', equipment: '哑铃'),
  ExerciseItem(name: '杠铃推举',  group: '肩', equipment: '杠铃'),
  ExerciseItem(name: '坐姿推举',  group: '肩', equipment: '器械'),
  ExerciseItem(name: '阿诺德推举', group: '肩', equipment: '哑铃'),
  ExerciseItem(name: '侧平举',    group: '肩', equipment: '哑铃'),
  ExerciseItem(name: '前平举',    group: '肩', equipment: '哑铃'),
  ExerciseItem(name: '绳索侧平举', group: '肩', equipment: '绳索'),
  ExerciseItem(name: '绳索前平举', group: '肩', equipment: '绳索'),
  ExerciseItem(name: '俯身反飞鸟', group: '肩', equipment: '哑铃'),
  ExerciseItem(name: '直立划船',  group: '肩', equipment: '杠铃'),

  // ── 手臂 ─────────────────────────────────────────────────────────────────────
  ExerciseItem(name: '杠铃弯举',   group: '手臂', equipment: '杠铃'),
  ExerciseItem(name: '哑铃弯举',   group: '手臂', equipment: '哑铃'),
  ExerciseItem(name: '锤式弯举',   group: '手臂', equipment: '哑铃'),
  ExerciseItem(name: '牧师弯举',   group: '手臂', equipment: '杠铃'),
  ExerciseItem(name: '反握弯举',   group: '手臂', equipment: '杠铃'),
  ExerciseItem(name: '绳索弯举',   group: '手臂', equipment: '绳索'),
  ExerciseItem(name: '窄距卧推',   group: '手臂', equipment: '杠铃'),
  ExerciseItem(name: '双杠臂屈伸', group: '手臂', equipment: '自重'),
  ExerciseItem(name: '绳索下压',   group: '手臂', equipment: '绳索'),
  ExerciseItem(name: '哑铃臂屈伸', group: '手臂', equipment: '哑铃'),

  // ── 核心 ─────────────────────────────────────────────────────────────────────
  ExerciseItem(name: '仰卧起坐', group: '核心', equipment: '自重'),
  ExerciseItem(name: '卷腹',     group: '核心', equipment: '自重'),
  ExerciseItem(name: '平板支撑', group: '核心', equipment: '自重'),
  ExerciseItem(name: '俄罗斯转体', group: '核心', equipment: '自重'),
  ExerciseItem(name: '悬挂举腿', group: '核心', equipment: '自重'),
  ExerciseItem(name: '侧卷腹',   group: '核心', equipment: '自重'),
  ExerciseItem(name: '死虫式',   group: '核心', equipment: '自重'),
  ExerciseItem(name: '超人式',   group: '核心', equipment: '自重'),
  ExerciseItem(name: '绳索卷腹', group: '核心', equipment: '绳索'),
  ExerciseItem(name: '腹轮',     group: '核心', equipment: '器械'),
];

/// Returns all exercises for the given body group, case-sensitive.
List<ExerciseItem> exercisesByGroup(String group) =>
    kExerciseLibrary.where((e) => e.group == group).toList();

/// Fuzzy search by name or equipment. Optional [muscleGroup] pre-filters by group.
List<ExerciseItem> searchExercises(String query, {String? muscleGroup}) {
  final list = muscleGroup != null
      ? kExerciseLibrary.where((e) => e.group == muscleGroup).toList()
      : kExerciseLibrary;
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return list;
  return list
      .where((e) =>
          e.name.toLowerCase().contains(q) ||
          e.equipment.toLowerCase().contains(q))
      .toList();
}
