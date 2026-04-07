import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/nutrition_calculator.dart';
import '../../data/models/daily_meal_record.dart';
import '../../data/models/ingredient.dart';
import '../../data/models/meal_item_record.dart';
import '../../data/repositories/ingredient_repository.dart';
import '../../domain/usecases/daily_diet_manager.dart';

class DietProvider extends ChangeNotifier {
  final DailyDietManager _dietManager = DailyDietManager();
  final IngredientRepository _ingredientRepo = IngredientRepository();
  final _uuid = const Uuid();

  DailyDietStatus? _dailyStatus;
  List<Ingredient> _ingredients = [];
  List<Ingredient> _filteredIngredients = [];
  bool _isLoading = false;
  String? _error;

  // 当前选中的日期
  DateTime _selectedDate = DateTime.now();

  // getters
  DailyDietStatus? get dailyStatus => _dailyStatus;
  List<Ingredient> get ingredients => _ingredients;
  List<Ingredient> get filteredIngredients => _filteredIngredients;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;

  /// 初始化
  Future<void> initialize() async {
    await loadIngredients();
    await loadDailyStatus();
  }

  /// 加载食材库
  Future<void> loadIngredients() async {
    try {
      _ingredients = _ingredientRepo.getAllIngredients();
      _filteredIngredients = _ingredients;
      notifyListeners();
    } catch (e) {
      _error = '加载食材库失败: $e';
      notifyListeners();
    }
  }

  /// 加载当日饮食状态
  Future<void> loadDailyStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dailyStatus = await _dietManager.getDailyDietStatus(_selectedDate);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '加载饮食状态失败: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 选择日期
  Future<void> selectDate(DateTime date) async {
    _selectedDate = date;
    await loadDailyStatus();
  }

  /// 搜索食材
  void searchIngredients(String keyword) {
    if (keyword.isEmpty) {
      _filteredIngredients = _ingredients;
    } else {
      _filteredIngredients = _ingredientRepo.searchIngredients(keyword);
    }
    notifyListeners();
  }

  /// 按类别筛选食材
  void filterByCategory(String category) {
    if (category.isEmpty || category == 'all') {
      _filteredIngredients = _ingredients;
    } else {
      _filteredIngredients = _ingredientRepo.getIngredientsByCategory(category);
    }
    notifyListeners();
  }

  /// 记录某餐
  Future<void> recordMeal({
    required int mealOrder,
    required List<MealItemRecord> items,
  }) async {
    final dateStr = _formatDate(_selectedDate);
    try {
      await _dietManager.recordMeal(
        date: dateStr,
        mealOrder: mealOrder,
        items: items,
      );
      await loadDailyStatus();
    } catch (e) {
      _error = '记录失败: $e';
      notifyListeners();
    }
  }

  /// 跳过某餐
  Future<void> skipMeal(int mealOrder) async {
    final dateStr = _formatDate(_selectedDate);
    try {
      await _dietManager.skipMeal(dateStr, mealOrder);
      await loadDailyStatus();
    } catch (e) {
      _error = '操作失败: $e';
      notifyListeners();
    }
  }

  /// 获取指定餐次的记录
  DailyMealRecord? getMealRecord(int mealOrder) {
    if (_dailyStatus == null) return null;
    try {
      return _dailyStatus!.meals.firstWhere((m) => m.mealOrder == mealOrder);
    } catch (e) {
      return null;
    }
  }

  /// 计算食材营养素
  NutritionData calculateIngredientNutrition(Ingredient ingredient, double amount) {
    return NutritionCalculator.calculateNutrition(
      carbPer100g: ingredient.carbPer100g,
      proteinPer100g: ingredient.proteinPer100g,
      fatPer100g: ingredient.fatPer100g,
      amountInGrams: amount,
    );
  }

  /// 添加食材到食材库
  Future<void> addIngredient(Ingredient ingredient) async {
    try {
      final id = _uuid.v4();
      await _ingredientRepo.insertIngredient(ingredient.copyWith(id: id));
      await loadIngredients();
    } catch (e) {
      _error = '添加食材失败: $e';
      notifyListeners();
    }
  }

  /// 更新食材
  Future<void> updateIngredient(Ingredient ingredient) async {
    try {
      await _ingredientRepo.updateIngredient(ingredient);
      await loadIngredients();
    } catch (e) {
      _error = '更新食材失败: $e';
      notifyListeners();
    }
  }

  /// 删除食材
  Future<void> deleteIngredient(String id) async {
    try {
      await _ingredientRepo.deleteIngredient(id);
      await loadIngredients();
    } catch (e) {
      _error = '删除食材失败: $e';
      notifyListeners();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
