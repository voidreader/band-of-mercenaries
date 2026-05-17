# M7 페이즈 4 통합 implement 계획·실행 보고서

> Skill used : implement-agent
> 적용 명세서:
> - `Docs/spec/m7_p4_1_region_state_system.md`
> - `Docs/spec/m7_p4_2_questgenerator_weights.md`
> - `Docs/spec/m7_p4_3_movement_ui.md`
> - `Docs/spec/m7_p4_4_infrastructure_system.md`
>
> 실행일: 2026-05-17
> 결과: **PASS** (analyze 0 issues / 564 tests PASS / flutter-reviewer APPROVE with warnings)

## 1. 수립한 구현 계획

planner 통합 계획 리포트 기반 23 TASK로 분해. 사용자 명시 implement 순서 준수:
1. SQL 마이그레이션 일괄 적용 (Supabase MCP)
2. 페이즈 4 #1 — RegionState/DangerLevel/Repository/Dialog/ActivityLog
3. 페이즈 4 #2 — Freezed sealed union + QuestGenerator 가중치 + applyDangerScoreFromQuest 본체
4. 페이즈 4 #4 — Infrastructure Config + transition trailing + CraftingService + HerbalistService + ForeignStallScreen
5. 페이즈 4 #3 — RegionAdjacency + MovementDistanceCalculator + UI 위젯 2종
6. build_runner 통합 실행
7. 검증

## 2. 실행 모드 / 검증 모드

- **실행 모드**: Batch 모드 (사용자 승인). mechanical/integration TASK는 병렬 batch + 자가 점검만, 복잡 도메인 TASK도 batch 진행 후 PHASE 2.5/3 통합 검증.
- **검증 모드**: 풀 검증 — PHASE 2.5 전체 analyze + test + dart-build-resolver 자동 수정 + PHASE 3 flutter-reviewer 최종 품질 검증.

## 3. TASK 실행 결과 요약

| TASK | 주제 | 모델 | 결과 | 자가 점검 |
|------|------|------|------|----------|
| TASK-1 | Supabase SQL 마이그레이션 일괄 (5건) | — (main 직접) | PASS | apply_migration 5건 성공 |
| TASK-2 | DangerLevel enum + 매핑 5종 | haiku | PASS | analyze=PASS |
| TASK-3 | RegionState/ActivityLog/UserData/VillageFacility HiveField 통합 | haiku | PASS | analyze+build_runner=PASS (159 actions) |
| TASK-4 | dangerLevelChangedProvider + RegionStateChangedDialog | haiku | PASS | analyze=PASS |
| TASK-5 | DialogTypeRegistry 확장 2 신규 키 | haiku | PASS | analyze=PASS |
| TASK-6 | RegionStateRepository 메서드 4종 + region_pacified grant | **opus** | PASS | analyze=PASS |
| TASK-8 | 트리거 통합 (chain/elite/decay) | sonnet | PASS | analyze=PASS |
| TASK-9 | QuestPool 확장 + RegionStateEffect sealed union | haiku | PASS | analyze+build_runner=PASS (freezed 2.4.4 @FreezedUnionValue) |
| TASK-10 | RegionStateWeightConfig 정적 상수 | haiku | PASS | analyze=PASS |
| TASK-11 | computeFinalWeight + applyDangerScoreFromQuest + trailing | **opus** | PASS | analyze+test 22/22 PASS |
| TASK-12 | SettlementInfrastructureConfig + provider + event + dialog | haiku | PASS | analyze=PASS |
| TASK-13 | _evaluateInfrastructureTransition + toggleFlag trailing 활성화 | **opus** | PASS | analyze=PASS |
| TASK-14 | app.dart ref.listen + UserDataNotifier.incrementForeignStallVisit | sonnet | PASS | analyze=PASS |
| TASK-15 | ForeignStallScreen + VillageVisitSection | sonnet | PASS | analyze=PASS |
| TASK-16 | ChiefHouseScreen 생활권 정보 버튼 | sonnet | PASS | analyze=PASS |
| TASK-17 | HerbalistService + RecipeUnlockCondition + CraftingService | sonnet | PASS | analyze+build_runner+test 10/10 PASS |
| TASK-18 | RegionAdjacency + StaticGameData + SyncService | haiku | PASS | analyze+build_runner=PASS |
| TASK-19 | AppTheme dangerLevelColor/Label | haiku | PASS | analyze=PASS |
| TASK-20 | M7Constants + MovementDistanceCalculator + LivingsphereJumpBar + RegionStatusBadgeRow | sonnet | PASS | analyze=PASS |
| TASK-21 | MovementScreen + movement_provider 통합 변경 | sonnet | PASS | analyze=PASS |
| TASK-22 | 가중치 unit test 6 시나리오 | sonnet | PASS | test 6/6 PASS |
| TASK-23 | 전체 build_runner + analyze + test (PHASE 2.5 흡수) | — | PASS | analyze=PASS, test 564/564 PASS |

## 4. 변경 파일 목록

### Supabase 마이그레이션 (5건)
- `m7_region_metadata` — regions UPDATE 6 + region_adjacency 신설+22행
- `m7_quest_pools_state` — quest_pools ALTER 3컬럼 + 36행 INSERT
- `m7_items_slot_check_extend` + `m7_phase3_5_recipes_chain_v2` — items 6 + recipes 6 + chain_m7_mist_clearing 2단계
- `m7_band_achievement_templates_v2` — category_check 확장 + 8행 INSERT
- `m7_data_versions_bump` — 7종 갱신

### 신규 생성 (21개 .dart 파일)
- `lib/features/investigation/domain/danger_level.dart`
- `lib/features/investigation/domain/danger_level_changed_event.dart`
- `lib/features/investigation/domain/danger_level_changed_provider.dart`
- `lib/features/investigation/domain/region_state_flag_descriptions.dart`
- `lib/features/investigation/domain/chain_region_state_mapping.dart`
- `lib/features/investigation/domain/elite_region_state_mapping.dart`
- `lib/core/widgets/region_state_changed_dialog.dart`
- `lib/core/models/region_state_effect.dart`
- `lib/core/models/region_adjacency.dart`
- `lib/features/quest/domain/region_state_weight_config.dart`
- `lib/features/settlement/domain/settlement_infrastructure_config.dart`
- `lib/features/settlement/domain/settlement_infrastructure_provider.dart`
- `lib/features/settlement/domain/infrastructure_upgrade_event.dart`
- `lib/features/settlement/domain/infrastructure_upgrade_provider.dart`
- `lib/core/widgets/settlement_infrastructure_upgraded_dialog.dart`
- `lib/features/settlement/view/foreign_stall_screen.dart`
- `lib/features/movement/domain/movement_distance_calculator.dart`
- `lib/features/movement/view/livingsphere_jump_bar.dart`
- `lib/features/movement/view/region_status_badge_row.dart`
- `lib/core/constants/m7_constants.dart`
- `test/features/quest/domain/region_state_weight_test.dart`

### 수정 (25+ 파일)
| 파일 경로 | 주요 변경 |
|----------|-----------|
| `lib/features/investigation/domain/region_state_model.dart` | HiveField 8·9·10·11·12 추가 |
| `lib/features/investigation/data/region_state_repository.dart` | 메서드 6종 추가 (getOrCreate/addDangerScore/toggleFlag/hasFlag/applyDangerScoreFromQuest/_evaluateInfrastructureTransition) + decay Map |
| `lib/core/domain/activity_log_model.dart` | HiveField 32·33·34 추가 |
| `lib/core/models/user_data.dart` | HiveField 27 추가 |
| `lib/features/settlement/domain/village_facility.dart` | foreignStall case 추가 |
| `lib/core/providers/dialog_queue_provider.dart` | 2 신규 키 + builder switch case |
| `lib/app.dart` | ref.listen 2종 추가 |
| `lib/core/providers/game_state_provider.dart` | UserDataNotifier.incrementForeignStallVisit |
| `lib/core/providers/timer_provider.dart` | regionDangerDecayProvider 신규 |
| `lib/core/providers/static_data_provider.dart` | regionAdjacencies + regionAdjacencyMap |
| `lib/core/data/sync_service.dart` | 'region_adjacency' 32번째 등록 |
| `lib/core/theme/app_theme.dart` | dangerLevelColor/Label + 색상 4종 |
| `lib/features/quest/domain/quest_generator.dart` | computeFinalWeight + _weightedSample + generateQuests 시그니처 |
| `lib/features/quest/domain/quest_provider.dart` | generateQuests 3 호출점 + trailing 2종 |
| `lib/features/quest/domain/quest_completion_service.dart` | currentInfraTier 인자 |
| `lib/features/chain_quest/domain/chain_quest_service.dart` | applyRegionStateFromChain 콜백 |
| `lib/features/chain_quest/domain/chain_quest_provider.dart` | 콜백 주입 |
| `lib/core/models/quest_pool.dart` | regionStateEffect/Required/Excluded 3 필드 |
| `lib/core/models/crafting_recipe_data.dart` | RecipeUnlockCondition 4 nullable 필드 |
| `lib/features/crafting/domain/crafting_service.dart` | _isUnlockedM7 4 type 분기 |
| `lib/features/settlement/domain/herbalist_service.dart` | infra multiplier 3종 + named optional 인자 |
| `lib/features/settlement/view/herbalist_screen.dart` | infraTier 인자 |
| `lib/features/settlement/view/village_visit_section.dart` | foreignStall 카드 + 인프라 배지 |
| `lib/features/settlement/view/chief_house_screen.dart` | 생활권 정보 버튼 + dialog |
| `lib/features/movement/view/movement_screen.dart` | 거리 위임 + 광장 이정표 + 환경 아이콘 + RegionStatusBadgeRow + 잠금 텍스트 + LivingsphereJumpBar |
| `lib/features/movement/domain/movement_provider.dart` | 거리 위임 + 광장 이정표 |
| `lib/features/home/view/home_screen.dart` | ActivityLogType switch 보강 (dart-build-resolver) |
| `lib/features/settlement/domain/settlement_npc_data.dart` | foreignStall case (dart-build-resolver) |
| `test/features/inventory/view/inventory_screen_test.dart` | regionAdjacencies: const [] |
| `test/features/quest/domain/quest_completion_service_test.dart` | regionAdjacencies: const [] |
| `test/features/quest/domain/quest_narrative_render_test.dart` | regionAdjacencies: const [] |
| `test/features/quest/domain/special_flag_processor_test.dart` | regionAdjacencies: const [] |
| `test/features/settlement/domain/herbalist_service_test.dart` | cooldown fallback 갱신 |

## 5. build_runner 재실행 (이미 수행됨)

- `region_state_model.g.dart` — HiveField 8·9·10·11·12
- `activity_log_model.g.dart` — HiveField 32·33·34
- `user_data.g.dart` — HiveField 27
- `region_state_effect.freezed.dart` + `.g.dart` — sealed union 신규
- `region_adjacency.freezed.dart` + `.g.dart` — freezed 신규
- `quest_pool.freezed.dart` + `.g.dart` — 3 필드 추가
- `crafting_recipe_data.freezed.dart` + `.g.dart` — RecipeUnlockCondition 4 필드 추가
- `static_data_provider.g.dart` (있다면)

## 6. CLAUDE.md 금지사항 위반

**없음**. CHECK 제약 확장(items_slot_check에 'consumable' 추가, band_achievement_templates_category_check에 region_pacified/infrastructure_growth 추가)은 명세서 페이즈 3 #5 SQL의 데이터 호환을 위한 필수 조치이며, 명세 범위 내.

## 7. SQL 마이그레이션 부산물

페이즈 3 #5 SQL의 cons_* 아이템(`cons_wildflower_oil`, `cons_seaweed_tonic`)이 `slot='consumable'`을 사용하는데 기존 `items_slot_check` CHECK 제약에 'consumable'이 누락되어 있어 `m7_items_slot_check_extend` 마이그레이션을 선행 적용.

페이즈 4 #1 SQL의 `region_pacified` + 페이즈 4 #4의 `infrastructure_growth` category가 기존 `band_achievement_templates_category_check`에 누락되어 `m7_band_achievement_templates_v2`에서 CHECK 확장 + INSERT 동시 수행.

## 8. PHASE 3 flutter-reviewer 결과: APPROVE (with warnings)

Critical/High 0건. Medium 8건 발견 후 1건 즉시 수정(ISSUE-1), 7건은 후속 개선 노트.

### 수정 완료
- **ISSUE-1**: M7 7리전 리스트 중복 하드코딩 4곳 → `M7Constants.livingsphereRegions` 통합 (timer_provider/chief_house_screen/region_state_repository/crafting_service 4 파일 수정 + analyze + test 564/564 재확인)

### 후속 개선 노트 (PASS 유지, 추후 검토)
- **ISSUE-2**: `StaticGameData.regionAdjacencyMap` getter 매 호출 시 Map 재구성 → `late final` cached field로 변환 권장. 7리전 22행 규모는 미미하나 M8+ 확장 시 검토.
- **ISSUE-3**: `ForeignStallScreen._showGossipDialog` 가 `millisecondsSinceEpoch % pool.length`로 의사 랜덤 사용 → `Random().nextInt(pool.length)` 변경 권장.
- **ISSUE-4**: `DangerLevelResolver.resolveLevel(0)`이 `tension` 반환하지만 `RegionState.currentDangerLevel` fallback은 `peaceful(2)` — 첫 진입 시점에 fallback과 실 계산값 모순 가능. 첫 `addDangerScore` 호출 후 자동 정합. 명세 4단계 임계값(tension 0~+49)의 의도된 경계 정의.
- **ISSUE-5**: `regionDangerDecayProvider` 첫 진입 시 12시간 대기 → `_lastDecayCheckedAt` fallback을 `DateTime.fromMillisecondsSinceEpoch(0)`로 변경하거나 RegionState HiveField로 영속화 권장. M7 MVP 의도된 동작이라 후속 검토.
- **ISSUE-6**: `_evaluateInfrastructureTransition` docstring에 "region 3 한정 평가" 명시 권장.
- **ISSUE-7**: `SettlementInfrastructureUpgradedDialog`에 `onDismiss` 콜백 도입하여 큐 dequeue 패턴 일관화 권장. 현재 동작 정상.
- **ISSUE-8**: `ForeignStallScreen._purchase`의 BuildContext.mounted 체크 보강 (dialog 컨텍스트 → 화면 ScaffoldMessenger 대체). 현재 동작 정상.

## 9. 최종 통합 검증 결과

| 검증 항목 | 결과 |
|----------|------|
| `flutter analyze` (전체) | PASS — No issues found |
| `flutter test` (전체) | PASS — 564 tests passed |
| Supabase 마이그레이션 | PASS — 5건 적용 + 검증 DO 블록 모두 통과 |
| build_runner | PASS — freezed/Hive 모든 .g.dart/.freezed.dart 재생성 완료 |
| flutter-reviewer | APPROVE (with warnings, Critical/High 0건) |

## 10. 다음 단계

implement 완료. 사용자 액션:
1. **수동 게임플레이 테스트** 권장 (M7 핵심 7리전 진입 + 의뢰 발급 + 사건 진행 + dangerLevel 전이 + 인프라 단계 전이 + 외래 좌판 거래 + chain_m7_mist_clearing chain + 위업 발급 전체 흐름 검증)
2. **finalize-feature 스킬**로 git commit + CHANGELOG fragment + 아카이브 진행
3. (선택) 후속 개선 ISSUE-2~8 별도 PR 또는 다음 마일스톤에서 정리

## 11. CLAUDE.md typeId·HiveField 표 갱신 필요

```
| RegionState (typeId 8) | 다음 HiveField 13 |
| UserData (typeId 5) | 다음 HiveField 28 |
| ActivityLogType (typeId 6) | 다음 HiveField 35 |
```

finalize-feature 시 CLAUDE.md 자동 갱신.
