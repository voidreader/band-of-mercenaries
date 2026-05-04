### M4 페이즈 4 #4: 마을 방문 UI + 거점 3종 + 약초상/의무실 분리

- 더스트빌(region 3, sector_type='village') 진입 시 이동 화면 하단에 "마을 내 방문" 영역 신설. 광장 풍문 1줄 + 거점 3종(촌장 집·낡은 대장간·약초상) 카드 메뉴. 거점 진입은 `_selectedFacility` enum 상태 기반 렌더링(Navigator.push 미사용), region 변경 시 자동 리셋.
- **촌장 집**: NPC 헤더(파슨) + 24h 사건 완료 배너(조건부) + 신뢰도 4단계 진행 바 + [상황 듣기]/[신뢰도 확인]/[보상 받기] 3개 버튼. 보상 받기는 자동 지급 안내(페이즈 4 #5 흐름 그대로 유지)로 disabled.
- **낡은 대장간**: NPC 헤더(하겐) + [제작 목표 보기]/[수리 의뢰 확인]/[재료 힌트 보기] 3개 버튼. 단계별 잠금: 1단계 모두 disabled, 2단계 제작 목표·재료 힌트 활성, 3단계 수리 의뢰 활성(50G), 4단계 ×1.2(60G). 수리 의뢰는 `UserData.lastSmithyRepairAt` 24h 쿨다운 stub.
- **약초상 (1회성 즉시 회복)**: NPC 헤더(네리스) + [즉시 회복]/[채집 정보]/[재료 힌트] 3개 버튼. 비용 75/50/45/40G + 쿨다운 45/30/15/10m 곡선. 부상/피로 용병 1명을 즉시 정상 복귀시키며 의무실 자동 회복 타이머도 함께 종료. 의무실 효과는 변경 없음.
- 채집 의뢰(`dustvile_chore_03`) 골드 보상 단계별 ×1.0/×1.1/×1.2 배수 — `QuestCompletionService.calculate(currentTrustLevel)` 시그니처 추가, `quest_provider`가 `regionStateRepository.getSettlementTrust(quest.region).level` 주입.
- 사건 완료(`settlement_3_pyegwang_reopen` step==6) 시 `RegionState.lastEventCompletedAt` 기록 → 24h 동안 모든 거점 화면 상단에 사건 완료 메시지 노출 → 24h 경과 후 4단계 인사말로 복귀.
- 신규 feature 모듈 `features/settlement/` 신설 — `HerbalistService`(정적 서비스 3개 메서드)/`VillageFacility` enum/`SettlementNpcData`(NPC 5명 + 인사말 17개 + 광장 풍문 + 사건 완료 메시지 const 인라인)/거점 화면 4종 + 즉시 회복 다이얼로그.
- `MercenaryRepository.healInstant(mercId)` + `MercenaryListNotifier.healInstant({mercId, cost, cooldownMinutes})` wrapper 추가 — Repository는 단일 책임(상태 normal + 두 endTime null + Hive save), Notifier가 spendGold/setHerbalistCooldown/ActivityLog 일괄 처리.
- `RegionStateRepository.setEventCompleted(regionId)` + `UserDataNotifier.setHerbalistCooldown`/`setSmithyRepairAt` setter 메서드 추가.
- HiveField 추가: `UserData` 22 `herbalistCooldownEndTime`·23 `lastSmithyRepairAt` / `RegionState` 6 `lastEventCompletedAt` + `eventCompletedRecently` getter / `ActivityLogType` 25 `herbalistHeal`·26 `smithyRepairCompleted` (홈 화면 `_logIcon` 매핑 추가).
- 단위 테스트 13건 신규 — `HerbalistService` 비용/쿨다운/배수 10케이스 + `MercenaryRepository.healInstant` Hive 인메모리 흐름 3케이스.
