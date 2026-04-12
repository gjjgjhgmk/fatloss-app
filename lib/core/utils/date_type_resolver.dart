import '../constants/diet_constants.dart';
import '../../data/models/app_settings.dart';
import '../database/hive_helper.dart';

class DateTypeResolver {
  // 训练循环：背 -> 胸 -> 腿 -> 背 -> 胸 -> 肩 -> 休息
  static const List<String> trainingCycle = <String>[
    'back',
    'chest',
    'leg',
    'back',
    'chest',
    'shoulder',
    'rest',
  ];

  static AppSettings _getSettings() {
    return HiveHelper.instance.appSettingsBoxInstance.get('settings') ??
        AppSettings(cycleStartDate: DateTime.now());
  }

  static Future<void> _saveSettings(AppSettings settings) async {
    await HiveHelper.instance.appSettingsBoxInstance.put('settings', settings);
  }

  static DateTime get cycleStartDate => _getSettings().cycleStartDate;

  static Future<void> setCycleStartDate(DateTime date) async {
    final settings = _getSettings();
    await _saveSettings(settings.copyWith(cycleStartDate: date));
  }

  static int get skippedDays => _getSettings().skippedDays;

  static Future<void> setRestDay(DateTime date, bool isRest) async {
    final settings = _getSettings();
    final dateStr = _formatDate(date);
    final manualRestDays = List<String>.from(settings.manualRestDays);
    final alreadyManualRest = manualRestDays.contains(dateStr);

    if (isRest) {
      if (alreadyManualRest) return;

      manualRestDays.add(dateStr);
      var nextSkippedDays = settings.skippedDays;
      final originalDayType = _getBaseDayType(date, settings);
      if (originalDayType != 'rest') {
        nextSkippedDays += 1;
      }

      await _saveSettings(
        settings.copyWith(
          skippedDays: nextSkippedDays,
          manualRestDays: manualRestDays,
        ),
      );
      return;
    }

    if (!alreadyManualRest) return;

    manualRestDays.remove(dateStr);
    var nextSkippedDays = settings.skippedDays;
    final originalDayType = _getBaseDayType(date, settings);
    if (originalDayType != 'rest') {
      nextSkippedDays = (nextSkippedDays - 1).clamp(0, 1 << 30).toInt();
    }

    await _saveSettings(
      settings.copyWith(
        skippedDays: nextSkippedDays,
        manualRestDays: manualRestDays,
      ),
    );
  }

  static bool isManualRestDay(DateTime date) {
    final dateStr = _formatDate(date);
    return _getSettings().isManualRestDay(dateStr);
  }

  static bool isCardioDay(DateTime date) {
    final dateStr = _formatDate(date);
    return _getSettings().isCardioDay(dateStr);
  }

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

  static String _getBaseDayType(DateTime date, AppSettings settings) {
    final effectiveDays =
        date.difference(settings.cycleStartDate).inDays - settings.skippedDays;
    final cyclePosition = effectiveDays % 7;
    final adjustedPosition =
        cyclePosition < 0 ? cyclePosition + 7 : cyclePosition;
    return trainingCycle[adjustedPosition];
  }

  static String resolveDayType(DateTime date) {
    if (isManualRestDay(date)) {
      return 'rest';
    }

    final settings = _getSettings();
    return _getBaseDayType(date, settings);
  }

  static String getDayTypeName(String dayType) {
    return DietConstants.DAY_TYPE_NAMES[dayType] ?? dayType;
  }

  static bool isTrainingDay(DateTime date) {
    final dayType = resolveDayType(date);
    return dayType != 'rest';
  }

  static bool isPostWorkoutTime(String mealTime) {
    return mealTime == '22:30';
  }

  static bool isPreWorkoutTime(String mealTime) {
    return mealTime == '21:00';
  }

  static List<Map<String, dynamic>> getMealTemplatesForDayType(String dayType) {
    return DietConstants.getMealTemplatesForDayType(dayType);
  }

  static List<Map<String, dynamic>> getMealTemplatesForDate(DateTime date) {
    final dayType = resolveDayType(date);
    return getMealTemplatesForDayType(dayType);
  }

  static DateTime? getNextTrainingDay(DateTime from) {
    for (int i = 1; i <= 7; i++) {
      final nextDay = from.add(Duration(days: i));
      if (isTrainingDay(nextDay)) {
        return nextDay;
      }
    }
    return null;
  }

  static int getCyclePosition(DateTime date) {
    final settings = _getSettings();
    final effectiveDays =
        date.difference(settings.cycleStartDate).inDays - settings.skippedDays;
    final cyclePosition = effectiveDays % 7;
    return cyclePosition < 0 ? cyclePosition + 7 : cyclePosition;
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
