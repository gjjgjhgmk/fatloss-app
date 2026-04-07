import '../../core/database/hive_helper.dart';
import '../models/meal_template.dart';

class MealTemplateRepository {
  final HiveHelper _hiveHelper = HiveHelper.instance;

  List<MealTemplate> getTemplatesByDayType(String dayType) {
    final box = _hiveHelper.mealTemplatesBoxInstance;
    return box.values
        .where((t) => t.dayType == dayType)
        .toList()
      ..sort((a, b) => a.mealOrder.compareTo(b.mealOrder));
  }

  MealTemplate? getTemplate(String dayType, int mealOrder) {
    final key = '${dayType}_$mealOrder';
    return _hiveHelper.mealTemplatesBoxInstance.get(key);
  }

  Future<void> insertTemplate(MealTemplate template) async {
    final key = '${template.dayType}_${template.mealOrder}';
    await _hiveHelper.mealTemplatesBoxInstance.put(key, template);
  }

  Future<void> updateTemplate(MealTemplate template) async {
    final key = '${template.dayType}_${template.mealOrder}';
    await _hiveHelper.mealTemplatesBoxInstance.put(key, template);
  }

  Future<void> deleteTemplate(String dayType, int mealOrder) async {
    final key = '${dayType}_$mealOrder';
    await _hiveHelper.mealTemplatesBoxInstance.delete(key);
  }
}
