-- ============================================================================
-- M1 페이즈 4 통합 마이그레이션 (P1 + P2 + P3 데이터 변경)
-- ============================================================================
-- 생성일: 2026-04-18
-- 마일스톤: M1 (세력 가입이 실제 영향을 미친다)
-- 출처 명세:
--   - P1: Docs/spec/[spec]20260418_passive-bonus-service.md
--   - P2: Docs/spec/[spec]20260418_faction-quest-system.md
--   - P3: Docs/spec/[spec]20260418_dispatch-synergy.md
--   - P4: Docs/spec/[spec]20260418_rank-bonus-service.md (스키마 변경 없음)
-- 데이터 소스:
--   - Docs/content-data/[faction-quest]20260417_m1-faction-exclusive.csv (98행)
--   - Docs/balance-design/20260417_faction_passive_values.md
--   - Docs/balance-design/20260417_rank_bonuses_values.md
--   - Docs/balance-design/20260417_dispatch_synergy_values.md
-- 멱등성: IF NOT EXISTS / ON CONFLICT DO NOTHING로 재실행 안전
-- ============================================================================

BEGIN;

-- ============================================================================
-- §1. [P1] PassiveBonusService — ranks / factions 스키마 및 데이터
-- ============================================================================

-- §1.1 ranks.bonus_json 컬럼 추가
ALTER TABLE ranks
  ADD COLUMN IF NOT EXISTS bonus_json JSONB NOT NULL DEFAULT '{"effects": []}'::jsonb;

-- §1.2 E 임계값 500 → 300 (C1 조정, 로드맵 첫 랭크업 30~60분 목표 근접)
UPDATE ranks SET required_reputation = 300 WHERE grade = 'E';

-- §1.3 6등급 bonus_json 최종값 (balance report 2026-04-17 기준)
UPDATE ranks SET bonus_json = '{"effects":[]}'::jsonb
  WHERE grade = 'F';

UPDATE ranks SET bonus_json = '{"effects":[{"type":"recruitment_cost_reduction","value":0.10}]}'::jsonb
  WHERE grade = 'E';

UPDATE ranks SET bonus_json = '{"effects":[{"type":"quest_reward_multiplier","quest_type":"all","value":0.03},{"type":"recovery_time_reduction","status":"injured","value":0.10}]}'::jsonb
  WHERE grade = 'D';

UPDATE ranks SET bonus_json = '{"effects":[{"type":"quest_success_rate_bonus","quest_type":"all","value":0.03},{"type":"dispatch_slot_bonus","value":1}]}'::jsonb
  WHERE grade = 'C';

UPDATE ranks SET bonus_json = '{"effects":[{"type":"quest_reward_multiplier","quest_type":"all","value":0.07},{"type":"idle_reward_bonus","bonus_type":"rate","value":0.15},{"type":"trait_acquisition_condition_relief","value":0.10},{"type":"quest_success_rate_bonus","quest_type":"all","value":0.02}]}'::jsonb
  WHERE grade = 'B';

UPDATE ranks SET bonus_json = '{"effects":[{"type":"quest_success_rate_bonus","quest_type":"all","value":0.05},{"type":"facility_cost_reduction","cost_type":"time","value":0.10},{"type":"mercenary_xp_bonus","value":0.15},{"type":"dispatch_slot_bonus","value":1}]}'::jsonb
  WHERE grade = 'A';

-- §1.4 14세력 passive_bonus_json 최종값 (P1~P4 조정 반영)
UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"quest_reward_multiplier","quest_type":"explore","value":0.12}]}'::jsonb
  WHERE id = 'faction_adventurers_guild';

UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"quest_reward_multiplier","quest_type":"escort","value":0.12},{"type":"idle_reward_bonus","bonus_type":"rate","value":0.10}]}'::jsonb
  WHERE id = 'faction_merchants_alliance';

UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"quest_success_rate_bonus","quest_type":"raid","value":0.05},{"type":"quest_success_rate_bonus","quest_type":"hunt","value":0.05}]}'::jsonb
  WHERE id = 'faction_warriors_guild';

UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"travel_event_mitigation","event_type":"gold_loss","value":0.30},{"type":"investigation_success_rate_bonus","value":0.05}]}'::jsonb
  WHERE id = 'faction_thieves_guild';

UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"quest_success_rate_bonus","quest_type":"explore","value":0.08},{"type":"trait_acquisition_condition_relief","value":0.10}]}'::jsonb
  WHERE id = 'faction_mage_towers';

UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"quest_success_rate_bonus","quest_type":"escort","value":0.08},{"type":"recovery_time_reduction","status":"injured","value":0.15}]}'::jsonb
  WHERE id = 'faction_sun_order';

UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"quest_success_rate_bonus","quest_type":"all","value":0.03}]}'::jsonb
  WHERE id = 'faction_balance_watchers';

UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"trait_evolution_condition_relief","value":0.15}]}'::jsonb
  WHERE id = 'faction_forbidden_archive';

UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"travel_event_mitigation","event_type":"damage","value":0.40},{"type":"recovery_time_reduction","status":"injured","value":0.15}]}'::jsonb
  WHERE id = 'faction_root_oath';

UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"facility_cost_reduction","cost_type":"gold","value":0.10},{"type":"facility_effect_bonus","facility_id":null,"value":0.05}]}'::jsonb
  WHERE id = 'faction_twilight_artificers';

UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"facility_cost_reduction","cost_type":"time","value":0.20}]}'::jsonb
  WHERE id = 'faction_deep_hammer';

UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"quest_reward_multiplier","quest_type":"raid","value":0.15}]}'::jsonb
  WHERE id = 'faction_volcanic_heart';

UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"recruitment_tier_boost","tier_min":4,"tier_max":5,"value":0.04}]}'::jsonb
  WHERE id = 'faction_blood_council';

UPDATE factions SET passive_bonus_json = '{"effects":[{"type":"quest_success_rate_bonus_party_size","min_party_size":3,"value":0.08}]}'::jsonb
  WHERE id = 'faction_fang_brotherhood';


-- ============================================================================
-- §2. [P2] 세력 전용 퀘스트 — quest_pools 스키마 및 98행 INSERT
-- ============================================================================

-- §2.1 quest_pools 5컬럼 확장
-- type_id: 기존 type(real, deprecated) 대체. quest_types FK. default 'raid'
-- faction_tag: 전용 퀘스트의 소속 세력. nullable (일반 퀘스트는 null, 런타임 태깅)
-- is_faction_exclusive: 전용 퀘스트 식별 플래그
-- min_reputation: 평판 해금 임계 (기본 0, 전용 기본 트랙 11, 고급 트랙 61)
-- sector_type: M3 대비 필드만 추가
ALTER TABLE quest_pools
  ADD COLUMN IF NOT EXISTS type_id TEXT NOT NULL DEFAULT 'raid' REFERENCES quest_types(id);
ALTER TABLE quest_pools
  ADD COLUMN IF NOT EXISTS faction_tag TEXT NULL REFERENCES factions(id) ON DELETE SET NULL;
ALTER TABLE quest_pools
  ADD COLUMN IF NOT EXISTS is_faction_exclusive BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE quest_pools
  ADD COLUMN IF NOT EXISTS min_reputation INTEGER NOT NULL DEFAULT 0;
ALTER TABLE quest_pools
  ADD COLUMN IF NOT EXISTS sector_type TEXT NULL;

-- §2.2 98행 전용 퀘스트 INSERT (14세력 × 7개: 기본 3 + 고급 4)
-- CSV 변환 규칙:
--   - type 컬럼(real): 0으로 통일 (기존 관행 유지, deprecated)
--   - type_id 컬럼(text): CSV type 숫자를 매핑 (1=raid, 2=hunt, 3=escort, 4=explore)
--   - sector_type: CSV 빈 문자열 → SQL NULL
-- 출처: Docs/content-data/[faction-quest]20260417_m1-faction-exclusive.csv
INSERT INTO quest_pools
  (id, name, type, type_id, difficulty, min_region_diff, max_region_diff, faction_tag, is_faction_exclusive, min_reputation, sector_type)
VALUES
-- 모험가 길드 (7개)
('fq_adventurers_guild_missing_explorer_search', '실종된 탐험가 수색', 0, 'explore', 2, 0, 3, 'faction_adventurers_guild', true, 11, NULL),
('fq_adventurers_guild_way_station_secure', '중간 기착지 확보', 0, 'escort', 2, 0, 3, 'faction_adventurers_guild', true, 11, NULL),
('fq_adventurers_guild_road_beast_cleanup', '길 위 야수 토벌', 0, 'hunt', 3, 0, 3, 'faction_adventurers_guild', true, 11, NULL),
('fq_adventurers_guild_ruins_deep_survey', '고대 유적 심층 탐사', 0, 'explore', 3, 0, 3, 'faction_adventurers_guild', true, 61, NULL),
('fq_adventurers_guild_legendary_treasure_race', '전설의 보물 경쟁', 0, 'raid', 3, 0, 3, 'faction_adventurers_guild', true, 61, NULL),
('fq_adventurers_guild_unknown_continent_vanguard', '미지의 대륙 선발대', 0, 'explore', 4, 0, 3, 'faction_adventurers_guild', true, 61, NULL),
('fq_adventurers_guild_forgotten_city_beast', '잊혀진 도시의 야수 처단', 0, 'hunt', 4, 0, 3, 'faction_adventurers_guild', true, 61, NULL),
-- 상인 연합 (7개)
('fq_merchants_alliance_caravan_escort', '소형 상단 호위', 0, 'escort', 2, 0, 4, 'faction_merchants_alliance', true, 11, NULL),
('fq_merchants_alliance_debt_recovery', '채무 기록 회수', 0, 'escort', 3, 0, 4, 'faction_merchants_alliance', true, 11, NULL),
('fq_merchants_alliance_trade_dispute_mediation', '교역 분쟁 중재', 0, 'escort', 3, 0, 4, 'faction_merchants_alliance', true, 11, NULL),
('fq_merchants_alliance_grand_caravan_march', '대상단 대장정 호위', 0, 'escort', 4, 0, 4, 'faction_merchants_alliance', true, 61, NULL),
('fq_merchants_alliance_rival_house_counter', '경쟁 상회 역공작', 0, 'hunt', 4, 0, 4, 'faction_merchants_alliance', true, 61, NULL),
('fq_merchants_alliance_route_monopoly', '교역로 독점권 확보', 0, 'explore', 5, 0, 4, 'faction_merchants_alliance', true, 61, NULL),
('fq_merchants_alliance_hazard_zone_express', '위험 지대 특송', 0, 'explore', 5, 0, 4, 'faction_merchants_alliance', true, 61, NULL),
-- 전사 길드 (7개)
('fq_warriors_guild_territory_monster_cull', '영역 내 괴수 토벌', 0, 'hunt', 3, 1, 5, 'faction_warriors_guild', true, 11, NULL),
('fq_warriors_guild_challenger_response', '도전자 응전', 0, 'hunt', 3, 1, 5, 'faction_warriors_guild', true, 11, NULL),
('fq_warriors_guild_rookie_trial', '신인 전사 시련', 0, 'escort', 4, 1, 5, 'faction_warriors_guild', true, 11, NULL),
('fq_warriors_guild_legendary_beast_slay', '전설급 괴수 처단', 0, 'hunt', 4, 1, 5, 'faction_warriors_guild', true, 61, NULL),
('fq_warriors_guild_warlord_siege', '적 군벌 공성', 0, 'raid', 4, 1, 5, 'faction_warriors_guild', true, 61, NULL),
('fq_warriors_guild_tournament_champion', '무도 대회 대표 출전', 0, 'raid', 5, 1, 5, 'faction_warriors_guild', true, 61, NULL),
('fq_warriors_guild_heroic_weapon_recovery', '영웅의 무기 회수', 0, 'raid', 5, 1, 5, 'faction_warriors_guild', true, 61, NULL),
-- 도둑 길드 (7개)
('fq_thieves_guild_lost_item_recovery', '분실 물품 회수', 0, 'explore', 3, 1, 5, 'faction_thieves_guild', true, 11, NULL),
('fq_thieves_guild_traitor_tracking', '배신자 추적', 0, 'hunt', 3, 1, 5, 'faction_thieves_guild', true, 11, NULL),
('fq_thieves_guild_informant_contact', '정보원 접선', 0, 'explore', 4, 1, 5, 'faction_thieves_guild', true, 11, NULL),
('fq_thieves_guild_vault_infiltration', '삼엄한 금고 침투', 0, 'raid', 4, 1, 5, 'faction_thieves_guild', true, 61, NULL),
('fq_thieves_guild_high_informant_extraction', '고위 정보원 탈취', 0, 'escort', 4, 1, 5, 'faction_thieves_guild', true, 61, NULL),
('fq_thieves_guild_double_spy_removal', '이중 스파이 제거', 0, 'raid', 5, 1, 5, 'faction_thieves_guild', true, 61, NULL),
('fq_thieves_guild_stolen_relic_retake', '도난 유물 재탈취', 0, 'explore', 5, 1, 5, 'faction_thieves_guild', true, 61, NULL),
-- 마탑 연합 (7개)
('fq_mage_towers_mana_sample_collection', '마나 시료 채집', 0, 'explore', 4, 2, 8, 'faction_mage_towers', true, 11, NULL),
('fq_mage_towers_anomaly_survey', '마나 이상 조사', 0, 'explore', 4, 2, 8, 'faction_mage_towers', true, 11, NULL),
('fq_mage_towers_laboratory_escort', '연구실 호송', 0, 'escort', 5, 2, 8, 'faction_mage_towers', true, 11, NULL),
('fq_mage_towers_sealed_artifact_retrieval', '봉인된 유물 확보', 0, 'explore', 5, 2, 8, 'faction_mage_towers', true, 61, NULL),
('fq_mage_towers_forbidden_magic_reseal', '금지 마법 재봉인', 0, 'explore', 5, 2, 8, 'faction_mage_towers', true, 61, NULL),
('fq_mage_towers_ancient_spell_expedition', '고대 주문 해독 원정', 0, 'explore', 5, 2, 8, 'faction_mage_towers', true, 61, NULL),
('fq_mage_towers_archmage_missing_probe', '대마법사 실종 수사', 0, 'hunt', 5, 2, 8, 'faction_mage_towers', true, 61, NULL),
-- 태양 교단 (7개)
('fq_sun_order_pilgrim_escort', '순례자 호위', 0, 'escort', 3, 1, 5, 'faction_sun_order', true, 11, NULL),
('fq_sun_order_curse_lift', '저주 해제', 0, 'hunt', 3, 1, 5, 'faction_sun_order', true, 11, NULL),
('fq_sun_order_heretic_purge', '사교도 단속', 0, 'hunt', 4, 1, 5, 'faction_sun_order', true, 11, NULL),
('fq_sun_order_grand_priest_guard', '대신관 직속 호위', 0, 'escort', 4, 1, 5, 'faction_sun_order', true, 61, NULL),
('fq_sun_order_demon_reseal', '봉인된 악마 재봉인', 0, 'raid', 4, 1, 5, 'faction_sun_order', true, 61, NULL),
('fq_sun_order_holy_relic_recovery', '잃어버린 성물 회수', 0, 'explore', 5, 1, 5, 'faction_sun_order', true, 61, NULL),
('fq_sun_order_inquisition_execution', '이단 심판 집행', 0, 'escort', 5, 1, 5, 'faction_sun_order', true, 61, NULL),
-- 균형 감시자 (7개)
('fq_balance_watchers_faction_dispute_watch', '세력 간 분쟁 관찰', 0, 'explore', 3, 1, 6, 'faction_balance_watchers', true, 11, NULL),
('fq_balance_watchers_relic_transit_monitor', '위험 유물 이동 감시', 0, 'escort', 4, 1, 6, 'faction_balance_watchers', true, 11, NULL),
('fq_balance_watchers_intel_gathering', '정보 수집', 0, 'explore', 4, 1, 6, 'faction_balance_watchers', true, 11, NULL),
('fq_balance_watchers_overgrown_faction_undermine', '과잉 세력 내부 와해', 0, 'hunt', 5, 1, 6, 'faction_balance_watchers', true, 61, NULL),
('fq_balance_watchers_catastrophe_relic_seal', '대재앙 유물 봉인', 0, 'escort', 5, 1, 6, 'faction_balance_watchers', true, 61, NULL),
('fq_balance_watchers_equilibrium_restoration', '균형 복원 작전', 0, 'raid', 5, 1, 6, 'faction_balance_watchers', true, 61, NULL),
('fq_balance_watchers_traitor_watcher_removal', '배반 감시자 제거', 0, 'hunt', 5, 1, 6, 'faction_balance_watchers', true, 61, NULL),
-- 금지된 서고 (7개)
('fq_forbidden_archive_banned_book_copy', '금서 사본 수집', 0, 'explore', 4, 2, 8, 'faction_forbidden_archive', true, 11, NULL),
('fq_forbidden_archive_exiled_scholar_contact', '추방된 학자 접촉', 0, 'escort', 4, 2, 8, 'faction_forbidden_archive', true, 11, NULL),
('fq_forbidden_archive_lost_record_trace', '소실 기록 추적', 0, 'explore', 5, 2, 8, 'faction_forbidden_archive', true, 11, NULL),
('fq_forbidden_archive_order_seal_break', '교단 봉인 해제', 0, 'raid', 5, 2, 8, 'faction_forbidden_archive', true, 61, NULL),
('fq_forbidden_archive_heretic_library_expedition', '고대 이단 서고 탐험', 0, 'explore', 5, 2, 8, 'faction_forbidden_archive', true, 61, NULL),
('fq_forbidden_archive_forbidden_rite_witness', '금지 의식 참관', 0, 'explore', 5, 2, 8, 'faction_forbidden_archive', true, 61, NULL),
('fq_forbidden_archive_vanished_school_revival', '사라진 학파 복원', 0, 'hunt', 5, 2, 8, 'faction_forbidden_archive', true, 61, NULL),
-- 뿌리의 맹세단 (7개)
('fq_root_oath_poacher_removal', '밀렵꾼 제거', 0, 'hunt', 2, 0, 4, 'faction_root_oath', true, 11, NULL),
('fq_root_oath_pollution_cleansing', '오염원 정화', 0, 'escort', 3, 0, 4, 'faction_root_oath', true, 11, NULL),
('fq_root_oath_sacred_grove_guard', '성스러운 숲 수호', 0, 'escort', 3, 0, 4, 'faction_root_oath', true, 11, NULL),
('fq_root_oath_logging_operation_sabotage', '대규모 벌목 방해', 0, 'raid', 4, 0, 4, 'faction_root_oath', true, 61, NULL),
('fq_root_oath_ancient_tree_awaken', '고대 나무 각성', 0, 'explore', 4, 0, 4, 'faction_root_oath', true, 61, NULL),
('fq_root_oath_ruined_shrine_restore', '훼손된 성지 복원', 0, 'hunt', 5, 0, 4, 'faction_root_oath', true, 61, NULL),
('fq_root_oath_machine_outpost_raid', '기계 문명 거점 습격', 0, 'raid', 5, 0, 4, 'faction_root_oath', true, 61, NULL),
-- 황혼 공학회 (7개)
('fq_twilight_artificers_material_procurement', '실험 재료 조달', 0, 'explore', 4, 2, 8, 'faction_twilight_artificers', true, 11, NULL),
('fq_twilight_artificers_prototype_field_test', '시제품 테스트 호송', 0, 'escort', 4, 2, 8, 'faction_twilight_artificers', true, 11, NULL),
('fq_twilight_artificers_lab_security', '실험실 보안', 0, 'escort', 5, 2, 8, 'faction_twilight_artificers', true, 11, NULL),
('fq_twilight_artificers_rival_lab_infiltration', '경쟁 연구소 잠입', 0, 'raid', 5, 2, 8, 'faction_twilight_artificers', true, 61, NULL),
('fq_twilight_artificers_forbidden_tech_retrieval', '금단 기술 회수', 0, 'explore', 5, 2, 8, 'faction_twilight_artificers', true, 61, NULL),
('fq_twilight_artificers_test_subject_acquisition', '실험 대상 확보', 0, 'hunt', 5, 2, 8, 'faction_twilight_artificers', true, 61, NULL),
('fq_twilight_artificers_prototype_live_deployment', '프로토타입 실전 투입', 0, 'explore', 5, 2, 8, 'faction_twilight_artificers', true, 61, NULL),
-- 심층 망치단 (7개)
('fq_deep_hammer_ore_vein_survey', '광맥 탐사', 0, 'explore', 4, 2, 8, 'faction_deep_hammer', true, 11, NULL),
('fq_deep_hammer_mine_intruder_repel', '광산 침입자 격퇴', 0, 'hunt', 4, 2, 8, 'faction_deep_hammer', true, 11, NULL),
('fq_deep_hammer_rune_material_gather', '룬 재료 수집', 0, 'escort', 5, 2, 8, 'faction_deep_hammer', true, 11, NULL),
('fq_deep_hammer_legendary_forge_restore', '전설의 대장간 복원', 0, 'escort', 5, 2, 8, 'faction_deep_hammer', true, 61, NULL),
('fq_deep_hammer_ancient_rune_decipher', '고대 룬 해독', 0, 'explore', 5, 2, 8, 'faction_deep_hammer', true, 61, NULL),
('fq_deep_hammer_volcanic_rival_strike', '숙적 화염 거점 타격', 0, 'raid', 5, 2, 8, 'faction_deep_hammer', true, 61, NULL),
('fq_deep_hammer_lost_masterwork_recovery', '잃어버린 작품 회수', 0, 'hunt', 5, 2, 8, 'faction_deep_hammer', true, 61, NULL),
-- 화산 심장단 (7개)
('fq_volcanic_heart_enemy_camp_raid', '적 진영 습격', 0, 'raid', 4, 2, 8, 'faction_volcanic_heart', true, 11, NULL),
('fq_volcanic_heart_fire_beast_hunt', '화염 괴수 토벌', 0, 'hunt', 4, 2, 8, 'faction_volcanic_heart', true, 11, NULL),
('fq_volcanic_heart_crater_defense', '화산 지대 방어', 0, 'raid', 5, 2, 8, 'faction_volcanic_heart', true, 11, NULL),
('fq_volcanic_heart_hammer_mine_strike', '숙적 광산 공격', 0, 'raid', 5, 2, 8, 'faction_volcanic_heart', true, 61, NULL),
('fq_volcanic_heart_lava_titan_slay', '전설의 용암 괴수 처단', 0, 'hunt', 5, 2, 8, 'faction_volcanic_heart', true, 61, NULL),
('fq_volcanic_heart_flame_relic_forging', '화염 유물 주조 원정', 0, 'explore', 5, 2, 8, 'faction_volcanic_heart', true, 61, NULL),
('fq_volcanic_heart_sealed_shrine_retake', '봉인된 화염신 성지 탈환', 0, 'raid', 5, 2, 8, 'faction_volcanic_heart', true, 61, NULL),
-- 혈계 귀족회 (7개)
('fq_blood_council_noble_escort', '귀족 호위', 0, 'escort', 4, 3, 8, 'faction_blood_council', true, 11, NULL),
('fq_blood_council_estate_patrol', '영지 순찰', 0, 'escort', 5, 3, 8, 'faction_blood_council', true, 11, NULL),
('fq_blood_council_protocol_enforcement', '격식 집행', 0, 'escort', 5, 3, 8, 'faction_blood_council', true, 11, NULL),
('fq_blood_council_bloodline_threat_silence', '혈계 위협자 암살', 0, 'hunt', 5, 3, 8, 'faction_blood_council', true, 61, NULL),
('fq_blood_council_ancient_genealogy_recovery', '고대 계보 회수', 0, 'explore', 5, 3, 8, 'faction_blood_council', true, 61, NULL),
('fq_blood_council_ducal_dispute_settlement', '대공가 분쟁 조정', 0, 'raid', 5, 3, 8, 'faction_blood_council', true, 61, NULL),
('fq_blood_council_rival_chieftain_removal', '경쟁 부족장 제거', 0, 'hunt', 5, 3, 8, 'faction_blood_council', true, 61, NULL),
-- 송곳니 결사 (7개)
('fq_fang_brotherhood_pack_hunt', '무리 사냥', 0, 'hunt', 3, 1, 5, 'faction_fang_brotherhood', true, 11, NULL),
('fq_fang_brotherhood_territory_defend', '영역 침입자 격퇴', 0, 'hunt', 3, 1, 5, 'faction_fang_brotherhood', true, 11, NULL),
('fq_fang_brotherhood_chieftain_escort', '족장 호위', 0, 'escort', 4, 1, 5, 'faction_fang_brotherhood', true, 11, NULL),
('fq_fang_brotherhood_legendary_prey_track', '전설의 사냥감 추적', 0, 'hunt', 4, 1, 5, 'faction_fang_brotherhood', true, 61, NULL),
('fq_fang_brotherhood_noble_estate_raid', '귀족 영지 습격', 0, 'raid', 4, 1, 5, 'faction_fang_brotherhood', true, 61, NULL),
('fq_fang_brotherhood_lost_tribe_gather', '잃어버린 부족 결집', 0, 'explore', 5, 1, 5, 'faction_fang_brotherhood', true, 61, NULL),
('fq_fang_brotherhood_grand_trophy_claim', '거대 전리품 획득', 0, 'raid', 5, 1, 5, 'faction_fang_brotherhood', true, 61, NULL)
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- §3. [P3] 파견 상성 — jobs / traits 스키마 및 데이터
-- ============================================================================

-- §3.1 jobs.role 컬럼 추가 (balance report 분석 6 확정)
-- 6개 enum: warrior / ranger / mage / rogue / support / specialist
ALTER TABLE jobs
  ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'specialist';

-- §3.2 85개 직업 role 전수 UPDATE
-- 분포: warrior 26 / specialist 16(DEFAULT) / mage 16 / support 10 / ranger 9 / rogue 8

-- warrior 26개
UPDATE jobs SET role = 'warrior' WHERE id IN (
  'ruffian',
  'gladiator_low', 'bandit', 'deserter_sword', 'mercenary_low',
  'squire', 'guard_low', 'militia', 'deserter_spear',
  'light_cavalry', 'mercenary', 'knight_low', 'shield_bearer', 'soldier', 'spearman',
  'mercenary_captain', 'knight', 'elite_knight', 'paladin',
  'demon_general', 'legend_swordsman', 'dragon_knight',
  'grand_knight', 'immortal', 'paladin_leader', 'royal_guard_captain'
);

-- ranger 9개
UPDATE jobs SET role = 'ranger' WHERE id IN (
  'hunter_small',
  'archer_low', 'hunter_mid', 'deserter_archer', 'scout_low',
  'monster_hunter', 'archer_skilled', 'scout_leader',
  'ranger'
);

-- mage 16개
UPDATE jobs SET role = 'mage' WHERE id IN (
  'apprentice_mage',
  'necromancer_low', 'battle_mage', 'druid_low',
  'necromancer', 'archmage_mid', 'warlock', 'elementalist', 'spellblade', 'druid', 'summoner',
  'grand_necromancer', 'archmage', 'dimension_mage', 'ancient_druid', 'spirit_envoy'
);

-- rogue 8개
UPDATE jobs SET role = 'rogue' WHERE id IN (
  'pickpocket', 'nomad', 'messenger',
  'thief', 'smuggler',
  'assassin_low',
  'assassin',
  'world_assassin'
);

-- support 10개
UPDATE jobs SET role = 'support' WHERE id IN (
  'acolyte',
  'inquisitor_low', 'bard_combat', 'priest_mid',
  'inquisitor', 'high_priest', 'bard', 'strategist',
  'high_priest_supreme', 'oracle'
);

-- specialist 16개는 DEFAULT 'specialist'로 자동 할당:
-- T1 노동형 11개(beggar/miner/lumberjack/slave/farmer/shepherd/fisher/laborer/artisan_apprentice/peddler/herb_gatherer)
-- T2 novice_adventurer
-- T3 adventurer_mid
-- T4 adventurer_high
-- T5 hero, guild_master

-- P2 이슈 기록: T5에 ranger가 0개. 엔드게임 hunt 최고 보정(+8) T5 파티 구성 어려움.
-- M1 범위에서는 허용. M2b 이후 T5 ranger 직업 1개 신규 추가 권장 (예: 전설의 추적자).

-- §3.3 15개 트레잇 effect_json 업데이트 (상성 시너지)
-- 실제 traits.key 확인 후 balance report 의도에 맞게 매핑
-- 단위: %p (예: 5.0 = +5%p). 독립 상한 ±10%p는 QuestCalculator에서 clamp

UPDATE traits SET effect_json = '{"hunt_success_rate": 5.0, "explore_success_rate": 3.0}'::jsonb
  WHERE key = 'hunter_origin';      -- 사냥꾼 출신 (innate)

UPDATE traits SET effect_json = '{"explore_success_rate": 3.0, "hunt_success_rate": 2.0}'::jsonb
  WHERE key = 'wanderer_origin';    -- 방랑자 출신 (innate)

UPDATE traits SET effect_json = '{"hunt_success_rate": 3.0, "explore_success_rate": 3.0}'::jsonb
  WHERE key = 'scout';              -- 정찰병 (acquired)

UPDATE traits SET effect_json = '{"raid_success_rate": 4.0, "explore_success_rate": 3.0}'::jsonb
  WHERE key = 'shadow';             -- 그림자 (evolved)

UPDATE traits SET effect_json = '{"raid_success_rate": 3.0, "hunt_success_rate": 3.0}'::jsonb
  WHERE key = 'shadow_hunter';      -- 그림자 사냥꾼 (evolved)

UPDATE traits SET effect_json = '{"raid_success_rate": 5.0, "explore_success_rate": -2.0}'::jsonb
  WHERE key = 'charger';            -- 돌격대장 (acquired)

UPDATE traits SET effect_json = '{"escort_success_rate": 6.0}'::jsonb
  WHERE key = 'guardian';           -- 수호자 (acquired)

UPDATE traits SET effect_json = '{"success_rate": 3.0}'::jsonb
  WHERE key = 'strategist';         -- 전략가 (evolved)

UPDATE traits SET effect_json = '{"success_rate": 2.0}'::jsonb
  WHERE key = 'tactician';          -- 전술가 (acquired)

UPDATE traits SET effect_json = '{"explore_success_rate": 5.0}'::jsonb
  WHERE key = 'treasure_hunter';    -- 보물사냥꾼 (evolved)

UPDATE traits SET effect_json = '{"raid_success_rate": -3.0, "escort_success_rate": 3.0}'::jsonb
  WHERE key = 'coward_king';        -- 겁쟁이 군주 (evolved)

UPDATE traits SET effect_json = '{"success_rate": 3.0}'::jsonb
  WHERE key = 'focused';            -- 극도의 집중 (evolved)

UPDATE traits SET effect_json = '{"success_rate": 3.0, "raid_success_rate": 2.0}'::jsonb
  WHERE key = 'hero';               -- 영웅 (evolved)

UPDATE traits SET effect_json = '{"escort_success_rate": 4.0, "hunt_success_rate": 2.0}'::jsonb
  WHERE key = 'vigilant';           -- 경계심 (acquired)

UPDATE traits SET effect_json = '{"escort_success_rate": 4.0, "raid_success_rate": -2.0}'::jsonb
  WHERE key = 'iron_guard';         -- 철벽 수호 (acquired)


-- ============================================================================
-- §4. data_versions 일괄 증가
-- ============================================================================
-- 5개 테이블(ranks, factions, quest_pools, jobs, traits) 모두 버전 증가
-- 앱 포그라운드 복귀 시 SyncService가 자동으로 변경 감지 → 재다운로드

UPDATE data_versions
  SET version = version + 1, updated_at = NOW()
  WHERE table_name IN ('ranks', 'factions', 'quest_pools', 'jobs', 'traits');


COMMIT;


-- ============================================================================
-- 검증 쿼리 (수동 실행 권장 — 롤백은 별도 처리)
-- ============================================================================
-- 아래 쿼리를 트랜잭션 COMMIT 후 별도로 실행하여 결과 확인:
--
-- §1 검증:
--   SELECT grade, required_reputation, bonus_json FROM ranks ORDER BY required_reputation;
--   -- 기대: F=0 / E=300 / D=2000 / C=8000 / B=25000 / A=80000
--   -- 기대: F bonus_json={"effects":[]}, 나머지 5개 등급 effects 배열 non-empty
--
--   SELECT id, passive_bonus_json FROM factions
--     WHERE passive_bonus_json IS NOT NULL AND passive_bonus_json != '{}'::jsonb
--     ORDER BY id;
--   -- 기대: 14행
--
-- §2 검증:
--   SELECT column_name FROM information_schema.columns WHERE table_name='quest_pools' ORDER BY ordinal_position;
--   -- 기대: id, name, type, difficulty, min_region_diff, max_region_diff,
--   --       type_id, faction_tag, is_faction_exclusive, min_reputation, sector_type
--
--   SELECT COUNT(*) FROM quest_pools WHERE is_faction_exclusive = true;
--   -- 기대: 98
--
--   SELECT faction_tag, COUNT(*) FROM quest_pools WHERE is_faction_exclusive GROUP BY faction_tag ORDER BY faction_tag;
--   -- 기대: 14세력 × 7개
--
--   SELECT min_reputation, COUNT(*) FROM quest_pools WHERE is_faction_exclusive GROUP BY min_reputation;
--   -- 기대: 11=42, 61=56
--
--   SELECT type_id, COUNT(*) FROM quest_pools WHERE is_faction_exclusive GROUP BY type_id ORDER BY type_id;
--   -- 기대: raid 20 / hunt 25 / escort 24 / explore 29
--
-- §3 검증:
--   SELECT role, COUNT(*) FROM jobs GROUP BY role ORDER BY role;
--   -- 기대: mage 16 / ranger 9 / rogue 8 / specialist 16 / support 10 / warrior 26
--
--   SELECT key, name, effect_json FROM traits
--     WHERE effect_json IS NOT NULL AND effect_json != '{}'::jsonb
--     ORDER BY key;
--   -- 기대: 15행
--
-- §4 검증:
--   SELECT table_name, version FROM data_versions
--     WHERE table_name IN ('ranks','factions','quest_pools','jobs','traits')
--     ORDER BY table_name;
--   -- 기대: 각 테이블 기존 버전 +1
--     (실행 전: factions=1 / jobs=2 / quest_pools=1 / ranks=1 / traits=4
--      실행 후: factions=2 / jobs=3 / quest_pools=2 / ranks=2 / traits=5)

-- ============================================================================
-- 롤백 시 수동 조치 (긴급 시에만)
-- ============================================================================
-- ALTER TABLE ranks DROP COLUMN IF EXISTS bonus_json;
-- ALTER TABLE quest_pools DROP COLUMN IF EXISTS type_id, DROP COLUMN IF EXISTS faction_tag,
--                         DROP COLUMN IF EXISTS is_faction_exclusive, DROP COLUMN IF EXISTS min_reputation,
--                         DROP COLUMN IF EXISTS sector_type;
-- ALTER TABLE jobs DROP COLUMN IF EXISTS role;
-- DELETE FROM quest_pools WHERE id LIKE 'fq_%';
-- UPDATE factions SET passive_bonus_json = '{}'::jsonb;
-- UPDATE ranks SET required_reputation = 500 WHERE grade = 'E';
-- UPDATE traits SET effect_json = NULL WHERE key IN ('hunter_origin','wanderer_origin','scout','shadow','shadow_hunter','charger','guardian','strategist','tactician','treasure_hunter','coward_king','focused','hero','vigilant','iron_guard');
-- UPDATE data_versions SET version = version - 1 WHERE table_name IN ('ranks','factions','quest_pools','jobs','traits');
