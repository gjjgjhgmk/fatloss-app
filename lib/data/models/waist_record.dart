import 'package:hive/hive.dart';

part 'waist_record.g.dart';

@HiveType(typeId: 8)
class WaistRecord extends HiveObject {
  @HiveField(0)
  final String id; // recordDate

  @HiveField(1)
  final String recordDate; // YYYY-MM-DD

  @HiveField(2)
  final double waist; // 腰围 cm

  @HiveField(3)
  final String? recordTime; // 具体时间点 "HH:mm"

  @HiveField(4)
  final String? notes;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  WaistRecord({
    required this.id,
    required this.recordDate,
    required this.waist,
    this.recordTime,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  WaistRecord copyWith({
    String? id,
    String? recordDate,
    double? waist,
    String? recordTime,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WaistRecord(
      id: id ?? this.id,
      recordDate: recordDate ?? this.recordDate,
      waist: waist ?? this.waist,
      recordTime: recordTime ?? this.recordTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recordDate': recordDate,
      'waist': waist,
      'recordTime': recordTime,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WaistRecord.fromMap(Map<String, dynamic> map) {
    return WaistRecord(
      id: map['id'] as String,
      recordDate: map['recordDate'] as String,
      waist: (map['waist'] as num).toDouble(),
      recordTime: map['recordTime'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
    );
  }
}
