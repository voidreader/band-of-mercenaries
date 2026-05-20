### M8b 페이즈 4 #4 — 전투 보고서 UI 확장

- `QuestResultDialog._buildDetailView`에 `CombatReport.schemaVersion == 1` 분기 추가. M8b 시뮬레이션 보고서는 라운드 로그 섹션을 인라인 표시, M8a 보고서는 기존 details + Chip Wrap 유지.
- `_CombatReportRoundLogSection` / `_RoundCard` / `_ActionLine` 3종 private widget 추가. lineBudget(4~8) 압축 정책으로 최대 8라운드 핵심 액션만 노출.
- 5 위치 분류(entry/development/crisis/resolution/aftermath) 별 보더 색상 차등. crisis → `dangerTension`, resolution → `chainGold`.
- `exitCondition` 6종 한국어 라벨 + `objectiveProgress` LinearProgressIndicator 표시 (호위/탐험 의뢰 한정 유효).
- protagonist Chip: 테두리 `chainGold` + `FontWeight.w700` 강화.
- decisive 배지: `combatReportKeywords.displayText` lookup 우선, 미발견 시 '결정적 장면' fallback.
- `damageRoll` / HP 절대값 / rate% 등 전투 수치 UI 비노출 유지 (§4.4 정합).
- 위젯 테스트 9개 추가 (`test/features/quest/view/quest_result_dialog_test.dart`). M8a 호환·M8b 분기·lineBudget·decisive·비노출 항목·fallback 안정성 검증.
