Skill used : implement-agent

# M2b 4-2 구현 계획 및 실행 결과

## 구현 계획 요약

엘리트 몬스터 시스템의 데이터 기반 구축. 총 8개 태스크를 2단계로 병렬 실행.

**1단계 (병렬)**:
- TASK-1: `elite_monsters` / `elite_loot_tables` DDL + `data_versions` INSERT SQL 마이그레이션 파일 생성
- TASK-2: `EliteMonsterData` Freezed 모델 신규 작성
- TASK-3: `EliteLootEntry` Freezed 모델 신규 작성
- TASK-4: `SyncService.allTables` 확장
- TASK-6: `InvestigationResult.unlockedEliteIds` 필드 추가

**빌드 러너 실행** (TASK-2, 3 완료 후)

**2단계 (병렬)**:
- TASK-7: `StaticGameData` 확장 + `staticDataProvider` loadFromCache 추가
- TASK-8: `InvestigationNotifier._completeInvestigation()` `elite` 분기 추가

## 변경 파일 목록

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `band_of_mercenaries/supabase/migrations/20260423_m2b_4_2_elite_tables.sql` | 신규 | `elite_monsters` / `elite_loot_tables` DDL + `data_versions` INSERT (BEGIN/COMMIT 트랜잭션, 멱등성 보장) |
| `band_of_mercenaries/lib/core/models/elite_monster_data.dart` | 신규 | `EliteMonsterData` Freezed + json_serializable 모델. `statWeight`는 `Map<String, double>` + `_statWeightFromJson` 커스텀 변환기 사용 (int/double 혼용 안전 처리) |
| `band_of_mercenaries/lib/core/models/elite_loot_entry.dart` | 신규 | `EliteLootEntry` Freezed + json_serializable 모델. `quantity @Default(1)` |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | 수정 | `allTables`에 `'elite_monsters'`(20번째), `'elite_loot_tables'`(21번째) 추가 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | 수정 | `StaticGameData`에 `eliteMonsters`, `eliteLootEntries` 필드 추가 + import + `loadFromCache` 호출 |
| `band_of_mercenaries/lib/features/investigation/domain/investigation_result.dart` | 수정 | `unlockedEliteIds: List<String>` 필드 추가 (기본값 `const []`) |
| `band_of_mercenaries/lib/features/investigation/domain/investigation_notifier.dart` | 수정 | `_completeInvestigation()`에 `discovery_type='elite'` 분기 추가 + `staticDataProvider` 중복 읽기 제거 (단일 `staticData` 변수로 통합) |
| `band_of_mercenaries/lib/core/models/elite_monster_data.freezed.dart` | 재생성 | build_runner |
| `band_of_mercenaries/lib/core/models/elite_monster_data.g.dart` | 재생성 | build_runner |
| `band_of_mercenaries/lib/core/models/elite_loot_entry.freezed.dart` | 재생성 | build_runner |
| `band_of_mercenaries/lib/core/models/elite_loot_entry.g.dart` | 재생성 | build_runner |
| `band_of_mercenaries/test/features/inventory/view/inventory_screen_test.dart` | 수정 | 빌드 게이트 — `StaticGameData` 생성자에 `eliteMonsters: const []`, `eliteLootEntries: const []` 추가 |
| `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` | 수정 | 빌드 게이트 — 동일 |

## 실제 개발 사항

### SQL 마이그레이션

- `elite_monsters` 테이블: 14컬럼 (id TEXT PK, name, description, is_unique BOOLEAN, type_family, tier INTEGER, power INTEGER, spawn_rate REAL, duration_multiplier REAL, environment_tags JSONB, stat_weight JSONB, fixed_region_environments JSONB nullable, lore TEXT nullable, title TEXT nullable)
- `elite_loot_tables` 테이블: 9컬럼 + FK 제약 2개 (`elite_id → elite_monsters.id`, `item_id → items.id`) + `CHECK (drop_rate BETWEEN 0.0 AND 1.0)` + `idx_elite_loot_tables_elite_id` 인덱스
- `data_versions` 양쪽 테이블 모두 `ON CONFLICT (table_name) DO NOTHING`으로 멱등성 보장

### Flutter 모델

**`EliteMonsterData` 핵심 설계 결정**:
- `statWeight`: `Map<String, dynamic>` 대신 `Map<String, double>` + `_statWeightFromJson` 커스텀 변환기 사용. Supabase JSONB가 정수/실수 혼용으로 내려올 때 `(v as num).toDouble()` 변환으로 runtime TypeError 방지.
- 어노테이션 순서: `@Default` → `@JsonKey` (프로젝트 컨벤션 준수)

### `InvestigationNotifier` elite 분기

`faction_clue` 분기 바로 아래 `else if (d.discoveryType == 'elite')` 블록 추가:
- `discoveryData['elite_id']` 파싱 → `unlockedEliteIds` 누적
- `discoveryData['reveal_text']` 우선, 없으면 `'엘리트 발견: ${d.description}'` 기본 메시지
- `ActivityLogType.discoveryFound` 활동 로그 기록
- `continue`로 기존 generic 로그 경로 스킵

### build_runner 결과

```
Succeeded after 7.1s with 6 outputs (1단계 실행)
Succeeded after ~3s with 3 outputs (수정 후 재실행)
```

### flutter analyze 결과

```
No issues found! (ran in 1.4s)
```

## 검증 모드 및 결과

**검증 모드**: 풀 검증 (TASK 수 8개 ≥ 3)

### 1차 검증 결과: FAIL

| 에이전트 | 판정 | 주요 이슈 |
|---------|------|----------|
| verifier | PASS | 이슈 없음 |
| flutter-reviewer | BLOCK | HIGH 2건, MEDIUM 1건 |

**수정된 이슈**:
- [HIGH-1] `statWeight` `Map<String, dynamic>` → `Map<String, double>` + `_statWeightFromJson` 추가
- [HIGH-2] `investigation_notifier.dart` `staticDataProvider` 삼중 중복 읽기 → 단일 `staticData` 변수 통합
- [MEDIUM-1] `elite_monster_data.dart` 어노테이션 순서 `@JsonKey→@Default` → `@Default→@JsonKey` 재배치

**스킵된 이슈**:
- [MEDIUM-2] `unlockedEliteIds` UI 렌더링: Phase 4-4에서 처리 예정 (명세서 §2.3)
- [LOW] `sync_service.dart` 광범위 예외 catch: 기존 코드 패턴 유지

### 2차 검증 결과: PASS

| 에이전트 | 판정 |
|---------|------|
| flutter-reviewer | APPROVE |

## CLAUDE.md 금지사항 위반

없음.

## 다음 단계

M2b 4-3: 엘리트 퀘스트 생성 + 드랍 판정 (`EliteLootService`, `ActiveQuest.isElite`, 인벤토리 시스템)

단, 선행 조건으로 `elite_monsters` 39행 + `elite_loot_tables` 209행 Supabase 데이터 INSERT가 필요하다 (data-generator 단계).
