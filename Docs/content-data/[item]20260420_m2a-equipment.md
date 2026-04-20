# 장비 10종 생성 리포트 (M2a)

> 생성일: 2026-04-20
> 타입: `item` (개인 장비 6 + 용병단 장비 4)
> 대상 테이블: `items` (category=personal_equipment / guild_equipment)
> 산출: `Docs/content-data/[item]20260420_m2a-equipment.csv`

## 입력 근거

- `Docs/content-design/[content]20260418_item_taxonomy.md` — 3대 카테고리, 개인 장비 5슬롯, 용병단 장비 3슬롯, E1-b 효과 축 분리
- `Docs/content-design/[content]20260418_initial_item_set.md` — 평이 5종 + 전설 후보 3안, 용병단 장비 4종 컨셉
- `Docs/balance-design/20260418_equipment_stats.md` — B 곡선 매트릭스, 전설 B+D 하이브리드(×1.2 + 유니크 효과), 단일 주스탯 정책
- `Docs/balance-design/20260418_guild_equipment_macro.md` — 4종 고정 스펙(깃발 복합 / 저울 / 뿔피리 / 방패 장식), A 경미 스케일

## 생성 요약

- 총 10행
- 개인 장비 6종 — weapon 1 / armor 1 / helmet 1 / boots 1 / accessory 2
- 용병단 장비 4종 — banner 1 / artifact 3
- 티어 분포(개인): T2×1 / T3×3 / T4×1 / T5×1 (전설)
- 티어 분포(용병단): T3×2 / T4×1 / T5×1 ← 고정 스펙 준수

## 티어 분포 결정 근거

개인 장비 기본 권장(T2×1/T3×2/T4×2/T5×1) 대신 **T2×1/T3×3/T4×1/T5×1** 채택:
- `initial_item_set.md` 5항 "티어 분포 가이드라인 (못박지 않는 원칙)"에 따라 강제 아님
- 컨셉 기획서의 권장 티어대(강철 장검 T2~T3 / 사슬 흉갑 T2~T3 / 질풍의 가죽 부츠 T3 / 단련의 은반지 T3~T4)를 네이밍 톤 일관성 기준으로 준수
- "T2~T5 최소 1개씩 포함" 강제 조건은 충족

## 전설 선택

**A안 멸혼결** (accessory, 기본 권장) 채택:
- 평이 5종 배치 변경 없음 (가장 단순)
- `legendary_effect.category = damage_resistance`
- 수치: `vit: 11` (T5 기본 9 × 1.2 = 10.8 → 반올림 11)
- 유니크 효과: `injury_rate_modifier: -0.10`, `death_rate_modifier: -0.05`
- 서사: 컨셉 기획서 그대로 ("혼을 끊어 만든 부적") — `death_rate_modifier`와 정합

## 스키마·톤 검증

### 개인 장비
- [x] 슬롯 배분: weapon 1 / armor 1 / helmet 1 / boots 1 / accessory 2 ✅
- [x] 각 slot의 허용 `stat_key` 엄수 (armor/helmet=vit 고정 / boots=agi 고정 / weapon=str / accessory 4축 택 1) ✅
- [x] 단일 주스탯 정책 (전설의 `legendary_effect` 제외) ✅
- [x] 전설 1종만 `legendary_effect` 필드 포함, 값 범위 내 ✅
- [x] accessory 2종 `stat_key` 분산 (단련의 은반지 str / 멸혼결 vit) ✅

### 용병단 장비
- [x] 슬롯 배분: banner 1 / artifact 3 ✅
- [x] 티어 분포: T3×2 / T4×1 / T5×1 ✅
- [x] 개인 스탯 키 미포함 (str/intelligence/vit/agi 없음) ✅
- [x] 허용 키(gold_reward_multiplier / recruit_high_tier_chance / injury_rate_modifier / reputation_gain_modifier)만 사용 ✅
- [x] 깃발만 복합 키, 나머지 단일 키 ✅
- [x] `legendary_effect` / `travel_event_bonus` 미사용 ✅

### 공통
- [x] 모든 `id` 카테고리별 형식(`equip_*` / `guild_*`) ✅
- [x] `id` 내부 유일성 ✅
- [x] 기존 `items` 20행(essence)과 이름·id 중복 없음 ✅
- [x] `flavor_text` 1~2문장, 60자 내외 ✅
- [x] 저작권 금칙 준수 (웹소설 고유명사 미사용) ✅

## description 필드 처리

DB `description` NOT NULL 제약 → "{slot} / {주스탯 +N}" 포맷으로 짧게 기재. 서사는 `flavor_text`가 전담.

## 수치 출처 교차 확인

| 아이템 | 근거 |
|---|---|
| 강철 장검 T3 str 6 | equipment_stats 분석 4 |
| 사슬 흉갑 T3 vit 6 | equipment_stats 분석 4 |
| 철 투구 T2 vit 2 | equipment_stats 분석 4 |
| 질풍의 가죽 부츠 T3 agi 5 | equipment_stats 분석 4 |
| 단련의 은반지 T4 str 6 | equipment_stats 분석 4 (accessory T4=6) |
| 멸혼결 T5 vit 11 + 유니크 | equipment_stats 분석 8 (전설 accessory 11 + damage_resistance) |
| 용병단 장비 4종 | guild_equipment_macro 분석 4 고정 스펙 그대로 |

## Supabase 상태 확인 (생성 전)

- `items` 테이블: 현재 20행 (essence만), personal_equipment·guild_equipment 0행 → 충돌 없음
- `data_versions.items`: version=2 (essence 투입 후). INSERT 후 version=3으로 bump 필요

## 후속 작업

1. 사용자 검토 → 승인 시 Supabase `items` 테이블에 INSERT (10행)
2. `data_versions.items` version 2 → 3 업데이트 (Flutter 앱 재동기화 트리거)
3. 페이즈 3 전체 완료 → 페이즈 4/3 swap 플로우 종료 → M2a 마일스톤 완료 체크포인트
4. 후속: operation-bom `table-config.ts`에 items 정의 추가(일괄 작업), Flutter 앱 Sync 검증
