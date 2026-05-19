# M8a 세력 지명 의뢰 데이터

> 작성일: 2026-05-18
> 데이터 파일: `Docs/content-data/[faction-quest]20260518_m8a-faction-named-quests.csv`
> 입력 문서:
> - `Docs/content-design/[content]20260518_m8a_faction_vertical_slice.md`
> - `Docs/content-design/[content]20260518_m8a_faction_patronage_flow.md`
> - `Docs/balance-design/[balance]20260518_m8a_faction_quest_rewards.md`

## 생성 범위

- 세력 지명 의뢰 12개
- 모험가 길드 4개, 상인 연합 4개, 전사 길드 4개
- 난이도 분포: 모험가 d2~d4, 상인 d2~d4, 전사 d3~d5
- 모든 의뢰는 `is_named=true`, `faction_named=true`, `combat_report=true` 메타를 가진다.

## 스키마 메모

기존 `quest_pools`에 이미 존재하는 컬럼과 M8a에서 필요한 후보 컬럼을 함께 담았다. `region_flag`, `faction_contact`, `faction_reputation` hook은 페이즈 4에서 `NamedHookEvaluator` 확장 대상으로 명세해야 한다.

`special_flags`에는 다음 후보 값을 포함한다.

| 키 | 의미 |
|----|------|
| `named_reward_multiplier` | 골드 보상 배수 |
| `named_reputation_multiplier` | 명성 보상 배수 |
| `faction_named` | M8a 세력 지명 의뢰 여부 |
| `combat_report` | 전투 보고서 생성 대상 |
| `faction_reputation_success` | 성공 시 세력 평판 보상 후보 |
| `faction_reputation_great_success` | 대성공 시 세력 평판 보상 후보 |
| `faction_reputation_critical_failure` | 대실패 시 세력 평판 패널티 후보 |
| `material_reward_hint` | `quest_pool_material_drops` 생성 또는 서비스 로직 연결 힌트 |

## 자체 검증

- 생성량 12개로 페이즈 목표 10~15개 범위 안이다.
- 모든 `faction_tag`는 M8a 대표 세력 3개 중 하나다.
- 기존 일반 지명 의뢰보다 평균 보상 배수가 낮다.
- 상점 재료 수급을 압도하지 않도록 재료 보상은 힌트 수준으로 제한했다.
- Supabase에는 아직 쓰지 않았다.
