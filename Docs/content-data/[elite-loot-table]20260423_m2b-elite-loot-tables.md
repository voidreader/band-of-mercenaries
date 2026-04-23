# elite-loot-table 생성 메타 — M2b 엘리트 드랍 테이블 209행

> 생성일: 2026-04-23
> 타입: elite-loot-table
> 대상 테이블: `elite_loot_tables` (INSERT 209행) — 테이블 미존재, Phase 4-1 마이그레이션 후 반영 필요
> CSV: `[elite-loot-table]20260423_m2b-elite-loot-tables.csv`

## 생성 근거

- 드랍 시뮬레이션: `Docs/balance-design/[balance]20260420_elite_drop_simulation.md`
- 엘리트 몬스터 목록: `Docs/content-data/[elite-monster]20260423_m2b-elite-monsters.csv`
- 아이템 참조: Supabase `items` 테이블 (30개 항목 조회 기준)
- 타입 스펙: `.claude/skills/data-generator/types/elite-monster.md` (§대상 2 elite-loot-table 모드)

## 생성 요약

| 구분 | 엘리트 수 | 행 수 | 행 수/엘리트 |
|------|---------|------|------------|
| 보통 T2 | 7 | 28 | 4 |
| 보통 T3 | 13 | 60 | 4~5 |
| 보통 T4 | 11 | 55 | 5 |
| 유니크 (T2~T5) | 8 | 66 | 8~9 |
| **합계** | **39** | **209** | |

## 확정 수치 (balance-design 기준)

### 보통 엘리트 드랍률 범위

| 구분 | Σ drop_rate | 에센스 Σ | 골드 범위 |
|------|-----------|---------|---------|
| T2 | 1.55~2.00 | 0.55~0.90 | 200~350G |
| T3 | 1.55~2.00 | 0.55~0.90 | 300~550G |
| T4 | 1.55~2.00 | 0.55~0.90 | 450~800G |

### 유니크 엘리트 드랍률 범위

| 구분 | Σ drop_rate | 에센스 Σ | 골드 (기본/잭팟) |
|------|-----------|---------|--------------|
| T2 | ≥2.80 | 1.00~1.65 | 300~500 / 700~1200G |
| T3 | ≥2.80 | 1.00~1.65 | 400~700 / 1000~1700G |
| T4 | ≥2.80 | 1.00~1.65 | 600~1100 / 2000~3200G |
| T5 | ≥2.80 | 1.00~1.65 | 1000~1800 / 3000~5000G |

## 참조한 item_id 목록

### 에센스 (20종)
- essence_str_t1 ~ essence_str_t5
- essence_int_t1 ~ essence_int_t5
- essence_vit_t1 ~ essence_vit_t5
- essence_agi_t1 ~ essence_agi_t5

### 개인 장비 (6종)
- equip_helmet_iron_helm (T2)
- equip_armor_chain_mail (T3)
- equip_weapon_steel_sword (T3)
- equip_boots_gale_leather (T3)
- equip_accessory_forge_silver_ring (T4)
- equip_accessory_soul_seal (T5)

### 길드 아이템 (4종)
- guild_banner_standard (T3)
- guild_artifact_golden_scale (T3)
- guild_artifact_honor_horn (T4)
- guild_artifact_guardian_emblem (T5)

## 타입 패밀리별 에센스 축

| type_family | 허용 에센스 축 |
|-------------|------------|
| golem | str / vit |
| orc | str / int |
| goblin | agi / int |
| troll | vit / str |
| lizardman | agi / str |
| undead | int / agi 전용 (str/vit 미드랍) |
| elemental | int 주축 + 서브 다양 |
| beast | str / agi |
| insect | agi / int |
| demon | int / agi 전용 (str/vit 미드랍) |

## 자체 검증 결과

- [x] 총 행 수 = 209
- [x] 모든 id 유일 (loot_{elite_id}_{n} 포맷)
- [x] 모든 elite_id가 elite_monsters.csv 내 실존 ID와 일치
- [x] 보통 T2 Σ drop_rate: 1.68~1.72 (범위 1.55~2.00 ✓)
- [x] 보통 T3 Σ drop_rate: 1.68~1.82 ✓
- [x] 보통 T4 Σ drop_rate: 1.81~1.82 ✓
- [x] 유니크 Σ drop_rate: 2.80~2.88 (최소 2.80 ✓)
- [x] 유니크 에센스 Σ: 1.22~1.59 (범위 1.00~1.65 ✓)
- [x] undead / demon 에센스: int/agi만 사용, str/vit 미포함 ✓
- [x] 장비 티어 제약: T2 보통 = T2 장비만 / T3 = T2~T3 / T4 = T3~T4 / 유니크 T4+ = T4~T5 ✓
- [x] 모든 item_id가 Supabase items 테이블 실존 ID ✓
- [x] 골드 행: gold_min/gold_max 채움, item_id 비움 ✓
- [x] 비골드 행: item_id 채움, gold_min/gold_max 비움 ✓
- [x] rarity_grade: common / rare / epic / legendary 4종만 사용 ✓
- [x] 유니크 8종 모두 gold_jackpot 행(rare) 포함 ✓

## DB 반영 안내

`elite_loot_tables` 테이블이 현재 Supabase에 존재하지 않음.

**반영 선행 조건**: Phase 4-1 마이그레이션에서 DDL 실행 후 이 CSV를 적용할 것.

```sql
CREATE TABLE elite_loot_tables (
  id TEXT PRIMARY KEY,
  elite_id TEXT NOT NULL REFERENCES elite_monsters(id),
  drop_type TEXT NOT NULL,       -- 'gold' | 'essence' | 'equipment' | 'guild_item'
  item_id TEXT REFERENCES items(id),
  gold_min INTEGER,
  gold_max INTEGER,
  drop_rate REAL NOT NULL,
  rarity_grade TEXT NOT NULL,    -- 'common' | 'rare' | 'epic' | 'legendary'
  quantity INTEGER NOT NULL DEFAULT 1
);
```

## 유니크별 Σ 상세

| 유니크 엘리트 | 행 수 | Σ drop_rate | 에센스 Σ |
|------------|-----|------------|---------|
| elite_wolf_ulbur | 8 | 2.80 | 1.25 |
| elite_golem_steel | 9 | 2.88 | 1.31 |
| elite_hydra_swamp | 8 | 2.82 | 1.22 |
| elite_skeleton_general | 8 | 2.80 | 1.45 |
| elite_guardian_desert | 8 | 2.80 | 1.34 |
| elite_witch_morgan | 8 | 2.80 | 1.35 |
| elite_kraken_abyss | 8 | 2.80 | 1.36 |
| elite_lich_primordial | 9 | 2.80 | 1.59 |

## 다음 단계

Phase 3 item 6: 유니크 엘리트 region_discovery 행 8~16개
- 대상 테이블: `region_discoveries` (기존 테이블)
- discovery_type = 'elite'
- 유니크 8종 × 1~2개 리전 환경 기반
