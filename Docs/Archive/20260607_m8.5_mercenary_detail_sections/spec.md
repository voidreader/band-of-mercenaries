# 용병 상세 화면 전투 기억·히든 스탯·개인 숙련도 섹션 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260521_m8.5_battle_memory.md` (M8.5 페이즈 1 #5 — 전투 기억, §3.5 표시 정책 / §3.4.3 ChronicleScreen 통합)
> - `Docs/content-design/[content]20260521_m8.5_hidden_stats.md` (M8.5 페이즈 1 #4 — 히든 스탯, §3.5 표시 정책)
> - `Docs/content-design/[content]20260521_m8.5_flagship_solo_quests.md` (M8.5 페이즈 1 #2 — 솔로/소수정예 의뢰, §3.5 개인 숙련도)
> - `Docs/spec/[spec]20260531_m8.5_combat_emotion_hidden_stats.md` (M8.5 페이즈 4 #3 — 데이터/도메인 계층, 본 명세의 선행 구현)
> 작성일: 2026-06-07
> 마일스톤: M8.5 페이즈 4 #4
> 범위: **UI 표시 계층만**. 데이터 모델·도메인 hook·완료 trailing·다이얼로그는 #3(커밋 `288fc71`)에서 이미 구현 완료. 본 명세는 용병 상세 화면 3 신규 섹션 + 연대기 추모 카드 펼침 통합을 다룬다.

## 1. 개요

M8.5 #3이 전투 기억·히든 스탯·감정 반응의 데이터·도메인 계층을 완성했으나(`Mercenary.hiddenStats`/`battleMemories`, `BattleMemoryEntry`, `HiddenStatData`, `BattleMemoryTemplate`, `HiddenStatBonusResolver`), 용병 상세 화면에는 아직 노출되지 않는다. 본 명세는 (1) 히든 스탯을 lv1+만 진행도 바로 보여주는 `HiddenStatsSection`, (2) 용병 개별 사건 일지를 시간순으로 보여주는 `BattleMemorySection`, (3) 솔로/소수정예 완수 숙련을 카운터+칭호 진행도로 보여주는 `MasteryProgressSection`을 신규 추가하고, (4) `ChronicleScreen`의 추모 카드를 펼침형으로 확장해 사망/방출 용병의 동결된 히든 스탯과 전투 기억을 열람하게 한다.

핵심 설계 제약(기획 문서 정합):
- 신규 데이터 모델·Provider·Hive 필드 **추가 없음**. 본 명세는 순수 표시 계층이며 #3 산출물을 읽기만 한다.
- 화면 전환은 상태 기반(`setState` 펼침). `Navigator.push` 금지(CLAUDE.md).
- 위업·칭호 lookup 실패는 fail-soft 숨김(`SizedBox.shrink()`). 빈 캐시(`hidden_stats`/`battle_memory_templates` optionalTables)도 fail-soft.
- 기존 섹션 위젯(`TitlesSection`/`BehaviorStatsSection`) 시각 패턴을 재사용한다.

## 2. 요구사항

### 2.1 기능 요구사항

#### A. 히든 스탯 섹션

- **[FR-1] `HiddenStatsSection` 신규 위젯**
  - 입력: `Mercenary merc`(+ `WidgetRef`로 `staticDataProvider.hiddenStats` 조회).
  - 노출 규칙(기획 §3.5.1): lv0(미해금) 완전 숨김 — placeholder 없음. lv1+만 카드 렌더. lv5(max)는 "★ 최대 도달" 배지 + 진행도 바 100%.
  - lv 산출: `merc.hiddenStats[statId]`를 우선 신뢰하되, 표시 진행도(현재 카운트/다음 임계)는 `merc.stats['${counterKey}']` 현재값과 `HiddenStatData.levelThresholds`(`[1,3,7,15,30]`)로 계산한다. `HiddenStatBonusResolver.computeLevel(counter)`로 lv 재검증 가능(불일치 시 hiddenStats 값 우선).
  - 카드 구성: `icon_key` 기반 아이콘 + `name lv{n}` + 진행도 바(`현재카운트/다음임계`, lv5는 충만) + 효과 2~3줄(한국어 변환, FR-1a).
  - **전체 lv0(해금된 스탯 0개)이면 섹션 자체를 숨긴다**(`SizedBox.shrink()`). "히든 스탯 없음" placeholder를 만들지 않는다("히든"의 의미 보존, 기획 §3.5.1·레퍼런스 원칙).
  - `AppTheme.hiddenStatAccent`(`0xFF7E57C2`, #3에서 정의 완료) 사용.

- **[FR-1a] 히든 스탯 효과 한국어 변환**
  - `HiddenStatData.combatEffectsJson`/`passiveEffectsJson`/`postRewardEffectsJson`을 현재 lv 기준으로 산출해 한국어 라벨 줄로 변환한다(기획 §3.5.2 예시: `death_resistance +0.06`, `injury_recovery -15%`, `critical_rate +0.04`, `drop_bonus +4% (후처리)`).
  - 변환 키 매핑은 본 위젯 내부 정적 `Map<String,String>` 라벨 테이블로 처리(별도 도메인 서비스 불요). 미정의 키는 raw 키 + 수치 fallback.

#### B. 전투 기억 섹션

- **[FR-2] `BattleMemorySection` 신규 위젯**
  - 입력: `Mercenary merc`(+ `WidgetRef`). `merc.battleMemories`를 timestamp **desc**(최신 위)로 정렬해 카드 리스트 렌더.
  - 헤더: `📖 전투 기억 ({n}/30)`. cap 30 도달 시에도 동일 포맷("최근 30 기억" 자연 FIFO, 기획 §3.5.2).
  - 빈 상태(0개): "아직 기억이 없습니다. 이 용병이 의뢰를 수행하면 사건이 누적됩니다."(기획 §3.5.5).
  - 각 entry는 FR-3 렌더 정책에 따라 1장의 미니 카드로 표시. 카드 = entryType 아이콘(FR-7) + 상대 시간(FR-7a) + 본문 텍스트(또는 lookup 미니 카드).

- **[FR-3] entryType별 렌더 정책 (6종)**
  - **템플릿 렌더 4종**(`emotional_apply`/`hidden_stat_unlock`/`solo_great_success`/`unique_elite_first_kill`): `entry.templateKey` 또는 `entry.sourceEventId`로 `staticData.battleMemoryTemplates`에서 매칭 → `templateEngineProvider.render(template.template, ctx)`로 렌더. `entry.templateData`를 TemplateContext 변수로 주입(`{merc.name}`/`{quest.name}`/`{enemy.name}`/`{ally.name}`).
    - 매칭 규칙(기획 §3.6.1 + #3 spec): `entry_type` 일치 AND (`source_event_match == null`(와일드카드) OR `sourceEventId`가 `source_event_match`와 매칭). 다중 매칭 시 weight 가중 랜덤이 아니라 **결정적 선택**(전투 기억은 발생 시점 1회 고정이 자연스러우나, 본 명세는 표시 시점 렌더이므로 `entry.templateKey`가 있으면 그 키를 1순위로 사용하고, 없으면 매칭 풀 중 `id` asc 첫 행을 선택해 재방문 시 텍스트가 흔들리지 않게 한다).
    - 템플릿 미발견(빈 캐시 포함) → fallback 고정 문구(entryType별 1줄, FR-3a) 또는 `SizedBox.shrink()`(FR-3 결정 사항 Q-2).
  - **lookup 렌더 2종**:
    - `achievement_granted`: `sourceEventId`(`achievement:{templateId}`)에서 templateId 추출 → `bandAchievementsProvider`에서 `templateId` 일치 항목 lookup → 위업 미니 카드(★ 아이콘 + 위업명) + 탭 시 `ChronicleScreen` 점프(FR-8). lookup 실패 시 `SizedBox.shrink()`(기획 §3.3.2).
    - `title_granted`: `sourceEventId`(`title:{titleId}`)에서 titleId 추출 → `titlesProvider`(또는 `mercenaryTitlesProvider(merc.id)`)에서 lookup → 칭호 미니 카드(★ 아이콘 + 칭호명) + 탭 시 본 용병 칭호 섹션 강조(FR-8). lookup 실패 시 `SizedBox.shrink()`.

- **[FR-3a] 템플릿 fallback 문구**
  - 빈 캐시(배포 전)에서도 기록 자체는 보존되므로(`sourceEventId`), 템플릿 미발견 시 entryType별 최소 1줄 한국어 fallback을 표시한다(예: `emotional_apply`→"감정에 휩싸였다", `hidden_stat_unlock`→"새로운 잠재력이 깨어났다", `solo_great_success`→"단독 의뢰를 대성공으로 마쳤다", `unique_elite_first_kill`→"강대한 적을 쓰러뜨렸다"). 카드 자체를 숨기지 않는다(기록의 존재는 보여준다).

#### C. 개인 숙련도 섹션

- **[FR-4] `MasteryProgressSection` 신규 위젯**
  - 입력: `Mercenary merc`(+ `WidgetRef`로 `titlesProvider`·`mercenaryTitlesProvider(merc.id)` 조회).
  - 표시 데이터(기획 §3.5, 솔로 의뢰): 4 카운터 `solo_completion_count`/`solo_great_success_count`/`pair_completion_count`/`small_party_count`(전부 `merc.stats`, 미존재 시 0).
  - **칭호 진행도**: M8.5 전용 4 칭호(`title_lone_wolf`/`title_silver_pair`/`title_three_kings`/`title_unyielding_solo`, 모두 `hook_type='action_stat'`)에 대해, `merc`가 **미보유**한 칭호의 진행도를 `현재카운터/임계값` 진행도 바로 표시한다(예: "외로운 늑대 3/5"). **보유한 칭호는 TitlesSection이 이미 표시하므로 여기서는 ✓ 달성 배지만** 간단히 표기(중복 카드 금지).
    - 카운터/임계값 매핑: `TitleData.hookCondition`에서 추출(`TitleService`의 action_stat hook 파싱 경로 참조, FR-4a). 4 칭호 ID는 본 명세 상수로 고정.
  - **전 카운터 0 AND 전용 칭호 진행 0**이면 섹션 숨김(`SizedBox.shrink()`) — 솔로/소수정예 의뢰를 한 번도 안 한 용병에 노이즈 방지.
  - `AppTheme.namedAccent`(`0xFFE91E63`, 솔로/소수정예 = 지명 의뢰 계열) 강조색 사용.

- **[FR-4a] 전용 칭호 카운터/임계 추출**
  - `title_lone_wolf`→`solo_completion_count`/5, `title_silver_pair`→`pair_completion_count`/8, `title_three_kings`→`small_party_count`/10, `title_unyielding_solo`→`solo_great_success_count`/1.
  - 가능하면 `TitleData.hookCondition`(JSONB)에서 동적 추출하되, 스키마 키가 불확실하면(Q-3) 본 명세 상수 테이블 fallback. 정적 데이터 행이 없으면(미동기화) 해당 칭호 카드 skip.

#### D. 화면 통합

- **[FR-5] `MercenaryDetailOverlay` 섹션 통합**
  - 현재 순서(mercenary_detail_overlay.dart:180-204): 프로필 → 장비 → 트레잇 → 시너지 → **TitlesSection(193)** → **BehaviorStatsSection(195)** → 트레잇히스토리.
  - 신규 배치(기획 §3.5.1 "TitlesSection과 BehaviorStatsSection 사이" + 전투기억 §3.5.1 "HiddenStatsSection 다음"):
    - TitlesSection(칭호) → **MasteryProgressSection(개인 숙련도)** → **HiddenStatsSection(히든 스탯)** → **BattleMemorySection(전투 기억)** → BehaviorStatsSection(행동 지표) → 트레잇히스토리.
  - 각 신규 섹션은 자체적으로 빈/미해금 상태를 `SizedBox.shrink()`로 숨기므로, 사이 `SizedBox(height:16)` 간격은 섹션이 실제 렌더될 때만 시각적으로 의미를 갖도록 배치한다(빈 섹션 + 간격으로 인한 빈 공백 방지 — 각 섹션이 `shrink`면 간격도 함께 사라지도록 조건부 간격 또는 섹션 내부 패딩 처리).

- **[FR-6] `ChronicleScreen._MemorialCard` 펼침 통합**
  - 현재 단순 `ListTile`(chronicle_screen.dart:205-240) → 탭 시 펼침되는 카드로 확장(`BehaviorStatsSection`의 `_expanded` setState 패턴 재사용 → `_MemorialCard`를 `ConsumerStatefulWidget`으로 전환).
  - 접힘(default): 기존 표시 유지(추모 아이콘 + `{name} (T{tier} {jobName})` + causeLabel).
  - 펼침: `mercSnapshot.titleIds`(보유 칭호 칩) + `mercSnapshot.hiddenStats`(해금된 히든 스탯 lv 요약, lv1+) + `mercSnapshot.battleMemories`(전투 기억 리스트, BattleMemorySection 렌더 로직 재사용, 30개 전체)를 펼침 표시(기획 §3.4.3 목업).
  - `mercSnapshot == null`(구버전 추모 데이터) 또는 빈 List → 펼침 시 "기록 없음" 또는 펼침 비활성. 기존 memorial 카드 호환(빈 List default).

#### E. 공통 표시

- **[FR-7] entryType별 아이콘·색상 매핑**
  - 기획 §3.5.3 매핑을 본 명세 상수로 고정:

| entryType (세부) | 아이콘 | 색상 |
|------------------|--------|------|
| `emotional_apply` : `emotional_rage` | ⚡ | `AppTheme.dangerRed` |
| `emotional_apply` : `emotional_despair` | 🌑 | `AppTheme.memorialGray` |
| `emotional_apply` : `emotional_sorrow` | 💧 | 옅은 블루(본 명세 신규 상수 또는 기존 info 색) |
| `emotional_apply` : `emotional_determination` | ✨ | `AppTheme.chainGold` |
| `hidden_stat_unlock` | ✨ | `AppTheme.hiddenStatAccent` |
| `achievement_granted` | ★ | `AppTheme.chainGold` |
| `title_granted` | ★ | `AppTheme.chainGold` |
| `solo_great_success` | ⭐ | `AppTheme.namedAccent` |
| `unique_elite_first_kill` | 🔥 | `AppTheme.uniqueAccent`(코드 실명 `eliteUniqueAccent` = `0xFFC084FC`) |
  - `emotional_apply` 세부 구분은 `entry.sourceEventId`(`emotional_*`) 또는 `entry.templateData['emotion']`로 판별.

- **[FR-7a] 상대 시간 표시**
  - `entry.timestamp` → "방금 전"/"N분 전"/"어제"/"N일 전"/"N주 전" 상대 표기(M8a CombatReport 시간 패턴 정합). 절대 시각은 보조(툴팁/長press 생략 가능, 최소 상대 표기 필수).

- **[FR-8] 미니 카드 탭 점프**
  - `achievement_granted` 카드 탭 → `currentTabProvider`를 정보 탭(또는 ChronicleScreen 진입 경로)으로 전환 + ChronicleScreen 표시. 기존 ChronicleScreen 진입 동선 재사용(상태 기반).
  - `title_granted` 카드 탭 → 동일 용병 상세 화면 내 TitlesSection으로 스크롤/강조(`Scrollable.ensureVisible` 또는 일시 하이라이트). 구현 난이도가 높으면 **탭 무동작(정보 표시만)**으로 축소 가능(Q-4).

### 2.2 데이터 요구사항

**신규/수정 없음.** 본 명세는 #3에서 구현된 다음 데이터를 읽기만 한다:
- `Mercenary.hiddenStats`(HiveField 26, `Map<String,int>`) · `Mercenary.battleMemories`(HiveField 27, `List<BattleMemoryEntry>`) · `Mercenary.stats`(카운터).
- `BattleMemoryEntry`(typeId 31, 6필드).
- `MercenarySnapshot.hiddenStats`(HiveField 6) · `.battleMemories`(HiveField 7) · `.titleIds`(HiveField 5).
- `StaticGameData.hiddenStats`(`List<HiddenStatData>`) · `.battleMemoryTemplates`(`List<BattleMemoryTemplate>`).
- `HiddenStatBonusResolver.computeLevel` / `.thresholds`.
- `bandAchievementsProvider` · `titlesProvider` · `mercenaryTitlesProvider(family)` · `templateEngineProvider`.

### 2.3 UI 요구사항

목업 없이 텍스트 명세(사용자 결정 2026-06-07). 기획 §3.5(히든 스탯·전투 기억) ASCII 목업을 구현 참조로 사용.

- **화면 진입 조건**: `selectedMercenaryIdProvider`로 용병 상세 오버레이가 열릴 때 3 신규 섹션이 함께 렌더. ChronicleScreen 추모 카드는 정보 탭 연대기 화면에서 카드 탭 시 펼침.
- **위젯 계층**:
  - `HiddenStatsSection`: `ConsumerWidget` → `Container`(border) > `Column` > lv1+ 스탯 카드 N개(아이콘 + 진행도 `LinearProgressIndicator` 또는 커스텀 바 + 효과 줄).
  - `BattleMemorySection`: `ConsumerWidget` → `Container`(border) > `Column`(헤더 + 카드 리스트). 카드는 entryType별 `_MemoryCard`(아이콘 + 시간 + 본문/미니카드).
  - `MasteryProgressSection`: `ConsumerWidget` → `Container`(`namedAccent` border) > `Column`(카운터 요약 + 미획득 전용 칭호 진행도 바).
  - `ChronicleScreen._MemorialCard`: `ConsumerStatefulWidget`(`_expanded`) → `Card` > `Column`(`ListTile`(기존) + 펼침 영역).
- **상태 변수**: `_MemorialCard._expanded`(bool). 나머지 3 섹션은 항상 펼친 단순 표시(필요 시 BattleMemorySection에 자체 `_expanded` 추가 검토 — 30개 길이 부담 시, Q-5).
- **화면 전환**: 상태 기반 렌더링. `Navigator.push` 금지. 미니 카드 탭은 `currentTabProvider`/`selectedMercenaryIdProvider`/스크롤 제어로 처리.
- **연출**: 기존 섹션 톤 정합. 펼침은 `setState` 즉시 전환(`AnimatedSize` 선택). 신규 애니메이션 필수 아님.
- **반응형**: 기존 오버레이 `ConstrainedBox`/패딩 정합(별도 maxWidth 도입 불요 — 오버레이 컨테이너 상속).

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `lib/features/mercenary/view/mercenary_detail_overlay.dart` | TitlesSection(193) 다음에 MasteryProgressSection·HiddenStatsSection·BattleMemorySection 3개 + 간격 삽입(BehaviorStatsSection 직전) | FR-5 |
| `lib/features/achievement/view/chronicle_screen.dart` | `_MemorialCard`를 `ConsumerStatefulWidget`으로 전환 + 펼침 영역(titleIds/hiddenStats/battleMemories) | FR-6 |

> `behavior_stats_section.dart`는 **수정하지 않는다**(개인 숙련도를 독립 섹션으로 분리하므로 `_labelMap` 확장 불요). 솔로 4 카운터가 행동 지표 펼침 그리드에 라벨 없이 노출되는 것을 막으려면 향후 정리 가능하나 본 명세 범위 외(Q-6).

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `lib/features/mercenary/view/hidden_stats_section.dart` | `HiddenStatsSection`(FR-1, FR-1a) + 효과 한국어 라벨 상수 |
| `lib/features/mercenary/view/battle_memory_section.dart` | `BattleMemorySection`(FR-2) + `_MemoryCard` + entryType 아이콘/색상 상수(FR-7) + 상대 시간 helper(FR-7a) + 렌더 로직(FR-3·3a) |
| `lib/features/mercenary/view/mastery_progress_section.dart` | `MasteryProgressSection`(FR-4, FR-4a) + 전용 칭호 상수 테이블 |

> `BattleMemorySection`의 entry 렌더 로직(FR-3)은 `ChronicleScreen._MemorialCard` 펼침(FR-6)에서도 재사용한다. 공통 렌더는 `battle_memory_section.dart`에 `static`/공개 헬퍼(예: `BattleMemoryCard(entry: ...)`)로 노출해 chronicle_screen에서 import한다(중복 구현 금지).

### 3.3 코드 생성 필요 파일

없음(freezed/Hive 모델 변경 없음 — build_runner 불요).

### 3.4 관련 시스템

- **용병 상세 화면**: 3 신규 섹션 추가(읽기 전용).
- **연대기(ChronicleScreen)**: 추모 카드 펼침으로 동결 스냅샷 열람.
- **정적 데이터**: `hidden_stats`/`battle_memory_templates` optionalTables 읽기(빈 캐시 fail-soft).
- **위업·칭호**: lookup 렌더(읽기). 본체 변경 없음.
- **TemplateEngine**: 전투 기억 템플릿 렌더(기존 컨텍스트 재사용).

### 3.5 검증 요구사항

| 테스트 파일 | 필수 검증 |
|-------------|-----------|
| `test/features/mercenary/view/hidden_stats_section_test.dart`(신규) | lv0 스탯은 렌더되지 않고, 전 스탯 lv0이면 섹션이 `SizedBox.shrink()`된다. lv5는 "최대 도달" 배지 + 충만 바. 진행도 = 카운터/다음 임계. |
| `test/features/mercenary/view/battle_memory_section_test.dart`(신규) | timestamp desc 정렬. 빈 List → 빈 상태 문구. 30개 초과 입력은 없음(데이터 cap이 보장하나 31개 들어와도 desc 30개만 렌더하지 않고 전부 렌더 — cap은 데이터 책임). `achievement_granted` lookup 실패 시 해당 카드 `SizedBox.shrink()`, 본 흐름 미실패. 빈 템플릿 캐시 시 fallback 문구 표시(카드 유지). |
| `test/features/mercenary/view/mastery_progress_section_test.dart`(신규) | 보유 칭호는 ✓ 배지, 미보유는 진행도 바. 전 카운터 0 + 전용 칭호 진행 0이면 섹션 숨김. 카운터/임계 매핑 정확. |
| `test/features/achievement/view/chronicle_screen_test.dart`(기존 보강 또는 신규) | `_MemorialCard` 탭 시 펼침. `mercSnapshot.battleMemories` 빈 List(구버전) 호환. hiddenStats lv1+만 표시. |

> 위젯 테스트는 `ProviderScope`/`pumpWidget` + 페이크 staticData 주입 패턴(기존 `inventory_screen_test.dart` 등 참조). 빈 캐시·lookup 실패 fail-soft가 핵심 케이스.

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- 섹션 컨테이너(border + 헤더 + 빈 상태): `lib/features/title/view/titles_section.dart`(chainGold border 0.05 alpha 배경, 헤더 텍스트, 카드 리스트 또는 빈 상태 조건부). MasteryProgressSection/HiddenStatsSection 컨테이너 톤 참조.
- 펼침/접기 setState: `lib/features/mercenary/view/behavior_stats_section.dart:56-127`(`_expanded` + GestureDetector + 조건부 레이아웃). `_MemorialCard` 펼침에 동일 패턴.
- 섹션 조립: `lib/features/mercenary/view/mercenary_detail_overlay.dart:177-205`(Column + SizedBox(height:16) 간격).
- 칭호 카드/효과 요약: `titles_section.dart` `_TitleCard`(effectJson → "의뢰 보상 +30%" 한국어 변환). HiddenStatsSection 효과 줄 변환 참조.
- 위업 lookup·정렬: `lib/features/achievement/domain/achievement_provider.dart`(`bandAchievementsProvider`). `renderedAchievementProvider`(family) — 위업명 표시 캐싱.
- 칭호 lookup: `lib/features/title/domain/title_provider.dart`(`titlesProvider`/`mercenaryTitlesProvider`).
- TemplateEngine 렌더: `lib/core/providers/template_engine_provider.dart` + `lib/core/domain/template_engine.dart`(`render(template, TemplateContext)`). 전투 기억 템플릿 렌더.
- 추모 카드: `lib/features/achievement/view/chronicle_screen.dart:205-240`(`_MemorialCard`, mercSnapshot 사용).

### 4.2 주의사항

- **읽기 전용**: 본 명세는 어떤 Hive 객체도 변경하지 않는다. `merc`는 Provider에서 watch한 값을 표시만 한다.
- **fail-soft 우선**: lookup 실패(위업/칭호 stale), 빈 캐시(템플릿/히든스탯 미동기화), null mercSnapshot 모두 카드/섹션 숨김 또는 fallback. 예외로 화면이 깨지면 안 된다.
- **표시 텍스트 결정성**: 전투 기억 템플릿 다중 매칭 시 `Math.random()` 금지 — `entry.templateKey` 1순위, 없으면 `id` asc 첫 행(재방문 시 텍스트 고정, FR-3).
- **중복 표시 금지**: 보유 칭호는 TitlesSection이 담당. MasteryProgressSection은 미획득 진행도 + ✓ 배지만(FR-4). 전투 기억의 `title_granted`/`achievement_granted`는 "획득 사건의 일지"이므로 칭호/위업 본체 표시와 의미가 다름(중복 아님).
- **`Navigator.push` 금지**(CLAUDE.md). 미니 카드 점프는 상태 기반.
- **간격 처리**(FR-5): 숨겨진 섹션 + `SizedBox(height:16)`이 빈 공백을 만들지 않도록, 간격을 섹션 내부 상단 패딩으로 흡수하거나 `shrink` 시 간격도 제거되게 조건부 배치.

### 4.3 엣지 케이스

- 신규 모집 용병: hiddenStats `{}`, battleMemories `[]`, 솔로 카운터 0 → 3 섹션 모두 숨김(노이즈 0).
- 일부 스탯만 해금: HiddenStatsSection은 lv1+만, 나머지 숨김.
- 전투 기억 30 cap 초과: 데이터 계층 책임(#3 FIFO). UI는 받은 List 전부 desc 렌더.
- 위업/칭호 stale 참조: 카드 `SizedBox.shrink()`(기록은 sourceEventId로 보존되나 표시 불가 시 숨김).
- 빈 템플릿 캐시(배포 전): 템플릿 렌더 4종은 FR-3a fallback 문구, lookup 2종은 본체 있으면 정상.
- 구버전 추모 데이터(`mercSnapshot.battleMemories == []`, `hiddenStats == {}`): 펼침 시 "기록 없음" 또는 해당 영역 생략.
- `mercSnapshot == null`(아주 오래된 memorial): 펼침 비활성, 기존 접힘 표시 유지.

### 4.4 구현 힌트

- 진입점: `MercenaryDetailOverlay.build`(mercenary_detail_overlay.dart:171 Column) → 라인 193(TitlesSection) 직후에 3 섹션 삽입.
- 데이터 흐름(히든 스탯): `merc.hiddenStats` + `merc.stats['{counterKey}']` + `staticData.hiddenStats` → `HiddenStatsSection` 카드. lv는 `HiddenStatBonusResolver.computeLevel` 재검증.
- 데이터 흐름(전투 기억): `merc.battleMemories`(desc) → entryType 분기 → 4종: `staticData.battleMemoryTemplates` 매칭 + `templateEngineProvider.render` / 2종: `bandAchievementsProvider`·`titlesProvider` lookup.
- 데이터 흐름(숙련도): `merc.stats`(4 카운터) + `mercenaryTitlesProvider(merc.id)`(보유 여부) + `titlesProvider`(전용 4 칭호 정의/임계) → 진행도 바.
- 데이터 흐름(추모 펼침): `achievement.mercSnapshot.{titleIds, hiddenStats, battleMemories}` → 펼침 영역(BattleMemoryCard 재사용).
- 확장 지점: 전투 기억 카드 공통 렌더를 `battle_memory_section.dart`에 공개 위젯(`BattleMemoryCard`)으로 분리 → 용병 상세 + 추모 펼침 양쪽 재사용.
- 색상: `AppTheme.hiddenStatAccent`/`chainGold`/`namedAccent`/`memorialGray`/`dangerRed`/`eliteUniqueAccent` 기존 정의 사용. 슬픔(💧) 옅은 블루만 신규 상수 필요 시 본 위젯 내 `const Color` 로컬 정의(AppTheme 추가는 선택).

## 5. 기획 확인 사항

- **[Q-1] 개인 숙련도 섹션 형태** → **결정**: 독립 `MasteryProgressSection` 신설(state.md #4 권장 + M8.5 가시화 정신). 솔로/페어/삼인행 카운터 + 미획득 전용 칭호 진행도. 보유 칭호는 TitlesSection 중복 표시 금지(✓ 배지만). (사용자 2026-06-07 결정)
- **[Q-2] 템플릿 미발견 시 카드 처리** → 본 명세: FR-3a fallback 문구로 카드 유지(기록 존재 보존). `SizedBox.shrink()` 숨김이 더 낫다면 구현 시 조정. **권장**: fallback 유지.
- **[Q-3] 전용 칭호 카운터/임계 추출 경로** → `TitleData.hookCondition`(JSONB) 스키마 키가 불확실. `TitleService`의 action_stat hook 평가 코드에서 키 구조 확인 후 동적 추출, 불확실하면 FR-4a 상수 테이블 fallback. 구현 시 `title_service.dart` 실측.
- **[Q-4] `title_granted` 미니 카드 탭 동작** → Chronicleの`achievement_granted`는 화면 점프 명확. `title_granted`는 동일 화면 내 TitlesSection 스크롤/강조가 난이도 있음. **권장**: 1차는 탭 무동작(정보 표시만) 허용, 스크롤 강조는 폴리싱 시 추가.
- **[Q-5] BattleMemorySection 길이(최대 30개) 처리** → 30개 전부 세로 나열 시 길어짐. **권장**: 1차 전체 렌더(스크롤은 오버레이 SingleChildScrollView가 흡수). 부담 시 "최근 10개 + 더 보기" 접기 추가 검토.
- **[Q-6] `BehaviorStatsSection`에 솔로 4 카운터 라벨 미등록** → 현재 `_labelMap`에 없어 펼침 그리드 미표시(노출 안 됨). MasteryProgressSection이 전담하므로 **현 상태 유지**(라벨 추가 안 함). 행동 지표에서도 보고 싶으면 별도 요청 시 추가.
- **[Q-7] 추모 카드 펼침에서 전투 기억 탭 점프** → 사망 용병은 본체 없음 → `title_granted`/`achievement_granted` 탭 점프가 모호. **권장**: 추모 펼침 내 미니 카드는 탭 무동작(열람 전용).
