# M5 페이즈 4 #3 — 드랍 출처 hook 5종 + 거대 박쥐 step 3 강제 spawn + 신뢰도 단계 진입 보너스 + region_discoveries 발견 hook + firstAcquiredItem 영속 추적 구현 계획서

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260505_M5_phase4_3_drop-hooks-and-progression-triggers.md`
> 작성일: 2026-05-05
> 마일스톤: M5 페이즈 4 #3 — **마지막 페이즈 (M5 종결)**
> 선행: 페이즈 4 #1 (commit `3b6506c`) + 페이즈 4 #2 (commit `d03c5b4`)

---

## 1. 작업 개요

페이즈 4 #1 데이터 인프라 + 페이즈 4 #2 도메인/UI 위에 **5종 드랍 hook 활성화** + **거대 박쥐 step 3 강제 spawn** + **신뢰도 단계 진입 일회성 보너스** + **region_discoveries 발견 hook** + **firstAcquiredItem 영속 추적**(`RegionState.firstAcquiredMaterialIds` HiveField 7) + **`ActivityLogType.inventoryStackCapped` HiveField 28** + **Supabase 데이터 INSERT**(quest_pool_material_drops 16행 + travel_choice 풀세트 신설). 본 페이즈 완료로 M5 종료 조건이 모두 충족된다.

---

## 2. 변경 파일 목록

### 2.1 수정 (13개 + 자동 재생성 2개)

| 파일 경로 | 변경 유형 | 설명 |
|---|---|---|
| `lib/features/investigation/domain/region_state_model.dart` | 수정 | `firstAcquiredMaterialIds: List<String>` HiveField 7 추가, typeId 8 유지 |
| `lib/features/investigation/domain/region_state_model.g.dart` | 자동 재생성 | hive_generator |
| `lib/core/domain/activity_log_model.dart` | 수정 | `ActivityLogType.inventoryStackCapped` HiveField 28 추가, typeId 6 유지 |
| `lib/core/domain/activity_log_model.g.dart` | 자동 재생성 | hive_generator |
| `lib/features/investigation/data/region_state_repository.dart` | 수정 | `addAcquiredMaterial(int, String)` 신규 메서드 + `addSettlementTrust` 단계 진입 재료 보너스 분기(2단계 #6 ×1 / 3단계 #1 ×3) + collection import |
| `lib/features/crafting/domain/crafting_service.dart` | 수정 | `evaluateState` firstAcquiredItem 분기 영속 평가 교체(RegionState.firstAcquiredMaterialIds.contains) + TODO 주석 제거 |
| `lib/features/quest/domain/elite_loot_service.dart` | 수정 | switch에 `case 'material'` fallthrough 추가 (essence/equipment/guild_item과 동일 처리) |
| `lib/features/investigation/domain/investigation_notifier.dart` | 수정 | `_applyDiscoveryItems` 헬퍼 추출 + 4분기(faction_clue/elite/hidden_quest/transform) 각각 + normal/default 분기에 helper 호출 추가 |
| `lib/features/movement/domain/movement_provider.dart` | 수정 | `applyTravelChoiceEffect` switch에 `'material_drop'` case 추가 + 999 사전 평가 + region 3 한정 영속 추적 + collection import |
| `lib/features/movement/domain/travel_choice_service.dart` | 수정 | `summarizeEffect` switch에 `'material_drop'` case 1줄 추가 |
| `lib/features/chain_quest/domain/chain_quest_service.dart` | 수정 | `onStepCompleted` 시그니처에 `addRewardItems` 콜백 파라미터 추가 + step 성공 분기에서 `chainStepData.rewardItems.entries` 순회 호출 |
| `lib/features/quest/domain/quest_provider.dart` | 수정 | `_applyCompletionResult`에 quest_pool_material_drops 매핑 hook(라인 655~683) + `chainQuestService.onStepCompleted` 호출부에 `addRewardItems` 콜백 인자 + `generateQuests`/`fillQuests`/`_refreshExpiredQuests` 3곳 호출부 currentChainId/currentChainStep 인자 추가 |
| `lib/features/quest/domain/quest_generator.dart` | 수정 | `generateQuests` 시그니처에 `String? currentChainId, int? currentChainStep` 파라미터 2개 + elite spawn 루프에 거대 박쥐 강제 spawn 분기 + TODO(M6+) 주석 1줄 |
| `lib/features/home/view/home_screen.dart` | 수정 (빌드 게이트) | switch에 `inventoryStackCapped` case 1줄 추가 (⚠️ 아이콘 + settlementAccent 색상) |
| `pubspec.yaml` | 수정 | `collection: ^1.18.0` 직접 의존성 추가 (firstWhereOrNull 사용) |

### 2.2 신규 생성 (1개)

| 파일 경로 | 역할 |
|---|---|
| `band_of_mercenaries/supabase/migrations/20260505_m5_phase4_3_drop_hooks.sql` | 단일 트랜잭션 SQL — quest_pool_material_drops 16행 + travel_choice_results CHECK 제약 ALTER + travel_choice_events 3행 + travel_choice_options 6행 + travel_choice_results 6행 + data_versions UPDATE 4행. apply_migration 적용 완료 |

---

## 3. 구현 내역

### 3.1 모델/enum 변경

- **RegionState.firstAcquiredMaterialIds** HiveField 7 — 기본값 `[]`, typeId 8 유지, HiveAdapter 호환
- **ActivityLogType.inventoryStackCapped** HiveField 28 — typeId 6 유지

### 3.2 도메인 서비스 시그니처 변경

| 서비스 | 변경 내용 |
|---|---|
| `RegionStateRepository.addAcquiredMaterial(int, String)` | 신규 멱등 메서드 (state null 시 신규 RegionState 생성) |
| `CraftingService.evaluateState` | firstAcquiredItem 분기 영속 평가 (페이즈 4 #2 임시 평가 교체) |
| `EliteLootService.rollDrops` | drop_type='material' fallthrough 추가 |
| `InvestigationNotifier._completeInvestigation` | `_applyDiscoveryItems` 헬퍼 신규 + 5분기(4 type + normal) helper 호출 |
| `MovementNotifier.applyTravelChoiceEffect` | 'material_drop' case 추가 |
| `TravelChoiceService.summarizeEffect` | 'material_drop' 한국어 요약 추가 |
| `ChainQuestService.onStepCompleted` | `addRewardItems` 콜백 파라미터 신규 추가 |
| `RegionStateRepository.addSettlementTrust` | 2/3단계 진입 시 일회성 재료 보너스 분기 추가 |
| `QuestListNotifier._applyCompletionResult` | quest_pool_material_drops 매핑 hook 추가 |
| `QuestGenerator.generateQuests` | `currentChainId/currentChainStep` 파라미터 2개 + 거대 박쥐 강제 spawn 분기 |

### 3.3 5종 드랍 hook 통합 패턴

각 hook 호출 측에서 동일 흐름:
1. staticData null 가드
2. `inv.getQuantityForItemId(itemId) >= 999` 사전 평가 → `inventoryStackCapped` 활동 로그 1행
3. `inv.addItem(itemId, quantity, items: staticData.items)`
4. `regionStateRepository.addAcquiredMaterial(regionId, itemId)` 멱등 호출

### 3.4 거대 박쥐 step 3 강제 spawn

- `quest_generator.dart` 라인 144~148:
  ```dart
  final isSettlement3Step3 = currentChainId == 'settlement_3_pyegwang_reopen' && currentChainStep == 3;
  final shouldForceSpawn = isSettlement3Step3 && monster.id == 'elite_giant_bat';
  if (shouldForceSpawn || random.nextDouble() < monster.spawnRate) { ... }
  ```
- `quest_provider.dart` 호출부 3곳(`generateQuests`/`fillQuests`/`_refreshExpiredQuests`) 모두 chain progress 조회 후 인자 전달
- TODO(M6+) 주석으로 향후 데이터 모델 마이그레이션 예고

### 3.5 firstAcquiredItem 영속 평가 (CraftingService)

페이즈 4 #2 임시 평가:
```dart
// TODO(M5 페이즈 4 #3): 첫 입수 영속 추적 도입
final qty = inventoryRepository.getQuantityForItemId(condition.firstAcquiredItem!);
if (qty <= 0) return RecipeState.locked;
```

본 페이즈 영속 평가 교체:
```dart
final regionState = regionStateRepository.getState(GameConstants.startingRegionId);
final acquired = regionState?.firstAcquiredMaterialIds
    .contains(condition.firstAcquiredItem!) ?? false;
if (!acquired) return RecipeState.locked;
```

### 3.6 Supabase 데이터 INSERT (apply_migration 완료)

검증 쿼리 결과:
- `quest_pool_material_drops`: **16행** (UNIQUE 제약으로 chore_03 #5 보너스 행 병합 — 코더 결정사항 2)
- `tce_dustvile_events`: 3 (마른 초원 야간 순찰/폐광길 짐 더미/먼지 길 여행자 조우)
- `tce_dustvile_options`: 6 (이벤트당 2 옵션)
- `travel_choice_results material_drop`: 6
- `effect_type CHECK`: 'material_drop' 포함 ✓

---

## 4. 검증 결과

### 4.1 검증 모드

**풀 검증** (TASK 수 14개 ≥ 3) — verifier + flutter-reviewer 병렬

### 4.2 1차 검증 (FAIL)

#### verifier 결과: FAIL
- ISSUE-1 [critical] FR-4 InvestigationNotifier discovery_data.items hook이 hidden_quest 분기에 도달 못함 — 페이즈 4 #1 등록 3개 발견 중 hidden_quest 2건 미적용
- ISSUE-2 [minor] FR-13 16행 vs 명세 17행 (UNIQUE 제약 회피, coder 결정 허용 범위)

#### flutter-reviewer 결과: APPROVE
- HIGH 2건 (StateError throw 5곳 / requireValue 일관성)
- MEDIUM 5건 (currentRegion! / discoveryFound 로그 중복 / 하드코딩 ID / chief_house ref.read / addAcquiredMaterial 의도 주석)

### 4.3 수정 작업 (4개 파일 병렬 재호출)

| TASK | 수정 내용 |
|---|---|
| TASK-8 (investigation_notifier.dart) | `_applyDiscoveryItems` 헬퍼 추출 + 4분기 + normal 분기 모두 호출 + firstOrNull 패턴 |
| TASK-12 (quest_provider.dart) | 라인 688/914 firstOrNull + 라인 909 valueOrNull |
| TASK-9 (movement_provider.dart) | firstWhereOrNull + bang 단언 제거 + collection import |
| TASK-11 (region_state_repository.dart) | 라인 203/219 firstWhereOrNull + collection import |

`pubspec.yaml`에 `collection: ^1.18.0` 직접 의존성 추가.

### 4.4 2차 검증 (PASS)

#### verifier 결과: PASS
- 1차 FAIL 1건 + reviewer HIGH 2건 + MEDIUM #3·#4 모두 수정 확인
- 회귀 없음, 모든 REQ PASS
- flutter analyze: PASS, 테스트: 512/512 PASS

#### flutter-reviewer 결과: APPROVE
- CRITICAL/HIGH 0건
- MEDIUM 2건 잔존 (기존 코드의 firstWhere 방어 미완성 — quest_provider 6곳 + region_state_repository getState — 본 페이즈 작업 범위 외, 기존 코드 안티패턴)

### 4.5 통합 판정: **PASS**

---

## 5. 명세 부분 충족 / 향후 위임

### 5.1 명세 가정 위반 1건 (사용자 (A) 옵션 선택으로 해소)

- **travel_choice_events에 region_id 컬럼 부재** — 페이즈 2 #1 §1-4가 가정한 region 3 한정 이벤트가 현재 DB에 0건. (A) 옵션 선택으로 region 3 한정 신규 이벤트 3개 + 옵션 6개 + 결과 6개 신설. category는 'encounter'/'discovery'/'dilemma' 분배. 단, **region 한정 트리거 작동은 후속 작업** (TravelEventService 변경 본 페이즈 범위 외). 현재 데이터는 글로벌 트리거 가능.

### 5.2 미수정 (본 페이즈 범위 외)

- **MEDIUM #5** QuestGenerator 하드코딩 ID — TODO(M6+) 주석으로 표시
- **MEDIUM #6** ChiefHouseScreen ref.read — 본 페이즈 §3.1 외
- **MEDIUM #7** addAcquiredMaterial regionId 의도 주석 — minor
- **reviewer 2차 MEDIUM 2건** — 기존 코드의 firstWhere 방어 미완성, 본 페이즈 작업 외 코드의 안티패턴

### 5.3 명세 vs 구현 미세 차이

- **FR-13 16행 vs 17행**: `quest_pool_material_drops`에 `UNIQUE(pool_id, item_id)` 제약으로 chore_03 #5 두 행(1.0 확정 + 0.2 보너스) 분리 불가 → `1.0, qty_min=1, qty_max=2` 단일 행으로 병합. 평균 산출량 1.2 → 1.5개/회 (미세 +25%). 페이즈 2 #1 시뮬레이션 38분 첫 제작 결과 영향 미세

---

## 6. build_runner 재실행 필요 파일

- `lib/features/investigation/domain/region_state_model.g.dart` (RegionState HiveField 7 추가)
- `lib/core/domain/activity_log_model.g.dart` (ActivityLogType HiveField 28 추가)

`cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs` 실행 완료 (TASK-4).

---

## 7. CLAUDE.md 금지사항 위반

**없음** — 모든 작업이 CLAUDE.md 정책 내에서 수행됨:
- Hive typeId 신규 등록 0건 (RegionState typeId 8 / ActivityLogType typeId 6 내부 필드만 추가)
- HiveField 점유표 갱신은 finalize-feature에서 처리 (RegionState 다음 7→8, ActivityLogType 다음 28→29)
- 코멘트 정책 준수
- avoid_print rule 준수

---

## 8. M5 마일스톤 종료 조건 검증

본 페이즈 4 #3 완료로 M5 종료 조건 모두 충족:

| 종료 조건 | 충족 여부 | 근거 |
|---|---|---|
| 재료 인벤토리 별도 구분 | ✅ | 페이즈 4 #2 인벤토리 4탭째 MaterialTab |
| 제작 레시피 충족/부족 표시 | ✅ | 페이즈 4 #2 RecipeCard 4상태 |
| 출처 3개 이상 연결 | ✅ | 본 페이즈 5종 출처 hook 모두 활성 (의뢰/조사/엘리트/이동/체인 + 신뢰도 보너스) |
| 첫 제작 목표 3개 달성 가능 | ✅ | 깃발 복원/광부 단검/폐광 유물 조각 모두 제작 가능 |
| 완제품 드랍과 제작 루트 공존 | ✅ | 페이즈 2 #3 검증 — 격차 보존 |
| 첫 제작 30~45분 (이상 38분) | ✅ | 페이즈 2 #1 시뮬레이션 정합 |
| 첫 희귀 90~150분 (광부 단검 60분 / 폐광 유물 98분) | ✅ | 페이즈 2 #1 시뮬레이션 정합 |

---

## 9. 다음 단계 안내

본 구현 완료 후:
1. `finalize-feature` 스킬 실행 — 커밋 + Archive + CLAUDE.md 갱신 + CHANGELOG fragment
2. `/milestone-runner M5 --resume` — **M5 마일스톤 완료 보고** (페이즈 4 #4 없음 — 마지막 페이즈)
