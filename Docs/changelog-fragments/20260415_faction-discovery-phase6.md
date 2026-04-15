### 세력 발견 시스템 (World Expansion Phase 6)

- 지역 조사 완료 시 세력 단서(`faction_clue`) 발견 흐름 추가 — clue_level 1~3 단계별 정보 공개
- 하단 탭 6번째를 설정에서 정보 탭으로 교체, 설정은 홈 화면 상단 아이콘 버튼으로 이전
- 세력 도감 화면 신설 — 발견된 세력 목록(별 진행도), 세력 상세(description/philosophy/tierRange 단계별 공개)
- 조사 완료 팝업에 단서 인라인 표시 및 "도감에서 확인" 버튼 추가 (자동 스크롤 연동)
- `factionStates` Hive 박스 신설 (FactionState typeId:9, FactionClueRecord typeId:10)
- Supabase `factions` 테이블 동기화 대상 추가 (18번째 테이블)
