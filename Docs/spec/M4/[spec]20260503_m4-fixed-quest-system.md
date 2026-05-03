# 명세서: M4 고정 의뢰 시스템 — quest_pools 컬럼 확장 + 노출 로직

> 작성일: 2026-05-03  
> 마일스톤: M4 페이즈 4 #3  
> 선행 명세:  
> - `Docs/spec/M4/[spec]20260503_m4-region-migration.md` (페이즈 4 #1)  
> - `Docs/spec/M4/[spec]20260503_m4-region-sectors.md` (페이즈 4 #2)  
> 후속 명세:  
> - 페이즈 4 #4 "마을 방문 UI + 약초상/의무실 분리" — 본 명세의 min_trust_level 노출 분기를 UI에서 반영  
> - 페이즈 4 #5 "마을 신뢰도 시스템 + 고정 사건 진행 상태" — 본 명세의 인터페이스 stub을 실제 구현으로 교체

---

## 1. 기능 목적

더스트빌(region_id 3) 시작 거점에 두 종류의 신규 의뢰 데이터를 추가하고, 노출 로직을 구현한다.

1. **"폐광길 재개방" 고정 사건 라인 6단계** (`dustvile_pyegwang_reopen`): trust_threshold + 이전 단계 완료 조건으로 점진 노출. 자동 갱신 주기에서 제외, 실패 후 재등장 보장.
2. **더스트빌 허드렛일 10건** (`dustvile_chore_NN`): 신규 labor 타입 포함 난이도 1 시작 풀. `min_trust_level` 컬럼으로 단계별 노출 제어 (채집 의뢰는 신뢰도 2단계 이상에서만 노출).
3. **dungeon/field 신규 풀 통합 여부**: 옵션 B — 별도 페이즈로 분리. (5. 기획 확인 사항 Q1 참조)

이를 위해 `quest_pools` 테이블에 9개 컬럼을 추가하고, `QuestPool` Freezed 모델과 `QuestGenerator`·`QuestListNotifier`의 필터 로직을 확장한다.

---

## 2. 요구사항

### 2.1 기능 요구사항

| ID | 요구사항 |
|----|---------|
| REQ-01 | `quest_pools` 테이블에 9개 컬럼 추가 (단일 트랜잭션 마이그레이션) |
| REQ-02 | `QuestPool` Freezed 모델에 9개 필드 추가 (snake_case @JsonKey) |
| REQ-03 | `QuestGenerator.generateQuests`에서 `is_fixed=true` 행을 일반 갱신 풀에서 제외 |
| REQ-04 | `QuestGenerator.generateQuests`에서 `min_trust_level <= currentTrustLevel` 필터 추가 |
| REQ-05 | 별도 고정 의뢰 노출 흐름 구현: trust_threshold + currentStep 조건으로 ActiveQuest 생성 |
| REQ-06 | `_checkQuestRefresh()` 내 is_fixed=true 의뢰는 만료·교체 제외 |
| REQ-07 | 단계 완료 시 다음 step 자동 노출: `QuestListNotifier.refreshAvailableQuests()` 메서드 시그니처 정의 |
| REQ-08 | `ChainTopSection`에서 `settlement_` prefix를 가진 chainId 퀘스트를 제외 (UI 분리) |
| REQ-09 | `QuestSortService`에서 거점 사건 카드를 일반 목록 최상단(신규 Tier 0.5)에 배치 |
| REQ-10 | SQL INSERT: `dustvile_pyegwang_reopen` 6행 + `dustvile_chore_NN` 10행 |
| REQ-11 | `data_versions` 테이블 `quest_pools` 버전 증가 |

### 2.2 데이터 요구사항

#### 2.2.1 마이그레이션 파일

**파일 경로**: `band_of_mercenaries/supabase/migrations/20260503_m4_phase4_3_quest_pools_extension.sql`

```sql
-- M4 페이즈 4 #3: quest_pools 컬럼 확장 + 더스트빌 고정 의뢰 데이터
-- 작성일: 2026-05-03
-- 명세서: Docs/spec/M4/[spec]20260503_m4-fixed-quest-system.md
-- 선행 조건: 20260503_m4_phase4_2_region_sectors.sql 적용 완료
-- 단일 트랜잭션. 실패 시 전체 롤백.

BEGIN;

-- §1. quest_pools 신규 컬럼 9개 추가 (REQ-01)
-- 페이즈 1 #4 컬럼 4개
ALTER TABLE quest_pools ADD COLUMN is_fixed BOOL NOT NULL DEFAULT false;
ALTER TABLE quest_pools ADD COLUMN fixed_chain_id TEXT NULL;
ALTER TABLE quest_pools ADD COLUMN fixed_step INT NULL CHECK (fixed_step BETWEEN 1 AND 20);
ALTER TABLE quest_pools ADD COLUMN trust_threshold INT NULL CHECK (trust_threshold BETWEEN 1 AND 4);

-- 페이즈 2 #4 컬럼 4개 (보상/시간 override)
ALTER TABLE quest_pools ADD COLUMN reward_gold_override INT NULL;
ALTER TABLE quest_pools ADD COLUMN reward_xp_bonus_override INT NULL;
ALTER TABLE quest_pools ADD COLUMN duration_override_seconds INT NULL;
ALTER TABLE quest_pools ADD COLUMN trust_reward_override INT NULL;

-- 페이즈 2 #3 컬럼 1개 (단계별 노출 제어)
ALTER TABLE quest_pools ADD COLUMN min_trust_level INT NOT NULL DEFAULT 0;

-- §2. UNIQUE 제약: 동일 chain의 동일 step 중복 방지 (is_fixed=true 행 한정)
-- is_fixed=false 행은 fixed_chain_id/fixed_step이 null이므로 제약 적용 안 됨
CREATE UNIQUE INDEX idx_quest_pools_fixed_chain_step
  ON quest_pools (fixed_chain_id, fixed_step)
  WHERE is_fixed = true;

-- §3. dustvile_pyegwang_reopen 6단계 INSERT (REQ-10)
-- 기획 근거: [content]20260503_settlement-trust-and-fixed-events.md 2.2절 + [balance]20260503_fixed-quest-curve.md 조정 1~6
INSERT INTO quest_pools (
  id, name, type, difficulty,
  min_region_diff, max_region_diff,
  type_id, sector_type,
  is_fixed, fixed_chain_id, fixed_step, trust_threshold,
  reward_gold_override, reward_xp_bonus_override,
  duration_override_seconds, trust_reward_override,
  min_trust_level, enemy_name,
  description
) VALUES
  -- step 1: 폐광 입구 정찰 (explore Lv1, dungeon)
  -- duration 300s=5분, 신뢰도 +10, 골드 기본 80G (override null)
  ('qp_pyegwang_step1', '폐광 입구 정찰', 0, 1,
   1, 1,
   'explore', 'dungeon',
   true, 'settlement_3_pyegwang_reopen', 1, 1,
   NULL, NULL,
   300, 10,
   1, '박쥐 떼',
   '촌장의 부탁. 오래 방치된 폐광 입구를 살펴보고 진입 가능 여부를 보고한다. 박쥐 떼와 대치할 수 있다.'),

  -- step 2: 도굴꾼 흔적 추적 (hunt Lv1, field)
  -- duration 300s=5분, 신뢰도 +15, 골드 기본 120G (override null)
  ('qp_pyegwang_step2', '도굴꾼 흔적 추적', 0, 1,
   1, 1,
   'hunt', 'field',
   true, 'settlement_3_pyegwang_reopen', 2, 1,
   NULL, NULL,
   300, 15,
   1, '도굴꾼 일당',
   '폐광 주변에서 발견된 수상한 흔적을 마른 초원까지 추적한다. 도굴꾼들이 외곽에 숨어 있는 것으로 보인다.'),

  -- step 3: 박쥐 둥지 소탕 (raid Lv2, dungeon)
  -- duration 360s=6분, 신뢰도 +20, 골드 200G override (+50 보너스)
  ('qp_pyegwang_step3', '박쥐 둥지 소탕', 0, 2,
   1, 1,
   'raid', 'dungeon',
   true, 'settlement_3_pyegwang_reopen', 3, 2,
   200, NULL,
   360, 20,
   2, '거대 박쥐 둥지',
   '폐광 내부에 자리 잡은 거대 박쥐 둥지를 소탕한다. 처음으로 폐광 깊숙이 들어가는 위험한 임무.'),

  -- step 4: 광부의 도구 회수 (escort Lv2, dungeon)
  -- duration 300s=5분, 신뢰도 +25, 골드 185G override (+50 보너스)
  ('qp_pyegwang_step4', '광부의 도구 회수', 0, 2,
   1, 1,
   'escort', 'dungeon',
   true, 'settlement_3_pyegwang_reopen', 4, 2,
   185, NULL,
   300, 25,
   2, '무너진 갱도',
   '마을 노인이 폐광에 두고 온 도구를 찾기 위해 동행한다. 무너진 갱도를 헤쳐 나가야 한다.'),

  -- step 5: 갱도 안전 확보 (raid Lv3, dungeon)
  -- duration 600s=10분, 신뢰도 +30, 골드 270G override (+50 보너스)
  ('qp_pyegwang_step5', '갱도 안전 확보', 0, 3,
   1, 1,
   'raid', 'dungeon',
   true, 'settlement_3_pyegwang_reopen', 5, 3,
   270, NULL,
   600, 30,
   3, '갱도 깊숙한 위협',
   '폐광 재개방 전 마지막 안전 확보 작업. 무너진 갱도를 보강하고 잔여 위협을 제거한다.'),

  -- step 6: 폐광 재개방식 (survey Lv3, village)
  -- duration 600s=10분, 신뢰도 +100, 골드 500G override (survey base_reward=0 우회), XP +50 보너스
  ('qp_pyegwang_step6', '폐광 재개방식', 0, 3,
   1, 1,
   'survey', 'village',
   true, 'settlement_3_pyegwang_reopen', 6, 3,
   500, 50,
   600, 100,
   3, NULL,
   '마을 광장에서 열리는 폐광 재개방식을 안전하게 진행한다. 마을 전체가 지켜보는 클라이맥스 임무.');

-- §4. dustvile_chore_NN 허드렛일 10건 INSERT (REQ-10)
-- 기획 근거: [balance]20260503_chore-quest-economy.md 2절 허드렛일 풀 컨셉
-- 모두 difficulty=1, min_region_diff=1, max_region_diff=1 (더스트플레인 T1 한정)
-- min_trust_level=0 (기본, 모든 단계에서 노출) 단, dustvile_chore_03만 min_trust_level=2
INSERT INTO quest_pools (
  id, name, type, difficulty,
  min_region_diff, max_region_diff,
  type_id, sector_type,
  is_fixed, min_trust_level,
  enemy_name, description
) VALUES
  -- 1: 짐 나르기 (labor, 마을 내)
  ('dustvile_chore_01', '짐 나르기', 0, 1,
   1, 1,
   'labor', NULL,
   false, 0,
   NULL, '마을 광장에서 약초상까지 무거운 짐을 옮긴다. 단순하지만 마을 사람들이 바라보고 있다.'),

  -- 2: 야간 순찰 (labor, 마을 외곽)
  ('dustvile_chore_02', '야간 순찰', 0, 1,
   1, 1,
   'labor', NULL,
   false, 0,
   NULL, '더스트빌 외곽을 야간에 순찰한다. 특별히 위험한 일은 없지만 마을 사람들에게 안심감을 준다.'),

  -- 3: 약초 채집 (labor, 마른 초원) — herbalist_gathering 채집 의뢰 / min_trust_level=2 (신뢰도 2단계부터 노출)
  -- 주의: 채집 의뢰 식별을 위해 별도 tags JSONB 컬럼 없이 ID prefix 'dustvile_chore_03'으로 식별
  -- 페이즈 4 #4에서 약초상 UI에 herbalist_gathering 배수 적용 시 이 ID를 참조
  ('dustvile_chore_03', '약초 채집 (마른 약초)', 0, 1,
   1, 1,
   'labor', 'field',
   false, 2,
   NULL, '마른 초원에서 약초를 채집한다. 약초상이 원하는 재료를 가져오면 추가 보상을 받는다.'),

  -- 4: 실종자 수색 (labor, 폐광 입구 부근)
  ('dustvile_chore_04', '실종자 수색', 0, 1,
   1, 1,
   'labor', 'dungeon',
   false, 0,
   NULL, '폐광 입구 부근에서 사라진 마을 주민을 수색한다. 구체적인 흔적은 없지만 마을이 불안해하고 있다.'),

  -- 5: 도적 흔적 조사 (labor, 먼지로 덮인 길)
  ('dustvile_chore_05', '도적 흔적 조사', 0, 1,
   1, 1,
   'labor', 'field',
   false, 0,
   NULL, '외부로 통하는 산길에서 도적의 흔적을 확인한다. 아직 위협적이지는 않지만 촌장이 걱정하고 있다.'),

  -- 6: 잡동사니 회수 (labor, 폐광 입구)
  ('dustvile_chore_06', '잡동사니 회수', 0, 1,
   1, 1,
   'labor', 'dungeon',
   false, 0,
   NULL, '폐광 입구에 버려진 잡동사니를 회수한다. 광산 도구 일부가 재활용될 수 있다고 한다.'),

  -- 7: 길 안내 (escort, 마른 초원→마을)
  ('dustvile_chore_07', '길 안내', 0, 1,
   1, 1,
   'escort', 'field',
   false, 0,
   NULL, '마른 초원에서 더스트빌로 들어오는 광물상을 안전하게 안내한다. 길이 험해 길잡이가 필요하다.'),

  -- 8: 동굴 입구 조사 (explore, 폐광 입구 외부)
  ('dustvile_chore_08', '동굴 입구 조사', 0, 1,
   1, 1,
   'explore', 'dungeon',
   false, 0,
   NULL, '폐광 입구 외부를 조사한다. 안으로 들어가지 않아도 되는 간단한 외부 점검 임무.'),

  -- 9: 우물 점검 (explore, 마을 내)
  ('dustvile_chore_09', '우물 점검', 0, 1,
   1, 1,
   'explore', NULL,
   false, 0,
   NULL, '마을 공동 우물의 안전을 점검한다. 최근 물맛이 이상하다는 민원이 들어왔다.'),

  -- 10: 늑대 떼 처치 (hunt, 마른 초원)
  ('dustvile_chore_10', '늑대 떼 처치', 0, 1,
   1, 1,
   'hunt', 'field',
   false, 0,
   '마른 초원 늑대 무리', '마른 초원에 출몰하는 늑대 떼를 처치한다. 마을 외곽 농가가 피해를 입고 있다.');

-- §5. data_versions 갱신 (REQ-11)
UPDATE data_versions SET version = version + 1, updated_at = NOW() WHERE table_name = 'quest_pools';

-- §6. 검증 ASSERT
-- is_fixed=true 행 수 확인 (6행이어야 함)
DO $$
DECLARE fixed_count INT;
BEGIN
  SELECT COUNT(*) INTO fixed_count FROM quest_pools WHERE is_fixed = true;
  IF fixed_count < 6 THEN
    RAISE EXCEPTION 'is_fixed=true 행이 6개 미만 — INSERT 실패 가능성';
  END IF;
END $$;

-- (fixed_chain_id, fixed_step) UNIQUE 제약 만족 확인
DO $$
DECLARE dup_count INT;
BEGIN
  SELECT COUNT(*) INTO dup_count
  FROM (
    SELECT fixed_chain_id, fixed_step, COUNT(*) as cnt
    FROM quest_pools
    WHERE is_fixed = true
    GROUP BY fixed_chain_id, fixed_step
    HAVING COUNT(*) > 1
  ) dup;
  IF dup_count > 0 THEN
    RAISE EXCEPTION '(fixed_chain_id, fixed_step) 중복 감지 — UNIQUE 제약 위반';
  END IF;
END $$;

COMMIT;
```

#### 2.2.2 quest_pools 신규 컬럼 요약

| 컬럼명 | 타입 | 제약 | 기본값 | 출처 |
|--------|------|------|--------|------|
| `is_fixed` | BOOL | NOT NULL | false | 페이즈 1 #4 3.1절 |
| `fixed_chain_id` | TEXT | nullable | NULL | 페이즈 1 #4 3.1절 |
| `fixed_step` | INT | nullable, CHECK 1..20 | NULL | 페이즈 1 #4 3.1절 |
| `trust_threshold` | INT | nullable, CHECK 1..4 | NULL | 페이즈 1 #4 3.1절 |
| `reward_gold_override` | INT | nullable | NULL | 페이즈 2 #4 조정 2 |
| `reward_xp_bonus_override` | INT | nullable | NULL | 페이즈 2 #4 조정 3 |
| `duration_override_seconds` | INT | nullable | NULL | 페이즈 2 #4 조정 4 |
| `trust_reward_override` | INT | nullable | NULL | 페이즈 2 #4 조정 6 |
| `min_trust_level` | INT | NOT NULL | 0 | 페이즈 2 #3 조정 2 |

**고정 의뢰 INSERT 데이터 요약** (6행 + 10행):

`dustvile_pyegwang_reopen` 6행:

| id | type_id | difficulty | sector_type | fixed_step | trust_threshold | reward_gold_override | reward_xp_bonus_override | duration_override_seconds | trust_reward_override |
|----|---------|-----------|------------|-----------|----------------|---------------------|------------------------|--------------------------|---------------------|
| qp_pyegwang_step1 | explore | 1 | dungeon | 1 | 1 | null | null | 300 | 10 |
| qp_pyegwang_step2 | hunt | 1 | field | 2 | 1 | null | null | 300 | 15 |
| qp_pyegwang_step3 | raid | 2 | dungeon | 3 | 2 | 200 | null | 360 | 20 |
| qp_pyegwang_step4 | escort | 2 | dungeon | 4 | 2 | 185 | null | 300 | 25 |
| qp_pyegwang_step5 | raid | 3 | dungeon | 5 | 3 | 270 | null | 600 | 30 |
| qp_pyegwang_step6 | survey | 3 | village | 6 | 3 | 500 | 50 | 600 | 100 |

`dustvile_chore_NN` 10행:

| id | type_id | difficulty | sector_type | min_trust_level |
|----|---------|-----------|------------|----------------|
| dustvile_chore_01 | labor | 1 | null | 0 |
| dustvile_chore_02 | labor | 1 | null | 0 |
| dustvile_chore_03 | labor | 1 | field | **2** (채집 의뢰) |
| dustvile_chore_04 | labor | 1 | dungeon | 0 |
| dustvile_chore_05 | labor | 1 | field | 0 |
| dustvile_chore_06 | labor | 1 | dungeon | 0 |
| dustvile_chore_07 | escort | 1 | field | 0 |
| dustvile_chore_08 | explore | 1 | dungeon | 0 |
| dustvile_chore_09 | explore | 1 | null | 0 |
| dustvile_chore_10 | hunt | 1 | field | 0 |

**채집 의뢰 식별 정책**: `dustvile_chore_03`의 ID prefix로 식별. `tags` JSONB 컬럼은 추가하지 않음. 페이즈 4 #4 약초상 UI에서 `questPool.id == 'dustvile_chore_03'`으로 조건 처리. 동일 패턴의 채집 의뢰 추가 시 `dustvile_gathering_*` prefix 컨벤션 도입을 페이즈 4 #4 명세에 위임.

### 2.3 QuestPool Freezed 모델 확장 (REQ-02)

**파일**: `band_of_mercenaries/lib/core/models/quest_pool.dart`

기존 12개 필드에 9개 추가:

```dart
@freezed
class QuestPool with _$QuestPool {
  const factory QuestPool({
    // ... 기존 12개 필드 유지 ...

    // 고정 의뢰 컬럼 (페이즈 1 #4)
    @Default(false) @JsonKey(name: 'is_fixed') bool isFixed,
    @JsonKey(name: 'fixed_chain_id') String? fixedChainId,
    @JsonKey(name: 'fixed_step') int? fixedStep,
    @JsonKey(name: 'trust_threshold') int? trustThreshold,

    // 보상/시간 override 컬럼 (페이즈 2 #4)
    @JsonKey(name: 'reward_gold_override') int? rewardGoldOverride,
    @JsonKey(name: 'reward_xp_bonus_override') int? rewardXpBonusOverride,
    @JsonKey(name: 'duration_override_seconds') int? durationOverrideSeconds,
    @JsonKey(name: 'trust_reward_override') int? trustRewardOverride,

    // 단계별 노출 제어 컬럼 (페이즈 2 #3)
    @Default(0) @JsonKey(name: 'min_trust_level') int minTrustLevel,
  }) = _QuestPool;

  factory QuestPool.fromJson(Map<String, dynamic> json) =>
      _$QuestPoolFromJson(json);
}
```

**주의**: 모델 수정 후 `dart run build_runner build` 실행 필수 (`.g.dart`, `.freezed.dart` 재생성).

### 2.4 노출 로직 명세 (REQ-03~07)

#### 2.4.1 일반 갱신 풀 필터 분기

**위치**: `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` — `generateQuests()` 내 일반 풀 SELECT 분기

현재 코드 (line 46~49):
```dart
final generalPools = filtered
    .where((p) => !p.isFactionExclusive)
    .where((p) => sectorType != null
        ? p.sectorType == sectorType
        : p.sectorType == null)
    .toList();
```

**변경 후**:
```dart
final generalPools = filtered
    .where((p) => !p.isFactionExclusive)
    .where((p) => !p.isFixed)                        // REQ-03: 고정 의뢰 제외
    .where((p) => p.minTrustLevel <= currentTrustLevel) // REQ-04: 신뢰도 단계 필터
    .where((p) => sectorType != null
        ? p.sectorType == sectorType
        : p.sectorType == null)
    .toList();
```

**`generateQuests()` 시그니처 파라미터 추가**:
```dart
static List<ActiveQuest> generateQuests({
  // ... 기존 파라미터 유지 ...
  int currentTrustLevel = 0, // 신규 — 현재 거점 신뢰도 단계 (페이즈 4 #5 주입 전까지 0=전체 노출)
}) {
```

**[stub 정책]** `currentTrustLevel`은 페이즈 4 #5에서 `RegionStateRepository.getSettlementTrust(regionId).level`로 주입될 예정. 본 명세에서는 `0`으로 고정하여 `p.minTrustLevel <= 0` 조건이 만족되는 풀(min_trust_level=0 행)만 노출. `min_trust_level=2`인 채집 의뢰는 페이즈 4 #5 이후 노출. (2.5절 참조)

#### 2.4.2 고정 의뢰 별도 노출 흐름

**위치**: `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` — `QuestListNotifier`에 신규 메서드 추가

```dart
/// 고정 사건 의뢰를 현재 진행 상태에 따라 ActiveQuest로 생성한다.
///
/// 호출 시점:
/// - generateQuests() 완료 직후
/// - refreshAvailableQuests() 호출 시 (단계 완료·신뢰도 단계 진입 후)
///
/// 의사 코드:
/// 1. chainQuestProgressProvider에서 settlement_3_pyegwang_reopen 진행 조회
/// 2. currentStep 확인 (없으면 step=1로 가정 — 미활성화 상태)
/// 3. quest_pools에서 is_fixed=true AND fixed_chain_id='settlement_3_pyegwang_reopen'
///    AND fixed_step=currentStep AND trust_threshold <= currentTrustLevel 검색
/// 4. 이미 ActiveQuest(pending/inProgress)로 존재하는 경우 skip
/// 5. 조건 만족 시 ActiveQuest 생성 (isChainStep=true, chainId='settlement_3_pyegwang_reopen', chainStep=currentStep)
Future<void> _injectFixedSettlementQuest() async {
  final staticData = ref.read(staticDataProvider).value;
  final chainRepo = ref.read(chainQuestRepositoryProvider);
  if (staticData == null) return;

  const chainId = 'settlement_3_pyegwang_reopen';
  final progress = chainRepo.get(chainId);
  if (progress == null || progress.status == ChainQuestStatus.completed) return;

  final currentStep = progress.currentStep;
  final currentTrustLevel = _getCurrentTrustLevel(); // 2.5절 stub 참조

  final fixedPool = staticData.questPools.where((p) =>
    p.isFixed &&
    p.fixedChainId == chainId &&
    p.fixedStep == currentStep &&
    (p.trustThreshold ?? 1) <= currentTrustLevel
  ).firstOrNull;

  if (fixedPool == null) return;

  // 이미 pending/inProgress인 고정 의뢰가 존재하면 skip (중복 방지)
  final alreadyActive = state.any((q) =>
    q.isChainQuest &&
    q.chainId == chainId &&
    q.chainStep == currentStep &&
    (q.status == QuestStatus.pending || q.status == QuestStatus.inProgress)
  );
  if (alreadyActive) return;

  // ActiveQuest 생성
  final quest = ActiveQuest(
    id: 'fixed_${chainId}_step${currentStep}_${DateTime.now().millisecondsSinceEpoch}',
    questPoolId: fixedPool.id,
    questTypeId: fixedPool.typeId,
    difficulty: fixedPool.difficulty.round(),
    region: ref.read(userDataProvider)!.region,
    questName: fixedPool.name,
    createdAt: DateTime.now(),
    isChainStep: true,
    chainId: chainId,
    chainStep: currentStep,
  );
  await _repo.addQuests([quest]);
  _load();
}
```

#### 2.4.3 is_fixed=true 의뢰의 자동 갱신 제외 (REQ-06)

**위치**: `quest_provider.dart` `_checkQuestRefresh()` 내 만료 검사

현재 코드 (line 348):
```dart
if (quest.status == QuestStatus.pending && quest.createdAt != null) {
```

**변경 후**:
```dart
if (quest.status == QuestStatus.pending && quest.createdAt != null) {
  // 고정 의뢰(isChainQuest && settlement_ prefix)는 만료 제외
  if (quest.isChainQuest && quest.chainId?.startsWith('settlement_') == true) continue;
```

**`_refreshExpiredQuests()` 분기 추가**: 같은 위치에서 expired 목록 빌드 시 동일 조건 제외.

#### 2.4.4 단계 완료 시 다음 step 자동 노출 (REQ-07)

**신규 메서드 시그니처**: `QuestListNotifier.refreshAvailableQuests()`

```dart
/// 단계 진입 또는 사건 step 완료 후 고정 의뢰 재노출을 트리거한다.
///
/// 페이즈 4 #5 호출 시점:
/// - RegionStateRepository.addSettlementTrust() 내에서 levelUp 발생 시
/// - QuestCompletionService 내 settlement_ 사건 step 완료 후
///
/// 본 명세(페이즈 4 #3)에서는 메서드 시그니처와 내부 로직 정의만 수행.
/// 실제 호출은 페이즈 4 #5에서 연결.
Future<void> refreshAvailableQuests() async {
  await _injectFixedSettlementQuest();
  // 일반 의뢰 부족분 채우기 (trust_level 변경으로 새 풀이 노출된 경우 포함)
  await fillQuests();
}
```

### 2.5 페이즈 4 #5 의존 인터페이스 (stub 정의)

본 명세가 참조하는 미구현 함수 목록. 실제 구현은 페이즈 4 #5에서 수행.

| 함수 | stub 동작 | 페이즈 4 #5 실제 동작 |
|------|----------|---------------------|
| `_getCurrentTrustLevel()` | `return 0;` (모든 trust_threshold 조건 실패 — 고정 의뢰 미노출) | `RegionStateRepository.getSettlementTrust(regionId).level` 반환 |
| `ChainQuestService.tryActivateSettlement(regionId, eventName)` | 미구현 (신뢰도 1단계 도달 시 자동 호출 예정) | ChainQuestProgress를 `settlement_3_pyegwang_reopen`으로 신규 생성 |
| `RegionStateRepository.addSettlementTrust(regionId, amount, source)` | 미구현 | 누적 점수 증가 + 단계 승급 검증 + `refreshAvailableQuests()` 호출 |
| `RegionState.settlementTrust` | 미존재 (HiveField 4 예정) | int? nullable, null=0 fallback |
| `RegionState.settlementTrustLevel` | 미존재 (HiveField 5 예정) | int? nullable, null=1 fallback |

**[중요]**: stub 상태에서는 `_getCurrentTrustLevel()`이 0을 반환하므로, trust_threshold=1인 고정 의뢰도 노출되지 않는다. 페이즈 4 #5에서 `tryActivateSettlement`를 통해 ChainQuestProgress가 생성되고, 신뢰도 1단계 초기화 후 `refreshAvailableQuests()`가 호출되어야 비로소 step 1이 노출된다.

**[단계 완료 처리 stub]**: `QuestCompletionService` 내 거점 사건 step 완료 처리도 페이즈 4 #5 범위. 본 명세는 ActiveQuest의 `chainId.startsWith('settlement_')` 판별만 정의.

### 2.6 정렬 우선순위 (REQ-08, REQ-09)

#### ChainTopSection 분리 (REQ-08)

**파일**: `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` (또는 ChainTopSection 렌더 위치)

현재 Tier 0 (chainTier0) 분류 조건 (`quest_sort_service.dart` line 62~65):
```dart
if (q.isChainQuest &&
    q.chainId != null &&
    activeChainIds.contains(q.chainId)) {
  chainTier0.add(q);
```

**변경 후** — settlement_ prefix 퀘스트를 Tier 0에서 제외:
```dart
if (q.isChainQuest &&
    q.chainId != null &&
    activeChainIds.contains(q.chainId) &&
    !(q.chainId!.startsWith('settlement_'))) {  // 거점 사건은 일반 목록으로
  chainTier0.add(q);
```

#### 거점 사건 카드 정렬 (REQ-09)

**`QuestSortResult` 확장**: 신규 필드 `settlementTier` 추가

```dart
class QuestSortResult {
  final List<ActiveQuest> chainTier0;      // ChainTopSection
  final List<ActiveQuest> settlementTier;  // 신규: 거점 사건 일반 목록 최상단
  final List<ActiveQuest> sortedRest;      // Tier 1~4
  // ...
}
```

**`QuestSortService.sort()` 분기 추가**:

```dart
// settlement_ prefix 체인 의뢰 → settlementTier (일반 목록 최상단)
if (q.isChainQuest &&
    q.chainId != null &&
    q.chainId!.startsWith('settlement_') &&
    activeChainIds.contains(q.chainId)) {
  settlementTier.add(q);
}
```

**`sortedRest` 빌드 순서**:
```dart
return QuestSortResult(
  chainTier0: chainTier0,
  settlementTier: settlementTier,
  sortedRest: [...settlementTier, ...tier1, ...tier2, ...tier3, ...tier4],
);
```

**dispatch_screen.dart 렌더 순서**: `settlementTier` 카드는 `ChainTopSection` 아래, `sortedRest` 목록 최상단에 배치. 배지 스타일: "📜 마을 사건" 레이블 (AppTheme 기존 컬러 활용 — `transformVillage` 0xFFFFA000 권장).

---

## 3. 영향 범위

### 3.1 수정 대상 파일

코드베이스 탐색으로 확인된 파일만 기재.

| 파일 경로 | 수정 내용 |
|---------|----------|
| `band_of_mercenaries/lib/core/models/quest_pool.dart` | 9개 필드 추가 (Freezed 모델) |
| `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` | `generateQuests()` — isFixed 제외 필터, minTrustLevel 필터, currentTrustLevel 파라미터 추가 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | `QuestListNotifier` — `_injectFixedSettlementQuest()`, `refreshAvailableQuests()` 메서드 추가; `generateQuests()` 완료 후 `_injectFixedSettlementQuest()` 호출; `_checkQuestRefresh()` settlement_ prefix 제외 분기 추가 |
| `band_of_mercenaries/lib/features/quest/domain/quest_sort_service.dart` | `QuestSortResult` settlementTier 필드 추가; `sort()` settlement_ prefix 분기 추가 |
| `band_of_mercenaries/lib/features/quest/domain/sorted_quests_provider.dart` | `settlementTier` 노출 — chainQuestProgressProvider watch 추가 (settlement_ 진행 변경 시 재계산) |

**수정 필요 가능 파일** (코드베이스 탐색 결과 확인 필요):
- `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` — `sortedRest` → `settlementTier` + `sortedRest` 분리 렌더링, 거점 사건 배지 UI 추가
- `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` — `calculateDispatchCost` / `calculateDispatchDuration` / `calculateReward` 내 isFixed override 분기 (단, 이 3개 분기는 페이즈 4 #5 범위 — 본 명세는 시그니처만 명시)

### 3.2 신규 생성 파일

| 파일 경로 | 내용 |
|---------|------|
| `band_of_mercenaries/supabase/migrations/20260503_m4_phase4_3_quest_pools_extension.sql` | 2.2.1절 전체 SQL 내용 |

### 3.3 코드 생성 필요 파일

`quest_pool.dart` Freezed 모델 수정 후 build_runner 재실행 필수:

```bash
cd band_of_mercenaries && dart run build_runner build
```

재생성 대상:
- `band_of_mercenaries/lib/core/models/quest_pool.g.dart`
- `band_of_mercenaries/lib/core/models/quest_pool.freezed.dart`

---

## 4. 구현 가이드

### 4.1 진입점 및 데이터 흐름

```
앱 시작 / 위치 이동
  └─ QuestListNotifier.generateQuests()
       ├─ QuestGenerator.generateQuests(currentTrustLevel=_getCurrentTrustLevel())
       │    ├─ generalPools 필터: !isFixed && minTrustLevel <= currentTrustLevel
       │    └─ 일반/전용/엘리트 퀘스트 생성
       └─ _injectFixedSettlementQuest()  ← 신규
            └─ settlement_3_pyegwang_reopen 현재 step 조회
                → trust_threshold 조건 충족 시 ActiveQuest 생성

단계 완료 (페이즈 4 #5 연결 후)
  └─ QuestCompletionService (settlement_ prefix 분기)
       ├─ RegionStateRepository.addSettlementTrust()
       │    └─ levelUp 시 QuestListNotifier.refreshAvailableQuests() 호출
       └─ ChainQuestService.advanceStep()
            └─ QuestListNotifier.refreshAvailableQuests() 호출
                 └─ _injectFixedSettlementQuest() → 다음 step 노출

자동 갱신 주기 (1시간)
  └─ _checkQuestRefresh()
       └─ settlement_ prefix chainId 퀘스트는 만료 제외 (is_fixed 보장)
```

### 4.2 참조 구현

| 패턴 | 참조 파일 |
|------|---------|
| isChainStep=true ActiveQuest 생성 | `quest_provider.dart` `injectChainStep()` (line 208~225) |
| chain_id prefix 판별 | `quest_sort_service.dart` `activeChainIds` 집합 활용 패턴 |
| 세력 전용 퀘스트 제외 필터 | `quest_generator.dart` line 44~48 (`isFactionExclusive` 분기) |
| migration BEGIN/COMMIT 패턴 | `20260503_m4_phase4_2_region_sectors.sql` 전체 구조 |
| data_versions UPDATE | 위 파일 §5 참조 |

### 4.3 chain_id 네이밍 컨벤션

| 형식 | 예시 | 용도 |
|------|------|------|
| `settlement_<region_id>_<event_name>` | `settlement_3_pyegwang_reopen` | 거점 사건 (본 명세) |
| `chain_<chain_name>` | `chain_roadside_shrine` | 기존 region_discovery 트리거 체인 |

정규식 구분: `^settlement_\d+_.+$` 매칭 시 거점 사건 처리 경로.

### 4.4 activeQuest isSettlementStep getter 권장

`quest_model.dart`에 편의 getter 추가 권장:

```dart
/// 거점 사건 step 여부: chainId가 settlement_ prefix인 체인 퀘스트
bool get isSettlementStep =>
    isChainQuest && (chainId?.startsWith('settlement_') ?? false);
```

### 4.5 페이즈 4 #5에서 연결할 QuestCalculator 분기 (본 명세 미구현)

아래 분기는 페이즈 4 #5에서 구현. 본 명세는 시그니처와 정책만 정의.

```dart
// QuestCalculator.calculateReward
if (pool.isFixed && pool.rewardGoldOverride != null) {
  return pool.rewardGoldOverride!;
}
// 기존 calculateReward

// QuestCalculator.calculateDispatchDuration
if (pool.isFixed && pool.durationOverrideSeconds != null) {
  return Duration(seconds: pool.durationOverrideSeconds!);
}
// 기존 calculateDispatchDuration

// QuestCalculator.calculateDispatchCost
if (pool.isFixed && pool.durationOverrideSeconds != null) {
  return difficulty.minDispatchCost; // max 미사용, min 단일 적용
}
// 기존 calculateDispatchCost

// ExperienceService.calculateXpGain
final baseXp = difficulty * 20 * resultMultiplier * (1 + facilityBonus + passiveXpBonus);
if (pool.isFixed && pool.rewardXpBonusOverride != null) {
  return baseXp.round() + pool.rewardXpBonusOverride!;
}
return baseXp.round();
```

---

## 5. 기획 확인 사항 (Q&A — 권장 답변 포함)

### Q1: dungeon/field 풀 12~16개 추가 통합 vs 분리

**결정**: **옵션 B — 별도 분리 (M5 또는 페이즈 4 #6)**.

**사유**:
1. 본 명세 이미 6행 + 10행 = 16행 INSERT + 9개 컬럼 마이그레이션 + QuestGenerator 분기 + QuestSortService 분기 + refreshAvailableQuests() 메서드로 대규모.
2. dungeon/field 신규 풀은 본 명세의 `is_fixed`/`min_trust_level` 컬럼과 의존성 없음 (기존 `sector_type` 매칭 시스템으로 동작).
3. 페이즈 4 #3에서 이미 `dustvile_chore_04·06·08`(dungeon), `dustvile_chore_03·05·07·10`(field)으로 해당 sector_type 풀 일부가 생성됨. 별도 dungeon/field 풀 추가는 페이즈 4 #4 또는 M5 결정 시 간단히 INSERT만으로 가능.
4. 코드베이스 탐색 결과 `QuestGenerator.generateQuests`에서 `sector_type` 매칭 로직이 이미 완성 상태 (line 46~49). 신규 풀 행 추가 시 코드 수정 불필요.

**결론**: 페이즈 4 #3은 고정 의뢰 시스템에 집중. dungeon/field 일반 풀은 M5 또는 페이즈 4 #6에서 data-generator로 일괄 생성 권장.

---

### Q2: ActiveQuest 모델에 isFixedSettlementStep getter 추가 vs chainId prefix 매칭

**권장**: `isSettlementStep` getter 추가 (`chainId?.startsWith('settlement_')` 래핑). 4.4절 참조.

**사유**: 코드 전체에서 `chainId?.startsWith('settlement_')` 중복 표현 방지. HiveField 추가 불필요 (computed getter).

---

### Q3: SortedQuestsProvider 5계층 fold에서 거pont 사건 카드의 Tier 위치

**결정**: **신규 settlementTier — ChainTopSection 아래, sortedRest 최상단**.

**사유**: 기획서 [content]20260503_settlement-trust-and-fixed-events.md 3.4절 권장안 채택. ChainTopSection(최대 3장 슬롯)과 공유하면 UI 혼잡. 거점 사건은 "마을의 의뢰"로 별도 컨텍스트를 가지므로 일반 목록 최상단 배치가 자연스러움.

---

### Q4: dustvile_chore_NN region 매칭 방법 (min_region_diff 값)

**결정**: `min_region_diff = 1`, `max_region_diff = 1` (더스트플레인 T1 tier 매칭).

**사유**: 기존 `QuestGenerator.generateQuests()` 필터 로직 (line 33~35)이 `p.minRegionDiff <= regionTier && p.maxRegionDiff >= regionTier`로 tier 기반 매칭. 더스트플레인 region 3의 tier는 1. `min_region_diff=1, max_region_diff=1`로 T1 한정 노출 보장. region_id 직접 매칭 컬럼은 별도 추가 불필요.

**주의**: T1인 다른 region(region 31, 127)에서도 이 풀이 노출될 수 있음. 이는 M4 MVP에서 허용 (단순성 우선). 완전한 거점 한정 노출은 페이즈 4 #4~5에서 `region_id` 컬럼 추가 또는 chainId prefix 조건 추가로 구현 가능.

---

### Q5: 기존 quest_pools 행에 신규 컬럼 추가 시 BACKFILL 정책

**결정**: **DEFAULT 사용 — 명시적 UPDATE 불필요**.

**사유**:
- `is_fixed BOOL NOT NULL DEFAULT false` — 기존 행은 자동으로 false.
- `min_trust_level INT NOT NULL DEFAULT 0` — 기존 행은 자동으로 0 (모든 단계에서 노출).
- nullable 컬럼 4+4개는 기존 행 null = 기존 동작 그대로.

`flutter analyze` 또는 Freezed `@Default` 처리로 기존 캐시 JSON 역직렬화 시 누락 컬럼을 기본값으로 처리. `QuestPool.fromJson()` backward 호환 보장.

---

### Q6: data_versions 신규 row 또는 quest_pools row만 increment

**결정**: **기존 `quest_pools` row의 version만 +1 증가**.

**사유**: 마이그레이션 파일 §5에서 `UPDATE data_versions SET version = version + 1 WHERE table_name = 'quest_pools'`. 신규 테이블 생성 없으므로 INSERT 불필요. 클라이언트 `SyncService`가 버전 비교 후 `quest_pools` 전체 재다운로드 트리거.

---

## 6. 페이즈 4 #5 위임 항목 요약

본 명세에서 stub 또는 시그니처만 정의하고 실제 구현을 페이즈 4 #5에 위임하는 항목:

| 항목 | 위임 사유 |
|------|----------|
| `RegionState` HiveField 4·5 (`settlementTrust`/`settlementTrustLevel`) 추가 | 신뢰도 저장소 전체 설계와 통합 필요 |
| `RegionStateRepository.addSettlementTrust()` / `getSettlementTrust()` | 위 모델 확장 선행 필요 |
| `settlementTrustProvider(regionId)` / `settlementTrustLevelUpProvider` | 신뢰도 단계 승급 이벤트 채널 |
| `ChainQuestService.tryActivateSettlement()` | 신뢰도 1단계 도달 트리거 연동 |
| `ChainQuestService.checkDormant()` — settlement_ prefix skip 분기 | 현재 14일 dormant 정책이 거점 사건에 부적합 |
| `QuestCalculator` isFixed override 분기 3개 (gold/duration/cost) | 기획 밸런스 검증 완료 후 일괄 적용 |
| `ExperienceService.calculateXpGain` isFixed XP bonus 분기 | 위와 동일 |
| `QuestCompletionService` 거점 사건 step 완료 처리 | settlementTrust/chainProgress 동시 업데이트 |
| `ActivityLogType` HiveField 22·23·24 추가 (settlementTrustUp/settlementEventStep/settlementEventCompleted) | 기존 enum 변경 시 Hive typeId 충돌 주의 |
| `dialogQueue` 신뢰도 단계 승급 다이얼로그 등록 | dialogQueueProvider medium priority 통합 |

---

## 7. 호환성 검토

- **기존 quest_pools 캐시**: 신규 컬럼은 `@Default` 또는 nullable 처리로 backward 호환. 구버전 캐시 JSON 역직렬화 시 누락 컬럼은 기본값 처리.
- **기존 ActiveQuest Hive 세이브**: HiveField 추가 없음. `isChainStep`·`chainId`·`chainStep` 기존 필드 재사용.
- **ChainQuestProgress Hive 박스**: 모델 변경 없음. `settlement_3_pyegwang_reopen` chainId로 신규 항목만 추가.
- **RegionState Hive 박스**: 본 명세에서 변경 없음 (HiveField 4·5는 페이즈 4 #5).
- **SyncService.allTables**: `quest_pools`는 이미 목록에 포함. 변경 불필요.
- **QuestSortResult**: `settlementTier` 필드 추가 시 파견 화면 렌더 코드에서 null 안전 처리 필요 (새 필드라 기존 코드에 없음).
