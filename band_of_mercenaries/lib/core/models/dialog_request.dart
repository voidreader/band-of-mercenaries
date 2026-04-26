import 'package:flutter/widgets.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_data.dart';

/// 다이얼로그 우선순위. 큐 정렬은 critical(가장 높음) → low(가장 낮음).
enum DialogPriority {
  critical, // 용병 사망·랭크업 — barrierDismissible: false
  high, // 퀘스트 완료·변형 발동·체인 완주
  medium, // 자동 이벤트·이동 선택지·건설/조사 완료·체인 진행
  low, // 향후 확장용 (현재 미사용)
}

/// 큐에 enqueue되는 다이얼로그 요청. builder는 메모리 전용 (직렬화 불가).
class DialogRequest {
  final String id;
  final DialogPriority priority;
  final Widget Function(BuildContext context, VoidCallback onDismiss) builder;

  /// DialogTypeRegistry 키 — persistence 복원용.
  final String dialogType;

  /// jsonEncode 가능한 타입 (`Map<String, dynamic>` 권장).
  final dynamic payload;

  final DateTime enqueuedAt;

  DialogRequest({
    required this.id,
    required this.priority,
    required this.builder,
    required this.dialogType,
    required this.payload,
    DateTime? enqueuedAt,
  }) : enqueuedAt = enqueuedAt ?? DateTime.now();
}

/// 체인 퀘스트 카드 메타 정보 (배지 렌더용).
class ChainQuestInfo {
  final String chainName;
  final int currentStep;
  final int totalSteps;

  const ChainQuestInfo({
    required this.chainName,
    required this.currentStep,
    required this.totalSteps,
  });
}

/// 퀘스트 카드 시각 통합용 계층 정보.
/// LayerSidebarResolver / QuestCardBadges 양쪽이 공유.
class QuestLayerInfo {
  /// null이면 체인 단계 아님.
  final ChainQuestInfo? chain;
  final bool isElite;
  final bool isUnique;

  /// 'village' | 'ruins' | 'hidden' | null
  final String? sectorType;

  /// factionTag 매핑된 세력 (없으면 null).
  final FactionData? faction;

  /// 전용 퀘스트 여부.
  final bool isFactionExclusive;

  const QuestLayerInfo({
    this.chain,
    this.isElite = false,
    this.isUnique = false,
    this.sectorType,
    this.faction,
    this.isFactionExclusive = false,
  });
}
