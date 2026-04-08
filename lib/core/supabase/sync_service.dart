import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/daily_record_repository.dart';
import '../../data/repositories/weight_record_repository.dart';
import '../../data/repositories/waist_record_repository.dart';
import '../../data/repositories/workout_record_repository.dart';
import '../../data/repositories/ingredient_repository.dart';
import 'supabase_config.dart';

class SyncService {
  static const String _lastSyncKey = 'last_sync_time';

  final DailyRecordRepository _dailyRecordRepo = DailyRecordRepository();
  final WeightRecordRepository _weightRecordRepo = WeightRecordRepository();
  final WaistRecordRepository _waistRecordRepo = WaistRecordRepository();
  final WorkoutRecordRepository _workoutRecordRepo = WorkoutRecordRepository();
  final IngredientRepository _ingredientRepo = IngredientRepository();

  /// 冷启动静默同步 - Fire and Forget
  Future<void> syncAllRecentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTime = prefs.getString(_lastSyncKey);

      print('🔄 开始冷启动同步...');

      // 1. 同步今天的每日餐次记录
      await _syncTodayMealRecords();

      // 2. 同步今天的体重记录
      await _syncTodayWeightRecords();

      // 3. 同步今天的腰围记录
      await _syncTodayWaistRecords();

      // 4. 同步今天的训练记录
      await _syncTodayWorkoutRecords();

      // 5. 同步食材库（只同步有变更的）
      await _syncModifiedIngredients(lastSyncTime);

      // 6. 同步饮食规则（仅在云端为空时）
      await _syncDietRulesIfEmpty();

      // 更新同步时间戳
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      print('✅ 冷启动同步完成');
    } catch (e) {
      print('⚠️ 同步失败: $e');
      // 静默处理，不抛出异常
    }
  }

  /// 同步今天的每日餐次记录
  Future<void> _syncTodayMealRecords() async {
    try {
      final today = _formatDate(DateTime.now());
      final records = _dailyRecordRepo.getDailyRecords(today);

      if (records.isEmpty) {
        print('📋 今日餐次记录为空，跳过');
        return;
      }

      await SupabaseConfig.client.from('daily_meal_records').upsert(
        records.map((r) => r.toMap()).toList(),
      );
      print('📋 已同步 ${records.length} 条餐次记录');
    } catch (e) {
      print('⚠️ 餐次记录同步失败: $e');
    }
  }

  /// 同步今天的体重记录
  Future<void> _syncTodayWeightRecords() async {
    try {
      final today = _formatDate(DateTime.now());
      final records = _weightRecordRepo.getWeightRecordsForDate(today);

      if (records.isEmpty) {
        print('⚖️ 今日体重记录为空，跳过');
        return;
      }

      await SupabaseConfig.client.from('weight_records').upsert(
        records.map((r) => r.toMap()).toList(),
      );
      print('⚖️ 已同步 ${records.length} 条体重记录');
    } catch (e) {
      print('⚠️ 体重记录同步失败: $e');
    }
  }

  /// 同步今天的腰围记录
  Future<void> _syncTodayWaistRecords() async {
    try {
      final today = _formatDate(DateTime.now());
      final record = _waistRecordRepo.getWaistRecordForDate(today);

      if (record == null) {
        print('📏 今日腰围记录为空，跳过');
        return;
      }

      await SupabaseConfig.client.from('waist_records').upsert(
        record.toMap(),
      );
      print('📏 已同步 1 条腰围记录');
    } catch (e) {
      print('⚠️ 腰围记录同步失败: $e');
    }
  }

  /// 同步今天的训练记录
  Future<void> _syncTodayWorkoutRecords() async {
    try {
      final today = _formatDate(DateTime.now());
      final dayType = _getDayType(today);
      final record = _workoutRecordRepo.getWorkoutRecord(today, dayType);

      if (record == null) {
        print('💪 今日训练记录为空，跳过');
        return;
      }

      await SupabaseConfig.client.from('workout_records').upsert(
        record.toMap(),
      );
      print('💪 已同步 1 条训练记录');
    } catch (e) {
      print('⚠️ 训练记录同步失败: $e');
    }
  }

  /// 同步有变更的食材库
  Future<void> _syncModifiedIngredients(String? lastSyncTime) async {
    try {
      final allIngredients = _ingredientRepo.getAllIngredients();

      if (allIngredients.isEmpty) {
        print('🥗 食材库为空，跳过');
        return;
      }

      // 如果没有上次同步时间，则同步全部
      if (lastSyncTime == null) {
        await SupabaseConfig.client.from('ingredients').upsert(
          allIngredients.map((i) => i.toMap()).toList(),
        );
        print('🥗 已同步全部 ${allIngredients.length} 条食材');
        return;
      }

      // 解析上次同步时间
      final lastSync = DateTime.tryParse(lastSyncTime);
      if (lastSync == null) {
        await SupabaseConfig.client.from('ingredients').upsert(
          allIngredients.map((i) => i.toMap()).toList(),
        );
        print('🥗 已同步全部 ${allIngredients.length} 条食材');
        return;
      }

      // 只同步修改时间晚于上次同步的食材
      final modifiedIngredients = allIngredients.where((i) {
        return i.updatedAt != null && i.updatedAt!.isAfter(lastSync);
      }).toList();

      if (modifiedIngredients.isEmpty) {
        print('🥗 食材库无变更，跳过');
        return;
      }

      await SupabaseConfig.client.from('ingredients').upsert(
        modifiedIngredients.map((i) => i.toMap()).toList(),
      );
      print('🥗 已同步 ${modifiedIngredients.length} 条变更食材');
    } catch (e) {
      print('⚠️ 食材库同步失败: $e');
    }
  }

  /// 同步饮食规则（仅在云端为空时）
  Future<void> _syncDietRulesIfEmpty() async {
    try {
      final response = await SupabaseConfig.client
          .from('diet_rules')
          .select()
          .limit(1);

      if (response.isNotEmpty) {
        print('📖 饮食规则已存在，跳过');
        return;
      }

      // 从 Hive 读取饮食规则
      final rules = _loadDietRulesFromHive();
      if (rules.isEmpty) {
        print('📖 饮食规则为空，跳过');
        return;
      }

      await SupabaseConfig.client.from('diet_rules').upsert(rules);
      print('📖 已同步 ${rules.length} 条饮食规则');
    } catch (e) {
      print('⚠️ 饮食规则同步失败: $e');
    }
  }

  List<Map<String, dynamic>> _loadDietRulesFromHive() {
    // 硬编码饮食规则（与 Hive 初始化数据一致）
    return [
      {
        'day_type': 'rest',
        'total_carb': 160.0,
        'total_protein': 120.0,
        'total_fat': 56.0,
        'meal_count': 2,
        'special_notes': '休息日，饮食分2餐（11:00、17:00），无练前练后餐',
      },
      {
        'day_type': 'back',
        'total_carb': 240.0,
        'total_protein': 120.0,
        'total_fat': 56.0,
        'meal_count': 3,
        'special_notes': '练背日，22:30练后餐需摄入80g碳水',
      },
      {
        'day_type': 'chest',
        'total_carb': 240.0,
        'total_protein': 120.0,
        'total_fat': 56.0,
        'meal_count': 3,
        'special_notes': '练胸日，22:30练后餐需摄入80g碳水',
      },
      {
        'day_type': 'leg',
        'total_carb': 280.0,
        'total_protein': 120.0,
        'total_fat': 56.0,
        'meal_count': 4,
        'special_notes': '练腿日，21:00练前餐24g碳水，22:30练后餐96g碳水',
      },
      {
        'day_type': 'shoulder',
        'total_carb': 200.0,
        'total_protein': 120.0,
        'total_fat': 56.0,
        'meal_count': 3,
        'special_notes': '练肩日，22:30练后餐需摄入40g碳水',
      },
    ];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getDayType(String dateStr) {
    // 根据日期判断训练日类型（与 DateTypeResolver 一致）
    final date = DateTime.parse(dateStr);
    final weekday = date.weekday;
    // 周一=1, 周日=7
    final types = ['back', 'chest', 'leg', 'back', 'chest', 'shoulder', 'rest'];
    return types[weekday - 1];
  }
}
