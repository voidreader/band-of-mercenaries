# M7 페이즈 3 산출물 3 메타: 지역 상태별 고정 발견 15행 신규

> 작성일: 2026-05-17
> 마일스톤: M7 (지역 생활권 확장)
> 페이즈: 3 #3
> 산출 파일: `Docs/content-data/[region-discovery]20260517_m7-discoveries.csv`

---

## 생성 근거

### 참조 기획 문서

- `Docs/content-design/[content]20260516_m7_livingsphere_regions.md` (페이즈 1 #1) — 7리전 매핑 + 사건 후보
- `Docs/content-design/[content]20260516_m7_region_state_rules.md` (페이즈 1 #2) — dangerScore + unlockedFlags
- `Docs/balance-design/[balance]20260517_m7_material_economy_curve.md` (페이즈 2 #1) — 조사 hook 분배 표 + drop_weight

### data-generator 미사용 사유

- 본 작업은 `region_discoveries` 테이블 INSERT (지원 타입 미존재 — region-discovery 타입은 추후 마일스톤 진입 시 추가 예정)
- 지원되는 `region-environment-tag` 타입은 regions.environment_tags UPDATE 전용 (M2b 특화)
- M2b 선례 `[region-discovery]20260423_m2b-elite-discoveries.csv`도 동일하게 인라인 처리됨
- 페이즈 3 #1 region_adjacency 처리 패턴 답습

---

## 생성 요약

### 총 15행 INSERT

| # | id | region | k 임계 | type | 핵심 재료 |
|---|----|--------|--------|------|---------|
| 1 | rdsc_m7_r31_wildflower | 31 | 20 | normal | mat_herb_wildflower q=2 dr=0.7 |
| 2 | rdsc_m7_r31_bandit_strap | 31 | 45 | normal | mat_hide_dry_strap q=2 dr=0.6 |
| 3 | rdsc_m7_r127_seaweed | 127 | 40 | normal | mat_herb_seaweed q=2 dr=0.6 |
| 4 | rdsc_m7_r127_nomad_strap | 127 | 55 | normal | mat_hide_nomad_strap q=1 dr=0.5 |
| 5 | rdsc_m7_r127_foreign_rumor | 127 | 80 | info | (text only) |
| 6 | rdsc_m7_r9_hide_glade | 9 | 25 | normal | mat_hide_dry_strap q=2 dr=0.8 |
| 7 | rdsc_m7_r9_beast_track | 9 | 50 | normal | mat_monster_beast_fang q=1 dr=0.3 |
| 8 | rdsc_m7_r9_beast_howl | 9 | 15 | info | (text only) |
| 9 | rdsc_m7_r10_wind_herb | 10 | 35 | normal | mat_herb_wind q=2 dr=0.5 |
| 10 | rdsc_m7_r10_swordsman_trace | 10 | 20 | info | (text only) |
| 11 | rdsc_m7_r146_poison_grove | 146 | 40 | normal | mat_herb_poison q=1 dr=0.4 |
| 12 | rdsc_m7_r146_swamp_seal | 146 | 65 | normal | mat_relic_swamp_seal q=1 dr=0.5 |
| 13 | rdsc_m7_r146_mist_omen | 146 | 85 | hidden_quest | chain_m7_mist_clearing start_step 1 |
| 14 | rdsc_m7_r38_polished_scrap | 38 | 55 | normal | mat_ore_polished_scrap q=2 dr=0.6 |
| 15 | rdsc_m7_r38_burnt_seal | 38 | 80 | normal | mat_relic_burnt_seal q=1 dr=0.4 |

### discovery_type 분포

- **normal**: 11행 (재료 채집 hook 67% — 페이즈 2 #1 권장 충족)
- **info**: 3행 (외래 상인 풍문 / 거대 야수 울음 / 검술 자취)
- **hidden_quest**: 1행 (안개 사건 — 페이즈 3 #5 신규 체인 의존)

### region 분배 (페이즈 2 #1 정합)

| Region | M5 기존 | M7 신규 | M7 종료 시점 합계 |
|--------|--------|--------|------------------|
| 3 더스트플레인 | 3 | 0 (보존) | 3 |
| 31 도적길 | 1 | 2 | 3 |
| 127 변방 해안 | 3 | 3 | 6 |
| 9 외곽 숲 | 1 | 3 | 4 |
| 10 풍신 숲 | 1 | 2 | 3 |
| 146 회색 늪지 | 1 | 3 | 4 |
| 38 부서진 요새 | 1 | 2 | 3 |
| **합계** | **11** | **15** | **26** |

### 8종 신규 region_exclusive 재료 매핑 검증

| 재료 | 매핑 발견 | dr | qty |
|------|---------|-----|-----|
| mat_herb_wildflower | #1 (r31) | 0.7 | 2 |
| mat_herb_seaweed | #3 (r127) | 0.6 | 2 |
| mat_hide_nomad_strap | #4 (r127) | 0.5 | 1 |
| mat_monster_beast_fang | #7 (r9) | 0.3 (조사 hook) | 1 |
| mat_herb_wind | #9 (r10) | 0.5 | 2 |
| mat_herb_poison | #11 (r146) | 0.4 | 1 |
| mat_relic_swamp_seal | #12 (r146) | 0.5 | 1 |
| mat_relic_burnt_seal | #15 (r38) | 0.4 | 1 |

→ **8/8 모두 매핑** ✅

---

## 검증 결과

### 자체 검증 체크리스트

- [x] 모든 `id`가 `rdsc_m7_r{region}_{slug}` 형식
- [x] 모든 `id`가 유일 (내부 중복 없음 + Supabase 기존 22행과 중복 없음)
- [x] `region_id` 모두 7리전 ID(31·127·9·10·146·38) 내 (r3은 미사용 — 보존)
- [x] `knowledge_threshold` 15~85 범위 (info 낮음 15~80 / normal 중간 20~80 / hidden_quest 높음 85)
- [x] `discovery_type` 3종 사용 (normal 11, info 3, hidden_quest 1)
- [x] `discovery_data.items.item_id` 모두 items 테이블에 실존 (M7 신규 8종 + M5 공용 1종 mat_hide_dry_strap·mat_ore_polished_scrap 활용)
- [x] drop_rate 페이즈 2 #1 권장 범위 준수 (T1 0.6~0.8 / T2 0.3~0.5 / T3 0.4)
- [x] description 한국어 30~50자 (기존 행 톤 답습)

### drop_rate 페이즈 2 #1 권장 정합

| Tier 범주 | 페이즈 2 #1 권장 | 본 산출물 적용 |
|----------|---------------|--------------|
| T1 region_exclusive | 0.6~0.7 | wildflower 0.7 / seaweed 0.6 ✅ |
| T2 region_exclusive | 0.4~0.6 | nomad_strap 0.5 / wind 0.5 / poison 0.4 / swamp_seal 0.5 ✅ |
| T2 monster_part 조사 hook | 0.3 | beast_fang 0.3 ✅ (엘리트 1.0 별도) |
| T3 region_exclusive | 0.3~0.5 | burnt_seal 0.4 ✅ |
| T1 공용 | 0.6~0.8 | hide_glade 0.8 / bandit_strap 0.6 ✅ |
| T2 공용 (광석) | 0.6 | polished_scrap 0.6 ✅ |

---

## 주의 사항

### chain_m7_mist_clearing 신규 체인 의존

#13 `rdsc_m7_r146_mist_omen`은 페이즈 3 #5에서 추가될 **신규 체인** `chain_m7_mist_clearing` 참조:
- chain_quests 테이블에 외래 키 제약 없음 (chain_id는 자유 TEXT 값)
- 본 산출물 INSERT 시점에 chain_quests에 chain_m7_mist_clearing 미존재 → 발견 트리거가 발동되어도 ChainQuestService가 chain 데이터 없음 처리 (fail-soft 처리 가정)
- 페이즈 3 #5에서 chain_m7_mist_clearing 단일 단계 체인 추가 시 자동 활성화

### r3 보존 정책

r3 더스트플레인 기존 3개 발견은 보존, 본 산출물에서 r3에 신규 추가 안 함. 외출 동기 강화를 위해 외곽 6리전에만 분산.

### M5 공용 재료 매핑 (#2, #6, #14)

페이즈 1 #1·#2에서 신규 region_exclusive 8종 외에도 M5 공용 재료(mat_hide_dry_strap, mat_ore_polished_scrap)도 일부 발견에 포함:
- #2 r31 도적 가죽끈 — bandit 키워드 + 가죽 채집 자연 통합
- #6 r9 외곽 숲 가죽 — 가죽 주력 region 컨셉 정합
- #14 r38 광석 채굴 — 페이즈 1 #1 r38 광석 채굴 hook과 정합

---

## Supabase 쓰기 옵션

- **옵션 A (권장)**: 즉시 INSERT — 단순 15행, items 외래 키만 의존 (확인 완료), region 외래 키 검증 완료
- 옵션 B: CSV만 남기고 페이즈 4 마이그레이션 단계에서 통합

---

## 다음 단계 권장

- **페이즈 3 산출물 3번 완료** → milestone-runner로 갱신
- **다음 페이즈 3 산출물 4번**: 지역 상태별 퀘스트 풀 30~50개 → `/data-generator quest-pool --brief @Docs/balance-design/[balance]20260517_m7_region_state_thresholds.md`

---

## 참고: 기존 M2b region-discovery CSV 패턴 답습

본 산출물은 M2b 단계 `[region-discovery]20260423_m2b-elite-discoveries.csv` 패턴 답습:
- 헤더: id, region_id, knowledge_threshold, discovery_type, discovery_data, description
- discovery_data JSONB 직렬화 + 쌍따옴표 이스케이프
- description 한국어 1~2문장 톤

M7·M8·M9에서 region_discoveries 신규 추가 시 본 산출물 형식 그대로 확장 가능.
