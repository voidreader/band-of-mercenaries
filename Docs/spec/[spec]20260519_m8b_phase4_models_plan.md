# M8b 페이즈 4 #2 — CombatSimulator 의존 freezed/Hive 모델 구현 plan

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260519_m8b_phase4_models.md`
> 작성일: 2026-05-19
> 마일스톤: M8b 페이즈 4 #2 (모델 + 정적 데이터 통합)

## 1. 수립한 구현 계획과 실제 개발 사항

### 1.1 PHASE 1 통합 계획 (planner 결과 요약)

8개 TASK로 분해, 순차 격리 모드 적용:

| # | TASK | 복잡도 | 모델 |
|---|------|--------|------|
| 1 | 정적 카탈로그 enum 7 + freezed 모델 3 | integration | sonnet |
| 2 | 시뮬레이션 영속 Hive 모델 6 + Hive enum 3 (typeId 22~30) | integration | sonnet |
| 3 | CombatReport HiveField 8~14 확장 | mechanical | haiku |
| 4 | StaticGameData 3 컬렉션 + staticDataProvider 로딩 | mechanical | haiku |
| 5 | SyncService allTables + optionalTables 3 항목 | mechanical | haiku |
| 6 | HiveInitializer 어댑터 9개 등록 | mechanical | haiku |
| 7 | Supabase 마이그레이션 4건 + data_versions 갱신 | integration | sonnet |
| 8 | build_runner 실행 (14 파일 자동 생성) | mechanical | haiku |

실행 순서(의존성):
- TASK-2 (BehaviorPattern enum 정의) → TASK-1 (EnemyArchetype에서 BehaviorPattern import)
- TASK-1·TASK-2·TASK-3 완료 → TASK-8 build_runner
- TASK-8 후 → TASK-6 (어댑터 등록은 `.g.dart` 클래스 의존)
- TASK-4·TASK-5는 의존 없이 진행
- TASK-7 Supabase 마이그레이션은 코드 무관, 마지막 단계

### 1.2 실제 개발 결과

PHASE 2의 8개 TASK 모두 PASS. PHASE 2.5 빌드 게이트에서 테스트 6 파일의 `StaticGameData(...)` 호출 누락이 발견되어 dart-build-resolver가 외과적 수정. PHASE 3 final integration APPROVE.

## 2. 변경 파일 목록

### 2.1 신규 생성 파일 (11 + 자동 생성 14)

#### 정적 카탈로그 (그룹 A, Hive typeId 미할당)
| 파일 경로 | 유형 | 설명 |
|-----------|------|------|
| `band_of_mercenaries/lib/core/models/combat_enums.dart` | 신규 | enum 7 (ApplyMethod/StackPolicy/ActionCost/TriggerKind/TargetingKind/DispelKind/EnemyKind), `@JsonValue` 매핑 (`extraAction` camelCase 보존, `debuff+dot` 특수문자 보존) |
| `band_of_mercenaries/lib/core/models/combat_skill.dart` | 신규 | freezed 23 필드 |
| `band_of_mercenaries/lib/core/models/combat_status_effect.dart` | 신규 | freezed 9 필드 (`kind`는 String, Q-3) |
| `band_of_mercenaries/lib/core/models/enemy_archetype.dart` | 신규 | freezed 20 필드, `BehaviorPattern` 이중 어노테이션 공유 |

#### 시뮬레이션 영속 (그룹 B, Hive typeId 22~30)
| 파일 경로 | typeId | 필드 수 |
|-----------|--------|--------|
| `band_of_mercenaries/lib/features/quest/domain/combat_enums_hive.dart` | 28, 29, 30 | CombatExitCondition(6) / BehaviorPattern(6) / PositionRow(3) |
| `band_of_mercenaries/lib/features/quest/domain/combat_simulation_result.dart` | 22 | 11 |
| `band_of_mercenaries/lib/features/quest/domain/combat_turn.dart` | 23 | 5 |
| `band_of_mercenaries/lib/features/quest/domain/combat_action.dart` | 24 | 17 |
| `band_of_mercenaries/lib/features/quest/domain/status_effect_event.dart` | 25 | 10 |
| `band_of_mercenaries/lib/features/quest/domain/combatant_snapshot.dart` | 26 | 15 |
| `band_of_mercenaries/lib/features/quest/domain/enemy_snapshot.dart` | 27 | 21 |

#### 자동 생성 14 (build_runner)
- `combat_skill.freezed.dart`/`.g.dart`
- `combat_status_effect.freezed.dart`/`.g.dart`
- `enemy_archetype.freezed.dart`/`.g.dart`
- `combat_enums_hive.g.dart`
- `combat_simulation_result.g.dart`
- `combat_turn.g.dart`
- `combat_action.g.dart`
- `status_effect_event.g.dart`
- `combatant_snapshot.g.dart`
- `enemy_snapshot.g.dart`
- `combat_report_model.g.dart` (기존 재생성)

### 2.2 수정 파일 (4 + 테스트 6)

| 파일 경로 | 변경 내용 |
|-----------|----------|
| `band_of_mercenaries/lib/features/quest/domain/combat_report_model.dart` | HiveField 8~14 신규 7 필드 (schemaVersion/combatantSnapshots/turns/exitCondition/objectiveProgress/enemySnapshots/statusEffectHistory), 모두 nullable로 M8a 호환 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | combatSkills/combatStatusEffects/enemyArchetypes 3 컬렉션 + loadFromCache 호출 3개 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | allTables 40 (37→40), optionalTables 9 (6→9) |
| `band_of_mercenaries/lib/core/data/hive_initializer.dart` | 어댑터 9개 등록 (enum 28~30 선등록 → 클래스 22~27) |

테스트 6 (PHASE 2.5 dart-build-resolver 자동 수정 — `StaticGameData(...)` 호출에 신규 3 인자 `const []` 추가):
- `test/features/crafting/domain/crafting_service_test.dart`
- `test/features/inventory/view/inventory_screen_test.dart`
- `test/features/quest/domain/combat_report_service_test.dart`
- `test/features/quest/domain/quest_completion_service_test.dart`
- `test/features/quest/domain/quest_narrative_render_test.dart`
- `test/features/quest/domain/special_flag_processor_test.dart`

### 2.3 Supabase 마이그레이션 (4건 + data_versions)

| 마이그레이션 명 | 적용 결과 |
|---|---|
| `m8b_phase4_combat_status_effects` | CREATE TABLE + 10행 INSERT |
| `m8b_phase4_combat_skills` | CREATE TABLE + 16행 INSERT (`status_effect_id` FK) |
| `m8b_phase4_enemies` | CREATE TABLE + 26행 INSERT (`elite_monster_id` FK) |
| `m8b_phase4_combat_report_templates` | scope CHECK 확장(+combat_skill) + 85행 INSERT |
| `data_versions` upsert | 4행 갱신 (combat_skills/combat_status_effects/enemies/combat_report_templates) |

신규 마이그레이션 파일 (사용자 검토용, `Docs/content-data/migrations/`):
- `m8b_phase4_combat_status_effects.sql`
- `m8b_phase4_combat_skills.sql`
- `m8b_phase4_enemies.sql`
- `m8b_phase4_combat_report_templates.sql`
- `m8b_phase4_data_versions.sql`

### 2.4 검증 결과
- 행수: status_effects 10 / skills 16 / enemies 26 / templates `combat_skill` 23 / templates 총 181
- `enemy_keyword_unmatched` 3건 (`goblin_raid_party`/`imp_swarm`/`lich_undead_legion`) — **expected**: 명세 §부록 A에 따라 페이즈 2 #2 §11.3 신규 5 키워드 후보로, 페이즈 3 #4 위임

## 3. 실행 모드 / 검증 모드 / 결과 요약

### 3.1 실행 모드
- **순차 격리 모드** (TASK 수 ≥ 5)
- 8개 TASK 모두 continuous execution
- coder → 미니 verifier → 미니 flutter-reviewer 사이클 (TASK-7은 외부 DB라 main 직접 검증)

### 3.2 검증 모드
- **PHASE 3-C 순차 격리 final integration sanity check**
- main 직접 통합 점검 + flutter-reviewer 1회 호출

### 3.3 결과 요약

| TASK | coder | verifier | flutter-reviewer | 비고 |
|------|-------|----------|------------------|------|
| TASK-2 | PASS | PASS | APPROVE | — |
| TASK-1 | PASS | PASS | APPROVE | BehaviorPattern import TASK-2 의존 |
| TASK-3 | PASS | PASS | APPROVE | M8a 호환 |
| TASK-5 | PASS | PASS | APPROVE | — |
| TASK-4 | PASS | PASS | APPROVE | — |
| TASK-8 | PASS | (코드 생성, 검증 생략) | (생략) | 14 파일 12.4초 |
| TASK-6 | PASS | PASS | APPROVE | — |
| TASK-7 | PASS | (외부 DB, main 직접 검증) | (생략) | 마이그레이션 4건 + data_versions |
| PHASE 2.5 | dart-build-resolver SUCCESS | — | — | 테스트 6 파일 외과적 수정 |
| PHASE 3-C | — | (생략, 통합 sanity) | APPROVE | task 간 통합 검증 6 포인트 |

전체 verifier PASS 6회 / flutter-reviewer APPROVE 6회 / FAIL 0회 / 재시도 0회.

이슈 수정 횟수: 0 (모든 task가 1회에 통과).

## 4. build_runner 재실행 필요 파일

본 구현에서 TASK-8 시점에 이미 build_runner 1회 실행 완료. 자동 생성 14 파일 모두 존재:

- `lib/core/models/combat_skill.freezed.dart` / `.g.dart`
- `lib/core/models/combat_status_effect.freezed.dart` / `.g.dart`
- `lib/core/models/enemy_archetype.freezed.dart` / `.g.dart`
- `lib/features/quest/domain/combat_enums_hive.g.dart`
- `lib/features/quest/domain/combat_simulation_result.g.dart`
- `lib/features/quest/domain/combat_turn.g.dart`
- `lib/features/quest/domain/combat_action.g.dart`
- `lib/features/quest/domain/status_effect_event.g.dart`
- `lib/features/quest/domain/combatant_snapshot.g.dart`
- `lib/features/quest/domain/enemy_snapshot.g.dart`
- `lib/features/quest/domain/combat_report_model.g.dart` (재생성)

`flutter analyze` 최종: 0 issues found.

## 5. 결정 사항 (명세서 Q-1 ~ Q-8 정합)

- **Q-1**: 일반 Hive 클래스 채택 (freezed 미사용, `CombatReport` 패턴 일관)
- **Q-2**: 3 신규 테이블 모두 `optionalTables` → fail-soft (페이즈 4 #1 [FR-20] 정합)
- **Q-3**: `CombatStatusEffect.kind`는 String 유지
- **Q-4**: `BehaviorPattern` typeId 29 (그룹 B와 함께)
- **Q-5**: `CombatReport.schemaVersion == null` ↔ M8a / `== 1 && turns != null` ↔ M8b
- **Q-6**: Supabase 마이그레이션 본 명세 구현 단계에서 적용 (직접 apply_migration MCP 호출)
- **Q-7**: `combat_report_templates` 85행 INSERT 본 명세 포함
- **Q-8**: 페이즈 4 #1 CombatSimulator 자동 컴파일 가능 (의존 모델 19종 + StaticGameData 3 컬렉션 매핑 완료)

## 6. CLAUDE.md 금지사항 위반

위반 없음.

## 7. 후속 단계

본 명세 구현이 완료되어 다음 단계가 자연스럽게 이어진다:

1. **페이즈 4 #1 (CombatSimulator) 구현**: `/implement-agent @Docs/spec/[spec]20260519_m8b_combat_simulator.md`
2. 페이즈 4 #3 (QuestCompletionService 통합)
3. 페이즈 4 #4 (UI)
4. 페이즈 4 #5 (검증·테스트)

## 8. 부록: typeId 점유 현황 갱신 (CLAUDE.md 반영 필요)

신규 typeId 22~30 점유. CLAUDE.md의 typeId 표 업데이트 권장:
- 22: CombatSimulationResult
- 23: CombatTurn
- 24: CombatAction
- 25: StatusEffectEvent
- 26: CombatantSnapshot
- 27: EnemySnapshot
- 28: CombatExitCondition
- 29: BehaviorPattern
- 30: PositionRow
