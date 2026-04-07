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
      'recordDate': recordDate,
      'dayType': dayType,
      'mealOrder': mealOrder,
      'mealTime': mealTime,
      'plannedCarb': plannedCarb,
      'plannedProtein': plannedProtein,
      'plannedFat': plannedFat,
      'actualCarb': actualCarb,
      'actualProtein': actualProtein,
      'actualFat': actualFat,
      'mealStatus': mealStatus,
      'notes': notes,
      'isPreWorkout': isPreWorkout,
      'isPostWorkout': isPostWorkout,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }

  factory DailyMealRecord.fromMap(Map<String, dynamic> map) {
    return DailyMealRecord(
      id: map['id'] as String,
      recordDate: map['recordDate'] as String,
      dayType: map['dayType'] as String,
      mealOrder: map['mealOrder'] as int,
      mealTime: map['mealTime'] as String,
      plannedCarb: (map['plannedCarb'] as num).toDouble(),
      plannedProtein: (map['plannedProtein'] as num).toDouble(),
      plannedFat: (map['plannedFat'] as num).toDouble(),
      actualCarb: (map['actualCarb'] as num?)?.toDouble() ?? 0,
      actualProtein: (map['actualProtein'] as num?)?.toDouble() ?? 0,
      actualFat: (map['actualFat'] as num?)?.toDouble() ?? 0,
      mealStatus: map['mealStatus'] as String? ?? 'pending',
      notes: map['notes'] as String?,
      isPreWorkout: map['isPreWorkout'] as bool? ?? false,
      isPostWorkout: map['isPostWorkout'] as bool? ?? false,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
      photoUrl: map['photoUrl'] as String?,
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
