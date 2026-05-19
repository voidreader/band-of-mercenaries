# M8b 선제권·행동 순서·공격자/방어자 판정 기획서

> 작성일: 2026-05-19
> 유형: 신규 컨텐츠 (M8b 마일스톤 — 페이즈 1 산출물 2/4)
> 선행 문서:
> - `Docs/content-design/[content]20260519_m8b_combat_turn_structure.md` (페이즈 1 #1)
> - `band_of_mercenaries/lib/features/quest/domain/role_synergy_matrix.dart`
> - `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart` (`effectiveAgi` line 162)
> - `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` (`_statWeights`)
> - `Docs/roadmap/master_roadmap.md` M8b 섹션 (1269행)
>
> 후속:
> - 페이즈 1 #3 기본 공격·피해량·명중·회피·치명타 공식 설계 (회피·반격 수치 확정)
> - 페이즈 1 #4 상태 효과 MVP 타입 설계 (메즈로 인한 행동 불가 / 추가 행동 차단 정책)
> - 페이즈 2 #1 직업군 대표 스킬 (행동 1회 소모하는 스킬 효과)
> - 페이즈 2 #2 적 유형 능력치·행동 패턴 (적 측 선제권/행동 순서)

## 개요

이 산출물은 `CombatSimulator`가 한 라운드 안에서 누가 먼저 행동하는지, 누구를 표적으로 삼는지, 방어자가 어떻게 대응하는지를 결정하는 규칙을 정의한다. 페이즈 1 #1이 정의한 4 페이즈 흐름(사전 단계 → 선제 라운드 → 일반 라운드 반복 → 마무리)의 Phase 1과 Phase 3 내부 동작을 채우는 설계다.

수치는 변수의 결합 구조만 다루며 실제 가중치 절대값(피해량, 명중 %, 회피 %)은 페이즈 1 #3에서 확정한다. 상태 효과로 인한 행동 불가 처리는 페이즈 1 #4에서 확정한다. 이 산출물은 "어떤 변수가 어디서 어떻게 합쳐지는가"의 골격에 집중한다.

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 적용 방식 |
|---------|--------------|----------|
| Final Fantasy Tactics — Action Time | 단순 정수 정렬 기반 행동 순서, 카운트 다운 방식 | 라운드 일괄 정렬 방식으로 단순화 (ATB 미채택) |
| Battle Brothers — initiative 통계 | 캐릭터별 initiative 점수가 라운드 시작 시 정렬되어 행동 순서 결정 | `actionScore = effectiveAgi + roleWeight + traitBonus + battlefield + noise` |
| Darkest Dungeon — Position 시스템 | 4열 진형, 직업별 가능한 표적 열이 정해져 있다 | 3열 단순화 (전열/중열/후열), 직업군 기반 자동 배치 |
| Into the Breach — 선제 우위 | 시작 시점 위치/조건으로 선제권을 결정 | 양측 선제 점수 격차 임계값(15) 기준으로 선제 라운드 발동 |
| Slay the Spire — Counter Attack | 일부 카드는 피격 시 반격 발동 | 트레잇/직업군 기반 회피 성공 후 반격 트리거 |

## 1. 행동 순서 방식 선택 — 라운드 일괄 정렬 채택

### 두 후보 비교

| 항목 | ATB (Active Time Battle) | 라운드 일괄 정렬 (Round-Robin Sort) |
|------|-------------------------|------------------------------------|
| 구현 복잡도 | 높음 — 각 전투원의 게이지 누적·트리거 관리 | 낮음 — 라운드 시작 시 1회 정렬 |
| 결정성 시드 재현 | 게이지 누적 정밀도 필요 (부동소수점 위험) | 정수 정렬로 결정적 |
| 라운드 경계 명확성 | 모호 (게이지가 라운드를 가로지름) | 명확 (페이즈 1 #1 종료 조건 평가와 정렬됨) |
| 텍스트 보고서 압축 | 어려움 (라운드 단위 결정적 장면 추출 곤란) | 쉬움 (라운드별 1~2 결정적 장면 후보 명확) |
| 다단 행동 (광역/연속) | 게이지 1회 소모로 처리 가능 | 단순 — 한 행동에 N 대상, 행동 순서 1번 소모 |
| 추가 행동 (`extraAction` 플래그) | 게이지 즉발 충전 형태 | 라운드 내 추가 슬롯 삽입 형태 |

### 결정

**라운드 일괄 정렬 방식을 채택한다.**

근거:
- 페이즈 1 #1에서 라운드 권장 범위 3~6, 상한 8로 명확한 라운드 구조를 채택했다. ATB는 라운드 경계를 흐려서 종료 조건 평가 타이밍이 모호해진다.
- 결정성 시드 재현이 단순해진다 (정수 정렬).
- 보고서 라인 압축 정책(라운드별 결정적 장면 1~2개)과 정합한다.
- 텍스트 기반 방치형 게임에서 ATB의 복잡도 비용은 가치가 낮다.

## 2. Phase 1 사전 단계 — 선제권 진입 자격 판정

### 선제 점수 산식

`CombatSimulator`는 사전 단계에서 양 진영의 **선제 점수**(`sideInitiativeScore`)를 계산한다.

```text
sideInitiativeScore(side) =
    average(effectiveAgi[side.combatants])
  + average(roleInitiativeWeight[side.combatants])
  + traitInitiativeBonus(side)
  + battlefieldInitiativeModifier(side, regionEnvironmentTags)
  + ambushBonus(quest, side)
```

| 항 | 의미 | 출처 |
|----|------|------|
| `average(effectiveAgi)` | 진영 평균 AGI | `Mercenary.effectiveAgi` (적은 `EnemySnapshot.agi`) |
| `average(roleInitiativeWeight)` | 직업군 선제권 가중치 평균 | 아래 매트릭스 |
| `traitInitiativeBonus(side)` | 진영 내 선제 관련 트레잇 합 | 카테고리·키워드 매핑(아래 5절) |
| `battlefieldInitiativeModifier` | 전장 조건 보정 | 6절 |
| `ambushBonus` | 매복·기습 의뢰 특수 보정 | `pool.specialFlags['ambush_side']` 분기 |

### 선제 라운드 발동 조건

```text
deltaScore = sideInitiativeScore(party) - sideInitiativeScore(enemy)

if (deltaScore >= 15)   → 파티가 선제 라운드 1회 행동
if (deltaScore <= -15)  → 적 진영이 선제 라운드 1회 행동
otherwise               → 선제 라운드 스킵, Phase 3 바로 진입
```

**임계값 15의 의미**: 평균 AGI 차이 + 직업군 가중치 + 트레잇 보너스 합산이 명확한 우위를 만들 때만 선제권이 발생한다. 작은 차이로 매번 선제권이 작동하면 전투의 분산이 줄고 라운드 1이 의미를 잃는다. 정확한 임계값은 페이즈 2 #2/페이즈 4 #5에서 적 능력치 분포와 함께 검증한다.

### 매복 의뢰 특수 처리

일부 의뢰는 처음부터 한쪽이 선제권을 가진다.

| 의뢰 유형 | 매복 측 | 처리 |
|-----------|---------|------|
| 호위 의뢰 + 도적 습격 시나리오 | 적 | `ambushBonus = +20` (적 측) → 적이 항상 선제 |
| 정찰 의뢰 성공 사전 조건 | 파티 | `ambushBonus = +20` (파티 측) → 파티가 항상 선제 |
| 일반 약탈/토벌 | 없음 | 매복 보너스 0 |

매복 보너스는 `quest_pools.specialFlags['ambush_side']` 또는 신규 컬럼으로 표현한다. 페이즈 4 #2 데이터 모델에서 확정한다.

## 3. Phase 3 일반 라운드 — 행동 순서 산식

### 라운드 시작 시 일괄 정렬

각 전투원의 **행동 점수**(`actionScore`)를 라운드 시작 시 계산하고, 내림차순 정렬한다. 정렬 결과가 그 라운드의 행동 순서다.

```text
actionScore(combatant, roundIndex) =
    effectiveAgi
  + roleActionWeight[combatant.role]
  + traitActionBonus(combatant.traitIds)
  + battlefieldActionModifier(combatant.role, regionEnvironmentTags)
  + roundRandomNoise(seed, roundIndex, combatant.id)
```

| 항 | 의미 | 범위 |
|----|------|------|
| `effectiveAgi` | 베이스 AGI (스냅샷 동결값) | 통상 3~25 |
| `roleActionWeight` | 직업군 기본 행동 순서 가중치 | -3 ~ +6 (아래 매트릭스) |
| `traitActionBonus` | 행동 순서 관련 트레잇 합 | -3 ~ +5 |
| `battlefieldActionModifier` | 전장 조건 보정 | -3 ~ +5 |
| `roundRandomNoise` | 라운드별 결정적 노이즈 | -3 ~ +3 |

### 노이즈 결정성

```text
roundRandomNoise(seed, roundIndex, combatantId) =
    Random(seed ^ stableSeed32('order|$roundIndex|$combatantId')).nextInt(7) - 3
```

같은 시드 + 같은 라운드 + 같은 전투원 → 같은 노이즈. 결정성 보장.

### 동률 처리

`actionScore`가 같으면 다음 순서로 분기한다:

1. 직업군 우선순위: `rogue > ranger > warrior > specialist > support > mage`
2. tier 높은 순
3. `stableSeed32(combatantId)` 오름차순 (결정성 보장)

이 정책은 직업군 정체성을 작은 차이에서도 드러나게 한다.

## 4. 직업군 가중치 매트릭스 초안

페이즈 1 #2는 두 매트릭스를 분리한다. **선제 점수 매트릭스**는 진영 평균에 들어가고, **행동 순서 매트릭스**는 개별 전투원 정렬에 들어간다.

### 4.1 직업군 선제 점수 가중치 (`roleInitiativeWeight`)

| 직업군 | 가중치 | 근거 |
|--------|--------|------|
| rogue | +6 | 기습·은신 — 선제권 직업적 정체성 |
| ranger | +5 | 정찰·시야 — 선제 발견 |
| warrior | +2 | 전열 돌격 가능 |
| specialist | +1 | 평균 |
| support | -2 | 후방 직업 |
| mage | -3 | 영창·준비 시간 |

### 4.2 직업군 행동 순서 가중치 (`roleActionWeight`)

| 직업군 | 가중치 | 근거 |
|--------|--------|------|
| rogue | +6 | 일격 이탈 |
| ranger | +4 | 사격 속도 |
| warrior | +1 | 중장비 무게 |
| specialist | 0 | 평균 |
| support | -1 | 보조 행동 우선순위 낮음 |
| mage | -3 | 영창 시간 |

### 매트릭스 분리 근거

선제권과 행동 순서를 동일한 가중치로 처리하면 직업군 정체성이 단조롭다. 예를 들어 warrior는 행동 순서에서 큰 우위는 없지만, 매복 의뢰(`ambushBonus +20`)가 있으면 선제 라운드에서 1차 돌격으로 적 후열을 흩트릴 수 있다. 두 매트릭스를 분리하면 직업군 조합 디자인 폭이 넓어진다.

## 5. 트레잇 보너스 매핑 규칙

페이즈 1 #2는 **개별 트레잇 ID 화이트리스트를 결정하지 않는다.** 카테고리·키워드 매핑 규칙만 정의하고, 실제 trait_id별 가중치는 페이즈 4 #1/#2 또는 페이즈 2 #1 스킬 설계에서 확정한다.

### 매핑 규칙

| 행동 지표 | 적용 카테고리 | 키워드 후보 | 가중치 범위 |
|-----------|--------------|-------------|-------------|
| 선제권 (`traitInitiativeBonus`) | Talent, Background, CombatStyle | `scout`, `ambush`, `first_strike`, `vigilant`, `tracker` | 트레잇당 +1 ~ +3 |
| 행동 순서 (`traitActionBonus`) | Physical, CombatStyle | `swift`, `nimble`, `quick`, `agile` | 트레잇당 +1 ~ +2 |
| 회피 (페이즈 1 #3 입력) | Survival | `evasion`, `dodge`, `nimble`, `slippery` | 페이즈 1 #3에서 % 가중치 |
| 반격 (페이즈 1 #3 입력) | CombatStyle | `riposte`, `counter`, `vengeance` | 페이즈 1 #3에서 % 가중치 |
| 방패 막기 (페이즈 1 #3 입력) | CombatStyle, Background | `shield`, `bulwark`, `guardian` | 페이즈 1 #3에서 % 가중치 |

### 키워드 결합 원칙

- 한 트레잇이 여러 행동 지표에 보너스를 줄 수 있다 (예: `vigilant_scout`은 선제 +2, 회피 +5%).
- 트레잇 시너지(`trait_synergies` 테이블)는 페이즈 4 #1 시뮬레이터 명세에서 합산 정책을 정한다.
- 페이즈 1 #2는 **각 카테고리별 최대 보너스 상한**을 권고한다.

### 카테고리별 상한 권고

진영 1명당 선제 트레잇 보너스가 무제한 합산되면 일부 직업군 결합이 과도하게 우세해진다. 다음 상한을 둔다.

| 행동 지표 | 진영 1명당 상한 | 진영 합산 상한 |
|-----------|---------------|---------------|
| 선제권 | +5 | +15 |
| 행동 순서 | +5 | — (개별 적용) |
| 회피 | 페이즈 1 #3 | 페이즈 1 #3 |
| 반격 | 페이즈 1 #3 | 페이즈 1 #3 |

## 6. 전장 조건 매핑 초안

`regionEnvironmentTags`(페이즈 1 #1 스냅샷 동결 필드)를 입력으로 받아 직업군별 보정을 적용한다.

### 전장 → 직업군 보정 매트릭스 초안

| 전장 태그 | warrior | ranger | mage | rogue | support | specialist |
|-----------|---------|--------|------|-------|---------|------------|
| forest | 0 | +5 | -2 | +1 | 0 | 0 |
| dungeon (좁은 공간) | +3 | -3 | -1 | +2 | 0 | +1 |
| sea_coast | -1 | +1 | 0 | 0 | +1 | +3 |
| desert | +1 | 0 | -1 | -1 | 0 | +1 |
| mountain | +2 | +2 | -2 | -1 | -1 | +1 |
| mist_field (M7 안개 지역) | -2 | -2 | +1 | +2 | 0 | 0 |
| swamp (M7 늪지) | -1 | +1 | +1 | 0 | -1 | +2 |
| ruined_castle | +2 | 0 | +1 | +2 | 0 | +1 |

태그가 여러 개 매칭되면 가중치를 단순 합산하고 ±5로 클램프한다.

### 선제 점수 보정과 행동 순서 보정의 분리

전장 조건 보정도 선제 점수와 행동 순서로 분리한다. 다만 페이즈 1 #2 MVP는 **동일 매트릭스를 두 곳에 모두 적용**하고, 실제 운영에서 분기가 필요해지면 매트릭스를 분리하는 점진적 확장 정책을 채택한다.

```text
battlefieldInitiativeModifier(side, tags) ≈ battlefieldActionModifier(role, tags)
```

페이즈 4 #5 검증에서 분기 필요성이 확인되면 매트릭스를 별도화한다.

## 7. 공격자 → 방어자 매칭 규칙

### 진형 3열 구조

스냅샷 동결 시점에 직업군 기반으로 자동 배치한다.

| 열 | 배치 직업군 우선순위 |
|----|---------------------|
| 전열 (front) | warrior, specialist |
| 중열 (middle) | rogue, ranger |
| 후열 (back) | mage, support |

진영당 1~5명(파티) 또는 1~6명(적). 직업군이 부족하면 한 열에 다수가 들어가거나 한 열이 비어 있을 수 있다. 빈 열은 다음 열로 압축(중열만 비어 있으면 전열 = 전열 + 중열).

### 접근형 vs 원거리 직업군

| 분류 | 직업군 | 표적 정책 |
|------|--------|----------|
| 접근형 | warrior, specialist, rogue | 상대 전열 우선, 전열 전멸 시 중열, 그 다음 후열 |
| 원거리 | ranger, mage, support | 자유 표적 선택 — 정책 결정(아래) |

### 원거리 직업군의 표적 선택 정책

원거리 직업군은 다음 우선순위로 표적을 결정한다 (MVP 단순화).

| 직업군 | 표적 우선순위 |
|--------|--------------|
| ranger | HP가 가장 낮은 적 (마무리 사격) |
| mage | 적 무리 중 가장 많이 모인 열 (광역 후보) — 광역 미보유 시 후열 mage/support |
| support | (공격 시) 적 후열 → support/mage 우선 / (보조 시) 아군 HP 최저 |

이 정책은 페이즈 4 #2에서 `TargetingStrategy` enum으로 명세된다.

### 전열 보호 효과

전열이 모두 사망하지 않은 동안에는 접근형 적이 중·후열을 타격할 수 없다. 전열이 모두 사망하면 다음 라운드부터 중·후열이 노출된다.

이 정책은 warrior 직업군의 "탱커" 정체성을 만들고, 페이즈 2 #2 적 행동 패턴에서 "전열 우선 돌파"형 적이 의미를 갖게 한다.

### 회피 후 표적 재선정 없음

방어자가 회피에 성공하면 그 행동은 실패로 처리되고, 다른 대상을 다시 표적으로 삼지 않는다. 라운드 행동 1회를 소모하고 끝난다. 이 단순화는 라운드 행동 시퀀스의 결정성을 보장한다.

## 8. 회피·반격·방패 막기 트리거

### 8.1 회피 (Evasion)

방어자가 행동을 회피하면 그 공격은 무효화된다.

```text
evasionChance =
    base * (defender.effectiveAgi / attacker.effectiveAgi)
  + traitEvasionBonus(defender.traitIds)
  + statusEffectEvasionMod(defender)
```

`base`, `traitEvasionBonus` 수치는 페이즈 1 #3에서 확정한다. 페이즈 1 #2는 회피가 **공격자/방어자 AGI 비율 + 트레잇 + 상태 효과**의 결합임을 명시한다.

### 8.2 반격 (Riposte)

회피 성공 후 일부 조건에서 반격이 발동한다.

```text
riposteChance =
    roleRiposteBase[defender.role]
  + traitRiposteBonus(defender.traitIds)
```

| 직업군 | 기본 반격 확률 |
|--------|---------------|
| warrior | 중간 |
| specialist | 낮음 |
| rogue | 중간 |
| ranger | 낮음 |
| mage | 없음 |
| support | 없음 |

수치는 페이즈 1 #3에서 확정한다. 반격은 행동 순서를 소모하지 않는 **추가 행동**이며, 라운드 액션 시퀀스에 즉시 삽입된다.

### 8.3 방패 막기 (Shield Block)

방패 관련 트레잇 또는 페이즈 2 #1 스킬 보유 시 발동한다. 회피와 달리 공격은 무효화되지 않고 **피해량이 N% 감소**한다.

```text
shieldBlockMitigation =
    traitShieldBonus(defender.traitIds)
  + (skill 미발동 시 0, skill 발동 시 페이즈 2 #1 수치)
```

방패 막기는 회피와 별도 판정이며, 회피 실패 후 적용된다 (회피 → 방패 막기 → 피해 적용 순).

### 8.4 판정 순서

```text
1. 공격자가 행동을 시작 (대상 결정)
2. 방어자 회피 판정
   ├─ 회피 성공 → 회피 트리거 (반격 판정으로 이동)
   └─ 회피 실패 → 방패 막기 판정
       ├─ 방패 막기 성공 → 피해량 감소 적용
       └─ 실패 → 정상 피해 적용
3. 회피 성공 시: 반격 판정
   ├─ 반격 성공 → 추가 행동 1회 삽입 (공격자가 방어자가 되어 회피·방패 판정 재진행)
   └─ 반격 실패 → 라운드 행동 종료
```

반격 추가 행동도 회피·방패 판정을 거치지만, **반격에서 반격은 발생하지 않는다** (무한 반격 루프 방지).

## 9. 다단 행동 규칙

라운드 내부에서 한 전투원이 여러 대상에 영향을 줄 수 있는 경우를 정의한다.

### 9.1 광역 공격 (Area Attack)

한 행동에 N개 대상을 동시 타격한다.

- 행동 순서를 1번만 소모한다.
- 대상별로 독립적으로 회피·방패 판정을 수행한다.
- 반격은 회피 성공한 대상별로 독립 판정한다.
- 광역 공격의 표적 범위(전열 전체 / 임의 N명 / 십자형 등)는 스킬마다 다르며 페이즈 2 #1에서 정의한다.

### 9.2 연속 공격 (Multi-Hit)

한 행동에 동일 대상에 N회 타격한다.

- 행동 순서를 1번만 소모한다.
- 회피·방패는 N회 독립 판정한다.
- 첫 타격 후 대상이 사망하면 남은 타격은 무효(추가 표적으로 전환하지 않음).

### 9.3 추가 행동 (Extra Action)

라운드 행동 순서를 추가로 받는 효과다. 다음 hook 시점에 삽입된다.

| 발동 hook | 삽입 위치 |
|-----------|----------|
| 반격 (회피 성공 후) | 회피 직후 즉시 |
| 트레잇 패시브 (예: `swift_strike`) | 라운드 시작 시 1회 추가 행동 (`extraAction` 플래그로 표현) |
| 스킬 효과 (예: `quick_step`) | 다음 라운드 시작 시 1회 (페이즈 2 #1 스킬) |

추가 행동은 회피·방패·반격 판정을 모두 거치지만, **추가 행동에서 추가 행동은 발생하지 않는다** (라운드 1회 행동 정책의 변동성 보호).

### 9.4 광역+연속 결합

광역 연속(각 대상에 N회 타격)도 가능하다. 행동 순서는 1번만 소모하고, 회피·방패·반격은 (대상 × N) 독립 판정한다. 페이즈 2 #1에서 이런 스킬이 정의되면 그때 부담 검증을 진행한다.

## 10. 페이즈 1 #1 4-페이즈 흐름과의 정합성

### Phase 1 사전 단계 입력

- `CombatantSnapshot.role` (직업군) → `roleInitiativeWeight` 룩업
- `CombatantSnapshot.effectiveAgi` → 선제 점수 평균
- `CombatantSnapshot.traitIds` → `traitInitiativeBonus` 합산
- `regionEnvironmentTags` → `battlefieldInitiativeModifier`
- `quest.specialFlags['ambush_side']` → `ambushBonus`
- 진형 자동 배치 (3열 구조)

### Phase 2 선제 라운드 발동 조건

- `|deltaScore| >= 15` 일 때 우세 진영만 1회 행동
- 미발동 시 즉시 Phase 3 진입

### Phase 3 일반 라운드 행동 순서

- 라운드 시작마다 `actionScore` 일괄 계산 → 내림차순 정렬
- 정렬 결과대로 1행동씩 진행
- 행동 → 표적 결정 (7절) → 회피·방패·반격 판정 (8절) → 피해 적용
- 다단 행동(9절)은 행동 순서를 1번만 소모
- 라운드 종료 시 상태 효과 갱신 (페이즈 1 #4)
- Phase 1 #1 종료 조건 (a)~(f) 평가

### Phase 4 마무리 판정

- 결정적 장면(높은 피해, 광역, 반격, 방패 막기) 시퀀스를 `featuredMercIds`에 채움
- protagonist는 가장 많은 결정적 장면 기여자로 결정 (페이즈 4 #1에서 정확한 정의)
- 보고서 라인 압축 (페이즈 1 #1 §M8a 호환 §라운드 압축 정책)

## 11. 현재 시스템과의 연관

| 시스템 | 영향 | 처리 방식 |
|--------|------|----------|
| `RoleSynergyMatrix` | 의뢰 유형 상성 — M8b는 별도 매트릭스 사용 | 두 매트릭스 병존 (의뢰 성공률 보정 vs 전투 행동 순서) |
| `Mercenary.effectiveAgi` | 동결 시점 캡처 | 페이즈 1 #1 동결 정책 그대로 |
| `Mercenary.traitIds` | 카테고리·키워드 매핑 입력 | 매핑 테이블은 페이즈 4 #1/#2에서 영속화 (또는 정적 상수) |
| `trait_categories` 테이블 | 카테고리 분류 사용 | 변경 없음 |
| `quest_pools.specialFlags` | `ambush_side` 추가 후보 | 페이즈 4 #2 데이터 모델 |
| `region.environment_tags` | 전장 보정 입력 | 변경 없음 |
| `QuestCalculator._statWeights` | 의뢰 성공률용, 전투와 무관 | 영향 없음 |
| `CombatSimulator` (M8b 신규) | 이 산출물의 흐름을 구현 | 페이즈 4 #1에서 명세 |

## 12. 결정성과 시드 활용

페이즈 1 #1의 시드 정책을 그대로 사용한다.

```text
seed = stableSeed32('${quest.startTime!.toUtc().microsecondsSinceEpoch}|${quest.id}')

라운드별 행동 순서 노이즈:
  Random(seed ^ stableSeed32('order|$roundIndex|$combatantId')).nextInt(7) - 3

회피·방패·반격 판정 랜덤:
  Random(seed ^ stableSeed32('react|$roundIndex|$attackerId|$defenderId')).nextDouble()
```

각 판정마다 별도 PRNG 인스턴스를 사용하여 한 판정의 결과가 다른 판정 시퀀스에 영향을 주지 않는다. Dart 런타임 `hashCode`는 사용하지 않고, 페이즈 4 #1에서 명세할 안정 해시 유틸만 사용한다. 동일 시드 + 동일 입력 → 동일 결과 보장.

## 13. 구현 우선순위 제안

| 우선순위 | 항목 | 이유 |
|----------|------|------|
| 높음 | 라운드 일괄 정렬 방식 채택 | 모든 후속 산식의 기반 |
| 높음 | `actionScore` 산식 5항 결합 구조 | Phase 3 행동 순서의 핵심 |
| 높음 | `sideInitiativeScore` 산식 + 임계값 15 | Phase 2 선제 라운드 발동 조건 |
| 높음 | 직업군 가중치 매트릭스 2종 (선제/행동 순서 분리) | 직업군 정체성 |
| 높음 | 진형 3열 + 접근형/원거리 표적 정책 | 7절 매칭 규칙 |
| 높음 | 회피 → 방패 → 반격 판정 순서 | 8절 트리거 일관성 |
| 중간 | 트레잇 카테고리·키워드 매핑 + 카테고리별 상한 | 진영 합산 폭주 방지 |
| 중간 | 전장 조건 매트릭스 (8 태그 × 6 직업군) | 환경 변별성 |
| 중간 | 다단 행동 규칙 (광역/연속/추가) | 페이즈 2 #1 스킬 호환 |
| 낮음 | 매복 의뢰 처리 (`ambush_side`) | 일부 의뢰에만 적용 |

## 14. data-generator 지시사항

이 산출물은 시스템·흐름 설계이며 벌크 데이터 생성을 직접 요구하지 않는다.

페이즈 3에서 별도로 필요한 데이터 중 이 산출물이 입력을 제공하는 항목:

| 페이즈 3 산출물 | 이 산출물의 입력 기여 |
|-----------------|----------------------|
| 페이즈 3 #1 적 유형 20~30개 | 적 측 `effectiveAgi`, `role`, 진형 배치 |
| 페이즈 3 #2 직업군 대표 스킬 6~10개 | 추가 행동 hook, 광역/연속 분류 |
| 페이즈 3 #3 상태 효과 8~12개 | 행동 불가, 회피 보정, 추가 행동 차단 정책 |
| 페이즈 3 #4 전투 로그 템플릿 | 결정적 장면 키워드 (회피·반격·방패·광역) |

직업군 가중치 매트릭스 2종, 전장 조건 매트릭스, 트레잇 매핑 규칙은 **정적 상수**로 코드에 내장하고 데이터 테이블로 분리하지 않는다. 페이즈 4 #1 시뮬레이터 명세에서 확정한다.

## 15. 다음 단계

페이즈 1 #3에서 회피·반격·방패 막기의 실제 % 수치, 명중·치명타·피해량 공식을 확정한다. 이 산출물의 트레잇 매핑 규칙과 카테고리별 상한이 #3의 입력이 된다.

페이즈 1 #4에서 상태 효과 MVP 타입을 설계한다. 이 산출물의 추가 행동(9.3절)은 상태 효과가 아니라 트레잇/스킬의 `extraAction` 플래그 입력이 된다.

페이즈 2 #1 직업군 대표 스킬 설계에서 광역·연속·추가 행동 분류를 사용한다.
