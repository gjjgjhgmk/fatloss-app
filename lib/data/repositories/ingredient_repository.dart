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
      await _syncIngredientToCloud(ingredient);
    } catch (e) {
      await _hiveHelper.ingredientsBoxInstance.delete(ingredient.id);
      rethrow;
    }
  }

  Future<void> updateIngredient(Ingredient ingredient) async {
    final oldIngredient = _hiveHelper.ingredientsBoxInstance.get(ingredient.id);
    final updated = ingredient.copyWith(updatedAt: DateTime.now());

    await _hiveHelper.ingredientsBoxInstance.put(updated.id, updated);
    try {
      await _syncIngredientToCloud(updated);
    } catch (e) {
      if (oldIngredient != null) {
        await _hiveHelper.ingredientsBoxInstance
            .put(oldIngredient.id, oldIngredient);
      } else {
        await _hiveHelper.ingredientsBoxInstance.delete(updated.id);
      }
      rethrow;
    }
  }

  Future<void> _syncIngredientToCloud(Ingredient ingredient,
      {int retryCount = 3}) async {
    Object? lastError;

    for (int i = 0; i < retryCount; i++) {
      try {
        final payload = ingredient.toMap(includeRemainingAmount: false);
        await _upsertIngredientWithSchemaFallback(payload);
        print('[Sync] 食材 ${ingredient.name} 同步成功');
        return;
      } catch (e) {
        lastError = e;
        print(
            '[Sync] 食材 ${ingredient.name} 同步失败 (尝试 ${i + 1}/$retryCount): $e');
        if (i < retryCount - 1) {
          await Future.delayed(Duration(seconds: i + 1));
        }
      }
    }

    throw Exception('食材同步失败: ${ingredient.name}, error: $lastError');
  }

  Future<void> _upsertIngredientWithSchemaFallback(
      Map<String, dynamic> payload) async {
    try {
      await SupabaseConfig.client.from('ingredients').upsert(payload);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (!msg.contains('updated_at')) {
        rethrow;
      }

      // 兼容旧表结构：如果后端没有 updated_at 字段，自动降级再写一次。
      final fallbackPayload = Map<String, dynamic>.from(payload)
        ..remove('updated_at');
      await SupabaseConfig.client.from('ingredients').upsert(fallbackPayload);
    }
  }

  Future<void> deleteIngredient(String id) async {
    final ingredient = _hiveHelper.ingredientsBoxInstance.get(id);
    if (ingredient == null) return;

    await _hiveHelper.ingredientsBoxInstance.delete(id);
    try {
      await SupabaseConfig.client.from('ingredients').delete().eq('id', id);
    } catch (e) {
      await _hiveHelper.ingredientsBoxInstance.put(ingredient.id, ingredient);
      throw Exception('删除食材失败: $e');
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
        .where(
            (i) => i.remainingAmount != null && i.remainingAmount! < threshold)
        .toList()
      ..sort(
          (a, b) => (a.remainingAmount ?? 0).compareTo(b.remainingAmount ?? 0));
  }
}
