import '../constants/diet_constants.dart';
import '../../data/models/app_settings.dart';
import '../database/hive_helper.dart';

class DateTypeResolver {
  // 训练循环：背→胸→腿→背→胸→肩→休息（7天循环）
  static const List<String> TRAINING_CYCLE = [
    'back',    // 0: 练背日
    'chest',   // 1: 练胸日
    'leg',     // 2: 练腿日
    'back',    // 3: 练背日
    'chest',   // 4: 练胸日
    'shoulder',// 5: 练肩日
    'rest',    // 6: 休息日
  ];

  static AppSettings _getSettings() {
    return HiveHelper.instance.appSettingsBoxInstance.get('settings') ??
        AppSettings(cycleStartDate: DateTime.now());
  }

  static Future<void> _saveSettings(AppSettings settings) async {
    await HiveHelper.instance.appSettingsBoxInstance.put('settings', settings);
  }

  /// 获取周期基准日
  static DateTime get cycleStartDate => _getSettings().cycleStartDate;

  /// 设置周期基准日
  static Future<void> setCycleStartDate(DateTime date) async {
    final settings = _getSettings();
    await _saveSettings(settings.copyWith(cycleStartDate: date));
  }

  /// 获取累积的顺延天数
  static int get skippedDays => _getSettings().skippedDays;

  /// 设置某天为休息日（顺延机制）
  /// 当用户将原本的训练日设为休息日时，需要顺延整个计划
  static Future<void> setRestDay(DateTime date, bool isRest) async {
    final settings = _getSettings();
    final dateStr = _formatDate(date);
    final today = DateTime.now();
    final todayStr = _formatDate(today);

    if (isRest) {
      // 只有设置"今天"为休息日时才触发顺延
      if (dateStr == todayStr) {
        // 获取今天原本的训练日类型
        final originalDayType = _getBaseDayType(date, settings);

        // 只有原本是训练日才需要顺延
        if (originalDayType != 'rest') {
          await _saveSettings(settings.copyWith(
            skippedDays: settings.skippedDays + 1,
          ));
        }
      }
    }
  }

  /// 检查某天是否被手动设为休息日（通过顺延机制实现）
  static bool isManualRestDay(DateTime date) {
    final dayType = resolveDayType(date);
    return dayType == 'rest';
  }

  /// 判断是否为空腹有氧日
  static bool isCardioDay(DateTime date) {
    final dateStr = _formatDate(date);
    return _getSettings().isCardioDay(dateStr);
  }

  /// 设置某天是否有氧
  static Future<void> setCardioDay(DateTime date, bool hasCardio) async {
    final settings = _getSettings();
    final dateStr = _formatDate(date);

    if (hasCardio) {
      settings.addCardioDay(dateStr);
    } else {
      settings.removeCardioDay(dateStr);
    }

    await _saveSettings(settings);
  }

  /// 获取基础训练日类型（不考虑手动设置的休息日）
  /// 使用周期计算：effectiveDays = (today - cycleStartDate).inDays - skippedDays
  static String _getBaseDayType(DateTime date, AppSettings settings) {
    final effectiveDays = date.difference(settings.cycleStartDate).inDays - settings.skippedDays;
    final cyclePosition = effectiveDays % 7;
    // 确保 cyclePosition 为正数
    final adjustedPosition = cyclePosition < 0 ? cyclePosition + 7 : cyclePosition;
    return TRAINING_CYCLE[adjustedPosition];
  }

  /// 综合判断日期类型
  /// 训练循环：背→胸→腿→背→胸→肩→休息（7天循环）
  static String resolveDayType(DateTime date) {
    final settings = _getSettings();
    return _getBaseDayType(date, settings);
  }

  /// 获取日期类型中文名称
  static String getDayTypeName(String dayType) {
    return DietConstants.DAY_TYPE_NAMES[dayType] ?? dayType;
  }

  /// 判断是否为训练日
  static bool isTrainingDay(DateTime date) {
    final dayType = resolveDayType(date);
    return dayType != 'rest';
  }

  /// 判断是否为练后餐时间（22:30）
  static bool isPostWorkoutTime(String mealTime) {
    return mealTime == '22:30';
  }

  /// 判断是否为练前餐时间（21:00，仅练腿日）
  static bool isPreWorkoutTime(String mealTime) {
    return mealTime == '21:00';
  }

  /// 获取指定日期类型的所有餐次模板
  static List<Map<String, dynamic>> getMealTemplatesForDayType(String dayType) {
    return DietConstants.getMealTemplatesForDayType(dayType);
  }

  /// 获取某日期的餐次配置
  static List<Map<String, dynamic>> getMealTemplatesForDate(DateTime date) {
    final dayType = resolveDayType(date);
    return getMealTemplatesForDayType(dayType);
  }

  /// 获取下一个训练日
  static DateTime? getNextTrainingDay(DateTime from) {
    for (int i = 1; i <= 7; i++) {
      final nextDay = from.add(Duration(days: i));
      if (isTrainingDay(nextDay)) {
        return nextDay;
      }
    }
    return null;
  }

  /// 获取训练循环中的位置（0-6）
  static int getCyclePosition(DateTime date) {
    final settings = _getSettings();
    final effectiveDays = date.difference(settings.cycleStartDate).inDays - settings.skippedDays;
    final cyclePosition = effectiveDays % 7;
    return cyclePosition < 0 ? cyclePosition + 7 : cyclePosition;
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
