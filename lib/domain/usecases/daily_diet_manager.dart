import '../../core/utils/date_type_resolver.dart';
import '../../core/utils/nutrition_calculator.dart';
import '../../data/models/daily_meal_record.dart';
import '../../data/models/diet_rule.dart';
import '../../data/models/meal_item_record.dart';
import '../../data/repositories/daily_record_repository.dart';
import '../../data/repositories/diet_rule_repository.dart';
import '../../data/repositories/ingredient_repository.dart';

class DailyDietStatus {
  final String date;
  final String dayType;
  final String dayTypeName;
  final bool isCardioDay;
  final DietRule? dietRule;
  final List<DailyMealRecord> meals;
  final NutritionData totalActual;
  final Map<String, ComplianceStatus> complianceStatus;

  DailyDietStatus({
    required this.date,
    required this.dayType,
    required this.dayTypeName,
    required this.isCardioDay,
    this.dietRule,
    required this.meals,
    required this.totalActual,
    required this.complianceStatus,
  });

  double get plannedCarb => dietRule?.totalCarb ?? 0;
  double get plannedProtein => dietRule?.totalProtein ?? 0;
  double get plannedFat => dietRule?.totalFat ?? 0;

  double get carbProgress => plannedCarb > 0 ? (totalActual.carb / plannedCarb).clamp(0.0, 2.0) : 0;
  double get proteinProgress => plannedProtein > 0 ? (totalActual.protein / plannedProtein).clamp(0.0, 2.0) : 0;
  double get fatProgress => plannedFat > 0 ? (totalActual.fat / plannedFat).clamp(0.0, 2.0) : 0;

  int get completedMeals => meals.where((m) => m.isCompleted).length;
  int get totalMeals => meals.length;
  int get skippedMeals => meals.where((m) => m.isSkipped).length;
}

class DailyDietManager {
  final DailyRecordRepository _dailyRecordRepo = DailyRecordRepository();
  final DietRuleRepository _dietRuleRepo = DietRuleRepository();
  final IngredientRepository _ingredientRepo = IngredientRepository();

  /// 获取当日饮食数据（含进度）
  Future<DailyDietStatus> getDailyDietStatus(DateTime date) async {
    final dateStr = _formatDate(date);
    final dayType = DateTypeResolver.resolveDayType(date);
    final dayTypeName = DateTypeResolver.getDayTypeName(dayType);
    final isCardioDay = DateTypeResolver.isCardioDay(date);

    // 获取或初始化当日记录
    await _dailyRecordRepo.initializeDailyRecords(dateStr, dayType);

    // 获取当日所有餐次记录
    final meals = _dailyRecordRepo.getDailyRecords(dateStr);

    // 获取饮食规则
    final dietRule = _dietRuleRepo.getRuleByDayType(dayType);

    // 计算实际摄入总计
    final totalActual = _calculateTotalActual(meals);

    // 判断达标状态
    final complianceStatus = NutritionCalculator.checkDayCompliance(
      actualCarb: totalActual.carb,
      actualProtein: totalActual.protein,
      actualFat: totalActual.fat,
      plannedCarb: dietRule?.totalCarb ?? 0,
      plannedProtein: dietRule?.totalProtein ?? 0,
      plannedFat: dietRule?.totalFat ?? 0,
    );

    return DailyDietStatus(
      date: dateStr,
      dayType: dayType,
      dayTypeName: dayTypeName,
      isCardioDay: isCardioDay,
      dietRule: dietRule,
      meals: meals,
      totalActual: totalActual,
      complianceStatus: complianceStatus,
    );
  }

  NutritionData _calculateTotalActual(List<DailyMealRecord> meals) {
    double totalCarb = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (final meal in meals) {
      totalCarb += meal.actualCarb;
      totalProtein += meal.actualProtein;
      totalFat += meal.actualFat;
    }

    return NutritionData(
      carb: totalCarb,
      protein: totalProtein,
      fat: totalFat,
    );
  }

  /// 记录某餐摄入
  Future<void> recordMeal({
    required String date,
    required int mealOrder,
    required List<MealItemRecord> items,
  }) async {
    final id = '${date}_$mealOrder';
    await _dailyRecordRepo.saveMealItems(id, items);
  }

  /// 跳过某餐
  Future<void> skipMeal(String date, int mealOrder) async {
    _dailyRecordRepo.skipMeal(date, mealOrder);
  }

  /// 获取指定日期的类型
  String getDayType(DateTime date) {
    return DateTypeResolver.resolveDayType(date);
  }

  /// 判断是否为空腹有氧日
  bool isCardioDay(DateTime date) {
    return DateTypeResolver.isCardioDay(date);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
