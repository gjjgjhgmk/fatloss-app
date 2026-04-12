import 'package:uuid/uuid.dart';

import '../../core/database/hive_helper.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/utils/date_type_resolver.dart';
import '../models/daily_meal_record.dart';
import '../models/meal_item_record.dart';

class DailyRecordRepository {
  final HiveHelper _hiveHelper = HiveHelper.instance;
  final _uuid = const Uuid();

  List<DailyMealRecord> getDailyRecords(String date) {
    final box = _hiveHelper.dailyMealRecordsBoxInstance;
    final records = box.values.where((r) => r.recordDate == date).toList();
    records.sort((a, b) => a.mealOrder.compareTo(b.mealOrder));
    return records;
  }

  DailyMealRecord? getMealRecord(String date, int mealOrder) {
    final key = '${date}_$mealOrder';
    final record = _hiveHelper.dailyMealRecordsBoxInstance.get(key);
    if (record == null) return null;

    final items = getMealItems(key);
    return record.copyWith(items: items);
  }

  DailyMealRecord? getMealRecordById(String id) {
    final record = _hiveHelper.dailyMealRecordsBoxInstance.get(id);
    if (record == null) return null;

    final items = getMealItems(id);
    return record.copyWith(items: items);
  }

  Future<void> initializeDailyRecords(String date, String dayType) async {
    final existing = getDailyRecords(date);
    if (existing.isNotEmpty) return;

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

  Future<void> rebuildDailyRecordsForDate(String date, String dayType) async {
    await _deleteLocalRecordsForDate(date);
    await _deleteRemoteRecordsForDate(date);
    await initializeDailyRecords(date, dayType);
    await _syncDateRecordsToSupabase(date);
  }

  Future<void> updateMealActual(DailyMealRecord record) async {
    await _hiveHelper.dailyMealRecordsBoxInstance.put(record.id, record);
    final items = getMealItems(record.id);
    await _syncToSupabase(record, items);
  }

  Future<void> updateMealStatus(String id, String status) async {
    final record = _hiveHelper.dailyMealRecordsBoxInstance.get(id);
    if (record == null) return;

    await _hiveHelper.dailyMealRecordsBoxInstance.put(
      id,
      record.copyWith(
        mealStatus: status,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> skipMeal(String date, int mealOrder) async {
    final id = '${date}_$mealOrder';
    await updateMealStatus(id, 'skipped');

    final record = _hiveHelper.dailyMealRecordsBoxInstance.get(id);
    if (record != null) {
      await _syncToSupabase(record, <MealItemRecord>[]);
    }
  }

  Future<void> saveMealItems(
    String dailyMealRecordId,
    List<MealItemRecord> items,
  ) async {
    final existingItems = getMealItems(dailyMealRecordId);
    for (final item in existingItems) {
      await _hiveHelper.mealItemRecordsBoxInstance.delete(item.id);
    }

    for (final item in items) {
      final id = _uuid.v4();
      await _hiveHelper.mealItemRecordsBoxInstance.put(
        id,
        item.copyWith(id: id, dailyMealRecordId: dailyMealRecordId),
      );
    }

    double totalCarb = 0;
    double totalProtein = 0;
    double totalFat = 0;
    for (final item in items) {
      totalCarb += item.carb;
      totalProtein += item.protein;
      totalFat += item.fat;
    }

    final record =
        _hiveHelper.dailyMealRecordsBoxInstance.get(dailyMealRecordId);
    if (record == null) return;

    final updatedRecord = record.copyWith(
      actualCarb: totalCarb,
      actualProtein: totalProtein,
      actualFat: totalFat,
      mealStatus: 'completed',
      updatedAt: DateTime.now(),
    );
    await _hiveHelper.dailyMealRecordsBoxInstance
        .put(dailyMealRecordId, updatedRecord);

    await _syncToSupabase(updatedRecord, items);
  }

  List<MealItemRecord> getMealItems(String dailyMealRecordId) {
    return _hiveHelper.mealItemRecordsBoxInstance.values
        .where((item) => item.dailyMealRecordId == dailyMealRecordId)
        .toList();
  }

  Future<void> deleteMealItems(String dailyMealRecordId) async {
    final items = getMealItems(dailyMealRecordId);
    for (final item in items) {
      await _hiveHelper.mealItemRecordsBoxInstance.delete(item.id);
    }
  }

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

    return <String, double>{
      'carb': totalCarb,
      'protein': totalProtein,
      'fat': totalFat,
    };
  }

  List<DailyMealRecord> getRecordsInRange(String startDate, String endDate) {
    final box = _hiveHelper.dailyMealRecordsBoxInstance;
    final records = box.values
        .where((r) =>
            r.recordDate.compareTo(startDate) >= 0 &&
            r.recordDate.compareTo(endDate) <= 0)
        .toList();
    records.sort((a, b) => a.recordDate.compareTo(b.recordDate));
    return records;
  }

  Future<void> _deleteLocalRecordsForDate(String date) async {
    final dailyBox = _hiveHelper.dailyMealRecordsBoxInstance;
    final itemBox = _hiveHelper.mealItemRecordsBoxInstance;

    final records = dailyBox.values.where((r) => r.recordDate == date).toList();
    final recordIds = records.map((e) => e.id).toSet();

    final items = itemBox.values
        .where((i) => recordIds.contains(i.dailyMealRecordId))
        .toList();

    for (final item in items) {
      await itemBox.delete(item.id);
    }

    for (final record in records) {
      await dailyBox.delete(record.id);
    }
  }

  Future<void> _deleteRemoteRecordsForDate(String date) async {
    try {
      final existingRows = await SupabaseConfig.client
          .from('daily_meal_records')
          .select('id')
          .eq('record_date', date);

      final ids = (existingRows as List)
          .whereType<Map>()
          .map((e) => e['id'])
          .whereType<String>()
          .toList();

      if (ids.isNotEmpty) {
        await SupabaseConfig.client
            .from('meal_item_records')
            .delete()
            .inFilter('daily_meal_record_id', ids);
      }

      await SupabaseConfig.client
          .from('daily_meal_records')
          .delete()
          .eq('record_date', date);
    } catch (_) {
      // Ignore remote cleanup failures and keep local flow available.
    }
  }

  Future<void> _syncDateRecordsToSupabase(String date) async {
    try {
      final records = getDailyRecords(date);
      if (records.isEmpty) return;

      await SupabaseConfig.client
          .from('daily_meal_records')
          .upsert(records.map((r) => r.toMap()).toList());
    } catch (_) {
      // Ignore sync failures to avoid blocking local usage.
    }
  }

  Future<void> _syncToSupabase(
    DailyMealRecord record,
    List<MealItemRecord> items,
  ) async {
    try {
      await SupabaseConfig.client
          .from('daily_meal_records')
          .upsert(record.toMap());
      if (items.isNotEmpty) {
        await SupabaseConfig.client
            .from('meal_item_records')
            .upsert(items.map((e) => e.toMap()).toList());
      }
    } catch (_) {
      // Ignore sync failures to avoid blocking local usage.
    }
  }
}
