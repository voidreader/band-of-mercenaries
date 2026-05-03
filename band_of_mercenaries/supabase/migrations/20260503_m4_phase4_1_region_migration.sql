-- ============================================================================
-- M4 페이즈 4 #1: 199 → 40 region 마이그레이션 + 시작 거점 고정
-- ============================================================================
-- 생성일: 2026-05-03
-- 마일스톤: M4 (40 리전 재설계 + 시작 거점 고정)
-- 출처 명세: Docs/spec/M4/[spec]20260503_m4-region-migration.md
-- 데이터 소스: Docs/content-design/[content]20260503_region-40-redesign.md
-- 선행 조건: Docs/content-data/postponed_regions_dump.json 추출 완료 가정 (rollback 가능)
-- 단일 트랜잭션: 부분 실패 시 BEGIN/COMMIT 안의 모든 변경이 롤백된다.
-- ============================================================================

BEGIN;

-- §1. region_discoveries 정리 — 살아남지 못한 region 참조 행 삭제
DELETE FROM region_discoveries
WHERE region_id NOT IN (
  3, 31, 127,
  9, 10, 20, 23, 146,
  5, 38, 49, 50, 51, 52, 65,
  13, 16, 21, 24, 28, 35,
  1, 25, 67, 90, 105,
  17, 36, 62, 84,
  44, 56, 115, 154,
  4, 18, 47,
  7, 11
);

-- §2. 159개 region 삭제 (200은 INSERT 전이므로 NOT IN에 포함해도 무영향)
DELETE FROM regions
WHERE region NOT IN (
  3, 31, 127,
  9, 10, 20, 23, 146,
  5, 38, 49, 50, 51, 52, 65,
  13, 16, 21, 24, 28, 35,
  1, 25, 67, 90, 105,
  17, 36, 62, 84,
  44, 56, 115, 154,
  4, 18, 47,
  7, 11,
  200
);

-- §3. 더스트플레인 region 3 재태깅 (plains → mountain)
UPDATE regions
SET region_name = '더스트플레인',
    environment_tags = '["mountain"]'::jsonb,
    description = '광산을 품은 변방 산악 지역. 신참 용병들이 첫 발을 떼는 곳.'
WHERE region = 3;

-- §4. T9 region 200 신규 INSERT
INSERT INTO regions (continent, region, region_tier, region_name, recommend_power, environment_tags, description)
VALUES (1, 200, 9, '망각의 수면', 380,
        '["underground"]'::jsonb,
        'T8 마계경계와 T10 심연 사이의 깊이. 시간이 멈춘 듯한 수면이 펼쳐져 있다. (M9 종속 시스템 확장 예정)');

-- §5. factions tier_range 검증 (1..10 범위 강제, 실패 시 트랜잭션 롤백)
DO $$
DECLARE
  invalid_count INT;
BEGIN
  SELECT COUNT(*) INTO invalid_count
  FROM factions
  WHERE EXISTS (
    SELECT 1 FROM jsonb_array_elements(tier_range) elem
    WHERE (elem::int) > 10 OR (elem::int) < 1
  );
  IF invalid_count > 0 THEN
    RAISE EXCEPTION 'factions.tier_range 검증 실패: % 행이 1..10 범위를 벗어남', invalid_count;
  END IF;
END $$;

-- §6. data_versions 갱신 (클라이언트 증분 동기화 트리거)
UPDATE data_versions SET version = version + 1, updated_at = NOW() WHERE table_name = 'regions';
UPDATE data_versions SET version = version + 1, updated_at = NOW() WHERE table_name = 'region_discoveries';

COMMIT;
