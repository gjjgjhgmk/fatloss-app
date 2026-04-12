import 'package:flutter/foundation.dart';
import '../../core/supabase/sync_service.dart';

enum SyncState {
  idle,
  syncing,
  success,
  error,
}

class SyncStatus {
  final SyncState state;
  final String? message;
  final DateTime? lastSyncTime;

  const SyncStatus({
    this.state = SyncState.idle,
    this.message,
    this.lastSyncTime,
  });

  SyncStatus copyWith({
    SyncState? state,
    String? message,
    DateTime? lastSyncTime,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      message: message ?? this.message,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  bool get isSyncing => state == SyncState.syncing;
  bool get hasError => state == SyncState.error;
  bool get isSuccess => state == SyncState.success;

  String get displayText {
    switch (state) {
      case SyncState.idle:
        if (lastSyncTime != null) {
          return '已同步 ${_formatTime(lastSyncTime!)}';
        }
        return '未同步';
      case SyncState.syncing:
        return '同步中...';
      case SyncState.success:
        return '同步成功';
      case SyncState.error:
        return message ?? '同步失败';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService = SyncService();

  SyncStatus _status = const SyncStatus();
  SyncStatus get status => _status;

  /// 触发全量同步
  Future<void> triggerSync() async {
    _status = _status.copyWith(state: SyncState.syncing, message: null);
    notifyListeners();

    try {
      await _syncService.syncAllRecentData();
      _status = _status.copyWith(
        state: SyncState.success,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      _status = _status.copyWith(
        state: SyncState.error,
        message: e.toString(),
      );
    }
    notifyListeners();
  }

  /// 触发从云端拉取
  Future<void> triggerPull() async {
    _status = _status.copyWith(state: SyncState.syncing, message: '正在从云端拉取...');
    notifyListeners();

    try {
      await _syncService.pullCloudDataToLocal();
      _status = _status.copyWith(
        state: SyncState.success,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      _status = _status.copyWith(
        state: SyncState.error,
        message: '拉取失败: $e',
      );
    }
    notifyListeners();
  }

  /// 重置状态
  void reset() {
    _status = const SyncStatus();
    notifyListeners();
  }
}
