Skill used : implement-agent

# M2b 4-3 구현 계획 및 실행 결과

## 구현 계획 요약

엘리트 퀘스트 생성 + 드랍 판정 + 인벤토리 적재. 총 5개 태스크를 4단계로 실행.

**1단계 (병렬)**:
- TASK-1: `quest_model.dart` — `ActiveQuest.eliteId` HiveField(20) + `isElite` getter
- TASK-2: `elite_loot_service.dart` 신규 — `EliteLootResult` + `EliteLootService.rollDrops()`

**build_runner 실행** (TASK-1 완료 후)

**2단계 (병렬, TASK-1 완료 후)**:
- TASK-3: `quest_generator.dart` — `generateQuests()` 엘리트 파라미터 + 보통/유니크 생성 블록

**3단계 (TASK-2, TASK-3 완료 후)**:
- TASK-4: `quest_completion_service.dart` — `QuestCompletionResult.eliteLoot` + `calculate()` 드랍 롤 블록

**4단계 (TASK-4 완료 후)**:
- TASK-5: `quest_provider.dart` — `_applyCompletionResult()` 엘리트 처리 + 3곳 파라미터 공급

## 변경 파일 목록

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/quest/domain/quest_model.dart` | 수정 | `ActiveQuest`에 `@HiveField(20) String? eliteId` + `isElite` getter 추가 |
| `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` | 수정 | `generateQuests()`에 `eliteMonsters`/`regionEnvironmentTags`/`triggeredDiscoveries` 파라미터 + 엘리트 생성 블록 (최대 2개) |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | 수정 | `QuestCompletionResult.eliteLoot` 필드 추가 + `calculate()`에 `eliteLootEntries` 파라미터 + 드랍 롤 블록 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | 수정 | `_applyCompletionResult()`에 엘리트 드랍 처리 (bonusGold → addGold, itemDrops → addItem) + `generateQuests()`/`fillQuests()`/`_refreshExpiredQuests()` 3곳에 파라미터 공급 + 헬퍼 2개 추가 |
| `band_of_mercenaries/lib/features/quest/domain/elite_loot_service.dart` | 신규 | `EliteLootResult` 값 객체 + `EliteLootService.rollDrops()` static 메서드 |
| `band_of_mercenaries/lib/features/quest/domain/quest_model.g.dart` | 재생성 | build_runner — HiveField(20) 포함한 `ActiveQuestAdapter` 재생성 |
| `band_of_mercenaries/test/features/quest/domain/elite_loot_service_test.dart` | 신규 | `EliteLootService.rollDrops()` 9개 단위 테스트 |

## 실제 개발 사항

### ActiveQuest 모델 확장

`@HiveField(20) final String? eliteId;` 추가 (기존 0~19 사용 중, 20 비어있음).
`bool get isElite => eliteId != null;` getter 추가.

### EliteLootService 설계

- `EliteLootResult`: const 생성자, `bonusGold(int)` + `itemDrops(List<String>)` + `EliteLootResult.empty` 상수
- `rollDrops()`: 엘리트 ID로 필터링 → 독립 확률 판정 (`random.nextDouble() < entry.dropRate`)
  - `'gold'`: goldMin~goldMax 범위 롤 (goldMin == goldMax 시 min 반환, nextInt(0) 오류 방지)
  - `'essence'`, `'equipment'`, `'guild_item'`: itemId를 `entry.quantity`만큼 반복하여 itemDrops에 추가
- drop_type 실제 DB 값: `'gold'`, `'essence'`, `'equipment'`, `'guild_item'`

### QuestGenerator 엘리트 생성 로직

- **보통 엘리트**: `!isUnique && environmentTags.any(regionEnvironmentTags.contains)` + spawnRate 판정
- **유니크 엘리트**: `isUnique && triggeredDiscoveries.any((d) => d.endsWith('_${m.id}'))` + spawnRate 판정
  - discovery ID 형식 `rd_XXX_elite_{eliteId}` 기반 `endsWith` 매칭
- 최대 2개 별도 슬롯 (기존 일반 퀘스트 `count` 슬롯과 무관, 슬롯 상한 초과 허용 — 명세 §FR-2)
- 퀘스트명: `'[유니크] ${name}'` / `'[엘리트] ${name}'`

### 엘리트 드랍 처리 흐름

```
_completeQuest() → QuestCompletionService.calculate(eliteLootEntries)
  → EliteLootService.rollDrops() → EliteLootResult
  → QuestCompletionResult.eliteLoot
→ _applyCompletionResult()
  → eliteLoot.bonusGold > 0 → userDataProvider.notifier.addGold()
  → eliteLoot.itemDrops → inventoryRepository.addItem() 반복
```

### build_runner 결과

```
Succeeded after 7.9s with 3 outputs
```

### flutter analyze 결과

```
No issues found! (ran in 1.2s)
```

### 테스트 결과

```
quest domain: 127/127 All tests passed!
elite_loot_service_test.dart: 9/9 All tests passed!
```

## 검증 모드 및 결과

**검증 모드**: 풀 검증 (TASK 수 5개 ≥ 3)

### 1차 검증 결과: FAIL

| 에이전트 | 판정 | 주요 이슈 |
|---------|------|----------|
| verifier | PASS | 이슈 없음 |
| flutter-reviewer | BLOCK | HIGH 1건, MEDIUM 3건 |

**수정된 이슈**:
- [HIGH] EliteLootService 단위 테스트 누락 → `elite_loot_service_test.dart` 9개 케이스 작성
- [MEDIUM] `isElite && eliteId != null` 이중 검사 → `quest.isElite` 단독 조건으로 단순화
- [MEDIUM] `elite_loot_service.dart` 상대 경로 import → `package:` 절대 경로 변경

**스킵된 이슈**:
- [MEDIUM] QuestGenerator count 초과: 명세 §FR-2에 "슬롯 상한 초과 허용"으로 명시 → Phase 4-4 UI에서 처리
- [LOW] 빈 환경 태그 silent no-op: 의도된 동작

### 2차 검증 결과: PASS

| 에이전트 | 판정 |
|---------|------|
| flutter-reviewer | APPROVE |

## CLAUDE.md 금지사항 위반

없음.

## 다음 단계

M2b 4-4: 엘리트 UI — 파견 화면 보통·유니크 2계층 구분(아이콘·강조 색상), 퀘스트 완료 팝업 드랍 결과 리스트 (`QuestCompletionResult.eliteLoot` 활용).
