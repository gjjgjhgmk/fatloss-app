import 'dart:convert';
import 'package:hive/hive.dart';

part 'workout_record.g.dart';

@HiveType(typeId: 8)
class WorkoutRecord extends HiveObject {
  @HiveField(0)
  final String id; // recordDate_dayType (e.g., "2024-04-08_chest")

  @HiveField(1)
  final String recordDate; // YYYY-MM-DD

  @HiveField(2)
  final String dayType; // chest, back, leg, shoulder, cardio, rest

  @HiveField(3)
  final List<WorkoutExercise> exercises;

  @HiveField(4)
  final bool isCompleted;

  @HiveField(5)
  final String? photoUrl;

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  @HiveField(9)
  final bool hasCardio; // 是否启用了空腹有氧

  WorkoutRecord({
    required this.id,
    required this.recordDate,
    required this.dayType,
    required this.exercises,
    this.isCompleted = false,
    this.photoUrl,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.hasCardio = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get completedCount => exercises.where((e) => e.isCompleted).length;
  int get totalCount => exercises.length;
  double get progress => totalCount > 0 ? completedCount / totalCount : 0;

  WorkoutRecord copyWith({
    String? id,
    String? recordDate,
    String? dayType,
    List<WorkoutExercise>? exercises,
    bool? isCompleted,
    String? photoUrl,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasCardio,
  }) {
    return WorkoutRecord(
      id: id ?? this.id,
      recordDate: recordDate ?? this.recordDate,
      dayType: dayType ?? this.dayType,
      exercises: exercises ?? this.exercises,
      isCompleted: isCompleted ?? this.isCompleted,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasCardio: hasCardio ?? this.hasCardio,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'record_date': recordDate,
      'day_type': dayType,
      'exercises': jsonEncode(exercises.map((e) => e.toMap()).toList()),
      'is_completed': isCompleted ? 1 : 0,
      'photo_url': photoUrl,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'has_cardio': hasCardio ? 1 : 0,
    };
  }

  factory WorkoutRecord.fromMap(Map<String, dynamic> map) {
    return WorkoutRecord(
      id: map['id'] as String,
      recordDate: map['record_date'] as String,
      dayType: map['day_type'] as String,
      exercises: _parseExercises(map['exercises']),
      isCompleted: _intToBool(map['is_completed']),
      photoUrl: map['photo_url'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      hasCardio: _intToBool(map['has_cardio']),
    );
  }

  static bool _intToBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    return false;
  }

  static List<WorkoutExercise> _parseExercises(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => WorkoutExercise.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => WorkoutExercise.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }
      } catch (_) {
        return [];
      }
    }

    return [];
  }
}

@HiveType(typeId: 9)
class WorkoutExercise {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final bool isCompleted;

  @HiveField(2)
  final int? sets;

  @HiveField(3)
  final String? reps;

  @HiveField(4)
  final double? weight;

  @HiveField(5)
  final int? duration; // 有氧用

  WorkoutExercise({
    required this.name,
    this.isCompleted = false,
    this.sets,
    this.reps,
    this.weight,
    this.duration,
  });

  WorkoutExercise copyWith({
    String? name,
    bool? isCompleted,
    int? sets,
    String? reps,
    double? weight,
    int? duration,
  }) {
    return WorkoutExercise(
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'duration': duration,
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      name: map['name'] as String,
      isCompleted: map['isCompleted'] as bool? ?? false,
      sets: map['sets'] as int?,
      reps: map['reps'] as String?,
      weight: (map['weight'] as num?)?.toDouble(),
      duration: map['duration'] as int?,
    );
  }
}
