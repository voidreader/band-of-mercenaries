# elite-monster 생성 메타 — M2b 엘리트 몬스터 39종

> 생성일: 2026-04-23
> 타입: elite-monster
> 대상 테이블: `elite_monsters` (INSERT 39행) — 테이블 미존재, Phase 4-1 마이그레이션 후 반영 필요
> CSV: `[elite-monster]20260423_m2b-elite-monsters.csv`

## 생성 근거

- 컨텐츠 기획: `Docs/content-design/[content]20260420_elite_monster_catalog.md`
- 전투력·출현확률: `Docs/balance-design/[balance]20260420_elite_combat_power.md`
- 드랍 시뮬레이션: `Docs/balance-design/[balance]20260420_elite_drop_simulation.md`
- 타입 스펙: `.claude/skills/data-generator/types/elite-monster.md`

## 생성 요약

| 구분 | 수 | 티어 분포 |
|------|---|----------|
| 보통 엘리트 | 31 | T2×7, T3×13, T4×11 |
| 유니크 엘리트 | 8 | T2×1, T3×3, T4×3, T5×1 |
| **합계** | **39** | |

> 보통 엘리트 T4 수가 11개로 기획서 §3.3 목표(10개)보다 1 초과.
> 타입 스펙 고정 목록 우선 적용(스펙 내 주석 참조). 총 39종 준수.

## 타입 가족별 분포

| type_family | 수 |
|-------------|---|
| golem | 5 (보통4 + 유니크1) |
| orc | 3 |
| goblin | 3 |
| troll | 2 |
| lizardman | 4 (보통3 + 유니크1) |
| undead | 6 (보통4 + 유니크2) |
| elemental | 4 |
| beast | 4 (보통3 + 유니크1) |
| insect | 3 |
| demon | 3 (보통2 + 유니크1) |
| unique_transcendent | 2 (유니크 전용) |

## 확정 수치 (balance-design 기준)

| 구분 | 전투력 범위 | 출현확률 | 소요시간 배수 |
|------|-----------|--------|------------|
| 보통 T2 | 90~105 | 0.15 | 1.5 |
| 보통 T3 | 125~145 | 0.12 | 1.6 |
| 보통 T4 | 175~195 | 0.08 | 1.8 |
| 유니크 T2 | 120 | 0.08 | 1.7 |
| 유니크 T3 | 155~170 | 0.07 | 1.8 |
| 유니크 T4 | 195~210 | 0.06 | 2.0 |
| 유니크 T5 | 245 | 0.05 | 2.0 |

## 자체 검증 결과

- [x] 총 행 수 = 39 (보통 31 + 유니크 8)
- [x] 모든 id 유일
- [x] 보통 31종 이름이 고정 목록과 일치
- [x] 유니크 8종 이름·tier·power·spawn_rate·duration_multiplier가 고정 목록과 일치
- [x] 모든 environment_tags 값이 8개 허용 태그 중에서만 선택
- [x] 모든 stat_weight 합계 1.0
- [x] is_unique=true 행 정확히 8개
- [x] 유니크 8종에 lore, title, fixed_region_environments 모두 채워짐
- [x] 보통 31종에 lore, title, fixed_region_environments 비어있음
- [x] type_family 값이 허용 11개 중 하나

## DB 반영 안내

`elite_monsters` 테이블이 현재 Supabase에 존재하지 않음.

**반영 선행 조건**: Phase 4-1 마이그레이션에서 DDL 실행 후 이 CSV를 적용할 것.

```sql
CREATE TABLE elite_monsters (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  is_unique BOOLEAN NOT NULL DEFAULT false,
  type_family TEXT NOT NULL,
  tier INTEGER NOT NULL,
  power INTEGER NOT NULL,
  spawn_rate REAL NOT NULL,
  duration_multiplier REAL NOT NULL,
  environment_tags JSONB NOT NULL DEFAULT '[]'::jsonb,
  stat_weight JSONB NOT NULL DEFAULT '{}'::jsonb,
  fixed_region_environments JSONB,
  lore TEXT,
  title TEXT
);
```

## 다음 단계

Phase 3 item 5: 엘리트 드랍 테이블 200~270행 생성
```
/data-generator elite-monster --brief @Docs/balance-design/[balance]20260420_elite_drop_simulation.md
```
(elite-loot-table 모드로 실행 — 타입 스펙 §대상 2 사용)
