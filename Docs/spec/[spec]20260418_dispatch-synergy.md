# QuestCalculator 상성 보정 + 파견 UI 힌트 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260417_dispatch_synergy.md` (role × quest_type 매트릭스 컨셉)
> - `Docs/balance-design/20260417_dispatch_synergy_values.md` (85개 job role 분류 + 독립 상한 +10%p)
> 선행 명세:
> - `Docs/spec/[spec]20260418_passive-bonus-service.md` (QuestCalculator에 `factionPassiveBonus` 파라미터 추가)
> - `Docs/spec/[spec]20260418_faction-quest-system.md` (QuestCalculator에 `trackBonus/passiveRewardBonus/rankRewardBonus` 추가)
> 작성일: 2026-04-18
> 마일스톤: M1 페이즈 4 (3/4)
> UI 목업: 사용 안 함 (파견 화면 배지·툴팁은 기존 위젯 확장 범위)

## 1. 개요

`jobs.role` 컬럼을 추가하고 85개 직업에 전수 role(`warrior/ranger/mage/rogue/support/specialist`)을 할당한다. `QuestCalculator.calculateSuccessRate`에 **role × quest_type 상성 매트릭스**를 파티 평균 방식으로 적용하여 `roleSynergyBonus` 독립 레이어(**+10%p 독립 상한**)를 추가한다. 공유 상한 +20%p 밖이므로 엔드게임에서도 전술 선택이 의미를 가진다. 파견 화면에 추천 role 배지, 용병 카드 상성 하이라이트, 성공률 분해 툴팁을 추가한다.

## 2. 요구사항

### 2.1 기능 요구사항

#### FR-1: `jobs.role` 컬럼 추가 및 85개 전수 UPDATE

Supabase `jobs` 테이블에 컬럼 추가:

| 필드 | 타입 | 기본값 | 용도 |
|------|------|-------|------|
| `role` | text | `'specialist'` | 6개 enum 중 하나 — 상성 매트릭스 조회 키 |

**85개 직업 role 분포 (balance 리포트 분석 6 확정):**

| role | 개수 | 비율 |
|------|:---:|:----:|
| warrior | 26 | 30.6% |
| specialist | 16 | 18.8% |
| mage | 16 | 18.8% |
| support | 10 | 11.8% |
| ranger | 9 | 10.6% |
| rogue | 8 | 9.4% |
| **합계** | **85** | 100% |

**마이그레이션 SQL 구조 (개요):**

```sql
BEGIN;

ALTER TABLE jobs ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'specialist';

-- warrior 26개
UPDATE jobs SET role = 'warrior' WHERE id IN (
  'ruffian','gladiator_low','bandit','deserter_sword','mercenary_low',
  'squire','guard_low','militia','deserter_spear',
  'light_cavalry','mercenary','knight_low','shield_bearer','soldier','spearman',
  'mercenary_captain','knight','elite_knight','paladin',
  'demon_general','legend_swordsman','dragon_knight','grand_knight','immortal','paladin_leader','royal_guard_captain'
);

-- ranger 9개
UPDATE jobs SET role = 'ranger' WHERE id IN (
  'hunter_small',
  'archer_low','hunter_mid','deserter_archer','scout_low',
  'monster_hunter','archer_skilled','scout_leader',
  'ranger'
);

-- mage 16개
UPDATE jobs SET role = 'mage' WHERE id IN (
  'apprentice_mage',
  'necromancer_low','battle_mage','druid_low',
  'necromancer','archmage_mid','warlock','elementalist','spellblade','druid','summoner',
  'grand_necromancer','archmage','dimension_mage','ancient_druid','spirit_envoy'
);

-- rogue 8개
UPDATE jobs SET role = 'rogue' WHERE id IN (
  'pickpocket','nomad','messenger',
  'thief','smuggler',
  'assassin_low',
  'assassin',
  'world_assassin'
);

-- support 10개
UPDATE jobs SET role = 'support' WHERE id IN (
  'acolyte',
  'inquisitor_low','bard_combat','priest_mid',
  'inquisitor','high_priest','bard','strategist',
  'high_priest_supreme','oracle'
);

-- specialist는 DEFAULT로 자동 할당 (16개: T1 노동형 11개 + 나머지 5개)
-- 확인용 SELECT: 예상 specialist = 16
-- SELECT role, COUNT(*) FROM jobs GROUP BY role ORDER BY role;

-- data_versions 갱신
UPDATE data_versions SET version = version + 1 WHERE table_name = 'jobs';

COMMIT;
```

전수 매핑은 balance 리포트 `20260417_dispatch_synergy_values.md` "분석 6. 85개 job의 role 분류 (전수)" 표를 기준으로 구현 단계에서 최종 검증.

#### FR-2: `JobData` Freezed 모델에 `role` 필드 추가

- 파일: `band_of_mercenaries/lib/core/models/job.dart`
- 마지막 필드 `baseAgi` 다음에 신규 필드 추가:

```dart
@freezed
class Job with _$Job {
  const factory Job({
    required String id,
    required int tier,
    required String name,
    @JsonKey(name: 'base_str') required int baseStr,
    @JsonKey(name: 'base_intelligence') required int baseIntelligence,
    @JsonKey(name: 'base_vit') required int baseVit,
    @JsonKey(name: 'base_agi') required int baseAgi,
    // 신규:
    @Default('specialist') @JsonKey(name: 'role') String role,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}
```

`@Default('specialist')`로 기존 JSON에 `role` 필드가 없어도 역직렬화 안전(SyncService 업데이트 전 구 캐시 호환).

#### FR-3: `RoleSynergyMatrix` 상수 정의

- 새 파일: `band_of_mercenaries/lib/features/quest/domain/role_synergy_matrix.dart`
- 또는 `QuestCalculator` 내부 private static 상수 (기획서 섹션 2 권장). **권장: 별도 파일 분리** (매트릭스만 읽고 싶은 다른 모듈 — 예: UI 배지 — 에서 재사용).

```dart
/// role × quest_type 상성 매트릭스 (%p 단위).
/// 범위: -2 ~ +8, 파티 평균 적용 후 ±10%p 독립 상한 클램프.
///
/// 밸런스 검증: Docs/balance-design/20260417_dispatch_synergy_values.md 분석 1.
class RoleSynergyMatrix {
  static const Map<String, Map<String, double>> _matrix = {
    'warrior':    {'raid': 8.0,  'hunt': 5.0, 'escort': 3.0, 'explore': -2.0},
    'ranger':     {'raid': 3.0,  'hunt': 8.0, 'escort': 2.0, 'explore': 3.0},
    'mage':       {'raid': -2.0, 'hunt': 2.0, 'escort': 3.0, 'explore': 8.0},
    'rogue':      {'raid': 5.0,  'hunt': 3.0, 'escort': 0.0, 'explore': 5.0},
    'support':    {'raid': 0.0,  'hunt': 2.0, 'escort': 8.0, 'explore': 2.0},
    'specialist': {'raid': 2.0,  'hunt': 2.0, 'escort': 2.0, 'explore': 2.0},
  };

  /// 단일 용병(role)의 특정 퀘스트 유형에 대한 보정값을 반환한다.
  /// 알 수 없는 role → specialist로 fallback. 알 수 없는 quest_type → 0.
  static double singleBonus(String role, String questTypeId) {
    final row = _matrix[role] ?? _matrix['specialist']!;
    return row[questTypeId] ?? 0.0;
  }

  /// 파티 평균 기반 보정값 계산.
  /// - 빈 파티: 0.0
  /// - 파티 멤버별 role 리스트 평균
  /// - 결과를 [-10, +10] %p 독립 상한으로 클램프
  static double partyAverageBonus({
    required List<String> partyRoles,
    required String questTypeId,
  }) {
    if (partyRoles.isEmpty) return 0.0;
    final sum = partyRoles.fold<double>(0.0, (acc, r) => acc + singleBonus(r, questTypeId));
    final avg = sum / partyRoles.length;
    return avg.clamp(-10.0, 10.0);
  }

  /// 해당 quest_type에서 상위 N개 role을 반환 (퀘스트 카드 추천 배지용).
  /// 공동 +8끼리 동률이면 매트릭스 선언 순서 보장.
  static List<MapEntry<String, double>> topRolesForQuest(String questTypeId, {int n = 2}) {
    final entries = _matrix.entries
        .map((e) => MapEntry(e.key, e.value[questTypeId] ?? 0.0))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(n).toList();
  }
}
```

**값 범위:** −2 ~ +8 (기획서 확정). **파티 평균 클램프:** ±10%p 독립 상한.

#### FR-4: `QuestCalculator.calculateSuccessRate` 시그니처 확장

- 파일: `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart`
- P1 명세(`factionPassiveBonus`) + P2 명세(`trackBonus/passiveRewardBonus/rankRewardBonus`)와 **통합된 최종 시그니처**:

```dart
static double calculateSuccessRate({
  required int partyPower,
  required int enemyPower,
  required List<String> traitBonuses,
  required String questTypeId,
  required int distancePenalty,
  required Random random,
  List<TraitData> allTraits = const [],
  int partySize = 1,
  // P1 명세에서 추가:
  double factionPassiveBonus = 0.0,
  // 본 명세에서 추가:
  List<String> partyRoles = const [],
}) {
  if (enemyPower <= 0) return 95.0;
  final powerRatio = partyPower / enemyPower;
  final questMod = _questModifiers[questTypeId] ?? 0.0;
  final traitBonus = TraitEffectService.calculateSuccessRateBonus(
    traitIds: traitBonuses, allTraits: allTraits,
    questTypeId: questTypeId, partySize: partySize,
  );
  final roleSynergyBonus = RoleSynergyMatrix.partyAverageBonus(
    partyRoles: partyRoles, questTypeId: questTypeId);
  final randomVariance = (random.nextDouble() * 10.0) - 5.0;

  final rate = 50.0
      + (powerRatio - 1.0) * 50.0
      + traitBonus
      + questMod
      - distancePenalty.toDouble()
      + roleSynergyBonus        // 신규 독립 레이어
      + factionPassiveBonus     // P1 독립 (공유 상한 +20%p 이미 적용된 값)
      + randomVariance;
  return rate.clamp(5.0, 95.0);
}
```

**`calculateSuccessRatePreview` (UI 표시용)도 동일 파라미터 추가**. `randomVariance`만 제외.

**시그니처 통합 원칙:**
- 모든 신규 파라미터는 **기본값 제공** (`List<String> partyRoles = const []`)으로 하위 호환
- 기존 호출부(파견 로직, 테스트 등)는 단계적 마이그레이션
- 본 명세 구현 순서는 P1 → P2 → P3(본) → P4. QuestCalculator 머지 컨플릭트는 P3 시점에서 필연적으로 해결됨

**호출측 업데이트:**
- `QuestCompletionService.calculate()` 및 호출측(예: 파견 완료 처리, 미리보기 UI)은 `partyRoles` 인자를 계산해 전달해야 함
- `partyRoles` 계산 방식:
  ```dart
  // mercs는 List<Mercenary>, staticData.jobs는 List<Job>
  final partyRoles = mercs.map((m) {
    final job = staticData.jobs.firstWhere(
      (j) => j.id == m.jobId,
      orElse: () => staticData.jobs.first, // 방어적
    );
    return job.role;
  }).toList();
  ```

#### FR-5: `Mercenary` 확장 (선택) — `resolveRole` 헬퍼

- 파일: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart`
- **`Mercenary` 모델은 Hive 저장 대상이므로 `Job` 참조 필드를 직접 추가하지 않는다** (role은 동적 파생값). 대신 호출측에서 `staticData.jobs`를 참조해 계산.
- 편의를 위해 정적 유틸 함수 신설:

```dart
// lib/features/quest/domain/role_utils.dart (신규)
class RoleUtils {
  /// 용병 리스트 → role 리스트 변환. 알 수 없는 jobId는 'specialist' fallback.
  static List<String> extractRoles(List<Mercenary> mercs, List<Job> jobs) {
    return mercs.map((m) {
      final job = jobs.where((j) => j.id == m.jobId).firstOrNull;
      return job?.role ?? 'specialist';
    }).toList();
  }
}
```

**모델 변경 없음**. 헬퍼 함수만 추가.

#### FR-6: `TraitEffectService` 코드 변경 없음 + 트레잇 데이터 업데이트

- **코드 변경 없음.** 기존 `trait_effect_service.dart:15-16`의 `${questTypeId}_success_rate` 키 규약을 재사용 (balance 리포트 분석 5 결정).
- 대신 Supabase `traits` 테이블의 `effect_json` 컬럼을 15개 트레잇에 대해 **업데이트 SQL 필요**.

**예시 SQL (balance 리포트 분석 5 권장 15개 초안):**

```sql
-- 트레잇 시너지 업데이트 (balance report 예시 값)
UPDATE traits SET effect_json = '{"hunt_success_rate": 5.0, "explore_success_rate": 3.0}'::jsonb WHERE key = 'tracker';
UPDATE traits SET effect_json = '{"escort_success_rate": 6.0}'::jsonb WHERE key = 'escort_specialist';
UPDATE traits SET effect_json = '{"raid_success_rate": 4.0, "explore_success_rate": 3.0}'::jsonb WHERE key = 'shadow_step';
UPDATE traits SET effect_json = '{"explore_success_rate": 4.0}'::jsonb WHERE key = 'knowledge_seeker';
UPDATE traits SET effect_json = '{"escort_success_rate": 4.0, "raid_success_rate": -2.0}'::jsonb WHERE key = 'defensive_stance';
UPDATE traits SET effect_json = '{"explore_success_rate": 3.0, "hunt_success_rate": 2.0}'::jsonb WHERE key = 'wanderer_wisdom';
UPDATE traits SET effect_json = '{"raid_success_rate": -3.0, "escort_success_rate": 3.0}'::jsonb WHERE key = 'pacifist';
UPDATE traits SET effect_json = '{"raid_success_rate": 5.0, "explore_success_rate": -2.0}'::jsonb WHERE key = 'brute';
UPDATE traits SET effect_json = '{"success_rate": 2.0}'::jsonb WHERE key = 'tactician';
UPDATE traits SET effect_json = '{"success_rate": -2.0}'::jsonb WHERE key = 'coward';

UPDATE data_versions SET version = version + 1 WHERE table_name = 'traits';
```

**주의:** 위 `key` 값들은 **예시**. 실제 `traits` 테이블의 기존 109개 row 중에서 **운영팀이 선별한 트레잇 키에 매칭 필요**. 구현 단계에서 `SELECT key, name FROM traits` 쿼리로 실제 존재 키를 확인 후 SQL 작성.

**상한:** `TraitEffectService.calculateSuccessRateBonus`는 현재 독립 상한 없이 합산만 수행. **본 명세에서 `QuestCalculator` 호출 직전에 `traitBonus.clamp(-10.0, 10.0)` 적용**으로 독립 상한 +10%p 확보.

```dart
// QuestCalculator.calculateSuccessRate 내부에서
final traitBonusRaw = TraitEffectService.calculateSuccessRateBonus(...);
final traitBonus = traitBonusRaw.clamp(-10.0, 10.0);  // 본 명세 신규 클램프
```

#### FR-7: 성공률 분해 툴팁 UI

- 파일: `band_of_mercenaries/lib/features/quest/view/dispatch_detail_page.dart`
- **현재 위치 (라인 202 주변):** `성공률: X%` 단순 텍스트 표시
- **변경:** 옆에 `?` 아이콘 → 탭 시 하단 시트(`showModalBottomSheet`) 또는 `Tooltip`으로 분해 표시

**분해 표 구조:**

```
성공률 72%

기본값         50%
파티력 비율   +22%  (power 185 / enemy 120)
퀘스트 유형    +5%  (탐험 보정)
상성           +4%  (파티 평균)          ← 본 명세 신규
트레잇         +3%  (지식의 탐구자)
세력 패시브    +8%  (마탑 연합)          ← P1 명세
명성 보너스    +2%  (C+A 누적)            ← P4 명세
공유 상한 도달 -2%  (세력+명성 clamp)     ← P1 명세 연계 (해당 시)
거리 패널티   -20%  (8 리전)
───────────────
합계           72%
```

**요구:** 각 레이어를 별도 항목으로 나열. 공유 상한으로 clamp된 경우 **"공유 상한 도달 −X%"** 별행 표시 (P1 명세의 FR-14 연계).

**위젯 구현 가이드:**
- 신규 위젯 `band_of_mercenaries/lib/features/quest/view/success_rate_breakdown_sheet.dart` (상태 기반 렌더링)
- 파견 상세에서 `_showBreakdownSheet` 상태 변수로 토글
- 위젯은 `SuccessRateBreakdown` 값 객체를 받아 렌더링 (아래 FR-8 참조)

#### FR-8: `SuccessRateBreakdown` 값 객체

- 새 파일: `band_of_mercenaries/lib/features/quest/domain/success_rate_breakdown.dart`
- `QuestCalculator.calculateSuccessRatePreview`에서 **단일 double 반환 대신** 분해 정보를 담은 값 객체 반환하는 **추가 메서드** 제공:

```dart
class SuccessRateBreakdown {
  final double base;                    // 50.0 고정
  final double powerRatioContribution;  // (powerRatio - 1) × 50
  final double questMod;
  final double roleSynergy;
  final double traitBonus;
  final double factionPassiveBonus;
  final double rankBonus;
  final double sharedCapLoss;           // 공유 상한 초과분 (음수)
  final double distancePenalty;         // 음수로 저장
  final double total;                   // clamp(5, 95) 전
  final double finalRate;               // clamp 적용 후
}
```

`QuestCalculator`에 **`calculateSuccessRateBreakdown(...)` static 메서드 추가** — 내부에서 기존 `calculateSuccessRatePreview` 공식을 재사용하되 각 레이어를 개별로 누적/기록. UI는 이 메서드 결과만 사용.

#### FR-9: 파견 화면 퀘스트 카드 추천 role 배지

- 파일: `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` (`_buildQuestCard` 메서드 라인 168~223)
- **위치:** 퀘스트 유형(questType.name) 옆 또는 보상 표시 아래
- **내용:** `RoleSynergyMatrix.topRolesForQuest(quest.questTypeId, n: 2)` 호출 → 상위 2개 role의 아이콘+라벨 `Chip`

**role 아이콘 매핑 (Material Icons 또는 이모지):**

| role | 아이콘 | 한글명 |
|------|:-----:|:-----:|
| warrior | `Icons.shield` | 전사 |
| ranger | `Icons.gps_fixed` | 순찰자 |
| mage | `Icons.auto_awesome` | 마법사 |
| rogue | `Icons.dark_mode` | 도적 |
| support | `Icons.favorite` | 지원 |
| specialist | `Icons.build` | 전문가 |

실제 아이콘은 구현 단계에서 `AppTheme` 컬러와 조합. 위 표는 기본 제안.

#### FR-10: 용병 카드 상성 하이라이트

- 파일: `band_of_mercenaries/lib/features/quest/view/dispatch_detail_page.dart` (라인 125~158 용병 카드 렌더링 부)
- **로직:** 현재 선택 퀘스트의 `questTypeId` 기준으로 각 용병의 role 보정값 계산 → **+5 이상인 용병**은 카드 배경에 `AppTheme.primary.withOpacity(0.10)` 또는 연한 tint
- **추가 정보 표시:** 용병 카드 내 `job.name` 옆 소수 첫째 자리까지 보정값 배지 (예: `+8.0`)

#### FR-11: 용병 상세 오버레이 상성 섹션

- 파일: `band_of_mercenaries/lib/features/mercenary/view/mercenary_detail_overlay.dart` (기존 파일 확인 필요. CLAUDE.md의 "selectedMercenaryIdProvider로 앱 레벨 전체화면 오버레이")
- 기존 트레잇 슬롯 섹션 아래에 **"퀘스트 유형별 상성" 섹션** 추가:

```
이 용병의 상성 (순찰자)
  약탈 +3 · 토벌 +8 · 호위 +2 · 탐험 +3
  트레잇 시너지: 호위 전문가 (+6 호위)
```

- role 이름 한글 매핑: warrior→전사, ranger→순찰자, mage→마법사, rogue→도적, support→지원, specialist→전문가

### 2.2 데이터 요구사항

#### 2.2.1 Supabase 스키마 확장

- 신규 파일: `supabase/migrations/20260418_jobs_role.sql`
- FR-1의 마이그레이션 SQL 구조 적용

#### 2.2.2 트레잇 시너지 데이터 업데이트

- 신규 파일 또는 동일 마이그레이션에 병합: `supabase/migrations/20260418_traits_synergy.sql`
- FR-6의 15개 트레잇 `effect_json` UPDATE SQL
- **기존 `traits.effect_json`은 현재 모두 NULL 상태**(balance 리포트 확인됨). 빈 상태에서 신규 입력하는 것이므로 안전.

#### 2.2.3 Flutter 데이터 모델

**수정 파일:**
- `band_of_mercenaries/lib/core/models/job.dart` — FR-2 `role` 필드 추가

**신규 파일:**
- `band_of_mercenaries/lib/features/quest/domain/role_synergy_matrix.dart` — FR-3
- `band_of_mercenaries/lib/features/quest/domain/success_rate_breakdown.dart` — FR-8
- `band_of_mercenaries/lib/features/quest/domain/role_utils.dart` — FR-5 헬퍼
- `band_of_mercenaries/lib/features/quest/view/success_rate_breakdown_sheet.dart` — FR-7 UI 위젯

**Hive 박스 변경 없음.** `Mercenary` 모델 수정 없음 (role은 동적 파생).

#### 2.2.4 SyncService 영향

- 파일: `band_of_mercenaries/lib/core/data/sync_service.dart`
- `jobs` 테이블 SELECT 쿼리가 `SELECT *` 가정이면 `role` 컬럼 자동 포함
- `data_versions.jobs` 버전 증가 → 포그라운드 복귀 시 자동 재다운로드

### 2.3 UI 요구사항

#### 2.3.1 성공률 분해 툴팁 (신규 위젯)

- **진입 조건:** `DispatchDetailPage`의 `?` 아이콘 탭
- **위젯 계층:** `showModalBottomSheet` > `SafeArea > Column > [제목, ListView(BreakdownItem×N), 닫기 버튼]`
- **상태 변수:** `_showBreakdownSheet` (bool) — 상태 기반 렌더링. Navigator.push 대신 modal bottom sheet 사용
- **화면 전환:** modal bottom sheet로 dispose 시 자동 닫힘. CLAUDE.md Navigator.push 금지 규약 준수
- **연출:** 기본 bottom sheet 슬라이드업 (Material 3 기본)

#### 2.3.2 퀘스트 카드 role 배지 (기존 위젯 수정)

- 진입 조건: 파견 탭 퀘스트 카드 렌더 시
- 위젯 계층: 기존 `Card > Column`에 `Row > [Chip×2]` 추가
- 상태 변수: 없음. `RoleSynergyMatrix.topRolesForQuest` 결과를 렌더 시 계산
- 화면 전환: 없음. 정적 표시

#### 2.3.3 용병 카드 상성 하이라이트 (기존 위젯 수정)

- 진입 조건: `DispatchDetailPage` 용병 목록 렌더 시
- 위젯 계층: 기존 용병 카드 `Container/Card` 배경 색상 조건부 변경
- 조건 로직: `RoleSynergyMatrix.singleBonus(job.role, quest.questTypeId) >= 5.0`
- 연출: 연한 primary tint (`AppTheme.primary.withOpacity(0.10)`)

#### 2.3.4 용병 상세 오버레이 상성 섹션 (기존 위젯 확장)

- 진입 조건: 용병 카드 탭 → 전체화면 오버레이
- 위젯 계층: 기존 `Column > [프로필, 트레잇 슬롯, ...]`에 `Card > Column > [제목, Row(4개 유형 보정값)]` 추가
- 상태 변수: 없음. 렌더 시 계산
- 연출: 기존 용병 상세 레이아웃과 일관. 정적 리스트

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/models/job.dart` | `role` 필드 추가 (`@Default('specialist') @JsonKey(name: 'role')`) | FR-2 |
| `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` | `calculateSuccessRate`/`calculateSuccessRatePreview`에 `partyRoles` 파라미터 추가 + `roleSynergyBonus` 합산 + `traitBonus` 클램프 + `calculateSuccessRateBreakdown` 신규 static 추가 | FR-4, FR-6, FR-8 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | `QuestCalculator.calculateSuccessRate` 호출 시 `partyRoles` 전달 (`RoleUtils.extractRoles` 사용) | FR-4, FR-5 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_detail_page.dart` | 성공률 표시 옆 `?` 아이콘 추가 + 분해 시트 호출 + 용병 카드 상성 하이라이트 | FR-7, FR-10 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` | `_buildQuestCard`에 추천 role 배지 Chip × 2 추가 | FR-9 |
| `band_of_mercenaries/lib/features/mercenary/view/mercenary_detail_overlay.dart` (또는 유사 파일) | 용병 상세 오버레이에 "퀘스트 유형별 상성" 섹션 추가 | FR-11 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | `jobs` 컬럼 확인 (SELECT * 이면 자동) | 2.2.4 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/features/quest/domain/role_synergy_matrix.dart` | 6×4 매트릭스 정적 상수 + 파티 평균 헬퍼 + topRoles 헬퍼 (FR-3) |
| `band_of_mercenaries/lib/features/quest/domain/success_rate_breakdown.dart` | 성공률 분해 값 객체 (FR-8) |
| `band_of_mercenaries/lib/features/quest/domain/role_utils.dart` | Mercenary→role 추출 헬퍼 (FR-5) |
| `band_of_mercenaries/lib/features/quest/view/success_rate_breakdown_sheet.dart` | 분해 툴팁 위젯 (FR-7) |
| `supabase/migrations/20260418_jobs_role.sql` | jobs.role 컬럼 + 85개 UPDATE + data_versions (FR-1) |
| `supabase/migrations/20260418_traits_synergy.sql` | 15개 트레잇 effect_json UPDATE (FR-6) |
| `band_of_mercenaries/test/features/quest/domain/role_synergy_matrix_test.dart` | 매트릭스 단일/평균/topRoles 유닛 테스트 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/job.g.dart` `.freezed.dart` | Job 모델에 role 필드 추가 |

`cd band_of_mercenaries && dart run build_runner build` 필수.

### 3.4 관련 시스템

- **퀘스트 시스템**: QuestCalculator 시그니처 최종 통합 (P1+P2+P3). `quest_completion_service.dart` 호출부 동기화. 파견 미리보기 UI 연결
- **용병 시스템**: Job 모델 확장. Mercenary 모델 변경 없음. 상세 오버레이 UI 확장
- **파견 UI**: 퀘스트 카드 배지, 용병 카드 하이라이트, 분해 툴팁. 모두 상태 기반 렌더링
- **트레잇 시스템**: TraitEffectService 코드 변경 없음. 데이터(effect_json) 업데이트만
- **세력 시스템**: 영향 없음 (상성은 독립 레이어)
- **명성 시스템**: 영향 없음

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **정적 상수 Map**: `QuestCalculator._questModifiers`, `_statWeights` 이미 동일 스타일. `_roleSynergyMatrix`도 정합
- **Freezed JsonKey snake_case**: `Job.baseStr = @JsonKey(name: 'base_str')` 이미 적용. `role`은 snake_case 매핑 불필요(이미 'role')하나 일관성으로 `@JsonKey(name: 'role')` 명시
- **정적 유틸 헬퍼**: `RoleUtils.extractRoles`, `RoleSynergyMatrix.topRolesForQuest` 모두 static 함수 유지
- **상태 기반 오버레이**: CLAUDE.md "웹: `_MobileFrame`에서 `ConstrainedBox(maxWidth: 430)`으로 모바일 해상도 제한. 새 화면 전환 시 `Navigator.push` 대신 상태 기반 렌더링 사용". 분해 시트는 `showModalBottomSheet`(허용) 또는 앱 레벨 오버레이

### 4.2 주의사항

- **QuestCalculator 시그니처 병합 (P1 → P2 → P3)**: 세 명세가 모두 QuestCalculator 수정. 본 명세 구현 시 이미 P1, P2가 머지되어 있어야 함. 실제 시그니처는 본 명세 FR-4의 통합 버전이 최종. **implement-agent 파이프라인에서 순차 처리** 필수
- **`traitBonus.clamp(-10.0, 10.0)` 추가 지점**: 기존 코드는 클램프 없이 합산. 본 명세에서 신규 추가. **별도 독립 상한**으로 role synergy 상한(+10%p)과 **같은 10%p지만 별개 풀** (balance 리포트 분석 3 확정)
- **P2 (T5 ranger 부재) 기록**: `SELECT COUNT(*) FROM jobs WHERE role='ranger' AND tier=5;` = 0. M1 허용. **M2b 이후 T5 ranger 신규 직업 1개 추가 권장** (본 명세 범위 외). 관련 주석을 `RoleSynergyMatrix` 파일 상단에 명기
- **role이 null인 직업 fallback**: `@Default('specialist')`로 JSON 역직렬화에서 자동 처리. SQL DEFAULT도 `'specialist'`. 이중 안전장치
- **트레잇 시너지 독립 상한 +10%p**: FR-6의 `.clamp(-10.0, 10.0)`은 **모든 트레잇 합산 후 적용** — 개별 트레잇 값이 +5를 넘어서는 안 된다는 의미가 아님. 파티 3명 × 트레잇별 +5 합산 = +15 → 클램프로 +10 제한
- **`jobs.role` 마이그레이션 85개 커버 확인**: SQL 실행 후 `SELECT role, COUNT(*) FROM jobs GROUP BY role` 결과가 balance 리포트의 분포(warrior 26 / specialist 16 / mage 16 / support 10 / ranger 9 / rogue 8)와 일치하는지 검증

### 4.3 엣지 케이스

- **빈 파티**: `roleSynergyBonus = 0.0` (RoleSynergyMatrix.partyAverageBonus 조기 반환)
- **알 수 없는 role 값**: `specialist`로 fallback (single 조회)
- **알 수 없는 quest_type**: 매트릭스 조회 결과 null → 0.0 반환
- **파티 멤버 전원 같은 role**: 평균은 단일 role의 보정값 그대로
- **Mercenary.jobId가 staticData.jobs에 존재하지 않음 (데이터 불일치)**: `RoleUtils.extractRoles`가 `'specialist'` fallback. 경고 로그 권장
- **파티 평균 결과가 +8.5 같이 상한을 약간 초과**: 클램프 +10 안쪽이므로 그대로 반영. 소수 첫째 자리까지 UI 표시
- **공유 상한 도달 시 분해 표 표시**: factionPassiveBonus가 +20 상한에 걸려 +X 손실된 경우 — P1 명세의 `cappedSuccessRateBonus`가 이미 상한 적용된 값을 반환하므로 loss 정보는 별도 계산 필요. `SuccessRateBreakdown.sharedCapLoss`는 PassiveBonusService에서 추가 반환값이 필요할 수 있음 (기획 확인 사항 Q-1)

### 4.4 구현 힌트

- **진입점**: `quest_calculator.dart:calculateSuccessRate` + `quest_completion_service.dart` 호출부. 분해 툴팁은 `dispatch_detail_page.dart` 성공률 표시 위젯
- **데이터 흐름**:
  ```
  파견 상세 진입 (DispatchDetailPage)
    → selectedMercenaryIds + quest.questTypeId
    → RoleUtils.extractRoles(mercs, staticData.jobs) → partyRoles
    → QuestCalculator.calculateSuccessRateBreakdown(...) → SuccessRateBreakdown
    → 성공률 표시 + ? 아이콘

  ? 아이콘 탭 → showModalBottomSheet(SuccessRateBreakdownSheet(breakdown))

  퀘스트 카드 렌더
    → RoleSynergyMatrix.topRolesForQuest(quest.questTypeId, n: 2)
    → role별 Chip 위젯 렌더

  용병 카드 렌더 (파견 상세)
    → RoleSynergyMatrix.singleBonus(job.role, quest.questTypeId)
    → bonus >= 5.0이면 primary tint
  ```
- **참조 구현**:
  - `quest_calculator.dart:11~13 _questModifiers`, `:15~20 _statWeights` — 정적 Map 상수 패턴
  - `quest_calculator.dart:32~53 calculateSuccessRate` — 기존 공식 구조. roleSynergyBonus 주입 위치
  - `job.dart` — 기존 Freezed + snake_case JsonKey 규약
  - `mercenary_detail_overlay.dart` (또는 유사) — 트레잇 슬롯 섹션 아래 새 섹션 추가 패턴
  - `dispatch_detail_page.dart:125~158` — 용병 카드 렌더 (하이라이트 적용 위치)
- **확장 지점**:
  - `RoleSynergyMatrix._matrix` Map — 향후 역할 추가·수치 조정 시 이 한 파일만 변경
  - `SuccessRateBreakdown` 값 객체 — 향후 레이어 추가(예: 장비 효과) 시 필드만 확장

### 4.5 통합 마이그레이션 파일 (선택)

작은 마이그레이션 파일이 여러 개(`jobs_role`, `traits_synergy`) 생성되므로 단일 파일로 통합 가능:

```
supabase/migrations/20260418_m1_phase4_complete.sql
  - ranks.bonus_json (P1)
  - ranks.required_reputation E 300 (P1)
  - factions.passive_bonus_json 14행 UPDATE (P1)
  - quest_pools 5컬럼 확장 + 98행 INSERT (P2)
  - jobs.role + 85행 UPDATE (본 명세 P3)
  - traits.effect_json 15행 UPDATE (본 명세 P3)
  - data_versions 일괄 증가
```

단일 트랜잭션으로 묶으면 원자성 보장. 구현 단계에서 유지보수 관점에서 분리 유지 vs 단일 통합 선택.

## 5. 기획 확인 사항

- [Q-1] `SuccessRateBreakdown.sharedCapLoss` 필드 — PassiveBonusService의 `cappedSuccessRateBonus` 는 clamp 결과만 반환. 손실량 추가 반환을 위해 **별도 API** 필요: `cappedSuccessRateBonusWithDetail() → (appliedValue, lossAmount)`. **P1 명세 재검토 필요** — 본 명세에서 요구사항 기록만 하고 P1 구현자와 협의.
- [Q-2] `role` 한글 표시 매핑은 하드코딩(본 명세 FR-11 표) vs enum 또는 상수화? → **권장: 상수화** (`RoleUtils.koreanName(String role)` 함수). 유지보수 용이.
- [Q-3] 퀘스트 카드 상위 2개 role 배지 vs 3개? → **권장: 2개 (기획서 섹션 6 A 표준)**. 3개는 화면 공간 부담.
- [Q-4] role 아이콘 - Material Icons vs 이모지? → **권장: Material Icons** (플랫폼 독립성). 이모지는 웹/모바일 렌더링 차이 발생 가능.
- [Q-5] 용병 카드 하이라이트 기준 +5 이상 vs +3 이상? → **권장: +5 이상** (specialist 제외). +3은 ranger의 raid/explore 보정과 겹쳐 하이라이트 과다.
- [Q-6] 15개 트레잇 시너지 업데이트 시 **실제 `traits.key` 값 확인** — 본 명세 FR-6의 예시 키(`tracker`, `escort_specialist` 등)는 balance 리포트의 권장 값. 실제 Supabase `traits` 테이블에 이 키가 존재하는지 **구현 단계에서 SELECT로 확인 후 매칭**하거나, 존재하지 않으면 가장 근접한 기존 트레잇에 할당. 임의 추정 금지.

---

## 명세서 생성 완료

파일: `Docs/spec/[spec]20260418_dispatch-synergy.md`

### 구현 규모 분석

| 기준 | 내용 | 판정 |
|------|------|------|
| 수정/생성 파일 | 수정 7개 + 신규 7개 = **14개** | **대규모** |
| 영향 시스템 | 퀘스트(Calc/Completion/View) / 용병(Job) / UI(Dispatch/Detail) / 트레잇(데이터만) = **3~4개** | **대규모** |
| 신규 클래스 | `RoleSynergyMatrix`, `SuccessRateBreakdown`, `RoleUtils`, `SuccessRateBreakdownSheet` = **4개** | **대규모** |
| 데이터 모델 | `jobs.role` + 85행 UPDATE + 15개 트레잇 JSON 업데이트 + Job 모델 필드 추가 | **대규모** |
| UI 작업 | 분해 툴팁(신규 위젯) + 퀘스트 카드 배지 + 용병 카드 하이라이트 + 용병 상세 섹션 | **대규모** (4지점) |
| 기존 시스템 변경 | QuestCalculator 시그니처 변경(P1·P2와 병합) + 용병 상세 오버레이 확장 | **대규모** |

**추천: implement-agent** (6/6점)
- P1·P2와 QuestCalculator 시그니처 병합 + 85개 SQL UPDATE + 4지점 UI 수정이 연쇄적으로 얽혀 analyzer→architect→coder→verifier 파이프라인이 필수

```
구현을 진행하려면 아래 명령어를 실행해주세요:

/implement-agent @Docs/spec/[spec]20260418_dispatch-synergy.md  ← 추천 (파이프라인)
/implement-spec @Docs/spec/[spec]20260418_dispatch-synergy.md  (올인원, 비추천)
```
