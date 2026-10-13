class FoodItem {
  final String name;
  final double per100gKcal;
  final double per100gProtein;
  final double? per100gCarbs;
  final double? per100gFat;

  const FoodItem({
    required this.name, required this.per100gKcal,
    required this.per100gProtein, this.per100gCarbs, this.per100gFat,
  });

  double kcalFor(double g) => per100gKcal * g / 100;
  double proteinFor(double g) => per100gProtein * g / 100;
}

const List<FoodItem> kFoodLibrary = [
  // ── 肉蛋类 ───────────────────────────────────────────────────────────────────
  FoodItem(name: '鸡胸肉',   per100gKcal: 165, per100gProtein: 31,   per100gCarbs: 0,    per100gFat: 3.6),
  FoodItem(name: '牛肉（瘦）', per100gKcal: 189, per100gProtein: 26,  per100gCarbs: 0,    per100gFat: 9.0),
  FoodItem(name: '猪肉（瘦）', per100gKcal: 143, per100gProtein: 20,  per100gCarbs: 0,    per100gFat: 7.0),
  FoodItem(name: '三文鱼',   per100gKcal: 208, per100gProtein: 20,   per100gCarbs: 0,    per100gFat: 13.0),
  FoodItem(name: '金枪鱼罐头', per100gKcal: 132, per100gProtein: 29,  per100gCarbs: 0,    per100gFat: 1.0),
  FoodItem(name: '虾',       per100gKcal: 99,  per100gProtein: 24,   per100gCarbs: 0,    per100gFat: 0.3),
  FoodItem(name: '鸡蛋',     per100gKcal: 155, per100gProtein: 13,   per100gCarbs: 1.1,  per100gFat: 11.0),
  FoodItem(name: '鸡蛋白',   per100gKcal: 52,  per100gProtein: 11,   per100gCarbs: 0.7,  per100gFat: 0.2),
  FoodItem(name: '清蒸鱼',   per100gKcal: 105, per100gProtein: 18,   per100gCarbs: 1.0,  per100gFat: 3.0),
  FoodItem(name: '炸鸡胸',   per100gKcal: 246, per100gProtein: 18,   per100gCarbs: 16.0, per100gFat: 12.0),

  // ── 主食 ─────────────────────────────────────────────────────────────────────
  FoodItem(name: '白米饭',    per100gKcal: 130, per100gProtein: 2.7,  per100gCarbs: 28.0, per100gFat: 0.3),
  FoodItem(name: '燕麦片',    per100gKcal: 389, per100gProtein: 17.0, per100gCarbs: 66.0, per100gFat: 7.0),
  FoodItem(name: '全麦面包',  per100gKcal: 247, per100gProtein: 13.0, per100gCarbs: 41.0, per100gFat: 4.0),
  FoodItem(name: '意大利面',  per100gKcal: 157, per100gProtein: 5.8,  per100gCarbs: 31.0, per100gFat: 0.9),
  FoodItem(name: '红薯',      per100gKcal: 86,  per100gProtein: 1.6,  per100gCarbs: 20.0, per100gFat: 0.1),
  FoodItem(name: '土豆',      per100gKcal: 77,  per100gProtein: 2.0,  per100gCarbs: 17.0, per100gFat: 0.1),
  FoodItem(name: '玉米',      per100gKcal: 96,  per100gProtein: 3.4,  per100gCarbs: 21.0, per100gFat: 1.5),
  FoodItem(name: '馒头',      per100gKcal: 233, per100gProtein: 7.8,  per100gCarbs: 47.0, per100gFat: 1.3),
  FoodItem(name: '米粥',      per100gKcal: 46,  per100gProtein: 1.1,  per100gCarbs: 10.0, per100gFat: 0.3),
  FoodItem(name: '包子（肉）', per100gKcal: 226, per100gProtein: 10.0, per100gCarbs: 32.0, per100gFat: 7.0),
  FoodItem(name: '饺子（猪肉白菜）', per100gKcal: 240, per100gProtein: 10.0, per100gCarbs: 35.0, per100gFat: 7.0),

  // ── 蔬菜 ─────────────────────────────────────────────────────────────────────
  FoodItem(name: '西兰花', per100gKcal: 34,  per100gProtein: 2.8,  per100gCarbs: 7.0,  per100gFat: 0.4),
  FoodItem(name: '菠菜',   per100gKcal: 23,  per100gProtein: 2.9,  per100gCarbs: 3.6,  per100gFat: 0.4),
  FoodItem(name: '黄瓜',   per100gKcal: 15,  per100gProtein: 0.7,  per100gCarbs: 3.6,  per100gFat: 0.1),
  FoodItem(name: '西红柿', per100gKcal: 18,  per100gProtein: 0.9,  per100gCarbs: 3.9,  per100gFat: 0.2),
  FoodItem(name: '胡萝卜', per100gKcal: 41,  per100gProtein: 0.9,  per100gCarbs: 10.0, per100gFat: 0.2),
  FoodItem(name: '白菜',   per100gKcal: 13,  per100gProtein: 1.2,  per100gCarbs: 2.2,  per100gFat: 0.2),
  FoodItem(name: '生菜沙拉', per100gKcal: 15, per100gProtein: 1.4,  per100gCarbs: 2.9,  per100gFat: 0.2),
  FoodItem(name: '番茄炒蛋', per100gKcal: 95, per100gProtein: 4.5,  per100gCarbs: 5.5,  per100gFat: 6.5),

  // ── 水果 ─────────────────────────────────────────────────────────────────────
  FoodItem(name: '苹果', per100gKcal: 52,  per100gProtein: 0.3,  per100gCarbs: 14.0, per100gFat: 0.2),
  FoodItem(name: '香蕉', per100gKcal: 89,  per100gProtein: 1.1,  per100gCarbs: 23.0, per100gFat: 0.3),
  FoodItem(name: '蓝莓', per100gKcal: 57,  per100gProtein: 0.7,  per100gCarbs: 14.0, per100gFat: 0.3),
  FoodItem(name: '橙子', per100gKcal: 47,  per100gProtein: 0.9,  per100gCarbs: 12.0, per100gFat: 0.1),
  FoodItem(name: '草莓', per100gKcal: 32,  per100gProtein: 0.7,  per100gCarbs: 7.7,  per100gFat: 0.3),

  // ── 乳制品 & 豆制品 ───────────────────────────────────────────────────────────
  FoodItem(name: '全脂牛奶',  per100gKcal: 61,  per100gProtein: 3.2,  per100gCarbs: 4.8,  per100gFat: 3.3),
  FoodItem(name: '希腊酸奶', per100gKcal: 59,  per100gProtein: 10.0, per100gCarbs: 3.6,  per100gFat: 0.4),
  FoodItem(name: '豆浆',     per100gKcal: 33,  per100gProtein: 3.0,  per100gCarbs: 1.8,  per100gFat: 1.8),
  FoodItem(name: '豆腐',     per100gKcal: 76,  per100gProtein: 8.0,  per100gCarbs: 1.9,  per100gFat: 4.8),
  FoodItem(name: '毛豆',     per100gKcal: 121, per100gProtein: 11.0, per100gCarbs: 10.0, per100gFat: 5.2),
  FoodItem(name: '鹰嘴豆',   per100gKcal: 164, per100gProtein: 9.0,  per100gCarbs: 27.0, per100gFat: 2.6),

  // ── 坚果 & 油脂 ──────────────────────────────────────────────────────────────
  FoodItem(name: '杏仁',  per100gKcal: 579, per100gProtein: 21.0, per100gCarbs: 22.0, per100gFat: 50.0),
  FoodItem(name: '花生',  per100gKcal: 567, per100gProtein: 26.0, per100gCarbs: 16.0, per100gFat: 49.0),
  FoodItem(name: '橄榄油', per100gKcal: 884, per100gProtein: 0,    per100gCarbs: 0,    per100gFat: 100.0),

  // ── 蛋白粉 ───────────────────────────────────────────────────────────────────
  FoodItem(name: '乳清蛋白粉', per100gKcal: 400, per100gProtein: 80.0, per100gCarbs: 8.0, per100gFat: 5.0),

  // ── 饮料 ─────────────────────────────────────────────────────────────────────
  FoodItem(name: '美式咖啡',   per100gKcal: 9,   per100gProtein: 0.1, per100gCarbs: 1.7, per100gFat: 0.1),
  FoodItem(name: '全脂拿铁',   per100gKcal: 54,  per100gProtein: 3.3, per100gCarbs: 5.1, per100gFat: 2.0),

  // ── 零食 ─────────────────────────────────────────────────────────────────────
  FoodItem(name: '黑巧克力(70%)', per100gKcal: 598, per100gProtein: 7.8,  per100gCarbs: 46.0, per100gFat: 43.0),
  FoodItem(name: '能量棒',        per100gKcal: 370, per100gProtein: 10.0, per100gCarbs: 60.0, per100gFat: 8.0),
];

/// Case-insensitive search by food name.
List<FoodItem> searchFood(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return kFoodLibrary;
  return kFoodLibrary.where((f) => f.name.toLowerCase().contains(q)).toList();
}
