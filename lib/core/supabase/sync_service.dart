import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/hive_helper.dart';
import '../../data/models/daily_meal_record.dart';
import '../../data/models/meal_item_record.dart';
import '../../data/models/waist_record.dart';
import '../../data/models/weight_record.dart';
import '../../data/models/workout_record.dart';
import '../../data/repositories/daily_record_repository.dart';
import '../../data/repositories/weight_record_repository.dart';
import '../../data/repositories/waist_record_repository.dart';
import '../../data/repositories/workout_record_repository.dart';
import '../../data/repositories/ingredient_repository.dart';
import '../utils/date_type_resolver.dart';
import 'supabase_config.dart';

class SyncService {
  static const String _lastSyncKey = 'last_sync_time';

  final DailyRecordRepository _dailyRecordRepo = DailyRecordRepository();
  final WeightRecordRepository _weightRecordRepo = WeightRecordRepository();
  final WaistRecordRepository _waistRecordRepo = WaistRecordRepository();
  final WorkoutRecordRepository _workoutRecordRepo = WorkoutRecordRepository();
  final IngredientRepository _ingredientRepo = IngredientRepository();

  /// 启动时从云端拉取当天关键数据并覆盖本地（云端优先）
  Future<void> pullCloudDataToLocal({DateTime? targetDate}) async {
    try {
      final today = _formatDate(targetDate ?? DateTime.now());
      print('☁️ 开始从云端拉取数据...');

      await _pullTodayMealRecords(today);
      await _pullTodayWorkoutRecords(today);
      await _pullTodayWeightRecords(today);
      await _pullTodayWaistRecords(today);

      print('☁️ 云端数据拉取完成');
    } catch (e) {
      print('⚠️ 云端拉取失败: $e');
      // 静默处理，不阻塞启动
    }
  }

  /// 兼容旧方法名
  Future<void> pullTodayDataFromCloud() async {
    await pullCloudDataToLocal();
  }

  /// 从云端拉取今日数据到本地（使用 last-write-wins 策略）
  /// 比较本地和云端记录的 updatedAt，保留最新版本
  Future<void> _pullTodayMealRecords(String today) async {
    final mealRows = await SupabaseConfig.client
        .from('daily_meal_records')
        .select()
        .eq('record_date', today);

    final dailyBox = HiveHelper.instance.dailyMealRecordsBoxInstance;
    final mealItemBox = HiveHelper.instance.mealItemRecordsBoxInstance;

    // 云端今日无数据，直接返回（保留本地数据）
    if (mealRows.isEmpty) {
      print('[Sync] 云端无今日餐次记录，保留本地数据');
      return;
    }

    // 构建云端记录映射
    final cloudMealsMap = <String, DailyMealRecord>{};
    for (final row in mealRows) {
      final meal = DailyMealRecord.fromMap(Map<String, dynamic>.from(row));
      cloudMealsMap[meal.id] = meal;
    }

    // 获取本地今日记录
    final localMeals = dailyBox.values.where((r) => r.recordDate == today).toList();

    // 合并策略：比较 updatedAt，保留最新
    for (final localMeal in localMeals) {
      final cloudMeal = cloudMealsMap[localMeal.id];
      if (cloudMeal == null) {
        // 云端没有这条记录，保留本地
        continue;
      }

      // 比较 updatedAt：谁更新保留谁
      final localUpdated = localMeal.updatedAt;
      final cloudUpdated = cloudMeal.updatedAt;
      final timeDiff = cloudUpdated.difference(localUpdated).inSeconds.abs();

      if (timeDiff < 2) {
        // 时间差小于2秒，优先保留本地（用户正在操作的数据）
        print('[Sync] 餐次 ${localMeal.id} 时间差${timeDiff}s，保留本地');
        cloudMealsMap.remove(localMeal.id);
      } else if (cloudUpdated.isAfter(localUpdated)) {
        // 云端更新，保留云端（删除本地旧记录）
        print('[Sync] 餐次 ${localMeal.id} 云端更新，采纳云端数据');
        await dailyBox.delete(localMeal.id);
      } else {
        // 本地更新，保留本地（删除云端旧数据标记，由后续 syncAllRecentData 同步）
        print('[Sync] 餐次 ${localMeal.id} 本地更新，保留本地');
        cloudMealsMap.remove(localMeal.id);
      }
    }

    // 写入剩余的云端记录（没有对应本地更新的）
    for (final meal in cloudMealsMap.values) {
      await dailyBox.put(meal.id, meal);
      print('[Sync] 从云端写入餐次 ${meal.id}');
    }

    // 处理餐次明细：类似策略
    if (cloudMealsMap.isNotEmpty) {
      final mealIds = cloudMealsMap.keys.toList();
      final mealItemRows = await SupabaseConfig.client
          .from('meal_item_records')
          .select()
          .inFilter('daily_meal_record_id', mealIds);

      final cloudItemsMap = <String, MealItemRecord>{};
      for (final row in mealItemRows) {
        final item = MealItemRecord.fromMap(Map<String, dynamic>.from(row));
        cloudItemsMap[item.id] = item;
      }

      // 获取本地属于这些 meal 的 items
      final localItems = mealItemBox.values
          .where((i) => mealIds.contains(i.dailyMealRecordId))
          .toList();

      for (final localItem in localItems) {
        final cloudItem = cloudItemsMap[localItem.id];
        if (cloudItem == null) {
          // 云端没有，保留本地
          continue;
        }

        final localUpdated = localItem.createdAt; // MealItemRecord 用 createdAt
        final cloudUpdated = cloudItem.createdAt;
        final timeDiff = cloudUpdated.difference(localUpdated).inSeconds.abs();

        if (timeDiff < 2) {
          cloudItemsMap.remove(localItem.id);
        } else if (cloudUpdated.isAfter(localUpdated)) {
          await mealItemBox.delete(localItem.id);
        } else {
          cloudItemsMap.remove(localItem.id);
        }
      }

      for (final item in cloudItemsMap.values) {
        await mealItemBox.put(item.id, item);
      }
    }
  }

  /// 从云端拉取训练记录（last-write-wins）
  Future<void> _pullTodayWorkoutRecords(String today) async {
    final workoutRows = await SupabaseConfig.client
        .from('workout_records')
        .select()
        .eq('record_date', today);

    final workoutBox = HiveHelper.instance.workoutRecordsBoxInstance;

    if (workoutRows.isEmpty) {
      print('[Sync] 云端无今日训练记录，保留本地数据');
      return;
    }

    final cloudRecordsMap = <String, WorkoutRecord>{};
    for (final row in workoutRows) {
      final record = WorkoutRecord.fromMap(Map<String, dynamic>.from(row));
      cloudRecordsMap[record.id] = record;
    }

    final localRecords = workoutBox.values.where((r) => r.recordDate == today).toList();

    for (final local in localRecords) {
      final cloud = cloudRecordsMap[local.id];
      if (cloud == null) continue;

      final localUpdated = local.updatedAt;
      final cloudUpdated = cloud.updatedAt;

      if (cloudUpdated.isAfter(localUpdated)) {
        await workoutBox.delete(local.id);
      } else {
        cloudRecordsMap.remove(local.id);
      }
    }

    for (final record in cloudRecordsMap.values) {
      await workoutBox.put(record.id, record);
      print('[Sync] 从云端写入训练记录 ${record.id}');
    }
  }

  /// 从云端拉取体重记录（last-write-wins）
  Future<void> _pullTodayWeightRecords(String today) async {
    final weightRows = await SupabaseConfig.client
        .from('weight_records')
        .select()
        .eq('record_date', today);

    final weightBox = HiveHelper.instance.weightRecordsBoxInstance;

    if (weightRows.isEmpty) {
      print('[Sync] 云端无今日体重记录，保留本地数据');
      return;
    }

    final cloudRecordsMap = <String, WeightRecord>{};
    for (final row in weightRows) {
      final record = WeightRecord.fromMap(Map<String, dynamic>.from(row));
      cloudRecordsMap[record.id] = record;
    }

    final localRecords = weightBox.values.where((r) => r.recordDate == today).toList();

    for (final local in localRecords) {
      final cloud = cloudRecordsMap[local.id];
      if (cloud == null) continue;

      final localUpdated = local.updatedAt;
      final cloudUpdated = cloud.updatedAt;

      if (cloudUpdated.isAfter(localUpdated)) {
        await weightBox.delete(local.id);
      } else {
        cloudRecordsMap.remove(local.id);
      }
    }

    for (final record in cloudRecordsMap.values) {
      await weightBox.put(record.id, record);
      print('[Sync] 从云端写入体重记录 ${record.id}');
    }
  }

  /// 从云端拉取腰围记录（last-write-wins）
  Future<void> _pullTodayWaistRecords(String today) async {
    final waistRows = await SupabaseConfig.client
        .from('waist_records')
        .select()
        .eq('record_date', today);

    final waistBox = HiveHelper.instance.waistRecordsBoxInstance;

    if (waistRows.isEmpty) {
      print('[Sync] 云端无今日腰围记录，保留本地数据');
      return;
    }

    final cloudRecordsMap = <String, WaistRecord>{};
    for (final row in waistRows) {
      final record = WaistRecord.fromMap(Map<String, dynamic>.from(row));
      cloudRecordsMap[record.id] = record;
    }

    final localRecords = waistBox.values.where((r) => r.recordDate == today).toList();

    for (final local in localRecords) {
      final cloud = cloudRecordsMap[local.id];
      if (cloud == null) continue;

      final localUpdated = local.updatedAt;
      final cloudUpdated = cloud.updatedAt;

      if (cloudUpdated.isAfter(localUpdated)) {
        await waistBox.delete(local.id);
      } else {
        cloudRecordsMap.remove(local.id);
      }
    }

    for (final record in cloudRecordsMap.values) {
      await waistBox.put(record.id, record);
      print('[Sync] 从云端写入腰围记录 ${record.id}');
    }
  }

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
      final dayType = DateTypeResolver.resolveDayType(DateTime.now());
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
          allIngredients
              .map((i) => i.toMap(includeRemainingAmount: false))
              .toList(),
        );
        print('🥗 已同步全部 ${allIngredients.length} 条食材');
        return;
      }

      // 解析上次同步时间
      final lastSync = DateTime.tryParse(lastSyncTime);
      if (lastSync == null) {
        await SupabaseConfig.client.from('ingredients').upsert(
          allIngredients
              .map((i) => i.toMap(includeRemainingAmount: false))
              .toList(),
        );
        print('🥗 已同步全部 ${allIngredients.length} 条食材');
        return;
      }

      // 只同步修改时间晚于上次同步的食材
      final modifiedIngredients = allIngredients.where((i) {
        return i.updatedAt.isAfter(lastSync);
      }).toList();

      if (modifiedIngredients.isEmpty) {
        print('🥗 食材库无变更，跳过');
        return;
      }

      await SupabaseConfig.client.from('ingredients').upsert(
        modifiedIngredients
            .map((i) => i.toMap(includeRemainingAmount: false))
            .toList(),
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
}
