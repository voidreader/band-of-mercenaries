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
  static const String settlementTrustUp = 'settlementTrustUp';
  static const String idleReward = 'idleReward';
  static const String achievementUnlocked = 'achievementUnlocked';
  // M6 페이즈 4 #2 — 칭호 해금 다이얼로그 (11번째)
  static const String titleUnlocked = 'titleUnlocked';
  // M7 페이즈 4 #5 — 지역 상태 변경 다이얼로그
  static const String regionStateChanged = 'regionStateChanged';
  // M7 페이즈 4 #5 — 마을 기반시설 업그레이드 다이얼로그
  static const String settlementInfrastructureUpgraded = 'settlementInfrastructureUpgraded';
  // M8a — 세력 접촉점 도착 다이얼로그 (FR-G2)
  static const String factionContactArrived = 'factionContactArrived';

  /// 등록된 전체 dialogType 키 집합. 영속 복원 시 필터링 기준으로 사용.
  static Set<String> get keys => {
    constructionComplete,
    investigationResult,
    rankUp,
    autoTravelEvent,
    travelChoiceRecall,
    chainCompleted,
    regionTransform,
    settlementTrustUp,
    idleReward,
    achievementUnlocked,
    titleUnlocked,
    regionStateChanged,
    settlementInfrastructureUpgraded,
    factionContactArrived,
  };
}

/// 전역 다이얼로그 큐 Notifier.
///
/// 인메모리 큐([DialogRequest] 리스트)를 관리하며, Hive persistence와 동기화한다.
/// 정렬 기준: [DialogPriority] 오름차순(critical 최우선) → enqueuedAt 오름차순(FIFO).
///
/// **영속 복원 전략**:
/// builder 클로저는 직렬화하지 않고, 저장된 dialogType + payload로 닫을 수 있는
/// 요약 다이얼로그를 재구성한다.
class DialogQueueNotifier extends StateNotifier<List<DialogRequest>> {
  final DialogQueuePersistence _persistence;

  /// 항목 유실 시 호출되는 콜백. reason은 'expired'·'unregistered_type'·'deserialize_error'.
  final void Function(String reason)? onLoss;

  DialogQueueNotifier(this._persistence, {this.onLoss}) : super(const []) {
    _restore();
  }

  /// 앱 시작 시 Hive 박스에서 유효한 항목을 복원한다.
  Future<void> _restore() async {
    final entries = await _persistence.loadValid(
      registeredDialogTypes: DialogTypeRegistry.keys,
      onLoss: onLoss,
    );
    if (entries.isEmpty) return;

    final restored = entries.map(_persistedToRequest).toList()..sort(_compare);
    state = restored;
    debugPrint('[BOM][DialogQueue] 시작 시 ${restored.length}건 복원');
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

  DialogRequest _persistedToRequest(PersistedDialogEntry entry) {
    final priority =
        entry.priority >= 0 && entry.priority < DialogPriority.values.length
        ? DialogPriority.values[entry.priority]
        : DialogPriority.low;
    final payload = _decodePayload(entry.payloadJson);

    return DialogRequest(
      id: entry.id,
      priority: priority,
      dialogType: entry.dialogType,
      payload: payload,
      enqueuedAt: entry.enqueuedAt,
      builder: (ctx, dismiss) => AlertDialog(
        title: const Text('놓친 알림'),
        content: Text(_restoredMessage(entry.dialogType, payload)),
        actions: [ElevatedButton(onPressed: dismiss, child: const Text('확인'))],
      ),
    );
  }

  dynamic _decodePayload(String payloadJson) {
    try {
      return jsonDecode(payloadJson);
    } catch (_) {
      onLoss?.call('deserialize_error');
      return <String, dynamic>{};
    }
  }

  String _restoredMessage(String dialogType, dynamic payload) {
    final map = payload is Map ? payload : const <String, dynamic>{};
    switch (dialogType) {
      case DialogTypeRegistry.constructionComplete:
        final name = map['facilityName'] ?? map['facilityId'] ?? '시설';
        final level = map['newLevel'];
        return level == null
            ? '$name 건설이 완료되었습니다.'
            : '$name이(가) Lv.$level(으)로 업그레이드되었습니다.';
      case DialogTypeRegistry.investigationResult:
        final mercName = map['mercName'] ?? '용병';
        return '$mercName의 지역 조사 결과가 도착했습니다.';
      case DialogTypeRegistry.rankUp:
        final toGrade = map['toGrade'];
        return toGrade == null
            ? '명성 랭크가 상승했습니다.'
            : '명성 랭크가 $toGrade 등급으로 상승했습니다.';
      case DialogTypeRegistry.autoTravelEvent:
        return '이동 중 발생한 이벤트 알림이 있습니다.';
      case DialogTypeRegistry.travelChoiceRecall:
        return '이동 중 선택지 결과 알림이 있습니다.';
      case DialogTypeRegistry.chainCompleted:
        return '연계 퀘스트가 완료되었습니다.';
      case DialogTypeRegistry.regionTransform:
        final regionId = map['regionId'];
        return regionId == null
            ? '지역 변화가 발생했습니다.'
            : '지역 $regionId에 변화가 발생했습니다.';
      case DialogTypeRegistry.settlementTrustUp:
        final toLevel = map['toLevel'];
        return toLevel == null
            ? '마을 신뢰도가 상승했습니다.'
            : '마을 신뢰도가 $toLevel단계로 상승했습니다.';
      case DialogTypeRegistry.idleReward:
        final reward = map['reward'];
        return reward == null ? '부재 보상이 도착했습니다.' : '부재 보상 ${reward}G를 획득했습니다.';
      case DialogTypeRegistry.achievementUnlocked:
        final name = map['name'];
        return name == null
            ? '용병단의 새 위업이 기록되었습니다.'
            : '용병단의 새 위업이 기록되었습니다: $name';
      case DialogTypeRegistry.titleUnlocked:
        final titleName = map['titleName'];
        return titleName == null
            ? '새 칭호가 발급되었습니다.'
            : '새 칭호가 발급되었습니다: $titleName';
      case DialogTypeRegistry.regionStateChanged:
        return '지역 상태가 변경되었습니다.';
      case DialogTypeRegistry.settlementInfrastructureUpgraded:
        return '마을의 기반시설이 업그레이드되었습니다.';
      case DialogTypeRegistry.factionContactArrived:
        final npcName = map['npcName'];
        final factionName = map['factionName'];
        return (npcName == null || factionName == null)
            ? '세력 접촉점이 새로 활성화되었습니다.'
            : '$factionName의 $npcName이(가) 도착했습니다.';
      default:
        return '표시되지 않은 알림이 있습니다.';
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
      final box = Hive.box<PersistedDialogEntry>(
        HiveInitializer.dialogQueueBoxName,
      );
      final persistence = DialogQueuePersistence(box);
      return DialogQueueNotifier(persistence);
    });
