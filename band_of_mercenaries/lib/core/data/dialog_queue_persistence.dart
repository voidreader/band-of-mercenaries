import 'package:hive/hive.dart';

import 'package:band_of_mercenaries/core/models/persisted_dialog_entry.dart';

/// Hive `dialogQueue` 박스 wrapper.
///
/// 24시간 만료 필터링과 복원 실패 처리를 담당한다.
/// Box를 생성자 주입받아 테스트에서도 직접 사용 가능하도록 한다.
class DialogQueuePersistence {
  final Box<PersistedDialogEntry> _box;

  /// 큐 항목 만료 기준. 24시간 초과 시 복원에서 제외된다.
  static const Duration expiry = Duration(hours: 24);

  DialogQueuePersistence(this._box);

  /// 박스에서 유효한 항목만 반환한다.
  ///
  /// - 24h 초과 항목은 박스에서 삭제하고 onLoss("expired") 호출
  /// - 등록되지 않은 dialogType은 박스에서 삭제하고 onLoss("unregistered_type") 호출
  /// - 예외 발생 시 박스 비우고 onLoss("deserialize_error") 호출 후 빈 리스트 반환
  Future<List<PersistedDialogEntry>> loadValid({
    required Set<String> registeredDialogTypes,
    void Function(String reason)? onLoss,
  }) async {
    final result = <PersistedDialogEntry>[];
    try {
      final now = DateTime.now();
      final toDelete = <PersistedDialogEntry>[];
      for (final entry in _box.values) {
        final age = now.difference(entry.enqueuedAt);
        if (age > expiry) {
          toDelete.add(entry);
          onLoss?.call('expired');
          continue;
        }
        if (!registeredDialogTypes.contains(entry.dialogType)) {
          toDelete.add(entry);
          onLoss?.call('unregistered_type');
          continue;
        }
        result.add(entry);
      }
      for (final entry in toDelete) {
        await entry.delete();
      }
      return result;
    } catch (_) {
      // 역직렬화 오류 등 복원 실패 시 안전하게 박스를 비운다.
      onLoss?.call('deserialize_error');
      await _box.clear();
      return const [];
    }
  }

  /// 큐 끝에 항목 추가. 정렬은 Notifier가 책임.
  Future<void> append(PersistedDialogEntry entry) async {
    await _box.add(entry);
  }

  /// id 일치 항목 삭제.
  Future<void> removeById(String id) async {
    final targets = _box.values.where((e) => e.id == id).toList();
    for (final entry in targets) {
      await entry.delete();
    }
  }

  /// 박스 전체 비우기.
  Future<void> clear() async {
    await _box.clear();
  }

  /// 디버깅/테스트용 — 박스 내 모든 항목 스냅샷.
  List<PersistedDialogEntry> all() => _box.values.toList(growable: false);
}
