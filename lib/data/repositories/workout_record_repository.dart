import '../../core/constants/workout_constants.dart';
import '../../core/database/hive_helper.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/workout_record.dart';

class WorkoutRecordRepository {
  final HiveHelper _hiveHelper = HiveHelper.instance;

  WorkoutRecord? getWorkoutRecord(String date, String dayType) {
    final id = '${date}_$dayType';
    return _hiveHelper.workoutRecordsBoxInstance.get(id);
  }

  Future<WorkoutRecord> getOrCreateWorkoutRecord(
    String date,
    String dayType, {
    bool hasCardio = false,
  }) async {
    final id = '${date}_$dayType';
    var record = _hiveHelper.workoutRecordsBoxInstance.get(id);

    if (record == null) {
      record = _buildWorkoutRecord(
        date: date,
        dayType: dayType,
        hasCardio: hasCardio,
      );
      await _hiveHelper.workoutRecordsBoxInstance.put(id, record);
    }

    return record;
  }

  Future<WorkoutRecord> replaceWorkoutRecordForDate(
    String date,
    String dayType, {
    bool hasCardio = false,
  }) async {
    final localBox = _hiveHelper.workoutRecordsBoxInstance;

    final localRecords =
        localBox.values.where((r) => r.recordDate == date).toList();
    for (final record in localRecords) {
      await localBox.delete(record.id);
    }

    try {
      await SupabaseConfig.client
          .from('workout_records')
          .delete()
          .eq('record_date', date);
    } catch (_) {
      // Ignore remote cleanup failures to keep local flow available.
    }

    final newRecord = _buildWorkoutRecord(
      date: date,
      dayType: dayType,
      hasCardio: hasCardio,
    );

    await localBox.put(newRecord.id, newRecord);

    try {
      await SupabaseConfig.client
          .from('workout_records')
          .upsert(newRecord.toMap());
    } catch (_) {
      // Ignore remote sync failures to keep local flow available.
    }

    return newRecord;
  }

  Future<void> saveWorkoutRecord(WorkoutRecord record) async {
    await _hiveHelper.workoutRecordsBoxInstance.put(record.id, record);

    try {
      await SupabaseConfig.client
          .from('workout_records')
          .upsert(record.toMap());
    } catch (_) {}
  }

  Future<WorkoutRecord> toggleExercise(
    String date,
    String dayType,
    int exerciseIndex,
  ) async {
    final record = await getOrCreateWorkoutRecord(date, dayType);
    final exercises = List<WorkoutExercise>.from(record.exercises);

    exercises[exerciseIndex] = exercises[exerciseIndex].copyWith(
      isCompleted: !exercises[exerciseIndex].isCompleted,
    );

    final updatedRecord = record.copyWith(
      exercises: exercises,
      isCompleted: exercises.every((e) => e.isCompleted),
      updatedAt: DateTime.now(),
    );

    await saveWorkoutRecord(updatedRecord);
    return updatedRecord;
  }

  Future<WorkoutRecord> setPhoto(
    String date,
    String dayType,
    String photoUrl,
  ) async {
    final record = await getOrCreateWorkoutRecord(date, dayType);
    final updatedRecord = record.copyWith(
      photoUrl: photoUrl,
      updatedAt: DateTime.now(),
    );

    await saveWorkoutRecord(updatedRecord);
    return updatedRecord;
  }

  Future<WorkoutRecord> setNotes(
    String date,
    String dayType,
    String notes,
  ) async {
    final record = await getOrCreateWorkoutRecord(date, dayType);
    final updatedRecord = record.copyWith(
      notes: notes,
      updatedAt: DateTime.now(),
    );

    await saveWorkoutRecord(updatedRecord);
    return updatedRecord;
  }

  List<WorkoutRecord> getWorkoutRecordsInRange(
      String startDate, String endDate) {
    final box = _hiveHelper.workoutRecordsBoxInstance;
    final records = box.values
        .where((r) =>
            r.recordDate.compareTo(startDate) >= 0 &&
            r.recordDate.compareTo(endDate) <= 0)
        .toList();
    records.sort((a, b) => a.recordDate.compareTo(b.recordDate));
    return records;
  }

  List<WorkoutRecord> getAllWorkoutRecords() {
    final records = _hiveHelper.workoutRecordsBoxInstance.values.toList();
    records.sort((a, b) => b.recordDate.compareTo(a.recordDate));
    return records;
  }

  WorkoutRecord _buildWorkoutRecord({
    required String date,
    required String dayType,
    required bool hasCardio,
  }) {
    final exercises = WorkoutConstants.getExercisesForDayType(dayType)
        .map(
          (e) => WorkoutExercise(
            name: e['name'] as String,
            sets: e['sets'] as int?,
            reps: e['reps'] as String?,
            duration: e['duration'] as int?,
          ),
        )
        .toList();

    if (hasCardio) {
      exercises.add(
        WorkoutExercise(
          name: '60min 爬坡',
          duration: 60,
        ),
      );
    }

    return WorkoutRecord(
      id: '${date}_$dayType',
      recordDate: date,
      dayType: dayType,
      exercises: exercises,
      hasCardio: hasCardio,
      updatedAt: DateTime.now(),
    );
  }
}
