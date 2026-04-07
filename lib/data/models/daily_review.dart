import 'package:hive/hive.dart';

part 'daily_review.g.dart';

@HiveType(typeId: 5)
class DailyReview extends HiveObject {
  @HiveField(0)
  final String recordDate;

  @HiveField(1)
  final double totalCarbActual;

  @HiveField(2)
  final double totalProteinActual;

  @HiveField(3)
  final double totalFatActual;

  @HiveField(4)
  final String? carbStatus; // short, ok, excess

  @HiveField(5)
  final String? proteinStatus;

  @HiveField(6)
  final String? fatStatus;

  @HiveField(7)
  final String? reviewNotes;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  DailyReview({
    required this.recordDate,
    this.totalCarbActual = 0,
    this.totalProteinActual = 0,
    this.totalFatActual = 0,
    this.carbStatus,
    this.proteinStatus,
    this.fatStatus,
    this.reviewNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get totalCaloriesActual => totalCarbActual * 4 + totalProteinActual * 4 + totalFatActual * 9;

  DailyReview copyWith({
    String? recordDate,
    double? totalCarbActual,
    double? totalProteinActual,
    double? totalFatActual,
    String? carbStatus,
    String? proteinStatus,
    String? fatStatus,
    String? reviewNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyReview(
      recordDate: recordDate ?? this.recordDate,
      totalCarbActual: totalCarbActual ?? this.totalCarbActual,
      totalProteinActual: totalProteinActual ?? this.totalProteinActual,
      totalFatActual: totalFatActual ?? this.totalFatActual,
      carbStatus: carbStatus ?? this.carbStatus,
      proteinStatus: proteinStatus ?? this.proteinStatus,
      fatStatus: fatStatus ?? this.fatStatus,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
