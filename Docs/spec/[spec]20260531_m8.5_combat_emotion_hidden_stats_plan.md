# M8.5 페이즈 4 #3 구현 계획·결과 문서

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260531_m8.5_combat_emotion_hidden_stats.md`
> 구현일: 2026-05-31
> 마일스톤: M8.5 페이즈 4 #3 — 전투 시뮬레이터 감정 반응·히든 스탯·전투 기억 hook

## 1. 개요

M8b `CombatSimulator` 결과 위에 세 겹의 재미 가시화 레이어를 추가했다. (1) 위기 사건을 4 감정 반응(분노·절망·슬픔·투지)으로 번역, (2) 사건 누적으로 5 히든 스탯(불굴·투지·운·공포 저항·전장 감각) 점진 해금, (3) 의미 있는 사건을 용병 개별 전투 기억으로 영구 보존. 데이터 모델·정적 데이터 동기화·시뮬레이터 hook·완료 trailing·히든 스탯 lv1 해금 다이얼로그까지 구현. 용병 상세 화면 UI(HiddenStatsSection/BattleMemorySection/ChronicleScreen)는 페이즈 4 #4로 분리.

## 2. 실행/검증 모드

- **실행 모드**: 순차 격리 모드(TASK 25개 ≥ 5). 의존 순서대로 진행하되 독립 파일은 동일 의존 레벨에서 병렬 호출.
- **검증 모드**: 시뮬레이터 핵심 TASK(14·15)와 완료 trailing(21)은 개별 미니 사이클(verifier → flutter-reviewer), 5단계 통합 작업은 풀 검증(verifier + flutter-reviewer 병렬). 모델/상수 정의(1~7·11·12·16)는 build_runner 게이트(TASK-8) + 전체 통합 게이트로 검증.
- **빌드 게이트**: TASK-8(build_runner 20 outputs 생성) + 최종 통합(analyze error 0 / test 762 PASS). switch 비망라 에러 1건은 dart-build-resolver로 외과 수정.

### 검증 결과 요약

| 검증 단계 | 결과 |
|----------|------|
| TASK-14 (히든 스탯 hook) | verifier FAIL(카운터 키 컨벤션) → 1회 수정 → PASS / flutter-reviewer APPROVE |
| TASK-15 (감정 trigger) | verifier PASS / flutter-reviewer APPROVE |
| 5단계 (17·19·20c·22·23) | verifier PASS / flutter-reviewer APPROVE(with warnings, medium 3건 보강) |
| TASK-20d·21 (완료 trailing) | verifier PASS / flutter-reviewer APPROVE(with warnings, medium 1·low 1 보강) |
| 최종 통합 | flutter analyze error 0 / flutter test 762 PASS |

### 수정된 주요 이슈

- **[verifier, TASK-14]** `hiddenStatEvents` 카운터 키가 스탯 ID(`fortitude`)로 돼 있어 명세 `{statId}_event_count` 컨벤션과 불일치 → `HiddenStatBonusResolver`에 카운터 상수 5개 추가 + 호출 8개 교체.
- **[flutter-reviewer, 5단계]** 보고서 감정 effectId 정렬 tie-breaker 누락(결정성) → effectId 2차 키 추가. fallback debug 로그 추가. merc.save() state 재동기화 주석 명시.
- **[flutter-reviewer, TASK-21]** `getAll()` 반복 스캔 + save 중복 → byId 인덱싱 + dirty 단일 save 패스. 효과 요약 raw key 노출 → description 통일.

## 3. 변경 파일 목록

### 신규 생성 (7 + SQL 산출물 1)

| 파일 | 역할 |
|------|------|
| `lib/features/mercenary/domain/battle_memory_entry.dart` | BattleMemoryEntry Hive 모델 typeId 31 |
| `lib/core/models/hidden_stat_data.dart` | HiddenStatData freezed 정적 모델 |
| `lib/core/models/battle_memory_template.dart` | BattleMemoryTemplate freezed 정적 모델 |
| `lib/features/quest/domain/emotional_reaction_config.dart` | EmotionalReactionConfig + TraitEmotionalKeywords |
| `lib/features/quest/domain/hidden_stat_bonus_resolver.dart` | HiddenStatBonusResolver(hook 가산·카운터 상수·computeLevel) |
| `lib/features/mercenary/domain/hidden_stat_unlocked_provider.dart` | hiddenStatUnlockedProvider + HiddenStatUnlockEvent |
| `lib/features/mercenary/view/hidden_stat_unlocked_dialog.dart` | HiddenStatUnlockedDialog 위젯 |
| `Docs/content-data/[data]20260531_m8.5_combat_emotion_hidden_stats_sql.md` | Supabase SQL 마이그레이션 산출물(4 블록 59행) |

### 수정

| 파일 | 변경 |
|------|------|
| `lib/features/mercenary/domain/mercenary_model.dart` | HiveField 26 hiddenStats / 27 battleMemories + addBattleMemory(30 cap FIFO) |
| `lib/features/achievement/domain/mercenary_snapshot_model.dart` | HiveField 6·7 + fromMercenary 동결 |
| `lib/features/quest/domain/combat_simulation_result.dart` | HiveField 13 hiddenStatEvents / 14 battleMemoryEvents |
| `lib/core/domain/activity_log_model.dart` | ActivityLogType 41 hiddenStatUnlocked / 42 hiddenStatLevelUp |
| `lib/features/quest/domain/combat_simulator.dart` | _Combatant.hiddenStats / hook 가산 8개 / 감정 trigger 4종·flush / 투지 death_resist / hiddenStatEvents·battleMemoryEvents |
| `lib/features/quest/domain/combat_simulator_constants.dart` | seedKeyEmotion / seedKeySorrowSkip |
| `lib/features/quest/domain/quest_provider.dart` | _applyHiddenStatAndBattleMemoryTrailing(카운터·lv·battleMemory·lv1 enqueue) / 운 drop 적용 / 유니크 엘리트 memory |
| `lib/features/quest/domain/quest_completion_service.dart` | hiddenStat PassiveBonus 주입(fortitude 개인·grit 최고1명) / itemDropBonus 노출 |
| `lib/features/quest/domain/combat_report_service.dart` | scope='emotional' 감정 장면(최대 3줄·우선순위·fail-soft·Q-1 잠정 TODO) |
| `lib/core/domain/passive_bonus_service.dart` | collect() hiddenStatEffects 인자 |
| `lib/features/achievement/domain/achievement_service.dart` (+ provider) | grant battleMemory trailing + getMercenary/updateMercenary 콜백 |
| `lib/features/title/domain/title_service.dart` | _grantTitle battleMemory trailing |
| `lib/core/data/sync_service.dart` | allTables/optionalTables에 hidden_stats / battle_memory_templates |
| `lib/core/providers/static_data_provider.dart` | StaticGameData hiddenStats / battleMemoryTemplates 필드·로더 |
| `lib/core/theme/app_theme.dart` | hiddenStatAccent(0xFF7E57C2) |
| `lib/core/providers/dialog_queue_provider.dart` | DialogTypeRegistry.hiddenStatUnlocked |
| `lib/app.dart` | hiddenStatUnlockedProvider ref.listen + enqueue |
| `lib/core/data/hive_initializer.dart` | BattleMemoryEntryAdapter(typeId 31) 등록 |
| `lib/features/home/view/home_screen.dart` | ActivityLogType switch 신규 2케이스(빌드 게이트 외과 수정) |

### 테스트 (신규 케이스 추가)

| 파일 | 신규 케이스 |
|------|------------|
| `test/features/quest/domain/combat_simulator_determinism_test.dart` | emotional 결정성 8 |
| `test/features/quest/domain/combat_simulator_test.dart` | 1명1감정 / DoT 카운터 2 |
| `test/features/quest/domain/combat_simulator_death_resistance_test.dart` | 불굴 clamp / 투지 cap 2 |
| `test/features/quest/domain/combat_report_service_test.dart` | scope='emotional' 5 |
| `test/features/quest/domain/quest_completion_service_test.dart` | computeLevel·luck·grit 16 |
| `test/features/quest/domain/quest_completion_side_effects_test.dart` | achievement/title memory fail-soft 8 |
| `test/core/domain/passive_bonus_service_test.dart` | hiddenStatEffects 상한 공유 9 |
| `test/features/mercenary/domain/mercenary_model_test.dart` | 빈 필드 초기화·30 cap FIFO 13 |
| (fixture 갱신) 9개 test 파일 | StaticGameData hiddenStats/battleMemoryTemplates const [] |

## 4. build_runner 재실행 필요 파일

TASK-8에서 일괄 생성 완료. 명세 구현 시 재생성된 파일:
- `mercenary_model.g.dart` / `mercenary_snapshot_model.g.dart` / `combat_simulation_result.g.dart` / `activity_log_model.g.dart`
- `battle_memory_entry.g.dart` (신규 Adapter)
- `hidden_stat_data.freezed.dart`·`.g.dart` / `battle_memory_template.freezed.dart`·`.g.dart`

## 5. 미적용·후속 사항

- **Supabase SQL 미적용**: 사용자 결정(코드 먼저, SQL은 산출물만)에 따라 `[data]20260531_m8.5_combat_emotion_hidden_stats_sql.md`만 작성. `hidden_stats`/`battle_memory_templates`는 `optionalTables`라 빈 캐시 fail-soft로 코드·테스트는 정상 동작. 실제 적용은 별도 승인.
- **Q-1 (보고서 emotion 매칭 컬럼)**: `combat_report_service.dart`에 `// TODO(Q-1)` 잠정 매칭(tags_json.emotion/effect_id) + 전풀 fallback. SQL 적용 단계에서 `combat_report_templates` 실제 스키마(tags_json 구조) SELECT 확인 후 정합 필요.
- **Q-2 (scope CHECK 전체 목록)**: SQL 산출물에 경고 포함. 적용 전 `pg_get_constraintdef`로 현재 CHECK 확인 후 전체 재선언.
- **페이즈 4 #4 위임**: 용병 상세 `HiddenStatsSection`/`BattleMemorySection`, `ChronicleScreen` memorial 펼침 UI.

## 6. CLAUDE.md 준수

- 금지사항 위반 없음. `CombatSimulator` 순수성 유지(Mercenary/Hive 직접 변경 금지 — 결과 객체 반환), 결정성(`stableSeed32` + 신규 도메인 키, `Math.random()`/`hashCode` 미사용), 신규 Hive typeId 1개(31)만, 신규 PassiveEffect 타입 0개, 모든 trailing fail-soft. ActivityLogType 번호는 코드 실측 기반 41/42로 정정(기획서 40/41은 stale).
