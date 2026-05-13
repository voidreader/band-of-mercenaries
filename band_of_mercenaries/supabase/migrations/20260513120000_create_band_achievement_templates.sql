-- M6 페이즈 4 #1 마이그레이션 — band_achievement_templates 신규 테이블 + 시드
-- 명세서: Docs/spec/[spec]20260513_M6_phase4_1_achievement-chronicle.md §2.2(b), §6
-- 작성일: 2026-05-13
-- 선행: M5 페이즈 4 완료 (crafting_recipes 10행, elite_monsters elite_giant_bat 1행)
--
-- 주의사항 (실제 DB 조회 결과):
-- (1) elite_unique_first_kill: Supabase elite_monsters 테이블에 is_unique=true 행이 현재 없음
--     (elite_giant_bat는 is_unique=false). placeholder ID 7개는 향후 유니크 엘리트 데이터
--     삽입 시 실제 ID로 UPDATE 필요. elite_giant_bat는 명세 §6 그대로 유지.
-- (2) craft_first_rare: T3+ 레시피 실제 조회 결과 1개뿐
--     ('recipe_dustvile_pyegwang_relic' → item_artifact_pyegwang_relic, tier 3).
--     나머지 2개 placeholder(recipe_dustvile_banner_restoration=T2 실제, recipe_t3_placeholder=미존재)는
--     T3+ 조건 미충족으로 시드에서 제외. 최종 행 수: 26행 (28행에서 2행 제외).

BEGIN;

-- ============================================================
-- §1 band_achievement_templates 테이블 DDL
-- ============================================================

CREATE TABLE band_achievement_templates (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL,
  name TEXT NOT NULL,
  description_template TEXT NOT NULL,
  icon_key TEXT NOT NULL DEFAULT 'default',
  chronicle_variants JSONB DEFAULT '[]'::jsonb,
  default_priority TEXT NOT NULL DEFAULT 'high',
  narrative_hint TEXT,
  CONSTRAINT band_achievement_templates_category_check CHECK (category IN (
    'chain_completed',
    'settlement_event_completed',
    'settlement_trust_belonging',
    'reputation_rank',
    'elite_unique_first_kill',
    'craft_first_rare',
    'memorial'
  )),
  CONSTRAINT band_achievement_templates_priority_check CHECK (default_priority IN (
    'critical_inline', 'high', 'medium'
  ))
);

-- ============================================================
-- §2 시드 데이터 (26행 — craft_first_rare 2행 제외됨, 주석 참조)
-- 카테고리 분류:
--   chain_completed × 7
--   settlement_event_completed × 1
--   settlement_trust_belonging × 1
--   reputation_rank × 5
--   elite_unique_first_kill × 8 (placeholder 7개 + elite_giant_bat 1개)
--   craft_first_rare × 1 (T3+ 레시피 실제 확정 1개만 포함)
--   memorial × 3
-- 합계: 7 + 1 + 1 + 5 + 8 + 1 + 3 = 26행
-- ============================================================

INSERT INTO band_achievement_templates (id, category, name, description_template, icon_key, chronicle_variants, default_priority, narrative_hint) VALUES

-- (1) chain_completed × 7 — M3 산출물 chain_quests 24행 중 chain_* prefix 7개와 1:1 매칭
('chain_completed:chain_roadside_shrine', 'chain_completed', '길가의 폐사당을 열어주다',
 '{merc.name}이(가) 옛 수호자의 투구를 건네받았다.', 'chain_shrine',
 '["{merc.name}이(가) 잊혀진 길가에 빛을 되돌렸다.", "{merc.name}은 폐사당의 마지막 증인이 되었다."]', 'high',
 '체인 1단계 완주. 차분하고 의식적 톤'),

('chain_completed:chain_bandit_road', 'chain_completed', '도적의 길을 끊다',
 '{merc.name}이(가) 산길을 따라 흐르던 약탈의 흔적을 지웠다.', 'chain_bandit',
 '["{merc.name}이(가) 도적의 깃발을 마지막으로 거두었다."]', 'high',
 '도적 토벌 체인 완주'),

('chain_completed:chain_silent_grove', 'chain_completed', '침묵의 숲을 깨우다',
 '{merc.name}이(가) [pick 안개|어둠|침묵]을 헤치고 숲의 비밀을 마주했다.', 'chain_grove',
 '["{merc.name}의 발걸음이 숲의 잠을 깨웠다.", "오랜 침묵이 {merc.name} 앞에서 풀어졌다."]', 'high',
 '신비 톤. 변주 중요'),

('chain_completed:chain_iron_oath', 'chain_completed', '철의 서약에 응하다',
 '{merc.name}이(가) 옛 전우의 서약을 자신의 이름으로 마무리했다.', 'chain_oath',
 '["{merc.name}은 약속을 어기지 않았다."]', 'high',
 '서약·맹세 모티프'),

('chain_completed:chain_drowned_lighthouse', 'chain_completed', '물에 잠긴 등대를 다시 켜다',
 '{merc.name}의 손에서 등대의 불이 다시 타올랐다.', 'chain_lighthouse',
 '["{merc.name}이(가) 바다에 빛을 돌려놓았다."]', 'high',
 '해안 체인. 시각적 톤'),

('chain_completed:chain_witchs_circle', 'chain_completed', '마녀의 원을 끊다',
 '{merc.name}이(가) [pick 주문|결계|봉인]을 정면으로 마주하고 살아 돌아왔다.', 'chain_circle',
 '["마녀의 원 안에 {merc.name}의 이름이 새겨졌다."]', 'high',
 '주술·결계 모티프'),

('chain_completed:chain_soul_severance', 'chain_completed', '혼을 끊은 자',
 '{merc.name}이(가) 멸혼결을 완주하여 용병단의 전설이 되었다.', 'chain_severance',
 '["용병단의 가장 깊은 어둠을 {merc.name}이(가) 통과했다.", "{merc.name}의 이름은 더 이상 한 사람의 것이 아니었다."]', 'high',
 '엔드 체인. 무게감 최상'),

-- (2) settlement_event_completed × 1 — M4 더스트빌 폐광길 재개방
('settlement_event_completed:settlement_3_pyegwang_reopen', 'settlement_event_completed',
 '더스트빌 폐광길을 다시 열다',
 '더스트빌의 [pick 광장|마을길|광부 길드]에서 작은 잔치가 열렸다. 마을 사람들은 {merc.name}에게 고개를 숙였다.',
 'settlement_pyegwang',
 '["{merc.name}의 손으로 더스트빌의 빗장이 열렸다.", "광부들이 {merc.name}의 이름을 처음으로 부르기 시작했다."]', 'high',
 '거점 사건 완주. 마무리 step 파티 최고 기여자가 주인공'),

-- (3) settlement_trust_belonging × 1 — M5 더스트빌 4단계 소속
('settlement_trust_belonging:region_3', 'settlement_trust_belonging',
 '더스트빌의 한 식구',
 '용병단은 더스트빌 사람들에게 [pick 손님|동료|식구]로 받아들여졌다.',
 'settlement_belong',
 '["더스트빌의 문은 이제 용병단에게 닫히지 않는다."]', 'high',
 '거점 소속 진입. mercSnapshot 없음'),

-- (4) reputation_rank × 5 — E·D·C·B·A 각 1행 (F 제외)
('reputation_rank:E', 'reputation_rank', '이름을 새기다',
 '용병단의 [pick 첫 이름|첫 인장|첫 깃대]이(가) 명부에 올랐다.',
 'rep_rank_E',
 NULL, 'critical_inline',
 'E 신출내기 진입. RankUpDialog 본체 인라인'),

('reputation_rank:D', 'reputation_rank', '평범한 이름을 얻다',
 '용병단이 [pick 일반|평범한|이름 있는] 급으로 인정받았다.',
 'rep_rank_D',
 NULL, 'critical_inline',
 'D 일반 진입'),

('reputation_rank:C', 'reputation_rank', '능숙한 손길로 알려지다',
 '용병단의 손이 [pick 능숙하다|믿을 만하다|날카롭다]는 평을 듣는다.',
 'rep_rank_C',
 NULL, 'critical_inline',
 'C 능숙 진입'),

('reputation_rank:B', 'reputation_rank', '실력으로 부름 받다',
 '거점들마다 용병단의 이름이 [pick 먼저|먼저|이미] 들린다.',
 'rep_rank_B',
 NULL, 'critical_inline',
 'B 실력 진입'),

('reputation_rank:A', 'reputation_rank', '전설로 회자되다',
 '용병단의 이름이 [pick 노래|소문|이야기]에 실려 떠다닌다.',
 'rep_rank_A',
 NULL, 'critical_inline',
 'A 전설 진입'),

-- (5) elite_unique_first_kill × 8
-- elite_giant_bat: is_unique=false이나 명세 §6 원문 그대로 포함 (향후 is_unique 변경 또는 별도 처리 예정)
-- 나머지 7개: elite_monsters 테이블에 is_unique=true 행 미존재 (2026-05-13 조회 기준)
--   → placeholder ID 유지. 유니크 엘리트 데이터 INSERT 후 실제 ID로 UPDATE 필요.
--   조회 명령: SELECT id, tier FROM elite_monsters WHERE is_unique = true ORDER BY tier, id;
('elite_unique_first_kill:elite_giant_bat', 'elite_unique_first_kill', '거대 박쥐를 처음 사냥하다',
 '{merc.name}이(가) [pick 어둠|박쥐의 비명|폐광의 메아리] 사이에서 칼을 휘둘렀다.',
 'elite_bat',
 '["{merc.name}의 [pick 활시위|검|창]이 박쥐의 날개를 갈랐다."]', 'high',
 '거대 박쥐. M5 시점 등장. is_unique 여부는 페이즈 4 #1 구현 시 확인'),

-- 아래 7행: placeholder ID — 유니크 엘리트 데이터 추가 후 실제 ID로 UPDATE 필요
-- UPDATE band_achievement_templates SET id = 'elite_unique_first_kill:{실제ID}' WHERE id = 'elite_unique_first_kill:{placeholder}';
('elite_unique_first_kill:elite_t1_unique_a', 'elite_unique_first_kill', '들개왕을 처음 쓰러뜨리다',
 '{merc.name}이(가) 들개 무리의 우두머리를 [pick 한 합|단번|짧은 호흡]에 베어 넘겼다.',
 'elite_unique',
 NULL, 'high',
 'T1 유니크 placeholder. 실제 elite_monsters ID로 교체'),

('elite_unique_first_kill:elite_t1_unique_b', 'elite_unique_first_kill', '독사의 여왕을 끊다',
 '{merc.name}의 검 끝이 [pick 독|비늘|뱀의 노래]을 갈랐다.',
 'elite_unique',
 NULL, 'high',
 'T1 유니크 placeholder'),

('elite_unique_first_kill:elite_t2_unique_a', 'elite_unique_first_kill', '강가의 거인을 처음 쓰러뜨리다',
 '{merc.name}이(가) 강가의 [pick 그림자|발자국|메아리] 앞에서 멈추지 않았다.',
 'elite_unique',
 NULL, 'high',
 'T2 유니크 placeholder'),

('elite_unique_first_kill:elite_t2_unique_b', 'elite_unique_first_kill', '회색 늑대 무리장을 베다',
 '{merc.name}의 칼날에서 [pick 늑대의 호흡|이빨의 빛|밤의 침묵]이 잠시 멈췄다.',
 'elite_unique',
 NULL, 'high',
 'T2 유니크 placeholder'),

('elite_unique_first_kill:elite_t3_unique_a', 'elite_unique_first_kill', '폐허의 골렘을 무너뜨리다',
 '{merc.name}이(가) [pick 돌|먼지|시간]의 무게를 잠시 짊어졌다.',
 'elite_unique',
 NULL, 'high',
 'T3 유니크 placeholder'),

('elite_unique_first_kill:elite_t3_unique_b', 'elite_unique_first_kill', '심해의 그림자를 끊다',
 '{merc.name}의 발자국이 [pick 바다|어둠|차가운 물결] 위에 남았다.',
 'elite_unique',
 NULL, 'high',
 'T3 유니크 placeholder'),

('elite_unique_first_kill:elite_t4_unique_a', 'elite_unique_first_kill', '잊혀진 군주를 쓰러뜨리다',
 '{merc.name}이(가) 옛 왕좌의 [pick 무게|침묵|먼지] 앞에 섰다.',
 'elite_unique',
 NULL, 'high',
 'T4 유니크 placeholder'),

-- (6) craft_first_rare × 1 (실제 T3+ 레시피 확정 1개만 포함)
-- 조회 결과 (2026-05-13): T3+ 레시피 = recipe_dustvile_pyegwang_relic (item_artifact_pyegwang_relic, tier 3)
-- 제외된 2행:
--   recipe_dustvile_banner_restoration → item_banner_dustvile_repaired (tier 2, T3 조건 미충족)
--   recipe_t3_placeholder → 존재하지 않음
('craft_first_rare:recipe_dustvile_pyegwang_relic', 'craft_first_rare',
 '폐광의 유물을 처음 빚어내다',
 '낡은 대장간의 [pick 모루|불|망치]가 잊혀진 [pick 손길|숨결|울림]을 되찾았다.',
 'craft_relic',
 '["용병단의 첫 희귀품이 모루 위에서 식어갔다."]', 'high',
 'M5 폐광 유물 조각 T3 첫 제작'),

-- (7) memorial × 3 — MemorialCause enum 3종 (diedQuest / diedEvent / released)
('memorial:died_quest', 'memorial', '의뢰에서 잠들다',
 '{merc.name}이(가) [pick 마지막 의뢰|이름 없는 길|돌아오지 못한 길]에서 [pick 잠들었다|쓰러졌다|발을 멈췄다].',
 'memorial',
 '["용병단은 {merc.name}의 자리를 한참 비워두었다.", "{merc.name}의 이야기는 마지막 의뢰의 한 줄로 남았다."]', 'high',
 '파견 중 사망. memorial 톤. dialog enqueue X (recordMemorial)'),

('memorial:died_event', 'memorial', '길 위에서 잠들다',
 '{merc.name}이(가) [pick 이동 중|여행 중|길 위]에서 [pick 마지막 숨|마지막 인사|마지막 발걸음]을 남겼다.',
 'memorial',
 '["{merc.name}의 자취가 길 위에서 멈췄다."]', 'high',
 '여행 이벤트 사망'),

('memorial:released', 'memorial', '용병단을 떠나다',
 '{merc.name}이(가) [pick 짐을 챙기고|용병증을 돌려주고|마지막 의뢰를 마치고] 용병단을 떠났다.',
 'memorial',
 '["{merc.name}의 자리는 비어 있지만, 이름은 명부에 남았다."]', 'high',
 '자발/용량 방출. dialog enqueue X');

-- ============================================================
-- §3 data_versions 행 등록 (SyncService 동기화 대상 등록)
-- ============================================================

INSERT INTO data_versions (table_name, version) VALUES ('band_achievement_templates', 1);

COMMIT;
