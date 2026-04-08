import '../../core/database/hive_helper.dart';
import '../../core/firebase/firestore_service.dart';
import '../../core/constants/workout_constants.dart';
import '../models/workout_record.dart';

class WorkoutRecordRepository {
  final HiveHelper _hiveHelper = HiveHelper.instance;
  final FirestoreService _firestore = FirestoreService();

  /// 获取某日训练记录
  WorkoutRecord? getWorkoutRecord(String date, String dayType) {
    final id = '${date}_$dayType';
    return _hiveHelper.workoutRecordsBoxInstance.get(id);
  }

  /// 获取或创建某日训练记录
  Future<WorkoutRecord> getOrCreateWorkoutRecord(String date, String dayType) async {
    final id = '${date}_$dayType';
    var record = _hiveHelper.workoutRecordsBoxInstance.get(id);

    if (record == null) {
      // 创建新的训练记录
      final exercises = WorkoutConstants.getExercisesForDayType(dayType)
          .map((e) => WorkoutExercise(
                name: e['name'] as String,
                sets: e['sets'] as int?,
                reps: e['reps'] as String?,
                duration: e['duration'] as int?,
              ))
          .toList();

      record = WorkoutRecord(
        id: id,
        recordDate: date,
        dayType: dayType,
        exercises: exercises,
      );

      await _hiveHelper.workoutRecordsBoxInstance.put(id, record);
    }

    return record;
  }

  /// 保存训练记录
  Future<void> saveWorkoutRecord(WorkoutRecord record) async {
    await _hiveHelper.workoutRecordsBoxInstance.put(record.id, record);

    // 同步到 Firebase
    try {
      await _firestore.saveWorkoutRecord(record);
    } catch (_) {}
  }

  /// 标记动作完成状态
  Future<WorkoutRecord> toggleExercise(String date, String dayType, int exerciseIndex) async {
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

  /// 设置打卡照片
  Future<WorkoutRecord> setPhoto(String date, String dayType, String photoUrl) async {
    final record = await getOrCreateWorkoutRecord(date, dayType);
    final updatedRecord = record.copyWith(
      photoUrl: photoUrl,
      updatedAt: DateTime.now(),
    );

    await saveWorkoutRecord(updatedRecord);
    return updatedRecord;
  }

  /// 设置备注
  Future<WorkoutRecord> setNotes(String date, String dayType, String notes) async {
    final record = await getOrCreateWorkoutRecord(date, dayType);
    final updatedRecord = record.copyWith(
      notes: notes,
      updatedAt: DateTime.now(),
    );

    await saveWorkoutRecord(updatedRecord);
    return updatedRecord;
  }

  /// 获取日期范围内的训练记录
  List<WorkoutRecord> getWorkoutRecordsInRange(String startDate, String endDate) {
    final box = _hiveHelper.workoutRecordsBoxInstance;
    final records = box.values
        .where((r) => r.recordDate.compareTo(startDate) >= 0 && r.recordDate.compareTo(endDate) <= 0)
        .toList();
    records.sort((a, b) => a.recordDate.compareTo(b.recordDate));
    return records;
  }

  /// 获取所有训练记录
  List<WorkoutRecord> getAllWorkoutRecords() {
    final records = _hiveHelper.workoutRecordsBoxInstance.values.toList();
    records.sort((a, b) => b.recordDate.compareTo(a.recordDate));
    return records;
  }
}
