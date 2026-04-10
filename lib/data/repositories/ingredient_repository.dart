import '../../core/database/hive_helper.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/ingredient.dart';

class IngredientRepository {
  final HiveHelper _hiveHelper = HiveHelper.instance;

  List<Ingredient> getAllIngredients() {
    return _hiveHelper.ingredientsBoxInstance.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<Ingredient> getIngredientsByCategory(String category) {
    return _hiveHelper.ingredientsBoxInstance.values
        .where((i) => i.category == category)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<Ingredient> getCommonIngredients() {
    return _hiveHelper.ingredientsBoxInstance.values
        .where((i) => i.isCommon)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Ingredient? getIngredientById(String id) {
    return _hiveHelper.ingredientsBoxInstance.get(id);
  }

  Future<void> insertIngredient(Ingredient ingredient) async {
    await _hiveHelper.ingredientsBoxInstance.put(ingredient.id, ingredient);
    try {
      await SupabaseConfig.client.from('ingredients').upsert(
            ingredient.toMap(includeRemainingAmount: false),
          );
    } catch (_) {}
  }

  Future<void> updateIngredient(Ingredient ingredient) async {
    await _hiveHelper.ingredientsBoxInstance.put(ingredient.id, ingredient);
    try {
      await SupabaseConfig.client.from('ingredients').upsert(
            ingredient.toMap(includeRemainingAmount: false),
          );
    } catch (_) {}
  }

  Future<void> deleteIngredient(String id) async {
    await _hiveHelper.ingredientsBoxInstance.delete(id);
    try {
      await SupabaseConfig.client.from('ingredients').delete().eq('id', id);
    } catch (_) {}
  }

  List<Ingredient> searchIngredients(String keyword) {
    return _hiveHelper.ingredientsBoxInstance.values
        .where((i) => i.name.contains(keyword))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<Ingredient> getLowStockIngredients({double threshold = 100}) {
    return _hiveHelper.ingredientsBoxInstance.values
        .where((i) => i.remainingAmount != null && i.remainingAmount! < threshold)
        .toList()
      ..sort((a, b) => (a.remainingAmount ?? 0).compareTo(b.remainingAmount ?? 0));
  }
}
