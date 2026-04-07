import '../../core/database/hive_helper.dart';
import '../models/daily_review.dart';

class DailyReviewRepository {
  final HiveHelper _hiveHelper = HiveHelper.instance;

  DailyReview? getReviewByDate(String date) {
    return _hiveHelper.dailyReviewsBoxInstance.get(date);
  }

  Future<void> insertReview(DailyReview review) async {
    await _hiveHelper.dailyReviewsBoxInstance.put(review.recordDate, review);
  }

  Future<void> updateReview(DailyReview review) async {
    await _hiveHelper.dailyReviewsBoxInstance.put(review.recordDate, review);
  }

  Future<void> upsertReview(DailyReview review) async {
    await _hiveHelper.dailyReviewsBoxInstance.put(review.recordDate, review);
  }

  List<DailyReview> getReviewsInRange(String startDate, String endDate) {
    final reviews = _hiveHelper.dailyReviewsBoxInstance.values
        .where((r) => r.recordDate.compareTo(startDate) >= 0 && r.recordDate.compareTo(endDate) <= 0)
        .toList();
    reviews.sort((a, b) => a.recordDate.compareTo(b.recordDate));
    return reviews;
  }

  Future<void> deleteReview(String date) async {
    await _hiveHelper.dailyReviewsBoxInstance.delete(date);
  }
}
