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
    await _syncIngredientToCloud(ingredient);
  }

  Future<void> updateIngredient(Ingredient ingredient) async {
    // 更新本地，确保 updatedAt 改变
    final updated = ingredient.copyWith(updatedAt: DateTime.now());
    await _hiveHelper.ingredientsBoxInstance.put(updated.id, updated);
    await _syncIngredientToCloud(updated);
  }

  Future<void> _syncIngredientToCloud(Ingredient ingredient, {int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        await SupabaseConfig.client.from('ingredients').upsert(
          ingredient.toMap(includeRemainingAmount: false),
        );
        print('[Sync] 食材 ${ingredient.name} 同步成功');
        return;
      } catch (e) {
        print('[Sync] 食材 ${ingredient.name} 同步失败 (尝试 ${i + 1}/$retryCount): $e');
        if (i < retryCount - 1) {
          // 指数退避: 1s, 2s, 4s
          await Future.delayed(Duration(seconds: 1 * (i + 1)));
        }
      }
    }
    // 所有重试都失败，记录错误（不再静默忽略）
    print('[Sync] 食材 ${ingredient.id} 同步失败，已放弃');
  }

  Future<void> deleteIngredient(String id) async {
    final ingredient = _hiveHelper.ingredientsBoxInstance.get(id);
    await _hiveHelper.ingredientsBoxInstance.delete(id);
    if (ingredient != null) {
      try {
        await SupabaseConfig.client.from('ingredients').delete().eq('id', id);
      } catch (e) {
        print('[Sync] 删除食材 ${ingredient.name} 失败: $e');
      }
    }
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
