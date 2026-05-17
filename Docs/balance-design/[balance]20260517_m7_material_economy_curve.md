# M7 지역 특산 재료 경제 곡선 밸런스 분석 리포트

> 작성일: 2026-05-17
> 유형: 밸런스 분석 + 수치 조정 제안 (M7 마일스톤 — 페이즈 2 산출물 1/3)
> 분석 대상: 8종 신규 region_exclusive 재료 drop_weight, M5 14~16개 레시피 수급 정합, 5 hook 균형, 5~8시간 누적 시뮬레이션
> 선행 문서:
> - `Docs/content-design/[content]20260516_m7_livingsphere_regions.md` — M7 페이즈 1 #1 7리전 + 8종 신규 region_exclusive 컨셉 3.2절
> - `Docs/content-design/[content]20260517_m7_livingsphere_progression_curve.md` — M7 페이즈 1 #4 5~8시간 분 단위 흐름 2절
> - `Docs/content-design/[content]20260517_m7_settlement_infrastructure_growth.md` — M7 페이즈 1 #3 인프라 단계별 거점 효과 multiplier
>
> 후속:
> - 페이즈 3 #2 "지역 특산 재료 10~20개" — 본 문서의 drop_weight 가이드를 입력으로 받아 items 8행 + quest_pool_material_drops 다수 INSERT
> - 페이즈 3 #4 "지역 상태별 퀘스트 풀 30~50개" — 본 문서의 hook 분배 비율을 입력으로 받아 quest_pool_material_drops 가중치 INSERT
> - 페이즈 3 #5 "마을 인프라 narrative + 체인 단계" — 본 문서의 외래 좌판 거래 가격 + 신규 레시피 재료 요구량을 입력

---

## 현재 상태

### 1. 재료 12종 현황 (M5 페이즈 4 #2 완료 시점)

5 slot × 5 tier 분포:

| slot | T1 (공용) | T1 (region_exclusive) | T2 (공용) | T2 (region_exclusive) | T3 (공용) | T3 (region_exclusive) |
|------|----------|---------------------|----------|---------------------|----------|---------------------|
| material_ore | 녹슨 쇳조각 | — | 연마된 쇳조각 | 녹슨 곡괭이 머리 (r3) | — | — |
| material_herb | 마른 약초 + 산기슭 버섯 | 접착 수액 (r3) | — | — | — | — |
| material_hide | 마른 가죽끈 | — | 빛바랜 천 조각 + 거친 가죽끈 묶음 | — | — | — |
| material_relic_fragment | — | — | — | 폐광의 유물 파편 (r3) | — | 고대 인장 조각 (r3) |
| material_monster_part | — | — | — | — | 거대 박쥐 송곳니 | — |
| **총** | 4종 | 2종 | 3종 | 2종 | 1종 | — |

→ region_exclusive **4종 모두 region 3 집중** (M5 진행 결과). M7 외출 동기 부족의 근본 원인.

### 2. M5 10개 레시피 재료 요구량 분석

| 레시피 | 결과 | 재료 요구 (총 수량) | 출처 hook | 해금 조건 |
|--------|------|-------------------|---------|----------|
| 단단한 갑옷 조각 | item_armor_solid_piece | ore 4 + hide 2 = **6** | 일반 | trust 2 |
| 낡은 깃발 복원 | item_banner_dustvile_repaired | hide(2종) 4 + dust resin 2 = **6** | 일반 | trust 2 |
| 약초 향낭 | item_accessory_herb_pouch | herb 7 + hide 2 = **9** | 일반 | trust 3 |
| 약초사 인장 | item_banner_herbalist_seal | herb 5 + hide 1 = **6** | 일반 | trust 3 |
| 거친 가죽끈 묶음 | mat_hide_rough_bundle (재료 변환) | hide 3 | 일반 | trust 2 |
| 광부의 부적 | item_artifact_miner_charm | ore 2 + relic shard 1 = **3** | r3 전용 | first_acquired |
| 광부의 단검 | item_weapon_miner_dagger | ore 3 + hide 1 + pickaxe 1 = **5** | r3 전용 | chain step 1 |
| 연마된 쇳조각 | mat_ore_polished_scrap (재료 변환) | ore 4 | 일반 | trust 2 |
| 폐광의 유물 조각 | item_artifact_pyegwang_relic | relic shard 3 + bat fang 1 + ancient seal 1 = **5** | r3 + elite | chain step 6 |
| 녹슨 곡괭이 | item_weapon_rusty_pickaxe | ore 2 + pickaxe 1 + hide 1 = **4** | r3 전용 | chain step 1 |

**총 재료 요구량 (10개 모두 1회 제작 시)**:
- mat_ore_rusty_scrap: 4+3+2+4+2 = **15개**
- mat_hide_dry_strap: 2+3+2+1+1+1 = **10개**
- mat_herb_dry: 4+3 = **7개**
- mat_herb_mountain_mushroom: 3+2 = **5개**
- mat_hide_faded_cloth: 1 = **1개**
- mat_herb_dust_resin: 2 = **2개**
- mat_relic_pyegwang_shard: 1+3 = **4개**
- mat_relic_pyegwang_pickaxe_head: 1+1 = **2개**
- mat_relic_ancient_seal_piece: 1 = **1개**
- mat_monster_giant_bat_fang: 1 = **1개**

### 3. 5 hook 현재 분포 (M5 완료 시점)

| Hook | 현재 행 수 | 활용도 | 비고 |
|------|----------|--------|------|
| 의뢰 `quest_pool_material_drops` | **16행** | 활발 | drop_rate 0.4~1.0, qty 1~3 분포 |
| 조사 `region_discoveries.discovery_data.items` | **~5행** | 중간 | region 3 폐광 시리즈 위주 |
| 엘리트 `elite_loot_tables` drop_type='material' | **1행** | **거의 미사용** | elite_giant_bat → bat_fang만 |
| 이동선택지 `travel_choice_results` effect='material_drop' | **6행** | 활발 | 모두 region 3 더스트빌 |
| 체인 `chain_quests.reward_items` JSONB | **1행** | 미사용 | settlement step 5만 |

→ **엘리트 hook 1/210 (0.5%) 활용도 — M7 핵심 개선 영역**

---

## 데이터 분석

### 1. 현재 drop_weight 패턴 (실측 통계)

`quest_pool_material_drops` 16행 분석:

| drop_rate 구간 | 행 수 | qty 분포 | 비고 |
|--------------|------|---------|------|
| 1.0 (100%) | 4행 | qty 1~3 | 사건 핵심 풀 (확정 드랍) |
| 0.8 | 3행 | qty 1~2 | T1·T2 가죽 채집 |
| 0.6 | 4행 | qty 1 | T1 광석 일반 |
| 0.5 | 3행 | qty 1 | T1 가죽·약초 정찰 |
| 0.4 | 1행 | qty 1 | dustvile_chore_05 가죽 |
| 0.05 | 1행 | qty 1 | mat_hide_faded_cloth (T2) — **극저드랍** |

**핵심 인사이트**: T1 일반 재료는 0.5~1.0, T2 일반 재료는 0.4~0.8, T2 region_exclusive 또는 희귀 재료는 0.05~0.4 분포. 본 문서는 이 패턴을 M7에 확장 적용한다.

### 2. M5 레시피 14~16개 정합 검증 (M7 신규 4~6개 포함)

**M7 페이즈 1 #3에서 결정된 신규 레시피 컨셉**:
- Tier 2: "야수 가죽 도구" (region 9 야수 처치 hook) + 1개 더 = **+2개**
- Tier 3: "유목민 가죽 장비" + "안개 늪 인장 장신구" + 1개 = **+3개**
- Tier 4: "부서진 요새 인장 장비" = **+1개**
- **총 +4~6개 신규 레시피**

**신규 레시피 재료 요구량 추정** (페이즈 3 #5 결정 의존, 본 문서는 가이드만):

| 레시피 | 결과 카테고리 | 재료 요구 (추정) | 출처 region | M7 누적 시점 |
|--------|-------------|----------------|------------|------------|
| 야수 가죽 도구 | personal_equipment T2 | 야수 송곳니 1 + 거친 가죽끈 묶음 2 = **3** | r9 hook | 4시간 |
| 들꽃 약초 향료 | consumable T1 | 들꽃 약초 3 + 마른 약초 2 = **5** | r31 hook | 3시간 |
| 유목민 가죽 장비 | personal_equipment T2 | 유목민 가죽끈 3 + 빛바랜 천 조각 1 = **4** | r127 hook + infra Tier 3 | 5시간 |
| 해안 약물 | consumable T1 | 해초 약재 2 + 산기슭 버섯 2 = **4** | r127 hook | 5시간 |
| 안개 늪 인장 장신구 | guild_equipment T2 | 늪의 인장 조각 2 + 독초 1 + 거친 가죽끈 묶음 1 = **4** | r146 hook | 7시간 |
| 부서진 요새 인장 장비 | guild_equipment T3 | 탄 인장 파편 2 + 연마된 쇳조각 2 + 고대 인장 조각 1 = **5** | r38 hook + infra Tier 4 | 8시간 |

**신규 8종 재료 총 요구량**:
- mat_herb_wildflower (r31 T1): 3
- mat_herb_seaweed (r127 T1): 2
- mat_hide_nomad_strap (r127 T2): 3
- mat_monster_beast_fang (r9 T2): 1
- mat_herb_wind (r10 T2): 0 (M7 MVP 레시피에 미사용, future 확장용)
- mat_herb_poison (r146 T2): 1
- mat_relic_swamp_seal (r146 T2): 2
- mat_relic_burnt_seal (r38 T3): 2

### 3. 5~8시간 의뢰 처리 횟수 추정

페이즈 1 #4 시나리오 2절 기반:
- 의뢰 평균 소요시간: 5~8분 (난이도 1·2 위주, 페이즈 2 #4 M4 결정)
- 5시간(300분) 시점 누적 의뢰 처리: ~50~60건
- 8시간(480분) 시점 누적: ~90~110건

**의뢰당 평균 재료 획득량** (현재 16행 평균 분석):
- 평균 drop_rate ≈ (1.0×4 + 0.8×3 + 0.6×4 + 0.5×3 + 0.4×1 + 0.05×1) / 16 = 0.66
- 평균 qty (성공 시) ≈ 1.4
- 의뢰당 기대 재료 획득 ≈ 0.66 × 1.4 = **0.92개**
- 단, 16개 풀 중 material_drop 보유 풀은 약 30% (페이즈 3 #4 신규 30~50개 신규 풀 추가 후 비율 변동)

**5시간 누적 재료 획득량 추정**:
- 의뢰 50건 × material_drop 보유율 30% × 기대량 0.92 = **약 14개 재료** (의뢰 hook만)
- + 엘리트 1~2회 × 평균 1개 = 2개
- + 이동선택지 5~8회 × 평균 1개 = 6개
- + 조사 2~3회 발견 × 평균 1개 = 3개
- + 체인 보상 1~2회 = 2개
- **5시간 누적 총량 ≈ 27개 재료**

**8시간 누적 추정**: ~50~60개 재료

---

## 문제점

### 1. 엘리트 hook 미활용 (210행 중 1행 = 0.5%)

elite_loot_tables 210행 중 material drop은 1행만. M5 단계에서 도입된 hook이지만 거의 활용 안 됨. M7에서 region 9 야수 송곳니(필수), region 31 도적 두목 가죽 등 신규 elite에서 material drop 활성화 필요.

**M7 페이즈 3 #2 권장 추가**:
- region 9 forest elite (거대 야수 종류) → 야수 송곳니 (drop_rate 1.0, rare)
- region 38 ruins elite (도굴꾼 두목) → 탄 인장 파편 (drop_rate 0.5, rare)
- region 146 swamp elite (안개 야수) → 늪의 인장 조각 (drop_rate 0.6, rare)
- region 31·127 일반 quest_pool (elite 무관) — material_drop 추가

### 2. region 3 일변도 (모든 hook이 region 3 집중)

- 의뢰: 16행 모두 r3 풀 (`dustvile_*` / `qp_dv_*`)
- 이동선택지: 6행 모두 r3 (`tce_dustvile_*`)
- 엘리트: 1행 모두 r3 폐광 (giant_bat)

**M7 페이즈 3 분배 권장**:

| Hook | M5 (현재) | M7 추가 후 | r3 | r31 | r127 | r9 | r10 | r146 | r38 |
|------|----------|----------|----|----|------|----|----|------|----|
| 의뢰 풀 material_drops | 16행 (r3 100%) | 50행 | 16 | 6 | 5 | 8 | 4 | 6 | 5 |
| 이동선택지 | 6행 (r3 100%) | 14행 | 6 | 2 | 2 | 2 | 1 | 1 | 0 |
| 엘리트 | 1행 (r3) | 5행 | 1 | 0 | 0 | 2 | 0 | 1 | 1 |
| 조사 | ~5행 (r3 위주) | 15~20행 | 5 | 1 | 2 | 2 | 1 | 2 | 3 |
| 체인 reward | 1행 (r3) | 5~7행 | 2 | 1 | 0 | 0 | 1 | 0 | 2 |

→ **r3은 보존**, 외곽 6리전에 균등 분배 (각 4~12행 추가).

### 3. mat_hide_faded_cloth 드랍률 극저 (0.05)

T2 가죽 재료 mat_hide_faded_cloth는 현재 quest_pool에서 5% 드랍만. "낡은 깃발 복원" 레시피의 핵심 재료지만 의뢰로 거의 못 얻음 → 사실상 chain 보상 / travel_choice (1행 0.5%) 의존.

**권장 조정**: 0.05 → 0.20 (4배 상승) 또는 신규 외곽 의뢰 풀에 material_drop 추가. 페이즈 3 #4에서 확정.

### 4. 광장 이정표 효과 정량 부재

페이즈 1 #3에서 결정된 광장 이정표 효과 "이동 시간 -10%"가 재료 수급에 미치는 영향 미정량화. 본 문서에서 정량 추가:

- 8시간 총 이동 시간 추정: ~1.5~2시간 (총 시간의 25%, 페이즈 1 #4 시나리오 기반)
- -10% 효과 → 약 9~12분 절감 → 추가 의뢰 1~2건 처리 가능
- 재료 수급 영향: 약 **+3% (5~8시간 누적 기준)** — 미미하지만 체감 가능
- **권장**: -10%는 적정 수준 (체감 가능 + 경제 충격 작음). 페이즈 2 #3 검토 시 그대로 유지

---

## 플레이어 체감 분석

### 1. region 3 의존 → "이동 동기 부족" 체감

현재 M5 시점: 더스트빌에서 의뢰만 돌려도 모든 재료 수급 가능. 외곽 진출은 명성 잠금 해제 외 동기 약함.

**M7 적용 후**: region 9 야수 송곳니가 region 9에서만 채집 가능 → "야수 가죽 도구"를 만들려면 외곽 외출 필수. 페이즈 1 #1 컨셉 충실.

### 2. 5시간 시점 제작 목표 2+ 도달 가능성

페이즈 1 #4 시나리오에서 5시간(구간 G 종료) 시점에 제작 목표 3개 달성:
- M4 폐광 진행 중 단검 (단일 trial)
- M7 야수 가죽 도구 (region 9 hook)
- M7 유목민 가죽 장비 (region 127 hook + Tier 3)

**수급 검증** (5시간 누적 ~27개 재료 기준):
- 야수 가죽 도구 (재료 3): 야수 송곳니 1 + 거친 가죽끈 묶음 2 (=마른 가죽끈 6개 변환) → **총 7개 재료 필요**. 5시간 수급으로 가능 ✅
- 유목민 가죽 장비 (재료 4): 유목민 가죽끈 3 + 빛바랜 천 조각 1 → 가능, 단 빛바랜 천 조각 드랍률 0.05 보정 필수 ⚠️

### 3. T3 재료 (탄 인장 파편) 접근성

T3 region_exclusive 재료는 region 38(부서진 요새, T3 잠금 명성 2,000)에서만 채집. M7 종료 시점(8시간) 명성 2,000~5,000 도달 가정 시 6~8시간 구간에 채집 가능.

**8시간 시점 누적 (~50~60개) 중 탄 인장 파편 추정**:
- 의뢰 hook drop_rate 0.4 × qty 1 평균 = 의뢰당 0.4개
- region 38 의뢰 처리 5건 가정 → 2개 (충분)
- + elite hook 0.5 × 1회 = 0.5개
- + 체인 보상 2개 (chain_ironbound_pact reward_items)
- **8시간 누적 ~4.5개** → 부서진 요새 인장 장비 1개 제작 (2개 필요) 가능 ✅ + 1~2개 여유

---

## 조정 제안

### 1. 8종 신규 region_exclusive 재료 drop_weight 확정안

**현재 패턴 (분석 결과 기반) → 권장 drop_weight**:

| 신규 재료 | slot | tier | region_exclusive | 출처 hook | drop_rate | qty | 비고 |
|----------|------|------|-----------------|----------|-----------|-----|------|
| mat_herb_wildflower (들꽃 약초) | material_herb | 1 | 31 | 의뢰 (escort/explore 풀) | **0.7** | 1~2 | T1 일반 (마른 약초 패턴) |
| mat_herb_seaweed (해초 약재) | material_herb | 1 | 127 | 의뢰 (explore 풀) + 조사 | **0.6** | 1~2 | T1 일반 |
| mat_hide_nomad_strap (유목민 가죽끈) | material_hide | 2 | 127 | 외래 좌판 거래 (Tier 3) + 의뢰 (escort) | **0.5** | 1 | T2 region_exclusive |
| mat_monster_beast_fang (야수 송곳니) | material_monster_part | 2 | 9 | 엘리트 (확정 드랍) + 의뢰 (hunt) 일부 | **엘리트 1.0 / 의뢰 0.3** | 1 (엘리트) / 1 (의뢰) | T2 region_exclusive, elite hook 활용 핵심 |
| mat_herb_wind (바람약초) | material_herb | 2 | 10 | 의뢰 (explore) + 조사 | **0.5** | 1~2 | T2 region_exclusive |
| mat_herb_poison (독초) | material_herb | 2 | 146 | 의뢰 (explore) + 조사 | **0.4** | 1 | T2 region_exclusive, swamp 위험 |
| mat_relic_swamp_seal (늪의 인장 조각) | material_relic_fragment | 2 | 146 | 엘리트 (안개 야수) + 조사 | **엘리트 0.6 / 조사 1.0** | 1 | T2 region_exclusive |
| mat_relic_burnt_seal (탄 인장 파편) | material_relic_fragment | 3 | 38 | 의뢰 (raid/explore) + 엘리트 (도굴꾼 두목) + 체인 보상 | **의뢰 0.4 / 엘리트 0.5 / 체인 확정** | 1 | T3 region_exclusive, 가장 희소 |

**근거**:
- T1 region_exclusive (들꽃·해초): 0.6~0.7 — M5 r3 dust_resin 1.0보다 낮은 이유는 신규 채집 학습 필요. 페이즈 3 #4 r31·r127 신규 의뢰 풀과 정합
- T2 region_exclusive: 0.4~0.6 — M5 r3 polished_scrap·pickaxe_head 1.0보다 낮음 (희소도 ↑). 엘리트 hook과 분산
- T3 region_exclusive: 0.4 — M5 r3 ancient_seal 1.0보다 낮음 (가장 희소, M7 후반부 도달)

### 2. 5 hook 분배 비율 권장

페이즈 3 #2·#4 데이터 생성 시 다음 비율 적용:

| Hook | M7 종료 시점 행 수 (목표) | r3 보존 | r31 | r127 | r9 | r10 | r146 | r38 |
|------|------------------------|--------|-----|------|-----|-----|------|-----|
| 의뢰 `quest_pool_material_drops` | **50행** (+34) | 16 | 6 | 5 | 8 | 4 | 6 | 5 |
| 조사 `region_discoveries.discovery_data` | **20행** (+15) | 5 | 1 | 2 | 2 | 1 | 2 | 3 |
| 엘리트 `elite_loot_tables` material | **5~8행** (+4~7) | 1 (giant_bat 유지) | 0 | 0 | 2 (forest beast) | 0 | 1 (swamp mist) | 1~2 (ruins boss) |
| 이동선택지 `travel_choice_results` material | **14행** (+8) | 6 | 2 | 2 | 2 | 1 | 1 | 0 |
| 체인 `chain_quests.reward_items` material | **5~7행** (+4~6) | 2 (settlement step 5 유지) | 1 (roadside_shrine) | 0 | 0 | 1 (windrunner) | 0 | 2 (ironbound) |

**Hook별 균형 검증**:
- 의뢰가 가장 많음 (50/103 = 49%) — 가장 빈번한 활동이므로 자연스러움
- 엘리트 비중 5~8% — M5에서 0.5%였던 것이 정상화
- 조사·이동선택지·체인이 각 13~19% — 보조 hook으로 균형

### 3. mat_hide_faded_cloth 드랍률 조정

현재 0.05 (5%) → **0.20 (20%)** 조정. 변경 전·후 비교:

| 항목 | 변경 전 (0.05) | 변경 후 (0.20) |
|------|--------------|--------------|
| 8시간 누적 획득량 (의뢰 hook 기준) | 0.5개 | 2~3개 |
| 낡은 깃발 복원 (요구 1개) 제작 가능성 | 매우 낮음 (체인 의존) | 충분 (M4~M7 어디서나) |
| 다른 hook 영향 | travel_choice 0.5%만 보조 | 가죽 채집 학습 곡선 안정 |

→ M5 단계 회고: 0.05는 명확한 over-tuning. M7 페이즈 3 #4 데이터 추가 시점에 함께 조정 권장.

### 4. 광장 이정표 효과 정량 (페이즈 2 #3 입력)

**현재 권장 -10% 유지**:
- 5~8시간 누적 의뢰 처리 횟수 ~3% 증가 (재료 수급 ~3% 증가)
- 체감: 외곽 이동 잦은 플레이어에게 가시적 + 거점 머무는 플레이어에게는 영향 없음
- 경제 충격: 무시 가능 수준 (~3% 추가 골드 = 5~8시간 누적 +60~120G)

**페이즈 2 #3 검토 옵션**:
- 옵션 A (권장): -10% 유지
- 옵션 B: -15% 강화 (이동 잦은 플레이어 보상 ↑)
- 옵션 C: -5% 약화 (경제 영향 최소화)

### 5. 외래 좌판 거래 가격 (페이즈 2 #3 + 페이즈 4 #4 입력)

페이즈 1 #3에서 결정된 외래 좌판 [재료 거래] 기능의 가격 정량화:

| 재료 | 채집 시간 추정 (5~8시간 평균) | 채집 골드 가치 (기회비용) | 외래 좌판 권장 가격 |
|------|------------------------------|-------------------------|-----------------|
| mat_hide_nomad_strap (r127 T2) | ~20분 외출 (r3→r127→채집) | ~80G | **120G** (시간 절약 50% 프리미엄) |
| mat_herb_wildflower (r31 T1) | ~10분 | ~40G | **60G** |
| mat_relic_burnt_seal (r38 T3) | ~30분 (r38 진입 + 채집) | ~150G | **250G** (희소도 + 위험도 프리미엄) |

**Tier별 가격 가이드**:
- T1 region_exclusive 재료: 50~80G
- T2 region_exclusive 재료: 100~150G
- T3 region_exclusive 재료: 200~300G

**Tier 4 도달 시 외래 좌판 확장 (페이즈 1 #3)**:
- 거래 종류 +50% → Tier 3 4종 거래 → Tier 4 6종 거래
- 가격 변동 없음 (단, M5 페이즈 4 #2 거점 효과 +20% 적용 시 -20% 할인 검토 — 페이즈 2 #3 결정)

---

## 시뮬레이션

### 시나리오: 평균 페르소나 5~8시간 흐름 (페이즈 1 #4 2절 기반)

**5시간(300분) 시점 누적 재료 표** (M5 + M7 신규 8종):

| 재료 | 5시간 시점 추정 | 5시간 시점 필요량 (지금까지 제작) | 잉여/부족 |
|------|---------------|---------------------------------|---------|
| mat_ore_rusty_scrap | 14개 | 7개 (단단한 갑옷 + 폐광 단검) | +7 |
| mat_hide_dry_strap | 12개 | 4개 (단단한 갑옷 + 광부의 단검) | +8 |
| mat_herb_dry | 5개 | 0개 | +5 (보관) |
| mat_herb_wildflower (신규 r31) | 4개 | 3개 (들꽃 약초 향료) | +1 |
| mat_herb_seaweed (신규 r127) | 3개 | 2개 (해안 약물) | +1 |
| mat_hide_nomad_strap (신규 r127) | 3개 | 3개 (유목민 가죽 장비) | 0 (딱 맞음) |
| mat_monster_beast_fang (신규 r9) | 2개 | 1개 (야수 가죽 도구) | +1 |
| mat_hide_faded_cloth | 1~2개 (0.20 조정 후) | 1개 (낡은 깃발 — M4부터 가능) | 0 ~ +1 |
| mat_relic_pyegwang_shard | 4개 | 3개 (폐광 유물) | +1 |
| mat_relic_pyegwang_pickaxe_head | 2개 | 2개 (단검 + 곡괭이) | 0 |

→ **5시간 시점 제작 목표 모두 충족 ✅** (제작 목표 3개 = 야수 가죽 도구 + 유목민 가죽 장비 + 들꽃 약초 향료)

**8시간(480분) 시점 누적 재료 표** (추가):

| 재료 | 8시간 시점 추정 | 8시간 시점 필요량 (Tier 4 도달 시 제작 목표) | 잉여/부족 |
|------|---------------|---------------------------------|---------|
| mat_herb_wind (신규 r10) | 2~3개 | 0개 (M7 MVP 미사용) | +2~3 (보관) |
| mat_herb_poison (신규 r146) | 2개 | 1개 (안개 늪 인장 장신구) | +1 |
| mat_relic_swamp_seal (신규 r146) | 3개 | 2개 (안개 늪 인장 장신구) | +1 |
| mat_relic_burnt_seal (신규 r38) | 4개 | 2개 (부서진 요새 인장 장비) | +2 |
| mat_ore_polished_scrap | 3개 | 2개 (부서진 요새 인장 장비) | +1 |
| mat_relic_ancient_seal_piece | 2개 | 2개 (폐광 유물 1개 + 부서진 요새 인장 장비 1개) | 0 |
| mat_monster_giant_bat_fang | 1~2개 | 1개 (폐광 유물) | 0 ~ +1 |

→ **8시간 시점 제작 목표 모두 충족 ✅** (Tier 4 도달 시 부서진 요새 인장 장비까지 제작 가능)

**총 8시간 제작 가능 레시피** (M4 첫 + M7 6개 = 7개 최소):
- M4: 광부의 단검 / 광부의 부적 / 녹슨 곡괭이 / 폐광의 유물 조각 / 단단한 갑옷 조각 / 낡은 깃발 / 거친 가죽끈 묶음 / 연마된 쇳조각 = 8개
- M7 신규: 야수 가죽 도구 / 유목민 가죽 장비 / 부서진 요새 인장 장비 / 들꽃 약초 향료 / 해안 약물 / 안개 늪 인장 장신구 = 6개
- **총 14개 = M5 10개 + M7 4개 (변환 레시피 2개 제외 시 12개)** — M5 10개 → M7 14~16개 목표와 정합 ✅

### 단계별 골드 흐름

페이즈 1 #4 2절 5~8시간 시나리오에서 외래 좌판 거래 도입 시 골드 영향:

| 구간 | 외래 좌판 활용 시 골드 흐름 | 미활용 시 |
|------|--------------------------|---------|
| 구간 G (4~5시간) Tier 3 진입 후 | 유목민 가죽끈 1개 구매 = -120G | 외출 30분 추가 |
| 구간 I·J (6~8시간) Tier 4 활용 | 탄 인장 파편 1개 구매 = -250G | 외출 30분 추가 |
| **총 골드 영향** | **약 -370G** (구매 활용 시) | 약 +200G (의뢰 추가) |

**경제 충격 분석**: 외래 좌판 활용은 골드를 시간으로 환산 — 시간 부족 플레이어에게는 가치, 골드 부족 플레이어에게는 페널티. **균형적** (필수 아닌 선택). 페이즈 2 #3에서 가격 미세 조정 가능.

---

## data-generator 수치 가이드

페이즈 3 #2 (items 8행) + 페이즈 3 #4 (quest_pool_material_drops 추가 ~34행) + 페이즈 3 #3 (region_discoveries.discovery_data ~15행) 데이터 생성 시 적용 가이드:

- **대상 타입**: `item` (재사용) + `quest-pool` (재사용) + `region-environment-tag` (재사용)
- **대상 테이블**: `items` (8행 INSERT) + `quest_pool_material_drops` (~34행 INSERT) + `region_discoveries` (~15행 신규 + discovery_data 업데이트) + `elite_loot_tables` (~4~7행 INSERT) + `travel_choice_results` (~8행 INSERT) + `chain_quests.reward_items` (~4~6행 UPDATE)
- **수치 범위**:
  - drop_rate: T1 region_exclusive 0.6~0.7 / T2 region_exclusive 0.4~0.6 / T3 region_exclusive 0.3~0.5
  - 엘리트 drop_rate: 확정 드랍 1.0 / 일반 0.5~0.6 / 희귀 0.3~0.5
  - qty_min·qty_max: 의뢰 1~2 / 엘리트 1 / 조사 1~2 / 이동선택지 1~2 / 체인 reward 1~3
  - mat_hide_faded_cloth 기존 행 drop_rate: 0.05 → 0.20 UPDATE
- **외래 키 제약**: 
  - region_exclusive 컬럼 값이 7리전 ID(3·31·127·9·10·146·38) 내에만 분포
  - elite_id는 신규 elite 추가 후 INSERT (페이즈 3 #2 #4와 동시)
- **balance 근거**: 본 문서 3절 분배 비율 표 + 5~8시간 누적 시뮬레이션 검증 (조정 제안 1·2절)

### Hook별 우선순위

1. **의뢰 hook** (50행): 페이즈 3 #4 quest_pools 30~50개 신규 풀 INSERT와 동시 진행. material_drop 자동 매핑
2. **엘리트 hook** (5~8행): region 9·146·38 신규 elite 추가 + drop_type='material' INSERT — M7 페이즈 3 별도 산출물 검토
3. **조사 hook** (15행): 페이즈 3 #3 region_discoveries 20~40개 신규 INSERT와 동시 진행
4. **이동선택지 hook** (8행): 페이즈 3 #4 또는 별도 산출물에서 travel_choice 신규 12행 + material_drop 매핑
5. **체인 hook** (4~6행): 기존 chain_quests reward_items 컬럼 UPDATE — chain_roadside_shrine / chain_windrunner_trail / chain_ironbound_pact 완주 보상에 material 1~3종 추가

### 검증 항목

- items 8행 INSERT 후 region_exclusive 분포: r3=4(기존) + r31=1 + r127=2 + r9=1 + r10=1 + r146=2 + r38=1 = **총 12개** ✅
- 5 hook 분배 비율 검증 (3절 표): 의뢰 50 / 조사 20 / 엘리트 5~8 / 이동선택지 14 / 체인 5~7 = **합계 약 94~99행**
- 8시간 누적 시뮬레이션 재검증 (시뮬레이션 절): M5 10 + M7 4~6 = 14~16개 레시피 제작 가능 ✅
- mat_hide_faded_cloth drop_rate UPDATE 1행 (qp_dv_v2_supply) 0.05 → 0.20

### 5 hook 균형 검증

| Hook | 행 수 | 비중 | M5 시점 비중 | 변화 |
|------|------|------|------------|------|
| 의뢰 | 50 | 51% | 16/29 = 55% | -4% (균형 유지) |
| 조사 | 20 | 20% | 5/29 = 17% | +3% |
| 이동선택지 | 14 | 14% | 6/29 = 21% | -7% (r3 외에 분산) |
| 체인 | 6 | 6% | 1/29 = 3% | +3% |
| 엘리트 | 8 | 8% | 1/29 = 3% | **+5% (핵심 개선)** |

→ 엘리트 hook 활용도 0.5% → 8%로 정상화 (16배 상승). M5 단계 hook 모두 활성화 ✅
