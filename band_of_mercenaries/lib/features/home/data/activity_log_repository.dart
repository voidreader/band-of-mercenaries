import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/features/home/domain/activity_log_model.dart';

class ActivityLogRepository {
  static const String boxName = 'activityLogs';
  static const int maxLogs = 50;

  Box<ActivityLog> get _box => Hive.box<ActivityLog>(boxName);

  List<ActivityLog> getAll() {
    final logs = _box.values.toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  Future<void> addLog(String message, ActivityLogType type) async {
    final log = ActivityLog(
      timestamp: DateTime.now(),
      message: message,
      type: type,
    );
    await _box.add(log);

    if (_box.length > maxLogs) {
      final sorted = _box.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final toDelete = sorted.take(_box.length - maxLogs);
      for (final log in toDelete) {
        await log.delete();
      }
    }
  }
}
