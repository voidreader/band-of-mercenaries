# 구현 계획 — M4 페이즈 4 #5 마을 신뢰도 시스템 + 고정 사건 진행 + 페이즈 4 #3 stub 해제

Skill used : implement-agent

> 명세서: `Docs/spec/M4/[spec]20260503_m4-settlement-trust.md`
> 구현 일자: 2026-05-04
> 마일스톤: M4 페이즈 4 #5 (페이즈 4 마지막 산출물)

---

## 1. 개요

페이즈 4 #3에서 stub 상태로 정의된 마을 신뢰도 시스템을 본격 구현하여 거점 사건 라인(`settlement_3_pyegwang_reopen` 6단계)을 활성화. 33개 요구사항(REQ-01 ~ REQ-33)을 17개 태스크로 분해 후 9단계 실행 순서로 처리.

페이즈 4 #3 후속 권고 #1·#2·#3(REQ-29·30·31) 통합 처리 완료. 페이즈 4 #3에서 INSERT만 되고 노출되지 않던 16행 quest_pools(`qp_pyegwang_step1~6` + `dustvile_chore_NN`) 활성화.

---

## 2. 변경 파일 목록

### 2.1 수정 (14개)

| 파일 | 변경 유형 | 설명 |
|------|-----------|------|
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.dart` | 모델 확장 | HiveField 4 `settlementTrust`(int?) + HiveField 5 `settlementTrustLevel`(int?) + getter 2종 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | enum 확장 | HiveField 22~24 (settlementTrustUp / settlementEventStep / settlementEventCompleted) |
| `band_of_mercenaries/lib/core/providers/dialog_queue_provider.dart` | 상수 추가 | `DialogTypeRegistry.settlementTrustUp` + keys 8종 확장 |
| `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart` | 메서드 추가 | `addSettlementTrust` / `getSettlementTrust` / `setSettlementTrust` + 상수 맵 3종 + `_grantXpEvenly` 헬퍼 |
| `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_service.dart` | 분기 추가 | `tryActivateSettlement` 메서드 + `checkDormant` settlement_ skip + `onStepCompleted` protagonist skip |
| `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` | 시그니처 확장 | `rewardGoldOverride` / `durationOverrideSeconds` / `isFixedWithDurationOverride` 추가 |
| `band_of_mercenaries/lib/core/domain/experience_service.dart` | 시그니처 확장 | `rewardXpBonusOverride` 추가 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | 필드 + 분기 추가 | `QuestCompletionResult.settlementTrustGain` + pool 조회 후 override 전달 + region==3 일반 의뢰 신뢰도 점수 계산 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | 6개 변경 | `_getCurrentTrustLevel` stub 해제 / dispatch override / `_injectFixedSettlementQuest` 중복 방어 / `_refreshExpiredQuests` 가독성 개선 / `_applyCompletionResult` settlement_ step 분기 + 일반 의뢰 분기 |
| `band_of_mercenaries/lib/features/quest/view/chain_top_section.dart` | 필터 확장 | `actives` 필터에 `!p.chainId.startsWith('settlement_')` 추가 |
| `band_of_mercenaries/lib/app.dart` | listen 추가 | `settlementTrustLevelUpProvider` listen + dialogQueue enqueue (high priority) |
| `band_of_mercenaries/lib/core/providers/game_state_provider.dart` | hook 추가 | `initializeNewGame` 끝부분에 region 3 RegionState 초기화 + `tryActivateSettlement` 호출 |
| `band_of_mercenaries/lib/features/movement/domain/movement_provider.dart` | hook 추가 | `_completeMovement`에서 region 3 진입 시 자동 초기화 (기존 세이브 호환). HIGH 이슈 수정으로 분기 분리 (state==null vs settlementTrust==null) |
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | switch case 추가 | `_logIcon`에 신규 enum 3종 case 분기 (빌드 게이트 자동 추가) |

### 2.2 신규 생성 (3개)

| 파일 | 역할 |
|------|------|
| `band_of_mercenaries/lib/features/investigation/domain/trust_level_up_event.dart` | `TrustLevelUpEvent` 클래스 + `settlementTrustLevelUpProvider` StateProvider |
| `band_of_mercenaries/lib/features/investigation/domain/settlement_trust_provider.dart` | `settlementTrustProvider(regionId)` Provider.family |
| `band_of_mercenaries/lib/core/widgets/settlement_trust_up_dialog.dart` | `SettlementTrustUpDialog` 위젯 (RankUpOverlay 패턴 모방, 단계별 색상 매핑) |

### 2.3 build_runner 자동 재생성 (2개)

| 파일 | 사유 |
|------|------|
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.g.dart` | RegionState HiveField 4·5 추가 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart` | ActivityLogType enum 신규 3종 |

---

## 3. 실행 순서 (9단계)

| 단계 | TASK | 내용 | 결과 |
|------|------|------|------|
| 1 | TASK-1·2·3·6·9·10·14 (병렬) | 모델/enum/Provider/시그니처/필터 확장 | 모두 PASS |
| 2 | TASK-5 | build_runner 1차 실행 (5 outputs 재생성, 8.7s) | PASS |
| 3 | TASK-4·12 (병렬) | settlementTrustProvider, SettlementTrustUpDialog | PASS |
| 4 | TASK-7 | RegionStateRepository 메서드 3종 + 상수 맵 + `_grantXpEvenly` | PASS |
| 5 | TASK-8 | ChainQuestService 분기 3종 | PASS |
| 6 | TASK-11 | QuestCompletionService override + settlementTrustGain 필드 | PASS |
| 7 | TASK-13 | QuestListNotifier 통합 (6개 변경) | PASS |
| 8 | TASK-15 | app.dart settlementTrustLevelUp listen | PASS |
| 9 | TASK-16·17 (병렬) | 게임 시작 + 이동 hook | PASS |

---

## 4. 검증 결과

### 4.1 검증 모드: 풀 검증

TASK 수 17개로 풀 검증 모드 적용. verifier(명세 검증)와 flutter-reviewer(품질 리뷰)를 병렬 실행.

### 4.2 verifier 결과: PASS

- REQ-01 ~ REQ-33 모든 요구사항 PASS
- 명세서 결정사항 D-1~D-7 전부 준수 (priority=high, AppTheme 신규 색상 미추가, XP 균등 분배, region 3 한정, override base만 대체)
- Q&A 권장 답변 준수 (Q-1: Repository 직접 Ref 주입, Q-2: settlement_ protagonist 무시, Q-6: setSettlementTrust 보상 우회)
- 호환성: HiveField nullable 추가, typeId 6·8 유지, default값 시그니처 — 기존 호출부 무영향
- `flutter analyze`: PASS (No issues found)
- 테스트: PASS (499/499)

### 4.3 flutter-reviewer 결과: APPROVE (조건부 → 1건 수정 후 APPROVE)

발견된 이슈 1건(HIGH)을 수정 후 APPROVE 확정.

#### HIGH 이슈 (수정 완료)

**`movement_provider.dart` _completeMovement의 RegionState 초기화 무력화**

- 근본 원인: `RegionStateRepository.saveState`(line 42~49)가 기존 객체 존재 시 신규 인자(`settlementTrust:0` 포함)를 버리고 `existing.save()`만 호출
- 영향: 기존 세이브에서 `RegionState`가 있고 `settlementTrust=null`인 경우 `saveState(RegionState(..., settlementTrust:0))` 호출이 무력화되어 `settlementTrust`가 영구 `null` 유지
- 수정: `else if (regionState.settlementTrust == null)` 분기에서 기존 객체 직접 수정 패턴으로 변경 (`regionState.settlementTrust = 0; regionState.settlementTrustLevel ??= 1; await regionState.save();`)
- 수정 후 `flutter analyze` PASS 재확인

#### MEDIUM 이슈 (수정 미수행 — 명세 결정 또는 영향 없음)

| # | 이슈 | 처리 사유 |
|---|------|-----------|
| 1 | `settlementTrustProvider`가 Hive 박스 변경 미감지 | 현재 미사용. 향후 UI watch 필요 시 StreamProvider로 전환 (명세 4.2절 주의사항 명시됨) |
| 2 | Repository에 Ref 직접 주입 (계층 결합) | 명세 Q-1 결정 — `addReputation` 패턴 모방 (단순성 우선). M7+ 다중 거점 확장 시 SettlementTrustService 분리 가능 |
| 3 | `settlementTrustProvider` 데드 코드 | 명세 REQ-05 산출물. 페이즈 4 #4 마을 방문 UI에서 사용 예정 (명세 후속 작업) |
| 4 | `_applyCompletionResult` 메서드 길이 과다 (336줄) | 본 명세 범위 외 리팩토링 권고 |
| 5 | `_trustThresholds` 순회가 Map 삽입 순서 의존 | Dart `LinkedHashMap` 명세상 보장. const Map 리터럴도 동일. 즉각 버그 없음 |

### 4.4 빌드 검증 (최종)

- `flutter analyze`: **No issues found!** (2.2s)
- `flutter test`: **All tests passed! (499/499)**
- build_runner 재실행 1회 (TASK-5): 5 outputs / 8.7s

---

## 5. CLAUDE.md 준수

- 한국어 주석 정책: 신규 코드 모두 한국어 주석 (settlement_ 분기 사유, 일회성 보상 통과 단계 합산 사유 등)
- 의존성 추가 없음 (기존 패키지만 사용)
- Navigator.push 미사용 (다이얼로그는 `showDialog` 단일 표시)
- 신규 폴더 1개 생성: `core/widgets/` (명세에 명시된 경로)

CLAUDE.md 금지사항 위반 없음.

---

## 6. 후속 작업

본 명세 완료 후 다음 작업이 권장됨 (명세 9절):

1. **페이즈 4 SQL 일괄 적용** — 페이즈 4 #1·#2·#3 SQL 마이그레이션 4종 + data_versions 증분
2. **페이즈 4 #4 마을 방문 UI** — `settlementTrustProvider(regionId)` 활용. 약초상/의무실 잠금 정책 + min_trust_level=2 채집 의뢰 노출
3. **회귀 테스트** — 첫 2시간 플레이 시뮬레이션 (0~30분 step 1·2 → 2단계 / 30~60분 step 3·4 → 3단계 / 60~100분 step 5·6 → 4단계 + +500G+200XP+100명성)
4. **ActivityLog UI 색상/아이콘 분화** — 현재는 `chainCompleted`/`chainProgressed`와 동일 매핑 (settlementTrustUp=chainGold/bold, settlementEventStep=primary, settlementEventCompleted=chainGold/bold)
5. **`_applyCompletionResult` 리팩토링** — 메서드 길이 분리 (flutter-reviewer MEDIUM #4)

---

## 7. 산출물

- 변경 파일: 17개 (수정 14 + 신규 3 + build_runner 2)
- 라인 변경: 약 +400 / -50 (정확한 수치는 git diff로 확인)
- 검증 모드: 풀 검증
- 검증 결과: PASS (HIGH 1건 수정 후)
- 빌드/테스트: PASS
