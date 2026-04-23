# M2b 4-3 엘리트 퀘스트 생성 + 드랍 판정 개발 명세서

> 기획 문서: Docs/content-design/[content]20260420_elite_monster_catalog.md, Docs/content-design/[content]20260420_elite_drop_table.md
> 밸런스 문서: Docs/balance-design/[balance]20260420_elite_combat_power.md, Docs/balance-design/[balance]20260420_elite_drop_simulation.md
> 선행 명세: Docs/spec/[spec]20260423_m2b-4-2-elite-data-models.md
> 작성일: 2026-04-23

## 1. 개요

엘리트 몬스터 퀘스트를 생성하고 완료 시 드랍 판정으로 인벤토리에 아이템을 적재한다.
- **보통 엘리트** (31종): 리전 `environment_tags` ↔ `EliteMonsterData.environmentTags` 교집합 + `spawn_rate` 확률 판정
- **유니크 엘리트** (8종): `RegionState.triggeredDiscoveries`에 해당 discovery ID 존재 여부로 해금 + `spawn_rate` 확률 판정
- `ActiveQuest`에 `eliteId` 필드를 추가하여 일반 퀘스트와 구분
- 완료 시 `EliteLootService.rollDrops()`로 드랍 판정 → `InventoryRepository.addItem()` 적재

## 2. 요구사항

### 2.1 기능 요구사항

- [FR-1] `ActiveQuest`에 `String? eliteId` 필드(HiveField 20)를 추가한다.
  - `isElite` getter: `eliteId != null`
  - 일반 퀘스트는 `eliteId == null`

- [FR-2] `QuestGenerator.generateQuests()`에 엘리트 파라미터를 추가하고 엘리트 퀘스트를 생성한다.
  - 신규 파라미터: `List<EliteMonsterData> eliteMonsters`, `List<String> regionEnvironmentTags`, `Set<String> triggeredDiscoveries`
  - **보통 엘리트 후보 필터**: `!isUnique && environmentTags.any((t) => regionEnvironmentTags.contains(t))`
  - **유니크 엘리트 후보 필터**: `isUnique && triggeredDiscoveries.any((d) => d.endsWith(id))`
  - 각 후보에 대해 `random.nextDouble() < spawnRate` 독립 판정 → 통과 시 퀘스트 생성
  - 생성된 엘리트 퀘스트 속성:
    - `questName`: `'[엘리트] ${monster.name}'` (유니크는 `'[유니크] ${monster.name}'`)
    - `eliteId`: 해당 엘리트 ID
    - 소요시간: `baseDuration * monster.durationMultiplier` (baseDuration = 퀘스트 타입 기본값 또는 60분)
    - 난이도(difficulty): `monster.tier` 값 사용 (적 전투력 대리 지표, UI용)
    - `questPoolId`: `'elite_${monster.id}'` (더미 ID, FK 불필요)
    - `questTypeId`: `'raid'` (기본값, 퀘스트 완료 계산에 활용)
  - 엘리트 퀘스트는 기존 일반 퀘스트 슬롯과 별개로 최대 2개까지 추가 생성 (슬롯 상한 초과 허용)

- [FR-3] `EliteLootService`를 신규 작성한다.
  - 위치: `lib/features/quest/domain/elite_loot_service.dart`
  - `static EliteLootResult rollDrops({required String eliteId, required List<EliteLootEntry> lootEntries, required Random random})`
  - 드랍 판정: 각 `EliteLootEntry`에 대해 `random.nextDouble() < entry.dropRate` 독립 판정
  - `drop_type == 'gold'`: `goldMin + random.nextInt(goldMax - goldMin + 1)` → `bonusGold` 누적
  - `drop_type == 'essence'|'equipment'|'guild_item'`: `itemId` → `itemDrops` 리스트 추가
  - 반환: `EliteLootResult(bonusGold: int, itemDrops: List<String>)`

- [FR-4] `QuestCompletionResult`에 엘리트 드랍 결과 필드를 추가한다.
  - `final EliteLootResult? eliteLoot` — 엘리트 퀘스트인 경우에만 non-null

- [FR-5] `QuestListNotifier._completeQuest()`를 확장하여 엘리트 드랍을 처리한다.
  - `quest.isElite && result.resultType != QuestResult.criticalFailure` 조건에서:
    1. `EliteLootService.rollDrops()` 호출
    2. `eliteLootResult.itemDrops` 각각 `inventoryRepository.addItem(itemId: itemId, items: staticData.items)` 호출
    3. `eliteLootResult.bonusGold`는 `rewardGold`에 가산
    4. 드랍 결과를 `QuestCompletionResult.eliteLoot`에 담아 전달

- [FR-6] `QuestListNotifier.generateQuests()` / `fillQuests()`에서 엘리트 파라미터를 공급한다.
  - `staticDataProvider` 에서 `eliteMonsters`, `eliteLootEntries` 읽기
  - 현재 리전의 `Region.environmentTags` 읽기 (`staticData.regions.firstWhere(r.region == regionId)`)
  - 현재 리전의 `RegionState.triggeredDiscoveries` 읽기 (`regionStateRepository.getState(regionId)?.triggeredDiscoveries ?? []`)

### 2.2 데이터 요구사항

- `ActiveQuest` Hive 모델에 `@HiveField(20) String? eliteId` 필드 추가
- build_runner로 `quest_model.g.dart` 재생성 필요
- `QuestCompletionResult`는 일반 Dart 클래스 (Freezed 없음) → 필드 수동 추가

### 2.3 UI 요구사항

이 명세의 범위는 아님. Phase 4-4에서 처리.
단, `QuestCompletionResult.eliteLoot`는 Phase 4-4 UI가 활용할 수 있도록 올바른 데이터를 담아야 한다.

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/quest/domain/quest_model.dart` | `ActiveQuest`에 `@HiveField(20) String? eliteId` 추가 + `isElite` getter | FR-1 |
| `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` | `generateQuests()` 파라미터 3개 추가 + 엘리트 생성 로직 | FR-2 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | `QuestCompletionResult`에 `eliteLoot` 필드 추가 | FR-4 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | `_completeQuest()` 엘리트 드랍 처리 + `generateQuests()`/`fillQuests()` 파라미터 공급 | FR-5, FR-6 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/features/quest/domain/elite_loot_service.dart` | `EliteLootService` + `EliteLootResult` 값 객체 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/features/quest/domain/quest_model.g.dart` | `ActiveQuest` HiveField(20) 추가로 어댑터 재생성 필요 |

### 3.4 관련 시스템

- **인벤토리 시스템 (M2a)**: `InventoryRepository.addItem()` 호출로 드랍 아이템 적재
- **지역 조사 시스템**: `RegionState.triggeredDiscoveries`로 유니크 해금 여부 확인
- **SyncService**: `eliteMonsters`, `eliteLootEntries` 이미 allTables에 추가됨 (Phase 4-2 완료)
- **StaticGameData**: `eliteMonsters`, `eliteLootEntries` 필드 이미 추가됨 (Phase 4-2 완료)

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `QuestGenerator.generateQuests()`: `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` — 퀘스트 생성 로직 전체 패턴
- `QuestListNotifier._completeQuest()`: `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` — 완료 처리 + 인벤토리 적재는 이 메서드에서 수행
- `InventoryRepository.addItem()`: `band_of_mercenaries/lib/features/inventory/data/inventory_repository.dart` — 아이템 적재 시그니처
- `FactionTagResolver.resolve()`: `band_of_mercenaries/lib/features/quest/domain/` — 런타임 태그 부여 패턴 참조 (유사 설계)

### 4.2 주의사항

- `ActiveQuest`는 Hive 모델로 HiveField 번호 중복 금지. 현재 0~19 사용 중, `@HiveField(20)` 사용.
- `QuestCompletionResult`는 Freezed가 아닌 일반 Dart 클래스. 생성자에 `eliteLoot` 추가 시 모든 호출 위치(테스트 포함) 수정 필요. `null`을 기본값으로 처리.
- `QuestGenerator.generateQuests()`의 엘리트 파라미터는 기본값 제공 (`eliteMonsters = const []`, `regionEnvironmentTags = const []`, `triggeredDiscoveries = const {}`) → 기존 호출 위치 호환성 유지.
- `EliteLootService.rollDrops()`에서 `goldMax == goldMin`이면 `nextInt(1)` 호출 오류 방지: `goldMin == goldMax`이면 `goldMin` 반환.
- `_completeQuest`에서 인벤토리 적재는 `await` 비동기. `inventoryRepositoryProvider`는 `ref.read`로 접근.
- 유니크 해금 판정: `triggeredDiscoveries.any((d) => d.endsWith('_${monster.id}'))` — discovery ID 형식이 `rd_XXX_elite_{eliteId}`이므로 `endsWith` 활용.

### 4.3 엣지 케이스

- 엘리트 퀘스트가 대실패(criticalFailure)로 끝나면 드랍 없음 (일반 퀘스트와 동일 규칙).
- `eliteMonsters`가 비어 있는 경우 (staticData 미로드): 엘리트 퀘스트 생성 스킵.
- 동일 엘리트가 중복 출현할 수 있음 (확률 독립 판정). 중복 방지 로직 불필요 (기획서 §5.2).
- `Region.environmentTags`가 빈 리스트이면 보통 엘리트 후보 없음 → 정상 처리.

### 4.4 구현 힌트

- **진입점**: `QuestListNotifier.generateQuests()` / `fillQuests()` → `QuestGenerator.generateQuests()`
- **데이터 흐름**:
  1. `staticDataProvider` → `eliteMonsters`, `eliteLootEntries`, `regions`
  2. `regionStateRepositoryProvider` → `triggeredDiscoveries`
  3. `QuestGenerator.generateQuests()` → 엘리트 ActiveQuest 생성 (eliteId 포함)
  4. `QuestListNotifier._completeQuest()` → `EliteLootService.rollDrops()` → `inventoryRepository.addItem()`
- **참조 구현**:
  - `quest_provider.dart:_collectPassiveEffects()` — staticData + ref.read 패턴
  - `investigation_notifier.dart:_completeInvestigation()` — `regionStateRepository` 접근 패턴
- **확장 지점**:
  - `quest_generator.dart`: 기존 `List<ActiveQuest> result = []` 초기화 후 일반 퀘스트 추가 블록 뒤에 엘리트 퀘스트 생성 블록 추가
  - `quest_provider.dart:_completeQuest()`: 기존 결과 계산 직후, 인벤토리 장비 적재(기존) 이후에 엘리트 드랍 처리 블록 추가

## 5. 기획 확인 사항

- [Q-1] 엘리트 퀘스트 슬롯: 기존 5개 퀘스트 슬롯에 포함시킬지 별도 슬롯으로 처리할지 → 별도 추가 (최대 2개, 슬롯 상한 초과 허용). Phase 4-4 UI에서 구분 표시.
- [Q-2] 엘리트 대실패 드랍 없음 정책: balance-designer §3 "성공/실패 모두 드랍 가능" vs "대실패 제외" → **대실패 제외**로 결정 (이 명세에서 적용).
- [Q-3] `questTypeId`: 엘리트 전용 퀘스트 타입 ID 신설 여부 → Phase 4-3은 `'raid'`를 기본값으로 사용 (Phase 4-4에서 변경 가능).
