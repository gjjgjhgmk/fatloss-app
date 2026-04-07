import 'package:hive/hive.dart';

part 'meal_item_record.g.dart';

@HiveType(typeId: 4)
class MealItemRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String dailyMealRecordId;

  @HiveField(2)
  final String? ingredientId;

  @HiveField(3)
  final String ingredientName;

  @HiveField(4)
  final double amount;

  @HiveField(5)
  final double carb;

  @HiveField(6)
  final double protein;

  @HiveField(7)
  final double fat;

  @HiveField(8)
  final bool isManualInput;

  @HiveField(9)
  final DateTime createdAt;

  MealItemRecord({
    required this.id,
    required this.dailyMealRecordId,
    this.ingredientId,
    required this.ingredientName,
    required this.amount,
    required this.carb,
    required this.protein,
    required this.fat,
    this.isManualInput = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get calories => carb * 4 + protein * 4 + fat * 9;

  MealItemRecord copyWith({
    String? id,
    String? dailyMealRecordId,
    String? ingredientId,
    String? ingredientName,
    double? amount,
    double? carb,
    double? protein,
    double? fat,
    bool? isManualInput,
    DateTime? createdAt,
  }) {
    return MealItemRecord(
      id: id ?? this.id,
      dailyMealRecordId: dailyMealRecordId ?? this.dailyMealRecordId,
      ingredientId: ingredientId ?? this.ingredientId,
      ingredientName: ingredientName ?? this.ingredientName,
      amount: amount ?? this.amount,
      carb: carb ?? this.carb,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      isManualInput: isManualInput ?? this.isManualInput,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
