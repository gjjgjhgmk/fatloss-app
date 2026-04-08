import 'package:flutter/foundation.dart';
import '../../data/models/workout_record.dart';
import '../../data/repositories/workout_record_repository.dart';
import '../../core/utils/date_type_resolver.dart';

class WorkoutProvider extends ChangeNotifier {
  final WorkoutRecordRepository _repository = WorkoutRecordRepository();

  WorkoutRecord? _currentRecord;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;
  bool _hasCardio = false;

  // getters
  WorkoutRecord? get currentRecord => _currentRecord;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCardio => _hasCardio;

  String get dayType => _currentRecord?.dayType ?? '';
  bool get isCompleted => _currentRecord?.isCompleted ?? false;
  int get completedCount => _currentRecord?.completedCount ?? 0;
  int get totalCount => _currentRecord?.totalCount ?? 0;
  double get progress => _currentRecord?.progress ?? 0;
  String? get photoUrl => _currentRecord?.photoUrl;

  /// 初始化 - 加载指定日期的训练记录
  Future<void> initialize(DateTime date, String dayType) async {
    _selectedDate = date;
    _isLoading = true;
    _error = null;
    _hasCardio = DateTypeResolver.isCardioDay(date);
    notifyListeners();

    try {
      _currentRecord = await _repository.getOrCreateWorkoutRecord(
        _formatDate(date),
        dayType,
        hasCardio: _hasCardio,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '加载训练记录失败: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 切换动作完成状态
  Future<void> toggleExercise(int index) async {
    if (_currentRecord == null) return;

    try {
      _currentRecord = await _repository.toggleExercise(
        _formatDate(_selectedDate),
        _currentRecord!.dayType,
        index,
      );
      notifyListeners();
    } catch (e) {
      _error = '更新失败: $e';
      notifyListeners();
    }
  }

  /// 设置打卡照片
  Future<void> setPhoto(String photoUrl) async {
    if (_currentRecord == null) return;

    try {
      _currentRecord = await _repository.setPhoto(
        _formatDate(_selectedDate),
        _currentRecord!.dayType,
        photoUrl,
      );
      notifyListeners();
    } catch (e) {
      _error = '保存照片失败: $e';
      notifyListeners();
    }
  }

  /// 设置备注
  Future<void> setNotes(String notes) async {
    if (_currentRecord == null) return;

    try {
      _currentRecord = await _repository.setNotes(
        _formatDate(_selectedDate),
        _currentRecord!.dayType,
        notes,
      );
      notifyListeners();
    } catch (e) {
      _error = '保存备注失败: $e';
      notifyListeners();
    }
  }

  /// 设置空腹有氧状态
  Future<void> setCardioDay(bool hasCardio) async {
    try {
      await DateTypeResolver.setCardioDay(_selectedDate, hasCardio);
      _hasCardio = hasCardio;

      // 如果当前有记录，需要更新记录
      if (_currentRecord != null) {
        // 重新获取记录，这会重建 exercises 列表
        _currentRecord = await _repository.getOrCreateWorkoutRecord(
          _formatDate(_selectedDate),
          _currentRecord!.dayType,
          hasCardio: hasCardio,
        );
      }
      notifyListeners();
    } catch (e) {
      _error = '设置空腹有氧失败: $e';
      notifyListeners();
    }
  }

  /// 获取历史训练记录
  List<WorkoutRecord> getHistoryRecords() {
    return _repository.getAllWorkoutRecords();
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
