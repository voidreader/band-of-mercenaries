# M7 페이즈 3 산출물 2 메타: 지역 특산 재료 8종 신규

> 작성일: 2026-05-17
> 마일스톤: M7 (지역 생활권 확장)
> 페이즈: 3 #2
> 산출 파일: `Docs/content-data/[item]20260517_m7-region-exclusive.csv`

---

## 생성 근거

### 참조 기획 문서

- `Docs/content-design/[content]20260516_m7_livingsphere_regions.md` (페이즈 1 #1)
  - 3.2절 — 8종 신규 region_exclusive 재료 컨셉 표
- `Docs/balance-design/[balance]20260517_m7_material_economy_curve.md` (페이즈 2 #1)
  - 조정 제안 1절 — 8종 drop_weight 확정안 표
  - 시뮬레이션 절 — 5~8시간 누적 수급 검증

### 타입 스펙 한정 사항

- 사용 타입: `item` (`.claude/skills/data-generator/types/item.md`)
- 타입 스펙은 `category=personal_equipment` / `guild_equipment` 전용으로 설계됨
- M5 도입된 `category=material`은 타입 스펙에 미정의 → **기존 12행 패턴 답습**:
  - description: '' (빈 값)
  - effect_json: {} (빈 JSONB)
  - id 형식: `mat_{slot_short}_{slug}`

---

## 생성 요약

### 총 8행 INSERT

| # | id | name | slot | tier | region_exclusive | 출처 region |
|---|----|------|------|------|------------------|------------|
| 1 | mat_herb_wildflower | 들꽃 약초 | material_herb | 1 | 31 | 도적길 |
| 2 | mat_herb_seaweed | 해초 약재 | material_herb | 1 | 127 | 변방 해안 |
| 3 | mat_hide_nomad_strap | 유목민 가죽끈 | material_hide | 2 | 127 | 변방 해안 |
| 4 | mat_monster_beast_fang | 야수 송곳니 | material_monster_part | 2 | 9 | 외곽 숲 |
| 5 | mat_herb_wind | 바람약초 | material_herb | 2 | 10 | 풍신 숲 |
| 6 | mat_herb_poison | 독초 | material_herb | 2 | 146 | 회색 늪지 |
| 7 | mat_relic_swamp_seal | 늪의 인장 조각 | material_relic_fragment | 2 | 146 | 회색 늪지 |
| 8 | mat_relic_burnt_seal | 탄 인장 파편 | material_relic_fragment | 3 | 38 | 부서진 요새 |

### slot 분포

- material_herb: 5종 (T1×2 + T2×3)
- material_hide: 1종 (T2)
- material_monster_part: 1종 (T2)
- material_relic_fragment: 2종 (T2×1 + T3×1)

### tier 분포

- T1: 2종 (mat_herb_wildflower, mat_herb_seaweed)
- T2: 5종 (mat_hide_nomad_strap, mat_monster_beast_fang, mat_herb_wind, mat_herb_poison, mat_relic_swamp_seal)
- T3: 1종 (mat_relic_burnt_seal)

### region_exclusive 분포 (M5 4종 r3 + M7 신규 8종 = 총 12종)

| region | M5 기존 | M7 신규 | 합계 |
|--------|--------|--------|------|
| 3 (더스트플레인) | 4 | 0 | 4 |
| 31 (도적길) | 0 | 1 | 1 |
| 127 (변방 해안) | 0 | 2 | 2 |
| 9 (외곽 숲) | 0 | 1 | 1 |
| 10 (풍신 숲) | 0 | 1 | 1 |
| 146 (회색 늪지) | 0 | 2 | 2 |
| 38 (부서진 요새) | 0 | 1 | 1 |
| **합계** | **4** | **8** | **12** |

→ 페이즈 1 #1 권장 분포(r3:4 + 외곽 6리전 균등 분배)와 정확히 일치 ✅

---

## 검증 결과

### 자체 검증 체크리스트

#### 공통
- [x] 모든 `id`가 `mat_{slot_short}_{slug}` 형식 (M5 기존 12행 패턴)
- [x] 모든 `id`가 유일 (내부 중복 없음 + Supabase 기존 12행과도 중복 없음)
- [x] 모든 `name`이 기존 12행과 중복 없음 (한국어 신규명)
- [x] `description` 빈 값 (기존 12행 패턴 답습 — DB NOT NULL 컬럼이라면 빈 문자열로 통과)
- [x] `flavor_text` 8행 모두 1~2문장, 30~36자 (60자 이내)
- [x] 저작권 금칙 준수 (웹소설 고유명사 미사용)

#### material 카테고리 (M5/M7 자체 정책)
- [x] effect_json `{}` 빈 JSONB (기존 12행 패턴 답습)
- [x] tier 1~3 범위 (페이즈 2 #1 권장 T1×2 / T2×5 / T3×1)
- [x] slot 4종 사용 (material_herb / material_hide / material_monster_part / material_relic_fragment)
- [x] region_exclusive 7리전 ID(31·127·9·10·146·38) 내에만 분포

### Supabase 사전 검증

- [x] `items` 테이블 존재
- [x] M5 기존 12행 `category=material` 확인 (SELECT 완료)
- [x] 신규 8개 `id` 모두 기존 행과 중복 없음

### flavor_text 톤 검증

각 재료의 출처 region 분위기와 정합:

| id | 출처 region 분위기 | flavor_text 정합성 |
|----|------------------|-----------------|
| mat_herb_wildflower | 도적길 (갈색 풀밭·도적 흔적) | "도적 흔적 사이로 자란다" ✅ |
| mat_herb_seaweed | 변방 해안 (짠 바람·유목민) | "유목민들이 약으로 쓰는 재료" ✅ |
| mat_hide_nomad_strap | 변방 해안 (유목민 텐트) | "유목민이 손수 무두질한 가죽끈" ✅ |
| mat_monster_beast_fang | 외곽 숲 (이끼·발자국) | "거대 야수에게서 얻는 단단한 송곳니" ✅ |
| mat_herb_wind | 풍신 숲 (바람·잎사귀 깃발) | "바람을 맞으며 자라는 약초" ✅ |
| mat_herb_poison | 회색 늪지 (안개·물웅덩이) | "안개 속에서 자라는 독성 약초" ✅ |
| mat_relic_swamp_seal | 회색 늪지 (잠긴 유적) | "늪 깊은 물 밑에서 건진 옛 인장의 일부" ✅ |
| mat_relic_burnt_seal | 부서진 요새 (잿더미·옛 인장) | "잿더미에서 발굴되는 검게 그을린 인장 조각" ✅ |

---

## 범위 외 (별도 산출물 처리)

본 산출물은 **items 8행 INSERT만** 다룹니다. 다음은 별도 산출물 또는 후속 페이즈에서 처리:

| 영역 | 권장 처리 시점 | 비고 |
|------|-----------|------|
| `quest_pool_material_drops` +34행 | 페이즈 3 #4 (지역 상태별 quest_pools)에서 통합 | hook 분배 비율 페이즈 2 #1 2절 |
| `mat_hide_faded_cloth` drop_rate 0.05 → 0.20 UPDATE | 페이즈 3 #4 또는 페이즈 4 #2 마이그레이션 | 단일 UPDATE 1행 |
| `elite_loot_tables` +5~8행 (drop_type=material) | 신규 elite 추가 필요 (별도 산출물) | region 9·146·38 신규 elite_monsters 추가 |
| `travel_choice_results` +8행 (effect_type=material_drop) | 별도 신규 travel_choice 12행 추가 시 통합 | 페이즈 3 별도 산출물 검토 |
| `chain_quests.reward_items` +4~6행 UPDATE | 페이즈 3 #5 (인프라 narrative + 체인) 통합 | 기존 chain reward 확장 |

---

## Supabase 쓰기 옵션

본 산출물은 단순 8행 INSERT이므로 자동 커밋 가능. 단, M4 region_migration 선례에 따라 **즉시 쓰기 vs CSV 보존 후 페이즈 4 마이그레이션 통합 적용** 두 가지 옵션:

### 옵션 A: 즉시 Supabase INSERT (권장)

- 8행 단순 INSERT, 의존성 없음 (region 외래 키만 — 확인 완료)
- operation-bom에서 즉시 확인 가능
- 페이즈 3 #4·#5에서 본 재료를 참조 (foreign key 조기 확보)

### 옵션 B: CSV만 남기고 페이즈 4 마이그레이션 통합

- M4 region_migration_199_to_40.csv 패턴 답습
- 페이즈 4 #1·#4 spec 단계에서 일괄 적용
- 본 산출물 즉시 영향 없음

---

## 다음 단계 권장

- **페이즈 3 산출물 2번 완료** → milestone-runner로 갱신
- **다음 페이즈 3 산출물 3번**: 지역 상태별 고정 발견 20~40개 → `/data-generator region-environment-tag --brief @...`

---

## 참고: 기존 12행 material 패턴 답습

본 산출물은 M5 단계 12행과 동일 스키마/네이밍/효과 정책 사용:
- description = '' (빈 값)
- effect_json = {} (빈 JSONB)
- id 형식: `mat_{slot_short}_{slug}`

이는 M5 단계에서 타입 스펙 `item.md`를 갱신하지 않은 채로 material 카테고리를 도입한 결과. M7도 동일 패턴 유지가 자연스럽다.

**타입 스펙 갱신 검토 권장 (선택)**: M9 또는 추후 M8 세력 재도입 시 타입 스펙에 `category=material` 섹션을 추가하여 effect_json 정책 (현재는 {} 빈 값으로 효과 미사용 → 게임 측에서 inventory stack만 추적) 명문화 권장.
