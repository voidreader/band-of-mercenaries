# 용병 전투 기억 컨텐츠 기획서

> 작성일: 2026-05-21
> 유형: 신규 컨텐츠 (M8.5 페이즈 1 #5)
> 적용 마일스톤: M8.5 "재미 가시화와 폴리싱"
> 선행 문서:
> - `Docs/content-design/[content]20260521_m8.5_combat_emotional_reactions.md` (M8.5 페이즈 1 #3) — 4 감정 발동이 `emotional_apply` entryType의 원천
> - `Docs/content-design/[content]20260521_m8.5_hidden_stats.md` (M8.5 페이즈 1 #4) — lv1·lv5 해금이 `hidden_stat_unlock` entryType의 원천
> - `Docs/content-design/[content]20260521_m8.5_flagship_solo_quests.md` (M8.5 페이즈 1 #2) — 솔로 의뢰 대성공이 `solo_great_success` entryType의 원천
> - `Docs/Archive/20260515_M6_phase4_1_achievement-chronicle/design.md` (M6 위업·연대기) — MercenarySnapshot 보존 패턴, BandAchievement 모델
> - `Docs/Archive/20260515_M6_phase4_2_titles-flagship/design.md` (M6 칭호) — titleIds 보존 + MercenarySnapshot 확장 패턴
> - `Docs/Archive/20260519_m8a_faction_combat_report/spec_p4_2_combat_report_system.md` (M8a 전투 보고서) — TemplateEngine 적용, scope 카탈로그
> - `Docs/roadmap/master_roadmap.md` M8.5 섹션 — 페이즈 1 #5 요구사항
> 후속:
> - M8.5 페이즈 2 #5는 본 문서 입력 사용하지 않음 (수치 결정 항목 없음)
> - M8.5 페이즈 3 #2 "감정 반응 상태 효과 시드"와 통합 (`battle_memory_templates` 신규 테이블 추가)
> - M8.5 페이즈 4 #3 "전투 시뮬레이터 감정 반응·히든 스탯 hook 명세" — 본 문서 + 페이즈 1 #3·#4 통합 spec-writer 호출
> - M8.5 페이즈 4 #4 "용병 상세 화면 전투 기억·히든 스탯·개인 숙련도 섹션 명세" — 본 문서 §3.5 표시 정책 UI 명세화 + ChronicleScreen 통합

---

## 1. 개요

M6 위업이 "용병단이 이 일을 해냈다"라는 단체 명예 카드를 만들었다면, M8.5 전투 기억은 "이 용병이 무엇을 겪었는가"라는 **개별 용병의 사건 일지**를 만든다. M8b CombatSimulator의 결정적 시뮬레이션, M8.5 페이즈 1 #3 감정 반응, 페이즈 1 #4 히든 스탯 해금, M6 위업·칭호 발급이라는 의미 있는 사건들이 활동 로그와 별도로 용병 본인에게 영구 누적된다.

전투 기억은 **신규 텍스트 데이터를 가급적 만들지 않는다**. 원천 사건의 ID만 참조(`sourceEventId`)하고 표시 시 위업·칭호 박스에서 lookup. 그래서 모델 자체는 가벼우면서도, 사용자에게는 "이 용병의 30개 사건 타임라인"이라는 한 화면 가시화를 제공한다. M8.5 "재미 가시화" 핵심 가치의 마지막 한 조각이다.

핵심 결정 사항:
1. **데이터 구조**: `Mercenary.battleMemories: List<BattleMemoryEntry>` 신규 HiveField **27**. `BattleMemoryEntry` 신규 typeId **31** (mercId / entryType / sourceEventId / timestamp / templateKey / templateData 6 필드). 용병당 최대 30개 cap, FIFO 제거. M6 칭호 시스템(`titleIds` HiveField 24) + 페이즈 1 #4 히든 스탯(`hiddenStats` HiveField 26) 패턴 정합.
2. **6 entryType 선별 기록**: `emotional_apply` (4 감정) / `hidden_stat_unlock` (lv1·lv5) / `achievement_granted` (본인 주인공) / `title_granted` (모든 칭호) / `solo_great_success` (솔로 의뢰 대성공) / `unique_elite_first_kill` (유니크 엘리트 첫 처치). 6종 외 사건은 기록하지 않음 (M9 이후 확장 위임).
3. **위업/칭호와의 관계**: `sourceEventId` 참조만. 텍스트 중복 없음. UI에서 위업/칭호 박스 lookup 후 미니 카드 렌더 + 탭 시 원본 화면 점프.
4. **사망/방출 보존**: 페이즈 1 #4에서 결정을 넘긴 `MercenarySnapshot.hiddenStats`를 HiveField **6**으로 보존하고, `MercenarySnapshot.battleMemories: List<BattleMemoryEntry>`는 HiveField **7**로 추가한다. 사망 직전 히든 스탯과 30개 기억을 함께 동결해 ChronicleScreen 카드에서 펼침 가능하게 한다.
5. **표시 정책**: 용병 상세 화면 신규 `BattleMemorySection`. 시간순 desc(최신 위로). 6 entryType별 아이콘 시각 구분. cap 30개 도달 시 "최근 30 기억" 헤더 + 자연 FIFO. lv1 해금/위업 발급/칭호 획득은 본 문서가 추가 다이얼로그를 만들지 않는다 (각 시스템의 기존 다이얼로그가 충분).
6. **신규 텍스트 데이터 최소화**: `BattleMemoryEntry.templateKey`는 6 entryType별 ~5 변형씩 ~30 템플릿. 신규 `battle_memory_templates` 테이블 1개 + 30행 시드. M8a `combat_report_templates` 패턴 정합.

종료 조건 매핑:
| roadmap M8.5 #5 종료 조건 | 본 문서 충족 |
|---|---|
| "용병 상세 화면에서 전투 기억을 확인할 수 있다" | §3.5 `BattleMemorySection` UI 명시 |
| "주요 사건이 누적되어 용병의 정체성이 드러난다" | 6 entryType + 30 cap + 사망 보존 |
| "위업·칭호와 별도 채널이되 자연 연결" | sourceEventId 참조 + lookup 렌더 + 원본 화면 점프 |

---

## 2. 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 본 시스템 적용 |
|---------|-------------|---------------|
| **Dwarf Fortress — Personal Memory Log** | dwarf마다 개인 사건 기록 (전투·우정·외상). 시간순 누적, 사망 후 묘비에 보존 | "용병 개별 사건 일지" 컨셉의 직접 영감. 사망 후 보존 (MercSnapshot)도 차용 |
| **Crusader Kings III — Character Story Cycle** | 인물의 일생 사건이 별도 history 패널에 누적. 사망 후 후손이 열람 가능 | "사망 후에도 기억은 남는다" 컨셉 차용. 본 시스템은 ChronicleScreen 통합 |
| **The Banner Saga — Heroes' Journey Tab** | 각 영웅의 주요 전투·사건이 캐릭터 상세에 누적 표시 | 용병 상세 화면 BattleMemorySection의 직접 영감 |
| **RimWorld — Pawn Memory & Events** | 콜로니스트의 주요 사건이 인물 background에 영구 기록 | sourceEventId 참조 패턴 (event-driven memory) |
| **Wartales — Troop Journal** | 부대원별 개인 사건 누적. 사망 후 묘비에 압축 표시 | 30 cap + 사망 시 MercSnapshot 보존 패턴 |
| **Pillars of Eternity II — Companion Quest Logs** | 동료의 개인 사건이 별도 quest log에 누적 | "용병 정체성을 사건으로 표현" 차용 |
| **Disco Elysium — Whirling-in-Rags Memory** | 인물의 인상적인 사건이 memory 카드로 시각화 | TemplateEngine 사용 + 카드 형식 렌더 차용 |

**핵심 설계 원칙**:
- **"기억은 사람에게 붙는다"** — 위업이 용병단의 공로라면, 전투 기억은 개별 용병의 인생사. M6 칭호가 "어떤 사람인가"의 라벨이라면, 전투 기억은 "무엇을 겪었는가"의 일지. 세 시스템(위업·칭호·전투 기억)이 한 용병의 세 정체성 면을 형성한다.
- **"중복 없는 자연 연결"** — sourceEventId 참조로 위업·칭호 시스템 본체에 의존. 텍스트 데이터 중복 없음. UI에서 원본 카드 lookup. 사용자는 "이 용병이 겪은 위업"을 전투 기억 탭에서 볼 수 있고, 탭 시 위업 본체로 점프.
- **"가시화의 마지막 한 조각"** — M8.5 페이즈 1 #1~#4(생활권 대시보드·솔로 의뢰·감정 반응·히든 스탯)가 모두 "사건"을 발생시켰다면, 본 문서는 그 사건을 "기억"으로 보존하여 시간 위에서 가시화한다.
- **"신규 모델은 1개, 신규 텍스트는 30행"** — 영속 모델 1개(BattleMemoryEntry) + 신규 테이블 1개(battle_memory_templates 30행). 페이즈 1 #4 정합으로 최소 확장.

---

## 3. 상세 설계

### 3.1 `BattleMemoryEntry` 모델

#### 3.1.1 Hive 모델 정의

```dart
@HiveType(typeId: 31)
class BattleMemoryEntry extends HiveObject {
  @HiveField(0)
  final String mercId;            // 기억 소유 용병 ID. CombatSimulationResult 후보 적용에 사용

  @HiveField(1)
  final String entryType;          // 6 entryType 중 하나 (§3.2)

  @HiveField(2)
  final String sourceEventId;      // 원천 사건 ID (entryType별 컨벤션, §3.3)

  @HiveField(3)
  final DateTime timestamp;        // 사건 발생 시각

  @HiveField(4)
  final String? templateKey;       // battle_memory_templates 키 (nullable, 위업·칭호는 null)

  @HiveField(5)
  final Map<String, dynamic> templateData;  // TemplateEngine 변수 (questName, enemyName 등)

  BattleMemoryEntry({
    required this.mercId,
    required this.entryType,
    required this.sourceEventId,
    required this.timestamp,
    this.templateKey,
    this.templateData = const {},
  });
}
```

**typeId 점유**: 현재 코드 기준 30(`PositionRow`)까지 점유하므로 다음 가용 **31**을 사용한다. 구현 후 다음 신규 typeId는 **32**이다.

#### 3.1.2 Mercenary 모델 확장

```dart
@HiveType(typeId: 1)
class Mercenary extends HiveObject {
  // ... 기존 0~26 ...

  @HiveField(27)
  List<BattleMemoryEntry> battleMemories;  // 신규 — 최대 30개 cap FIFO
}
```

**HiveField 점유 갱신**:
- 현재 `Mercenary` 다음 HiveField: 26 (페이즈 1 #4 `hiddenStats` 사용)
- 본 문서로 **27** (`battleMemories`) 사용 → 다음 가용 **28**

기존 데이터 호환: nullable 또는 default 빈 List. Hive 자동 마이그레이션.

#### 3.1.3 30 cap FIFO 정책

```dart
void addBattleMemory(BattleMemoryEntry entry) {
  battleMemories.add(entry);
  while (battleMemories.length > 30) {
    battleMemories.removeAt(0);  // 가장 오래된 제거
  }
}
```

cap 30 결정 근거:
- 활동 로그 100 cap의 30% — 개별 용병의 의미 있는 사건만 모은 압축본
- UI 스크롤 부담 적정 (한 페이지 8~10개 + 스크롤 3페이지 이내)
- 30개 사건이면 ~2~3시간 플레이 분량 (페이즈 2 #4 추정)
- M5 인벤토리 999 클램프 같은 큰 cap이 아닌 의미 있는 압축

cap 정책 분기 검토:
- (A) 단순 FIFO (시간순 가장 오래된 제거) — 권장
- (B) 우선순위 보존 (위업·칭호는 영구) — 복잡도 증가
- (C) lv5 해금·솔로 대성공 등 "큰 사건"은 별도 슬롯 — 단순 FIFO 권장

**결정**: (A) 단순 FIFO. 사용자가 "오래된 기억은 흐릿해진다" 자연 인지. M6 칭호·위업 시스템은 영구 보존이므로 큰 사건은 원본 시스템에서 자연 보존된다.

### 3.2 6 entryType 카탈로그

#### 3.2.1 표

| entryType | 발동 시점 | 원천 사건 | sourceEventId 컨벤션 | templateKey 사용 |
|-----------|----------|---------|--------------------|---------------|
| `emotional_apply` | 페이즈 1 #3 4 감정 발동 직후 | 분노/절망/슬픔/투지 발동 | 상태 효과 ID 그대로. 예: `emotional_determination` | O (4 감정 × 5 변형) |
| `hidden_stat_unlock` | 페이즈 1 #4 lv1 해금 또는 lv5 완성 | 5 히든 스탯 lv1·lv5 도달 | `hidden_{stat_id}_{lv}` 예: `hidden_fortitude_1`, `hidden_fortitude_5` | O (5 스탯 × 2 lv × 1 변형 = 10) |
| `achievement_granted` | M6 AchievementService.grant() 시 본인이 mercSnapshot 주인공일 때 | 위업 발급 | `achievement:{template_id}` 예: `achievement:chain_completed:chain_roadside_shrine` | N (위업 본체에서 lookup) |
| `title_granted` | M6 TitleService 칭호 부여 시 | 칭호 획득 | `title:{title_id}` 예: `title:title_lone_wolf` | N (칭호 본체에서 lookup) |
| `solo_great_success` | 페이즈 1 #2 솔로 의뢰 (`party_size_max == 1`) `greatSuccess` 결과 시 | 솔로 의뢰 대성공 | `quest:{quest_pool_id}` 예: `quest:qp_solo_flagship_request` | O (솔로 의뢰 5종 별 1 변형) |
| `unique_elite_first_kill` | M2b 유니크 엘리트 첫 처치 시 (본인 파견) | 유니크 엘리트 첫 처치 | `elite:{elite_id}` 예: `elite:dustsand_wraith_king` | O (엘리트별 ~10 통합 풀) |

#### 3.2.2 emotional_apply 발동 정합 (페이즈 1 #3 보강)

페이즈 1 #3 §3.3.3에서 감정 발동은 `CombatSimulator` Phase 3 라운드 흐름 trailing. 본 문서 entryType은 같은 trailing 위치에서 fail-soft로 추가 기록:

```
Phase 3 라운드 흐름:
  ...
  4. 행동 실행 (각 전투원 1회):
     - 액션 후 사망 마킹 → 감정 trigger: 분노 (페이즈 1 #3)
       └ 분노 발동 성공 시 `CombatSimulationResult.battleMemoryEvents`에 BattleMemoryEntry 후보 추가 (본 문서 신규)
     - 액션 후 중상 마킹 → 감정 trigger: 슬픔
       └ 슬픔 발동 성공 시 추가
     ...
```

`CombatSimulator`는 순수 도메인 서비스이므로 `Mercenary` Hive 객체를 직접 변경하지 않는다. emotional_apply 기록은 `CombatSimulationResult.battleMemoryEvents`에 후보로 담고, 실제 `mercenary.battleMemories` 영속 반영은 `QuestCompletionService` trailing에서 수행한다. 각 후보 생성과 적용은 try/catch fail-soft로 처리한다.

#### 3.2.3 hidden_stat_unlock 발동 정합 (페이즈 1 #4 보강)

페이즈 1 #4 §3.7.2에서 lv 임계 평가는 `QuestCompletionService` 보상 처리 직후 trailing. lv1 또는 lv5 도달 시 본 문서 추가:

```
QuestCompletionService trailing:
  ...
  hiddenStat 카운터 증가
  lv 임계 평가
    └ lv1 도달 시:
       (1) hiddenStatUnlockedProvider enqueue (페이즈 1 #4)
       (2) mercenary.battleMemories에 BattleMemoryEntry(entryType='hidden_stat_unlock', sourceEventId='hidden_fortitude_1') 추가 (본 문서)
    └ lv5 도달 시:
       (1) ActivityLog hiddenStatLevelUp 기록 (페이즈 1 #4)
       (2) BattleMemoryEntry(entryType='hidden_stat_unlock', sourceEventId='hidden_fortitude_5') 추가 (본 문서)
```

**lv2~lv4는 기록하지 않음**. lv1=발견(첫 해금), lv5=완성(최대 도달)만 의미 있는 사건. 중간 단계는 활동 로그만.

#### 3.2.4 achievement_granted 발동 정합 (M6 보강)

M6 `AchievementService.grant()`는 mercSnapshot을 받아 위업을 발급한다. 본 문서는 다음 trailing 추가:

```
AchievementService.grant():
  ...
  bandAchievementsBox.add(achievement)
  activityLog 기록
  dialog 큐 enqueue (위업 카테고리 따라)
  └ mercSnapshot이 non-null일 때 trailing:
     - mercSnapshot.id로 mercenary 본체 lookup
     - mercenary.battleMemories에 BattleMemoryEntry(entryType='achievement_granted', sourceEventId='achievement:${achievement.templateId}') 추가
     - fail-soft try/catch
```

위업 발급은 mercSnapshot 주인공이 있을 때만 본 문서 기록. 주인공 없는 위업(예: `reputation_rank:A` 같은 용병단 전체 위업)은 기록 안 함.

#### 3.2.5 title_granted 발동 정합 (M6 보강)

M6 `TitleService._grantTitle()` 본체에 trailing 추가:

```
TitleService._grantTitle(mercId, titleId):
  ...
  mercenary.titleIds.add(titleId)
  updateMercenaryTitles()
  activityLog titleUnlocked 기록
  titleUnlockedDialog enqueue
  └ trailing:
     - mercenary.battleMemories에 BattleMemoryEntry(entryType='title_granted', sourceEventId='title:$titleId') 추가
     - fail-soft try/catch
```

#### 3.2.6 solo_great_success 발동 정합 (페이즈 1 #2 보강)

페이즈 1 #2 솔로 의뢰 (`party_size_max == 1`)가 `greatSuccess`로 끝났을 때 `QuestCompletionService` trailing:

```
QuestCompletionService trailing (페이즈 1 #2):
  ...
  if (pool.partySizeMax == 1 && resultType == greatSuccess):
    - solo_great_success_count 카운터 +1 (페이즈 1 #2)
    - mercenary.battleMemories에 BattleMemoryEntry(entryType='solo_great_success', sourceEventId='quest:${pool.id}') 추가 (본 문서)
```

#### 3.2.7 unique_elite_first_kill 발동 정합 (M2b 보강)

M2b 엘리트 시스템에서 유니크 엘리트(`is_unique == true`) 첫 처치 시 본 문서 기록:

```
QuestCompletionService 엘리트 분기 (M2b):
  ...
  if (eliteId != null && elite.isUnique && firstKill):
    - UserData.killedUniqueEliteIds.add(eliteId) (M6 위업 hook)
    - eliteRegionStateMapping trailing (M7)
    - 파견 mercenary 전원에게 BattleMemoryEntry(entryType='unique_elite_first_kill', sourceEventId='elite:$eliteId') 추가 (본 문서)
```

**파견 mercenary 전원 기록**: 유니크 엘리트 첫 처치는 큰 사건이므로 같은 파티 mercenary 모두에게 기록.

### 3.3 sourceEventId 참조 + lookup 렌더

#### 3.3.1 entryType별 렌더 정책

| entryType | UI 렌더 방식 |
|-----------|------------|
| `emotional_apply` | templateKey + templateData → TemplateEngine 렌더 (예: "동료의 죽음에 분노하며 적을 헤집었다") |
| `hidden_stat_unlock` | templateKey 고정 텍스트 (예: "✨ 불굴 lv1 발견", "★ 불굴 lv5 완성") |
| `achievement_granted` | sourceEventId의 templateId로 `bandAchievementsBox` lookup → 위업 미니 카드 (아이콘 + 위업명) + 탭 → ChronicleScreen 점프 |
| `title_granted` | sourceEventId의 titleId로 `titles` 정적 데이터 lookup → 칭호 미니 카드 (아이콘 + 칭호명) + 탭 → 본 용병 칭호 섹션 강조 |
| `solo_great_success` | templateKey + templateData → 의뢰명 포함 텍스트 (예: "솔로 의뢰 '셔행장의 부탁'을 대성공으로 마쳤다") |
| `unique_elite_first_kill` | templateKey + templateData → 엘리트명 포함 텍스트 (예: "유니크 엘리트 '먼지바람의 망령왕'을 처치했다") |

#### 3.3.2 lookup 실패 시 fail-soft

위업·칭호 참조가 lookup 실패할 가능성:
- 위업: 사용자가 의도적으로 위업 삭제 (현재 시스템 없음) — 거의 불가능
- 칭호: 운영자가 `titles` 정적 데이터 행 삭제 — 가능

lookup 실패 시 BattleMemoryEntry를 빈 카드로 렌더하지 않고 자동 숨김:
```dart
final achievement = bandAchievementsBox.values.firstWhereOrNull(
  (a) => 'achievement:${a.templateId}' == entry.sourceEventId,
);
if (achievement == null) return SizedBox.shrink();
// 렌더
```

### 3.4 사망/방출 시 MercenarySnapshot 보존

#### 3.4.1 MercenarySnapshot 확장

```dart
@HiveType(typeId: 18)
class MercenarySnapshot extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String name;
  @HiveField(2) final String jobId;
  @HiveField(3) final String jobName;
  @HiveField(4) final int tier;
  @HiveField(5) final List<String> titleIds;
  @HiveField(6) final Map<String, int> hiddenStats;  // M8.5 #4 결정 — 사망 시점 히든 스탯 동결
  @HiveField(7) final List<BattleMemoryEntry> battleMemories;  // 신규 — 30개 전체 보존

  MercenarySnapshot.fromMercenary(Mercenary merc)
    : id = merc.id,
      ...,
      titleIds = List.from(merc.titleIds),
      hiddenStats = Map.from(merc.hiddenStats),
      battleMemories = List.from(merc.battleMemories);  // 사망 직전 동결
}
```

**HiveField 점유 갱신**: 현재 5(titleIds)까지 점유한다. 페이즈 1 #4의 `hiddenStats` 보존 결정을 본 문서에서 확정해 **6**을 사용하고, 본 문서의 `battleMemories`는 **7**을 사용한다. 구현 후 `MercenarySnapshot` 다음 HiveField는 **8**이다.

#### 3.4.2 보존 시점

`AchievementService.recordMemorial(MemorialCause, MercenarySnapshot, payload?)` 호출 시 mercSnapshot 구성 단계에서 `fromMercenary()`가 `hiddenStats`와 `battleMemories`를 자동 보존한다. M6 정합. 별도 trailing 코드 불필요.

`MercenaryRepository.dismiss(mercId)`도 동일하게 `MercenarySnapshot.fromMercenary` 호출 → 자동 보존.

#### 3.4.3 ChronicleScreen 통합

ChronicleScreen은 M6에서 도입된 위업 + memorial 통합 화면. 본 문서는 ChronicleScreen에서 memorial 카드 펼침 시 battleMemories 30개를 함께 표시 (페이즈 4 #4 UI 명세):

```
[ChronicleScreen — Memorial 카드 펼침]

✝ 김철수
  T3 검사 / Lv3
  사망 원인: 의뢰 중 사망 (greatSuccess 직후)
  사망일: 2026-05-21

  보유 칭호: [외로운 늑대] [폐광의 생존자]
  히든 스탯: 불굴 lv5 · 운 lv3

  ▼ 그가 겪은 일 (30 기억)         ← 신규 (본 문서)
    [최신 → 과거]
    🌑 절망 발동 (동료 한설아의 사망)
    ⚡ 분노 발동
    ✨ 불굴 lv5 완성
    ⭐ 솔로 대성공: 셔행장의 부탁
    [위업] 폐광의 생존자
    [칭호] 외로운 늑대 획득
    ✨ 운 lv1 발견
    ⚡ 분노 발동
    ...
```

### 3.5 표시 정책 — `BattleMemorySection`

#### 3.5.1 UI 구조

용병 상세 화면 (`MercenaryDetailOverlay`) 신규 섹션. 페이즈 1 #4 `HiddenStatsSection` 다음 배치 권장:

```
[용병 상세 화면 — 섹션 순서]
  1. 기본 정보 (이름·티어·직업·레벨·HP/MP)
  2. 스탯 (STR/INT/VIT/AGI)
  3. 트레잇 슬롯 그리드
  4. 시너지 섹션 (M5)
  5. 칭호 섹션 (M6)
  6. 히든 스탯 섹션 (M8.5 #4)
  7. 전투 기억 섹션 (M8.5 #5)  ← 신규
  8. 행동 지표 (기존, 접기 default)
  9. 트레잇 히스토리 (기존, 접기 default)
```

#### 3.5.2 섹션 내부 레이아웃

```
[전투 기억 섹션]

📖 전투 기억  (12/30)              ←─ 헤더 + 카운트

[최신 → 과거 시간순 카드 리스트]

⚡ 어제, 분노 발동                  ←─ emotional_apply
   "동료의 죽음에 분노하며 적을 헤집었다"

✨ 어제, 불굴 lv5 완성              ←─ hidden_stat_unlock (lv5)
   "끈기의 극치에 도달했습니다"

[위업] 어제                         ←─ achievement_granted (위업 미니 카드)
   ★ 폐광의 생존자
   탭 → 연대기로 이동

⭐ 2일 전, 솔로 대성공              ←─ solo_great_success
   "솔로 의뢰 '셔행장의 부탁'을 대성공으로 마쳤다"

[칭호] 3일 전                       ←─ title_granted (칭호 미니 카드)
   ★ 외로운 늑대 획득

🌑 4일 전, 절망 면제                ←─ emotional_apply (despair 면제)
   "동료들이 무너졌지만 김철수는 굳건했다"

🔥 5일 전, 유니크 엘리트 처치       ←─ unique_elite_first_kill
   "먼지바람의 망령왕을 처치했다"

...
```

#### 3.5.3 entryType별 아이콘 매핑

| entryType | 아이콘 | 색상 |
|-----------|--------|------|
| `emotional_apply: rage` | ⚡ | AppTheme.dangerRed |
| `emotional_apply: despair` | 🌑 | AppTheme.memorialGray |
| `emotional_apply: sorrow` | 💧 | (옅은 블루) |
| `emotional_apply: determination` | ✨ | AppTheme.chainGold |
| `hidden_stat_unlock` | ✨ | AppTheme.hiddenStatAccent (페이즈 1 #4) |
| `achievement_granted` | ★ | AppTheme.chainGold |
| `title_granted` | ★ | AppTheme.chainGold |
| `solo_great_success` | ⭐ | AppTheme.namedAccent (페이즈 1 #2) |
| `unique_elite_first_kill` | 🔥 | AppTheme.uniqueAccent |

#### 3.5.4 시간 표시

상대 시간 ("어제", "3일 전", "1주일 전") + 호버 시 절대 시간 (timestamp). M8a CombatReport 시간 표시 패턴 정합.

#### 3.5.5 빈 상태

cap 0개인 신규 용병 (모집 직후):
```
📖 전투 기억  (0/30)

  아직 기억이 없습니다.
  이 용병이 의뢰를 수행하면 사건이 누적됩니다.
```

#### 3.5.6 추가 다이얼로그 없음

본 문서는 추가 다이얼로그를 만들지 않는다:
- `emotional_apply`: 페이즈 1 #3에서 별도 다이얼로그 없음 (보고서 통합)
- `hidden_stat_unlock`: 페이즈 1 #4 `HiddenStatUnlockedDialog`가 lv1만 보여줌 (lv5는 활동 로그만)
- `achievement_granted` / `title_granted`: M6 `AchievementUnlockedDialog` / `TitleUnlockedDialog` 그대로
- `solo_great_success`: 의뢰 결과 다이얼로그가 충분
- `unique_elite_first_kill`: 의뢰 결과 다이얼로그가 충분

전투 기억은 "이미 보여진 사건의 누적 기록"이므로 별도 다이얼로그 부담 없음.

### 3.6 `battle_memory_templates` 신규 테이블

#### 3.6.1 스키마

`emotional_apply` / `hidden_stat_unlock` / `solo_great_success` / `unique_elite_first_kill` 4 entryType은 templateKey 사용. 텍스트는 SyncService로 관리.

| 컬럼 | 타입 | 제약 | 의미 |
|------|------|------|------|
| `id` | TEXT | PRIMARY KEY | templateKey (예: `memory_determination_solo`) |
| `entry_type` | TEXT | NOT NULL CHECK | 6 entryType 중 하나 |
| `source_event_match` | TEXT | NULL | sourceEventId 매칭 패턴 (예: `emotional_determination` / `hidden_fortitude_1` / NULL=모든 매칭) |
| `template` | TEXT | NOT NULL | TemplateEngine 텍스트 (변수 `{merc.name}`, `{quest.name}`, `{enemy.name}` 사용) |
| `weight` | INT | NOT NULL DEFAULT 1 | 가중 random 선택 weight |

**SyncService 등록**: 페이즈 1 #4의 `hidden_stats`가 41번째 테이블이므로, 본 문서는 `battle_memory_templates`를 **42번째 테이블**로 등록한다. 템플릿 캐시가 비어도 앱 기동과 기존 기억 렌더가 막히면 안 되므로 `optionalTables`에도 포함한다. 템플릿 lookup 실패 시 해당 템플릿 기반 기억은 fail-soft 숨김 또는 fallback 문구로 처리한다.

#### 3.6.2 시드 30행 분포 (페이즈 3 #2 또는 페이즈 4 #3 위임)

| entry_type | source_event_match 풀 | 변형 수 | 누적 |
|-----------|--------------------|--------|------|
| emotional_apply | rage / despair / sorrow / determination | 4 × 3 = 12 | 12 |
| hidden_stat_unlock | hidden_*_1 / hidden_*_5 (5×2=10) | 1 각각 | 10 |
| solo_great_success | quest:* (와일드카드) | 3 변형 | 3 |
| unique_elite_first_kill | elite:* (와일드카드) | 5 변형 | 5 |
| **합계** | | | **30** |

`achievement_granted` / `title_granted`는 templateKey 사용 안 함 (lookup 렌더). 신규 텍스트 0행.

### 3.7 카운터 추가 없음

페이즈 1 #4가 `Mercenary.stats`에 5 신규 카운터 (`fortitude_event_count` 등)를 추가했다. 본 문서는 추가 카운터를 만들지 않는다. `battleMemories.length`로 사건 수를 직접 셀 수 있고, entryType 필터로 카테고리별 카운트 가능.

만약 페이즈 4 #4 UI에서 "이 용병의 분노 발동 횟수" 같은 통계가 필요하면 `battleMemories.where((e) => e.entryType == 'emotional_apply' && e.sourceEventId == 'emotional_rage').length`로 즉시 산출. 별도 카운터 불필요.

### 3.8 모델 확장 검토 (본 문서 미도입)

| 필드 | 도입 결정 | 사유 |
|------|---------|------|
| `BattleMemoryEntry.priority: int` | ❌ 미도입 | FIFO 단순화 (§3.1.3 옵션 A) |
| `BattleMemoryEntry.isImportant: bool` | ❌ 미도입 | FIFO에서 보호 정책 복잡도 증가 |
| `Mercenary.battleMemoryCounters: Map<String, int>` | ❌ 미도입 | §3.7 — battleMemories 필터로 즉시 산출 |
| `BattleMemoryEntry.combatReportId: String?` | ❌ 미도입 | M8a CombatReport는 ActiveQuest에 임베드 → 별도 ID 없음. 솔로 대성공 시 quest_pool_id로 충분 |
| `BattleMemoryEntry.sharedWithChronicle: bool` | ❌ 미도입 | ChronicleScreen은 memorial 카드 펼침 시 battleMemories 함께 표시 (§3.4.3). 별도 플래그 없이 자연 통합 |
| `CombatantSnapshot.battleMemories` | ❌ 미도입 | 전투 시작 시점 스냅샷은 전투 중 생성되는 기억을 담기에 부적합 |

---

## 4. 현재 시스템과의 연관

### 4.1 영향받는 시스템

| 시스템 | 영향 내용 | 마이그레이션 |
|--------|----------|-------------|
| `BattleMemoryEntry` Hive 모델 | 신규 typeId 31 (6 필드: mercId 포함) | 페이즈 4 #3 |
| `Mercenary` 모델 | HiveField 27 `battleMemories: List<BattleMemoryEntry>` 추가 | 페이즈 4 #3 |
| `MercenarySnapshot` 모델 | HiveField 6 `hiddenStats: Map<String,int>` + HiveField 7 `battleMemories: List<BattleMemoryEntry>` 추가 (사망 보존) | 페이즈 4 #3 |
| `CombatSimulationResult` 모델 | HiveField 14 `battleMemoryEvents: List<BattleMemoryEntry>` 추가. 각 entry의 `mercId`로 적용 대상 식별. HiveField 13은 페이즈 1 #4 `hiddenStatEvents`가 사용 | 페이즈 4 #3 |
| Supabase `battle_memory_templates` 테이블 | 42번째 신규 정적 테이블 + 30행 INSERT, `optionalTables` 등록 | 페이즈 3 #2 또는 페이즈 4 #3 |
| `BattleMemoryTemplate` Freezed 모델 | 신규 모델 (5 필드) | 페이즈 4 #3 |
| `StaticGameData.battleMemoryTemplates: List<BattleMemoryTemplate>` | 신규 필드 | 페이즈 4 #3 |
| `SyncService.allTables` | 42번째 `battle_memory_templates` 등록 + `optionalTables` 포함 | 페이즈 4 #3 |
| `CombatSimulator.simulate` | 4 emotional trigger 후 trailing — `battleMemoryEvents` 후보 생성 fail-soft (페이즈 1 #3 정합) | 페이즈 4 #3 |
| `QuestCompletionService` | `battleMemoryEvents` 적용 + 4 entryType trailing (hidden_stat_unlock lv1·lv5 / solo_great_success / unique_elite_first_kill) | 페이즈 4 #3 |
| `AchievementService.grant` | mercSnapshot 주인공일 때 본인 mercenary.battleMemories trailing | 페이즈 4 #3 |
| `TitleService._grantTitle` | 칭호 부여 직후 본인 mercenary.battleMemories trailing | 페이즈 4 #3 |
| `MercenaryRepository.dismiss` | MercenarySnapshot.fromMercenary 호출 시 battleMemories 자동 동결 | 페이즈 4 #3 (자동, 별도 코드 없음) |
| `MercenaryDetailOverlay` | 신규 `BattleMemorySection` 위젯 (시간순 desc, 아이콘 매핑, lookup 렌더, fail-soft) | 페이즈 4 #4 |
| `ChronicleScreen` | Memorial 카드 펼침 시 battleMemories 30개 함께 표시 (페이즈 4 #4) | 페이즈 4 #4 |
| `TemplateEngine` | entryType별 변수 컨텍스트 (`merc.name`, `quest.name`, `enemy.name`) — 기존 TemplateContext 재사용 | 변경 없음 |
| `AppTheme` | 페이즈 1 #4 `hiddenStatAccent` 재사용 + entryType별 아이콘 색상 매핑 | 페이즈 4 #4 |
| operation-bom | `battle_memory_templates` 편집 폼 30행 | 별도 작업 |

### 4.2 호환성 검토

- **기존 Mercenary 데이터**: `battleMemories == []` (빈 List) default. Hive 자동 호환.
- **기존 MercenarySnapshot 데이터** (M6 위업·memorial): `hiddenStats == {}` + `battleMemories == []` default. 기존 memorial 카드는 빈 List로 렌더. 페이즈 4 #4에서 빈 List는 "기억 없음" 처리.
- **M6 위업·칭호 시스템**: 본 문서는 trailing 추가만. 위업·칭호 본체 영향 없음.
- **M8b CombatSimulator**: emotional_apply 후보 생성은 fail-soft이며 영속 저장은 QuestCompletionService가 담당한다. 시뮬레이션 무결성 영향 없음.
- **M8a CombatReport**: 영향 없음 (별도 채널).
- **활동 로그 시스템**: 영향 없음. 활동 로그는 용병단 전체, 전투 기억은 용병 개별.

### 4.3 호환성 리스크

- **낮음**: typeId 31 신규는 현재 코드의 다음 가용 번호와 정합. 다음 신규 typeId는 32.
- **중간**: `Mercenary.battleMemories` 30 cap × 다수 용병 → 메모리 부담. 100명 용병 × 30 entry = 3000 entry. 각 entry ~200 bytes → ~600KB. 무시 가능 수준.
- **중간**: MercenarySnapshot 보존 데이터 영구 누적 → 사망/방출 100명 × 30 entry = 3000 entry. 위와 동일 ~600KB. 6개월 이상 플레이에서도 1MB 미만.
- **낮음**: `sourceEventId` 위업·칭호 참조 정합 — 위업 templateId 변경 / 칭호 ID 변경 시 stale 참조. fail-soft 자동 숨김 (§3.3.2).
- **낮음**: cap 30 FIFO 정책 — 큰 사건이 작은 사건으로 밀려날 수 있음. 단순성 우선 (§3.1.3 옵션 A).

---

## 5. 구현 우선순위 제안

| 항목 | 우선순위 | 근거 |
|------|---------|------|
| `BattleMemoryEntry` Hive 모델 (typeId 31) + Mercenary.battleMemories HiveField 27 | **높음** | 영속 데이터 토대 |
| `MercenarySnapshot.hiddenStats` HiveField 6 + `battleMemories` HiveField 7 추가 | **높음** | 사망 보존 핵심 |
| `CombatSimulationResult.battleMemoryEvents` HiveField 14 추가 | **높음** | 순수 시뮬레이터와 Hive 영속 반영 경계 유지 |
| `battle_memory_templates` 신규 테이블(42번째) + 30행 INSERT | **높음** | 4 entryType 텍스트 데이터 |
| `BattleMemoryTemplate` Freezed 모델 + `StaticGameData.battleMemoryTemplates` + SyncService 등록 | **높음** | 정적 데이터 동기화 |
| `CombatSimulator.simulate` emotional_apply 후보 생성 | **높음** | 4 감정 기록 원천 |
| `QuestCompletionService` battleMemoryEvents 적용 + 4 entryType trailing | **높음** | 의뢰 결과 영속 기록 |
| `AchievementService.grant` / `TitleService._grantTitle` trailing | **높음** | 위업·칭호 기록 |
| `MercenaryDetailOverlay` 신규 `BattleMemorySection` | **높음** | 종료 조건 충족 |
| `ChronicleScreen` memorial 카드 battleMemories 펼침 | **중간** | UX 통합 |
| sourceEventId lookup 렌더 (위업·칭호 미니 카드) | **중간** | 중복 없는 자연 연결 |
| entryType별 아이콘·색상 매핑 | **중간** | UI 폴리싱 |
| 빈 상태 + cap 30 헤더 UI | **중간** | UX 완성도 |
| operation-bom 편집 폼 확장 | **낮음** | 관리 도구 |

---

## 6. data-generator 지시사항

본 문서의 30행 `battle_memory_templates`는 페이즈 3 #2 또는 페이즈 4 #3 인라인 SQL 처리 권장. 페이즈 1 #3 `combat_report_templates` ~20행과 함께 처리하면 효율적.

- **대상 타입**: 별도 타입 스펙 불요 (M8a `combat_report_templates` 패턴 재사용)
- **대상 테이블**: `battle_memory_templates` 30행
- **생성 수량**: 30행 (§3.6.2 분포)
- **톤/세계관 가이드**:
  - 한국어 판타지 톤. "이 용병이 무엇을 겪었는가" 1인칭/3인칭 혼합 톤
  - emotional_apply: 페이즈 1 #3 감정 톤 그대로 (분노=폭주, 절망=무력, 슬픔=위축, 투지=영웅적)
  - hidden_stat_unlock lv1: "새로운 잠재력을 발견" 발견 톤
  - hidden_stat_unlock lv5: "끈기의 극치", "행운의 화신" 등 완성 톤
  - solo_great_success: 의뢰명을 포함한 자랑스러운 톤
  - unique_elite_first_kill: 엘리트명을 포함한 사냥꾼 톤
  - 1~2문장. 카드 내 1~2줄 분량
  - 변수: `{merc.name}`, `{quest.name}` (의뢰명), `{enemy.name}` (엘리트명), `{ally.name}` (인접 동료)
  - 고유명사 저작권 금칙
- **구조적 제약**:
  - 30행 분포: emotional_apply 12 + hidden_stat_unlock 10 + solo_great_success 3 + unique_elite_first_kill 5
  - source_event_match: emotional은 상태 효과 ID 그대로(`emotional_rage`/`emotional_despair`/`emotional_sorrow`/`emotional_determination`), hidden은 `hidden_{stat_id}_{lv}`, 그 외는 NULL (와일드카드)
  - weight 균등 1.0 또는 변형별 차별화 (페이즈 3 #2 결정)
- **수치 출처**: 본 문서는 수치 결정 항목 없음 (텍스트 데이터만)
- **특수 요구**:
  - hidden_stat_unlock lv1 5행은 "발견" 톤
  - hidden_stat_unlock lv5 5행은 "완성" 톤
  - achievement_granted / title_granted는 templateKey 사용 안 함 (lookup 렌더) — 본 30행에 포함 안 함
- **검증**:
  - entry_type CHECK 위반 없음
  - 30행 분포 정합
  - TemplateEngine 변수 컨텍스트 정합 (`{merc.name}` 등)

---

## 7. 오픈 질문

- **Q-1 (cap 30 정책 정확성)**: **결정**. 단순 FIFO를 사용한다. 큰 사건(위업·칭호·lv5)은 각 원본 시스템에서 영구 보존되므로 전투 기억에서는 별도 보호 슬롯을 만들지 않는다.
- **Q-2 (lv2~lv4 hidden_stat_unlock 기록)**: §3.2.3에서 lv1·lv5만 기록 결정. lv2/3/4도 기록하면 30 cap 빠르게 초과. **결정**: lv1+lv5만 (본 문서 명시).
- **Q-3 (achievement_granted mercSnapshot 매칭 정확도)**: §3.2.4 mercSnapshot.id가 mercenary.id와 일치할 때 본인 매칭. 단 죽은 mercenary의 mercSnapshot은 본인 mercenary 본체 없음. 본 문서 trailing은 mercenary 본체 lookup 실패 시 skip한다. **결정**: mercenary 본체 lookup 실패 시 skip한다.
- **Q-4 (unique_elite_first_kill 파견 전원 vs 1명)**: **결정**. 유니크 엘리트 첫 처치는 파견 전원에게 기록한다. 30 cap을 빠르게 채울 수 있으나, 유니크 엘리트는 빈도가 낮고 파티 전체의 공유 사건으로 보는 편이 UI 서사와 맞다.
- **Q-5 (templateKey 매칭 가중치)**: §3.6.2 변형별 weight. 페이즈 3 #2에서 균등 1.0 default 또는 변형별 차별화 결정. **권장**: 페이즈 3 #2 위임.
- **Q-6 (운영자 위업 삭제 시 stale 참조 정리)**: §4.3 fail-soft 자동 숨김. 다만 stale 데이터는 영구 누적. **권장**: 페이즈 4 #3에서 정리 정책 결정 (예: 7일 이상 stale 자동 제거).
- **Q-7 (MercenarySnapshot 보존 데이터의 메모리 부담)**: §4.3 6개월 플레이 ~1MB. 무시 가능. **결정**: 별도 cap 정책 없이 `hiddenStats`와 최근 30개 `battleMemories`를 영구 보존한다.
- **Q-8 (ChronicleScreen UI 통합 명세)**: §3.4.3 펼침 카드. 페이즈 4 #4 UI 명세에서 정밀화. **권장**: 페이즈 4 #4 결정.

---

## 8. 후속 작업

### 페이즈 1 진행 상태

본 문서는 M8.5 페이즈 1의 개인 용병 서사 축을 마무리한다. 페이즈 1 체크포인트:
- [x] #1 생활권 완성도 대시보드 컨셉
- [x] #2 간판 용병 솔로/소수정예 의뢰 컨셉
- [x] #3 전투 감정 반응 컨셉
- [x] #4 히든 스탯 해금 컨셉
- [x] #5 용병 전투 기억 컨셉
- [ ] #6 주간 기여도 랭킹 컨셉 (남음)

### 페이즈 2 입력 (예고)

본 문서는 페이즈 2에 입력으로 사용되지 않는다 (수치 결정 항목 없음). 페이즈 1 #4 영향 (히든 스탯 lv 임계값)이 페이즈 2 #4에서 결정되면 본 문서 entryType `hidden_stat_unlock` 발동 빈도도 자연 정합.

### 페이즈 3 #2 입력

- **페이즈 3 #2 "감정 반응 상태 효과 시드 4행"**과 통합 — 본 문서 30행 `battle_memory_templates` 시드를 함께 작성 (스코프 분리 시 페이즈 3 #6 별도 산출물 신설 검토)

### 페이즈 4 #3 명세 입력

본 문서 + 페이즈 1 #3·#4 + 페이즈 2 #3·#4 + 페이즈 3 #2 시드를 입력으로 spec-writer 호출:
- `BattleMemoryEntry` Hive 모델 (typeId 31, mercId 포함 6필드, 다음 신규 typeId 32)
- `Mercenary.battleMemories` HiveField 27
- `MercenarySnapshot.hiddenStats` HiveField 6 + `battleMemories` HiveField 7
- `CombatSimulationResult.battleMemoryEvents` HiveField 14
- `battle_memory_templates` 42번째 정적 테이블 + 30행 + optionalTables 등록
- `BattleMemoryTemplate` Freezed + StaticGameData 통합
- SyncService 등록
- `CombatSimulator.simulate` emotional_apply 후보 생성
- `QuestCompletionService` battleMemoryEvents 적용 + 4 entryType trailing
- `AchievementService.grant` / `TitleService._grantTitle` trailing
- 30 cap FIFO 정책
- lookup fail-soft 정책

### 페이즈 4 #4 UI 명세 입력

- `MercenaryDetailOverlay` 신규 `BattleMemorySection`
- `ChronicleScreen` memorial 카드 펼침 통합
- entryType별 아이콘·색상 매핑

### 밸런스 검토 필요

**아니오** (텍스트 데이터만, 수치 항목 없음).

### 벌크 데이터 생성 필요

**부분적**. 30행 templates는 페이즈 3 #2 인라인 권장. 페이즈 1 #3 `combat_report_templates` ~20행과 함께 작성.

### 구현 명세서 생성

페이즈 4 #3에서:
- 호출: `/spec-writer @Docs/content-design/[content]20260521_m8.5_battle_memory.md` (페이즈 1 #3·#4 + 페이즈 2 #3·#4 + 페이즈 3 #2 시드 모두 입력)
