import 'package:hive/hive.dart';
import 'meal_item_record.dart';

part 'daily_meal_record.g.dart';

@HiveType(typeId: 3)
class DailyMealRecord extends HiveObject {
  @HiveField(0)
  final String id; // recordDate_mealOrder

  @HiveField(1)
  final String recordDate; // YYYY-MM-DD

  @HiveField(2)
  final String dayType;

  @HiveField(3)
  final int mealOrder;

  @HiveField(4)
  final String mealTime;

  @HiveField(5)
  final double plannedCarb;

  @HiveField(6)
  final double plannedProtein;

  @HiveField(7)
  final double plannedFat;

  @HiveField(8)
  final double actualCarb;

  @HiveField(9)
  final double actualProtein;

  @HiveField(10)
  final double actualFat;

  @HiveField(11)
  final String mealStatus; // pending, completed, skipped

  @HiveField(12)
  final String? notes;

  @HiveField(13)
  final bool isPreWorkout;

  @HiveField(14)
  final bool isPostWorkout;

  @HiveField(15)
  final DateTime createdAt;

  @HiveField(16)
  final DateTime updatedAt;

  @HiveField(17)
  final List<MealItemRecord> items;

  @HiveField(18)
  final String? photoUrl; // 拍照打卡照片URL

  DailyMealRecord({
    required this.id,
    required this.recordDate,
    required this.dayType,
    required this.mealOrder,
    required this.mealTime,
    required this.plannedCarb,
    required this.plannedProtein,
    required this.plannedFat,
    this.actualCarb = 0,
    this.actualProtein = 0,
    this.actualFat = 0,
    this.mealStatus = 'pending',
    this.notes,
    this.isPreWorkout = false,
    this.isPostWorkout = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.items = const [],
    this.photoUrl,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get remainingCarb => plannedCarb - actualCarb;
  double get remainingProtein => plannedProtein - actualProtein;
  double get remainingFat => plannedFat - actualFat;

  bool get isCompleted => mealStatus == 'completed';
  bool get isSkipped => mealStatus == 'skipped';
  bool get isPending => mealStatus == 'pending';

  double get carbProgress => plannedCarb > 0 ? (actualCarb / plannedCarb).clamp(0.0, 2.0) : 0;
  double get proteinProgress => plannedProtein > 0 ? (actualProtein / plannedProtein).clamp(0.0, 2.0) : 0;
  double get fatProgress => plannedFat > 0 ? (actualFat / plannedFat).clamp(0.0, 2.0) : 0;

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'record_date': recordDate,
      'day_type': dayType,
      'meal_order': mealOrder,
      'meal_time': mealTime,
      'planned_carb': plannedCarb,
      'planned_protein': plannedProtein,
      'planned_fat': plannedFat,
      'actual_carb': actualCarb,
      'actual_protein': actualProtein,
      'actual_fat': actualFat,
      'meal_status': mealStatus,
      'notes': notes,
      'is_pre_workout': isPreWorkout,
      'is_post_workout': isPostWorkout,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'photo_url': photoUrl,
    };
  }

  factory DailyMealRecord.fromMap(Map<String, dynamic> map) {
    return DailyMealRecord(
      id: map['id'] as String,
      recordDate: map['record_date'] as String,
      dayType: map['day_type'] as String,
      mealOrder: map['meal_order'] as int,
      mealTime: map['meal_time'] as String,
      plannedCarb: (map['planned_carb'] as num).toDouble(),
      plannedProtein: (map['planned_protein'] as num).toDouble(),
      plannedFat: (map['planned_fat'] as num).toDouble(),
      actualCarb: (map['actual_carb'] as num?)?.toDouble() ?? 0,
      actualProtein: (map['actual_protein'] as num?)?.toDouble() ?? 0,
      actualFat: (map['actual_fat'] as num?)?.toDouble() ?? 0,
      mealStatus: map['meal_status'] as String? ?? 'pending',
      notes: map['notes'] as String?,
      isPreWorkout: map['is_pre_workout'] == true || map['is_pre_workout'] == 1,
      isPostWorkout: map['is_post_workout'] == true || map['is_post_workout'] == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : DateTime.now(),
      photoUrl: map['photo_url'] as String?,
    );
  }

  DailyMealRecord copyWith({
    String? id,
    String? recordDate,
    String? dayType,
    int? mealOrder,
    String? mealTime,
    double? plannedCarb,
    double? plannedProtein,
    double? plannedFat,
    double? actualCarb,
    double? actualProtein,
    double? actualFat,
    String? mealStatus,
    String? notes,
    bool? isPreWorkout,
    bool? isPostWorkout,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MealItemRecord>? items,
    String? photoUrl,
  }) {
    return DailyMealRecord(
      id: id ?? this.id,
      recordDate: recordDate ?? this.recordDate,
      dayType: dayType ?? this.dayType,
      mealOrder: mealOrder ?? this.mealOrder,
      mealTime: mealTime ?? this.mealTime,
      plannedCarb: plannedCarb ?? this.plannedCarb,
      plannedProtein: plannedProtein ?? this.plannedProtein,
      plannedFat: plannedFat ?? this.plannedFat,
      actualCarb: actualCarb ?? this.actualCarb,
      actualProtein: actualProtein ?? this.actualProtein,
      actualFat: actualFat ?? this.actualFat,
      mealStatus: mealStatus ?? this.mealStatus,
      notes: notes ?? this.notes,
      isPreWorkout: isPreWorkout ?? this.isPreWorkout,
      isPostWorkout: isPostWorkout ?? this.isPostWorkout,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
