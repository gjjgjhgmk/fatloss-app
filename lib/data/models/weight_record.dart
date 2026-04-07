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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recordDate': recordDate,
      'timeOfDay': timeOfDay,
      'weight': weight,
      'recordTime': recordTime,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WeightRecord.fromMap(Map<String, dynamic> map) {
    return WeightRecord(
      id: map['id'] as String,
      recordDate: map['recordDate'] as String,
      timeOfDay: map['timeOfDay'] as String,
      weight: (map['weight'] as num).toDouble(),
      recordTime: map['recordTime'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
    );
  }

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
