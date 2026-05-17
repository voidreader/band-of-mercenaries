# M7 페이즈 4 #2: QuestGenerator 지역 상태 가중치 분기 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260516_m7_region_state_rules.md` (페이즈 1 #2 — 4절 QuestGenerator 가중치 정책 컨셉)
> - `Docs/balance-design/[balance]20260517_m7_region_state_thresholds.md` (페이즈 2 #2 — 4·5·6절 매트릭스·플래그 가중치 정량)
>
> 데이터 산출물: `Docs/content-data/m7_quest_pools_state.sql` (페이즈 3 #4 — ALTER + 36행 INSERT, 본 spec 적용 시 마이그레이션)
>
> 동반 spec: `Docs/spec/m7_p4_1_region_state_system.md` (페이즈 4 #1 — RegionState 모델 확장 + dangerScore/dangerLevel/unlockedFlags + 트리거 5종)
>
> 작성일: 2026-05-17

## 1. 개요

M7 페이즈 4 #1에서 도입한 `RegionState.dangerScore` / `dangerLevel` / `unlockedFlags` 3축을 입력으로 받아, **`QuestGenerator`가 발급 시점에 4×4 가중치 매트릭스 + 8 flag 가중치 + 비노출 정책(region_state_required/excluded)을 적용**하여 region 상태에 따라 의뢰 풀 분포를 차별화한다. `quest_pools` 테이블에 신규 3 컬럼(`region_state_effect JSONB` / `region_state_required TEXT` / `region_state_excluded TEXT`)을 추가하고 M7 7리전 36행을 INSERT한다. QuestPool freezed 모델을 확장하고 `RegionStateEffect` 신규 Freezed 모델로 cumulative/oneshot 분기를 표현한다. 또한 페이즈 4 #1 FR-4a에서 호출 지점만 명세했던 `applyDangerScoreFromQuest()` trailing을 본 spec에서 **활성화** — `QuestCompletionService` 직후 cumulative 카운터 누적·cap 도달 시 단발 -10 보너스·flag toggle 분기를 구현한다. cumulative 카운터는 `RegionState.questPoolCompletionCounts` (HiveField 11, Map<String, int>) 영속.

## 2. 요구사항

### 2.1 기능 요구사항

#### FR-1: `quest_pools` 신규 3 컬럼 마이그레이션 (Supabase) + 36행 INSERT

- `Docs/content-data/m7_quest_pools_state.sql` 그대로 적용. 단일 트랜잭션:
  - (A) `ALTER TABLE quest_pools` — `region_state_effect JSONB` / `region_state_required TEXT` / `region_state_excluded TEXT` 3 컬럼 + COMMENT.
  - (B) CHECK 제약 2종 — `chk_quest_pools_region_state_required` / `chk_quest_pools_region_state_excluded` (값 `IN ('stable','peaceful','tension','threat')` 또는 NULL).
  - (C) 36행 INSERT — r3:2 / r31:6 / r127:5 / r9:6 / r10:5 / r146:6 / r38:6, prefix `qp_m7_`.
  - (D) 검증 DO 블록 4종 — 총 36행 / threshold_flag 8개 검증 / region 분포 / 풀 분포(cumulative 7·oneshot 6·상태 조건 11·일반 12).
- 적용 후 `UPDATE data_versions SET version = version + 1 WHERE table_name = 'quest_pools';` 수동 실행 — DataLoader 캐시 무효화.
- operation-bom `table-config.ts` quest_pools 정의에 신규 3 컬럼 등록 (편집 폼 — JSONB editor + enum select × 2). **operation-bom 수정은 본 spec 영역 외** (별도 PR 위임), 단 권장 안내만 명세에 기재.

#### FR-2: `QuestPool` freezed 모델 신규 3 필드 + `RegionStateEffect` 신규 Freezed 모델

- **`QuestPool` 확장 (`core/models/quest_pool.dart`)** — 신규 3 필드 추가:
  ```dart
  // M7 페이즈 4 #2 — 지역 상태 시스템 컬럼
  @JsonKey(name: 'region_state_effect') RegionStateEffect? regionStateEffect,
  @JsonKey(name: 'region_state_required') String? regionStateRequired,
  @JsonKey(name: 'region_state_excluded') String? regionStateExcluded,
  ```
  - `regionStateEffect`는 JSONB를 RegionStateEffect freezed 모델로 매핑. nullable.
  - `regionStateRequired`/`excluded`는 raw String 유지 (DangerLevel enum 변환은 가중치 계산 시점에 수행 — DangerLevel.fromLowercaseString 활용).
- **`RegionStateEffect` 신규 Freezed 모델** (`core/models/region_state_effect.dart`):
  ```dart
  @freezed
  sealed class RegionStateEffect with _$RegionStateEffect {
    @FreezedUnionValue('cumulative')
    const factory RegionStateEffect.cumulative({
      @JsonKey(name: 'delta_per_completion') required int deltaPerCompletion, // -10 권장
      @JsonKey(name: 'cap_per_threshold') required int capPerThreshold,       // -50 권장
      @JsonKey(name: 'threshold_flag') required String thresholdFlag,         // 8개 flag 중 하나
    }) = CumulativeEffect;

    @FreezedUnionValue('oneshot')
    const factory RegionStateEffect.oneshot({
      required int delta,         // -10 ~ -50
      required String flag,       // 8개 flag 중 하나
    }) = OneshotEffect;

    factory RegionStateEffect.fromJson(Map<String, dynamic> json) =>
        _$RegionStateEffectFromJson(json);
  }
  ```
  - sealed union + `@FreezedUnionValue` discriminator `type`. JSONB 구조 `{"type":"cumulative",...}` / `{"type":"oneshot",...}` 자동 매핑.
  - build_runner 재실행 필요 (`region_state_effect.freezed.dart` / `.g.dart` 신규 + `quest_pool.freezed.dart` / `.g.dart` 재생성).

#### FR-3: `RegionStateWeightConfig` 신규 상수 모듈 (`features/quest/domain/region_state_weight_config.dart`)

- 4단계 × 4 quest_type 가중치 매트릭스 (페이즈 2 #2 4절 그대로 채택):
  ```dart
  static const Map<DangerLevel, Map<String, double>> dangerLevelMultiplier = {
    DangerLevel.threat:   {'raid': 3.0, 'hunt': 3.0, 'escort': 1.5, 'explore': 1.5},
    DangerLevel.tension:  {'raid': 2.0, 'hunt': 2.0, 'escort': 1.3, 'explore': 1.3},
    DangerLevel.peaceful: {'raid': 1.0, 'hunt': 1.0, 'escort': 1.2, 'explore': 1.0},
    DangerLevel.stable:   {'raid': 0.3, 'hunt': 0.5, 'escort': 1.5, 'explore': 1.3},
  };
  ```
  - quest_type key는 String — `quest_types.id` 그대로 사용 (`'raid'`/`'hunt'`/`'escort'`/`'explore'`).
  - `labor`/`survey`는 매트릭스 미정의 → fallback 1.0× (기존 동작 유지).
- 8 flag × 1~2 quest_type = 14쌍 (페이즈 2 #2 6절 그대로 채택):
  ```dart
  static const Map<String, Map<String, double>> flagMultipliers = {
    'region_3_pyegwang_reopen_completed':       {'hunt': 0.7, 'escort': 1.2},
    'region_31_bandits_cleared':                {'raid': 0.3, 'escort': 1.5},
    'region_31_shrine_quest_completed':         {'explore': 1.3},
    'region_127_nomad_friendly':                {'escort': 1.3, 'raid': 0.5},
    'region_9_giant_beast_killed':              {'hunt': 0.5, 'escort': 1.2},
    'region_10_windrunner_chain_completed':     {'explore': 1.3},
    'region_146_mist_cleared':                  {'explore': 1.3, 'hunt': 0.7},
    'region_38_ironbound_pact_completed':       {'raid': 0.5, 'explore': 1.2},
  };
  ```
- cumulative cap 도달 후 노출 빈도 축소 multiplier:
  ```dart
  static const double cumulativeCapReachedMultiplier = 0.2;
  ```
- decay 상수는 본 spec 영역 외 (페이즈 4 #1 FR-4d) — 본 spec은 매트릭스·가중치만 보유.

#### FR-4: `QuestGenerator.computeFinalWeight()` 신규 헬퍼 + `_weightedSample` 통합

- **신규 정적 메서드 `computeFinalWeight(QuestPool pool, RegionState? state, NewbieGate gate)`** — `_weightFor()` 다음 라인 추가:
  ```dart
  static double computeFinalWeight({
    required QuestPool pool,
    required RegionState? regionState,
    required NewbieGate gate,
  }) {
    // 1. NewbieGate base weight (기존 _weightFor)
    var weight = _weightFor(gate, pool.difficulty);
    if (weight <= 0) return 0.0;

    // 2. 비노출 검증 — region_state_required (불일치 시 weight=0)
    if (regionState != null && pool.regionStateRequired != null) {
      final required = DangerLevel.fromLowercaseString(pool.regionStateRequired!);
      if (required != null && DangerLevel.fromCacheInt(regionState.dangerLevel) != required) {
        return 0.0;
      }
    }

    // 3. 비노출 검증 — region_state_excluded (일치 시 weight=0)
    if (regionState != null && pool.regionStateExcluded != null) {
      final excluded = DangerLevel.fromLowercaseString(pool.regionStateExcluded!);
      if (excluded != null && DangerLevel.fromCacheInt(regionState.dangerLevel) == excluded) {
        return 0.0;
      }
    }

    // 4. dangerLevel 가중치 — RegionState 없으면 peaceful fallback (페이즈 4 #1 FR-1)
    final level = regionState != null
        ? DangerLevel.fromCacheInt(regionState.dangerLevel) ?? DangerLevel.peaceful
        : DangerLevel.peaceful;
    final dangerMulti = RegionStateWeightConfig.dangerLevelMultiplier[level]?[pool.typeId] ?? 1.0;
    weight *= dangerMulti;

    // 5. unlockedFlags 가중치 합산 (multiplicative)
    if (regionState != null) {
      for (final flag in regionState.unlockedFlags) {
        final flagMulti = RegionStateWeightConfig.flagMultipliers[flag]?[pool.typeId];
        if (flagMulti != null) weight *= flagMulti;
      }
    }

    // 6. cumulative cap 도달 후 노출 빈도 축소 (regionStateEffect가 cumulative이고 threshold_flag 이미 토글)
    final effect = pool.regionStateEffect;
    if (effect is CumulativeEffect && regionState != null) {
      if (regionState.unlockedFlags.contains(effect.thresholdFlag)) {
        weight *= RegionStateWeightConfig.cumulativeCapReachedMultiplier;
      }
    }

    // 7. 지명 의뢰 +α=3 가중치 (M6 페이즈 4 #3 기존 동작 유지 — addition으로 누적)
    if (pool.isNamed) weight += 3.0;

    return weight;
  }
  ```
- **`_weightedSample` 시그니처 변경** — `RegionState? regionState` 인자 추가, 내부에서 `computeFinalWeight()` 호출로 통합:
  ```dart
  static List<QuestPool> _weightedSample(
    List<QuestPool> pools,
    int count,
    NewbieGate gate,
    Random random,
    RegionState? regionState,
  ) {
    // ... 기존 구조 유지, w 계산만 computeFinalWeight()로 대체
  }
  ```
- **기존 `_weightFor`는 유지** (computeFinalWeight 내부에서 호출) — 신규 유저 게이트 분기 보존.
- **지명 의뢰 +α=3는 computeFinalWeight 내부로 이동** (`_weightedSample`에서 제거) — 가중치 계산 일원화.

#### FR-5: `QuestGenerator.generateQuests()` 시그니처 확장 + RegionState 주입

- 신규 인자 추가:
  ```dart
  RegionState? regionState, // M7 페이즈 4 #2 — region 상태 가중치 계산용
  ```
- generalPools 필터링 (라인 64~78) **재구성**:
  - 기존 `where((p) => !p.isFactionExclusive)` / `!p.isFixed` / `minTrustLevel` / sector / named hook + cooldown 체인 유지.
  - 비노출 정책(`region_state_required`/`excluded`)은 **필터링이 아닌 `computeFinalWeight` 내부 weight=0 처리로 통합** — 일관성 위해. 단, 필터 단계에서 정적으로 0이 보장되므로 효율 저하 없음.
- `_weightedSample` 호출 시 `regionState` 전달:
  ```dart
  final selectedGeneralPools = _weightedSample(
    generalPools,
    remainingCount,
    gate,
    random,
    regionState, // 신규
  );
  ```
- 호출 지점 3곳 (`quest_provider.dart` 라인 249·462·658 = `generateQuests`/`refreshAvailableQuests`/`_refillSpecific`)에서 `regionState: ref.read(regionStateRepositoryProvider).getState(userData.region)` 인자 추가.

#### FR-6: 누적(cumulative) 카운터 영속 추적 — `RegionState.questPoolCompletionCounts` HiveField 11

- **`RegionState` HiveField 11 추가** (`features/investigation/domain/region_state_model.dart`):
  ```dart
  /// M7 페이즈 4 #2 — quest_pool별 region 내 누적 완료 횟수 (cumulative cap 추적)
  /// key: quest_pool_id, value: 완료 횟수 (0~∞, cap 도달 후 더 이상 증가시키지 않음)
  @HiveField(11)
  Map<String, int> questPoolCompletionCounts;
  ```
- 생성자 default `{}` 보장 + nullable 회피 (멱등 추가 패턴).
- build_runner 재생성 필요 (`region_state_model.g.dart`).
- **별도 typeId 신규 부여 없음** — RegionState (typeId 8) 내부 필드 추가만.
- **대안 (UserData에 통합)은 기각**:
  - 이유 1: region별로 분리 추적이 자연스러움 (도적 cumulative는 region 31 한정).
  - 이유 2: RegionState는 이미 region 단위 누적 데이터(knowledge·trust)를 보유하므로 응집성 일관.
  - 이유 3: UserData 변경 회피로 다른 시스템과의 충돌 최소화.

#### FR-7: `RegionStateRepository.applyDangerScoreFromQuest()` 신규 메서드 (페이즈 4 #1 FR-4a 활성화)

- 페이즈 4 #1 FR-4a에서 "호출 지점만 명세하고 실제 region_state_effect 사용은 페이즈 4 #2 마이그레이션 후 활성화"로 위임된 본체 구현.
- **시그니처**:
  ```dart
  /// M7 페이즈 4 #2 — quest 완료 시 region_state_effect 적용.
  ///
  /// cumulative: 누적 카운터 증가 → cap 미달 시 delta 적용 / cap 도달 시 단발 -10 보너스 + flag toggle.
  /// oneshot: flag 미보유 시에만 delta 적용 + flag toggle (멱등).
  Future<void> applyDangerScoreFromQuest({
    required int regionId,
    required QuestPool pool,
    required Ref ref,
  }) async {
    final effect = pool.regionStateEffect;
    if (effect == null) return;
    final state = getOrCreateRegionState(regionId);
    switch (effect) {
      case CumulativeEffect(:final deltaPerCompletion, :final capPerThreshold, :final thresholdFlag):
        // 이미 cap 도달(threshold_flag 토글됨) → 카운터 증가만 (delta 미적용)
        if (state.unlockedFlags.contains(thresholdFlag)) {
          state.questPoolCompletionCounts[pool.id] = (state.questPoolCompletionCounts[pool.id] ?? 0) + 1;
          await state.save();
          return;
        }
        // 카운터 +1
        final newCount = (state.questPoolCompletionCounts[pool.id] ?? 0) + 1;
        state.questPoolCompletionCounts[pool.id] = newCount;
        await state.save();
        // delta 적용 (회당 -10)
        await addDangerScore(regionId: regionId, delta: deltaPerCompletion, source: 'cumulative_${pool.id}', ref: ref);
        // cap 도달 검증 (newCount * delta == capPerThreshold)
        final cumulativeDelta = newCount * deltaPerCompletion;
        if (cumulativeDelta <= capPerThreshold) {
          // cap 도달 — flag toggle + 단발 -10 보너스 (페이즈 2 #2 3절)
          final toggled = await toggleFlag(regionId: regionId, flag: thresholdFlag, ref: ref);
          if (toggled) {
            await addDangerScore(regionId: regionId, delta: -10, source: 'cumulative_cap_bonus', ref: ref);
          }
        }
        break;
      case OneshotEffect(:final delta, :final flag):
        if (state.unlockedFlags.contains(flag)) return; // 멱등 — 이미 적용
        await toggleFlag(regionId: regionId, flag: flag, ref: ref);
        await addDangerScore(regionId: regionId, delta: delta, source: 'oneshot_${pool.id}', ref: ref);
        break;
    }
  }
  ```
- `addDangerScore`/`toggleFlag`/`getOrCreateRegionState`는 페이즈 4 #1 spec FR-3에서 정의됨 — 본 spec은 호출만.
- **cap 도달 정량** (페이즈 2 #2 3절): 회당 -10 × 5회 = -50 도달 시점에 flag toggle + 단발 -10 보너스 = 총 -60 (stable -50 안정 진입 보장).
- **race 조건 회피**: dart 단일 스레드. `state.save()` 동기 보장 — 카운터 갱신 후 addDangerScore 순차 호출.

#### FR-8: `QuestCompletionService` 또는 `_applyCompletionResult` trailing — `applyDangerScoreFromQuest` 호출

- **호출 위치**: `quest_provider.dart` `_applyCompletionResult` 메서드 끝부분 (라인 1419~1437 사이) — 거점 사건 trailing + 일반 의뢰 신뢰도 trailing 다음, `_load()` 직전.
- **호출 조건**:
  - quest 성공/대성공 한정 (`result.resultType == QuestResult.greatSuccess || result.resultType == QuestResult.success`).
  - quest_pool 조회 후 `pool.regionStateEffect != null` 분기.
  - quest.isChainQuest && quest.isSettlementStep는 제외하지 않음 — settlement step도 적용 (page 1 #2 5.2절 의도된 이중 작동, region 3 폐광 단계 -30 정합).
- **구현**:
  ```dart
  // M7 페이즈 4 #2 — region_state_effect trailing (fail-soft)
  if (result.resultType == QuestResult.greatSuccess || result.resultType == QuestResult.success) {
    final pool = staticData.questPools
        .where((p) => p.id == quest.questPoolId)
        .firstOrNull;
    if (pool != null && pool.regionStateEffect != null) {
      try {
        await ref.read(regionStateRepositoryProvider).applyDangerScoreFromQuest(
          regionId: quest.region,
          pool: pool,
          ref: ref,
        );
      } on Exception catch (e) {
        debugPrint('[BOM][M7] region_state_effect 적용 실패: $e');
      }
    }
  }
  ```
- `addDangerScore` 내부에서 dangerLevel 전이 발생 시 자동 publish + dialog + 위업 hook (페이즈 4 #1 FR-3·FR-5·FR-7) — 본 spec은 호출만.
- **퀘스트 풀 갱신 호출**: `addDangerScore`/`toggleFlag`로 region 상태 변동 후 `refreshAvailableQuests()` 자동 호출 — `addSettlementTrust`의 라인 276 패턴(단계 승급 시) 답습. **본 spec은 페이즈 4 #1 FR-3에 의존**.

#### FR-9: `QuestSortService` 영향 — 변경 없음

- 비노출 정책(`region_state_required`/`excluded`)은 `QuestGenerator` 단계에서 weight=0 처리되어 발급 단계에서 제거됨 → ActiveQuest 풀에 진입 자체가 안 됨.
- 따라서 `QuestSortService`는 변경 없음. 단, 정렬 입력으로 들어오는 ActiveQuest는 이미 region_state 조건을 통과한 상태.
- **단, sectionType이 변형됐는데 region_state도 변경된 경우** — `QuestSortService._isSectorTransformQuest`는 변경 없음 (sector_type 일치만 확인). region_state required와 sector 변형은 직교 정책.

#### FR-10: DataLoader 영향 — 변경 없음 (자동 매핑)

- `DataLoader.parseList` (`core/data/data_loader.dart` 라인 30~38)는 fromJson 콜백 기반이므로 QuestPool 신규 3 필드 자동 매핑.
- `region_state_effect` JSONB → `Map<String, dynamic>` 수신 → `RegionStateEffect.fromJson` 자동 호출 (sealed union discriminator `type` 분기).
- 단, Supabase 클라이언트가 JSONB를 dynamic으로 반환하는지 확인 필요 (special_flags 동작 검증됨 — 동일 패턴).

#### FR-11: `DangerLevel.fromLowercaseString(String)` 헬퍼 — 페이즈 4 #1 FR-2 확장

- 페이즈 4 #1 spec FR-2에서 `toLowercaseString()` 매핑 헬퍼만 정의됨. 본 spec은 역변환 추가:
  ```dart
  static DangerLevel? fromLowercaseString(String s) => switch (s) {
    'stable'   => DangerLevel.stable,
    'peaceful' => DangerLevel.peaceful,
    'tension'  => DangerLevel.tension,
    'threat'   => DangerLevel.threat,
    _          => null, // 미지의 값은 silent null
  };
  ```
- 위치: `features/investigation/domain/danger_level.dart` (페이즈 4 #1 신규 생성 파일).

#### FR-12: 가중치 계산 검증 시뮬레이션 (테스트 케이스)

- **시나리오 1 — region 31 stable + bandits_cleared (페이즈 2 #2 7절)**:
  - 입력: regionState (dangerLevel=stable, unlockedFlags=['region_31_bandits_cleared']), pool typeId='escort', difficulty=2.
  - 기대: weight = 1.0(NewbieGate) × 1.5(stable escort) × 1.5(bandits_cleared escort) = 2.25.
- **시나리오 2 — region 38 threat, 일반 raid 풀**:
  - 입력: regionState (dangerLevel=threat, unlockedFlags=[]), pool typeId='raid', difficulty=3.
  - 기대: weight = 1.0 × 3.0 × 1.0(flag 없음) = 3.0.
- **시나리오 3 — region_state_required 'threat' 풀, 현재 peaceful**:
  - 입력: pool.regionStateRequired='threat', regionState dangerLevel=peaceful.
  - 기대: weight = 0.0 (비노출).
- **시나리오 4 — cumulative cap 도달 후 노출 축소**:
  - 입력: pool.regionStateEffect=CumulativeEffect(thresholdFlag='region_31_bandits_cleared'), regionState.unlockedFlags 보유.
  - 기대: weight = 1.0 × dangerMulti × flagMulti × 0.2 (cap 도달 multiplier).
- **시나리오 5 — RegionState null (M7 외 region)**:
  - 입력: regionState=null, pool typeId='raid'.
  - 기대: weight = 1.0 × 1.0(peaceful fallback raid) = 1.0 (영향 없음, 기존 동작 유지).
- 테스트 파일: `test/features/quest/domain/region_state_weight_test.dart` 신규 생성. 5개 시나리오 ≥ 1 unit test.

### 2.2 데이터 요구사항

#### Hive 박스 / 모델

- **`RegionState`** (typeId 8): HiveField 11 신규 추가
  - `Map<String, int> questPoolCompletionCounts` (HiveField 11, default `{}`)
  - **페이즈 4 #1과의 충돌 회피**: 페이즈 4 #1 spec이 HiveField 8·9·10 점유 (dangerScore/dangerLevel/unlockedFlags) → 본 spec은 HiveField 11부터 사용.
  - 다음 HiveField: 12 (페이즈 4 #1 11 → 본 spec 적용 후 12로 시프트).
- build_runner 재실행: `region_state_model.g.dart`
- **신규 freezed 모델**: `RegionStateEffect` (sealed union, cumulative/oneshot 분기) — `core/models/region_state_effect.dart`
- **확장 freezed 모델**: `QuestPool` — `region_state_effect` / `region_state_required` / `region_state_excluded` 3 필드 추가
- build_runner 재실행: `region_state_effect.freezed.dart`/`.g.dart`, `quest_pool.freezed.dart`/`.g.dart`

#### Supabase 정적 데이터

- `quest_pools` 테이블 신규 3 컬럼 + 36행 INSERT (`Docs/content-data/m7_quest_pools_state.sql` — 본 spec 적용 시 일괄).
- CHECK 제약 2종 추가.
- `data_versions.version` 1 증가 (quest_pools 캐시 무효화).
- region_discoveries / band_achievement_templates / chain_quests / crafting_recipes — 변경 없음.

#### 신규 enum / 클래스

- `RegionStateEffect` sealed union: `CumulativeEffect`, `OneshotEffect` 두 case.
- `RegionStateWeightConfig` 정적 상수 클래스: `dangerLevelMultiplier`, `flagMultipliers`, `cumulativeCapReachedMultiplier`.
- `DangerLevel.fromLowercaseString` 헬퍼 (페이즈 4 #1 FR-2 확장).

#### 밸런스 수치 (페이즈 2 #2 4·5·6절)

- 4×4 매트릭스 16 셀 (모든 dangerLevel × {raid,hunt,escort,explore}).
- 8 flag × 1~2 quest_type = 14쌍.
- cumulativeCapReachedMultiplier = 0.2.
- cumulative 회당 -10, cap -50, cap 보너스 단발 -10 (페이즈 4 #1 FR-3 addDangerScore 통과).

### 2.3 UI 요구사항

**본 spec 범위 외** — UI 변경 없음.

- 본 spec은 도메인 로직 + 데이터 모델 + 마이그레이션만 다룸.
- `MovementScreen` region 카드 dangerLevel 색상 표시 등 UI는 페이즈 4 #3 spec (별도).
- `RegionStateChangedDialog`는 페이즈 4 #1 spec FR-5에서 처리.

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/models/quest_pool.dart` | regionStateEffect/regionStateRequired/regionStateExcluded 3 필드 추가 | FR-2 |
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.dart` | HiveField 11 questPoolCompletionCounts 추가 | FR-6 |
| `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart` | applyDangerScoreFromQuest 메서드 추가 | FR-7 |
| `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` | computeFinalWeight 메서드 추가, _weightedSample 시그니처 변경(regionState 인자), generateQuests 시그니처 확장 | FR-3, FR-4, FR-5 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | generateQuests 호출 3곳(라인 249·462·658) regionState 인자 추가, _applyCompletionResult trailing applyDangerScoreFromQuest 호출 추가 | FR-5, FR-8 |
| `band_of_mercenaries/lib/features/investigation/domain/danger_level.dart` (페이즈 4 #1 신규) | fromLowercaseString 헬퍼 추가 | FR-11 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/region_state_effect.dart` | RegionStateEffect freezed sealed union (cumulative/oneshot) (FR-2) |
| `band_of_mercenaries/lib/features/quest/domain/region_state_weight_config.dart` | 4×4 매트릭스 + 14 flag 가중치 + cap multiplier 정적 상수 (FR-3) |
| `band_of_mercenaries/test/features/quest/domain/region_state_weight_test.dart` | 가중치 계산 unit test 5 시나리오 (FR-12) |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/quest_pool.freezed.dart` | QuestPool 3 필드 추가 |
| `band_of_mercenaries/lib/core/models/quest_pool.g.dart` | QuestPool 3 필드 추가 |
| `band_of_mercenaries/lib/core/models/region_state_effect.freezed.dart` | 신규 sealed union |
| `band_of_mercenaries/lib/core/models/region_state_effect.g.dart` | 신규 sealed union fromJson |
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.g.dart` | HiveField 11 추가 (페이즈 4 #1 8·9·10 + 본 spec 11 통합) |

`dart run build_runner build --delete-conflicting-outputs` 1회 실행 필요 (페이즈 4 #1과 통합 implement 시 1회로 처리).

### 3.4 관련 시스템

- **페이즈 4 #1 (RegionState 시스템)**: 본 spec의 직접 의존. addDangerScore/toggleFlag/getOrCreateRegionState/DangerLevel enum/fromCacheInt/dangerLevelChangedProvider 모두 페이즈 4 #1에서 제공. **반드시 페이즈 4 #1 spec과 함께 implement** (FR-7·FR-11이 페이즈 4 #1 API에 의존).
- **페이즈 3 #4 SQL (`m7_quest_pools_state.sql`)**: 본 spec 적용 시점에 마이그레이션 일괄 적용 (FR-1).
- **QuestGenerator (기존)**: NewbieGate 분기 + named α=3 가중치 + sector 필터 + named hook + cooldown 모두 보존. 본 spec은 가중치 일원화(computeFinalWeight)만 추가.
- **QuestCompletionService / quest_provider._applyCompletionResult**: trailing fail-soft 패턴 답습 (M6 페이즈 4 #1 6 hook과 동일). 신규 7번째 hook 추가가 아닌 페이즈 4 #1 FR-4a 본체 활성화.
- **DataLoader**: 변경 없음 (자동 매핑).
- **QuestSortService**: 변경 없음 (regionState 필터는 발급 단계에서 처리).
- **operation-bom**: quest_pools 편집 폼에 신규 3 컬럼 추가 권장 (별도 PR).

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **JSONB 매핑 패턴**: `quest_pool.specialFlags` (`Map<String, dynamic>`) — Supabase JSONB ↔ Dart Map 자동 매핑. 단 본 spec은 더 강한 타입 안정성을 위해 sealed union 채택.
- **freezed sealed union**: 프로젝트 내 사용 예 — `regionState`/`trustLevelUp` event 클래스. JSON discriminator 패턴은 `chain_quest_progress.dart` `ChainQuestStatus` enum 참고하되, RegionStateEffect는 union 형태로 신규 도입. `freezed_annotation: ^2.4.0+` 의 `@FreezedUnionValue` 지원 확인 필요 — 미지원 시 일반 freezed class + factory + type discriminator 수동 분기로 대체.
- **HiveField Map<String, int>**: `Mercenary.stats` (`Map<String, int>`) — Hive 직렬화 검증된 패턴. typeAdapter 자동 처리.
- **RegionStateRepository fail-soft trailing**: `addSettlementTrust` (라인 145~280) — clamp + 단계 재계산 + ActivityLog + publish + grant + refreshAvailableQuests. `applyDangerScoreFromQuest`는 본 패턴 답습하되 내부 처리는 페이즈 4 #1 `addDangerScore`/`toggleFlag`로 위임.
- **QuestGenerator `_weightedSample`** (라인 226~258): 비복원 가중 샘플링 — 본 spec은 weight 계산 부분만 `computeFinalWeight`로 분리.
- **`_applyCompletionResult` trailing 패턴** (라인 1383~1419): 거점 사건 trailing → 신뢰도 trailing → ... 순차 fail-soft. 본 spec은 라인 1419~1433 다음에 region_state_effect trailing 추가.

### 4.2 주의사항

- **페이즈 4 #1과의 implement 순서**: 페이즈 4 #1을 먼저 implement (HiveField 8·9·10 + addDangerScore/toggleFlag/getOrCreateRegionState/DangerLevel enum/fromCacheInt) → 본 spec은 11·12 추가 + API 호출. **순서 역전 시 빌드 실패**.
- **build_runner 1회 통합 실행**: 페이즈 4 #1·#2 spec을 함께 implement 시 freezed/Hive 재생성을 1회로 처리. 별도 실행 시 `region_state_model.g.dart` 재생성 충돌 가능 → `--delete-conflicting-outputs` 플래그 필수.
- **`_weightedSample` 시그니처 변경 영향**: `QuestGenerator` 내부 private 메서드라 외부 호출 없음. 단, 향후 다른 위치에서 호출 시 컴파일 에러로 즉시 발견.
- **`region_state_required` enum 매핑 silent null**: 잘못된 값(예: `'unknown'`)은 `fromLowercaseString`이 null 반환 → 필터 무시 (모든 상태에서 노출). 데이터 검증은 CHECK 제약(FR-1 B)에서 DB 단계 차단.
- **`computeFinalWeight` weight=0 처리**: weight<=0인 풀은 `_weightedSample`에서 사전 제외 (`if (w <= 0) continue;` 패턴 유지). 따라서 비노출 정책이 자연스럽게 작동.
- **cumulative cap 도달 직전·직후 분기**: cap 도달 시점 자체에서 flag toggle + 단발 -10 보너스 적용. cap 도달 이후 추가 완료는 카운터만 증가 (delta 미적용 / 노출 빈도 0.2× 축소). 페이즈 2 #2 3절 정합.
- **cap_per_threshold 부호**: SQL 시드는 `cap_per_threshold = -50` (음수). FR-7 비교 `cumulativeDelta <= capPerThreshold`는 음수 비교 — 새 카운트 5 × -10 = -50 ≤ -50 시점에 cap 도달. 부등호 방향 주의.
- **settlement_3_pyegwang_reopen 이중 영향**: 페이즈 4 #1 FR-4b가 chain 완주 trailing에서 region 3 -30을 적용. 본 spec FR-8은 `is_fixed=true` 고정 의뢰가 settlement 6단계 완료 시 별도 region_state_effect 미부여 — 기획 분리 보장.
- **fixed 의뢰의 region_state_effect 처리**: `quest_pools` 36행은 모두 `is_fixed=false`. fixed 의뢰는 chain 완주 trailing(페이즈 4 #1 FR-4b)에서 처리. 본 spec FR-8은 일반/체인 step 양쪽 트리거하되 chain 완주의 oneshot delta와 중복 발생 가능성 — `OneshotEffect`의 flag 멱등성으로 안전 (이미 보유 시 skip).
- **decay와의 충돌**: decay는 dangerScore<0일 때만 +1. quest 완료로 dangerScore 변동 시 decay 카운터 리셋되지 않음 (페이즈 4 #1 FR-4d 정적 Map 갱신은 decay 적용 시점에만). 동시 적용 가능. 정상 동작.
- **operation-bom JSONB 편집**: 본 spec 영역 외. 본 spec 적용 후 별도 PR 권장.

### 4.3 엣지 케이스

- **regionState=null (M7 외 region 의뢰 발급)**: `computeFinalWeight`에서 dangerLevel=peaceful fallback + flag multiplier skip → 기존 가중치(1.0× × NewbieGate weight) 유지. M7 외 33 리전(T4~T10)에 영향 없음.
- **regionStateEffect=null (대부분 풀)**: cumulative cap 검증 분기 미실행. weight 영향 없음.
- **regionStateRequired와 regionStateExcluded 동시 설정**: 양쪽 모두 검증. required 일치 + excluded 일치(같은 값)는 논리 모순이나 weight=0으로 자연 차단. CHECK 제약 추가 권장이나 본 spec 미포함 (DB 데이터 검증).
- **questPoolCompletionCounts 무한 증가**: cap 도달 후에도 카운터는 증가 — Map<String, int>는 메모리 영향 무시. 단 cap 도달 이후 도적 의뢰 자체가 0.2× 노출되므로 실질 증가 속도 둔화.
- **cumulative + region_state_required 동시 설정**: 가능. 예: `region_state_required='threat'` + cumulative effect — threat 상태에서만 노출되는 cumulative 풀. weight=0 분기가 우선 (required 불일치 시 effect 미적용 — cap 도달 전 단계에서는 노출되지 않으므로 자연 작동).
- **quest_pool_id 변경 또는 삭제**: questPoolCompletionCounts에 orphan key 발생 가능. Hive Map은 silent 보존. 정리 정책 없음 (M7 MVP). M9+ 데이터 마이그레이션 시 검토.
- **카운터 추적이 region별 독립**: region 31에서 도적 의뢰 3회 완료 후 region 38에서 같은 quest_pool(차후 데이터 추가 시) 완료해도 별도 카운터. 의도된 동작.
- **flag 토글 직전 quest 완료**: cap 도달 시 toggle + 보너스 -10이 같은 await 체인 내에서 순차 실행. dangerLevel 전이 publish는 보너스 적용 후. 안전.
- **단일 quest 완료로 dangerLevel 다단계 전이**: 예 — region 146 안개 해소 -50이 tension(+30) → stable(-50) 직행 (3단계 전이). 페이즈 4 #1 FR-5의 isBigTransition 판정 식이 `(from.index - to.index).abs() >= 2`이므로 자연 큰 전이 처리.
- **build_runner 실패 — sealed union 미지원 freezed 버전**: `freezed_annotation < 2.4` 시 `@FreezedUnionValue` 미지원. 대안 — 일반 freezed factory + 별도 헬퍼 `RegionStateEffect.fromJson()`에서 `type` 분기 (`if (json['type'] == 'cumulative') return CumulativeEffect.fromJson(json)` 등). [Q-1] 참조.
- **테스트 작성**: RegionState mock 또는 실제 Hive box (test 디렉토리). 기존 `test/features/quest/domain/quest_calculator_test.dart` 패턴 답습.

### 4.4 구현 힌트

- **진입점**:
  - 가중치 계산: `QuestGenerator.computeFinalWeight()` 신규 (FR-4)
  - quest 완료 trailing: `quest_provider.dart _applyCompletionResult` 라인 1419~1437 사이 (FR-8)
  - 정적 상수: `RegionStateWeightConfig` (FR-3)
- **데이터 흐름**:
  1. quest 완료 → `_applyCompletionResult` 실행
  2. 거점 trailing + 신뢰도 trailing 후 region_state_effect trailing 분기 (FR-8)
  3. `applyDangerScoreFromQuest(regionId, pool, ref)` → 페이즈 4 #1 `addDangerScore`/`toggleFlag` 호출
  4. RegionState 갱신 + dangerLevelChangedProvider publish + 위업 hook + refreshAvailableQuests
  5. 다음 발급: `generateQuests(regionState: ...)` → `_weightedSample(regionState)` → `computeFinalWeight()` 가중치 적용
  6. region 상태에 따라 quest_pool 분포 차별화 (예: stable region 31에서 escort 49% 점유)
- **참조 구현**:
  - `quest_generator.dart:208~258` — `_weightFor`/`_weightedSample` 기존 구조
  - `quest_pool.dart:7~44` — freezed 모델 확장 패턴 (@JsonKey snake_case)
  - `region_state_repository.dart:78~89` — `addAcquiredMaterial` 멱등 List 추가 패턴 (toggleFlag와 유사)
  - `region_state_repository.dart:145~280` — `addSettlementTrust` clamp + 단계 재계산 + trailing 통합
  - `quest_provider.dart:1383~1419` — `_applyCompletionResult` trailing 패턴 (거점 사건 + 신뢰도)
  - `quest_provider.dart:1457~` — `_updateNamedCooldownsForQuests` Map merge + 단일 save 패턴 (questPoolCompletionCounts 갱신 시 참고)
- **확장 지점**:
  - 4×4 매트릭스 추가 quest_type (labor/survey): `RegionStateWeightConfig.dangerLevelMultiplier` 16 셀 → 24 셀 확장
  - 9번째 flag 추가: `flagMultipliers` Map에 1행 추가
  - cumulative 이외 effect 타입(예: triggered_by_chain): `RegionStateEffect` sealed union에 case 추가

## 5. 기획 확인 사항

- **[Q-1] freezed sealed union `@FreezedUnionValue` 지원 여부** → `pubspec.yaml` freezed_annotation 버전 확인 필요. **본 spec 권장: 2.4+ 사용. 미지원 시 일반 freezed class 2개(CumulativeEffect / OneshotEffect) + `RegionStateEffect.fromJson()` factory 분기**로 우회. implement 단계에서 결정.
- **[Q-2] cumulative 카운터 저장 위치 (RegionState vs UserData)** → 본 spec 채택: **RegionState.questPoolCompletionCounts (HiveField 11)**. 이유 — region별 독립 추적이 자연스럽고, UserData 변경 회피. M9+ 운영 도구 확장 시 RegionState dump 한 번에 추적 가능.
- **[Q-3] regionStateEffect를 freezed sealed union으로 강타입화 vs Map<String, dynamic> 유지** → 본 spec 채택: **sealed union (FR-2)**. 이유 — cumulative/oneshot 분기 시 컴파일 시점 검증, switch 패턴 매칭으로 누락 방지. special_flags 패턴(Map)과 다른 이유는 effect 구조가 안정적이고 분기 명확.
- **[Q-4] computeFinalWeight 내부에 NewbieGate + named α=3 통합 vs `_weightedSample`에 분리 유지** → 본 spec 채택: **통합 (FR-4)**. 이유 — 가중치 계산 단일 진입점 보장. 단, _weightFor는 NewbieGate 분기만 담당하는 내부 헬퍼로 유지.
- **[Q-5] region_state_required/excluded 필터를 generalPools.where()로 사전 제외 vs computeFinalWeight weight=0** → 본 spec 채택: **computeFinalWeight 내부 weight=0 (FR-4)**. 이유 — 필터 일원화. `_weightedSample`의 `if (w <= 0) continue;`로 효율 손실 없음.
- **[Q-6] quest_pool_id별 카운터 cap 도달 후 카운터 계속 증가 vs 멈춤** → 본 spec 채택: **계속 증가 (FR-7)**. 이유 — 운영 도구·디버그용 통계로 활용 가능. cap 도달 후 delta 적용은 멈춤(if 분기) — 의미 분리.
- **[Q-7] settlement_3_pyegwang_reopen step 완료 시 region_state_effect 트리거** → 본 spec 채택: **트리거 (FR-8)**. settlement step의 quest_pool도 region_state_effect 보유 가능. 단 페이즈 3 #4 SQL 36행에는 settlement 풀이 없으므로 실질 영향 없음. 페이즈 4 #1 FR-4b의 chain_id='settlement_3_pyegwang_reopen' → region 3 -30 (oneshot delta) trailing은 별도 경로 — 본 spec과 중복 없음.
- **[Q-8] 가중치 계산 unit test 위치** → 본 spec 채택: **`test/features/quest/domain/region_state_weight_test.dart` 신규** (FR-12 5 시나리오). 기존 quest_calculator_test.dart 패턴 답습.
- **[Q-9] operation-bom table-config.ts 신규 3 컬럼 등록** → 본 spec 영역 외. 별도 PR 위임. 본 spec implement 후 안내.
- **[Q-10] decay 적용 시 cumulative 카운터 영향** → 본 spec 채택: **영향 없음**. decay는 dangerScore에만 영향 (페이즈 4 #1 FR-4d), 카운터는 quest 완료 시점에만 갱신. M8+ region 회귀 후 도적 의뢰 재발 시 카운터는 이미 5 이상이므로 cap 도달 상태 유지 (flag도 영구 보존). decay로 인한 재무장 시나리오는 M8+ flag 해제 메커니즘과 함께 재검토.
- **[Q-11] regionState 미존재(getState=null) 시 자동 생성 vs null 전달** → 본 spec 채택: **null 전달 (FR-5)**. computeFinalWeight 내부에서 peaceful fallback. 자동 생성은 quest 완료 trailing(FR-7 applyDangerScoreFromQuest)에서 getOrCreateRegionState로 처리 — 발급 시점 자동 생성은 불필요한 Hive write 회피.
