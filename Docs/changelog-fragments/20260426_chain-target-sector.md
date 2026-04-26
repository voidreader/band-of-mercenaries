### M3 체인 퀘스트 섹터 단위 하이라이트 — chain_quests.target_sector_id 추가

- Supabase `chain_quests` 테이블에 `target_sector_id INTEGER NULL` 컬럼 추가 (1-based 1..10). `data_versions.chain_quests` version 1→2 갱신
- `ChainQuestData` freezed 모델에 `targetSectorId` 필드 추가, build_runner 재생성
- MovementScreen이 `chainTargetRegionIds`(Set) → `chainTargetSectors`(`Map<int, Set<int?>>`)로 자료구조 확장. `null in set` 시 region 전체 fallback, `sector in set` 시 해당 섹터 타일만 금색 테두리/배지 표시
- 기존 24개 chain_quest 단계는 모두 `targetSectorId == null` 상태이므로 region 단위 하이라이트로 동작 동일 (시각적 변경 없음)
- CSV(`Docs/content-data/[chain-quest]20260424_m3-chains.csv`) 헤더에 `target_sector_id` 컬럼 추가, 24행은 빈 값 유지 (콘텐츠 입력은 후속 sprint)
