import 'package:flutter/foundation.dart';
import '../../domain/usecases/diet_review_generator.dart';

class ReviewProvider extends ChangeNotifier {
  final DietReviewGenerator _reviewGenerator = DietReviewGenerator();

  DietReviewResult? _dailyReview;
  Map<String, dynamic>? _weeklyReview;
  bool _isLoading = false;
  String? _error;

  // getters
  DietReviewResult? get dailyReview => _dailyReview;
  Map<String, dynamic>? get weeklyReview => _weeklyReview;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 加载每日复盘
  Future<void> loadDailyReview(String date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dailyReview = await _reviewGenerator.generateDailyReview(date);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '加载复盘失败: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载周复盘
  Future<void> loadWeeklyReview(DateTime weekStart) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _weeklyReview = await _reviewGenerator.generateWeeklyReview(weekStart);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '加载周复盘失败: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 保存复盘备注
  Future<void> saveReviewNotes(String date, String notes) async {
    try {
      await _reviewGenerator.saveReviewNotes(date, notes);
      await loadDailyReview(date);
    } catch (e) {
      _error = '保存备注失败: $e';
      notifyListeners();
    }
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
