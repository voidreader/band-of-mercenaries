# M8b 상태 효과 MVP 타입 기획서

> 작성일: 2026-05-19
> 유형: 신규 컨텐츠 (M8b 마일스톤 — 페이즈 1 산출물 4/4)
> 선행 문서:
> - `Docs/content-design/[content]20260519_m8b_combat_turn_structure.md` (페이즈 1 #1 — Phase 3 라운드 종료 시점 상태 갱신 정책)
> - `Docs/content-design/[content]20260519_m8b_initiative_and_action_order.md` (페이즈 1 #2 — 추가 행동·행동 불가 hook)
> - `Docs/content-design/[content]20260519_m8b_combat_formulas.md` (페이즈 1 #3 — `statusEffectXxxMod` hook 7곳)
> - `Docs/roadmap/master_roadmap.md` M8b 섹션 1272행 — "버프, 디버프, 광역 공격, 메즈, 지속 피해 등 상태 효과 MVP"
>
> 후속:
> - 페이즈 2 #1 직업군 대표 스킬 — 상태 효과를 부여하는 스킬 정의
> - 페이즈 2 #3 상태 효과 수치 확정 — intensity·duration·발동 확률
> - 페이즈 3 #3 상태 효과 데이터 — `combat_status_effects` 8~12행 생성
> - 페이즈 4 #2 `CombatStatusEffect` 모델 명세

## 개요

이 산출물은 M8b 전투 시뮬레이터에서 사용할 상태 효과의 **타입·구조·결합 규칙**을 정의한다. 페이즈 1 #1~#3에서 명시한 상태 효과 hook 중 MVP 카탈로그가 직접 담당하는 항목과, 스킬·트레잇 플래그로 분리할 항목을 결정한다.

정확한 수치(공격력 +X%, 지속 N턴, 발동 Y%)는 페이즈 2 #3에서 확정한다. 이 산출물은 "어떤 상태 효과가 있고, 어디에 들어가고, 어떻게 결합되는가"의 구조에 집중한다.

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 적용 방식 |
|---------|--------------|----------|
| Darkest Dungeon — Blight & Bleed | 두 가지 DoT(중독/출혈)가 분리된 부여·해제 정책을 가진다 | `dot_bleeding` 비례형 + `dot_poisoned` 절대형으로 2가지 분리 |
| FFXIV — Status 카테고리 (Buff/Debuff) | 동일 ID 재부여 시 지속 갱신, 다른 ID는 별도 슬롯 | `stackPolicy: refresh` 기본 |
| Pillars of Eternity — 곱셈 Modifier | 다중 버프·디버프가 곱셈 결합 | (1 + buff) × (1 - debuff) 곱셈식 채택 |
| Slay the Spire — Stun (Skip Turn) | 메즈 보유자는 그 턴 행동 스킵, 다른 판정은 정상 | `mez_stunned`은 행동만 스킵, 회피·방어 판정 정상 |

## 1. 상태 효과 카탈로그 (10 타입 MVP)

페이즈 3 #3 권장 범위 8~12개 안에서 10 타입으로 시작한다.

### 1.1 버프 4 타입

| ID | 라벨 | 효과 | hook 매핑 | 적용 방식 |
|----|------|------|-----------|----------|
| `buff_attack_up` | 공격력 강화 | 공격력 ×(1+intensity) | §3.2 statusEffectAttackMod | 곱셈 |
| `buff_defense_up` | 방어력 강화 | 방어값 ×(1+intensity) | §4 statusEffectDefenseMod | 곱셈 |
| `buff_accuracy_up` | 명중 강화 | 명중률 +intensity (퍼센트 가산) | §6 statusEffectHitMod | 가산 |
| `buff_evasion_up` | 회피 강화 | 회피율 +intensity (퍼센트 가산) | §8 statusEffectEvasionMod | 가산 |

### 1.2 디버프 3 타입

| ID | 라벨 | 효과 | hook 매핑 | 적용 방식 |
|----|------|------|-----------|----------|
| `debuff_attack_down` | 공격력 약화 | 공격력 ×(1-intensity) | §3.2 statusEffectAttackMod | 곱셈 |
| `debuff_defense_down` | 방어력 약화 | 방어값 ×(1-intensity) | §4 statusEffectDefenseMod | 곱셈 |
| `debuff_accuracy_down` | 명중 약화 | 명중률 -intensity (퍼센트 가산) | §6 statusEffectHitMod | 가산 |

### 1.3 행동 불가 1 타입

| ID | 라벨 | 효과 | hook 매핑 | 적용 방식 |
|----|------|------|-----------|----------|
| `mez_stunned` | 기절 | 그 턴 행동 스킵 (피격·회피·방어는 정상) | §3.1 행동 시점 분기 | 행동 1회 소모 |

### 1.4 지속 피해 2 타입

| ID | 라벨 | 효과 | hook 매핑 | 적용 방식 |
|----|------|------|-----------|----------|
| `dot_bleeding` | 출혈 | 매 라운드 종료 시 비례 피해 | §5.1과 무관 (자체 산식) | DoT 산식 §5 |
| `dot_poisoned` | 중독 | 매 라운드 시작 시 절대 피해 | §5.1과 무관 (자체 산식) | DoT 산식 §5 |

### 1.5 hook 미매핑 항목 (MVP 범위 외)

페이즈 1 #3에서 정의한 hook 중 MVP에서 상태 효과 매핑이 없는 것:

| hook | 매핑 상태 |
|------|----------|
| §7 statusEffectCritMod | MVP 미매핑 — 페이즈 2 #1 스킬 효과에서 직접 처리 |
| §9 statusEffectRiposteMod | MVP 미매핑 — 페이즈 2 #1 스킬 효과에서 직접 처리 |
| §5.1 `skillDamageMultiplier` | 상태 효과 미매핑 — 페이즈 2 #1 광역 공격 스킬 효과에서 직접 처리 |
| §10 사망 저항 보정 | MVP 미매핑 — 트레잇·세력 패시브로만 |

MVP 10 타입에 모두 욱여넣지 않고, 페이즈 2 #1 스킬에서 직접 표현하는 효과를 분리한다. 이 분리는 (a) MVP 범위 보호, (b) 스킬의 정체성 강화, (c) 데이터량 폭증 방지를 목적으로 한다.

추가 행동(페이즈 1 #2 §9.3)도 MVP 상태 효과로 두지 않는다. 트레잇/스킬에서 직접 `extraAction: true` 플래그로 처리한다. 페이즈 4 #2 모델에서 확정한다.

## 2. 상태 효과 데이터 구조

페이즈 4 #2가 정확한 freezed/Hive 모델을 정의한다. 컨텐츠 관점의 최소 필드는 다음과 같다.

```text
CombatStatusEffect
- id: String                    // §1 ID (예: 'buff_attack_up')
- kind: StatusEffectKind        // {buff, debuff, mez, dot}
- hookTargets: List<StatHook>   // §3 hook 매핑
- durationTurns: int            // 남은 턴 (0 도달 시 자연 해제)
- intensity: double             // 0.0~1.0 (퍼센트 효과) 또는 정수 stack (DoT)
- stackPolicy: StackPolicy      // {refresh, stack, ignore}
- sourceKind: SourceKind        // {skill, trait, environment}
- sourceId: String?             // 출처 추적용
```

`intensity`는 효과 종류마다 의미가 다르다.

| kind | intensity 의미 | 페이즈 2 #3 확정 |
|------|---------------|------------------|
| buff/debuff | 곱셈 또는 가산 % (0.0~1.0) | 0.10~0.40 예상 |
| mez | 의미 없음 (있으면 1) | 항상 1 |
| dot | stack count (1~3) | 페이즈 2 #3 |

`durationTurns`는 라운드 단위. 부여 시 N → 라운드 종료마다 -1 → 0 도달 시 해제.

## 3. hook 매핑 결합 규칙

페이즈 1 #3 hook 산식에 상태 효과를 결합하는 방법.

### 3.1 곱셈 hook (`statusEffectAttackMod`, `statusEffectDefenseMod`)

```text
statusEffectAttackMod = (1 + sum(buff_attack_up.intensity))
                      × (1 - sum(debuff_attack_down.intensity))

baseAttack = roleAttackFormula(snapshot) × statusEffectAttackMod
```

다중 버프와 다중 디버프는 각각 합산 후 곱셈으로 결합. 예:
- buff_attack_up 0.15 + buff_attack_up 0.10 (둘 다 보유)
- debuff_attack_down 0.20

→ `baseAttack × (1 + 0.25) × (1 - 0.20) = baseAttack × 1.0`

### 3.2 가산 hook (`statusEffectHitMod`, `statusEffectEvasionMod`)

```text
statusEffectHitMod    = sum(buff_accuracy_up.intensity) - sum(debuff_accuracy_down.intensity)
statusEffectEvasionMod = sum(buff_evasion_up.intensity)

hitChance += statusEffectHitMod (퍼센트 단위, 0.10 = 10%)
evasionChance += statusEffectEvasionMod
```

페이즈 1 #3 §6/§8 클램프(`[50%, 95%]`/`[0%, 75%]`)를 그대로 적용. 상태 효과 합산 후 클램프된다.

### 3.3 결합 정책의 근거

| 항목 | 가산 vs 곱셈 | 근거 |
|------|-------------|------|
| 공격력/방어력 | 곱셈 | 절대 수치라 베이스 분포 폭이 크다. 곱셈이 직관적 |
| 명중률/회피율 | 가산 | 퍼센트 자체라 가산이 직관적. 클램프로 폭주 방지 |

이 정책은 페이즈 1 #3 §3.2/§4(곱셈), §6/§8(가산)과 정합한다.

## 4. 발동 정책

상태 효과는 다음 출처에서 발동한다.

| sourceKind | 발동 위치 | 예시 |
|------------|----------|------|
| `skill` | 페이즈 2 #1 직업군 대표 스킬의 부수 효과 | warrior 격노 스킬 → `buff_attack_up` |
| `trait` | 페이즈 1 #2 트레잇 hook (선제 라운드 시작 시 자동) | `vigilant` 트레잇 → `buff_evasion_up` 1턴 |
| `environment` | 페이즈 1 #1 Phase 1 사전 단계 자동 부여 | `mist_field` 전장 → 적군 전원 `debuff_accuracy_down` 2턴 |

상태 효과 부여는 발동 시점에 **저항 판정 없이** 부여된다(MVP 단순화). 페이즈 2 #1 스킬에 명시된 적용 확률(예: "70% 확률로 출혈 부여")이 발동 자체를 판정하는 유일한 단계다.

### 부여 확률 분기

페이즈 2 #1에서 스킬마다 `applyChance` 명시. 광역 공격의 경우 대상별 독립 판정.

```text
for each target in skill.targets:
    roll = Random(seed ^ stableSeed32('apply|$roundIndex|$sourceId|$targetId|$effectId'))
    if (roll < skill.statusEffect.applyChance):
        target.applyStatusEffect(skill.statusEffect)
```

광역 공격에서 같은 라운드의 대상 A는 출혈 부여 성공, 대상 B는 실패가 가능하다.

## 5. 지속 피해(DoT) 산식

페이즈 1 #3 §5.1 일반 피해 산식과 **분리**된 자체 산식을 사용한다. 방어 차감, 치명타, 명중 판정을 거치지 않는다.

### 5.1 `dot_bleeding` (비례형)

```text
bleedingDamage(target) = max(1, floor(target.maxHp × 0.04 × intensity_stack))
```

| stack | 효과 |
|-------|------|
| 1 | maxHp 4% |
| 2 | maxHp 8% |
| 3 (상한) | maxHp 12% |

발동 시점: **매 라운드 종료 시** (다른 라운드 종료 효과들과 함께).

비례형으로 설계하여 HP가 높은 적(엘리트·유니크)에게 의미를 가지게 한다. mage 류는 baseAttack이 낮아도 출혈 부여로 누적 피해를 낼 수 있다.

### 5.2 `dot_poisoned` (절대형)

```text
poisonedDamage(target) = max(1, floor(intensity × 5 + target.level × 2))
```

| intensity (페이즈 2 #3 확정) | level 1 target | level 5 target |
|----------------------------|----------------|----------------|
| 3 | 17 | 25 |
| 5 | 27 | 35 |
| 8 | 42 | 50 |

발동 시점: **매 라운드 시작 시** (행동 순서 정렬 전).

절대형으로 설계하여 HP가 낮은 약자(rogue·mage 등)에게 위협이 된다. warrior 류는 절대 피해 50도 견디지만, mage 류는 33 HP에 절대 피해 30이 치명적이다.

### 5.3 두 DoT 발동 시점 분리의 이유

- `dot_bleeding` 라운드 종료 → "이번 라운드 행동이 끝나고 피로 인한 피해를 받는다"는 서사
- `dot_poisoned` 라운드 시작 → "독이 라운드 내내 침투해 있다가 다음 라운드 시작 시 발현된다"는 서사
- 시점 분리는 라운드 종료 조건 (a)/(b)/(d) 평가 시점과의 결합에서도 의미가 있다. bleeding으로 죽음의 문턱에 간 대상이 라운드 시작 poisoned에 추가 사망 처리되는 식의 누적 위협이 가능하다.

### 5.4 사망 저항 적용

DoT로 HP가 0 이하로 떨어져도 페이즈 1 #3 §10 사망 저항 롤을 거친다. 저항 성공 시 HP=1, 부상 처리. DoT는 영구 피해가 아니다.

## 6. 행동 불가 (`mez_stunned`) 처리

페이즈 1 #2 §3 라운드 시작 시 일괄 정렬 정책과의 결합 규칙.

### 6.1 정렬 정책

stunned는 **정렬에는 포함**된다. `actionScore` 계산은 정상 수행한다.

### 6.2 행동 시점 분기

정렬 순서대로 행동을 진행할 때 stunned 보유자의 차례에 다음 분기를 거친다.

```text
if (combatant.hasStatusEffect('mez_stunned')) {
    // 행동 스킵
    recordSkippedTurn(combatant);
    continue;
}
// 정상 행동
```

### 6.3 회피·방어 판정은 정상

stunned 보유자가 공격받을 때는 회피·방패·반격 판정을 **정상** 수행한다. stunned는 **공격 행동만 차단**한다.

### 6.4 stunned 라운드 갱신

라운드 종료 시 stunned 지속 턴 -1. 0 도달 시 해제.

```text
if (combatant.hasStatusEffect('mez_stunned')) {
    combatant.getStatusEffect('mez_stunned').durationTurns -= 1;
    if (durationTurns <= 0) removeStatusEffect('mez_stunned');
}
```

### 6.5 추가 행동 hook과의 결합

페이즈 1 #2 §9.3에서 정의한 추가 행동(반격·트레잇 패시브·스킬)은 stunned 무시 정책을 따른다.

| 추가 행동 종류 | stunned 보유 시 |
|---------------|----------------|
| 반격 (회피 성공 후) | **수행** (stunned는 공격 행동만 차단, 반격은 반응 행동) |
| 트레잇 패시브 (스킬·턴 시작) | **차단** (적극적 행동) |
| 스킬 효과 (다음 라운드 추가 행동) | **차단** (적극적 행동) |

이 분기 정책은 MVP에서 단순화한 결정이다. 페이즈 4 #1 시뮬레이터 명세에서 정확한 정의를 둔다.

## 7. 중첩 정책 (`stackPolicy`)

같은 ID의 상태 효과가 재부여될 때의 처리.

### 7.1 refresh (대부분의 버프·디버프·메즈)

이미 보유 중이면 **지속 턴만 갱신**(이전과 새로운 것 중 큰 값). intensity는 갱신하지 않는다.

```text
if (target.hasStatusEffect(newEffect.id)) {
    target.getStatusEffect(newEffect.id).durationTurns
        = max(existing.durationTurns, newEffect.durationTurns);
} else {
    target.addStatusEffect(newEffect);
}
```

이 정책의 의미: 같은 버프를 재부여해도 효과가 강화되지 않지만, 효과가 끊기지 않는다.

### 7.2 stack (DoT 전용)

같은 ID의 DoT가 부여될 때 `intensity_stack` 증가 (상한 3).

```text
if (target.hasStatusEffect('dot_bleeding')) {
    existing.intensity = min(3, existing.intensity + 1);
    existing.durationTurns = max(existing.durationTurns, newDot.durationTurns);
} else {
    target.addStatusEffect(newDot);
}
```

이 정책은 다단 출혈/중독의 누적 위협을 만든다.

### 7.3 ignore (특수 케이스)

이미 보유 중이면 무시. MVP에서는 사용하지 않는다 (예약).

### 7.4 적용 표

| ID | stackPolicy |
|----|-------------|
| buff_attack_up | refresh |
| buff_defense_up | refresh |
| buff_accuracy_up | refresh |
| buff_evasion_up | refresh |
| debuff_attack_down | refresh |
| debuff_defense_down | refresh |
| debuff_accuracy_down | refresh |
| mez_stunned | refresh |
| dot_bleeding | stack |
| dot_poisoned | stack |

## 8. 해제 정책

### 8.1 해제 트리거

| 트리거 | 적용 | 설명 |
|--------|------|------|
| 지속 턴 0 도달 | 자연 해제 | 매 라운드 종료 시 -1 → 0 |
| 명시적 dispel | 즉시 해제 | 페이즈 2 #1 dispel 스킬 발동 시 |
| 대상 사망 | 모든 효과 해제 | 사망 처리 단계 (Phase 4) |
| 부상 처리 | 모든 효과 해제 | Phase 4 마무리 |
| 전투 종료 | 모든 효과 해제 | 시뮬레이션 완료 시점 |

### 8.2 dispel 분류

페이즈 2 #1 dispel 스킬은 두 가지로 분류한다.

| 분류 | 대상 | 비고 |
|------|------|------|
| `dispel_debuff` | 본인/아군의 debuff/dot 1~N개 해제 | support 직업군 |
| `dispel_buff` | 적군의 buff 1~N개 해제 | rogue 직업군 |

`mez_stunned`는 dispel로 해제되지 않는다 (MVP). 자연 해제만.

### 8.3 부분 해제

dispel은 대상의 모든 상태 효과를 해제하지 않고, **kind 매칭 1~N개**만 해제한다. 해제 우선순위는 페이즈 2 #1 스킬마다 정의.

## 9. 라운드 내 처리 순서

페이즈 1 #1 Phase 3 일반 라운드의 정확한 시퀀스에 상태 효과를 결합한다.

```text
Round Start
  ├─ DoT poisoned 자체 피해 적용 (대상별)
  │    └─ HP ≤ 0 도달 시 사망 저항 롤 (§5.4)
  ├─ 종료 조건 (a)/(b) 평가
  └─ 종료 조건 미충족 시 진행

Action Phase
  ├─ actionScore 일괄 계산 + 정렬
  └─ 정렬 순서대로 1명씩 행동:
      ├─ stunned 보유 시 행동 스킵
      ├─ 행동 (기본 공격 또는 스킬, 페이즈 2 #1)
      │    ├─ 명중 판정 → 회피 판정 → 방패 판정 → 피해 적용
      │    └─ 부수 효과 적용 (상태 효과 부여 등)
      └─ 반격 판정 (회피 성공한 방어자가 조건 충족 시)

Round End
  ├─ DoT bleeding 자체 피해 적용 (대상별)
  │    └─ HP ≤ 0 도달 시 사망 저항 롤
  ├─ 모든 상태 효과 durationTurns -1
  │    └─ 0 도달 시 자연 해제 (보고서에 텍스트 1줄 후보)
  ├─ 종료 조건 (a)/(b)/(c)/(d)/(e)/(f) 평가
  └─ 종료 조건 미충족 시 다음 라운드
```

### 동시 다발 사망 처리

라운드 시작 poisoned 또는 라운드 종료 bleeding으로 **여러 대상이 동시에 HP 0**에 도달할 수 있다. 이 경우 모든 대상에 대해 사망 저항 롤을 독립적으로 진행하고, Phase 4까지는 사망 마킹만 한다. 라운드 중간의 동시 사망은 전투 종료 조건 (a)/(b)를 즉시 트리거할 수 있다.

## 10. 결정성

페이즈 1 #1 §결정성과 페이즈 1 #3 §14 PRNG 분리 정책을 그대로 사용한다.

```text
applyRoll      = Random(seed ^ stableSeed32('apply|$roundIndex|$pairId|$effectId'))
dotRoll        = Random(seed ^ stableSeed32('dot|$roundIndex|$targetId|$effectId'))
dispelRoll     = Random(seed ^ stableSeed32('dispel|$roundIndex|$casterId'))
```

DoT 피해량은 §5.1/§5.2 산식이 결정적(반올림 후 정수)이라 PRNG가 필요 없다. `dotRoll`은 부수 효과(예: 출혈 stack이 임계값에서 추가 피해 증폭) 발동 시에만 사용한다 — MVP는 미사용, 예약. Dart 런타임 `hashCode`는 사용하지 않는다.

## 11. 보고서 노출 정책 (페이즈 1 #3 §11 정합)

### 11.1 노출 정책

| 이벤트 | 보고서 노출 | 정책 |
|--------|------------|------|
| 상태 효과 부여 | 노출 | 라벨 + 지속 턴 (예: "출혈 3턴 부여") |
| 상태 효과 자연 해제 | 노출 | 라벨만 (예: "독이 사라졌다") |
| 상태 효과 dispel 해제 | 노출 | 시전자 + 대상 + 라벨 (예: "신관이 도적의 강화를 풀었다") |
| DoT 피해 적용 | 노출 | 라벨 + 피해 정수 (예: "출혈로 12 피해") |
| stack 증가 | 노출 | 새 스택 수 (예: "출혈 2 스택") |
| stunned 행동 스킵 | 노출 | 텍스트만 (예: "도적이 기절해 행동하지 못했다") |
| intensity 값 | 비노출 | 페이즈 1 #3 §11.3 확률 비노출 정책과 정합 |
| applyChance 발동 결과 | 비노출 | 결과(부여 성공/실패)만 텍스트로 |

### 11.2 라벨 사용 정책

상태 효과의 한국어 라벨은 `combat_status_effects` 테이블 컬럼 `display_label`에 저장 (페이즈 3 #3). 보고서 템플릿은 `{statusEffect.label}` 변수로 참조.

기본 라벨 권고:

| ID | display_label |
|----|---------------|
| buff_attack_up | 공격력 강화 |
| buff_defense_up | 방어력 강화 |
| buff_accuracy_up | 명중 강화 |
| buff_evasion_up | 회피 강화 |
| debuff_attack_down | 공격력 약화 |
| debuff_defense_down | 방어력 약화 |
| debuff_accuracy_down | 명중 약화 |
| mez_stunned | 기절 |
| dot_bleeding | 출혈 |
| dot_poisoned | 중독 |

페이즈 3 #4 전투 로그 템플릿이 이 라벨을 직접 참조한다.

### 11.3 보고서 라인 예시

페이즈 1 #1 §M8a 호환 §라운드 압축 정책과 결합:

```text
[전개] 신관이 김철수에게 방어력 강화 2턴 부여.
[전개] 도적 대장이 박영희에게 출혈 2턴 부여.
[위기] 박영희가 출혈로 8 피해.
[해소] 김철수의 방어력 강화가 사라졌다.
[해소] 도적 대장이 쓰러졌다.
```

페이즈 3 #4 템플릿이 이 분포를 만든다.

## 12. ID 네이밍 규칙

페이즈 4 #2 데이터 모델 입력을 위한 ID 네이밍.

### 12.1 형식

```text
{kind}_{effect}[_{direction}]
```

- `kind` ∈ {buff, debuff, mez, dot}
- `effect` ∈ {attack, defense, accuracy, evasion, stunned, bleeding, poisoned, ...}
- `direction` ∈ {up, down} — buff는 up, debuff는 down

### 12.2 확장 케이스

페이즈 2 #1 신규 상태 효과 추가 시:

| 후보 | ID | 비고 |
|------|----|----|
| 치명타 강화 | `buff_crit_up` | §7 hook |
| 반격 강화 | `buff_riposte_up` | §9 hook |
| 화상 (DoT) | `dot_burning` | §5.1/§5.2 외 신규 산식 후보 |
| 침묵 (스킬 차단) | `mez_silenced` | mage 표적 |
| 도발 (표적 강제) | `mez_taunted` | 페이즈 1 #2 §7 표적 정책 보완 |

이 카탈로그는 MVP 10 타입을 넘어선다. 페이즈 2 #1 스킬 설계에서 필요 시 추가.

### 12.3 snake_case 일관성

ID는 snake_case로 통일한다. 카탈로그 ID는 `display_label`(한국어)과 분리하여 페이즈 4 #2 모델의 `String` 필드로 보존.

## 13. 현재 시스템과의 연관

| 시스템 | 영향 | 처리 방식 |
|--------|------|----------|
| 페이즈 1 #1 Phase 3 라운드 흐름 | §9 라운드 내 처리 순서 결합 | 변경 없음 |
| 페이즈 1 #2 행동 순서 정렬 | §6 stunned 정렬 포함, 행동 시점 스킵 | 변경 없음 |
| 페이즈 1 #2 추가 행동 hook | §6.5 분기 정책 | MVP는 상태 효과 매핑 없음 |
| 페이즈 1 #3 7개 hook | §3 결합 규칙으로 활성화 | hook 활성화 완료 |
| 페이즈 1 #3 §5.1 일반 피해 산식 | DoT는 분리 산식 | DoT는 방어 차감·치명타 없음 |
| 페이즈 1 #3 §10 사망 저항 | DoT 사망 진입 시도 호환 | §5.4 변경 없음 |
| 페이즈 1 #3 §11 보고서 노출 정책 | §11 라벨·지속 턴 노출 / intensity 비노출 | 정합 |
| `Mercenary` 본체 | 상태 효과를 용병 본체에 영속화하지 않음. 상태 이벤트는 전투 로그에만 보존 | 변경 없음 |
| `MercenaryStatus` enum | injured/deceased만 영속, M8b 전투 중 상태 효과는 별도 | 변경 없음 |
| `combat_report_keywords` | category=decisive 키워드와 §11.3 라인이 결합 | 페이즈 3 #4 확장 후보 |

## 14. 구현 우선순위 제안

| 우선순위 | 항목 | 이유 |
|----------|------|------|
| 높음 | 10 타입 카탈로그 확정 | MVP 범위 |
| 높음 | `CombatStatusEffect` 모델 5 필드 (페이즈 4 #2) | 데이터 구조 |
| 높음 | hook 매핑 (곱셈 vs 가산) | 페이즈 1 #3 hook 활성화 |
| 높음 | stunned 행동 시점 분기 | 페이즈 1 #2 정렬 정합 |
| 높음 | DoT 분리 산식 (비례/절대) | 페이즈 1 #3 §5.1과 결합 분리 |
| 높음 | 라운드 처리 순서 (DoT 시점, 지속 턴 갱신) | §9 |
| 중간 | stack 정책 (DoT 상한 3) | 누적 위협 |
| 중간 | refresh 정책 (지속 턴 max 갱신) | 단순화 |
| 중간 | dispel 분류 (debuff vs buff) | 페이즈 2 #1 |
| 낮음 | 라벨 한국어 (`display_label`) | 페이즈 3 #3 |
| 낮음 | 보고서 라인 노출 정책 정합 | 페이즈 3 #4 템플릿 |

## 15. data-generator 지시사항

페이즈 3 #3에서 `combat_status_effects` 신규 테이블에 10행을 생성한다. 이 산출물이 시드 데이터의 골격이 된다.

### 권장 컬럼 (페이즈 4 #2 모델 명세에서 확정)

| 컬럼 | 타입 | 예시 |
|------|------|------|
| `id` | TEXT PK | `buff_attack_up` |
| `kind` | TEXT (enum) | `buff` |
| `display_label` | TEXT | `공격력 강화` |
| `default_duration_turns` | INT | 2 |
| `default_intensity` | NUMERIC | 0.20 |
| `stack_policy` | TEXT (enum) | `refresh` |
| `hook_target` | TEXT[] | `['attack']` |
| `apply_method` | TEXT (enum) | `multiplicative` 또는 `additive` |
| `description` | TEXT | 보고서 노출용 보충 설명 |

페이즈 2 #3에서 `default_duration_turns`/`default_intensity` 수치 분포를 확정한다.

## 16. 다음 단계

페이즈 1 컨텐츠 설계가 4/4 완료된다. 다음 행동은 페이즈 1 종료 체크포인트 → 페이즈 2 시작이다.

페이즈 2 #1 직업군 대표 스킬 설계에서 본 카탈로그의 상태 효과를 부수 효과로 결합한다. 예: warrior 격노 스킬 → 자신에게 `buff_attack_up` 2턴 부여.

페이즈 2 #3 상태 효과 수치 확정에서 본 카탈로그의 `default_duration_turns`, `default_intensity`, DoT stack 상한 등을 수치화한다.

페이즈 3 #3에서 `combat_status_effects` 10행 시드 데이터를 생성한다.

페이즈 4 #2에서 `CombatStatusEffect` freezed 모델을 명세한다.
