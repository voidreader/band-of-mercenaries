# M7 페이즈 4 #4: 마을 인프라 성장 시스템 + 진입점 통합 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260517_m7_settlement_infrastructure_growth.md` (페이즈 1 #3 — 4단계 구조 + 거점 효과 컨셉)
>
> 밸런스 문서: `Docs/balance-design/[balance]20260517_m7_infrastructure_growth_curve.md` (페이즈 2 #3 — 임계 2/4/6 + multiplier + 보상 정량)
>
> 데이터 산출물: `Docs/content-data/m7_phase3_5_recipes_chain.sql` (페이즈 3 #5 — items 6 + crafting_recipes 6 + chain_m7_mist_clearing 2단계, 본 spec 적용 시 마이그레이션)
>
> 동반 spec:
> - `Docs/spec/m7_p4_1_region_state_system.md` (페이즈 4 #1 — RegionState API + toggleFlag trailing hook FR-4e + chain_m7_mist_clearing chain 매핑 FR-4b)
> - `Docs/spec/m7_p4_3_movement_ui.md` (페이즈 4 #3 — `settlementInfrastructureTierProvider` 의존 위젯 2종 — VillageVisitSection 인프라 배지 / MovementScreen 광장 이정표)
>
> 작성일: 2026-05-17

## 1. 개요

페이즈 1 #3의 4단계 인프라 성장 시스템(고립/연결/거점화/변방의 중심)을 구현한다. `RegionState`에 `infrastructureTier` HiveField 12 추가, `SettlementInfrastructureConfig` 코드 상수 모듈 신설(임계 flag 2/4/6 + 단계 전이 보상 + 외래 좌판 가격 + 광장 이정표 효과 + 8 flag 집합), `RegionStateRepository.toggleFlag` 내부에서 `_evaluateInfrastructureTransition()` 본체 활성화(페이즈 4 #1 FR-4e의 호출 지점 위임 활성), `SettlementInfrastructureUpgradedDialog`(medium priority) + ActivityLog HiveField 34 추가, `settlementInfrastructureTierProvider` family 정의(페이즈 4 #3 stub 활성화), `VillageFacility.foreignStall` 신규 enum + `ForeignStallScreen` 신규 화면(외래 상인 케일 NPC + 거래/소식/방문 횟수 3 버튼), `ChiefHouseScreen` 4번째 버튼 "생활권 정보" 추가(Tier 2+), `HerbalistService` infra 인자 확장(곱셈 합산 — cost/cooldown/gathering), `CraftingService.evaluateState` 신규 4 type(`regionFlag`/`infrastructureTier`/`all`/`any`) 분기 추가, 페이즈 3 #5 SQL 적용(items 6 + crafting_recipes 6 + chain_m7_mist_clearing 2단계), 페이즈 4 #1 FR-4b chain 매핑에 `chain_m7_mist_clearing` 활성화. Tier 4 진입 시 위업 "변방의 영주" 발급(`infrastructure_tier:tier_4` template_id).

## 2. 요구사항

### 2.1 기능 요구사항

#### FR-1: `RegionState.infrastructureTier` HiveField 12 추가

- **위치**: `features/investigation/domain/region_state_model.dart`
- **HiveField 점유 확인** (CLAUDE.md 표 + 동반 spec 점유):
  - 페이즈 4 #1: 8(dangerScore), 9(dangerLevel), 10(unlockedFlags)
  - 페이즈 4 #2: 11(questPoolCompletionCounts)
  - **본 spec: HiveField 12 (infrastructureTier)** — 충돌 없음
- **필드 추가**:
  ```dart
  /// M7 페이즈 4 #4 — 마을 인프라 단계 (1~4)
  /// null = 1 fallback (Tier 1: 고립). region 3 한정 사용 (다른 region은 null 유지).
  @HiveField(12)
  int? infrastructureTier;

  int get currentInfrastructureTier => infrastructureTier ?? 1;
  ```
- 생성자 인자 + nullable 처리.
- build_runner 재실행 필요: `region_state_model.g.dart`.
- 다음 HiveField: 13.
- 기존 사용자 세이브 호환 — nullable + fallback.

#### FR-2: `SettlementInfrastructureConfig` 신규 상수 모듈

- **위치**: `features/settlement/domain/settlement_infrastructure_config.dart` 신규.
- **내용** (페이즈 2 #3 6절 코드 상수 그대로 채택):
  ```dart
  class SettlementInfrastructureConfig {
    // 임계 flag 수 (Tier → 필요 flag 합) — 페이즈 2 #3 1절 채택
    static const Map<int, int> infraTierThresholds = {1: 0, 2: 2, 3: 4, 4: 6};

    // 단계 전이 일회성 보상 — 페이즈 2 #3 6절
    static const Map<int, ({int gold, int xp, int rep})> infraTierRewards = {
      2: (gold: 100, xp: 100, rep: 50),
      3: (gold: 200, xp: 200, rep: 100),
      4: (gold: 500, xp: 500, rep: 300),
    };

    // 한국어 단계명 (페이즈 1 #3 1.1절)
    static const Map<int, String> infraTierNames = {
      1: '고립', 2: '연결', 3: '거점화', 4: '변방의 중심',
    };

    // M7 인프라 관련 8개 flag (페이즈 1 #2 1.3절)
    static const Set<String> infrastructureRelevantFlags = {
      'region_3_pyegwang_reopen_completed',
      'region_31_bandits_cleared',
      'region_31_shrine_quest_completed',
      'region_127_nomad_friendly',
      'region_9_giant_beast_killed',
      'region_10_windrunner_chain_completed',
      'region_146_mist_cleared',
      'region_38_ironbound_pact_completed',
    };

    // 외래 좌판 거래 기본 가격 (Tier 3 기준)
    static const Map<String, int> foreignStallBasePrices = {
      'mat_herb_wildflower': 60,
      'mat_herb_seaweed': 60,
      'mat_hide_nomad_strap': 120,
      'mat_herb_wind': 150,
      'mat_herb_poison': 150,
      'mat_relic_swamp_seal': 200,
      'mat_relic_burnt_seal': 250,
      'mat_relic_ancient_seal_piece': 300,
    };

    // Tier 4 할인율 (-20%)
    static const double foreignStallTier4Discount = 0.80;

    // Tier 3·4 거래 가능 종류 수 (페이즈 2 #3 5절)
    static const int foreignStallTier3VarietyCap = 3;
    static const int foreignStallTier4VarietyCap = 6;

    // 광장 이정표 (페이즈 2 #3 3절)
    static const double signpostDistanceMultiplier = 0.90; // -10%
    static const int signpostMinTier = 2;

    // 단계 전이 → infra Tier 계산 (페이즈 1 #3 3.2절 _resolveTier)
    static int resolveTier(int flagCount) {
      if (flagCount >= infraTierThresholds[4]!) return 4;
      if (flagCount >= infraTierThresholds[3]!) return 3;
      if (flagCount >= infraTierThresholds[2]!) return 2;
      return 1;
    }
  }
  ```

#### FR-3: `settlementInfrastructureTierProvider` Provider family 정의 (페이즈 4 #3 stub 활성화)

- **위치**: `features/settlement/domain/settlement_infrastructure_provider.dart` 신규.
- **내용**:
  ```dart
  /// M7 페이즈 4 #4 — 마을 인프라 단계 동기 조회.
  /// 페이즈 4 #3 spec에서 stub 호출 → 본 spec에서 실 정의.
  final settlementInfrastructureTierProvider =
      Provider.family<int, int>((ref, regionId) {
    final repo = ref.watch(regionStateRepositoryProvider);
    final state = repo.getState(regionId);
    return state?.currentInfrastructureTier ?? 1;
  });
  ```
- 페이즈 4 #3 spec FR-4(광장 이정표 -10%) / FR-8(VillageVisitSection 인프라 배지)의 stub graceful degradation이 본 spec 적용 시 자동 활성.

#### FR-4: `RegionStateRepository._evaluateInfrastructureTransition()` 본체 + `toggleFlag` trailing 활성화 (페이즈 4 #1 FR-4e 위임 활성)

- **위치**: `features/investigation/data/region_state_repository.dart`
- **내부 메서드 추가** (페이즈 1 #3 3.2절 패턴):
  ```dart
  /// M7 페이즈 4 #4 — toggleFlag trailing에서 호출. region 3 인프라 단계 전이 평가.
  Future<InfrastructureUpgradeEvent?> _evaluateInfrastructureTransition({
    required Ref ref,
  }) async {
    final r3State = getOrCreateRegionState(GameConstants.startingRegionId);
    final currentTier = r3State.currentInfrastructureTier;

    // 7리전(M7 핵심) unlockedFlags 합산 (8개 flag 한정)
    int flagCount = 0;
    for (final regionId in const [3, 31, 127, 9, 10, 146, 38]) {
      final state = getState(regionId);
      if (state == null) continue;
      for (final flag in state.unlockedFlags) {
        if (SettlementInfrastructureConfig.infrastructureRelevantFlags.contains(flag)) {
          flagCount++;
        }
      }
    }

    final nextTier = SettlementInfrastructureConfig.resolveTier(flagCount);
    if (nextTier <= currentTier) return null;

    // 단계 갱신
    r3State.infrastructureTier = nextTier;
    await r3State.save();

    // 통과한 모든 Tier 보상 합산 (M4 addSettlementTrust 패턴)
    int rewardGold = 0, rewardXp = 0, rewardRep = 0;
    for (int tier = currentTier + 1; tier <= nextTier; tier++) {
      final r = SettlementInfrastructureConfig.infraTierRewards[tier];
      if (r == null) continue;
      rewardGold += r.gold;
      rewardXp += r.xp;
      rewardRep += r.rep;
    }
    if (rewardGold > 0) await ref.read(userDataProvider.notifier).addGold(rewardGold);
    if (rewardRep > 0) await ref.read(userDataProvider.notifier).addReputation(rewardRep);
    if (rewardXp > 0) await _grantXpEvenly(ref, rewardXp);

    // ActivityLog
    final tierName = SettlementInfrastructureConfig.infraTierNames[nextTier] ?? '';
    ref.read(activityLogProvider.notifier).addLog(
      '더스트빌이 [$nextTier단계: $tierName] 단계로 발전했다',
      ActivityLogType.settlementInfrastructureUpgraded,
    );

    // 위업 hook — Tier 4 진입 시 "변방의 영주" (FR-9)
    List<String> grantedAchievements = const [];
    if (nextTier == 4) {
      try {
        final granted = await ref.read(achievementServiceProvider).grant(
          'infrastructure_tier:tier_4',
          regionId: GameConstants.startingRegionId,
          payload: {'fromTier': currentTier, 'toTier': nextTier, 'flagCount': flagCount},
        );
        if (granted != null) grantedAchievements = ['infrastructure_tier:tier_4'];
      } on Exception catch (e) {
        debugPrint('[M7][Achievement] infrastructure_tier grant 실패: $e');
      }
    }

    // 퀘스트 풀 갱신 (신규 레시피·외래 좌판 노출 즉시 반영)
    await ref.read(questListProvider.notifier).refreshAvailableQuests();

    return InfrastructureUpgradeEvent(
      fromTier: currentTier,
      toTier: nextTier,
      rewardGold: rewardGold > 0 ? rewardGold : null,
      rewardXp: rewardXp > 0 ? rewardXp : null,
      rewardReputation: rewardRep > 0 ? rewardRep : null,
      grantedAchievements: grantedAchievements,
    );
  }
  ```
- **`toggleFlag` trailing 활성화** (페이즈 4 #1 spec FR-4e의 "본 spec은 hook 호출 지점만 명세, 실제 인프라 전이 로직은 페이즈 4 #4 spec" 위임 본체):
  - 페이즈 4 #1 FR-3의 `toggleFlag(regionId, flag, ref)` 메서드 내부 멱등 추가·ActivityLog 직후 trailing 추가:
    ```dart
    // M7 페이즈 4 #4 — 인프라 단계 전이 평가 (fail-soft)
    try {
      final event = await _evaluateInfrastructureTransition(ref: ref);
      if (event != null) {
        ref.read(settlementInfrastructureUpgradedProvider.notifier).state = event;
      }
    } on Exception catch (e) {
      debugPrint('[M7][Infrastructure] transition 평가 실패: $e');
    }
    ```
- **호출 시점**: M7 핵심 7리전 중 어느 region이든 `toggleFlag`로 8 flag 중 하나 토글 시 자동 평가. 임계 미달 시 자동 skip(`nextTier <= currentTier`).

#### FR-5: `InfrastructureUpgradeEvent` + `settlementInfrastructureUpgradedProvider` + `SettlementInfrastructureUpgradedDialog`

- **`InfrastructureUpgradeEvent`** (`features/settlement/domain/infrastructure_upgrade_event.dart` 신규):
  ```dart
  class InfrastructureUpgradeEvent {
    final int fromTier;
    final int toTier;
    final int? rewardGold;
    final int? rewardXp;
    final int? rewardReputation;
    final List<String> grantedAchievements;

    const InfrastructureUpgradeEvent({
      required this.fromTier,
      required this.toTier,
      this.rewardGold,
      this.rewardXp,
      this.rewardReputation,
      this.grantedAchievements = const [],
    });
  }
  ```
- **Provider** (`features/settlement/domain/infrastructure_upgrade_provider.dart` 신규):
  ```dart
  final settlementInfrastructureUpgradedProvider =
      StateProvider<InfrastructureUpgradeEvent?>((ref) => null);
  ```
- **DialogTypeRegistry 확장** (`core/providers/dialog_queue_provider.dart` 라인 24 직후):
  ```dart
  static const String settlementInfrastructureUpgraded = 'settlementInfrastructureUpgraded';
  ```
- **`SettlementInfrastructureUpgradedDialog`** (`core/widgets/settlement_infrastructure_upgraded_dialog.dart` 신규):
  - AlertDialog (Material 3 기본) > Column(mainAxisSize: min) > [타이틀 + 단계명 + 본문 + 보상 표시(있을 시) + 위업 알림(Tier 4)] + actions: [TextButton('확인')].
  - 타이틀: `"{tierName} 단계 진입"` (예: "거점화 단계 진입")
  - 본문 (페이즈 3 #5 narrative 톤):
    - Tier 2: "광장에 새 이정표가 세워졌다. 외지 용병의 활약이 마을에 변화를 가져온다."
    - Tier 3: "외래 상인의 좌판이 광장에 들어섰다. 더스트빌이 변방 생활권의 거점이 되어간다."
    - Tier 4: "광장에 영구 잔치 분위기가 감돈다. 더스트빌이 변방의 중심으로 자리매김했다."
  - 보상 표시: rewardGold/Xp/Rep이 null이 아닌 항목만 "💰 {N}G" / "⭐ {N}XP" / "🎖️ {N} 명성".
  - 위업 표시 (Tier 4 한정): "🏆 위업 '변방의 영주' 획득"
- **medium priority + barrierDismissible: true** (페이즈 1 #3 3.4절).
- **이벤트 채널 패턴**: `app.dart` ref.listen → `dialogQueue.enqueue(settlementInfrastructureUpgraded, payload)` → 즉시 `provider.state = null` 리셋 (페이즈 4 #1 spec FR-5 동일 패턴 답습).

#### FR-6: `ActivityLogType.settlementInfrastructureUpgraded` HiveField 34

- **위치**: `core/domain/activity_log_model.dart`
- **HiveField 점유 확인**:
  - 페이즈 4 #1: 32(regionDangerLevelChanged), 33(regionUnlockedFlagToggled)
  - **본 spec: HiveField 34 (settlementInfrastructureUpgraded)** — 충돌 없음
- **enum 추가**:
  ```dart
  @HiveField(34)
  settlementInfrastructureUpgraded,
  ```
- 다음 HiveField: 35.
- build_runner 재실행: `activity_log_model.g.dart`.

#### FR-7: `VillageFacility.foreignStall` enum 확장 + `ForeignStallScreen` 신규

- **`VillageFacility` enum 확장** (`features/settlement/domain/village_facility.dart`):
  ```dart
  enum VillageFacility {
    chiefHouse,
    oldSmithy,
    herbalist,
    foreignStall, // M7 페이즈 4 #4 — Tier 3 신설
  }
  ```
- **`ForeignStallScreen`** (`features/settlement/view/foreign_stall_screen.dart` 신규):
  - 진입 조건: `infraTier >= 3` 시 `VillageVisitSection`이 `_FacilityCard`로 노출 (FR-8). Tier 2 이하는 미노출.
  - 위젯 계층: `Column(crossAxisAlignment: stretch)` > [_NpcHeader(케일 인사말) + 3 ActionButton (재료 거래·외래 소식·방문 횟수) + 닫기].
  - **재료 거래 버튼**: `SettlementInfrastructureConfig.foreignStallBasePrices` 8종 중 Tier 3은 처음 3종(varietyCap=3) / Tier 4는 6종(varietyCap=6) 노출. 가격은 Tier 4일 때 `× foreignStallTier4Discount`(0.80) 적용. 구매 시 `userDataProvider.notifier.spendGold(price)` + `inventoryRepository.addItem(itemId, 1)` + ActivityLog `foreignStallTrade` (HiveField 35 신규 추가 — FR-6 확장 또는 inline log 사용).
    - **간소화**: ActivityLog 새 HiveField 추가 부담 회피 — `mercenaryDismiss` 패턴처럼 일반 ActivityLog로 처리 또는 `craftCompleted`와 유사 카테고리. 본 spec 채택: **별도 HiveField 미추가, `inventoryStackCapped`와 동일 카테고리로 처리 — 단순 텍스트 메시지 "외래 좌판에서 {itemName} 구매"** ([Q-7] 참조).
  - **외래 소식 버튼**: 페이즈 3 #5 narrative 텍스트 5~7행 중 무작위 1행 표시 (AlertDialog). 본 spec 코드 상수 `foreignMerchantGossip` Map<int, List<String>> (Tier 3/Tier 4 분리, 페이즈 3 #5 m7_phase3_5_narrative.md 텍스트 인용 — 본 spec 4.4절 인용표 참조).
  - **방문 횟수 버튼**: `UserData.foreignStallVisitCount` HiveField 27 신규 추가(M6 페이즈 4 #3 26번 다음). 진입 시마다 +1. AlertDialog로 누적 횟수 표시.
- **외래 상인 케일 NPC 인사말** (페이즈 3 #5 narrative):
  - Tier 3: "외지 손님, 이런 변방까지 오느라 수고했네. 내가 가진 물건들을 한 번 보겠나?"
  - Tier 4: "어서 오시오, 변방의 영주여. 이제 자네를 위해 따로 마련한 물건들이 있다네."

#### FR-8: `VillageVisitSection` Tier 3+ `foreignStall` 카드 노출 분기 + 인프라 배지 (페이즈 4 #3 FR-8 활성)

- **위치**: `features/settlement/view/village_visit_section.dart` 라인 90~112 (3개 _FacilityCard 직후).
- **추가 분기**:
  ```dart
  // M7 페이즈 4 #4 — Tier 3+ 외래 좌판 카드 노출
  final infraTier = ref.watch(settlementInfrastructureTierProvider(GameConstants.startingRegionId));
  if (infraTier >= 3) ...[
    const SizedBox(height: 10),
    _FacilityCard(
      facility: VillageFacility.foreignStall,
      emoji: '🛒',
      title: '외래 좌판',
      subtitle: '외래 상인 케일의 좌판 (재료 거래·외래 소식)',
      onSelect: onSelect,
    ),
  ],
  ```
- **`selectedFacility` switch case 확장** (라인 36~40):
  ```dart
  VillageFacility.foreignStall => ForeignStallScreen(onClose: onClose),
  ```
- **인프라 배지**: 페이즈 4 #3 spec FR-8에서 이미 명세된 위치 + `_infrastructureLabel` 정적 헬퍼는 이제 정상 동작 (provider stub 미적용 → 실 값 반환).

#### FR-9: `ChiefHouseScreen` 4번째 버튼 "생활권 정보" 추가 (Tier 2+)

- **위치**: `features/settlement/view/chief_house_screen.dart` 라인 52~53 (`_DisabledRewardButton` 직후, 라인 54 SizedBox 직전).
- **추가 분기**:
  ```dart
  // M7 페이즈 4 #4 — Tier 2+ 생활권 정보 버튼
  final infraTier = ref.watch(settlementInfrastructureTierProvider(GameConstants.startingRegionId));
  if (infraTier >= 2) ...[
    const SizedBox(height: 8),
    _ActionButton(
      label: '생활권 정보',
      onTap: () => _showLivingsphereDialog(context, ref),
    ),
  ],
  ```
- **`_showLivingsphereDialog`** 메서드 추가:
  - AlertDialog 본문: M7 7리전 각각의 `regionName` + dangerLevel 한국어 라벨(페이즈 4 #1 FR-2) + unlockedFlags 진행도(`X/8`). 페이즈 4 #1 + 페이즈 4 #3 API 활용.
  - Tier 3+ 시 추가 카드: "외래 소식" 1줄 (Tier 3 narrative). Tier 4+ 시 "M8 풍문" 1줄 (페이즈 3 #5 narrative — M8 빌드업 — stub 텍스트).
- 페이즈 1 #3 2.1절 컨셉 정합. "다음 사건 추천 알고리즘"은 본 spec 범위 외 (M7 MVP에서 정적 텍스트만).

#### FR-10: `HerbalistService` infra 인자 확장 (곱셈 합산)

- **위치**: `features/settlement/domain/herbalist_service.dart`
- **신규 상수 추가** (페이즈 2 #3 2절):
  ```dart
  static const Map<int, double> _infraCostMultipliers = {1: 1.0, 2: 1.0, 3: 0.9, 4: 0.8};
  static const Map<int, double> _infraGatheringMultipliers = {1: 1.0, 2: 1.05, 3: 1.10, 4: 1.20};
  static const Map<int, double> _infraCooldownMultipliers = {1: 1.0, 2: 1.0, 3: 0.85, 4: 0.70};
  ```
- **메서드 시그니처 확장** (기본값 1로 하위호환):
  ```dart
  static int calculateCost(int trustLevel, {int infraTier = 1}) {
    final base = 50;
    final trust = _costMultipliers[trustLevel] ?? 1.0;
    final infra = _infraCostMultipliers[infraTier] ?? 1.0;
    return (base * trust * infra).round();
  }

  static int calculateCooldownMinutes(int trustLevel, {int infraTier = 1}) {
    final baseMin = _cooldownMinutes[trustLevel] ?? 45;
    final infra = _infraCooldownMultipliers[infraTier] ?? 1.0;
    return (baseMin * infra).round();
  }

  static double gatheringMultiplier(int trustLevel, {int infraTier = 1}) {
    final trust = _gatheringMultipliers[trustLevel] ?? 1.0;
    final infra = _infraGatheringMultipliers[infraTier] ?? 1.0;
    return trust * infra;
  }
  ```
- **호출자 갱신**: 기존 `HerbalistService.calculateCost(trustLevel)` 호출 지점에 `infraTier` 인자 추가:
  - `HerbalistScreen` (`features/settlement/view/herbalist_screen.dart`)에서 `ref.watch(settlementInfrastructureTierProvider(regionId))`로 조회 후 전달.
  - `quest_completion_service.dart:202` `HerbalistService.gatheringMultiplier(currentTrustLevel)` 호출에 `infraTier` 추가. region 3 한정이므로 `currentRegion == 3` 분기에서만 ref.read로 infraTier 조회 후 전달.

#### FR-11: `CraftingService.evaluateState` 신규 4 type 분기 + `RecipeUnlockCondition` freezed 확장

- **위치**:
  - 모델: `features/crafting/domain/crafting_recipe_data.dart` (현재 라인 40~48 `RecipeUnlockCondition` freezed).
  - 서비스: `features/crafting/domain/crafting_service.dart` (라인 56~95 `evaluateState`).
- **두 형식 공존 처리 정책** — M5 기존 형식 (`{"trust_level":N}`/`{"chain_step":{...}}`/`{"first_acquired_item":"..."}`) + M7 신규 형식 (`{"type":"regionFlag","flag":"..."}`/`{"type":"infrastructureTier","value":N}`/`{"type":"all","conditions":[...]}`/`{"type":"any","conditions":[...]}`):
  - **`RecipeUnlockCondition` freezed 확장** — 신규 필드 5개 추가 (모두 nullable, 기존 3 필드는 보존):
    ```dart
    @freezed
    class RecipeUnlockCondition with _$RecipeUnlockCondition {
      const factory RecipeUnlockCondition({
        // M5 기존 (type 필드 없는 형식 — null trust_level/chain_step/first_acquired_item)
        @JsonKey(name: 'trust_level') int? trustLevel,
        @JsonKey(name: 'chain_step') ChainStepCondition? chainStep,
        @JsonKey(name: 'first_acquired_item') String? firstAcquiredItem,

        // M7 신규 (type discriminator 형식)
        String? type, // 'regionFlag' / 'infrastructureTier' / 'all' / 'any'
        String? flag, // type='regionFlag'
        int? value,   // type='infrastructureTier'
        List<RecipeUnlockCondition>? conditions, // type='all' / 'any'
      }) = _RecipeUnlockCondition;

      factory RecipeUnlockCondition.fromJson(Map<String, dynamic> json) =>
          _$RecipeUnlockConditionFromJson(json);
    }
    ```
  - build_runner 재실행: `crafting_recipe_data.freezed.dart`/`.g.dart`.
- **`evaluateState` 분기 확장** (라인 56~95):
  ```dart
  RecipeState evaluateState(CraftingRecipeData recipe) {
    final condition = recipe.unlockCondition;
    if (condition != null) {
      // M7 신규 type 분기 (페이즈 4 #4) — type 필드 존재 시 우선
      if (condition.type != null) {
        if (!_isUnlockedM7(condition)) return RecipeState.locked;
      } else {
        // M5 기존 — trustLevel/chainStep/firstAcquiredItem
        if (condition.trustLevel != null) {
          final trust = regionStateRepository
              .getSettlementTrust(GameConstants.startingRegionId);
          if (trust.level < condition.trustLevel!) return RecipeState.locked;
        }
        if (condition.chainStep != null) {
          final chainStep = condition.chainStep!;
          final progress = chainQuestRepository.get(chainStep.chainId);
          final unlocked = progress != null &&
              progress.status == ChainQuestStatus.completed &&
              progress.currentStep > chainStep.step;
          if (!unlocked) return RecipeState.locked;
        }
        if (condition.firstAcquiredItem != null) {
          final regionState =
              regionStateRepository.getState(GameConstants.startingRegionId);
          final acquired = regionState?.firstAcquiredMaterialIds
                  .contains(condition.firstAcquiredItem!) ??
              false;
          if (!acquired) return RecipeState.locked;
        }
      }
    }

    // 재료 보유량 평가 (M5 기존 패턴 보존)
    for (final input in recipe.inputs) {
      final qty = inventoryRepository.getQuantityForItemId(input.itemId);
      if (qty < input.quantity) return RecipeState.insufficient;
    }
    return RecipeState.ready;
  }

  /// M7 신규 type 분기 평가 (재귀 — all/any 지원)
  bool _isUnlockedM7(RecipeUnlockCondition condition) {
    switch (condition.type) {
      case 'regionFlag':
        final flag = condition.flag;
        if (flag == null) return false;
        // M7 핵심 7리전 중 flag 보유 region 검색
        for (final regionId in const [3, 31, 127, 9, 10, 146, 38]) {
          final state = regionStateRepository.getState(regionId);
          if (state?.unlockedFlags.contains(flag) == true) return true;
        }
        return false;
      case 'infrastructureTier':
        final value = condition.value;
        if (value == null) return false;
        final r3 = regionStateRepository.getState(GameConstants.startingRegionId);
        final tier = r3?.currentInfrastructureTier ?? 1;
        return tier >= value;
      case 'all':
        final conds = condition.conditions;
        if (conds == null || conds.isEmpty) return false;
        return conds.every(_isUnlockedM7);
      case 'any':
        final conds = condition.conditions;
        if (conds == null || conds.isEmpty) return false;
        return conds.any(_isUnlockedM7);
      default:
        return false; // 미지의 type silent fail (잠금 유지)
    }
  }
  ```

#### FR-12: 페이즈 3 #5 SQL 마이그레이션 적용 (items 6 + crafting_recipes 6 + chain_m7_mist_clearing 2단계)

- `Docs/content-data/m7_phase3_5_recipes_chain.sql` 그대로 적용. 단일 트랜잭션:
  - (A) `items` 6행 INSERT (M7 신규 레시피 결과 아이템 — placeholder effect_json 그대로).
  - (B) `crafting_recipes` 6행 INSERT (M7 신규 6 레시피, M5 unlock_condition 확장).
  - (C) `chain_quests` 2행 INSERT (chain_m7_mist_clearing 2단계).
  - (D) 검증 DO 블록 3종.
- 적용 후 `data_versions` 수동 갱신:
  ```sql
  UPDATE data_versions SET version = version + 1 WHERE table_name IN ('items', 'crafting_recipes', 'chain_quests');
  ```
- **placeholder effect_json**: items 6행 모두 placeholder. 본 spec FR-13에서 최종 확정 (별도 SQL UPDATE).

#### FR-13: items 6행 `effect_json` 최종 확정 (placeholder 대체)

- 페이즈 3 #5 SQL이 placeholder 보유 (`{"str":3}` 등 단순). 본 spec implement 시 별도 SQL UPDATE:
  ```sql
  UPDATE items SET effect_json = '{"str":3,"hit":2}'::jsonb WHERE id = 'equip_weapon_beast_tool';
  UPDATE items SET effect_json = '{"recovery_seconds":300,"cooldown_minutes":30}'::jsonb WHERE id = 'cons_wildflower_oil';
  UPDATE items SET effect_json = '{"vit":3,"injury_resist":0.05}'::jsonb WHERE id = 'equip_armor_nomad';
  UPDATE items SET effect_json = '{"recovery_seconds":600,"cooldown_minutes":45}'::jsonb WHERE id = 'cons_seaweed_tonic';
  UPDATE items SET effect_json = '{"reputation_gain_modifier":0.07}'::jsonb WHERE id = 'guild_artifact_swamp_seal';
  UPDATE items SET effect_json = '{"recruit_high_tier_chance":0.03}'::jsonb WHERE id = 'guild_artifact_burnt_seal';
  ```
- **수치는 페이즈 1 #3 4절 컨셉 + M5 패턴 답습**. 세부 수치는 페이즈 4 #4 [Q-1] 권장.

#### FR-14: 페이즈 4 #1 FR-4b `chain_m7_mist_clearing` 활성화

- 페이즈 4 #1 spec FR-4b 매핑 표에 `chain_m7_mist_clearing → region 146, -50 특수 단발, flag region_146_mist_cleared` 이미 등록됨. 본 spec FR-12에서 페이즈 3 #5 SQL 적용 시 chain 데이터가 존재 → 페이즈 4 #1 trailing이 자동 활성.
- **구현 변경 없음** — 페이즈 4 #1 spec implement 시점에 이미 매핑 등록됨, 본 spec은 데이터만 활성화.

#### FR-15: `band_achievement_templates` 1행 신규 INSERT — "변방의 영주"

- **신규 행**:
  | template_id | category | name | description | hook_type | hook_value |
  |------------|---------|------|-------------|-----------|-----------|
  | infrastructure_tier:tier_4 | infrastructure_growth | 변방의 영주 | 더스트빌이 변방의 중심으로 자리매김했다. | infrastructure_tier | tier_4_reached |
- **SQL 마이그레이션**:
  ```sql
  INSERT INTO band_achievement_templates (id, category, name, description, hook_type, hook_value) VALUES
    ('infrastructure_tier:tier_4', 'infrastructure_growth', '변방의 영주', '더스트빌이 변방의 중심으로 자리매김했다.', 'infrastructure_tier', 'tier_4_reached');
  ```
- **AchievementService 동작**: 페이즈 4 #1 spec FR-7과 동일 — hook_type 분기 로직 없음, template_id 매칭만으로 grant. 본 spec FR-4에서 `grant('infrastructure_tier:tier_4', ...)` 호출.
- **AchievementUnlockedDialog** (M6 페이즈 4 #1) — high priority 자동 발동 (변경 없음).
- 적용 후 `data_versions` 갱신:
  ```sql
  UPDATE data_versions SET version = version + 1 WHERE table_name = 'band_achievement_templates';
  ```

#### FR-16: `UserData.foreignStallVisitCount` HiveField 27 추가 (외래 좌판 방문 누적)

- **위치**: `core/models/user_data.dart`
- **HiveField 점유 확인** — M6 페이즈 4 #3에서 26(namedQuestCooldowns) 점유. 본 spec **HiveField 27**.
- **필드 추가**:
  ```dart
  /// M7 페이즈 4 #4 — 외래 좌판 방문 누적 (foreignStall facility 진입 시 +1)
  @HiveField(27)
  int foreignStallVisitCount;
  ```
- 생성자 default `0`.
- build_runner 재실행: `user_data.g.dart`.
- **사용처**: ForeignStallScreen 진입 시 `userDataProvider.notifier.incrementForeignStallVisit()` → UserData.foreignStallVisitCount += 1 → save. 메서드 신규 추가.

### 2.2 데이터 요구사항

#### Hive 박스 / 모델

- **`RegionState`** (typeId 8): HiveField 12 (infrastructureTier) 추가. 다음 13.
- **`UserData`** (typeId 5): HiveField 27 (foreignStallVisitCount) 추가. 다음 28.
- **`ActivityLogType`** enum (typeId 6): HiveField 34 (settlementInfrastructureUpgraded). 다음 35.
- **`VillageFacility`** enum (typeId 없음 — code enum): foreignStall 추가 (3 → 4 case).
- **`RecipeUnlockCondition`** freezed 확장: type/flag/value/conditions 4 nullable 필드 추가.
- build_runner 재실행 4종: `region_state_model.g.dart`, `user_data.g.dart`, `activity_log_model.g.dart`, `crafting_recipe_data.freezed.dart/.g.dart`.

#### Supabase 정적 데이터

- `items` 6행 INSERT (페이즈 3 #5 SQL) + 6행 effect_json UPDATE (FR-13).
- `crafting_recipes` 6행 INSERT (페이즈 3 #5 SQL).
- `chain_quests` 2행 INSERT (chain_m7_mist_clearing 2단계).
- `band_achievement_templates` 1행 INSERT (변방의 영주 — FR-15).
- `data_versions` 4개 항목 갱신 (items / crafting_recipes / chain_quests / band_achievement_templates).

#### 신규 enum / 클래스 / 위젯 / Provider

- `SettlementInfrastructureConfig` 정적 상수 클래스.
- `InfrastructureUpgradeEvent` 페이로드 클래스.
- `settlementInfrastructureTierProvider` Provider.family<int, int>.
- `settlementInfrastructureUpgradedProvider` StateProvider<InfrastructureUpgradeEvent?>.
- `SettlementInfrastructureUpgradedDialog` Widget.
- `ForeignStallScreen` ConsumerWidget.

#### 밸런스 수치 (페이즈 2 #3)

- 임계 flag 수: Tier 2=2, Tier 3=4, Tier 4=6 (페이즈 2 #3 1절).
- 단계 전이 보상: 100/200/500 골드 + 100/200/500 XP + 50/100/300 명성 (페이즈 2 #3 6절).
- 외래 좌판 가격 8종 (페이즈 2 #3 5절).
- Tier 4 할인율 0.80 (-20%).
- 광장 이정표 0.90 (-10%, Tier 2+).
- HerbalistService infra multiplier 3종.

### 2.3 UI 요구사항

#### SettlementInfrastructureUpgradedDialog

- **화면 진입 조건**: `settlementInfrastructureUpgradedProvider`에 `event != null` 발생 시 `app.dart` ref.listen → `dialogQueue.enqueue(settlementInfrastructureUpgraded, payload)` → 큐 head 도달 시 자동 표시.
- **위젯 계층**: `AlertDialog` > `Column(mainAxisSize: min)` > [Text(타이틀 큰 글씨) + SizedBox + Text(본문) + 보상 Container(있을 시) + 위업 Container(Tier 4)] + actions: [TextButton('확인')].
- **상태 변수**: 없음 (read-only payload).
- **화면 전환**: dialogQueue 큐 패턴. dismiss는 큐 책임.
- **CLAUDE.md 제약**: enqueue 직후 즉시 provider.state = null 리셋.
- **medium priority + barrierDismissible: true**.

#### ForeignStallScreen (Tier 3 신설)

- **화면 진입 조건**: VillageVisitSection에서 `infraTier >= 3` 시 `_FacilityCard` 노출 → onTap → `selectedFacility = foreignStall` setState.
- **위젯 계층**: `Column(crossAxisAlignment: stretch)` > [_NpcHeader(케일 인사말) + 3 _ActionButton + SizedBox + OutlinedButton(닫기)].
- **상태 변수**: `selectedFacility` (VillageVisitSection에서 관리).
- **화면 전환**: 상태 기반 렌더링 (Navigator.push 미사용) — 기존 거점 화면 3종 패턴 답습.
- **연출**: 기본 fade-in.
- **재료 거래 다이얼로그**: `AlertDialog` > `ListView` > N개 거래 카드 (재료명 + 가격 + [구매] 버튼). 구매 시 BuildContext mounted check + 토스트.

#### ChiefHouseScreen "생활권 정보" 다이얼로그 (Tier 2+)

- **AlertDialog** > `SingleChildScrollView` > `Column` > [타이틀 + 7리전 카드 (각 region 1행) + Tier 4 풍문 1줄(Tier 4 시)].
- 각 region 카드: regionName + dangerLevel 한국어 라벨 (page 4 #1 FR-2) + unlockedFlags 카운트 (X/8).

#### VillageVisitSection 인프라 배지 (페이즈 4 #3 FR-8 활성)

- 페이즈 4 #3 spec FR-8 위치에 정의됨. 본 spec implement 시 stub → 실 provider로 자동 전환.

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.dart` | HiveField 12 infrastructureTier 추가 | FR-1 |
| `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart` | `_evaluateInfrastructureTransition()` 신규 + `toggleFlag` trailing 활성화 | FR-4 |
| `band_of_mercenaries/lib/core/models/user_data.dart` | HiveField 27 foreignStallVisitCount + 생성자 default 0 | FR-16 |
| `band_of_mercenaries/lib/core/providers/game_state_provider.dart` (UserDataNotifier) | `incrementForeignStallVisit()` 메서드 추가 | FR-16 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | HiveField 34 settlementInfrastructureUpgraded | FR-6 |
| `band_of_mercenaries/lib/features/settlement/domain/village_facility.dart` | foreignStall enum case 추가 | FR-7 |
| `band_of_mercenaries/lib/features/settlement/view/village_visit_section.dart` | foreignStall switch case + Tier 3+ _FacilityCard 노출 | FR-7, FR-8 |
| `band_of_mercenaries/lib/features/settlement/view/chief_house_screen.dart` | Tier 2+ "생활권 정보" 버튼 + `_showLivingsphereDialog` 메서드 | FR-9 |
| `band_of_mercenaries/lib/features/settlement/domain/herbalist_service.dart` | _infraCostMultipliers/_infraGatheringMultipliers/_infraCooldownMultipliers + 메서드 시그니처 확장 | FR-10 |
| `band_of_mercenaries/lib/features/settlement/view/herbalist_screen.dart` | infraTier 인자 전달 | FR-10 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | 라인 202 `HerbalistService.gatheringMultiplier(currentTrustLevel)` 호출에 infraTier 추가 | FR-10 |
| `band_of_mercenaries/lib/features/crafting/domain/crafting_recipe_data.dart` | RecipeUnlockCondition freezed type/flag/value/conditions 4 nullable 필드 | FR-11 |
| `band_of_mercenaries/lib/features/crafting/domain/crafting_service.dart` | `evaluateState` M7 신규 type 분기 + `_isUnlockedM7` 재귀 헬퍼 | FR-11 |
| `band_of_mercenaries/lib/core/providers/dialog_queue_provider.dart` | DialogTypeRegistry.settlementInfrastructureUpgraded 키 + builder switch case | FR-5 |
| `band_of_mercenaries/lib/app.dart` | settlementInfrastructureUpgradedProvider ref.listen + dialogQueue enqueue + state=null 리셋 | FR-5 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/features/settlement/domain/settlement_infrastructure_config.dart` | 모든 상수 (임계·보상·가격·multiplier) (FR-2) |
| `band_of_mercenaries/lib/features/settlement/domain/settlement_infrastructure_provider.dart` | settlementInfrastructureTierProvider Provider.family (FR-3) |
| `band_of_mercenaries/lib/features/settlement/domain/infrastructure_upgrade_event.dart` | InfrastructureUpgradeEvent 페이로드 클래스 (FR-5) |
| `band_of_mercenaries/lib/features/settlement/domain/infrastructure_upgrade_provider.dart` | settlementInfrastructureUpgradedProvider StateProvider (FR-5) |
| `band_of_mercenaries/lib/core/widgets/settlement_infrastructure_upgraded_dialog.dart` | SettlementInfrastructureUpgradedDialog 위젯 (FR-5) |
| `band_of_mercenaries/lib/features/settlement/view/foreign_stall_screen.dart` | ForeignStallScreen + 외래 상인 케일 NPC 인사말 + 3 ActionButton (FR-7) |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.g.dart` | HiveField 12 (페이즈 4 #1·#2와 통합 재생성) |
| `band_of_mercenaries/lib/core/models/user_data.g.dart` | HiveField 27 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart` | HiveField 34 (페이즈 4 #1과 통합) |
| `band_of_mercenaries/lib/features/crafting/domain/crafting_recipe_data.freezed.dart` | RecipeUnlockCondition 4 필드 추가 |
| `band_of_mercenaries/lib/features/crafting/domain/crafting_recipe_data.g.dart` | RecipeUnlockCondition fromJson |

`dart run build_runner build --delete-conflicting-outputs` 1회 실행 (4 spec 통합 implement 시 통합 처리).

### 3.4 관련 시스템

- **페이즈 4 #1 spec (RegionState)**: 본 spec의 직접 의존 — getOrCreateRegionState / toggleFlag / addDangerScore. 페이즈 4 #1 FR-4e의 `_evaluateInfrastructureTransition` 호출 지점 위임 본체를 본 spec FR-4가 활성화. 페이즈 4 #1 FR-4b chain_m7_mist_clearing 매핑은 본 spec FR-12 SQL로 데이터 활성.
- **페이즈 4 #2 spec (QuestGenerator 가중치)**: 영향 없음 (인프라 단계가 의뢰 발급 가중치에 영향 안 미침). 단 페이즈 4 #2의 HiveField 11과 본 spec HiveField 12 충돌 없음.
- **페이즈 4 #3 spec (MovementScreen UI)**: 본 spec FR-3가 페이즈 4 #3 의존하는 `settlementInfrastructureTierProvider` 본체 활성화. 페이즈 4 #3 FR-4(광장 이정표 -10%) / FR-8(VillageVisitSection 인프라 배지) graceful degradation이 자동 해제.
- **M4 settlement_trust**: 독립 축. HiveField 4·5(trust/trustLevel)와 HiveField 12(infrastructureTier) 별도 저장. HerbalistService에서 곱셈 합산.
- **M5 CraftingService / RecipeListSection**: M5 기존 10 레시피 + M7 신규 6 레시피 공존. `evaluateState` 분기 확장으로 두 형식(M5 trust_level/chain_step/first_acquired_item + M7 type discriminator) 모두 처리.
- **M6 AchievementService**: hook_type 'infrastructure_tier' 신규 — 코드 변경 없음 (grant 멱등 보장). band_achievement_templates 1행 INSERT만.
- **chain_m7_mist_clearing**: 페이즈 3 #5 SQL에서 2단계 INSERT. 페이즈 4 #1 FR-4b 매핑으로 region 146 dangerScore -50 + flag toggle 자동 작동.
- **operation-bom**: items effect_json 편집 (FR-13 placeholder 대체), band_achievement_templates 1행 추가, crafting_recipes unlock_condition_json 신규 type 자동 호환 (자유 JSONB).

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **`RegionStateRepository.addSettlementTrust`** (라인 145~280) — 단계 재계산 + 통과 단계 보상 합산 + ActivityLog + publish + achievement grant + refreshAvailableQuests. `_evaluateInfrastructureTransition`은 본 패턴 답습 (보상 합산 + ActivityLog + publish + grant 동일).
- **`TrustLevelUpEvent`** (`features/investigation/domain/trust_level_up_event.dart`) — InfrastructureUpgradeEvent 동일 패턴.
- **`settlementTrustLevelUpProvider`** — settlementInfrastructureUpgradedProvider 동일 패턴.
- **`SettlementTrustUpDialog`** — SettlementInfrastructureUpgradedDialog 동일 시각 (AlertDialog + 확인 버튼 1개).
- **`DialogTypeRegistry.settlementTrustUp`** (dialog_queue_provider.dart 라인 24) — settlementInfrastructureUpgraded 동일 등록 패턴.
- **`ChiefHouseScreen._ActionButton`** (라인 43~52) — "생활권 정보" 버튼 동일 패턴.
- **`VillageVisitSection._FacilityCard`** (라인 90~112) — foreignStall 카드 동일 시각.
- **M6 hook 패턴**: `AchievementService.grant()` fail-soft trailing (`elite_unique_first_kill` 패턴) — 본 spec `infrastructure_tier:tier_4` 동일.
- **`HerbalistService` 기존 상수** (라인 4~6) — `_costMultipliers`/`_cooldownMinutes`/`_gatheringMultipliers`. infra 상수 3종 동일 패턴.
- **M5 `RecipeUnlockCondition` freezed** (현재 라인 40~48) — type discriminator 형식 추가 시 nullable 필드만 추가 (sealed union 회피 — M5 기존 호환).
- **페이즈 3 #5 SQL 적용 패턴**: `m7_phase3_5_recipes_chain.sql` 검증 DO 블록 3종 + COMMENT — M7 페이즈 3 #1 SQL과 동일 마이그레이션 패턴.

### 4.2 주의사항

- **implement 순서**: 페이즈 4 #1 → 페이즈 4 #2 → 페이즈 4 #3 → **본 spec(#4) 마지막**. 본 spec의 모든 의존(RegionState API + toggleFlag trailing + settlementInfrastructureTierProvider + VillageVisitSection 인프라 배지 + 광장 이정표)이 이전 spec에서 제공됨.
- **build_runner 통합 1회 실행**: 4 spec의 freezed/Hive 변경을 한 번에 처리. `--delete-conflicting-outputs` 플래그 필수.
- **HiveField 충돌 회피**: RegionState 8·9·10·11·**12** / UserData 26·**27** / ActivityLogType 32·33·**34**. 4 spec 분담 정합.
- **`_evaluateInfrastructureTransition` 재진입**: `toggleFlag`가 fail-soft trailing으로 호출 → 본 메서드가 다시 toggleFlag를 호출하지 않음 (안전). 단 `addDangerScore`는 trailing에서 dialogLevel 전이 발생 가능 → infrastructure 평가는 toggleFlag에서만 트리거됨 (정상).
- **단일 quest 완료로 여러 flag 동시 토글되지 않음**: 1개 quest = 1개 flag (cumulative cap 도달 / oneshot). 따라서 `_evaluateInfrastructureTransition` 1회 호출당 최대 1 Tier 전이. 단 한 번의 호출에서 여러 Tier를 건너뛰는 경우(예: 동시 flag 2개 토글로 임계 2 + 4 모두 도달)는 발생하지 않음 — 한 번에 1 flag 토글 보장.
- **여러 Tier 동시 통과 시 보상 합산**: 만약 디버그 시점에 flag 5개를 한 번에 토글 시 — Tier 1 → 4 직행 가능. `_evaluateInfrastructureTransition` 내부 `for (int tier = currentTier + 1; tier <= nextTier; tier++)` 루프가 통과 단계 보상 모두 합산 (M4 `addSettlementTrust` 라인 175~182 패턴 답습).
- **`CraftingService.evaluateState` 두 형식 공존**: M5 기존 condition(type 필드 null) + M7 신규(type 필드 보유). `if (condition.type != null)` 분기로 일관 처리. M5 데이터 변경 없음.
- **`evaluateState` 호출자 변경 없음**: `evaluateState` 시그니처는 변경 없음 — 내부에서 regionStateRepository를 통해 infraTier / unlockedFlags 직접 조회. CraftingService 호출자 영향 0.
- **HerbalistService 호출자 인자 추가**: `calculateCost` 등 3 메서드에 `infraTier` named 인자 추가 (default 1로 하위호환). 호출 지점(`HerbalistScreen`, `quest_completion_service.dart`)에서 region 3 한정 분기 시에만 실 값 전달.
- **`HerbalistService.gatheringMultiplier` 호출 지점** (`quest_completion_service.dart:202`): `region == 3 && questPoolId == 'dustvile_chore_03'` 분기 내부. infraTier 조회는 `ref.read(settlementInfrastructureTierProvider(3))`. ref 없는 정적 컨텍스트가 아니므로 안전.
- **ForeignStallScreen 재료 거래 검증**: 사용자 골드 < 가격 시 disabled + 회색. 인벤토리 999 도달 시 disabled + "보유량 가득" 표시.
- **외래 좌판 거래 종류 노출 순서**: `foreignStallBasePrices` Map 입력 순서 그대로 (Tier 3 처음 3종, Tier 4 6종 전체). 단순함.
- **Tier 4 진입 위업 멱등**: AchievementService.grant 내부 hasAchievement 체크로 중복 발급 회피. Tier 4 → Tier 4 재진입 자체가 불가능하므로 실질 영향 없음.
- **운영 도구**: items effect_json placeholder 갱신 시 GUI 편집 가능. band_achievement_templates 1행 추가도 표준 CRUD.
- **chain_m7_mist_clearing chain 진입 조건**: 페이즈 3 #3 region_discoveries `rdsc_m7_r146_mist_omen` (knowledge=85, hidden_quest) 트리거 의존. 페이즈 3 #3 데이터가 이미 Supabase 적용 완료 (state.md 페이즈 3 산출물 3 완료) → 본 spec FR-12 SQL 적용 시 자동 작동.

### 4.3 엣지 케이스

- **region 3 RegionState 미존재 (첫 진입)**: `_evaluateInfrastructureTransition`이 `getOrCreateRegionState`로 자동 생성. infrastructureTier null → 1 fallback. 정상.
- **flag 토글 후 Tier 변화 없음**: `nextTier <= currentTier` 시 즉시 return null. Dialog 미발동. 정상 동작.
- **`getOrCreateRegionState`가 페이즈 4 #1에서 미정의**: 페이즈 4 #1 FR-3에 정의됨 — `RegionState가 없으면 신규 생성+box에 추가, 있으면 기존 반환`. 본 spec은 호출만.
- **`UserData.foreignStallVisitCount` 카운터 오버플로우**: int 32비트 한계는 무시 가능 (실질 100~1000 회 수준).
- **외래 좌판 거래 가격 0G 또는 음수**: `foreignStallBasePrices` 8종 모두 양수 (60~300G). Tier 4 할인 후 최소 48G. 정상.
- **VillageFacility.foreignStall switch 미커버**: switch case 누락 시 컴파일 에러 (dart sealed enum 강제). 안전.
- **`incrementForeignStallVisit` race 조건**: dart 단일 스레드. `userData.foreignStallVisitCount++` + `await save()` 순차 보장.
- **CraftingService 두 형식 동시 사용**: 한 recipe의 unlock_condition_json이 type 필드 + trust_level 필드 둘 다 있는 경우 — type 필드 우선 처리. 페이즈 3 #5 SQL은 6 레시피 모두 type 필드만 사용 (정합).
- **`_isUnlockedM7` 재귀 무한 루프**: `all`/`any`의 conditions 내부에 또 `all`/`any` 중첩 시 재귀 — 깊이 제한 없음. 페이즈 3 #5 SQL은 1단 중첩만 사용 (안전). M9+ 다단 중첩 시 깊이 제한 검토.
- **build_runner 재실행 시 RecipeUnlockCondition 호환성**: 신규 nullable 필드 추가는 기존 데이터 fromJson 호환 (null 처리). M5 기존 데이터 영향 0.
- **Tier 4 진입 위업 + 다이얼로그 발동 순서**: `_evaluateInfrastructureTransition` 내부 — (1) infrastructureTier 갱신 (2) 보상 지급 (3) ActivityLog (4) achievementService.grant Tier 4 한정 (5) refreshAvailableQuests (6) return event → app.dart ref.listen → dialogQueue.enqueue (settlementInfrastructureUpgraded). 위업 다이얼로그 (high priority `achievementUnlocked`)는 grant 본체에서 별도 enqueue. **두 다이얼로그 모두 발동** — 큐 우선순위에 따라 위업 다이얼로그 먼저, 인프라 다이얼로그 다음.
- **외래 좌판 거래 ActivityLog 카테고리**: 본 spec [Q-7] — 별도 HiveField 미추가, `mercenaryRecruit`나 일반 텍스트 메시지로 처리. 단순 텍스트 "외래 좌판에서 {itemName} 구매 ({price}G)" 형식. 카테고리는 보류 — implement 시점에 단순 결정 권장.
- **ChiefHouseScreen "생활권 정보" 다이얼로그 Tier 4 풍문**: 페이즈 3 #5 narrative에 M8 빌드업 stub 텍스트 사용 — "어디선가 큰 깃발이 펄럭이는 풍문이 들린다..." 1줄 정도.

### 4.4 구현 힌트

- **진입점**:
  - 인프라 단계 갱신: `RegionStateRepository.toggleFlag(regionId, flag, ref)` → fail-soft trailing → `_evaluateInfrastructureTransition(ref)`
  - 이벤트 채널: `settlementInfrastructureUpgradedProvider` (StateProvider, app.dart ref.listen)
  - 다이얼로그: dialogQueueProvider (medium priority)
  - UI 활성화: `settlementInfrastructureTierProvider(regionId)` → 페이즈 4 #3 위젯 2종 자동 활성
- **데이터 흐름**:
  1. 사건 완료 → `applyDangerScoreFromQuest` (페이즈 4 #2) 또는 `ChainQuestService.completeChain` (페이즈 4 #1 FR-4b)
  2. → `toggleFlag(regionId, flag, ref)` (페이즈 4 #1 FR-3) → unlockedFlags 추가 + ActivityLog
  3. → fail-soft trailing → `_evaluateInfrastructureTransition(ref)`
  4. → 8 flag 합산 → resolveTier → nextTier > currentTier 검증
  5. → infrastructureTier 갱신 + 보상 합산 지급 + ActivityLog `settlementInfrastructureUpgraded` + Tier 4 위업 grant + refreshAvailableQuests
  6. → return InfrastructureUpgradeEvent → settlementInfrastructureUpgradedProvider.state = event
  7. → app.dart ref.listen → dialogQueue.enqueue(settlementInfrastructureUpgraded, payload) → state=null 리셋
  8. → dialogQueue head 도달 → SettlementInfrastructureUpgradedDialog 표시
  9. → UI 자동 갱신: VillageVisitSection 인프라 배지·외래 좌판 카드 노출, MovementScreen 광장 이정표 효과, OldSmithyScreen 신규 레시피 노출, ChiefHouseScreen "생활권 정보" 버튼
- **참조 구현**:
  - `region_state_repository.dart:145~280` — addSettlementTrust 메서드 (단계 재계산·publish·ActivityLog·grant·refreshAvailableQuests 통합 패턴)
  - `core/widgets/settlement_trust_up_dialog.dart` — AlertDialog 패턴
  - `dialog_queue_provider.dart:15~30, 156~186` — DialogTypeRegistry + builder switch
  - `app.dart:48 ref.listen` — settlementTrustUpProvider 패턴
  - `features/settlement/view/herbalist_screen.dart` — calculateCost 호출 + UI 표시 패턴
  - `features/settlement/view/old_smithy_screen.dart` — VillageFacility 진입점 + RecipeListSection
  - `crafting_service.dart:56~95` — evaluateState 패턴 (M5 기존 trust_level/chain_step/first_acquired_item 분기)
- **확장 지점**:
  - Tier 5+ 추가: SettlementInfrastructureConfig.infraTierThresholds + infraTierRewards + infraTierNames 행 추가
  - 다른 region 인프라 (M8): 본 spec은 region 3 한정. M8+ region 38 거점화 시 동일 패턴 복제
  - 추가 외래 좌판 거래: `foreignStallBasePrices` Map 행 추가
  - 새 unlock_condition type: `_isUnlockedM7` switch case 추가

## 5. 기획 확인 사항

- **[Q-1] items 6행 effect_json 최종 수치** → 본 spec 채택: FR-13 표 (placeholder 대체). 야수 가죽 도구 STR+3/HIT+2, 들꽃 향료 회복 300초/쿨다운 30분, 유목민 가죽 VIT+3/부상저항 5%, 해안 약물 회복 600초/쿨다운 45분, 안개 인장 명성 게인 +7%, 부서진 인장 고티어 모집 +3%. 페이즈 1 #3 4절 컨셉 + M5 패턴 답습. **implement 시점에 사용자 검토 권장**.
- **[Q-2] RecipeUnlockCondition freezed 확장 vs sealed union 마이그레이션** → 본 spec 채택: **freezed nullable 필드 추가** (FR-11). M5 기존 데이터(type 필드 없음) 호환을 위해. sealed union(페이즈 4 #2 RegionStateEffect 패턴)은 M5 데이터 마이그레이션 부담 — 회피.
- **[Q-3] `_evaluateInfrastructureTransition` 호출 위치 (toggleFlag 내부 trailing vs addDangerScore 내부)** → 본 spec 채택: **toggleFlag trailing 한정** (FR-4). 페이즈 4 #1 FR-4e의 위임 본체. addDangerScore는 dangerLevel 전이 + region_pacified 위업만 담당. 의미 분리.
- **[Q-4] Tier 4 위업 "변방의 영주" hook_type** → 본 spec 채택: `infrastructure_tier`. AchievementService 코드 변경 없음 (template_id 매칭만). 페이즈 4 #1 FR-7과 동일 패턴.
- **[Q-5] "생활권 정보" 다이얼로그 진입 조건** → 본 spec 채택: **Tier 2+ 활성** (FR-9). Tier 2부터 7리전 매트릭스 정보 노출 의미 있음. Tier 1은 미노출.
- **[Q-6] 외래 좌판 거래 종류 노출 우선순위** → 본 spec 채택: **`foreignStallBasePrices` Map 입력 순서** (FR-7). Tier 3 = 처음 3종 (wildflower, seaweed, nomad_strap) / Tier 4 = 6종 전체. 단순함.
- **[Q-7] 외래 좌판 거래 ActivityLog 카테고리** → 본 spec 채택: **별도 HiveField 미추가, 일반 텍스트 메시지로 처리**. ActivityLog HiveField 35 추가 시 typeId 6 재생성 부담 + 본 spec 범위 비대. M8+ 필요 시 추가.
- **[Q-8] `_isUnlockedM7` 재귀 깊이 제한** → 본 spec 채택: **제한 없음**. 페이즈 3 #5 SQL이 1단 중첩만 사용. M9+ 다단 중첩 시 재검토.
- **[Q-9] `UserData.foreignStallVisitCount` 사용처 확장** → 본 spec 채택: **방문 횟수 표시만**. 위업 hook 등 추가 영향 없음. M8+ "외래 친교" 위업 시 활용.
- **[Q-10] Tier 4 위업 다이얼로그 + 인프라 다이얼로그 두 번 발동 정합** → 본 spec 채택: **두 다이얼로그 모두 발동**. 위업 다이얼로그(high) 먼저, 인프라 다이얼로그(medium) 다음. 큐 패턴 정합.
- **[Q-11] HerbalistService 메서드 시그니처 변경 영향** → 본 spec 채택: **named 인자 + default 1로 하위호환**. 기존 호출자 영향 0. 신규 호출자(region 3 한정 분기)만 실 값 전달.
- **[Q-12] "변방의 영주" 위업 template_id 명명 규약** → 본 spec 채택: `infrastructure_tier:tier_4`. M6 페이즈 4 #1 위업 26행 명명 규약(`{카테고리}:{식별자}`) 정합.
- **[Q-13] chain_m7_mist_clearing 진입 트리거 (knowledge=85)와 페이즈 4 #1 chain 매핑 정합** → 본 spec 채택: **페이즈 4 #1 매핑이 chain_id 기준** → chain 활성화 시 자동 작동. 페이즈 3 #3 region_discovery `rdsc_m7_r146_mist_omen` (페이즈 3 산출물 3 Supabase 적용 완료)이 hidden_quest 트리거 → chain_m7_mist_clearing 1단계 활성 → 완주 시 페이즈 4 #1 FR-4b 매핑이 region 146 dangerScore -50 + flag toggle.
