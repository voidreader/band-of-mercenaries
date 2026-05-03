### M4 region_sectors 신규 테이블 + 섹터 데이터 기반 렌더링

- regions.sector_count 컬럼 신설(1~6 가변, 기본 4). 4개 거점급 region(1·23·127·146)은 5섹터로 승격. 기존 하드코딩된 10섹터 그리드 제거 + region별 동적 렌더링.
- region_sectors 정규화 테이블 신설(sector_index 1-based, sector_type 5종 — village/ruins/hidden/dungeon/field). 데이터 시드는 후속 페이즈 위임.
- 더스트플레인(시작 거점) 4섹터를 코드 fallback 상수로 인라인 — 더스트빌(village)·폐광(dungeon)·마른 초원(field)·먼지로 덮인 길(field). 시드 미배포 상태에서도 시작 거점 진입 보장.
- MovementScreen 그리드에 dungeon ⛏️ / field 🌾 신규 시각 마커 추가(LayerSidebar·QuestCardBadges는 기존 변형 3종 정책 보존).
- region_discoveries 3행 sector_index 재매핑 SQL — region 18·23·146의 transform hidden 데이터 정합성 확보.
- GameConstants.sectorCount stub 상수 완전 제거 — region.sectorCount 동적 조회로 일괄 마이그레이션.
- 기존 세이브 자동 복구 — RegionMigrationService에 sectorCount 초과 sectorChanges 키 정리 단계 추가(별도 멱등성 플래그 `region_sector_count_v1`로 1회 실행).
