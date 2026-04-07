import '../../core/database/hive_helper.dart';
import '../models/weight_record.dart';

class WeightRecordRepository {
  final HiveHelper _hiveHelper = HiveHelper.instance;

  /// 获取某日体重记录（早上和晚上）
  List<WeightRecord> getWeightRecordsForDate(String date) {
    return _hiveHelper.weightRecordsBoxInstance.values
        .where((r) => r.recordDate == date)
        .toList();
  }

  /// 获取早上体重记录
  WeightRecord? getMorningWeight(String date) {
    final records = _hiveHelper.weightRecordsBoxInstance.values
        .where((r) => r.recordDate == date && r.timeOfDay == 'morning')
        .toList();
    return records.isNotEmpty ? records.first : null;
  }

  /// 获取晚上体重记录
  WeightRecord? getEveningWeight(String date) {
    final records = _hiveHelper.weightRecordsBoxInstance.values
        .where((r) => r.recordDate == date && r.timeOfDay == 'evening')
        .toList();
    return records.isNotEmpty ? records.first : null;
  }

  /// 保存体重记录
  Future<void> saveWeightRecord(WeightRecord record) async {
    await _hiveHelper.weightRecordsBoxInstance.put(record.id, record);
  }

  /// 删除体重记录
  Future<void> deleteWeightRecord(String id) async {
    await _hiveHelper.weightRecordsBoxInstance.delete(id);
  }

  /// 获取日期范围内的体重记录
  List<WeightRecord> getWeightRecordsInRange(String startDate, String endDate) {
    final records = _hiveHelper.weightRecordsBoxInstance.values
        .where((r) => r.recordDate.compareTo(startDate) >= 0 && r.recordDate.compareTo(endDate) <= 0)
        .toList();
    records.sort((a, b) => a.recordDate.compareTo(b.recordDate));
    return records;
  }

  /// 获取所有体重记录
  List<WeightRecord> getAllWeightRecords() {
    final records = _hiveHelper.weightRecordsBoxInstance.values.toList();
    records.sort((a, b) => b.recordDate.compareTo(a.recordDate));
    return records;
  }
}
