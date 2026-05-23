import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:band_of_mercenaries/features/settlement/domain/village_facility.dart';

part 'livingsphere_dashboard_models.freezed.dart';

// =========================================================================
// Enums
// =========================================================================

/// 거점 완성도 대시보드의 6 지표 키
enum MetricKey {
  stability,         // FR-1: 안정도
  infrastructure,    // FR-2: 거점 발전
  eventCompletion,   // FR-3: 사건 완료율
  resourceCraft,     // FR-4: 자원·제작
  influence,         // FR-5: 영향력
  achievement,       // FR-6: 위업 달성률
}

/// FR-2, FR-4, FR-5, FR-6: 지표값의 표시 모드
enum MetricDisplayMode {
  percent,         // 0~100% 표시 (안정도, 거점, 사건, 자원·제작, 영향력, 위업)
  tierLevel,       // Tier 1~4 표시 (인프라 추가 정보용, 현재 미사용)
  countOverTotal,  // n/m 표시 (사건, 자원·제작, 위업 상세)
  averageStage,    // 평균 단계 표시 (추후 위임)
}

/// FR-8, FR-9: 30분 vs 8시간 목표 슬롯
enum GoalSlot {
  short30Min,
  long8Hour,
}

/// FR-8, FR-9: 12가지 목표 후보 종류 (명세 §2.2 B 본문 12종)
enum GoalCandidateKind {
  inProgressQuest,    // 진행 중 의뢰
  movement,           // 진행 중 이동
  investigation,      // 진행 중 조사
  construction,       // 진행 중 건설
  imminentTrust,      // 임박 신뢰도 임계
  imminentInfra,      // 임박 인프라 flag
  imminentRank,       // 임박 명성 랭크
  chainCompletion,    // 활성 체인 완주
  craftUnlock,        // 핵심 제작 레시피 해금
  factionJoin,        // 신규 세력 가입
  pacification,       // region_pacified 임박
  fallback,           // 기본값 (후보 없음)
}

// =========================================================================
// GoalJumpTarget — freezed sealed union (명세 §2.2 B 본문 7종)
// =========================================================================

/// FR-8~11, FR-19~21: 목표 카드의 점프 대상 (sealed union)
@freezed
sealed class GoalJumpTarget with _$GoalJumpTarget {
  /// 이동 화면 진입 (region 특정)
  const factory GoalJumpTarget.movement({int? regionId}) = GoalJumpTargetMovement;

  /// 파견 화면 진입 (특정 quest_pool 포커스)
  const factory GoalJumpTarget.dispatch({String? questPoolId}) = GoalJumpTargetDispatch;

  /// 마을 시설 화면 진입 (기본 MovementScreen)
  const factory GoalJumpTarget.settlementFacility({
    required VillageFacility facility,
    required int regionId,
  }) = GoalJumpTargetSettlementFacility;

  /// 인벤토리 화면 진입 (재료 탭, 특정 아이템 포커스)
  const factory GoalJumpTarget.inventory({String? itemId}) = GoalJumpTargetInventory;

  /// 낡은 대장간 화면 (region 3 sector 1)
  const factory GoalJumpTarget.smithy() = GoalJumpTargetSmithy;

  /// 세력 도감 진입 (특정 세력 포커스)
  const factory GoalJumpTarget.faction({String? factionId}) = GoalJumpTargetFaction;

  /// 연대기 화면 진입
  const factory GoalJumpTarget.chronicle() = GoalJumpTargetChronicle;
}

// =========================================================================
// Data Models (freezed) — Hive 영속 미사용, Provider 전용
// =========================================================================

/// FR-1~7: 단일 지표의 계산 결과
@freezed
class MetricValue with _$MetricValue {
  const factory MetricValue({
    /// 0~100 백분율
    required double percent,

    /// 표시 모드 (percent/tierLevel/countOverTotal/averageStage)
    required MetricDisplayMode displayMode,

    /// 현재값 (예: Tier 3 → 3, n/m → n)
    num? currentValue,

    /// 전체값 (예: n/m → m)
    num? totalValue,

    /// 라벨 텍스트 (예: "평온", "Tier 3", "안정 단계")
    String? label,

    /// 펼침 본문에서 UI가 추가로 조합할 요약 텍스트
    String? expandedSummary,
  }) = _MetricValue;
}

/// FR-1~7: 6 지표 통합 스냅샷
@freezed
class LivingsphereDashboardSnapshot with _$LivingsphereDashboardSnapshot {
  const factory LivingsphereDashboardSnapshot({
    /// 대시보드 대상 region ID (MVP는 항상 3)
    required int regionId,

    /// 6 지표의 계산 결과 (MetricKey → MetricValue)
    required Map<MetricKey, MetricValue> metrics,

    /// 통합 완성도 (0~100)
    required double totalCompletionPct,
  }) = _LivingsphereDashboardSnapshot;
}

/// FR-8~11: 단일 목표 후보
@freezed
class GoalCandidate with _$GoalCandidate {
  const factory GoalCandidate({
    /// 목표 ID (pinId 포맷: 'quest:{id}', 'chain:{id}' 등)
    required String id,

    /// 목표 슬롯 (30분 vs 8시간)
    required GoalSlot slot,

    /// UI에 표시할 라벨 (예: "동굴 박쥐 소탕", "대장간 개방")
    required String label,

    /// 목표의 종류
    required GoalCandidateKind kind,

    /// 기본 가중치 (50~100)
    required double baseWeight,

    /// 진행 인자 (0.0~1.0, progress_factor = 1 - remaining/max)
    required double progressFactor,

    /// 가치 인자 (0~50, 난이도·중요도 등의 정규화)
    required double valueFactor,

    /// 최종 점수 = baseWeight × clamp(progressFactor) + clamp(valueFactor)
    required double score,

    /// 점프 대상 (null이면 텍스트만 노출)
    GoalJumpTarget? jumpTarget,

    /// 핀 무효화 판정용 플래그 (의뢰 완료, 체인 완주 등으로 false 가능)
    @Default(true) bool isValid,
  }) = _GoalCandidate;
}

/// FR-10, FR-19~21: 목표 추천 결과
@freezed
class GoalRecommendation with _$GoalRecommendation {
  const factory GoalRecommendation({
    /// 목표 슬롯
    required GoalSlot slot,

    /// 자동 추천 또는 핀된 후보 (null이면 fallback 상태)
    GoalCandidate? primary,

    /// 핀 활성 여부 (primary가 pinned candidate)
    @Default(false) bool pinned,

    /// 기타 대안 후보 (최대 3개, score > 0만)
    @Default([]) List<GoalCandidate> alternatives,

    /// fallback 상태 (후보 없음 또는 모두 score <= 0)
    @Default(false) bool isFallback,

    /// 무효화된 pinId (감지되면 UI의 post-frame cleanup에서 제거)
    String? invalidatedPinId,
  }) = _GoalRecommendation;

  /// fallback 생성자
  factory GoalRecommendation.fallback(GoalSlot slot) => GoalRecommendation(
        slot: slot,
        primary: null,
        pinned: false,
        alternatives: const [],
        isFallback: true,
        invalidatedPinId: null,
      );
}
