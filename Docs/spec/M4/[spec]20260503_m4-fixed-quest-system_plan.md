# M4 페이즈 4 #3 quest_pools 컬럼 확장 + 고정 의뢰 노출 로직 구현 계획·결과

Skill used : implement-agent

> 명세서: `Docs/spec/M4/[spec]20260503_m4-fixed-quest-system.md`
> 기획 입력 (4개):
> - `Docs/content-design/[content]20260503_settlement-trust-and-fixed-events.md` (페이즈 1 #4)
> - `Docs/balance-design/[balance]20260503_fixed-quest-curve.md` (페이즈 2 #4)
> - `Docs/balance-design/[balance]20260503_chore-quest-economy.md` (페이즈 2 #3)
> - `Docs/content-design/[content]20260503_sector-system-redesign.md` (페이즈 1 #2)
> 작성일: 2026-05-03
> 선행 페이즈: 페이즈 4 #1 (커밋 94d9ccc) + 페이즈 4 #2 (커밋 2189adf)

---

## 1. 구현 계획 요약

### 사용자 결정 사항 (planner 산출 Q&A)

- **Q1=B**: AppTheme `settlementAccent = Color(0xFFFFA000)` 신규 상수 추가. 변형 섹터 `transformVillage`(0xFF2E7D32 초록)과 의미 충돌 회피.
- **Q2=인라인 한정**: settlementTier 배지를 dispatch_screen 인라인 Container로 추가. QuestCardBadges 통합은 페이즈 4 #4로 위임.
- **Q3=Notifier 비공개 stub**: `QuestListNotifier._getCurrentTrustLevel()` `return 0;` stub. RegionStateRepository 미수정 (페이즈 4 #5 본격 구현 영역).

### 13 TASK + 7단계 실행 순서

| 단계 | 병렬/직렬 | TASK 수 | 비고 |
|------|----------|---------|------|
| 1 | 병렬 | 3개 (TASK-1·2·6) | SQL + QuestPool 모델 + isSettlementStep getter |
| 2 | 직렬 (build_runner) | 1개 (TASK-3) | freezed/json 7 outputs |
| 3 | 병렬 | 2개 (TASK-4·9) | QuestGenerator filter + AppTheme 색상 |
| 4 | 직렬 | 1개 (TASK-5) | QuestListNotifier 6개 변경 통합 |
| 5 | 직렬 | 1개 (TASK-7) | QuestSortService settlementTier (TASK-8 자동 처리 통합) |
| 6 | 직렬 | 1개 (TASK-10) | dispatch_screen 배지 |
| 7 (검증) | 병렬 | verifier + flutter-reviewer | 풀 검증 PASS |

TASK-8은 TASK-7 진행 중 sorted_quests_provider 빈 fallback 보강이 함께 처리되어 별도 호출 생략.

---

## 2. 변경 파일 목록

### 2.1 신규 생성 (1개)

| 파일 경로 | 역할 | TASK |
|-----------|------|------|
| `band_of_mercenaries/supabase/migrations/20260503_m4_phase4_3_quest_pools_extension.sql` (223 라인) | 단일 BEGIN/COMMIT 트랜잭션. §1 ALTER quest_pools 9컬럼 추가 / §2 Partial UNIQUE 인덱스 / §3 INSERT 6행 (qp_pyegwang_step1~6) / §4 INSERT 10행 (dustvile_chore_NN) / §5 data_versions UPDATE / §6 ASSERT 2건 | TASK-1 |

### 2.2 수정 (8개)

| 파일 경로 | 변경 내용 | TASK |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/models/quest_pool.dart` | 9개 필드 추가 (line 24~37, 3그룹: 고정/override/노출제어). snake_case @JsonKey | TASK-2 |
| `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` | `generateQuests()` 시그니처에 `int currentTrustLevel = 0` 파라미터 추가 (line 31). `generalPools` 필터 체인에 `.where((p) => !p.isFixed)` + `.where((p) => p.minTrustLevel <= currentTrustLevel)` 2개 추가 (line 48~49) | TASK-4 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | (1) `chain_quest_progress.dart` + `chain_quest_repository.dart` import 추가 (line 34~35) / (2) `_getCurrentTrustLevel()` stub 메서드 추가 (line 137) / (3) `_injectFixedSettlementQuest()` 추가 (line 253~297) / (4) `refreshAvailableQuests()` 공개 메서드 추가 (line 307) / (5) `generateQuests`/`fillQuests`/`_refreshExpiredQuests` 3곳에 `currentTrustLevel: _getCurrentTrustLevel()` 인자 (line 189·353·495) / (6) `generateQuests` 끝부분 `_injectFixedSettlementQuest()` 호출 (line 193) / (7) `_checkQuestRefresh()` settlement_ continue (line 435) / (8) `_refreshExpiredQuests()` `filteredExpired` + 조기 return (line 459) | TASK-5 |
| `band_of_mercenaries/lib/features/quest/domain/quest_model.dart` | `isSettlementStep` getter 추가 (line 152~154). `isChainQuest && (chainId?.startsWith('settlement_') ?? false)` | TASK-6 |
| `band_of_mercenaries/lib/features/quest/domain/quest_sort_service.dart` | (1) `QuestSortResult.settlementTier` 필드 추가 (line 11) / (2) 생성자 파라미터 (line 16) / (3) `sort()` 내 `settlementTier = <ActiveQuest>[]` 지역 변수 (line 58) / (4) `q.isSettlementStep` 분기 추가 (line 68~74) / (5) `_sortByEstimatedReward(settlementTier, ...)` 호출 (line 93) / (6) `sortedRest: [...settlementTier, ...tier1~4]` 빌드 (line 100~103) | TASK-7 |
| `band_of_mercenaries/lib/features/quest/domain/sorted_quests_provider.dart` | line 33 빈 fallback `QuestSortResult` 인스턴스에 `settlementTier: const []` 인자 추가 | TASK-8 (TASK-7에 통합 처리) |
| `band_of_mercenaries/lib/core/theme/app_theme.dart` | `settlementAccent = Color(0xFFFFA000)` 색상 상수 추가 (line 53~56). 변형 섹터 그룹 직후, `chainGold` 직전 | TASK-9 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` | `_QuestCard.build()` 내 `QuestCardBadges` 직후에 `quest.isSettlementStep` 조건부 인라인 Container 추가 (line 473~493). "📜 마을 사건" 배지, `AppTheme.settlementAccent.withValues(alpha: 0.15)` 배경 + 1px 테두리 | TASK-10 |

### 2.3 자동 생성 파일 (build_runner, TASK-3)

| 파일 경로 | 비고 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/quest_pool.freezed.dart` | 9개 신규 필드 반영 |
| `band_of_mercenaries/lib/core/models/quest_pool.g.dart` | snake_case @JsonKey fromJson/toJson 자동 생성 |

build_runner 실행 결과: 7 outputs (9.7s).

---

## 3. 검증 결과 요약

### 검증 모드: 풀 검증 (TASK 수 ≥ 3)

verifier + flutter-reviewer 병렬 호출.

### 3.1 verifier 결과: PASS (with warnings, minor만)

- REQ-01~14 모두 PASS
- Q-1·Q-2·Q-3 결정사항 모두 정합
- 페이즈 4 #5 의존 인터페이스 stub 정합 — 미구현 함수(ChainQuestService.tryActivateSettlement / RegionStateRepository.addSettlementTrust / RegionState HiveField 4·5) 본 코드에서 호출 안 함
- dustvile_pyegwang_reopen 6×9 매트릭스 + dustvile_chore_NN 10행 분포 모두 정확 일치
- flutter analyze: PASS (`No issues found! ran in 2.1s`)
- 테스트: PASS 499/499

### 3.2 flutter-reviewer 결과: APPROVE

- BLOCK 없음
- HIGH 1 + MEDIUM 5 + LOW 1 권고 (모두 후속 페이즈 위임 또는 stub 해제 전 검토 권장)

### 3.3 통합 판정: PASS (이슈 기록)

`verifier PASS (with warnings minor만) + flutter-reviewer APPROVE` → PASS 케이스 4 적용.

---

## 4. 후속 페이즈에서 처리할 권고 사항 (검증 단계 이슈 기록)

본 페이즈는 stub 상태(`_getCurrentTrustLevel() = 0`)로 고정 의뢰가 미노출되므로 즉각 회귀는 없음. 아래 권고는 페이즈 4 #5 stub 해제 시점 또는 후속 정리 페이즈에서 처리.

| # | 출처 | 심각도 | 항목 | 처리 시점 |
|---|------|--------|------|----------|
| 1 | verifier ISSUE-1 | minor | ChainTopSection의 `chainQuestProgressProvider` watch에 `!chainId.startsWith('settlement_')` 필터 누락 — 페이즈 4 #5에서 ChainQuestProgress가 settlement_ chainId로 등록되면 ChainTopSection에 중복 표시 위험 | **페이즈 4 #5 명세** |
| 2 | flutter-reviewer MEDIUM | medium | `_injectFixedSettlementQuest()` 중복 주입 방어 — `state.any(...)`가 _load() 이전 스냅샷 참조. Hive 박스 직접 조회로 변경 또는 `_load()` 순서 조정 권장 | **페이즈 4 #5 stub 해제 전** (고정 의뢰 활성화 시 회귀 방지) |
| 3 | verifier ISSUE-2 + flutter-reviewer MEDIUM | medium | `_refreshExpiredQuests()` `filteredExpired` 이중 필터 — `_checkQuestRefresh()` settlement_ continue로 이미 차단된 후 재필터. 코드 가독성 저하. 둘 중 하나만 유지 권장 | 후속 정리 |
| 4 | flutter-reviewer HIGH | high | `_QuestCard.build()` 내 `IntrinsicHeight` 사용 — 스크롤 리스트 내부 카드마다 이중 레이아웃. 본 페이즈 변경 외 기존 영역 | 후속 UI 사이클 |
| 5 | flutter-reviewer MEDIUM | medium | `_QuestCard` `Builder` 클로저 내 `ref.watch(speedMultiplierProvider)` — 속도 변경 시 모든 카드 rebuild. 별도 ConsumerWidget 분리 권장. 본 페이즈 변경 외 기존 영역 | 후속 UI 사이클 |
| 6 | flutter-reviewer MEDIUM | medium | "📜 마을 사건" 배지 emoji 접근성 — `Semantics(label: '마을 사건')` 또는 `ExcludeSemantics` 권장. 기존 다른 emoji 배지(🔥/★)와 일관성 차원에서 통합 개선 검토 | 후속 접근성 사이클 |
| 7 | flutter-reviewer MEDIUM | medium | `_injectFixedSettlementQuest()` hardcoded `'settlement_3_pyegwang_reopen'` chainId — M5 다중 거점 확장 시 일반화 (settlementChainId 상수 또는 모든 settlement_ 풀 순회) 필요 | M5 또는 페이즈 4 #5 |
| 8 | flutter-reviewer LOW | low | `settlementAccent` 라이트 테마 대비비 (WCAG AA 미달 가능) — 다크 프라이머리 테마 환경에서는 무시 가능. 라이트 테마 호환성 차원에서 fontWeight w600 유지 | 향후 라이트 테마 도입 시 |

---

## 5. 페이즈 4 #5 의존 인터페이스 (본 페이즈 stub 정의)

페이즈 4 #5에서 다음을 구현하여 본 페이즈의 stub을 활성화합니다.

| 인터페이스 | 본 페이즈 stub | 페이즈 4 #5 실제 구현 |
|-----------|--------------|---------------------|
| `_getCurrentTrustLevel()` | `return 0;` | `RegionStateRepository.getSettlementTrust(userData.region).level` |
| `RegionState.settlementTrust` (HiveField 4) | 미존재 | `int?` nullable, null=0 fallback |
| `RegionState.settlementTrustLevel` (HiveField 5) | 미존재 | `int?` nullable, null=1 fallback |
| `RegionStateRepository.addSettlementTrust()` | 미구현 | 누적 점수 증가 + 단계 승급 검증 + `QuestListNotifier.refreshAvailableQuests()` 호출 |
| `RegionStateRepository.getSettlementTrust()` | 미구현 | `(trust: int, level: int)` 레코드 반환 |
| `ChainQuestService.tryActivateSettlement(regionId, eventName)` | 미구현 | `settlement_3_pyegwang_reopen` ChainQuestProgress 신규 생성 |
| `ChainQuestService.checkDormant()` settlement_ skip | 분기 없음 | settlement_ prefix는 14일 dormant 정책 미적용 |
| `QuestCalculator` is_fixed override 분기 (gold/duration/cost) | 미구현 | `pool.rewardGoldOverride` / `pool.durationOverrideSeconds` / `pool.minDispatchCost` 우선 사용 |
| `ExperienceService` is_fixed XP bonus 분기 | 미구현 | `pool.rewardXpBonusOverride` 가산 |
| `QuestCompletionService` 거점 사건 step 완료 처리 | 미구현 | settlementTrust + chainProgress 동시 업데이트 + `refreshAvailableQuests()` 호출 |
| `ActivityLogType` HiveField 22·23·24 | 미존재 | `settlementTrustUp` / `settlementEventStep` / `settlementEventCompleted` |
| `dialogQueue` 신뢰도 단계 승급 다이얼로그 | 미통합 | `dialogQueueProvider` medium priority 통합 |

---

## 6. CLAUDE.md 위반 사항

**없음**.

- 모든 코더가 CLAUDE.md 코멘트 정책 준수 (한국어, 비자명한 사유만 명시)
- `Navigator.push` 신규 사용 없음 (상태 기반 렌더링 보존)
- LayerSidebar 변경 없음 (본 페이즈 범위 외)
- QuestCardBadges 통합 없음 (Q-2 결정 준수, 인라인 한정)
- Supabase MCP 호출 없음 (옵션 B 일괄 적용 정책 유지)
- 절대 경로 import 사용 (`package:band_of_mercenaries/...`)

---

## 7. Supabase 적용 보류 (옵션 B 연장)

본 페이즈는 SQL 마이그레이션 파일만 작성하고 실제 Supabase 적용은 페이즈 4 #5 완료 후 단일 시점 일괄 적용 예정 (옵션 B 유지).

- 페이즈 4 #1 SQL: 미적용
- 페이즈 4 #2 SQL: 미적용
- 페이즈 4 #3 SQL: 미적용 (본 페이즈)
- data_versions 미증분이라 클라이언트 sync에서 변경분 안 내려옴 → stub `_getCurrentTrustLevel() = 0`과 결합하여 안전 대기 상태

페이즈 4 #4·#5 완료 후 4개 SQL 파일을 단일 트랜잭션으로 일괄 적용.

---

## 8. 빌드 게이트 / 테스트 결과

| 검증 | 결과 | 비고 |
|------|------|------|
| `flutter analyze` (PHASE 2.5) | PASS | No issues found! (2.3s) |
| `dart run build_runner build --delete-conflicting-outputs` | PASS | 7 outputs, 9.7s, riverpod_generator analyzer 호환 경고만 (기존 환경 이슈) |
| `flutter analyze` (PHASE 5 재확인) | PASS | No issues found! (2.2s) |
| 회귀 테스트 (verifier 수행) | PASS | 499/499 |

build_runner 재실행이 필요한 파일: `quest_pool.g.dart`, `quest_pool.freezed.dart` — 자동 생성 완료.
