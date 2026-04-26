### M3 공존 정책 후속 정리 — 트레잇 진화 domain 이전 / 정렬 메모이제이션 / 다이얼로그 dismiss 일관성

- 트레잇 진화 적용 로직(Repository 호출/트레잇 이름 lookup/ActivityLog 기록/refresh)을 view에서 `MercenaryListNotifier.applyEvolution()`으로 이전. dispatch_screen은 위젯 위임 한 줄로 단순화
- `EvolutionChoice` 데이터 클래스를 view → domain 레이어로 이동 (`features/mercenary/domain/evolution_choice.dart`)
- 파견 화면 정렬을 `sortedPendingQuestsProvider`(derived Provider)로 메모이제이션. 1초 주기 `gameTickProvider`로 매 tick 정렬 재계산되던 비용 제거. 세력 가입/탈퇴(`factionRefreshProvider`) + 지역 변형(`currentRegionSectorChangesProvider`) 시 자동 무효화
- 다이얼로그 큐 5개 채널(건설·조사·랭크업·체인 완주·지역 변형) dismiss 책임 일원화: `enqueue` 직후 즉시 `state = null` 호출, builder/onDismiss 콜백은 `dismiss` 단순 참조만 수행
- `InvestigationResultDialog`의 누락된 state 리셋 보완 (재발화 위험 제거)
- 동작 변경 없음 (사용자 시각 동일성 보장 — 정렬 결과·진화 메시지·다이얼로그 표시 시퀀스 모두 동일)
