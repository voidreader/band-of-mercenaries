### 이동 선택지 시스템 (M3 페이즈 4-5)

- 이동 완료 시 확률 기반으로 선택지 이벤트 발생 — `P = min(base + coeff × distance, 0.30)`, 리전 티어별 coeff 조정
- `TravelChoiceRecallDialog` 2단계 팝업: 상황 서사 + 선택지 → 결과 서사 + 효과 요약
- 선택지 3종 risk_level (safe/risky/hidden) + `visibility_expr` TemplateEngine 평가로 숨겨진 선택지 조건부 노출
- 결과 8종 효과: gold_gain/gold_loss/xp_gain/reputation_gain/reputation_loss/trait_learning_boost/item_drop/trait_innate
- `UserData.choiceEventId` HiveField(21) — 앱 재시작 시에도 미표시 선택지 이벤트 보존
- `travel_choice_events` / `travel_choice_options` / `travel_choice_results` 정적 테이블 3개 Supabase 동기화 추가
- `TravelChoiceService` 순수 서비스 (5개 static 메서드) + 단위 테스트 19개
