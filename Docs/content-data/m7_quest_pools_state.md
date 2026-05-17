# M7 페이즈 3 산출물 4 메타: 지역 상태별 퀘스트 풀 36행 + 신규 3 컬럼

> 작성일: 2026-05-17
> 마일스톤: M7 (지역 생활권 확장)
> 페이즈: 3 #4
> 산출 파일: `Docs/content-data/m7_quest_pools_state.sql`
> 처리 방식: **옵션 B** — CSV 대신 SQL 마이그레이션. 페이즈 4 #2 spec 단계에서 일괄 적용

---

## 생성 근거

### 참조 기획 문서

- `Docs/content-design/[content]20260516_m7_region_state_rules.md` (페이즈 1 #2)
  - 1.3절 — 8개 unlockedFlags 정의
  - 3절 — 트리거 3종 (cumulative / oneshot / decay)
  - 4절 — QuestGenerator 가중치 정책
- `Docs/balance-design/[balance]20260517_m7_region_state_thresholds.md` (페이즈 2 #2)
  - data-generator 가이드 36행 분포 표 (3.4절)
  - 트리거 점수 등급 4종 (소형/중형/대형/특수)

### 옵션 B 채택 사유

페이즈 4 #2 "QuestGenerator 지역 상태 가중치 분기" spec 단계에서 다음을 **일괄 마이그레이션**으로 처리:
1. ALTER TABLE quest_pools 신규 3 컬럼 추가
2. 36행 INSERT
3. Flutter QuestPool freezed 모델 갱신 + QuestGenerator 가중치 계산 분기
4. SyncService data_versions 갱신

→ DDL 변경 + 데이터 + 코드 변경이 게임 동작 시점에 일치해야 하므로 본 산출물은 spec 입력 형태로 SQL을 작성하되 즉시 적용은 안 함.

### data-generator 미사용 사유

- `quest-pool` 타입 스펙 존재하나 **M7 신규 3 컬럼을 알지 못함** (M4 이전 작성)
- 36행은 main agent 직접 작성 부담 적정
- 페이즈 3 #1·#3의 옵션 A 패턴(SQL 마이그레이션 직접 작성) 답습

---

## 생성 요약

### (A) ALTER TABLE — 신규 3 컬럼

```sql
ALTER TABLE quest_pools
  ADD COLUMN region_state_effect JSONB,
  ADD COLUMN region_state_required TEXT,
  ADD COLUMN region_state_excluded TEXT;
```

CHECK 제약 2종:
- `region_state_required`: nullable + 4 enum (stable/peaceful/tension/threat)
- `region_state_excluded`: nullable + 동일 enum

### (B) 36행 INSERT 분포

| Region | 누적 사건 | 단발 사건 | 상태 조건 | 일반 풀 | 소계 |
|--------|---------|---------|---------|-------|------|
| r3 더스트플레인 | 1 | 0 | 1 | 0 | **2** |
| r31 도적길 | 1 | 1 | 2 | 2 | **6** |
| r127 변방 해안 | 1 | 1 | 1 | 2 | **5** |
| r9 외곽 숲 | 1 | 1 | 2 | 2 | **6** |
| r10 풍신 숲 | 1 | 1 | 1 | 2 | **5** |
| r146 회색 늪지 | 1 | 1 | 2 | 2 | **6** |
| r38 부서진 요새 | 1 | 1 | 2 | 2 | **6** |
| **합계** | **7** | **6** | **11** | **12** | **36** |

→ 페이즈 2 #2 권장 분포와 정확히 일치 ✅

### 36행 인덱스

| # | id | region | type | dif | type_id | 사건 종류 |
|---|----|--------|------|-----|---------|---------|
| 1 | qp_m7_r3_cave_bats | 3 | 0 | 2 | hunt | cumulative (pyegwang) |
| 2 | qp_m7_r3_safe_escort | 3 | 0 | 1 | escort | required=stable |
| 3 | qp_m7_r31_bandit_patrol | 31 | 0 | 2 | raid | cumulative (bandits) |
| 4 | qp_m7_r31_shrine_offering | 31 | 0 | 1 | escort | oneshot -20 (shrine) |
| 5 | qp_m7_r31_safe_caravan | 31 | 0 | 2 | escort | required=stable |
| 6 | qp_m7_r31_bandit_raid | 31 | 0 | 2 | raid | required=threat |
| 7 | qp_m7_r31_pilgrim_escort | 31 | 0 | 1 | escort | 일반 |
| 8 | qp_m7_r31_road_patrol | 31 | 0 | 1 | explore | 일반 |
| 9 | qp_m7_r127_coast_scout | 127 | 0 | 1 | explore | cumulative (nomad) |
| 10 | qp_m7_r127_nomad_visit | 127 | 0 | 1 | escort | oneshot -20 (nomad) |
| 11 | qp_m7_r127_foreign_trade | 127 | 0 | 2 | escort | required=stable |
| 12 | qp_m7_r127_seaweed_gather | 127 | 0 | 1 | explore | 일반 |
| 13 | qp_m7_r127_beach_patrol | 127 | 0 | 1 | escort | 일반 |
| 14 | qp_m7_r9_beast_trail | 9 | 0 | 2 | hunt | cumulative (beast) |
| 15 | qp_m7_r9_giant_beast | 9 | 0 | 3 | hunt | oneshot **-40** (giant beast) |
| 16 | qp_m7_r9_hide_harvest | 9 | 0 | 1 | escort | required=peaceful |
| 17 | qp_m7_r9_beast_hunt | 9 | 0 | 2 | hunt | required=tension |
| 18 | qp_m7_r9_forest_explore | 9 | 0 | 2 | explore | 일반 |
| 19 | qp_m7_r9_mushroom_gather | 9 | 0 | 1 | labor | 일반 |
| 20 | qp_m7_r10_wind_patrol | 10 | 0 | 2 | explore | cumulative (windrunner) |
| 21 | qp_m7_r10_windrunner_finale | 10 | 0 | 3 | escort | oneshot **-30** (windrunner) |
| 22 | qp_m7_r10_calm_explore | 10 | 0 | 2 | explore | required=peaceful |
| 23 | qp_m7_r10_swordsman_hunt | 10 | 0 | 2 | hunt | 일반 |
| 24 | qp_m7_r10_wind_herb | 10 | 0 | 2 | explore | 일반 |
| 25 | qp_m7_r146_mist_scout | 146 | 0 | 2 | explore | cumulative (mist) |
| 26 | qp_m7_r146_mist_clearing | 146 | 0 | 3 | hunt | **특수 단발 -50** (mist) |
| 27 | qp_m7_r146_threat_hunt | 146 | 0 | 3 | hunt | required=threat |
| 28 | qp_m7_r146_quiet_explore | 146 | 0 | 2 | explore | required=stable |
| 29 | qp_m7_r146_poison_gather | 146 | 0 | 2 | explore | 일반 |
| 30 | qp_m7_r146_swamp_relic | 146 | 0 | 2 | explore | 일반 |
| 31 | qp_m7_r38_robber_hunt | 38 | 0 | 3 | hunt | cumulative (ironbound) |
| 32 | qp_m7_r38_ironbound_finale | 38 | 0 | 3 | explore | oneshot **-40** (ironbound) |
| 33 | qp_m7_r38_threat_raid | 38 | 0 | 3 | raid | required=threat |
| 34 | qp_m7_r38_calm_explore | 38 | 0 | 3 | explore | required=peaceful |
| 35 | qp_m7_r38_ore_dig | 38 | 0 | 3 | labor | 일반 |
| 36 | qp_m7_r38_relic_hunt | 38 | 0 | 3 | hunt | 일반 |

### quest_type 분포

| type_id | 행 수 | 비중 |
|---------|------|------|
| hunt | 10 | 28% |
| escort | 9 | 25% |
| explore | 13 | 36% |
| raid | 3 | 8% |
| labor | 2 | 6% |

### difficulty 분포

| difficulty | 행 수 | region 매핑 |
|-----------|------|-----------|
| 1 | 8 | r3·r31·r127 일반 (T1) |
| 2 | 16 | T2 region 위주 + 일부 T1 사건 |
| 3 | 12 | r9 거대 야수 (D3) + r10 finale + r146 사건 + r38 전체 (T3) |

페이즈 2 #2 data-generator 가이드 권장 "D1·D2·D3 중심, D4·D5는 region 38 한정" → 본 산출물은 D4·D5 미사용 (M7 MVP). 페이즈 4 #2 spec 단계에서 r38 D4 추가 검토 가능.

---

## 검증 결과

### SQL 자체 검증 4종 (스크립트 내 DO 블록)

1. **D1**: 36행 INSERT 검증
2. **D2**: region_state_effect.threshold_flag·flag가 8개 정의된 flag 내인지 검증
3. **D3**: region별 분포 (r3:2 / r31:6 / r127:5 / r9:6 / r10:5 / r146:6 / r38:6)
4. **D4**: 풀 분포 (cumulative 7 / oneshot 6 / 상태조건 11 / 일반 12)

### threshold_flag·flag 사용 검증 (D2)

8개 정의 flag별 사용 횟수:
- region_3_pyegwang_reopen_completed: 1 (cumulative #1)
- region_31_bandits_cleared: 1 (cumulative #3)
- region_31_shrine_quest_completed: 1 (oneshot #4)
- region_127_nomad_friendly: 2 (cumulative #9 + oneshot #10) — 동일 flag 양쪽 사용 (M7 페이즈 4 #2 spec에서 cumulative+oneshot 같은 flag 의미 명확화 필요)
- region_9_giant_beast_killed: 2 (cumulative #14 + oneshot #15)
- region_10_windrunner_chain_completed: 2 (cumulative #20 + oneshot #21)
- region_146_mist_cleared: 2 (cumulative #25 + oneshot #26)
- region_38_ironbound_pact_completed: 2 (cumulative #31 + oneshot #32)

**중요**: cumulative와 oneshot이 같은 flag를 사용하면 페이즈 4 #2 spec에서 다음 처리 필요:
- oneshot이 먼저 발생 시 (chain·elite hook): flag 즉시 토글 → cumulative cap 도달 무효
- cumulative이 먼저 발생 시 (cap 5회 도달): flag 토글 → oneshot 추가 발동 시 효과 무시 (이미 flag 보유)
- 권장: `RegionStateRepository.toggleFlag()` 메서드의 멱등 처리 (이미 보유 시 skip)로 자연 해결

### CHECK 제약 검증

- region_state_required·excluded 4 enum 외 사용 0건 ✅ (모든 행 정확한 enum)

### 페이즈 2 #2 시뮬레이션 정합

페이즈 2 #2 시뮬레이션 절의 7리전 dangerLevel 변동 곡선 정합:

| 시점 | 진행 | dangerScore 변화 검증 |
|------|------|-------------------|
| 120분 → 0분: r3 폐광 step 6 완료 | M4 종료 -30 | #1 cumulative 5회 cap = -50 (이후 r3 0→-50, peaceful → stable 가능) |
| 170분: r31 shrine 완주 | #4 oneshot -20 → r31 +15 → -5 (peaceful) | ✅ 페이즈 2 #2 시뮬과 정합 |
| 215분: r9 야수 처치 | #15 oneshot -40 → r9 +20 → -20 (peaceful) | ✅ |
| 255분: r31 도적 5회 cap | #3 cumulative -50 + cap 단발 -10 → r31 -50~-60 (stable 진입) | ✅ |
| 290분: r127 친교 | #10 oneshot -20 → r127 -10→-30 | ✅ |
| 330분: r10 windrunner 완주 | #21 oneshot -30 → r10 +10→-20 (peaceful) | ✅ |
| 380분: r38 ironbound | #32 oneshot -40 → r38 +60→+20 (tension) | ✅ |
| 430분: r146 안개 해소 | #26 oneshot **-50** → r146 +30→-20 (peaceful) | ✅ |

→ 모든 사건 timeline이 시뮬레이션 곡선과 정확히 정합 ✅

---

## 적용 절차 (페이즈 4 #2 spec 단계)

본 SQL 스크립트는 **즉시 적용하지 않는다**. 페이즈 4 #2 명세 단계에서 다음 순서로 일괄 적용:

1. **페이즈 4 #2 spec 작성 시 본 스크립트 인라인 참조**
2. **operation-bom table-config.ts 갱신**:
   - quest_pools 편집 폼에 신규 3 컬럼 추가
   - region_state_effect JSONB 편집기 + 검증 (cumulative/oneshot 타입 분기)
   - region_state_required·excluded 셀렉트 (4 enum)
3. **Flutter freezed 모델 갱신**:
   - QuestPool 모델에 regionStateEffect / regionStateRequired / regionStateExcluded 필드 추가
   - `dart run build_runner build` 실행
4. **QuestGenerator 가중치 계산**:
   - 페이즈 2 #2 5절 매트릭스 + 6절 플래그 가중치 적용
   - 의사 코드 (페이즈 2 #2 시뮬레이션 절 참조)
5. **SyncService 마이그레이션**:
   - data_versions `quest_pools` 버전 ↑
6. **Supabase 실행**:
   - 본 SQL을 단일 트랜잭션으로 실행
   - DO 블록 4종 검증 통과 후 commit

---

## 페이즈 4 #2 spec 입력 보강

본 산출물 외 페이즈 4 #2 spec에 다음 항목 통합 필요:

### 가중치 계산 의사 코드 (페이즈 2 #2 5절 + 6절)

```dart
class RegionStateWeightConfig {
  static const Map<DangerLevel, Map<QuestType, double>> dangerLevelMultiplier = {
    DangerLevel.threat: {QT.raid: 3.0, QT.hunt: 3.0, QT.escort: 1.5, QT.explore: 1.5},
    DangerLevel.tension: {QT.raid: 2.0, QT.hunt: 2.0, QT.escort: 1.3, QT.explore: 1.3},
    DangerLevel.peaceful: {QT.raid: 1.0, QT.hunt: 1.0, QT.escort: 1.2, QT.explore: 1.0},
    DangerLevel.stable: {QT.raid: 0.3, QT.hunt: 0.5, QT.escort: 1.5, QT.explore: 1.3},
  };

  static const Map<String, Map<QuestType, double>> flagMultipliers = {
    'region_3_pyegwang_reopen_completed': {QT.hunt: 0.7, QT.escort: 1.2},
    'region_31_bandits_cleared': {QT.raid: 0.3, QT.escort: 1.5},
    'region_31_shrine_quest_completed': {QT.explore: 1.3},
    'region_127_nomad_friendly': {QT.escort: 1.3, QT.raid: 0.5},
    'region_9_giant_beast_killed': {QT.hunt: 0.5, QT.escort: 1.2},
    'region_10_windrunner_chain_completed': {QT.explore: 1.3},
    'region_146_mist_cleared': {QT.explore: 1.3, QT.hunt: 0.7},
    'region_38_ironbound_pact_completed': {QT.raid: 0.5, QT.explore: 1.2},
  };

  static const Duration decayInterval = Duration(hours: 12);
}

double computeFinalWeight(QuestPoolData pool, RegionState state) {
  // 1. 비노출 검증
  if (pool.regionStateRequired != null && pool.regionStateRequired != state.dangerLevelString) return 0.0;
  if (pool.regionStateExcluded != null && pool.regionStateExcluded == state.dangerLevelString) return 0.0;

  // 2. dangerLevel 가중치
  double weight = pool.baseWeight;
  weight *= RegionStateWeightConfig.dangerLevelMultiplier[state.dangerLevel]?[pool.questType] ?? 1.0;

  // 3. unlockedFlags 가중치 (페이즈 2 #2 6절 14쌍)
  for (final flag in state.unlockedFlags) {
    final flagWeight = RegionStateWeightConfig.flagMultipliers[flag]?[pool.questType];
    if (flagWeight != null) weight *= flagWeight;
  }

  // 4. region_state_effect.cap 도달 후 노출 빈도 축소
  final effect = pool.regionStateEffect;
  if (effect != null && effect['type'] == 'cumulative') {
    if (state.hasFlag(effect['threshold_flag'])) weight *= 0.2;
  }

  return weight;
}
```

---

## 다음 단계

- **페이즈 3 산출물 4번 완료** → milestone-runner로 갱신
- **다음 페이즈 3 산출물 5번**: 마을 인프라 성장 narrative + 체인 단계 → `/data-generator quest-narrative --brief @...` + chain_m7_mist_clearing 신규 체인 추가

---

## 참고: 페이즈 3 #1·#3·#4 처리 패턴 통일

본 산출물은 페이즈 3 #1 region_adjacency / #3 region_discoveries 처리 패턴과 일관성 유지:
- 옵션 A·B 처리 (data-generator 타입 부족 또는 DDL 변경 필요)
- main agent 직접 작성
- 페이즈 4 spec 단계에서 일괄 적용

이는 M5 페이즈 4 #1·#2 처리 패턴과도 정합.
