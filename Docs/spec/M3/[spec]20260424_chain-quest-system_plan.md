# 구현 계획서

Skill used : implement-agent

---

## 명세서

`Docs/spec/M3/[spec]20260424_chain-quest-system.md`

---

## 요구사항 분해

| 코드 | 내용 | 구현 상태 |
|------|------|----------|
| FR-1 | 지역 조사 완료 시 hidden_quest 트리거로 체인 활성화 | PASS |
| FR-2 | 주인공 선정 (1단계 첫 성공 시, quest_type별 partyPower 기여도 최고 용병) | PASS |
| FR-3 | 파견 화면 최상단 ChainStepCard 고정 (이동/대기/휴면 오버레이) | PASS |
| FR-4 | 단계 완료 처리 (성공=currentStep++/delay, 실패=failureCount++) | PASS |
| FR-5 | 주인공 사망률 50% 감소, "🛡️ 주인공의 운명" 배지 항상 표시 | PASS |
| FR-6 | 최종 단계 진입 직전 canAdvanceToFinal 체크 + 차단 모달 | PASS |
| FR-7 | 체인 완주 처리 (평판 보너스, completedChains 추가, 완주 팝업) | PASS |
| FR-8 | 주인공 폴백 (사망/방출 시 partyMercs→allMercs 재지정 + 교체 로그) | PASS |
| FR-9 | 14일 비활동 휴면 전환, 탭하여 재활성화 | PASS |
| FR-10 | ActiveQuest HiveField 21~23 (isChainStep/chainId/chainStep) | PASS |
| FR-11 | TemplateEngine으로 description 렌더 (완주 팝업) | PASS |
| FR-12 | completedChains 중복 완주 차단 | PASS |

---

## 변경 파일 목록

### 신규 생성

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `lib/core/models/chain_quest_data.dart` | 신규 | Freezed 정적 모델, chain_quests 테이블 매핑 |
| `lib/features/chain_quest/domain/chain_quest_progress.dart` | 신규 | HiveType(typeId:13) ChainQuestProgress, HiveType(typeId:14) ChainQuestStatus |
| `lib/features/chain_quest/domain/chain_quest_service.dart` | 신규 | ChainQuestService 순수 서비스 + ChainCompletedEvent |
| `lib/features/chain_quest/domain/chain_quest_provider.dart` | 신규 | 4개 Provider (service/progress/activeChain/chainCompleted) |
| `lib/features/chain_quest/data/chain_quest_repository.dart` | 신규 | ChainQuestRepository (Hive CRUD + watchAll Stream) |
| `lib/features/chain_quest/view/chain_step_card.dart` | 신규 | ChainStepCard ConsumerWidget + _ChainStepCardContent + _ChainStepCardOverlay |
| `lib/features/chain_quest/view/chain_completed_dialog.dart` | 신규 | ChainCompletedDialog ConsumerWidget (TemplateEngine 적용, onDismiss) |

### 수정

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `lib/core/models/user_data.dart` | 수정 | HiveField(20) completedChains: List<String> + completedChainSet getter |
| `lib/features/quest/domain/quest_model.dart` | 수정 | HiveField(21~23) isChainStep/chainId/chainStep, isChainQuest getter |
| `lib/core/domain/activity_log_model.dart` | 수정 | HiveField(18~20) regionTransform/chainProgressed/chainCompleted |
| `lib/core/data/sync_service.dart` | 수정 | 'chain_quests' 테이블 동기화 추가 |
| `lib/core/providers/static_data_provider.dart` | 수정 | StaticGameData.chainQuests 추가 |
| `lib/core/data/hive_initializer.dart` | 수정 | ChainQuestStatusAdapter(14)/ChainQuestProgressAdapter(13) 등록, chainQuestProgress 박스 open |
| `lib/core/providers/game_state_provider.dart` | 수정 | addCompletedChain() async 메서드 추가 |
| `lib/features/quest/domain/quest_calculator.dart` | 수정 | mercPower() static 헬퍼 추가 |
| `lib/features/quest/domain/quest_completion_service.dart` | 수정 | isChainStep 파라미터 + 사망률 0.5 감소 |
| `lib/features/quest/domain/quest_provider.dart` | 수정 | onStepCompleted 호출 + injectChainStep + async 콜백 |
| `lib/features/investigation/domain/investigation_notifier.dart` | 수정 | hidden_quest 분기 추가 |
| `lib/app.dart` | 수정 | chainCompletedProvider listen + checkDormant 후크 + onDismiss 패턴 |
| `lib/features/quest/view/dispatch_screen.dart` | 수정 | ChainStepCard 최상단 삽입 |
| `test/features/inventory/view/inventory_screen_test.dart` | 수정 | chainQuests: const [] 추가 |
| `test/features/quest/domain/quest_completion_service_test.dart` | 수정 | chainQuests: const [] 추가 |

---

## 설계 결정

### Hive typeId
- 명세서 §4.2는 typeId 11/12를 명시했으나, InventoryItem(M2a)이 11을 선점
- ChainQuestProgress=13, ChainQuestStatus=14로 조정 (충돌 없음)

### UserData.completedChains 타입
- 명세 Set<String> → 구현 List<String> + completedChainSet getter
- Hive Set 어댑터 호환성 이슈 회피, 기능 동일

### ChainQuestService 의존성 역전
- 순수 서비스 (Ref 직접 의존 없음)
- logActivity/addReputation/addCompletedChain/publishCompleted 콜백으로 호출처에 의존성 역전

### TemplateEngine 적용
- ChainCompletedDialog를 ConsumerWidget으로 변환
- templateEngineProvider + TemplateContext(user, merc=protagonist, region) 구성
- render()로 finalDescription 치환 후 렌더

---

## 검증 모드

**풀 검증** (TASK 수 ≥ 3): verifier + flutter-reviewer 병렬 실행

| 라운드 | verifier | flutter-reviewer | 결과 |
|--------|----------|-----------------|------|
| Round 1 | FAIL | BLOCK | 8건 수정 |
| Round 2 | FAIL | BLOCK | 12건 수정 |
| Round 3 | — | — | 빌드 PASS, 테스트 425/425 |

### 수정된 이슈

**Round 1** (배치 1):
- onChainCompleted void → Future<void> 콜백 변환
- tryActivate activeProgresses 파라미터 제거 (내부 repo 조회로 변경)
- onStepCompleted allMercs 파라미터 + resolveProtagonist 연결
- InvestigationNotifier data 레이어 직접 접근 제거

**Round 1** (배치 2):
- quest_provider.dart allMercs 파라미터 전달
- ChainStepCard ref.watch 조건부 호출 최상단 이동
- app.dart unawaited() 명시
- chain_quest_provider.dart spread copy 정렬

**Round 2**:
- ChainCompletedEvent.protagonistMercId 추가
- completeChain addReputation/addCompletedChain async 콜백
- onStepCompleted 주인공 폴백 로직 (step>1, 생존 용병 fallback, 교체 로그)
- chain_step_card.dart: _buildCard 타입 명시, _ChainStepCardContent/_ChainStepCardOverlay 추출
- chain_step_card.dart: canAdvanceToFinal 최종 단계 진입 전 체크 + 차단 모달
- chain_step_card.dart: "🛡️ 주인공의 운명" 배지 항상 표시
- ChainCompletedDialog ConsumerWidget + TemplateEngine 렌더
- app.dart chainCompleted 리스너 onDismiss 패턴 적용
- chain_quest_repository.dart distinct() 제거

---

## build_runner 재실행 필요

- `chain_quest_data.dart` (freezed + json_serializable 모델)
- `chain_quest_progress.dart` (hive_generator)

명령어:
```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```
