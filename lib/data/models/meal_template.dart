import 'package:hive/hive.dart';

part 'meal_template.g.dart';

@HiveType(typeId: 1)
class MealTemplate extends HiveObject {
  @HiveField(0)
  final String dayType;

  @HiveField(1)
  final int mealOrder;

  @HiveField(2)
  final String mealTime;

  @HiveField(3)
  final double carb;

  @HiveField(4)
  final double protein;

  @HiveField(5)
  final double fat;

  @HiveField(6)
  final bool isPreWorkout;

  @HiveField(7)
  final bool isPostWorkout;

  @HiveField(8)
  final DateTime createdAt;

  MealTemplate({
    required this.dayType,
    required this.mealOrder,
    required this.mealTime,
    required this.carb,
    required this.protein,
    required this.fat,
    this.isPreWorkout = false,
    this.isPostWorkout = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  MealTemplate copyWith({
    String? dayType,
    int? mealOrder,
    String? mealTime,
    double? carb,
    double? protein,
    double? fat,
    bool? isPreWorkout,
    bool? isPostWorkout,
    DateTime? createdAt,
  }) {
    return MealTemplate(
      dayType: dayType ?? this.dayType,
      mealOrder: mealOrder ?? this.mealOrder,
      mealTime: mealTime ?? this.mealTime,
      carb: carb ?? this.carb,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      isPreWorkout: isPreWorkout ?? this.isPreWorkout,
      isPostWorkout: isPostWorkout ?? this.isPostWorkout,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
