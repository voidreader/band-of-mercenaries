-- ====================================================================
-- M7 페이즈 3 산출물 4: 지역 상태별 퀘스트 풀 36행 + 신규 3 컬럼 DDL
-- ====================================================================
--
-- 작성일: 2026-05-17
-- 마일스톤: M7 (지역 생활권 확장)
-- 페이즈: 3 #4
-- 처리 방식: 옵션 B — CSV 대신 SQL 마이그레이션 형태. 페이즈 4 #2 spec 단계에서 일괄 적용
--
-- 선행 문서:
--   - Docs/content-design/[content]20260516_m7_region_state_rules.md (페이즈 1 #2)
--   - Docs/balance-design/[balance]20260517_m7_region_state_thresholds.md (페이즈 2 #2)
--     특히 data-generator 권장 36행 분포 표
--
-- 본 스크립트 구성:
--   (A) ALTER TABLE quest_pools — 신규 3 컬럼 추가 (region_state_effect / required / excluded)
--   (B) CHECK 제약 — required·excluded 4 enum 검증
--   (C) INSERT 36행 — 7리전 분배 (r3:2 / r31:6 / r127:5 / r9:6 / r10:5 / r146:6 / r38:6)
--   (D) 검증 DO 블록 4종
--
-- 적용 시점: 페이즈 4 #2 "QuestGenerator 지역 상태 가중치 분기" 명세 단계에서
--   RegionState 시스템 코드 변경 + 본 마이그레이션 일괄 적용 (게임 동작 시점 일치)
--
-- 트리거 점수 변동 가이드 (페이즈 2 #2):
--   - cumulative: delta_per_completion=-10, cap_per_threshold=-50
--   - oneshot 등급: 소형 -10~-15 / 중형 -20~-25 / 대형 -30~-40 / 특수 -50
-- ====================================================================


-- ====================================================================
-- (A) 신규 3 컬럼 추가
-- ====================================================================

ALTER TABLE quest_pools
  ADD COLUMN IF NOT EXISTS region_state_effect JSONB,
  ADD COLUMN IF NOT EXISTS region_state_required TEXT,
  ADD COLUMN IF NOT EXISTS region_state_excluded TEXT;

COMMENT ON COLUMN quest_pools.region_state_effect IS
  'M7 페이즈 4 #2 — 의뢰 완료 시 region dangerScore 변동. {"type":"cumulative","delta_per_completion":N,"cap_per_threshold":N,"threshold_flag":"..."} 또는 {"type":"oneshot","delta":N,"flag":"..."}';

COMMENT ON COLUMN quest_pools.region_state_required IS
  'M7 페이즈 4 #2 — 특정 dangerLevel(stable/peaceful/tension/threat)에서만 노출. NULL이면 모든 상태에서 노출';

COMMENT ON COLUMN quest_pools.region_state_excluded IS
  'M7 페이즈 4 #2 — 특정 dangerLevel에서 노출 제외. NULL이면 제외 없음';


-- ====================================================================
-- (B) CHECK 제약: required·excluded 4 enum 검증
-- ====================================================================

ALTER TABLE quest_pools
  ADD CONSTRAINT chk_quest_pools_region_state_required
    CHECK (region_state_required IS NULL OR region_state_required IN ('stable', 'peaceful', 'tension', 'threat'));

ALTER TABLE quest_pools
  ADD CONSTRAINT chk_quest_pools_region_state_excluded
    CHECK (region_state_excluded IS NULL OR region_state_excluded IN ('stable', 'peaceful', 'tension', 'threat'));


-- ====================================================================
-- (C) 36행 INSERT
-- ====================================================================
--
-- 분포: cumulative 7 / oneshot 6 / 상태 조건 11 / 일반 12 = 36행
-- region 분배: r3 2 / r31 6 / r127 5 / r9 6 / r10 5 / r146 6 / r38 6
--
-- 컬럼 채움 정책:
--   - type: 0 (real, 기존 행 패턴 답습 — 의미 불명. 0 고정)
--   - min_region_diff: 1 / max_region_diff: 1 (region 인근만 노출)
--   - is_faction_exclusive: false / min_reputation: 0 / is_fixed: false / min_trust_level: 0 / is_named: false (모든 기본값)
--   - special_flags: '{}' (기본값)
--   - faction_tag, fixed_*, override*, named_*, trust_threshold: NULL


-- ─── r3 더스트플레인 (2행) ───────────────────────────────────────
-- 폐광 박쥐 cumulative (페이즈 2 #2 표)
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, sector_type, enemy_name, region_state_effect)
VALUES ('qp_m7_r3_cave_bats', '폐광 박쥐 잔당 사냥', 0, 2, 1, 1, 'hunt', 'dungeon', '폐광 박쥐',
  '{"type":"cumulative","delta_per_completion":-10,"cap_per_threshold":-50,"threshold_flag":"region_3_pyegwang_reopen_completed"}'::jsonb);

-- 안정 상태 호위 (region_state_required=stable)
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, region_state_required)
VALUES ('qp_m7_r3_safe_escort', '평온한 마을 외곽 호위', 0, 1, 1, 1, 'escort', 'stable');


-- ─── r31 도적길 (6행) ───────────────────────────────────────────
-- 도적 cumulative (5회 cap → bandits_cleared)
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, sector_type, enemy_name, region_state_effect)
VALUES ('qp_m7_r31_bandit_patrol', '도적 잔당 소탕', 0, 2, 1, 1, 'raid', 'field', '도적 잔당',
  '{"type":"cumulative","delta_per_completion":-10,"cap_per_threshold":-50,"threshold_flag":"region_31_bandits_cleared"}'::jsonb);

-- shrine 완주 oneshot (중형 단발 -20)
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, region_state_effect)
VALUES ('qp_m7_r31_shrine_offering', '폐사당 봉헌 호위', 0, 1, 1, 1, 'escort',
  '{"type":"oneshot","delta":-20,"flag":"region_31_shrine_quest_completed"}'::jsonb);

-- stable 시 호위 의뢰
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, region_state_required)
VALUES ('qp_m7_r31_safe_caravan', '안전해진 상단 호위', 0, 2, 1, 1, 'escort', 'stable');

-- threat 시 약탈 의뢰
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, enemy_name, region_state_required)
VALUES ('qp_m7_r31_bandit_raid', '도적 본거지 습격', 0, 2, 1, 1, 'raid', '도적 두목', 'threat');

-- 일반 풀
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id)
VALUES ('qp_m7_r31_pilgrim_escort', '순례자 동행', 0, 1, 1, 1, 'escort');

INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id)
VALUES ('qp_m7_r31_road_patrol', '도적길 일대 정찰', 0, 1, 1, 1, 'explore');


-- ─── r127 변방 해안 (5행) ──────────────────────────────────────
-- 해안 정찰 cumulative (5회 cap → 친교 flag 토글 보조)
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, region_state_effect)
VALUES ('qp_m7_r127_coast_scout', '해안 야영지 정찰', 0, 1, 1, 1, 'explore',
  '{"type":"cumulative","delta_per_completion":-10,"cap_per_threshold":-50,"threshold_flag":"region_127_nomad_friendly"}'::jsonb);

-- 유목민 친교 oneshot (중형 단발 -20)
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, region_state_effect)
VALUES ('qp_m7_r127_nomad_visit', '유목민 천막 방문', 0, 1, 1, 1, 'escort',
  '{"type":"oneshot","delta":-20,"flag":"region_127_nomad_friendly"}'::jsonb);

-- stable 시 외래 의뢰
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, region_state_required)
VALUES ('qp_m7_r127_foreign_trade', '외래 상인 동행', 0, 2, 1, 1, 'escort', 'stable');

-- 일반 풀
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id)
VALUES ('qp_m7_r127_seaweed_gather', '해초 채집', 0, 1, 1, 1, 'explore');

INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id)
VALUES ('qp_m7_r127_beach_patrol', '해안 절벽 순찰', 0, 1, 1, 1, 'escort');


-- ─── r9 외곽 숲 (6행) ──────────────────────────────────────────
-- 야수 흔적 hunt cumulative
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, sector_type, enemy_name, region_state_effect)
VALUES ('qp_m7_r9_beast_trail', '숲 야수 흔적 추적', 0, 2, 1, 1, 'hunt', 'field', '야수',
  '{"type":"cumulative","delta_per_completion":-10,"cap_per_threshold":-50,"threshold_flag":"region_9_giant_beast_killed"}'::jsonb);

-- 거대 야수 oneshot (대형 단발 -40)
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, enemy_name, region_state_effect)
VALUES ('qp_m7_r9_giant_beast', '거대 야수 토벌', 0, 3, 1, 1, 'hunt', '거대 야수',
  '{"type":"oneshot","delta":-40,"flag":"region_9_giant_beast_killed"}'::jsonb);

-- peaceful 시 가죽 채집
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, region_state_required)
VALUES ('qp_m7_r9_hide_harvest', '평온한 숲 가죽 수집', 0, 1, 1, 1, 'escort', 'peaceful');

-- tension 시 hunt
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, enemy_name, region_state_required)
VALUES ('qp_m7_r9_beast_hunt', '울음소리 추적', 0, 2, 1, 1, 'hunt', '야생 늑대', 'tension');

-- 일반 풀
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id)
VALUES ('qp_m7_r9_forest_explore', '외곽 숲 탐사', 0, 2, 1, 1, 'explore');

INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id)
VALUES ('qp_m7_r9_mushroom_gather', '숲 버섯 채집', 0, 1, 1, 1, 'labor');


-- ─── r10 풍신 숲 (5행) ────────────────────────────────────────
-- 바람 정찰 cumulative
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, region_state_effect)
VALUES ('qp_m7_r10_wind_patrol', '풍신 능선 정찰', 0, 2, 1, 1, 'explore',
  '{"type":"cumulative","delta_per_completion":-10,"cap_per_threshold":-50,"threshold_flag":"region_10_windrunner_chain_completed"}'::jsonb);

-- windrunner 완주 oneshot (대형 단발 -30)
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, region_state_effect)
VALUES ('qp_m7_r10_windrunner_finale', '풍신의 자취 마무리', 0, 3, 1, 1, 'escort',
  '{"type":"oneshot","delta":-30,"flag":"region_10_windrunner_chain_completed"}'::jsonb);

-- peaceful 시 explore
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, region_state_required)
VALUES ('qp_m7_r10_calm_explore', '잠잠한 풍신 숲 탐사', 0, 2, 1, 1, 'explore', 'peaceful');

-- 일반 풀
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id)
VALUES ('qp_m7_r10_swordsman_hunt', '잘려나간 자취 추격', 0, 2, 1, 1, 'hunt');

INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id)
VALUES ('qp_m7_r10_wind_herb', '바람약초 채집', 0, 2, 1, 1, 'explore');


-- ─── r146 회색 늪지 (6행) ────────────────────────────────────
-- 안개 정찰 cumulative
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, region_state_effect)
VALUES ('qp_m7_r146_mist_scout', '안개 늪지 정찰', 0, 2, 1, 1, 'explore',
  '{"type":"cumulative","delta_per_completion":-10,"cap_per_threshold":-50,"threshold_flag":"region_146_mist_cleared"}'::jsonb);

-- 안개 해소 특수 단발 -50 (M7 7리전 최고 사건)
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, enemy_name, region_state_effect)
VALUES ('qp_m7_r146_mist_clearing', '회색 늪지 안개 해소', 0, 3, 1, 1, 'hunt', '안개의 야수',
  '{"type":"oneshot","delta":-50,"flag":"region_146_mist_cleared"}'::jsonb);

-- threat 시 hunt
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, enemy_name, region_state_required)
VALUES ('qp_m7_r146_threat_hunt', '독무 출몰 짐승 처치', 0, 3, 1, 1, 'hunt', '독안개 짐승', 'threat');

-- stable 시 explore
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, region_state_required)
VALUES ('qp_m7_r146_quiet_explore', '안개가 걷힌 늪 탐사', 0, 2, 1, 1, 'explore', 'stable');

-- 일반 풀
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id)
VALUES ('qp_m7_r146_poison_gather', '독초 채집', 0, 2, 1, 1, 'explore');

INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id)
VALUES ('qp_m7_r146_swamp_relic', '늪 인장 발굴', 0, 2, 1, 1, 'explore');


-- ─── r38 부서진 요새 (6행) ───────────────────────────────────
-- 도굴꾼 cumulative
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, sector_type, enemy_name, region_state_effect)
VALUES ('qp_m7_r38_robber_hunt', '도굴꾼 무리 소탕', 0, 3, 1, 1, 'hunt', 'ruins', '도굴꾼',
  '{"type":"cumulative","delta_per_completion":-10,"cap_per_threshold":-50,"threshold_flag":"region_38_ironbound_pact_completed"}'::jsonb);

-- ironbound 완주 oneshot (대형 단발 -40)
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, sector_type, region_state_effect)
VALUES ('qp_m7_r38_ironbound_finale', '서약의 인장 마무리', 0, 3, 1, 1, 'explore', 'ruins',
  '{"type":"oneshot","delta":-40,"flag":"region_38_ironbound_pact_completed"}'::jsonb);

-- threat 시 raid 폭증
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, enemy_name, region_state_required)
VALUES ('qp_m7_r38_threat_raid', '도굴꾼 본거지 습격', 0, 3, 1, 1, 'raid', '도굴꾼 두목', 'threat');

-- peaceful 시 explore
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, sector_type, region_state_required)
VALUES ('qp_m7_r38_calm_explore', '평온해진 폐허 탐사', 0, 3, 1, 1, 'explore', 'ruins', 'peaceful');

-- 일반 풀
INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id)
VALUES ('qp_m7_r38_ore_dig', '폐허 광석 채굴', 0, 3, 1, 1, 'labor');

INSERT INTO quest_pools (id, name, type, difficulty, min_region_diff, max_region_diff, type_id, enemy_name)
VALUES ('qp_m7_r38_relic_hunt', '유적 도굴꾼 처치', 0, 3, 1, 1, 'hunt', '도굴꾼');


-- ====================================================================
-- (D) 검증 DO 블록
-- ====================================================================

-- D1: 총 36행 INSERT 검증
DO $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM quest_pools WHERE id LIKE 'qp_m7_%';
  IF v_count <> 36 THEN
    RAISE EXCEPTION 'M7 quest_pools INSERT 검증 실패: 36행이어야 하나 % 행', v_count;
  END IF;
END $$;

-- D2: region_state_effect.threshold_flag가 8개 flag 중 하나인지 검증
DO $$
DECLARE
  v_invalid INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_invalid
  FROM quest_pools
  WHERE id LIKE 'qp_m7_%'
    AND region_state_effect IS NOT NULL
    AND (
      (region_state_effect->>'type' = 'cumulative' AND
       region_state_effect->>'threshold_flag' NOT IN (
         'region_3_pyegwang_reopen_completed',
         'region_31_bandits_cleared',
         'region_31_shrine_quest_completed',
         'region_127_nomad_friendly',
         'region_9_giant_beast_killed',
         'region_10_windrunner_chain_completed',
         'region_146_mist_cleared',
         'region_38_ironbound_pact_completed'
       ))
      OR
      (region_state_effect->>'type' = 'oneshot' AND
       region_state_effect->>'flag' NOT IN (
         'region_3_pyegwang_reopen_completed',
         'region_31_bandits_cleared',
         'region_31_shrine_quest_completed',
         'region_127_nomad_friendly',
         'region_9_giant_beast_killed',
         'region_10_windrunner_chain_completed',
         'region_146_mist_cleared',
         'region_38_ironbound_pact_completed'
       ))
    );

  IF v_invalid > 0 THEN
    RAISE EXCEPTION 'region_state_effect flag 검증 실패: 8개 정의 flag 외 사용 % 행', v_invalid;
  END IF;
END $$;

-- D3: region별 분포 검증 (r3:2 / r31:6 / r127:5 / r9:6 / r10:5 / r146:6 / r38:6)
DO $$
DECLARE
  r3_n INTEGER; r31_n INTEGER; r127_n INTEGER; r9_n INTEGER;
  r10_n INTEGER; r146_n INTEGER; r38_n INTEGER;
BEGIN
  SELECT COUNT(*) INTO r3_n FROM quest_pools WHERE id LIKE 'qp_m7_r3_%';
  SELECT COUNT(*) INTO r31_n FROM quest_pools WHERE id LIKE 'qp_m7_r31_%';
  SELECT COUNT(*) INTO r127_n FROM quest_pools WHERE id LIKE 'qp_m7_r127_%';
  SELECT COUNT(*) INTO r9_n FROM quest_pools WHERE id LIKE 'qp_m7_r9_%';
  SELECT COUNT(*) INTO r10_n FROM quest_pools WHERE id LIKE 'qp_m7_r10_%';
  SELECT COUNT(*) INTO r146_n FROM quest_pools WHERE id LIKE 'qp_m7_r146_%';
  SELECT COUNT(*) INTO r38_n FROM quest_pools WHERE id LIKE 'qp_m7_r38_%';

  IF r3_n <> 2 OR r31_n <> 6 OR r127_n <> 5 OR r9_n <> 6 OR r10_n <> 5 OR r146_n <> 6 OR r38_n <> 6 THEN
    RAISE EXCEPTION 'M7 region 분배 검증 실패: 실제(r3=%, r31=%, r127=%, r9=%, r10=%, r146=%, r38=%)',
      r3_n, r31_n, r127_n, r9_n, r10_n, r146_n, r38_n;
  END IF;
END $$;

-- D4: 분포 검증 — cumulative 7 / oneshot 6 / 상태 조건 11 / 일반 12
DO $$
DECLARE
  cum_n INTEGER; one_n INTEGER; req_n INTEGER; gen_n INTEGER;
BEGIN
  SELECT COUNT(*) INTO cum_n FROM quest_pools
    WHERE id LIKE 'qp_m7_%' AND region_state_effect->>'type' = 'cumulative';
  SELECT COUNT(*) INTO one_n FROM quest_pools
    WHERE id LIKE 'qp_m7_%' AND region_state_effect->>'type' = 'oneshot';
  SELECT COUNT(*) INTO req_n FROM quest_pools
    WHERE id LIKE 'qp_m7_%' AND region_state_effect IS NULL AND region_state_required IS NOT NULL;
  SELECT COUNT(*) INTO gen_n FROM quest_pools
    WHERE id LIKE 'qp_m7_%' AND region_state_effect IS NULL AND region_state_required IS NULL;

  IF cum_n <> 7 OR one_n <> 6 OR req_n <> 11 OR gen_n <> 12 THEN
    RAISE EXCEPTION 'M7 풀 분포 검증 실패: cumulative=% oneshot=% 상태조건=% 일반=%',
      cum_n, one_n, req_n, gen_n;
  END IF;
END $$;


-- ====================================================================
-- 적용 후 후속 작업 (수동)
-- ====================================================================
--
-- 1. data_versions 갱신:
--    UPDATE data_versions SET version = version + 1 WHERE table_name = 'quest_pools';
--
-- 2. operation-bom table-config.ts에 신규 3 컬럼 추가
--    - region_state_effect (JSONB 편집기)
--    - region_state_required (셀렉트: stable/peaceful/tension/threat/NULL)
--    - region_state_excluded (셀렉트)
--
-- 3. Flutter 측 변경 사항 (페이즈 4 #2 명세 영역):
--    - QuestPool freezed 모델 신규 3 컬럼 추가
--    - QuestGenerator computeFinalWeight() 가중치 계산 분기
--    - RegionStateRepository.addDangerScore() trailing trigger
--
-- ====================================================================
