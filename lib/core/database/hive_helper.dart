import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/diet_rule.dart';
import '../../data/models/meal_template.dart';
import '../../data/models/ingredient.dart';
import '../../data/models/daily_meal_record.dart';
import '../../data/models/meal_item_record.dart';
import '../../data/models/daily_review.dart';
import '../../data/models/weekly_review.dart';
import '../../data/models/weight_record.dart';
import '../../data/models/waist_record.dart';
import '../../data/models/workout_record.dart';
import '../../data/models/app_settings.dart';

class HiveHelper {
  static final HiveHelper instance = HiveHelper._init();

  // Box names
  static const String dietRulesBox = 'diet_rules';
  static const String mealTemplatesBox = 'meal_templates';
  static const String ingredientsBox = 'ingredients';
  static const String dailyMealRecordsBox = 'daily_meal_records';
  static const String mealItemRecordsBox = 'meal_item_records';
  static const String dailyReviewsBox = 'daily_reviews';
  static const String weeklyReviewsBox = 'weekly_reviews';
  static const String weightRecordsBox = 'weight_records';
  static const String waistRecordsBox = 'waist_records';
  static const String workoutRecordsBox = 'workout_records';
  static const String appSettingsBox = 'app_settings';

  HiveHelper._init();

  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters (with safety check to prevent duplicate registration)
    ensureAdapterRegistered();

    // Open boxes - use typed boxes where possible
    await Hive.openBox<DietRule>(dietRulesBox);
    await Hive.openBox<MealTemplate>(mealTemplatesBox);
    await Hive.openBox<Ingredient>(ingredientsBox);
    await Hive.openBox<DailyMealRecord>(dailyMealRecordsBox);
    await Hive.openBox<MealItemRecord>(mealItemRecordsBox);
    await Hive.openBox<DailyReview>(dailyReviewsBox);
    await Hive.openBox<WeeklyReview>(weeklyReviewsBox);
    await Hive.openBox<WeightRecord>(weightRecordsBox);
    await Hive.openBox<WaistRecord>(waistRecordsBox);
    await Hive.openBox<WorkoutRecord>(workoutRecordsBox);
    await Hive.openBox<AppSettings>(appSettingsBox);

    // Seed initial data if empty
    await seedDataIfNeeded();
  }

  Box<DietRule> get dietRulesBoxInstance => Hive.box<DietRule>(dietRulesBox);
  Box<MealTemplate> get mealTemplatesBoxInstance => Hive.box<MealTemplate>(mealTemplatesBox);
  Box<Ingredient> get ingredientsBoxInstance => Hive.box<Ingredient>(ingredientsBox);
  Box<DailyMealRecord> get dailyMealRecordsBoxInstance => Hive.box<DailyMealRecord>(dailyMealRecordsBox);
  Box<MealItemRecord> get mealItemRecordsBoxInstance => Hive.box<MealItemRecord>(mealItemRecordsBox);
  Box<DailyReview> get dailyReviewsBoxInstance => Hive.box<DailyReview>(dailyReviewsBox);
  Box<WeeklyReview> get weeklyReviewsBoxInstance => Hive.box<WeeklyReview>(weeklyReviewsBox);
  Box<WeightRecord> get weightRecordsBoxInstance => Hive.box<WeightRecord>(weightRecordsBox);
  Box<WaistRecord> get waistRecordsBoxInstance => Hive.box<WaistRecord>(waistRecordsBox);
  Box<WorkoutRecord> get workoutRecordsBoxInstance => Hive.box<WorkoutRecord>(workoutRecordsBox);
  Box<AppSettings> get appSettingsBoxInstance => Hive.box<AppSettings>(appSettingsBox);

  /// 确保所有 adapter 已注册（安全调用，不会重复注册）
  void ensureAdapterRegistered() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(DietRuleAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MealTemplateAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(IngredientAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DailyMealRecordAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(MealItemRecordAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(DailyReviewAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(WeeklyReviewAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(WeightRecordAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(WorkoutRecordAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(WorkoutExerciseAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(WaistRecordAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(AppSettingsAdapter());
  }

  /// 公开的 seed 方法（main.dart 中调用）
  Future<void> seedDataIfNeeded() async {
    // Seed diet rules if empty
    if (dietRulesBoxInstance.isEmpty) {
      await _seedDietRules();
    }
    // Seed meal templates if empty
    if (mealTemplatesBoxInstance.isEmpty) {
      await _seedMealTemplates();
    }
    // Seed common ingredients if empty
    if (ingredientsBoxInstance.isEmpty) {
      await _seedCommonIngredients();
    }
    // Seed app settings if empty
    if (appSettingsBoxInstance.isEmpty) {
      await _seedAppSettings();
    }
  }

  Future<void> _seedAppSettings() async {
    // 默认周期基准日设为 2026-04-07（练背日）
    // 这样 2026-04-09 就是练腿日：back(4/7) → chest(4/8) → leg(4/9)
    final settings = AppSettings(
      cycleStartDate: DateTime(2026, 4, 7),
      skippedDays: 0,
      cardioDays: [],
    );
    await appSettingsBoxInstance.put('settings', settings);
  }

  Future<void> _seedDietRules() async {
    final rules = [
      DietRule(
        dayType: 'rest',
        totalCarb: 160.0,
        totalProtein: 120.0,
        totalFat: 56.0,
        mealCount: 2,
        specialNotes: '休息日，饮食分2餐（11:00、17:00），无练前练后餐',
      ),
      DietRule(
        dayType: 'back',
        totalCarb: 240.0,
        totalProtein: 120.0,
        totalFat: 56.0,
        mealCount: 3,
        specialNotes: '练背日，22:30练后餐需摄入80g碳水',
      ),
      DietRule(
        dayType: 'chest',
        totalCarb: 240.0,
        totalProtein: 120.0,
        totalFat: 56.0,
        mealCount: 3,
        specialNotes: '练胸日，22:30练后餐需摄入80g碳水',
      ),
      DietRule(
        dayType: 'leg',
        totalCarb: 280.0,
        totalProtein: 120.0,
        totalFat: 56.0,
        mealCount: 4,
        specialNotes: '练腿日，21:00练前餐24g碳水，22:30练后餐96g碳水',
      ),
      DietRule(
        dayType: 'shoulder',
        totalCarb: 200.0,
        totalProtein: 120.0,
        totalFat: 56.0,
        mealCount: 3,
        specialNotes: '练肩日，22:30练后餐需摄入40g碳水',
      ),
    ];

    for (final rule in rules) {
      await dietRulesBoxInstance.put(rule.dayType, rule);
    }
  }

  Future<void> _seedMealTemplates() async {
    final templates = [
      // 休息日
      MealTemplate(dayType: 'rest', mealOrder: 1, mealTime: '11:00', carb: 80.0, protein: 60.0, fat: 28.0),
      MealTemplate(dayType: 'rest', mealOrder: 2, mealTime: '17:00', carb: 80.0, protein: 60.0, fat: 28.0),

      // 练背日
      MealTemplate(dayType: 'back', mealOrder: 1, mealTime: '11:00', carb: 80.0, protein: 40.0, fat: 20.0),
      MealTemplate(dayType: 'back', mealOrder: 2, mealTime: '17:00', carb: 80.0, protein: 40.0, fat: 20.0),
      MealTemplate(dayType: 'back', mealOrder: 3, mealTime: '22:30', carb: 80.0, protein: 40.0, fat: 16.0, isPostWorkout: true),

      // 练胸日
      MealTemplate(dayType: 'chest', mealOrder: 1, mealTime: '11:00', carb: 80.0, protein: 40.0, fat: 20.0),
      MealTemplate(dayType: 'chest', mealOrder: 2, mealTime: '17:00', carb: 80.0, protein: 40.0, fat: 20.0),
      MealTemplate(dayType: 'chest', mealOrder: 3, mealTime: '22:30', carb: 80.0, protein: 40.0, fat: 16.0, isPostWorkout: true),

      // 练腿日
      MealTemplate(dayType: 'leg', mealOrder: 1, mealTime: '11:00', carb: 80.0, protein: 40.0, fat: 20.0),
      MealTemplate(dayType: 'leg', mealOrder: 2, mealTime: '17:00', carb: 80.0, protein: 40.0, fat: 20.0),
      MealTemplate(dayType: 'leg', mealOrder: 3, mealTime: '21:00', carb: 24.0, protein: 0.0, fat: 0.0, isPreWorkout: true),
      MealTemplate(dayType: 'leg', mealOrder: 4, mealTime: '22:30', carb: 96.0, protein: 40.0, fat: 16.0, isPostWorkout: true),

      // 练肩日
      MealTemplate(dayType: 'shoulder', mealOrder: 1, mealTime: '11:00', carb: 80.0, protein: 40.0, fat: 20.0),
      MealTemplate(dayType: 'shoulder', mealOrder: 2, mealTime: '17:00', carb: 80.0, protein: 40.0, fat: 20.0),
      MealTemplate(dayType: 'shoulder', mealOrder: 3, mealTime: '22:30', carb: 40.0, protein: 40.0, fat: 16.0, isPostWorkout: true),
    ];

    for (final template in templates) {
      final key = '${template.dayType}_${template.mealOrder}';
      await mealTemplatesBoxInstance.put(key, template);
    }
  }

  Future<void> _seedCommonIngredients() async {
    // 常用食材预设
    final ingredients = [
      // 碳水类
      Ingredient(id: 'ing_1', name: '熟米饭', category: 'carb', carbPer100g: 26.0, proteinPer100g: 2.6, fatPer100g: 0.3, isCooked: true, isCommon: true, unit: 'g'),
      Ingredient(id: 'ing_2', name: '燕麦片', category: 'carb', carbPer100g: 60.0, proteinPer100g: 12.0, fatPer100g: 6.0, isCooked: false, isCommon: true, unit: 'g'),
      Ingredient(id: 'ing_3', name: '红薯', category: 'carb', carbPer100g: 20.0, proteinPer100g: 1.0, fatPer100g: 0.1, isCooked: false, isCommon: true, unit: 'g'),
      Ingredient(id: 'ing_4', name: '香蕉', category: 'carb', carbPer100g: 23.0, proteinPer100g: 1.1, fatPer100g: 0.2, isCooked: false, isCommon: true, unit: 'g'),
      Ingredient(id: 'ing_5', name: '全麦面包', category: 'carb', carbPer100g: 45.0, proteinPer100g: 8.0, fatPer100g: 3.0, isCooked: false, isCommon: true, unit: '片'),

      // 蛋白质类
      Ingredient(id: 'ing_6', name: '鸡胸肉', category: 'protein', carbPer100g: 0.0, proteinPer100g: 31.0, fatPer100g: 3.6, isCooked: false, isCommon: true, unit: 'g'),
      Ingredient(id: 'ing_7', name: '鸡蛋', category: 'protein', carbPer100g: 1.1, proteinPer100g: 13.0, fatPer100g: 11.0, isCooked: false, isCommon: true, unit: '个'),
      Ingredient(id: 'ing_8', name: '蛋白粉', category: 'protein', carbPer100g: 5.0, proteinPer100g: 80.0, fatPer100g: 3.0, isCooked: false, isCommon: true, unit: '勺'),
      Ingredient(id: 'ing_9', name: '牛肉', category: 'protein', carbPer100g: 0.0, proteinPer100g: 26.0, fatPer100g: 15.0, isCooked: false, isCommon: true, unit: 'g'),
      Ingredient(id: 'ing_10', name: '鱼', category: 'protein', carbPer100g: 0.0, proteinPer100g: 20.0, fatPer100g: 5.0, isCooked: false, isCommon: true, unit: 'g'),

      // 脂肪类
      Ingredient(id: 'ing_11', name: '橄榄油', category: 'fat', carbPer100g: 0.0, proteinPer100g: 0.0, fatPer100g: 100.0, isCooked: false, isCommon: true, unit: 'ml'),
      Ingredient(id: 'ing_12', name: '坚果', category: 'fat', carbPer100g: 20.0, proteinPer100g: 15.0, fatPer100g: 50.0, isCooked: false, isCommon: true, unit: 'g'),
      Ingredient(id: 'ing_13', name: '花生酱', category: 'fat', carbPer100g: 20.0, proteinPer100g: 25.0, fatPer100g: 50.0, isCooked: false, isCommon: true, unit: 'g'),
    ];

    for (final ingredient in ingredients) {
      await ingredientsBoxInstance.put(ingredient.id, ingredient);
    }
  }

  Future<void> close() async {
    await Hive.close();
  }
}
