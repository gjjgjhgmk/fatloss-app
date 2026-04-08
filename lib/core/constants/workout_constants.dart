class WorkoutConstants {
  // ============ 训练计划定义 ============

  // 练胸日
  static const List<Map<String, dynamic>> CHEST_EXERCISES = [
    {'name': '上斜杠铃卧推', 'sets': 4, 'reps': '8-12'},
    {'name': '杠铃卧推', 'sets': 4, 'reps': '8-12'},
    {'name': '器械飞鸟', 'sets': 3, 'reps': '12-15'},
    {'name': '双杠臂屈伸（辅助）', 'sets': 3, 'reps': '8-12'},
  ];

  // 练背日
  static const List<Map<String, dynamic>> BACK_EXERCISES = [
    {'name': '引体向上（辅助）', 'sets': 4, 'reps': '8-12'},
    {'name': '宽距下拉', 'sets': 4, 'reps': '10-12'},
    {'name': '坐姿单手划船', 'sets': 3, 'reps': '10-12'},
    {'name': '坐姿划船', 'sets': 3, 'reps': '10-12'},
    {'name': '哑铃弯举', 'sets': 3, 'reps': '12-15'},
  ];

  // 练腿日
  static const List<Map<String, dynamic>> LEG_EXERCISES = [
    {'name': '深蹲', 'sets': 4, 'reps': '8-12'},
    {'name': '杠铃臀冲', 'sets': 4, 'reps': '10-12'},
    {'name': '卷腹', 'sets': 3, 'reps': '15-20'},
    {'name': '站姿器械提踵', 'sets': 3, 'reps': '15-20'},
    {'name': '器械倒蹬', 'sets': 3, 'reps': '10-12'},
    {'name': '硬拉', 'sets': 4, 'reps': '6-8'},
    {'name': '坐姿髋内收', 'sets': 3, 'reps': '12-15'},
  ];

  // 练肩日
  static const List<Map<String, dynamic>> SHOULDER_EXERCISES = [
    {'name': '哑铃推肩', 'sets': 4, 'reps': '8-12'},
    {'name': '蝴蝶机反向飞鸟', 'sets': 3, 'reps': '12-15'},
    {'name': '侧平举', 'sets': 3, 'reps': '12-15'},
  ];

  // 有氧日
  static const List<Map<String, dynamic>> CARDIO_EXERCISES = [
    {'name': '空腹有氧', 'duration': 30},
    {'name': '跑步', 'duration': 20},
    {'name': '骑行', 'duration': 30},
  ];

  // 根据训练类型获取动作列表
  static List<Map<String, dynamic>> getExercisesForDayType(String dayType) {
    switch (dayType) {
      case 'chest':
        return CHEST_EXERCISES;
      case 'back':
        return BACK_EXERCISES;
      case 'leg':
        return LEG_EXERCISES;
      case 'shoulder':
        return SHOULDER_EXERCISES;
      case 'cardio':
        return CARDIO_EXERCISES;
      default:
        return [];
    }
  }

  // 获取训练类型中文名称
  static const Map<String, String> DAY_TYPE_NAMES = {
    'chest': '练胸日',
    'back': '练背日',
    'leg': '练腿日',
    'shoulder': '练肩日',
    'cardio': '空腹有氧',
    'rest': '休息日',
  };

  static String getDayTypeName(String dayType) {
    return DAY_TYPE_NAMES[dayType] ?? dayType;
  }

  // 训练类型图标
  static const Map<String, int> DAY_TYPE_ICONS = {
    'chest': 0xe1c3, // Icons.fitness_center
    'back': 0xe887,   // Icons.rowing
    'leg': 0xe570,    // Icons.directions_run
    'shoulder': 0xe5c4, // Icons.accessibility_new
    'cardio': 0xe52f,  // Icons.favorite
    'rest': 0xe8b4,    // Icons.hotel
  };

  // 训练类型颜色
  static const Map<String, int> DAY_TYPE_COLORS = {
    'chest': 0xFFE53935,    // 红色
    'back': 0xFF1E88E5,     // 蓝色
    'leg': 0xFF43A047,      // 绿色
    'shoulder': 0xFFFF9800, // 橙色
    'cardio': 0xFFE91E63,   // 粉色
    'rest': 0xFF9E9E9E,     // 灰色
  };

  // ============ 月度目标配置 ============
  static const double APRIL_START_WEIGHT = 80.0;
  static const double APRIL_GOAL_WEIGHT = 75.0;
  static const String APRIL_GOAL_MONTH = '2026-04';
}
