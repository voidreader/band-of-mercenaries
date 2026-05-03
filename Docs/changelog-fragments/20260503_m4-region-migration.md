### M4 데이터 마이그레이션 + 시작 거점 고정

- 199개 리전을 40개로 축소(보존 39 + T9 신규 region 200). 삭제 160개 리전과 종속 region_discoveries 15행은 dump JSON으로 rollback 가능 보관.
- 시작 거점을 더스트플레인(region 3) sector 1로 고정. 기존 random Tier 1 부여 로직 제거.
- 시작 골드 500G → 200G 하향. baseQuestCount 5 → 6 상향(시작 의뢰 슬롯 6개 정책 정합).
- 살아남지 못한 리전을 참조하는 기존 세이브는 자동 복구 — `regionStates` 박스 정리, `UserData.region`을 region 3으로 강제 이동, `factionStates.clueRecords`에서 무효 단서 삭제.
- `GameConstants.sectorCount`를 `@Deprecated` 마킹(M4 페이즈 4 #2에서 region_sectors.sector_count 동적 조회로 대체 예정).
