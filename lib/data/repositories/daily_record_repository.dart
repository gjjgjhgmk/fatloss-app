import 'package:uuid/uuid.dart';
import '../../core/database/hive_helper.dart';
import '../../core/firebase/firestore_service.dart';
import '../../core/utils/date_type_resolver.dart';
import '../models/daily_meal_record.dart';
import '../models/meal_item_record.dart';

class DailyRecordRepository {
  final HiveHelper _hiveHelper = HiveHelper.instance;
  final _uuid = const Uuid();
  final FirestoreService _firestore = FirestoreService();

  /// 获取某日所有餐次记录
  List<DailyMealRecord> getDailyRecords(String date) {
    final box = _hiveHelper.dailyMealRecordsBoxInstance;
    final records = box.values
        .where((r) => r.recordDate == date)
        .toList();
    records.sort((a, b) => a.mealOrder.compareTo(b.mealOrder));
    return records;
  }

  /// 获取某餐次记录详情（含食材列表）
  DailyMealRecord? getMealRecord(String date, int mealOrder) {
    final key = '${date}_$mealOrder';
    final record = _hiveHelper.dailyMealRecordsBoxInstance.get(key);
    if (record == null) return null;

    // 加载食材列表
    final items = getMealItems(key);
    return record.copyWith(items: items);
  }

  /// 获取某餐次记录详情（含食材列表）通过ID
  DailyMealRecord? getMealRecordById(String id) {
    final record = _hiveHelper.dailyMealRecordsBoxInstance.get(id);
    if (record == null) return null;

    final items = getMealItems(id);
    return record.copyWith(items: items);
  }

  /// 创建/更新每日餐次记录（根据日期类型初始化）
  Future<void> initializeDailyRecords(String date, String dayType) async {
    // 检查是否已初始化
    final existing = getDailyRecords(date);
    if (existing.isNotEmpty) return;

    // 获取该日期类型的餐次模板
    final templates = DateTypeResolver.getMealTemplatesForDayType(dayType);

    for (final template in templates) {
      final id = '${date}_${template['meal_order']}';
      final record = DailyMealRecord(
        id: id,
        recordDate: date,
        dayType: dayType,
        mealOrder: template['meal_order'] as int,
        mealTime: template['meal_time'] as String,
        plannedCarb: (template['carb'] as num).toDouble(),
        plannedProtein: (template['protein'] as num).toDouble(),
        plannedFat: (template['fat'] as num).toDouble(),
        actualCarb: 0,
        actualProtein: 0,
        actualFat: 0,
        mealStatus: 'pending',
        isPreWorkout: template['is_pre_workout'] as bool,
        isPostWorkout: template['is_post_workout'] as bool,
      );

      await _hiveHelper.dailyMealRecordsBoxInstance.put(id, record);
    }
  }

  /// 更新餐次实际摄入
  Future<void> updateMealActual(DailyMealRecord record) async {
    await _hiveHelper.dailyMealRecordsBoxInstance.put(record.id, record);
  }

  /// 更新餐次状态
  Future<void> updateMealStatus(String id, String status) async {
    final record = _hiveHelper.dailyMealRecordsBoxInstance.get(id);
    if (record != null) {
      await _hiveHelper.dailyMealRecordsBoxInstance.put(
        id,
        record.copyWith(
          mealStatus: status,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  /// 跳过某餐
  Future<void> skipMeal(String date, int mealOrder) async {
    final id = '${date}_$mealOrder';
    await updateMealStatus(id, 'skipped');

    // 同步到 Firebase
    final record = _hiveHelper.dailyMealRecordsBoxInstance.get(id);
    if (record != null) {
      try {
        await _firestore.saveDailyMealRecords([record]);
      } catch (_) {}
    }
  }

  /// 保存食材到餐次
  Future<void> saveMealItems(String dailyMealRecordId, List<MealItemRecord> items) async {
    // 先删除旧记录
    final existingItems = getMealItems(dailyMealRecordId);
    for (final item in existingItems) {
      await _hiveHelper.mealItemRecordsBoxInstance.delete(item.id);
    }

    // 插入新记录
    for (final item in items) {
      final id = _uuid.v4();
      await _hiveHelper.mealItemRecordsBoxInstance.put(
        id,
        item.copyWith(id: id, dailyMealRecordId: dailyMealRecordId),
      );
    }

    // 更新餐次的实际营养素
    double totalCarb = 0;
    double totalProtein = 0;
    double totalFat = 0;
    for (final item in items) {
      totalCarb += item.carb;
      totalProtein += item.protein;
      totalFat += item.fat;
    }

    final record = _hiveHelper.dailyMealRecordsBoxInstance.get(dailyMealRecordId);
    if (record != null) {
      final updatedRecord = record.copyWith(
        actualCarb: totalCarb,
        actualProtein: totalProtein,
        actualFat: totalFat,
        mealStatus: 'completed',
        updatedAt: DateTime.now(),
      );
      await _hiveHelper.dailyMealRecordsBoxInstance.put(dailyMealRecordId, updatedRecord);

      // 同步到 Firebase
      await _syncMealRecordToFirebase(updatedRecord, items);
    }
  }

  /// 获取餐次的所有食材记录
  List<MealItemRecord> getMealItems(String dailyMealRecordId) {
    return _hiveHelper.mealItemRecordsBoxInstance.values
        .where((item) => item.dailyMealRecordId == dailyMealRecordId)
        .toList();
  }

  /// 删除餐次食材记录
  Future<void> deleteMealItems(String dailyMealRecordId) async {
    final items = getMealItems(dailyMealRecordId);
    for (final item in items) {
      await _hiveHelper.mealItemRecordsBoxInstance.delete(item.id);
    }
  }

  /// 获取当日营养素总计
  Map<String, double> getDailyTotals(String date) {
    final records = getDailyRecords(date);
    double totalCarb = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (final record in records) {
      totalCarb += record.actualCarb;
      totalProtein += record.actualProtein;
      totalFat += record.actualFat;
    }

    return {
      'carb': totalCarb,
      'protein': totalProtein,
      'fat': totalFat,
    };
  }

  /// 获取日期范围内的记录
  List<DailyMealRecord> getRecordsInRange(String startDate, String endDate) {
    final box = _hiveHelper.dailyMealRecordsBoxInstance;
    final records = box.values
        .where((r) => r.recordDate.compareTo(startDate) >= 0 && r.recordDate.compareTo(endDate) <= 0)
        .toList();
    records.sort((a, b) => a.recordDate.compareTo(b.recordDate));
    return records;
  }

  /// 同步餐次记录到 Firebase
  Future<void> _syncMealRecordToFirebase(DailyMealRecord record, List<MealItemRecord> items) async {
    try {
      await _firestore.saveDailyMealRecords([record]);
      await _firestore.saveMealItemRecords(items);
    } catch (_) {
      // Firebase 同步失败不影响本地操作
    }
  }
}
