-- M4 페이즈 4 #3: quest_pools 컬럼 확장 + 더스트빌 고정 의뢰 데이터
-- 작성일: 2026-05-03
-- 명세서: Docs/spec/M4/[spec]20260503_m4-fixed-quest-system.md
-- 선행 조건: 20260503_m4_phase4_2_region_sectors.sql 적용 완료
-- 단일 트랜잭션. 실패 시 전체 롤백.

BEGIN;

-- §1. quest_pools 신규 컬럼 9개 추가 (REQ-01)
-- 페이즈 1 #4 컬럼 4개
ALTER TABLE quest_pools ADD COLUMN is_fixed BOOL NOT NULL DEFAULT false;
ALTER TABLE quest_pools ADD COLUMN fixed_chain_id TEXT NULL;
ALTER TABLE quest_pools ADD COLUMN fixed_step INT NULL CHECK (fixed_step BETWEEN 1 AND 20);
ALTER TABLE quest_pools ADD COLUMN trust_threshold INT NULL CHECK (trust_threshold BETWEEN 1 AND 4);

-- 페이즈 2 #4 컬럼 4개 (보상/시간 override)
ALTER TABLE quest_pools ADD COLUMN reward_gold_override INT NULL;
ALTER TABLE quest_pools ADD COLUMN reward_xp_bonus_override INT NULL;
ALTER TABLE quest_pools ADD COLUMN duration_override_seconds INT NULL;
ALTER TABLE quest_pools ADD COLUMN trust_reward_override INT NULL;

-- 페이즈 2 #3 컬럼 1개 (단계별 노출 제어)
ALTER TABLE quest_pools ADD COLUMN min_trust_level INT NOT NULL DEFAULT 0;

-- §2. UNIQUE 제약: 동일 chain의 동일 step 중복 방지 (is_fixed=true 행 한정)
-- is_fixed=false 행은 fixed_chain_id/fixed_step이 null이므로 제약 적용 안 됨
CREATE UNIQUE INDEX idx_quest_pools_fixed_chain_step
  ON quest_pools (fixed_chain_id, fixed_step)
  WHERE is_fixed = true;

-- §3. dustvile_pyegwang_reopen 6단계 INSERT (REQ-10)
-- 기획 근거: [content]20260503_settlement-trust-and-fixed-events.md 2.2절 + [balance]20260503_fixed-quest-curve.md 조정 1~6
INSERT INTO quest_pools (
  id, name, type, difficulty,
  min_region_diff, max_region_diff,
  type_id, sector_type,
  is_fixed, fixed_chain_id, fixed_step, trust_threshold,
  reward_gold_override, reward_xp_bonus_override,
  duration_override_seconds, trust_reward_override,
  min_trust_level, enemy_name,
  description
) VALUES
  -- step 1: 폐광 입구 정찰 (explore Lv1, dungeon)
  -- duration 300s=5분, 신뢰도 +10, 골드 기본 80G (override null)
  ('qp_pyegwang_step1', '폐광 입구 정찰', 0, 1,
   1, 1,
   'explore', 'dungeon',
   true, 'settlement_3_pyegwang_reopen', 1, 1,
   NULL, NULL,
   300, 10,
   1, '박쥐 떼',
   '촌장의 부탁. 오래 방치된 폐광 입구를 살펴보고 진입 가능 여부를 보고한다. 박쥐 떼와 대치할 수 있다.'),

  -- step 2: 도굴꾼 흔적 추적 (hunt Lv1, field)
  -- duration 300s=5분, 신뢰도 +15, 골드 기본 120G (override null)
  ('qp_pyegwang_step2', '도굴꾼 흔적 추적', 0, 1,
   1, 1,
   'hunt', 'field',
   true, 'settlement_3_pyegwang_reopen', 2, 1,
   NULL, NULL,
   300, 15,
   1, '도굴꾼 일당',
   '폐광 주변에서 발견된 수상한 흔적을 마른 초원까지 추적한다. 도굴꾼들이 외곽에 숨어 있는 것으로 보인다.'),

  -- step 3: 박쥐 둥지 소탕 (raid Lv2, dungeon)
  -- duration 360s=6분, 신뢰도 +20, 골드 200G override (+50 보너스)
  ('qp_pyegwang_step3', '박쥐 둥지 소탕', 0, 2,
   1, 1,
   'raid', 'dungeon',
   true, 'settlement_3_pyegwang_reopen', 3, 2,
   200, NULL,
   360, 20,
   2, '거대 박쥐 둥지',
   '폐광 내부에 자리 잡은 거대 박쥐 둥지를 소탕한다. 처음으로 폐광 깊숙이 들어가는 위험한 임무.'),

  -- step 4: 광부의 도구 회수 (escort Lv2, dungeon)
  -- duration 300s=5분, 신뢰도 +25, 골드 185G override (+50 보너스)
  ('qp_pyegwang_step4', '광부의 도구 회수', 0, 2,
   1, 1,
   'escort', 'dungeon',
   true, 'settlement_3_pyegwang_reopen', 4, 2,
   185, NULL,
   300, 25,
   2, '무너진 갱도',
   '마을 노인이 폐광에 두고 온 도구를 찾기 위해 동행한다. 무너진 갱도를 헤쳐 나가야 한다.'),

  -- step 5: 갱도 안전 확보 (raid Lv3, dungeon)
  -- duration 600s=10분, 신뢰도 +30, 골드 270G override (+50 보너스)
  ('qp_pyegwang_step5', '갱도 안전 확보', 0, 3,
   1, 1,
   'raid', 'dungeon',
   true, 'settlement_3_pyegwang_reopen', 5, 3,
   270, NULL,
   600, 30,
   3, '갱도 깊숙한 위협',
   '폐광 재개방 전 마지막 안전 확보 작업. 무너진 갱도를 보강하고 잔여 위협을 제거한다.'),

  -- step 6: 폐광 재개방식 (survey Lv3, village)
  -- duration 600s=10분, 신뢰도 +100, 골드 500G override (survey base_reward=0 우회), XP +50 보너스
  ('qp_pyegwang_step6', '폐광 재개방식', 0, 3,
   1, 1,
   'survey', 'village',
   true, 'settlement_3_pyegwang_reopen', 6, 3,
   500, 50,
   600, 100,
   3, NULL,
   '마을 광장에서 열리는 폐광 재개방식을 안전하게 진행한다. 마을 전체가 지켜보는 클라이맥스 임무.');

-- §4. dustvile_chore_NN 허드렛일 10건 INSERT (REQ-10)
-- 기획 근거: [balance]20260503_chore-quest-economy.md 2절 허드렛일 풀 컨셉
-- 모두 difficulty=1, min_region_diff=1, max_region_diff=1 (더스트플레인 T1 한정)
-- min_trust_level=0 (기본, 모든 단계에서 노출) 단, dustvile_chore_03만 min_trust_level=2
INSERT INTO quest_pools (
  id, name, type, difficulty,
  min_region_diff, max_region_diff,
  type_id, sector_type,
  is_fixed, min_trust_level,
  enemy_name, description
) VALUES
  -- 1: 짐 나르기 (labor, 마을 내)
  ('dustvile_chore_01', '짐 나르기', 0, 1,
   1, 1,
   'labor', NULL,
   false, 0,
   NULL, '마을 광장에서 약초상까지 무거운 짐을 옮긴다. 단순하지만 마을 사람들이 바라보고 있다.'),

  -- 2: 야간 순찰 (labor, 마을 외곽)
  ('dustvile_chore_02', '야간 순찰', 0, 1,
   1, 1,
   'labor', NULL,
   false, 0,
   NULL, '더스트빌 외곽을 야간에 순찰한다. 특별히 위험한 일은 없지만 마을 사람들에게 안심감을 준다.'),

  -- 3: 약초 채집 (labor, 마른 초원) — herbalist_gathering 채집 의뢰 / min_trust_level=2 (신뢰도 2단계부터 노출)
  -- 주의: 채집 의뢰 식별을 위해 별도 tags JSONB 컬럼 없이 ID prefix 'dustvile_chore_03'으로 식별
  -- 페이즈 4 #4에서 약초상 UI에 herbalist_gathering 배수 적용 시 이 ID를 참조
  ('dustvile_chore_03', '약초 채집 (마른 약초)', 0, 1,
   1, 1,
   'labor', 'field',
   false, 2,
   NULL, '마른 초원에서 약초를 채집한다. 약초상이 원하는 재료를 가져오면 추가 보상을 받는다.'),

  -- 4: 실종자 수색 (labor, 폐광 입구 부근)
  ('dustvile_chore_04', '실종자 수색', 0, 1,
   1, 1,
   'labor', 'dungeon',
   false, 0,
   NULL, '폐광 입구 부근에서 사라진 마을 주민을 수색한다. 구체적인 흔적은 없지만 마을이 불안해하고 있다.'),

  -- 5: 도적 흔적 조사 (labor, 먼지로 덮인 길)
  ('dustvile_chore_05', '도적 흔적 조사', 0, 1,
   1, 1,
   'labor', 'field',
   false, 0,
   NULL, '외부로 통하는 산길에서 도적의 흔적을 확인한다. 아직 위협적이지는 않지만 촌장이 걱정하고 있다.'),

  -- 6: 잡동사니 회수 (labor, 폐광 입구)
  ('dustvile_chore_06', '잡동사니 회수', 0, 1,
   1, 1,
   'labor', 'dungeon',
   false, 0,
   NULL, '폐광 입구에 버려진 잡동사니를 회수한다. 광산 도구 일부가 재활용될 수 있다고 한다.'),

  -- 7: 길 안내 (escort, 마른 초원→마을)
  ('dustvile_chore_07', '길 안내', 0, 1,
   1, 1,
   'escort', 'field',
   false, 0,
   NULL, '마른 초원에서 더스트빌로 들어오는 광물상을 안전하게 안내한다. 길이 험해 길잡이가 필요하다.'),

  -- 8: 동굴 입구 조사 (explore, 폐광 입구 외부)
  ('dustvile_chore_08', '동굴 입구 조사', 0, 1,
   1, 1,
   'explore', 'dungeon',
   false, 0,
   NULL, '폐광 입구 외부를 조사한다. 안으로 들어가지 않아도 되는 간단한 외부 점검 임무.'),

  -- 9: 우물 점검 (explore, 마을 내)
  ('dustvile_chore_09', '우물 점검', 0, 1,
   1, 1,
   'explore', NULL,
   false, 0,
   NULL, '마을 공동 우물의 안전을 점검한다. 최근 물맛이 이상하다는 민원이 들어왔다.'),

  -- 10: 늑대 떼 처치 (hunt, 마른 초원)
  ('dustvile_chore_10', '늑대 떼 처치', 0, 1,
   1, 1,
   'hunt', 'field',
   false, 0,
   '마른 초원 늑대 무리', '마른 초원에 출몰하는 늑대 떼를 처치한다. 마을 외곽 농가가 피해를 입고 있다.');

-- §5. data_versions 갱신 (REQ-11)
UPDATE data_versions SET version = version + 1, updated_at = NOW() WHERE table_name = 'quest_pools';

-- §6. 검증 ASSERT
-- is_fixed=true 행 수 확인 (6행이어야 함)
DO $$
DECLARE fixed_count INT;
BEGIN
  SELECT COUNT(*) INTO fixed_count FROM quest_pools WHERE is_fixed = true;
  IF fixed_count < 6 THEN
    RAISE EXCEPTION 'is_fixed=true 행이 6개 미만 — INSERT 실패 가능성';
  END IF;
END $$;

-- (fixed_chain_id, fixed_step) UNIQUE 제약 만족 확인
DO $$
DECLARE dup_count INT;
BEGIN
  SELECT COUNT(*) INTO dup_count
  FROM (
    SELECT fixed_chain_id, fixed_step, COUNT(*) as cnt
    FROM quest_pools
    WHERE is_fixed = true
    GROUP BY fixed_chain_id, fixed_step
    HAVING COUNT(*) > 1
  ) dup;
  IF dup_count > 0 THEN
    RAISE EXCEPTION '(fixed_chain_id, fixed_step) 중복 감지 — UNIQUE 제약 위반';
  END IF;
END $$;

COMMIT;
