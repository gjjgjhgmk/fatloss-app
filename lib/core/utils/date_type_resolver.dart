import '../constants/diet_constants.dart';

class DateTypeResolver {
  // 基准日期：假设项目初始化当天为练背日（用户可自定义）
  static DateTime _baseDate = DateTime.now();

  // 手动设置的休息日列表（用于特殊情况顺延）
  static final Set<String> _manualRestDays = {};

  // 手动设置的有氧日列表
  static final Set<String> _cardioDays = {};

  static void setBaseDate(DateTime date) {
    _baseDate = DateTime(date.year, date.month, date.day);
  }

  static DateTime get baseDate => _baseDate;

  /// 设置某天为休息日
  static void setRestDay(DateTime date, bool isRest) {
    final dateStr = _formatDate(date);
    if (isRest) {
      _manualRestDays.add(dateStr);
    } else {
      _manualRestDays.remove(dateStr);
    }
  }

  /// 设置某天是否有氧
  static void setCardioDay(DateTime date, bool hasCardio) {
    final dateStr = _formatDate(date);
    if (hasCardio) {
      _cardioDays.add(dateStr);
    } else {
      _cardioDays.remove(dateStr);
    }
  }

  /// 判断是否为空腹有氧日
  static bool isCardioDay(DateTime date) {
    final dateStr = _formatDate(date);
    return _cardioDays.contains(dateStr);
  }

  /// 获取基础训练日类型（不考虑手动设置的休息日）
  /// 训练循环：背→胸→腿→背→胸→肩→休息（7天循环）
  static String _getBaseDayType(DateTime date) {
    final weekday = date.weekday; // 1=周一, 7=周日
    final adjustedWeekday = weekday - 1; // 转为0=周一, 6=周日
    return DietConstants.WEEKDAY_TRAINING[adjustedWeekday] ?? 'rest';
  }

  /// 综合判断日期类型
  /// 优先使用手动设置的休息日，否则使用训练循环
  static String resolveDayType(DateTime date) {
    final dateStr = _formatDate(date);

    // 优先检查手动设置的休息日
    if (_manualRestDays.contains(dateStr)) {
      return 'rest';
    }

    return _getBaseDayType(date);
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
    final weekday = date.weekday;
    final adjustedWeekday = weekday - 1; // 0=周一
    return adjustedWeekday;
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
