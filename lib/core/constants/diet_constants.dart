class DietConstants {
  // 每日固定营养素摄入
  static const double DAILY_PROTEIN = 120.0; // g
  static const double DAILY_FAT = 56.0; // g

  // 各日期类型碳水预设 (g)
  // 5种力量训练日 + 休息日
  static const Map<String, double> CARB_BY_DAY_TYPE = {
    'rest': 160.0,
    'back': 240.0,      // 练背日
    'chest': 240.0,     // 练胸日
    'leg': 280.0,       // 练腿日
    'shoulder': 200.0,   // 练肩日
    'cardio': 160.0,    // 空腹有氧日
  };

  // 各日期类型中文名称
  static const Map<String, String> DAY_TYPE_NAMES = {
    'rest': '休息日',
    'back': '练背日',
    'chest': '练胸日',
    'leg': '练腿日',
    'shoulder': '练肩日',
    'cardio': '空腹有氧日',
  };

  // 训练循环定义（背→胸→腿→背→胸→肩→休息，7天循环）
  // 索引0-6对应周一到周日
  static const List<String> TRAINING_CYCLE = [
    'back',    // 0: 周一 - 练背日
    'chest',   // 1: 周二 - 练胸日
    'leg',     // 2: 周三 - 练腿日
    'back',    // 3: 周四 - 练背日
    'chest',   // 4: 周五 - 练胸日
    'shoulder',// 5: 周六 - 练肩日
    'rest',    // 6: 周日 - 休息日
  ];

  // 周几对应的训练类型（用于计算循环）
  // 0=周一, 1=周二, ..., 6=周日
  static const Map<int, String> WEEKDAY_TRAINING = {
    0: 'back',     // 周一
    1: 'chest',    // 周二
    2: 'leg',      // 周三
    3: 'back',     // 周四
    4: 'chest',    // 周五
    5: 'shoulder', // 周六
    6: 'rest',     // 周日
  };

  // 空腹有氧日（周二、四、六）
  static const List<int> CARDIO_WEEKDAYS = [2, 4, 6]; // 周二=2, 周四=4, 周六=6

  // 营养素达标容差 (g)
  static const double COMPLIANCE_TOLERANCE = 5.0;

  // 餐次状态
  static const String MEAL_STATUS_PENDING = 'pending';
  static const String MEAL_STATUS_COMPLETED = 'completed';
  static const String MEAL_STATUS_SKIPPED = 'skipped';

  // 达标状态
  static const String COMPLIANCE_SHORT = 'short';
  static const String COMPLIANCE_OK = 'ok';
  static const String COMPLIANCE_EXCESS = 'excess';

  // 食材类别
  static const String CATEGORY_CARB = 'carb';
  static const String CATEGORY_PROTEIN = 'protein';
  static const String CATEGORY_FAT = 'fat';

  static const Map<String, String> CATEGORY_NAMES = {
    'carb': '碳水类',
    'protein': '蛋白质类',
    'fat': '脂肪类',
  };

  // ============ 各日期类型精确餐次配置 ============

  // 休息日：C=160g，2餐
  // 第一餐 11:00：C60 / P40 / F20
  // 第二餐 17:00：C100 / P80 / F36
  static const List<Map<String, dynamic>> REST_MEALS = [
    {'meal_order': 1, 'meal_time': '11:00', 'carb': 60.0, 'protein': 40.0, 'fat': 20.0, 'is_pre_workout': false, 'is_post_workout': false},
    {'meal_order': 2, 'meal_time': '17:00', 'carb': 100.0, 'protein': 80.0, 'fat': 36.0, 'is_pre_workout': false, 'is_post_workout': false},
  ];

  // 练背/练胸日：C=240g，练后 80g，3餐
  // 第一餐 11:00：C80 / P40 / F20
  // 第二餐 17:00：C80 / P30 / F26
  // 22:30 练后餐：C80 / P50 / F10（低油）
  static const List<Map<String, dynamic>> PUSH_PULL_MEALS = [
    {'meal_order': 1, 'meal_time': '11:00', 'carb': 80.0, 'protein': 40.0, 'fat': 20.0, 'is_pre_workout': false, 'is_post_workout': false},
    {'meal_order': 2, 'meal_time': '17:00', 'carb': 80.0, 'protein': 30.0, 'fat': 26.0, 'is_pre_workout': false, 'is_post_workout': false},
    {'meal_order': 3, 'meal_time': '22:30', 'carb': 80.0, 'protein': 50.0, 'fat': 10.0, 'is_pre_workout': false, 'is_post_workout': true},
  ];

  // 练腿日：C=280g，练前 24g，练后 96g，4餐
  // 第一餐 11:00：C120 / P40 / F20
  // 第二餐 17:00：C40 / P30 / F26
  // 21:00 练前餐：C24 / P10 / F0（小快碳）
  // 22:30 练后餐：C96 / P40 / F10
  static const List<Map<String, dynamic>> LEG_MEALS = [
    {'meal_order': 1, 'meal_time': '11:00', 'carb': 120.0, 'protein': 40.0, 'fat': 20.0, 'is_pre_workout': false, 'is_post_workout': false},
    {'meal_order': 2, 'meal_time': '17:00', 'carb': 40.0, 'protein': 30.0, 'fat': 26.0, 'is_pre_workout': false, 'is_post_workout': false},
    {'meal_order': 3, 'meal_time': '21:00', 'carb': 24.0, 'protein': 10.0, 'fat': 0.0, 'is_pre_workout': true, 'is_post_workout': false},
    {'meal_order': 4, 'meal_time': '22:30', 'carb': 96.0, 'protein': 40.0, 'fat': 10.0, 'is_pre_workout': false, 'is_post_workout': true},
  ];

  // 练肩日：C=200g，练后 40g，3餐
  // 第一餐 11:00：C90 / P40 / F20
  // 第二餐 17:00：C70 / P30 / F26
  // 22:30 练后餐：C40 / P50 / F10
  static const List<Map<String, dynamic>> SHOULDER_MEALS = [
    {'meal_order': 1, 'meal_time': '11:00', 'carb': 90.0, 'protein': 40.0, 'fat': 20.0, 'is_pre_workout': false, 'is_post_workout': false},
    {'meal_order': 2, 'meal_time': '17:00', 'carb': 70.0, 'protein': 30.0, 'fat': 26.0, 'is_pre_workout': false, 'is_post_workout': false},
    {'meal_order': 3, 'meal_time': '22:30', 'carb': 40.0, 'protein': 50.0, 'fat': 10.0, 'is_pre_workout': false, 'is_post_workout': true},
  ];

  // 空腹有氧日：C=160g，1餐（有氧后正常吃）
  // 有氧后第一餐 11:00：C160 / P120 / F56

  static const List<Map<String, dynamic>> CARDIO_MEALS = [
    {'meal_order': 1, 'meal_time': '11:00', 'carb': 60.0, 'protein': 40.0, 'fat': 20.0, 'is_pre_workout': false, 'is_post_workout': false},
    {'meal_order': 2, 'meal_time': '17:00', 'carb': 100.0, 'protein': 80.0, 'fat': 36.0, 'is_pre_workout': false, 'is_post_workout': false},
  ];


  // 获取餐次配置
  static List<Map<String, dynamic>> getMealTemplatesForDayType(String dayType) {
    switch (dayType) {
      case 'rest':
        return REST_MEALS;
      case 'back':
      case 'chest':
        return PUSH_PULL_MEALS;
      case 'leg':
        return LEG_MEALS;
      case 'shoulder':
        return SHOULDER_MEALS;
      case 'cardio':
        return CARDIO_MEALS;
      default:
        return REST_MEALS;
    }
  }

  // 获取餐次数量
  static int getMealCount(String dayType) {
    return getMealTemplatesForDayType(dayType).length;
  }
}
