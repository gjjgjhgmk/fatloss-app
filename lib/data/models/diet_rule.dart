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
}
