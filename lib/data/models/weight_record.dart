import 'package:hive/hive.dart';

part 'weight_record.g.dart';

@HiveType(typeId: 7)
class WeightRecord extends HiveObject {
  @HiveField(0)
  final String id; // recordDate_timeOfDay (e.g., "2024-04-07_morning")

  @HiveField(1)
  final String recordDate; // YYYY-MM-DD

  @HiveField(2)
  final String timeOfDay; // "morning" 或 "evening"

  @HiveField(3)
  final double weight; // 体重 kg

  @HiveField(4)
  final String? recordTime; // 具体时间点 "HH:mm"

  @HiveField(5)
  final String? notes;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  WeightRecord({
    required this.id,
    required this.recordDate,
    required this.timeOfDay,
    required this.weight,
    this.recordTime,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get displayTime => timeOfDay == 'morning' ? '早上' : '晚上';

  WeightRecord copyWith({
    String? id,
    String? recordDate,
    String? timeOfDay,
    double? weight,
    String? recordTime,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeightRecord(
      id: id ?? this.id,
      recordDate: recordDate ?? this.recordDate,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      weight: weight ?? this.weight,
      recordTime: recordTime ?? this.recordTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
