import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/daily_meal_record.dart';
import '../../data/models/meal_item_record.dart';
import '../../data/models/diet_rule.dart';
import '../../data/models/weight_record.dart';
import '../../data/models/waist_record.dart';
import '../../data/models/ingredient.dart';
import '../../data/models/workout_record.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  late FirebaseFirestore _db;
  bool _initialized = false;

  FirebaseFirestore get db => _db;

  Future<void> initialize() async {
    if (_initialized) return;
    _db = FirebaseFirestore.instance;
    _initialized = true;
  }

  // ============ 每日餐次记录 ============

  Future<void> saveDailyMealRecords(List<DailyMealRecord> records) async {
    final batch = _db.batch();
    for (final record in records) {
      final docRef = _db.collection('daily_meal_records').doc(record.id);
      batch.set(docRef, record.toMap());
    }
    await batch.commit();
  }

  Future<void> saveMealItemRecords(List<MealItemRecord> items) async {
    final batch = _db.batch();
    for (final item in items) {
      final docRef = _db.collection('meal_item_records').doc(item.id);
      batch.set(docRef, item.toMap());
    }
    await batch.commit();
  }

  Future<List<DailyMealRecord>> getDailyMealRecords(String date) async {
    final snapshot = await _db
        .collection('daily_meal_records')
        .where('recordDate', isEqualTo: date)
        .get();

    final List<DailyMealRecord> records = [];
    for (final doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          records.add(DailyMealRecord.fromMap(data));
        }
      } catch (_) {
        // Skip malformed documents
      }
    }
    return records;
  }

  Future<List<MealItemRecord>> getMealItemRecords(String dailyMealRecordId) async {
    final snapshot = await _db
        .collection('meal_item_records')
        .where('dailyMealRecordId', isEqualTo: dailyMealRecordId)
        .get();

    return snapshot.docs.map((doc) {
      return MealItemRecord.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Stream<QuerySnapshot> watchDailyMealRecords(String date) {
    return _db
        .collection('daily_meal_records')
        .where('recordDate', isEqualTo: date)
        .snapshots();
  }

  // ============ 体重记录 ============

  Future<void> saveWeightRecord(WeightRecord record) async {
    await _db.collection('weight_records').doc(record.id).set(record.toMap());
  }

  Future<List<WeightRecord>> getWeightRecords({int limit = 30}) async {
    final snapshot = await _db
        .collection('weight_records')
        .orderBy('recordDate', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      return WeightRecord.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Stream<QuerySnapshot> watchWeightRecords() {
    return _db
        .collection('weight_records')
        .orderBy('recordDate', descending: true)
        .limit(30)
        .snapshots();
  }

  // ============ 腰围记录 ============

  Future<void> saveWaistRecord(WaistRecord record) async {
    await _db.collection('waist_records').doc(record.id).set(record.toMap());
  }

  Future<List<WaistRecord>> getWaistRecords({int limit = 30}) async {
    final snapshot = await _db
        .collection('waist_records')
        .orderBy('recordDate', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      return WaistRecord.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Stream<QuerySnapshot> watchWaistRecords() {
    return _db
        .collection('waist_records')
        .orderBy('recordDate', descending: true)
        .limit(30)
        .snapshots();
  }

  // ============ 食材库 ============

  Future<void> saveIngredient(Ingredient ingredient) async {
    await _db.collection('ingredients').doc(ingredient.id).set(ingredient.toMap());
  }

  Future<List<Ingredient>> getIngredients() async {
    final snapshot = await _db.collection('ingredients').get();
    return snapshot.docs.map((doc) {
      return Ingredient.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Stream<QuerySnapshot> watchIngredients() {
    return _db.collection('ingredients').snapshots();
  }

  // ============ 饮食规则（只读模板）============

  Future<void> seedDietRules(List<DietRule> rules) async {
    final snapshot = await _db.collection('diet_rules').get();
    if (snapshot.docs.isNotEmpty) return; // 已有数据不覆盖

    final batch = _db.batch();
    for (final rule in rules) {
      final docRef = _db.collection('diet_rules').doc(rule.dayType);
      batch.set(docRef, rule.toMap());
    }
    await batch.commit();
  }

  // ============ 公开数据（围观用）============

  /// 获取今日饮食概览（公开，只读）
  Future<Map<String, dynamic>> getPublicTodayOverview(String date) async {
    final records = await getDailyMealRecords(date);
    final weights = await getWeightRecords(limit: 1);
    final waists = await getWaistRecords(limit: 1);

    double totalCarb = 0, totalProtein = 0, totalFat = 0;
    int completedMeals = 0;
    for (final r in records) {
      totalCarb += r.actualCarb;
      totalProtein += r.actualProtein;
      totalFat += r.actualFat;
      if (r.isCompleted) completedMeals++;
    }

    return {
      'date': date,
      'totalCarb': totalCarb,
      'totalProtein': totalProtein,
      'totalFat': totalFat,
      'completedMeals': completedMeals,
      'totalMeals': records.length,
      'latestWeight': weights.isNotEmpty ? weights.first.weight : null,
      'latestWaist': waists.isNotEmpty ? waists.first.waist : null,
      'records': records.map((r) => r.toMap()).toList(), // 转换为 Map 以便 JSON 序列化
    };
  }

  /// 监听今日饮食概览变化
  Stream<Map<String, dynamic>> watchPublicTodayOverview(String date) {
    return watchDailyMealRecords(date).asyncMap((snapshot) async {
      final List<DailyMealRecord> records = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            records.add(DailyMealRecord.fromMap(data));
          }
        } catch (_) {
          // Skip malformed documents
        }
      }
      final weights = await getWeightRecords(limit: 1);

      double totalCarb = 0, totalProtein = 0, totalFat = 0;
      int completedMeals = 0;
      for (final r in records) {
        totalCarb += r.actualCarb;
        totalProtein += r.actualProtein;
        totalFat += r.actualFat;
        if (r.isCompleted) completedMeals++;
      }

      return {
        'date': date,
        'totalCarb': totalCarb,
        'totalProtein': totalProtein,
        'totalFat': totalFat,
        'completedMeals': completedMeals,
        'totalMeals': records.length,
        'latestWeight': weights.isNotEmpty ? weights.first.weight : null,
        'records': records.map((r) => r.toMap()).toList(),
      };
    });
  }

  // ============ 训练记录 ============

  Future<void> saveWorkoutRecord(WorkoutRecord record) async {
    await _db.collection('workout_records').doc(record.id).set(record.toMap());
  }

  Future<List<WorkoutRecord>> getWorkoutRecords({int limit = 30}) async {
    final snapshot = await _db
        .collection('workout_records')
        .orderBy('recordDate', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      return WorkoutRecord.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Stream<QuerySnapshot> watchWorkoutRecords() {
    return _db
        .collection('workout_records')
        .orderBy('recordDate', descending: true)
        .limit(30)
        .snapshots();
  }
}
