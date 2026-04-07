import '../../core/database/hive_helper.dart';
import '../models/diet_rule.dart';

class DietRuleRepository {
  final HiveHelper _hiveHelper = HiveHelper.instance;

  List<DietRule> getAllRules() {
    return _hiveHelper.dietRulesBoxInstance.values.toList();
  }

  DietRule? getRuleByDayType(String dayType) {
    return _hiveHelper.dietRulesBoxInstance.get(dayType);
  }

  Future<void> insertRule(DietRule rule) async {
    await _hiveHelper.dietRulesBoxInstance.put(rule.dayType, rule);
  }

  Future<void> updateRule(DietRule rule) async {
    await _hiveHelper.dietRulesBoxInstance.put(rule.dayType, rule);
  }

  Future<void> deleteRule(String dayType) async {
    await _hiveHelper.dietRulesBoxInstance.delete(dayType);
  }
}
