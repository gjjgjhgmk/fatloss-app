import '../../core/database/hive_helper.dart';
import '../../core/firebase/firestore_service.dart';
import '../models/waist_record.dart';

class WaistRecordRepository {
  final HiveHelper _hiveHelper = HiveHelper.instance;
  final FirestoreService _firestore = FirestoreService();

  /// 获取某日腰围记录
  WaistRecord? getWaistRecordForDate(String date) {
    return _hiveHelper.waistRecordsBoxInstance.get(date);
  }

  /// 保存腰围记录
  Future<void> saveWaistRecord(WaistRecord record) async {
    await _hiveHelper.waistRecordsBoxInstance.put(record.id, record);
    // 同步到 Firebase
    try {
      await _firestore.saveWaistRecord(record);
    } catch (_) {}
  }

  /// 删除腰围记录
  Future<void> deleteWaistRecord(String date) async {
    await _hiveHelper.waistRecordsBoxInstance.delete(date);
  }

  /// 获取日期范围内的腰围记录
  List<WaistRecord> getWaistRecordsInRange(String startDate, String endDate) {
    final records = _hiveHelper.waistRecordsBoxInstance.values
        .where((r) => r.recordDate.compareTo(startDate) >= 0 && r.recordDate.compareTo(endDate) <= 0)
        .toList();
    records.sort((a, b) => a.recordDate.compareTo(b.recordDate));
    return records;
  }

  /// 获取所有腰围记录
  List<WaistRecord> getAllWaistRecords() {
    final records = _hiveHelper.waistRecordsBoxInstance.values.toList();
    records.sort((a, b) => b.recordDate.compareTo(a.recordDate));
    return records;
  }
}
