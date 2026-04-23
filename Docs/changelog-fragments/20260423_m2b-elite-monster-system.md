### M2b: 엘리트 몬스터 시스템

- 리전 `environment_tags` JSONB 컬럼 추가 — 지형/환경 태그로 퀘스트 풀 필터링 지원
- `EliteMonsterData` / `EliteLootTableData` 정적 데이터 모델 추가 (Supabase 동기화 대상 2개 테이블 신규)
- `EliteSpawnService`: 퀘스트 생성 시 리전 티어·환경 태그·난이도 조건으로 엘리트 몬스터 확률 배정
- `EliteLootService`: 드랍 테이블 가중 확률 롤 → 보너스 골드 + 아이템 드랍 계산
- `QuestGenerator` / `QuestCompletionService` 연동 — 엘리트 스폰·완료 처리 통합
- 파견 카드 엘리트 UI: 좌측 색상 사이드바·배지·이름 강조 (보통 🔥 오렌지 / 유니크 ★ 퍼플 2계층)
- 파견 상세 페이지: 엘리트 서사 카드(이름·설명/로어, 그라디언트 배경) 조건부 삽입
- 퀘스트 완료 팝업: 엘리트 드랍 섹션(보너스 골드·아이템 목록) 조건부 표시
