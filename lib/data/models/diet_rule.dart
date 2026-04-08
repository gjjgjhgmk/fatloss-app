import 'package:hive/hive.dart';

part 'diet_rule.g.dart';

@HiveType(typeId: 0)
class DietRule extends HiveObject {
  @HiveField(0)
  final String dayType;

  @HiveField(1)
  final double totalCarb;

  @HiveField(2)
  final double totalProtein;

  @HiveField(3)
  final double totalFat;

  @HiveField(4)
  final int mealCount;

  @HiveField(5)
  final String? specialNotes;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  DietRule({
    required this.dayType,
    required this.totalCarb,
    required this.totalProtein,
    required this.totalFat,
    required this.mealCount,
    this.specialNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  DietRule copyWith({
    String? dayType,
    double? totalCarb,
    double? totalProtein,
    double? totalFat,
    int? mealCount,
    String? specialNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DietRule(
      dayType: dayType ?? this.dayType,
      totalCarb: totalCarb ?? this.totalCarb,
      totalProtein: totalProtein ?? this.totalProtein,
      totalFat: totalFat ?? this.totalFat,
      mealCount: mealCount ?? this.mealCount,
      specialNotes: specialNotes ?? this.specialNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day_type': dayType,
      'total_carb': totalCarb,
      'total_protein': totalProtein,
      'total_fat': totalFat,
      'meal_count': mealCount,
      'special_notes': specialNotes,
    };
  }

  factory DietRule.fromMap(Map<String, dynamic> map) {
    return DietRule(
      dayType: map['day_type'] as String,
      totalCarb: (map['total_carb'] as num).toDouble(),
      totalProtein: (map['total_protein'] as num).toDouble(),
      totalFat: (map['total_fat'] as num).toDouble(),
      mealCount: map['meal_count'] as int,
      specialNotes: map['special_notes'] as String?,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
