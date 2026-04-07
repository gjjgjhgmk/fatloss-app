import 'package:hive/hive.dart';

part 'weekly_review.g.dart';

@HiveType(typeId: 6)
class WeeklyReview extends HiveObject {
  @HiveField(0)
  final String id; // weekStartDate

  @HiveField(1)
  final String weekStartDate;

  @HiveField(2)
  final String weekEndDate;

  @HiveField(3)
  final double avgCarbIntake;

  @HiveField(4)
  final double avgProteinIntake;

  @HiveField(5)
  final double avgFatIntake;

  @HiveField(6)
  final double carbComplianceRate;

  @HiveField(7)
  final double proteinComplianceRate;

  @HiveField(8)
  final double fatComplianceRate;

  @HiveField(9)
  final int totalSkippedMeals;

  @HiveField(10)
  final String? notes;

  @HiveField(11)
  final DateTime createdAt;

  WeeklyReview({
    required this.id,
    required this.weekStartDate,
    required this.weekEndDate,
    this.avgCarbIntake = 0,
    this.avgProteinIntake = 0,
    this.avgFatIntake = 0,
    this.carbComplianceRate = 0,
    this.proteinComplianceRate = 0,
    this.fatComplianceRate = 0,
    this.totalSkippedMeals = 0,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get avgCaloriesIntake => avgCarbIntake * 4 + avgProteinIntake * 4 + avgFatIntake * 9;

  WeeklyReview copyWith({
    String? id,
    String? weekStartDate,
    String? weekEndDate,
    double? avgCarbIntake,
    double? avgProteinIntake,
    double? avgFatIntake,
    double? carbComplianceRate,
    double? proteinComplianceRate,
    double? fatComplianceRate,
    int? totalSkippedMeals,
    String? notes,
    DateTime? createdAt,
  }) {
    return WeeklyReview(
      id: id ?? this.id,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      weekEndDate: weekEndDate ?? this.weekEndDate,
      avgCarbIntake: avgCarbIntake ?? this.avgCarbIntake,
      avgProteinIntake: avgProteinIntake ?? this.avgProteinIntake,
      avgFatIntake: avgFatIntake ?? this.avgFatIntake,
      carbComplianceRate: carbComplianceRate ?? this.carbComplianceRate,
      proteinComplianceRate: proteinComplianceRate ?? this.proteinComplianceRate,
      fatComplianceRate: fatComplianceRate ?? this.fatComplianceRate,
      totalSkippedMeals: totalSkippedMeals ?? this.totalSkippedMeals,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
