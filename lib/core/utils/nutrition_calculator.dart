import '../constants/diet_constants.dart';

class NutritionData {
  final double carb;
  final double protein;
  final double fat;

  const NutritionData({
    required this.carb,
    required this.protein,
    required this.fat,
  });

  NutritionData operator +(NutritionData other) {
    return NutritionData(
      carb: carb + other.carb,
      protein: protein + other.protein,
      fat: fat + other.fat,
    );
  }

  NutritionData operator -(NutritionData other) {
    return NutritionData(
      carb: carb - other.carb,
      protein: protein - other.protein,
      fat: fat - other.fat,
    );
  }

  NutritionData operator *(double factor) {
    return NutritionData(
      carb: carb * factor,
      protein: protein * factor,
      fat: fat * factor,
    );
  }

  double get totalCalories => carb * 4 + protein * 4 + fat * 9;

  @override
  String toString() =>
      'NutritionData(carb: ${carb.toStringAsFixed(1)}g, protein: ${protein.toStringAsFixed(1)}g, fat: ${fat.toStringAsFixed(1)}g)';
}

enum ComplianceStatus { short, ok, excess }

class NutritionCalculator {
  /// 根据食材和克数计算营养素
  static NutritionData calculateNutrition({
    required double carbPer100g,
    required double proteinPer100g,
    required double fatPer100g,
    required double amountInGrams,
  }) {
    final factor = amountInGrams / 100.0;
    return NutritionData(
      carb: carbPer100g * factor,
      protein: proteinPer100g * factor,
      fat: fatPer100g * factor,
    );
  }

  /// 计算餐次已摄入营养素总计
  static NutritionData calculateMealTotal(List<Map<String, double>> items) {
    double totalCarb = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (final item in items) {
      totalCarb += item['carb'] ?? 0;
      totalProtein += item['protein'] ?? 0;
      totalFat += item['fat'] ?? 0;
    }

    return NutritionData(
      carb: totalCarb,
      protein: totalProtein,
      fat: totalFat,
    );
  }

  /// 计算当日已摄入营养素总计
  static NutritionData calculateDayTotal(List<NutritionData> meals) {
    NutritionData total = const NutritionData(carb: 0, protein: 0, fat: 0);
    for (final meal in meals) {
      total = total + meal;
    }
    return total;
  }

  /// 判断营养素达标状态（容差±5g）
  static ComplianceStatus checkCompliance(double actual, double planned, {double tolerance = DietConstants.COMPLIANCE_TOLERANCE}) {
    final diff = actual - planned;
    if (diff < -tolerance) return ComplianceStatus.short;
    if (diff > tolerance) return ComplianceStatus.excess;
    return ComplianceStatus.ok;
  }

  /// 判断当日营养素总体达标状态
  static Map<String, ComplianceStatus> checkDayCompliance({
    required double actualCarb,
    required double actualProtein,
    required double actualFat,
    required double plannedCarb,
    required double plannedProtein,
    required double plannedFat,
  }) {
    return {
      'carb': checkCompliance(actualCarb, plannedCarb),
      'protein': checkCompliance(actualProtein, plannedProtein),
      'fat': checkCompliance(actualFat, plannedFat),
    };
  }

  /// 重新分配跳过餐次的营养素到剩余餐次（自动均分）
  static List<NutritionData> redistributeNutrition({
    required List<NutritionData> originalMeals,
    required int skippedMealIndex,
  }) {
    if (skippedMealIndex < 0 || skippedMealIndex >= originalMeals.length) {
      return originalMeals;
    }

    final skippedMeal = originalMeals[skippedMealIndex];
    final remainingMeals = <NutritionData>[];
    final remainingIndices = <int>[];

    for (int i = 0; i < originalMeals.length; i++) {
      if (i != skippedMealIndex) {
        remainingMeals.add(originalMeals[i]);
        remainingIndices.add(i);
      }
    }

    if (remainingMeals.isEmpty) {
      return originalMeals;
    }

    // 计算每份应分配的营养素
    final perMealCarb = skippedMeal.carb / remainingMeals.length;
    final perMealProtein = skippedMeal.protein / remainingMeals.length;
    final perMealFat = skippedMeal.fat / remainingMeals.length;

    // 复制原数据并更新
    final result = List<NutritionData>.from(originalMeals);
    for (final index in remainingIndices) {
      result[index] = NutritionData(
        carb: result[index].carb + perMealCarb,
        protein: result[index].protein + perMealProtein,
        fat: result[index].fat + perMealFat,
      );
    }

    return result;
  }

  /// 获取达标状态的中文描述
  static String getComplianceText(ComplianceStatus status) {
    switch (status) {
      case ComplianceStatus.short:
        return '未达标';
      case ComplianceStatus.ok:
        return '达标';
      case ComplianceStatus.excess:
        return '超标';
    }
  }

  /// 获取达标状态颜色值
  static int getComplianceColor(ComplianceStatus status) {
    switch (status) {
      case ComplianceStatus.short:
        return 0xFF9E9E9E; // 灰色
      case ComplianceStatus.ok:
        return 0xFF4CAF50; // 绿色
      case ComplianceStatus.excess:
        return 0xFFF44336; // 红色
    }
  }
}
