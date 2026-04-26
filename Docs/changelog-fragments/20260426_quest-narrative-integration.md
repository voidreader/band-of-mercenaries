### 퀘스트 서사 통합 (M3 페이즈 4-4)

- 퀘스트 완료 시 `quest_narratives` 88행에서 서사 템플릿을 weight 기반 가중 랜덤 선택 후 TemplateEngine으로 렌더링
- 렌더된 서사를 `ActiveQuest.renderedNarrative`에 저장, `QuestResultDialog` 완료 팝업에 이탤릭 텍스트로 표시
- 활동 로그 메시지에 서사 포함 (`'퀘스트 "이름" 결과! — 서사'` 포맷)
- `{quest.enemy}` 변수 지원 — 일반 퀘스트: `quest_pools.enemy_name` 필드, 엘리트: 몬스터 이름, null 시 `"적"` fallback
- 엘리트 퀘스트 전용 서사 8행 분리 적용 (`is_elite` 매트릭스)
- `AppTheme.elite*` 색상 상수 6개 추가 — `dispatch_screen`, `dispatch_detail_page`, `quest_result_dialog` 색상 리터럴 통일
- `QuestResultDialog` `_build*` 헬퍼 메서드 → `_EliteLootSection`, `_MercStatusRow`, `_RewardRow` StatelessWidget 추출
