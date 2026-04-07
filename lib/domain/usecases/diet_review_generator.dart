import '../../core/utils/nutrition_calculator.dart';
import '../../data/models/daily_meal_record.dart';
import '../../data/models/daily_review.dart';
import '../../data/repositories/daily_record_repository.dart';
import '../../data/repositories/daily_review_repository.dart';
import '../../data/repositories/diet_rule_repository.dart';

class MealSummary {
  final int mealOrder;
  final String mealTime;
  final NutritionData planned;
  final NutritionData actual;
  final String status;
  final bool isPostWorkout;

  MealSummary({
    required this.mealOrder,
    required this.mealTime,
    required this.planned,
    required this.actual,
    required this.status,
    this.isPostWorkout = false,
  });
}

class DietReviewResult {
  final String recordDate;
  final NutritionData totalActual;
  final NutritionData totalPlanned;
  final Map<String, ComplianceStatus> complianceStatus;
  final List<MealSummary> mealSummaries;
  final List<String> warnings;
  final String? userNotes;

  DietReviewResult({
    required this.recordDate,
    required this.totalActual,
    required this.totalPlanned,
    required this.complianceStatus,
    required this.mealSummaries,
    required this.warnings,
    this.userNotes,
  });
}

class DietReviewGenerator {
  final DailyRecordRepository _dailyRecordRepo = DailyRecordRepository();
  final DailyReviewRepository _dailyReviewRepo = DailyReviewRepository();
  final DietRuleRepository _dietRuleRepo = DietRuleRepository();

  /// 生成当日复盘报告
  Future<DietReviewResult> generateDailyReview(String date) async {
    // 获取当日所有餐次记录
    final meals = _dailyRecordRepo.getDailyRecords(date);

    // 获取日期类型和饮食规则
    final dayType = meals.isNotEmpty ? meals.first.dayType : 'rest';
    final dietRule = _dietRuleRepo.getRuleByDayType(dayType);

    // 计算实际摄入总计
    double totalCarbActual = 0;
    double totalProteinActual = 0;
    double totalFatActual = 0;

    final mealSummaries = <MealSummary>[];
    final warnings = <String>[];

    for (final meal in meals) {
      totalCarbActual += meal.actualCarb;
      totalProteinActual += meal.actualProtein;
      totalFatActual += meal.actualFat;

      final planned = NutritionData(
        carb: meal.plannedCarb,
        protein: meal.plannedProtein,
        fat: meal.plannedFat,
      );
      final actual = NutritionData(
        carb: meal.actualCarb,
        protein: meal.actualProtein,
        fat: meal.actualFat,
      );

      mealSummaries.add(MealSummary(
        mealOrder: meal.mealOrder,
        mealTime: meal.mealTime,
        planned: planned,
        actual: actual,
        status: meal.mealStatus,
        isPostWorkout: meal.isPostWorkout,
      ));

      // 检查练后餐是否达标
      if (meal.isPostWorkout && meal.mealStatus == 'completed') {
        final carbCompliance = NutritionCalculator.checkCompliance(
          meal.actualCarb,
          meal.plannedCarb,
        );
        if (carbCompliance != ComplianceStatus.ok) {
          warnings.add('练后餐碳水${carbCompliance == ComplianceStatus.short ? '不足' : '超标'}');
        }
      }

      // 检查未完成的餐次
      if (meal.mealStatus == 'pending') {
        warnings.add('第${meal.mealOrder}餐(${meal.mealTime})未记录');
      }
    }

    final totalActual = NutritionData(
      carb: totalCarbActual,
      protein: totalProteinActual,
      fat: totalFatActual,
    );

    final totalPlanned = NutritionData(
      carb: dietRule?.totalCarb ?? 0,
      protein: dietRule?.totalProtein ?? 0,
      fat: dietRule?.totalFat ?? 0,
    );

    final complianceStatus = NutritionCalculator.checkDayCompliance(
      actualCarb: totalActual.carb,
      actualProtein: totalActual.protein,
      actualFat: totalActual.fat,
      plannedCarb: totalPlanned.carb,
      plannedProtein: totalPlanned.protein,
      plannedFat: totalPlanned.fat,
    );

    // 获取用户备注
    final existingReview = _dailyReviewRepo.getReviewByDate(date);

    return DietReviewResult(
      recordDate: date,
      totalActual: totalActual,
      totalPlanned: totalPlanned,
      complianceStatus: complianceStatus,
      mealSummaries: mealSummaries,
      warnings: warnings,
      userNotes: existingReview?.reviewNotes,
    );
  }

  /// 保存每日复盘备注
  Future<void> saveReviewNotes(String date, String notes) async {
    final review = await generateDailyReview(date);
    await _dailyReviewRepo.upsertReview(DailyReview(
      recordDate: date,
      totalCarbActual: review.totalActual.carb,
      totalProteinActual: review.totalActual.protein,
      totalFatActual: review.totalActual.fat,
      carbStatus: _statusToString(review.complianceStatus['carb']),
      proteinStatus: _statusToString(review.complianceStatus['protein']),
      fatStatus: _statusToString(review.complianceStatus['fat']),
      reviewNotes: notes,
    ));
  }

  String? _statusToString(ComplianceStatus? status) {
    if (status == null) return null;
    switch (status) {
      case ComplianceStatus.short:
        return 'short';
      case ComplianceStatus.ok:
        return 'ok';
      case ComplianceStatus.excess:
        return 'excess';
    }
  }

  /// 生成周复盘汇总
  Future<Map<String, dynamic>> generateWeeklyReview(DateTime weekStart) async {
    final startStr = _formatDate(weekStart);
    final endStr = _formatDate(weekStart.add(const Duration(days: 6)));

    final records = _dailyRecordRepo.getRecordsInRange(startStr, endStr);

    // 按日期分组计算
    final dailyData = <String, Map<String, double>>{};
    for (final record in records) {
      final date = record.recordDate;
      dailyData[date] ??= {'carb': 0, 'protein': 0, 'fat': 0};
      dailyData[date]!['carb'] = (dailyData[date]!['carb'] ?? 0) + record.actualCarb;
      dailyData[date]!['protein'] = (dailyData[date]!['protein'] ?? 0) + record.actualProtein;
      dailyData[date]!['fat'] = (dailyData[date]!['fat'] ?? 0) + record.actualFat;
    }

    // 计算平均值
    final days = dailyData.length;
    if (days == 0) {
      return {
        'weekStart': startStr,
        'weekEnd': endStr,
        'avgCarb': 0.0,
        'avgProtein': 0.0,
        'avgFat': 0.0,
        'totalMeals': 0,
        'completedMeals': 0,
        'complianceRate': 0.0,
      };
    }

    double totalCarb = 0;
    double totalProtein = 0;
    double totalFat = 0;
    int totalMeals = 0;
    int completedMeals = 0;

    for (final data in dailyData.values) {
      totalCarb += data['carb'] ?? 0;
      totalProtein += data['protein'] ?? 0;
      totalFat += data['fat'] ?? 0;
    }

    for (final record in records) {
      totalMeals++;
      if (record.isCompleted) completedMeals++;
    }

    return {
      'weekStart': startStr,
      'weekEnd': endStr,
      'avgCarb': totalCarb / days,
      'avgProtein': totalProtein / days,
      'avgFat': totalFat / days,
      'totalMeals': totalMeals,
      'completedMeals': completedMeals,
      'complianceRate': totalMeals > 0 ? (completedMeals / totalMeals * 100) : 0.0,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
