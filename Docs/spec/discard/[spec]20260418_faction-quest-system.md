# 세력 태그 + 전용 퀘스트 시스템 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260417_faction_quests.md` (태그/전용 퀘스트 컨셉)
> - `Docs/balance-design/20260417_faction_quests_balance.md` (수치·확률·쿨다운 확정)
> - `Docs/content-data/[faction-quest]20260417_m1-faction-exclusive.csv` (전용 퀘스트 98행 데이터)
> 선행 명세: `Docs/spec/[spec]20260418_passive-bonus-service.md` (보상 공식 가산 레이어 통합 대상)
> 작성일: 2026-04-18
> 마일스톤: M1 페이즈 4 (2/4)
> UI 목업: 사용 안 함 (파견 화면 배지·강조 표시는 소규모, 별도 UI 목업 불요)

## 1. 개요

일반 퀘스트에 런타임으로 **세력 태그**를 부여하는 `FactionTagResolver`와, `quest_pools`에 저장된 **세력 전용 퀘스트 98행**(CSV)을 조건부 노출시키는 `QuestGenerator` 확장을 구현한다. 퀘스트 완료 시 `QuestCompletionService`가 태그/전용 분기로 세력 평판을 지급하고, 보상 공식에 트랙 보너스(+0.30/+0.40)와 PassiveBonusService 합산을 가산 상한 **+0.80 클램프**로 통합한다. `quest_pools` 스키마를 4필드 확장하고 CSV 98행을 단일 마이그레이션으로 INSERT한다.

## 2. 요구사항

### 2.1 기능 요구사항

#### FR-1: `quest_pools` 스키마 4필드 확장

Supabase `quest_pools` 테이블에 다음 컬럼 추가:

| 필드 | 타입 | 기본값 | 용도 |
|------|------|-------|------|
| `faction_tag` | text | null | 전용 퀘스트: 세력 ID 고정. 일반 퀘스트: null (런타임 태깅) |
| `is_faction_exclusive` | boolean | false | 전용 퀘스트 식별 플래그 |
| `min_reputation` | int | 0 | 전용 퀘스트 해금 평판 임계 (기본 11 / 고급 61) |
| `sector_type` | text | null | M3 대비 필드만 추가 (기본 null) |

**외래 키:** `faction_tag REFERENCES factions(id)` (nullable, ON DELETE SET NULL).

**`type` 컬럼 처리 결정:** 현재 `type real default 0`으로 모든 행이 0이며 실질적으로 미사용 상태. CSV는 1~4 정수 매핑(1=raid/2=hunt/3=escort/4=explore)으로 작성됨. 두 옵션:
- (A) `type` 그대로 유지 + `type_id text` 신규 컬럼 추가, 신규 컬럼을 퀘스트 유형 참조로 사용
- (B) `type` 컬럼을 real → text로 변환, 기존 0 값을 `null` 또는 기본 유형으로 치환

**권장: (A) `type_id text` 신규 컬럼 추가.** 이유:
- 기존 200행의 `type real = 0` 값을 파괴하지 않음 (하위 호환)
- `quest_types.id`(text) 외래 키 정합성 명확
- CSV의 숫자(1~4)는 마이그레이션 SQL에서 `CASE WHEN type=1 THEN 'raid' ... END`로 변환 후 INSERT

**확정 스키마:**
```
quest_pools (
  id text PK,
  name text,
  type real,                       -- 기존 유지 (deprecated, 미사용)
  type_id text NOT NULL DEFAULT 'raid' REFERENCES quest_types(id),  -- 신규
  difficulty real,
  min_region_diff real,
  max_region_diff real,
  faction_tag text NULL REFERENCES factions(id) ON DELETE SET NULL,  -- 신규
  is_faction_exclusive boolean NOT NULL DEFAULT false,                -- 신규
  min_reputation int NOT NULL DEFAULT 0,                              -- 신규
  sector_type text NULL                                               -- 신규
)
```

#### FR-2: CSV 98행 DB INSERT (⚠️ 필수)

`Docs/content-data/[faction-quest]20260417_m1-faction-exclusive.csv` 98행을 스키마 확장과 **같은 트랜잭션**에서 INSERT.

**변환 규칙:**
- CSV의 `type` 컬럼(1~4 정수) → `type_id`(text) 매핑:
  - 1 → `'raid'`, 2 → `'hunt'`, 3 → `'escort'`, 4 → `'explore'`
- CSV의 `type` 값은 `type` 컬럼(real)에는 그대로 저장하지 않고 **0**으로 통일(기존 관행). 실제 유형은 `type_id`에서 조회
- CSV의 `sector_type` 빈 문자열 → SQL `NULL`

**data_versions 갱신:**
```sql
UPDATE data_versions SET version = version + 1 WHERE table_name = 'quest_pools';
```

앱 포그라운드 복귀 시 SyncService가 이 버전 차이를 감지하여 `quest_pools` 전체 재다운로드.

#### FR-3: `FactionTagResolver` 서비스 신설

- 새 파일: `band_of_mercenaries/lib/features/quest/domain/faction_tag_resolver.dart`
- 정적 유틸 클래스 (기존 서비스 패턴 준수)
- 의사코드 (밸런스 리포트 분석 8):

```dart
class FactionTagResolver {
  /// 일반 퀘스트에 부여할 세력 태그를 결정한다.
  /// 반환: 세력 ID (부여) 또는 null (미부여, 일반 퀘스트로 유지)
  static String? resolve({
    required int regionId,
    required List<String> joinedFactionIds,
    required Map<String, int> clueLevelsInRegion, // factionId -> clueLevel
    required List<String> hostileFactionIds,       // 평판 -100 세력
    required int proximityTier, // 1~4 (거점 거리 기반, M1 범위 밖이면 기본 3)
    required Random random,
  }) {
    // 1. 단서 보유 후보 수집
    final candidates = clueLevelsInRegion.entries
        .where((e) => e.value >= 1)
        .map((e) => e.key)
        .where((id) => !hostileFactionIds.contains(id))
        .toList();
    if (candidates.isEmpty) return null;

    // 2. 가입 세력 우선 경로 (확률 100%)
    final joinedCandidates =
        candidates.where((id) => joinedFactionIds.contains(id)).toList();
    if (joinedCandidates.isNotEmpty) {
      return joinedCandidates[random.nextInt(joinedCandidates.length)];
    }

    // 3. 비가입 세력: 거점 근접도 기반 확률
    const probabilities = {1: 0.30, 2: 0.20, 3: 0.10, 4: 0.05};
    final prob = probabilities[proximityTier] ?? 0.10;
    if (random.nextDouble() > prob) return null;

    // 4. 가중 랜덤 (M1은 균등 랜덤으로 단순화)
    return candidates[random.nextInt(candidates.length)];
  }

  /// 태그 퀘스트 평판 획득량.
  static int tagReputationGain(int proximityTier) =>
      proximityTier <= 2 ? 2 : 1;
}
```

**M1 시점 proximityTier 공급:**
거점 시스템은 M3 이후. M1 범위에서는 **기본 3 (10%)**로 고정. 거점 데이터 도입 시 `proximityTier`를 리전-세력 거리 계산으로 대체.

#### FR-4: `QuestGenerator` 확장

- 파일: `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart`
- `generateQuests` 시그니처 확장:

```dart
static List<ActiveQuest> generateQuests({
  required int regionTier,
  required int regionId,
  required List<QuestPool> questPools,
  required List<QuestType> questTypes,
  required int count,
  required Random random,
  // 신규 파라미터:
  required List<String> joinedFactionIds,
  required Map<int, int> factionReputations,  // factionId(int) → 평판, 실제 팩션ID는 String이므로 Map<String,int>
  required Map<String, Map<String, int>> clueLevelsByRegion, // regionId → factionId → clueLevel
  required Set<String> cooldownExclusiveQuestIds,  // 6h 쿨다운 중인 전용 퀘스트 ID
  required int activeSlotCount,                    // 현재 활성 슬롯 수 (정보망 반영)
  int proximityTier = 3,                           // M1 기본 3
  List<String> hostileFactionIds = const [],
})
```

**로직 변경 (라인 18~36 주변):**

```
1. 기존 필터: regionTier in [minRegionDiff, maxRegionDiff]
2. 전용 퀘스트 / 일반 퀘스트 분리:
   exclusivePools = filtered.where(p => p.isFactionExclusive)
   generalPools = filtered.where(p => !p.isFactionExclusive)

3. 전용 퀘스트 후보 필터링:
   eligibleExclusive = exclusivePools.where(p =>
     joinedFactionIds.contains(p.factionTag)        // 가입한 세력만
     && !hostileFactionIds.contains(p.factionTag)
     && (factionReputations[p.factionTag] ?? 0) >= p.minReputation  // 트랙 해금
     && !cooldownExclusiveQuestIds.contains(p.id)   // 쿨다운 제외
   ).toList();
   eligibleExclusive.shuffle(random);

4. 전용 노출 상한 계산:
   exclusiveCap = min(joinedFactionIds.length * 2, (activeSlotCount * 0.5).floor())
   selectedExclusive = eligibleExclusive.take(exclusiveCap).toList();

5. 일반 퀘스트 채우기:
   remainingCount = count - selectedExclusive.length
   generalPools.shuffle(random)
   selectedGeneral = generalPools.take(remainingCount).toList()

6. ActiveQuest 생성:
   for (pool in selectedExclusive) {
     // 전용 퀘스트: factionTag = pool.factionTag, isAdvancedTrack = (pool.minReputation >= 61)
     // type 유형은 pool.typeId 우선 사용 (기존 random 선택 대체)
     // reputationReward: isAdvancedTrack ? 8+random.nextInt(3) : 5+random.nextInt(3)
   }
   for (pool in selectedGeneral) {
     // 일반 퀘스트: FactionTagResolver.resolve(...)로 faction_tag 동적 부여
     // faction_tag != null이면 reputationReward = tagReputationGain(proximityTier) (+1 or +2)
     // faction_tag == null이면 reputationReward = null (평판 미획득)
     // type은 기존처럼 pool.typeId로 고정 (기존 random.nextInt(questTypes) 폐기 — 전용과 일반 모두 풀 정의 유형 사용)
   }
   return [...selectedExclusive, ...selectedGeneral]
```

**중요 변경:** 기존 `questType = questTypes[random.nextInt(questTypes.length)]` 로직은 **폐기**. 전용/일반 모두 `pool.typeId`(FR-1 신규 컬럼)를 그대로 사용. `type_id`가 없는 기존 행은 기본값 `'raid'`로 처리.

#### FR-5: `QuestGenerator` 호출부 갱신 (`quest_provider.dart`)

- 파일: `band_of_mercenaries/lib/core/providers/quest_provider.dart`
- 1시간 게임 시간 갱신 로직 (라인 199~220 `_checkQuestRefresh`) 수정:

```dart
1. 기존: 대기 퀘스트 만료 처리
2. 신규: 완료된 전용 퀘스트 ID를 settings 박스의 쿨다운 맵에 기록
   (key: 'faction_exclusive_cooldown.{questId}' → value: DateTime.toIso8601String())
3. 쿨다운 맵에서 6시간 경과 항목 제거 (정리)
4. 현재 활성 쿨다운 ID 집합 → Set<String> cooldownExclusiveQuestIds
5. generateQuests 호출 시 cooldownExclusiveQuestIds 전달
```

**쿨다운 저장 규약 (SettingsKeys 확장):**
- `settings` 박스에 개별 키 대신 단일 키 `'factionQuestCooldowns'`(JSON 문자열 Map) 저장 권장 (키 수 폭주 방지)
- 값: `{"fq_adventurers_guild_missing_explorer_search": "2026-04-18T03:15:00Z", ...}`
- 6h 경과 항목 비우기는 접근 시마다 수행 (lazy cleanup)

- `SettingsKeys` 파일(`band_of_mercenaries/lib/core/data/settings_keys.dart`)에 `static const String factionQuestCooldowns = 'factionQuestCooldowns';` 추가

#### FR-6: `QuestCompletionService` 평판 지급 분기

- 파일: `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart`
- 기존 라인 135~141 명성(플레이어 랭크 평판) 계산 **이후에** 세력 평판 지급 블록 추가:

```dart
// 기존: repGain = ReputationService.calculateQuestReputation(...)  // 플레이어 랭크

// 신규: 세력 평판 지급
String? factionTag = quest.factionTag;
int factionRepGain = 0;
if (factionTag != null &&
    (resultType == QuestResult.greatSuccess || resultType == QuestResult.success)) {
  // quest.reputationReward가 생성 시점에 이미 계산되어 저장되어 있음
  factionRepGain = quest.reputationReward ?? 0;
  // FactionStateRepository.addReputation(factionTag, factionRepGain) 호출 — 결과 반환값에 포함
}
// QuestCompletionResult에 factionTag, factionRepGain 필드 추가
```

**`QuestCompletionResult` 확장:**

```dart
class QuestCompletionResult {
  // 기존: rewardGold, totalWage, dispatchCost, earnedXp, earnedReputation 등
  final String? factionTag;       // 신규
  final int factionRepGain;       // 신규
  // ...
}
```

**호출측(quest_provider.dart 완료 처리)에서 결과 반영:**
- `factionTag != null && factionRepGain > 0` → `ref.read(factionStateRepositoryProvider).addReputation(factionTag, factionRepGain)`
- 완료된 퀘스트가 전용 퀘스트(`quest.isAdvancedTrack != null`)면 쿨다운 맵에 기록

#### FR-7: 보상 공식 가산 상한 +0.80 클램프

- 파일: `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart`
- `calculateReward` 시그니처 확장:

```dart
static int calculateReward({
  required int baseReward,
  required double rewardMultiplier,
  bool isGreatSuccess = false,
  // 신규 파라미터 (모두 기본값 0.0으로 하위 호환):
  double trackBonus = 0.0,      // 전용 퀘스트 트랙 (0.30 basic / 0.40 advanced)
  double passiveRewardBonus = 0.0, // PassiveBonusService: quest_reward_multiplier 가산 합
  double rankRewardBonus = 0.0,    // 명성 rank_json의 quest_reward_multiplier (all)
}) {
  final stackedBonus = (trackBonus + passiveRewardBonus + rankRewardBonus)
      .clamp(0.0, 0.80);
  final reward = (baseReward * rewardMultiplier * (1 + stackedBonus)).round();
  return isGreatSuccess ? reward * 2 : reward;
}
```

**호출측 `QuestCompletionService` 갱신 (기존 라인 100 주변):**

```dart
final trackBonus = quest.isAdvancedTrack == true
    ? 0.40
    : (quest.factionTag != null && quest.reputationReward != null && !_isTagQuest(quest) ? 0.30 : 0.0);
final passiveRewardBonus = PassiveBonusService.sumRewardMultiplier(
    questTypeId: quest.questTypeId, effects: collectedEffects);
final rankRewardBonus = ...; // rank effects의 all 유형 합산

final rewardGold = QuestCalculator.calculateReward(
  baseReward: ...,
  rewardMultiplier: difficulty.rewardMultiplier,
  isGreatSuccess: ...,
  trackBonus: trackBonus,
  passiveRewardBonus: passiveRewardBonus,
  rankRewardBonus: rankRewardBonus,
);
```

**`trackBonus` 판정:**
- `quest.isFactionExclusive == true`이면: `isAdvancedTrack == true ? 0.40 : 0.30`
- 일반 태그 퀘스트(`factionTag != null && !isFactionExclusive`)는 **trackBonus 없음** (태그 퀘스트는 평판만 지급, 보상 추가 없음)

#### FR-8: `ActiveQuest` Hive 모델 확장

- 파일: `band_of_mercenaries/lib/features/quest/domain/quest_model.dart`
- 현재 최대 HiveField 번호: **16** (`earnedReputation`)
- 신규 필드:

```dart
@HiveField(17)
String? factionTag;              // 런타임 부여된 세력 태그 또는 전용 퀘스트 고정 세력

@HiveField(18)
int? reputationReward;           // 완료 시 지급될 세력 평판 (생성 시점에 미리 계산)

@HiveField(19)
bool? isAdvancedTrack;           // 전용 퀘스트 트랙 구분 (null=일반, false=기본, true=고급)
```

**생성자에 `this.factionTag, this.reputationReward, this.isAdvancedTrack` 추가.**

파생 getter (옵션):
```dart
bool get isFactionExclusive => isAdvancedTrack != null;
```

기존 저장된 ActiveQuest(null 필드)는 Hive null-safe로 호환됨.

#### FR-9: `QuestPool` 모델 확장

- 파일: `band_of_mercenaries/lib/core/models/quest_pool.dart`
- Freezed 필드 추가 (snake_case @JsonKey):

```dart
@Default('raid') @JsonKey(name: 'type_id') String typeId,
@JsonKey(name: 'faction_tag') String? factionTag,
@Default(false) @JsonKey(name: 'is_faction_exclusive') bool isFactionExclusive,
@Default(0) @JsonKey(name: 'min_reputation') int minReputation,
@JsonKey(name: 'sector_type') String? sectorType,
```

기존 `type` (real) 필드는 Freezed에서 유지하되 코드 내 사용처 제거. deprecated 주석.

#### FR-10: `SyncService` 업데이트

- 파일: `band_of_mercenaries/lib/core/data/sync_service.dart`
- `quest_pools` 테이블 SELECT 쿼리 확인. 현재 `SELECT *` 가정 → 신규 5개 컬럼(`type_id`, `faction_tag`, `is_faction_exclusive`, `min_reputation`, `sector_type`) 자동 포함
- 만약 명시적 컬럼 리스트면 추가 필수
- data_versions `quest_pools` 버전 비교 로직 확인 (기존 구조 유지)

#### FR-11: 파견 화면 UI (기존 위젯 확장)

- 파일: `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` (또는 퀘스트 카드 위젯)
- 퀘스트 카드에 **세력 태그 배지** 표시:
  - `quest.factionTag != null` → `FactionData.color` 기반 칩(Chip) 또는 작은 배지 표시
  - `quest.isFactionExclusive == true` → 카드 테두리 색상 변경 + "전용" 라벨
- **전용 퀘스트 강조:** 카드 배경에 faction.color의 연한 톤 적용
- 별도 화면 전환 없음. 상태 기반 렌더링 그대로.

### 2.2 데이터 요구사항

#### 2.2.1 Supabase 스키마 마이그레이션

**신규 파일:** `supabase/migrations/20260418_quest_pools_faction_fields.sql`

```sql
BEGIN;

-- 1. quest_pools 스키마 확장
ALTER TABLE quest_pools ADD COLUMN IF NOT EXISTS type_id TEXT NOT NULL DEFAULT 'raid' REFERENCES quest_types(id);
ALTER TABLE quest_pools ADD COLUMN IF NOT EXISTS faction_tag TEXT NULL REFERENCES factions(id) ON DELETE SET NULL;
ALTER TABLE quest_pools ADD COLUMN IF NOT EXISTS is_faction_exclusive BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE quest_pools ADD COLUMN IF NOT EXISTS min_reputation INT NOT NULL DEFAULT 0;
ALTER TABLE quest_pools ADD COLUMN IF NOT EXISTS sector_type TEXT NULL;

-- 2. 기존 200개 일반 퀘스트 type_id 결정
-- 현재 모든 행 type=0이므로 이름 기반 패턴 매칭 또는 기본값 'raid' 적용.
-- (실제 전환 정책은 구현 단계에서 운영 협의. 임시 기본값 유지)

-- 3. 98개 전용 퀘스트 INSERT (CSV 기반)
-- CSV의 type 숫자를 type_id text로 매핑 (1=raid, 2=hunt, 3=escort, 4=explore)
INSERT INTO quest_pools (id, name, type, type_id, difficulty, min_region_diff, max_region_diff, faction_tag, is_faction_exclusive, min_reputation, sector_type) VALUES
('fq_adventurers_guild_missing_explorer_search', '실종된 탐험가 수색', 0, 'explore', 2, 0, 3, 'faction_adventurers_guild', true, 11, NULL),
('fq_adventurers_guild_way_station_secure', '중간 기착지 확보', 0, 'escort', 2, 0, 3, 'faction_adventurers_guild', true, 11, NULL),
-- ... (98행 전체, CSV 기반 자동 변환)
('fq_fang_brotherhood_grand_trophy_claim', '거대 전리품 획득', 0, 'raid', 5, 1, 5, 'faction_fang_brotherhood', true, 61, NULL)
ON CONFLICT (id) DO NOTHING;  -- 재실행 안전성

-- 4. data_versions 갱신
UPDATE data_versions SET version = version + 1 WHERE table_name = 'quest_pools';

COMMIT;
```

**변환 스크립트 주의사항:**
- CSV의 `type` 컬럼(1~4) → `type_id`(text) 매핑 필수
- CSV의 빈 `sector_type` → SQL `NULL`
- ID 충돌 방지: `ON CONFLICT (id) DO NOTHING` (재실행 안전)

#### 2.2.2 Flutter 데이터 모델

**수정 파일:**
- `band_of_mercenaries/lib/core/models/quest_pool.dart` — FR-9 Freezed 필드 5개 추가
- `band_of_mercenaries/lib/features/quest/domain/quest_model.dart` — FR-8 ActiveQuest HiveField 17~19 추가

**Hive 박스 변경 없음.** `quests` 박스에 저장되는 `ActiveQuest`는 기존 typeId 4 유지. 필드 추가만으로 하위 호환 확보.

#### 2.2.3 SettingsKeys 확장

- 파일: `band_of_mercenaries/lib/core/data/settings_keys.dart`
- 신규 상수: `static const String factionQuestCooldowns = 'factionQuestCooldowns';`
- 값 타입: `String` (JSON 직렬화된 `Map<String, String>` — questId → ISO timestamp)

#### 2.2.4 밸런스 파라미터 상수

- 파일: `band_of_mercenaries/lib/core/constants/game_constants.dart`
- 신규 상수 추가:

```dart
// 세력 태그/전용 퀘스트 파라미터 (balance report 2026-04-17)
static const double tagProbNear = 0.30;   // proximityTier 1 (1~3 거리)
static const double tagProbMid = 0.20;    // proximityTier 2 (4~7)
static const double tagProbFar = 0.10;    // proximityTier 3 (8~15, M1 기본)
static const double tagProbVeryFar = 0.05; // proximityTier 4 (16+)
static const double trackRewardBasic = 0.30;
static const double trackRewardAdvanced = 0.40;
static const double rewardBonusStackCap = 0.80;
static const Duration factionQuestCooldown = Duration(hours: 6);
```

### 2.3 UI 요구사항

#### 2.3.1 파견 화면 퀘스트 카드 (기존 위젯 수정)

- **진입 조건:** 기존 파견 화면에서 퀘스트 목록 표시 시
- **위젯 계층:** 기존 `Card > Column > [제목, 난이도, 보상, ...]` 구조에 **세력 배지 `Chip` 또는 `Container + Text`** 추가
- **상태 변수:** 기존 `ActiveQuest` 인스턴스의 `factionTag`, `isFactionExclusive`, `isAdvancedTrack` 필드 참조
- **화면 전환:** 기존 상태 기반 렌더링 유지. Navigator.push 사용 안 함
- **색상 규약:** `FactionData.color` 필드(이미 존재) 활용
- **연출:** 전용 퀘스트는 카드 좌측에 세로 막대(3px width) 세력 컬러 추가

#### 2.3.2 파견 상세 페이지 (DispatchDetailPage)

- **전용 퀘스트:** 상단 제목 아래 세력 이름 + 트랙 표시 ("모험가 길드 · 기본 트랙" 등)
- **태그 퀘스트:** 제목 옆에 작은 세력 아이콘(faction.color)과 세력 이름
- 기존 3단 구조(상단 퀘스트 정보 / 중앙 용병 목록 / 하단 버튼) 유지

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` | `generateQuests` 파라미터 확장 + 전용/일반 분리 로직 | FR-4 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | 세력 평판 지급 분기 + 보상 공식 훅 주입 | FR-6, FR-7 |
| `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` | `calculateReward` 파라미터 확장 (track/passive/rank 가산 상한 0.80) | FR-7 |
| `band_of_mercenaries/lib/features/quest/domain/quest_model.dart` | `ActiveQuest` HiveField 17~19 추가 | FR-8 |
| `band_of_mercenaries/lib/core/models/quest_pool.dart` | Freezed 필드 5개 추가 (`typeId`, `factionTag`, `isFactionExclusive`, `minReputation`, `sectorType`) | FR-9 |
| `band_of_mercenaries/lib/core/providers/quest_provider.dart` | `_checkQuestRefresh` 쿨다운 관리 + `generateQuests` 호출 인자 확장 | FR-5 |
| `band_of_mercenaries/lib/core/data/settings_keys.dart` | `factionQuestCooldowns` 상수 추가 | FR-5 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | `quest_pools` 컬럼 변경 확인 (현재 SELECT * 이면 자동) | FR-10 |
| `band_of_mercenaries/lib/core/constants/game_constants.dart` | 밸런스 파라미터 상수 7개 추가 | 2.2.4 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` (또는 퀘스트 카드 위젯) | 세력 배지 + 전용 강조 표시 | FR-11 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_detail_page.dart` | 상단 세력/트랙 표시 | FR-11 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/features/quest/domain/faction_tag_resolver.dart` | 태그 선정 로직 (FR-3) |
| `supabase/migrations/20260418_quest_pools_faction_fields.sql` | 스키마 확장 + CSV 98행 INSERT + data_versions 갱신 (FR-1, FR-2) |
| `band_of_mercenaries/test/features/quest/domain/faction_tag_resolver_test.dart` | 태그 선정 케이스 유닛 테스트 (가입/비가입/거점 확률) |
| `band_of_mercenaries/test/features/quest/domain/quest_generator_exclusive_test.dart` | 전용 노출 상한·쿨다운 필터링 유닛 테스트 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/features/quest/domain/quest_model.g.dart` | Hive TypeAdapter 재생성 (HiveField 3개 추가) |
| `band_of_mercenaries/lib/core/models/quest_pool.g.dart` `.freezed.dart` | Freezed 필드 5개 추가 |

`cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs` 필수.

### 3.4 관련 시스템

- **퀘스트 시스템**: 코어 대상. QuestGenerator/QuestCompletionService/QuestCalculator/QuestPool/ActiveQuest 모두 변경
- **세력 시스템**: FactionStateRepository.addReputation 호출, clueLevelsInRegion 조회. **FactionState.clueRecords에서 regionId 기반 조회 필요** — 현재 Repository에 해당 조회 메서드 있는지 확인 필요 (없으면 신규 추가 필요 — "기획 확인 사항" 참조)
- **명성 시스템**: `rankRewardBonus`는 PassiveBonusService 결과에서 분리. 페이즈 4의 4번 명세(ReputationService 확장)와 통합
- **파견 화면 UI**: 세력 배지 표시
- **방치/이동/시설 시스템**: 영향 없음

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **정적 유틸 클래스**: `QuestGenerator`, `QuestCalculator` 모두 static 메서드 기반. `FactionTagResolver`도 동일 스타일
- **Freezed JsonKey snake_case**: `QuestPool`의 `min_region_diff` / `max_region_diff` 이미 적용됨. 신규 필드도 동일 규약
- **Hive 모델 필드 추가**: 기존 ActiveQuest는 HiveField 12~16이 null-safe 추가된 전례(CLAUDE.md "`ActiveQuest` 모델에 HiveField 12-16으로 보상 데이터 저장"). 동일 패턴으로 17~19 확장
- **SettingsKeys 단일 키 JSON 저장**: 기존 `dataVersions` 키가 Map을 JSON 문자열로 저장하는 패턴과 동일
- **CSV 기반 마이그레이션**: 본 프로젝트 최초. 하지만 개별 INSERT 98개는 단순 SQL로 충분

### 4.2 주의사항

- **⚠️ CSV 98행 INSERT 누락 금지**: 페이즈 3에서 생성된 CSV는 **반드시 본 명세의 마이그레이션 SQL에 포함**되어야 한다. 별도 단계로 미루면 데이터가 DB에 적재되지 않은 채 기능이 배포될 위험.
- **`type` 컬럼 중복 존재**: `type`(real, 기존) + `type_id`(text, 신규)가 공존. 코드에서는 `type_id`만 사용. 향후 `type` 제거는 별도 마일스톤.
- **PassiveBonusService 의존**: 본 명세의 FR-7은 P1 명세(`PassiveBonusService`)의 `sumRewardMultiplier` 또는 유사 API가 필요. P1 구현 선행 권장. 병행 시 시그니처 합의 필수.
- **QuestCalculator 시그니처 병합**: 페이즈 4의 1번(`factionPassiveBonus`) + 본 명세(`trackBonus/passiveRewardBonus/rankRewardBonus`) + 페이즈 4의 3번(`roleSynergyBonus`)이 모두 `QuestCalculator`를 수정. **1 → 2 → 3 순서로 구현하고 머지 컨플릭트 관리** 필요.
- **쿨다운 정리 타이밍**: 쿨다운 맵 크기 무제한 증가 방지를 위해 `_checkQuestRefresh` 호출 시마다 lazy cleanup 수행 필수. 쿨다운 만료된 항목 제거.
- **전용 퀘스트 중복 할당 방지**: `generateQuests` 반환 시 동일 전용 퀘스트가 중복 포함되면 UI에 쌍둥이 표시. `eligibleExclusive.shuffle + take` 로직이 중복 방지하므로 원본 리스트에 중복 없어야 함(CSV ID 유일성 확인됨 98/98).
- **가입 세력 후보 없는 전용 퀘스트**: 특정 세력만 탈퇴했다가 재가입할 때 `min_reputation` 조건을 다시 충족해야 함. 현재 로직은 단순 비교로 자동 처리.

### 4.3 엣지 케이스

- **가입 세력 = 0**: 전용 퀘스트 모두 미노출. 태그 퀘스트도 비가입 거점 확률만 적용. 일반 퀘스트 위주로 구성됨
- **가입 세력은 있으나 평판 < 11**: 기본 트랙 전용 퀘스트도 미노출. 태그 퀘스트로 평판 누적
- **활성 슬롯이 2 미만**: `min(joined×2, slot×0.5)` → slot×0.5 = 0 또는 1. 전용 노출 0~1개. 초기 정보망 미건설 상태 자연 제약
- **쿨다운 Map JSON 파싱 오류**: 빈 Map으로 초기화, 경고 로그
- **전용 퀘스트 완료 중 세력 탈퇴**: 완료 처리 시점에 이미 저장된 `factionTag`로 평판 지급 시도 → `FactionStateRepository.addReputation`이 미가입 세력에 대해 어떻게 처리하는지 확인 필요 (기획 확인 사항 Q-2)
- **적대 세력(-100) 태그 퀘스트**: `FactionTagResolver`가 `hostileFactionIds`로 제외. 기존에 태그된 활성 퀘스트는 그대로 완료 가능
- **프록시미티 Tier M1 고정**: 거점 시스템 도입 전까지 모든 리전 `proximityTier=3` (10%). M3 이후 거점-리전 거리 계산으로 동적 결정

### 4.4 구현 힌트

- **진입점**: `quest_provider.dart:_checkQuestRefresh()` (라인 199~220). 여기서 1시간 게임 시간 갱신 주기로 QuestGenerator가 호출됨. 쿨다운 수집 + 세력 상태 주입도 이 지점에서 수행
- **데이터 흐름**:
  ```
  _checkQuestRefresh trigger (게임 시간 1h)
    → factionStateRepositoryProvider.getJoinedFactionIds() + 평판 Map
    → SettingsKeys.factionQuestCooldowns 로드 → 만료 정리 → Set<questId>
    → QuestGenerator.generateQuests(..., joinedFactionIds, reputations, cooldownIds)
      → 전용 필터 + 노출 상한 + 쿨다운 제외 + 일반 채우기
      → 일반 퀘스트에 FactionTagResolver.resolve()로 factionTag 동적 부여
      → ActiveQuest 인스턴스 생성 (factionTag, reputationReward, isAdvancedTrack 필드 채움)
    → quests 박스 저장

  퀘스트 완료 (QuestCompletionService)
    → QuestCalculator.calculateReward(trackBonus, passiveRewardBonus, rankRewardBonus)
    → factionTag != null → FactionStateRepository.addReputation(factionTag, reputationReward)
    → isFactionExclusive → 쿨다운 맵에 questId + now() 추가
  ```
- **참조 구현**:
  - `quest_generator.dart:18~36` — 현재 단순 필터·셔플 로직. 여기에 전용/일반 분리 추가
  - `quest_completion_service.dart:125~141` — 기존 XP/명성 계산 블록 바로 뒤에 세력 평판 지급 추가
  - `quest_calculator.dart:86~89 calculateReward` — 현재 2줄 계산. `clamp(0.0, 0.80)` 가산 상한 주입
  - `settings_keys.dart` — 기존 단일 키 JSON 패턴 그대로 적용
  - `faction_state_repository.dart:80~86 addReputation` — 기존 메서드 재사용 (별도 수정 없음)
- **확장 지점**:
  - `FactionTagResolver.resolve()` 내부 `proximityTier` 계산: 거점 시스템 도입 시 외부 서비스로 대체
  - `QuestPool.typeId` 기본값 `'raid'`: 기존 200개 행의 실제 유형 재분류는 별도 콘텐츠 작업

### 4.5 CSV → SQL INSERT 변환 자동화

CSV 98행을 SQL로 변환하는 스크립트 예 (구현 단계 참고):

```bash
cd band_of_mercenaries
tail -n +2 "../Docs/content-data/[faction-quest]20260417_m1-faction-exclusive.csv" | awk -F, '
{
  type_map["1"]="raid"; type_map["2"]="hunt"; type_map["3"]="escort"; type_map["4"]="explore";
  sector=$10; if(sector=="") sector_sql="NULL"; else sector_sql="'\''"sector"'\''";
  printf "(\"%s\", \"%s\", 0, '\''%s'\'', %s, %s, %s, '\''%s'\'', %s, %s, %s),\n",
    $1, $2, type_map[$3], $4, $5, $6, $7, $8, $9, sector_sql;
}' > migration_inserts.sql
```

(실제 구현에서는 awk 따옴표 이스케이프를 정확히 처리. 한국어는 UTF-8 그대로 전달 가능.)

## 5. 기획 확인 사항

- [Q-1] `quest_pools.type` 컬럼 처리 방식: **(A) `type_id` 신규 컬럼 추가** vs (B) 기존 `type`을 real→text 변환 → **FR-1 권장: (A)**. 기존 200행의 type=0 데이터 보존 및 FK 정합성 이유.
- [Q-2] 전용 퀘스트 진행 중 세력 탈퇴 시 완료 처리 — 저장된 `factionTag`에 대해 미가입 상태에서 `addReputation()` 호출이 가능한가? → **`FactionStateRepository.addReputation` 시그니처 확인 필요**. 미가입이면 `joined=false`라 평판 적용 안 될 가능성. **구현 단계에서 동작 확인 후 조정** 권장. 기획 의도: 완료 시점 이미 발생한 퀘스트는 평판 적용 허용.
- [Q-3] 일반 퀘스트의 `type_id`가 없는 기존 200행은 어떻게 처리? → **기본값 `'raid'` 적용 (FR-1 주석)**. 실제 유형 재분류는 콘텐츠 팀 별도 작업. 본 명세는 스키마 확장만 담당.
- [Q-4] 쿨다운 저장을 Hive `settings` 단일 JSON 키로 할지 별도 박스로 할지 → **FR-5: 단일 JSON 키 권장**. 98개 전용 × 6h 만료로 맵 크기 최대 98. 별도 박스 오버헤드 불필요.
- [Q-5] `proximityTier` M1 기본값을 3(10%) vs 2(20%)로 할지 → **권장: 3 (10%)**. 밸런스 리포트 "거점 데이터가 없으면 → 기본 10% 적용" 명시에 따름.
- [Q-6] 태그 퀘스트의 `reputationReward`도 퀘스트 생성 시점에 미리 계산해 저장? → **예.** `ActiveQuest.reputationReward`에 저장. 완료 시점 계산 대신 생성 시점 고정으로 플레이어가 UI에서 "+2 평판" 미리볼 수 있도록.
- [Q-7] **가입 세력이 여러 리전에 단서 보유 시 clue_level 맵을 전체 리전 or 현재 리전만 조회?** → 현재 리전(`regionId`)만. `FactionStateRepository`에서 `getFactionStatesInRegion(regionId)` 또는 유사 메서드 필요. **없으면 Repository에 신규 메서드 추가** 필요 — 본 명세 범위에 포함.

---

## 명세서 생성 완료

파일: `Docs/spec/[spec]20260418_faction-quest-system.md`

### 구현 규모 분석

| 기준 | 내용 | 판정 |
|------|------|------|
| 수정/생성 파일 | 수정 11개 + 신규 4개 = **15개** | **대규모** |
| 영향 시스템 | 퀘스트 / 세력 / 명성(공식 통합) / UI = **4개 시스템** | **대규모** |
| 신규 클래스 | `FactionTagResolver` + `QuestCompletionResult` 확장 = **1~2개** | **소규모** (경계선) |
| 데이터 모델 | `quest_pools` 5컬럼 확장 + 98행 INSERT + `ActiveQuest` 3필드 + `QuestPool` 5필드 + data_versions 갱신 | **대규모** |
| UI 작업 | 퀘스트 카드 배지·강조 (기존 위젯 수정) | **소규모** |
| 기존 시스템 변경 | QuestGenerator/QuestCompletionService/QuestCalculator 시그니처 확장 + quest_provider 갱신 로직 확장 | **대규모** |

**추천: implement-agent** (5/6점)
- CSV 98행 DB 쓰기 + 스키마 확장 + QuestCalculator 시그니처가 P1·P3와 병합 필요 → analyzer→architect→coder→verifier 파이프라인 권장

```
구현을 진행하려면 아래 명령어를 실행해주세요:

/implement-agent @Docs/spec/[spec]20260418_faction-quest-system.md  ← 추천 (파이프라인)
/implement-spec @Docs/spec/[spec]20260418_faction-quest-system.md  (올인원, 비추천)
```
