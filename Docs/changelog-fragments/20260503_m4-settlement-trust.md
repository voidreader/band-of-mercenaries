### M4 페이즈 4 #5: 마을 신뢰도 시스템 + 거점 사건 활성화 + 페이즈 4 #3 stub 해제

- 더스트빌(region 3) 마을 신뢰도 시스템 도입 — 의뢰 완료로 신뢰도가 누적되며 4단계(의심/인지/친근/소속)로 승급. 임계값 30/80/200점, 단계 진입 시 일회성 보상(2단계 +100G+50XP / 3단계 +200G+100XP / 4단계 +500G+200XP+100명성). XP는 살아있는 용병에 균등 분배.
- 일반 의뢰 신뢰도 점수 — region 3 + 일반 의뢰(체인/세력 태그 제외) + 성공/대성공 시 난이도별 2/3/5/0/0점 누적.
- 거점 사건 라인 "폐광길 재개방" 6단계 활성화 (`settlement_3_pyegwang_reopen`) — `trust_threshold` 단계별 노출, `duration_override_seconds`(300~600s)/`reward_gold_override`/`trust_reward_override`(10~100점)로 일반 의뢰 보상 곡선과 분리.
- 단계 승급 시 단계별 색상 + 일회성 보상 요약 다이얼로그(`SettlementTrustUpDialog`) 표시. 4단계 진입 시 명성 +100으로 인한 랭크업 발생 시 critical(rankUp) → high(trustUp) → high(chainCompleted) 순으로 dialog 큐 직렬화.
- `RegionState` HiveField 4·5 (`settlementTrust`/`settlementTrustLevel`) 추가 + null fallback getter — 기존 세이브 호환 보장.
- `RegionStateRepository`에 `addSettlementTrust`/`getSettlementTrust`/`setSettlementTrust` 3개 메서드 + 임계값/보상/단계명 상수 맵.
- `TrustLevelUpEvent` + `settlementTrustLevelUpProvider` StateProvider + `settlementTrustProvider` Provider.family 신규.
- `ChainQuestService.tryActivateSettlement` 메서드 추가 + `checkDormant` settlement_ prefix skip(14일 미적용) + `onStepCompleted` protagonist resolution skip.
- `QuestCalculator`(`rewardGoldOverride`/`durationOverrideSeconds`/`isFixedWithDurationOverride`) + `ExperienceService`(`rewardXpBonusOverride`) 시그니처 확장 — `is_fixed=true` 행은 baseReward·rewardMultiplier·trackBonus 등 기존 보상 경로 우회.
- `QuestCompletionService.calculate`에 pool 조회 + override 인자 전달 + `QuestCompletionResult.settlementTrustGain` 필드 추가.
- `QuestListNotifier`: `_getCurrentTrustLevel` stub 해제(`getSettlementTrust(region).level`로 교체) + `dispatch` override 적용 + `_injectFixedSettlementQuest` 중복 방어(`_load()` 선행) + `_refreshExpiredQuests` 가독성 개선(이중 필터 제거) + `_applyCompletionResult`에 settlement_ step 신뢰도 누적 + 일반 의뢰 신뢰도 점수 분기 추가.
- `ActivityLogType` HiveField 22~24 (`settlementTrustUp`/`settlementEventStep`/`settlementEventCompleted`) + 홈 화면 `_logIcon` 매핑 추가.
- `DialogTypeRegistry.settlementTrustUp` 키 추가(8종) + `app.dart`에 listen 블록 + dialogQueue high priority enqueue.
- `ChainTopSection` `actives` 필터에 `!chainId.startsWith('settlement_')` 추가 — 거점 사건은 일반 목록의 settlementTier로만 노출(페이즈 4 #3 후속 권고 #1).
- 게임 시작(`UserDataNotifier.initializeNewGame`) + region 3 진입(`MovementNotifier._completeMovement`) 시 자동 RegionState 초기화 + `tryActivateSettlement` 호출. 기존 세이브에서 `settlementTrust=null`인 경우 기존 객체 직접 수정 패턴(`saveState` 우회)으로 마이그레이션.
