### M8a 마일스톤 종료 — 정적 데이터 정책·통합 회고·Supabase 마이그레이션 적용

- `SyncService.allTables`가 37 테이블로 확장(M8a 신규 5). `optionalTables` Set으로 후속 마일스톤의 점진적 스키마 적용을 지원 — 빈 캐시 = fail-soft 빈 데이터로 동작하며 앱 기동을 막지 않는다.
- M8a 페이즈 4 #1 Supabase 마이그레이션 5건 적용 — `faction_contacts` 3행·`faction_reactions` 33행·`faction_shop_items` 18행 신규 테이블 + RLS + 인덱스 + `quest_pools` +12 / `items` +17 / `crafting_recipes` +2 / `titles` +2 행 추가 + `titles.hook_type`·`quest_pools.named_hook_type` CHECK 확장 + `data_versions` 5행(신규 3 + 기존 4 v+1).
- M8a 완료 기준 9개 모두 충족 — 대표 3 세력 생활권 연결 / 위업·신뢰·칭호·지역 상태 조건 지명 의뢰 / 상점 제작 연결 / 보상 위상·지역 영향 / 전투 보고서 5 트리거 저장 / 요약·상세 구분 / 영속 / MVP 완결성 / M1~M7 회귀 0.
- 빌드 검증 — `flutter analyze` 0 issues, `flutter test` 578 PASS(회귀 0건).
- 페이즈 1~4 산출물 16개와 `state.md`를 `Docs/Archive/20260519_m8a_faction_combat_report/`로 이관 정리. 마일스톤 상태 `archived`.
- 후속 백로그(M8b 진입 시 처리): operation-bom `table-config.ts` 일괄 등록(17 → 30+ 테이블), 보고서 장기 재열람 박스, MercenarySnapshot 이름 동결, 14세력 점진 확장, 턴 기반 전투 시뮬레이터.
