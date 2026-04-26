import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:band_of_mercenaries/core/data/dialog_queue_persistence.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/models/dialog_request.dart';
import 'package:band_of_mercenaries/core/models/persisted_dialog_entry.dart';

/// dialogType String을 builder 함수로 매핑하는 정적 레지스트리.
///
/// 앱 종료 후 복원 시 [PersistedDialogEntry] → [DialogRequest] 재구축에 사용한다.
/// 실제 빌더 매핑은 app.dart가 주관하며, 본 레지스트리는 유효한 키 집합만 관리한다.
class DialogTypeRegistry {
  static const String constructionComplete = 'constructionComplete';
  static const String investigationResult = 'investigationResult';
  static const String rankUp = 'rankUp';
  static const String autoTravelEvent = 'autoTravelEvent';
  static const String travelChoiceRecall = 'travelChoiceRecall';
  static const String chainCompleted = 'chainCompleted';
  static const String regionTransform = 'regionTransform';

  /// 등록된 전체 dialogType 키 집합. 영속 복원 시 필터링 기준으로 사용.
  static Set<String> get keys => {
        constructionComplete,
        investigationResult,
        rankUp,
        autoTravelEvent,
        travelChoiceRecall,
        chainCompleted,
        regionTransform,
      };
}

/// 전역 다이얼로그 큐 Notifier.
///
/// 인메모리 큐([DialogRequest] 리스트)를 관리하며, Hive persistence와 동기화한다.
/// 정렬 기준: [DialogPriority] 오름차순(critical 최우선) → enqueuedAt 오름차순(FIFO).
///
/// **영속 복원 전략 (MVP)**:
/// 복원된 [DialogRequest]의 builder는 [SizedBox.shrink] placeholder로 설정한다.
/// 실제 위젯 생성은 app.dart가 dialogType + payload를 보고 분기 처리한다.
/// 이는 각 도메인 Provider의 startup hook에서 재 enqueue를 허용하는 방식과 병용한다.
class DialogQueueNotifier extends StateNotifier<List<DialogRequest>> {
  final DialogQueuePersistence _persistence;

  /// 항목 유실 시 호출되는 콜백. reason은 'expired'·'unregistered_type'·'deserialize_error'.
  final void Function(String reason)? onLoss;

  DialogQueueNotifier(this._persistence, {this.onLoss}) : super(const []) {
    _restore();
  }

  /// 앱 시작 시 Hive에서 유효 항목을 복원하여 큐를 초기화한다.
  Future<void> _restore() async {
    final entries = await _persistence.loadValid(
      registeredDialogTypes: DialogTypeRegistry.keys,
      onLoss: onLoss,
    );
    if (entries.isEmpty) return;

    // 복원된 항목을 DialogRequest로 변환하고 priority 기준으로 정렬한다.
    final restored = entries
        .map(_persistedToRequest)
        .whereType<DialogRequest>()
        .toList();
    restored.sort(_compare);
    state = restored;
  }

  /// 큐에 다이얼로그 요청을 추가한다.
  ///
  /// 동일 [id]가 이미 존재하면 무시한다(중복 방지).
  /// 추가 후 priority → FIFO 순으로 정렬하고 Hive에 즉시 저장한다.
  void enqueue(DialogRequest req) {
    if (state.any((r) => r.id == req.id)) return;
    final next = [...state, req];
    next.sort(_compare);
    state = next;
    // best-effort: persistence 저장 실패 시 인메모리 큐는 유지된다.
    _persistence.append(_requestToPersisted(req));
  }

  /// 큐의 첫 번째 항목(head)을 제거한다. 큐가 비어있으면 무시한다.
  void dequeue() {
    if (state.isEmpty) return;
    final head = state.first;
    state = state.sublist(1);
    _persistence.removeById(head.id);
  }

  /// priority 오름차순(critical=0 최우선), 동순위는 enqueuedAt 오름차순(FIFO).
  static int _compare(DialogRequest a, DialogRequest b) {
    final p = a.priority.index.compareTo(b.priority.index);
    if (p != 0) return p;
    return a.enqueuedAt.compareTo(b.enqueuedAt);
  }

  /// [DialogRequest] → [PersistedDialogEntry] 변환.
  /// payload 직렬화 실패 시 빈 JSON 객체로 대체한다.
  PersistedDialogEntry _requestToPersisted(DialogRequest r) {
    String payloadJson;
    try {
      payloadJson = jsonEncode(r.payload);
    } catch (_) {
      payloadJson = '{}';
    }
    return PersistedDialogEntry(
      id: r.id,
      priority: r.priority.index,
      dialogType: r.dialogType,
      payloadJson: payloadJson,
      enqueuedAt: r.enqueuedAt,
    );
  }

  /// [PersistedDialogEntry] → [DialogRequest] 변환.
  ///
  /// 등록되지 않은 dialogType은 null을 반환하여 복원 목록에서 제외된다.
  /// builder는 [SizedBox.shrink] placeholder로 설정한다.
  /// app.dart가 [dialogType] + [payload]를 참조하여 실제 위젯으로 대체한다.
  DialogRequest? _persistedToRequest(PersistedDialogEntry e) {
    if (!DialogTypeRegistry.keys.contains(e.dialogType)) return null;
    return DialogRequest(
      id: e.id,
      priority: DialogPriority.values[e.priority],
      dialogType: e.dialogType,
      payload: _safeDecode(e.payloadJson),
      enqueuedAt: e.enqueuedAt,
      // MVP: builder는 placeholder. app.dart가 dialogType + payload 기반으로 실제 다이얼로그 생성.
      builder: (ctx, dismiss) => const SizedBox.shrink(),
    );
  }

  /// JSON 디코딩 실패 시 빈 맵을 반환한다.
  dynamic _safeDecode(String json) {
    try {
      return jsonDecode(json);
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}

/// 앱 전역 다이얼로그 큐 Provider.
///
/// [DialogQueuePersistence]를 통해 Hive `dialogQueue` 박스와 동기화한다.
/// onLoss 콜백은 현재 빈 구현으로, 유실 로그 기록이 필요하면 app.dart에서
/// ref.listen 후 ActivityLogNotifier로 별도 처리한다.
final dialogQueueProvider =
    StateNotifierProvider<DialogQueueNotifier, List<DialogRequest>>((ref) {
  final box =
      Hive.box<PersistedDialogEntry>(HiveInitializer.dialogQueueBoxName);
  final persistence = DialogQueuePersistence(box);
  return DialogQueueNotifier(persistence);
});
