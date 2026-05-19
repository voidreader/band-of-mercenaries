# M8b 기본 공격·피해량·명중·회피·치명타 공식 기획서

> 작성일: 2026-05-19
> 유형: 신규 컨텐츠 (M8b 마일스톤 — 페이즈 1 산출물 3/4)
> 선행 문서:
> - `Docs/content-design/[content]20260519_m8b_combat_turn_structure.md` (페이즈 1 #1)
> - `Docs/content-design/[content]20260519_m8b_initiative_and_action_order.md` (페이즈 1 #2)
> - `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart` (`effectiveXxx` 162~191행)
> - `band_of_mercenaries/lib/core/constants/game_constants.dart` (`levelBonusPerLevel=0.1`, `tiredDebuffMultiplier=0.8`)
> - `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` (`_statWeights`)
> - `band_of_mercenaries/lib/features/inventory/domain/equipment_stat_bonus.dart`
> - `Docs/roadmap/master_roadmap.md` M8b 섹션 1270행
>
> 후속:
> - 페이즈 1 #4 상태 효과 MVP — 공격력/방어력/명중/회피 상태 효과 배수
> - 페이즈 2 #2 적 유형 — 적 측 HP·공격·방어 베이스
> - 페이즈 2 #4 전투 로그 노출 기준 — 본 산출물 §10 보고서 노출 정책의 데이터 매트릭스화
> - 페이즈 4 #1 `CombatSimulator` 명세 — 본 산출물의 산식을 코드로

## 개요

이 산출물은 M8b 전투의 모든 수치 산식을 정의한다. HP·피해·명중·회피·치명타·방어·사망 저항·보고서 수치 노출까지 8개 영역의 결합 구조를 모두 다룬다. 페이즈 1 #1의 시드 정책과 페이즈 1 #2의 직업군 매트릭스·트레잇 카테고리 매핑을 그대로 사용한다.

여기서 정의한 산식은 페이즈 2 #2(적 유형)와 페이즈 2 #4(전투 로그 노출 기준)에서 적 측 베이스 수치와 함께 검증된다. 상태 효과(공격력 증감, 방어력 감소, 행동 불가 등)의 영향은 hook 위치만 명시하고 정확한 배수는 페이즈 1 #4에서 확정한다.

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 적용 방식 |
|---------|--------------|----------|
| Battle Brothers — 피해 = 공격 - 방어 | 단순 차감식 + 클램프 1 최소값 | `damage = max(1, atk - def)` 단순화 |
| Darkest Dungeon — Death's Door | HP 0 도달 후 사망 저항 롤로 1턴 더 생존 | M8b는 단발 저항: 성공 → 부상, 실패 → 사망 |
| Pillars of Eternity — 명중/빗나감/그레이즈/크리티컬 4단계 | 단일 판정에서 4 가지 결과 분기 | M8b는 명중/회피/방패 막기/치명타 4 분기 |
| Wizardry — AC 기반 방어 | AGI/회피와 별개로 방어값 차감 | AGI는 회피·명중·치명타, VIT는 HP·방어 |

## 1. 스탯 기준값과 동결

### 1.1 effective 스탯 동결

페이즈 1 #1에서 정의한 대로 `CombatantSnapshot` 동결 시점에 다음 값을 캡처한다.

```text
snapshot.str = effectiveStrWith(equipmentBonus)
snapshot.int = effectiveIntelligenceWith(equipmentBonus)
snapshot.vit = effectiveVitWith(equipmentBonus)
snapshot.agi = effectiveAgiWith(equipmentBonus)
```

각 스탯은 `((base + permanent + equipment) × (1 + 0.1 × (level-1)))` 결과이며, 동결 시점 `MercenaryStatus.tired`이면 ×0.8을 추가 적용한다. 동결 후에는 시뮬레이션 도중 변경되지 않는다.

### 1.2 통상 스탯 범위 (참고)

| Tier | 베이스 합계 (STR+INT+VIT+AGI) | 단일 스탯 상한 (레벨 5 만렙 + 장비 4개 만렙 기준) |
|------|-----------------------------|---------------------------------------------------|
| T1 | 10~16 | ~25 |
| T2 | 18~26 | ~38 |
| T3 | 28~38 | ~55 |
| T4 | 40~52 | ~72 |
| T5 | 54~70 | ~95 |

이 범위는 산식 검증의 기준선이다. 페이즈 2 #4에서 실제 분포와 함께 재검증한다.

## 2. HP 산식

### 2.1 베이스 HP

```text
baseHp = (snapshot.vit × roleVitCoef) + roleHpFlat + tierHpBonus + level × 6
```

| 항 | 의미 | 값 |
|----|------|-----|
| `snapshot.vit × roleVitCoef` | VIT 환산 HP | 직업군별 계수 (아래) |
| `roleHpFlat` | 직업군 고정 HP | 직업군별 (아래) |
| `tierHpBonus` | 티어 보너스 | T1=0, T2=10, T3=25, T4=45, T5=70 |
| `level × 6` | 레벨 보너스 | 1=6, 5=30 |

### 2.2 직업군 HP 계수

| 직업군 | `roleVitCoef` | `roleHpFlat` | 베이스 HP (Tier1 신참 — VIT 4, Lv1) |
|--------|--------------|--------------|-------------------------------------|
| warrior | 5.5 | 30 | 4×5.5 + 30 + 0 + 6 = **58** |
| specialist | 4.5 | 25 | 4×4.5 + 25 + 0 + 6 = **49** |
| ranger | 4.0 | 20 | 4×4.0 + 20 + 0 + 6 = **42** |
| rogue | 3.5 | 18 | 4×3.5 + 18 + 0 + 6 = **38** |
| support | 4.0 | 22 | 4×4.0 + 22 + 0 + 6 = **44** |
| mage | 3.0 | 15 | 4×3.0 + 15 + 0 + 6 = **33** |

### 2.3 HP 분포 검증

|  | T1 Lv1 (VIT 4) | T3 Lv3 (VIT 10) | T5 Lv5 (VIT 18) |
|---|---------------|-----------------|------------------|
| warrior | 58 | 5.5×10 + 30 + 25 + 18 = **128** | 5.5×18 + 30 + 70 + 30 = **229** |
| mage | 33 | 3.0×10 + 15 + 25 + 18 = **88** | 3.0×18 + 15 + 70 + 30 = **169** |

T1 신참 ~ T5 정예 사이 HP 격차 약 4~5배. 한 라운드 평균 피해량 10~25의 분포와 결합해 3~6 라운드 평균 전투 길이(페이즈 1 #1)를 자연스럽게 만든다.

### 2.4 HP는 시뮬레이션 도중 변동

HP만은 동결 후에도 변경되는 유일한 시뮬레이션 상태다 (페이즈 1 #1 동결 정책 예외). 라운드 단위 피해/회복으로 갱신된다.

## 3. 공격력 산식

### 3.1 직업군별 공격 스탯

직업군마다 STR과 INT의 결합 비율이 다르다.

| 직업군 | 공격 산식 | 분류 |
|--------|----------|------|
| warrior | `snapshot.str × 1.2` | 순수 STR (근접) |
| specialist | `snapshot.str × 1.0` | 순수 STR (근접) |
| rogue | `snapshot.str × 0.7 + snapshot.agi × 0.4` | 혼합 (속도형) |
| ranger | `snapshot.str × 0.5 + snapshot.agi × 0.5` | 혼합 (원거리) |
| mage | `snapshot.int × 1.2` | 순수 INT (마법) |
| support | `snapshot.int × 0.8 + snapshot.vit × 0.3` | 혼합 (보조) |

### 3.2 기본 공격력 = 공격 산식 + 가산

```text
baseAttack = roleAttackFormula(snapshot)
           + weaponAttackBonus
           + statusEffectAttackMod(페이즈 1 #4 hook)
```

| 항 | 의미 | 출처 |
|----|------|------|
| `roleAttackFormula` | 위 3.1 표 | 직업군별 |
| `weaponAttackBonus` | 무기 슬롯 공격 보정 | `EquipmentStatBonus`는 스탯 기반이므로 이미 snapshot에 반영됨. M8b에서 무기 슬롯 직접 공격 보너스는 0(MVP). 추후 무기 슬롯 확장 시 hook |
| `statusEffectAttackMod` | 상태 효과 공격력 증감 | 페이즈 1 #4 곱셈/가산 분기 |

## 4. 방어값 산식

```text
baseDefense = snapshot.vit × roleDefCoef
            + roleDefFlat
            + armorDefenseBonus
            + statusEffectDefenseMod(페이즈 1 #4 hook)
```

### 4.1 직업군 방어 계수

| 직업군 | `roleDefCoef` | `roleDefFlat` | 베이스 방어 (T1 VIT 4) |
|--------|--------------|--------------|------------------------|
| warrior | 1.5 | 8 | 4×1.5 + 8 = **14** |
| specialist | 1.2 | 6 | 4×1.2 + 6 = **10.8** |
| ranger | 1.0 | 4 | 4×1.0 + 4 = **8** |
| rogue | 0.8 | 3 | 4×0.8 + 3 = **6.2** |
| support | 1.0 | 5 | 4×1.0 + 5 = **9** |
| mage | 0.7 | 2 | 4×0.7 + 2 = **4.8** |

소수점은 정수 반올림 후 저장한다 (보고서 노출용).

### 4.2 방패 막기 적용

페이즈 1 #2 §8.3 방패 막기 hook이 발동하면 다음 추가 감소를 적용한다.

```text
mitigation = shieldBlockReduction(defender.traitIds, defender.equipment)
finalDamage = max(1, baseDamage - finalDefense)
            × (1.0 - mitigation)
```

### 4.3 방패 막기 감소율

| 발동 조건 | 감소율 |
|-----------|--------|
| 방패 트레잇 1개 (`shield_basic` 키워드군) | 0.20 (20% 감소) |
| 방패 트레잇 2개 이상 누적 | 0.30 (30% 감소) |
| 방패 트레잇 + 방패 무기 슬롯 | 0.40 (40% 감소) |
| 방패 막기 스킬 발동 (페이즈 2 #1) | +0.10 ~ +0.20 추가 (조합 시 상한 0.60) |

방패 막기는 회피 실패 후 적용된다 (페이즈 1 #2 §8.4 판정 순서).

## 5. 피해량 산식

### 5.1 단발 피해

```text
rawDamage = (max(1, baseAttack - defense)
           × critMultiplier (치명타 발동 시)
           × (1.0 - shieldMitigation) (방패 막기 발동 시)
           × skillDamageMultiplier (페이즈 2 #1 스킬 직접 배수))
           + random(-noiseRange, +noiseRange)

hitDamage = max(1, round(rawDamage))
```

| 항 | 값 |
|----|-----|
| `noiseRange` | floor(baseAttack × 0.10), 최소 1, 최대 5 |
| `critMultiplier` | 직업군별 (§7) |
| `shieldMitigation` | §4.3 |

### 5.2 최저 피해 1

방어가 공격보다 높거나 노이즈가 음수로 적용되어도 최종 피해는 최소 1로 클램프한다. 무한 무피해 회피 루프를 방지한다.

### 5.3 다단 행동의 피해

페이즈 1 #2 §9 다단 행동 규칙에 따라 광역/연속 공격은 개별 대상에 §5.1 산식을 독립 적용한다. 광역의 피해 분산 정책은 페이즈 2 #1 스킬마다 정의한다.

## 6. 명중률 산식

```text
hitChance = baseHitRate(role)
          + (snapshot.atk_agi - snapshot.def_agi) × agiHitCoef
          + traitHitBonus(attacker.traitIds)
          + battlefieldHitMod(role, environmentTags)
          + statusEffectHitMod(페이즈 1 #4 hook)
          - rangePenalty
```

클램프: **[50%, 95%]**.

### 6.1 직업군 베이스 명중률

| 직업군 | `baseHitRate` |
|--------|---------------|
| warrior | 80% |
| specialist | 78% |
| ranger | 82% (조준형) |
| rogue | 76% |
| mage | 75% |
| support | 75% |

### 6.2 AGI 차이 계수

```text
agiHitCoef = 0.8% per 1 AGI 차이
```

예: 공격자 AGI 12, 방어자 AGI 8 → +3.2% 명중

### 6.3 거리 패널티

| 조건 | `rangePenalty` |
|------|----------------|
| 원거리(ranger/mage/support)가 후열 표적 공격 | 0% |
| 원거리가 전열 우회하여 중·후열 강제 표적 (광역 등) | 0% |
| 접근형(warrior/specialist/rogue)이 적 중열 공격 (전열 전멸 후) | 0% |
| 접근형이 후열 강제 공격 (관통 스킬 등 페이즈 2 #1) | 5% |

### 6.4 트레잇 명중 보너스

| 카테고리 | 키워드 후보 | 가중치 |
|----------|-------------|--------|
| Talent | `marksman`, `keen_eye`, `sniper` | +5% per 트레잇 |
| Survival | `tracker`, `huntsman` | +3% per 트레잇 |
| Background | `veteran` | +2% per 트레잇 |

진영 1명당 명중 트레잇 합산 상한 **+10%**.

### 6.5 전장 명중 보정

| 전장 태그 | 명중 보정 |
|-----------|----------|
| mist_field (M7 안개) | -10% (모두) |
| dungeon (좁은 공간) | +5% (접근형) / -3% (원거리) |
| forest | -3% (원거리) |
| swamp | -2% (모두) |
| sea_coast | 0% |
| desert | -2% (원거리) |
| mountain | +3% (원거리) |
| ruined_castle | +2% (모두) |

## 7. 치명타 산식

### 7.1 치명타 발동 확률

```text
critChance = baseCritRate(role)
           + snapshot.atk_agi × agiCritCoef
           + traitCritBonus(attacker.traitIds)
           + flankBonus
           + statusEffectCritMod (페이즈 1 #4 hook)
```

클램프: **[5%, 60%]**.

### 7.2 직업군 베이스 치명타

| 직업군 | `baseCritRate` |
|--------|----------------|
| warrior | 5% |
| specialist | 5% |
| ranger | 10% (정조준) |
| rogue | 15% (급소 노림) |
| mage | 8% |
| support | 5% |

### 7.3 AGI 치명타 계수

```text
agiCritCoef = 0.3% per 1 AGI
```

예: AGI 15 → +4.5% 치명타

### 7.4 후방 공격 보너스 (Flank)

페이즈 1 #2 §7 진형 매칭에서 후열 표적을 직접 공격하는 경우만:

| 조건 | `flankBonus` |
|------|--------------|
| rogue가 적 후열 공격 (전열 전멸 후) | +10% |
| ranger가 적 후열 공격 | +5% |
| 그 외 | 0% |

이 보너스는 직업군 정체성을 보강한다.

### 7.5 트레잇 치명타 보너스

| 카테고리 | 키워드 후보 | 가중치 |
|----------|-------------|--------|
| CombatStyle | `precise`, `deadly`, `assassin` | +5% per 트레잇 |
| Talent | `keen_eye`, `sharpshooter` | +4% per 트레잇 |

진영 1명당 치명타 트레잇 합산 상한 **+15%**.

### 7.6 치명타 피해 배수 `critMultiplier`

| 직업군 | 배수 |
|--------|------|
| rogue | 2.0× (급소 일격) |
| ranger | 1.7× |
| mage | 1.7× (집중 마법) |
| warrior | 1.5× |
| specialist | 1.5× |
| support | 1.5× |

## 8. 회피율 산식 (페이즈 1 #2 hook 채우기)

페이즈 1 #2 §8.1이 명시한 회피 hook의 % 산식을 확정한다.

```text
evasionChance = baseEvasion(role)
              + (snapshot.def_agi - snapshot.atk_agi) × agiEvasionCoef
              + traitEvasionBonus(defender.traitIds)
              + battlefieldEvasionMod(defender.role, environmentTags)
              + statusEffectEvasionMod (페이즈 1 #4 hook)
```

클램프: **[0%, 75%]**.

### 8.1 직업군 베이스 회피율

| 직업군 | `baseEvasion` |
|--------|---------------|
| warrior | 5% |
| specialist | 8% |
| ranger | 15% |
| rogue | 18% |
| support | 10% |
| mage | 7% |

### 8.2 AGI 회피 계수

```text
agiEvasionCoef = 0.8% per 1 AGI 차이
```

예: 공격자 AGI 10, 방어자 AGI 18 → +6.4% 회피

### 8.3 트레잇 회피 보너스

| 카테고리 | 키워드 후보 | 가중치 |
|----------|-------------|--------|
| Survival | `evasion`, `nimble`, `slippery`, `dodge` | +4% per 트레잇 |
| Physical | `agile`, `light_step` | +3% per 트레잇 |

진영 1명당 회피 트레잇 합산 상한 **+12%**.

### 8.4 전장 회피 보정

| 전장 태그 | 회피 보정 |
|-----------|----------|
| forest | +3% (전원) |
| dungeon (좁은 공간) | -5% (모두) |
| mist_field | +5% (전원) |
| swamp | -3% (전원) |
| 그 외 | 0% |

## 9. 반격 산식 (페이즈 1 #2 hook 채우기)

페이즈 1 #2 §8.2가 명시한 반격 hook의 % 산식을 확정한다.

```text
riposteChance = baseRiposte(role)
              + traitRiposteBonus(defender.traitIds)
              + statusEffectRiposteMod (페이즈 1 #4 hook)
```

클램프: **[0%, 60%]**.

### 9.1 직업군 베이스 반격률

| 직업군 | `baseRiposte` |
|--------|---------------|
| warrior | 25% |
| specialist | 15% |
| rogue | 20% |
| ranger | 10% |
| mage | 0% |
| support | 0% |

mage·support는 트레잇 보너스가 있어도 클램프 [0%]만 보장하며 통상적으로 반격하지 않는다.

### 9.2 트레잇 반격 보너스

| 카테고리 | 키워드 후보 | 가중치 |
|----------|-------------|--------|
| CombatStyle | `riposte`, `counter`, `vengeance` | +8% per 트레잇 |
| Mental | `vigilant`, `unyielding` | +5% per 트레잇 |

진영 1명당 반격 트레잇 합산 상한 **+20%**.

### 9.3 반격 피해

반격 피해는 §5.1과 동일 산식이며, 치명타/회피/방패 막기 판정도 모두 거친다. **단 반격에서 반격은 발생하지 않는다** (페이즈 1 #2 §8.4).

## 10. 사망 저항 산식

페이즈 1 #1 Phase 4 매핑에서 HP ≤ 0 도달 시 1회 사망 저항 롤을 수행한다.

```text
deathResistChance = baseDeathResist(tier)
                  + roleDeathResist(role)
                  + traitDeathResist(traitIds)
                  + factionPassiveDeathResist (M8a hook)
```

일반 클램프: **[20%, 80%]**. 체인 퀘스트 주인공 보호는 §10.6 예외 상한을 적용한다.

### 10.1 티어 기반 베이스 저항

| Tier | `baseDeathResist` |
|------|-------------------|
| T1 | 30% |
| T2 | 35% |
| T3 | 45% |
| T4 | 55% |
| T5 | 65% |

### 10.2 직업군 저항 보너스

| 직업군 | `roleDeathResist` |
|--------|-------------------|
| warrior | +10% |
| specialist | +5% |
| 그 외 | 0 |

### 10.3 트레잇 저항 보너스

| 카테고리 | 키워드 후보 | 가중치 |
|----------|-------------|--------|
| Survival | `survivor`, `tough`, `resilient` | +5% per 트레잇 |
| Physical | `iron_body`, `hardy` | +5% per 트레잇 |

진영 1명당 사망 저항 트레잇 합산 상한 **+15%**.

### 10.4 세력 패시브 (M8a hook)

M8a 세력 패시브 일부(전사 길드 가입자, 모험가 길드 신뢰 단계)는 사망 저항 +3~5%를 부여할 수 있다. 페이즈 4 #3 `QuestCompletionService` 통합 명세에서 hook을 활성화한다.

### 10.5 결과 분기

| 롤 결과 | 처리 |
|---------|------|
| 저항 성공 | HP = 1, `MercenaryStatus.injured` (페이즈 1 #1 Phase 4 일괄 적용) |
| 저항 실패 | `MercenaryStatus.deceased`, `Mercenary.die()` 호출 |

### 10.6 체인 퀘스트 주인공 보호

기존 시스템: 체인 퀘스트 주인공은 사망률 50% 감소. M8b도 이를 유지한다.

```text
if (quest.isChainQuest && mercId == quest.chainProtagonistId) {
    deathResistChance += (1.0 - deathResistChance) * 0.5;
    deathResistChance = min(deathResistChance, 0.90);
}
```

저항 확률을 단순 +50%p가 아니라 "잔여 사망 확률의 절반을 저항으로 전환"하는 방식으로 결합한다. 예: 저항 50% → 75%, 저항 70% → 85%. 일반 상한 80%를 넘을 수 있지만, 체인 주인공도 최종 상한 90%를 넘지 않는다.

## 11. 보고서 노출 수치 기준

페이즈 1 #1 §M8a 호환 §라인 압축 정책과 M8a 길이 매트릭스(2~4 요약 / 4~8 상세)와 정합한다.

### 11.1 노출 정책

| 데이터 | 보고서 노출 | 정책 |
|--------|------------|------|
| 단발 피해량 | 노출 | 정수 (예: "47의 피해를 입혔다") |
| 치명타 발동 | 노출 | 텍스트 + 정수 (예: "치명타! 89") |
| 회피 | 노출 | 텍스트만 (예: "도적이 회피했다") |
| 방패 막기 | 노출 | 텍스트 + 감소 비율 (예: "방패로 막아 30% 감소") |
| 반격 | 노출 | 텍스트 + 피해 정수 (예: "반격으로 15의 피해") |
| 광역 공격 | 노출 | 대상 수 + 합계 (예: "3명에게 총 65의 피해") |
| 연속 공격 | 노출 | 횟수 + 합계 (예: "3연타로 47") |
| 상태 효과 부여 | 노출 | 텍스트 + 지속 턴 (예: "출혈 3턴 부여") |
| HP 절대값 | 비노출 | 비율/상태만 (예: "절반 이하", "빈사", "쓰러졌다") |
| 명중률/회피율/치명타율 % | 비노출 | 수치 노출 피로 방지. 결과만 텍스트로 |
| 사망 저항 % | 비노출 | "죽음의 문턱에서 일어났다" 같은 텍스트만 |
| 진형/행동 순서 | 비노출 | 결정적 장면 라인에 텍스트로만 간접 표현 |

### 11.2 라인 구성 예시

페이즈 1 #1 §라운드 압축 정책의 보고서 8줄 한도와 결합한다.

```text
[진입] 더스트빌 폐광 입구에서 좁은 통로를 마주했다.
[전개] 김철수가 도적 대장에게 47의 피해를 입혔다.
[전개] 박영희가 후위 궁수에게 치명타! 89.
[위기] 도적 부두목이 정찰꾼에게 32의 피해. 정찰꾼이 부상.
[해소] 김철수가 도적 대장의 일격을 방패로 막아 30% 감소.
[해소] 도적 대장이 쓰러졌다.
[후일담] 파티는 무사히 귀환했다.
```

요약 문장은 정확한 피해 수치 없이 결과 톤만 유지한다 ("우세한 격전 끝에 적 우두머리를 쓰러뜨렸다"). 정수 노출은 상세 라인에만 한정한다.

### 11.3 비노출 정책의 근거

M8a 보고서 MVP가 "용병단 기록"의 톤을 유지하기 위해 과도한 수치 노출을 피했다. M8b도 이를 계승한다. 시뮬레이션 결정성과 보고서 가독성의 균형을 위해 다음 원칙을 둔다.

- **노출**: 행동 결과(피해/사망/부상)는 보여준다.
- **비노출**: 행동 확률(명중/회피/치명타/사망 저항 %)은 가린다.
- **간접 표현**: HP 비율은 정수 대신 "절반 이하"/"빈사" 텍스트로.

확률 수치 자체는 페이즈 4 #5 검증 단계 디버그 로그에서만 노출한다.

## 12. 산식 결합 검증

### 12.1 라운드 1 평균 피해 예시

조건:
- 공격자: T3 warrior, Lv3, snapshot.str=15, snapshot.agi=10
- 방어자: T3 specialist, Lv3, snapshot.vit=12, snapshot.agi=9
- 환경: forest

산식 추적:
- baseAttack = 15 × 1.2 = **18**
- baseDefense = 12 × 1.2 + 6 = **20.4 → 20**
- hitChance = 80% + (10-9)×0.8% - 3%(forest 원거리만 적용, warrior는 0%) = **80.8% → 81%**
- critChance = 5% + 10×0.3% + 0% = **8%**
- evasionChance = 8% + (9-10)×0.8% + 3%(forest 전체) = **10.2% → 10%**
- 명중 시 단발 피해 = max(1, 18-20) + noise(-2~+2) = **1 ~ 3**

낮은 피해 분포. 방어가 공격을 초과하는 매치업은 라운드가 길어지고 보고서가 단조로워진다. 페이즈 2 #4 검증에서 직업군 매치업별 평균 라운드 수를 시뮬레이션한다.

### 12.2 라운드 1 평균 피해 예시 (mage vs warrior)

조건:
- 공격자: T3 mage, Lv3, snapshot.int=15, snapshot.agi=11
- 방어자: T3 warrior, Lv3, snapshot.vit=15, snapshot.agi=8

산식 추적:
- baseAttack = 15 × 1.2 = **18**
- baseDefense = 15 × 1.5 + 8 = **30.5 → 31**
- 명중 시 단발 피해 = max(1, 18-31) + noise = **1 ~ 3**

mage는 warrior 전열에 비효율적이다. 페이즈 1 #2 진형 정책에서 mage가 후열 표적을 우선하도록 한 것이 합리적임을 검증한다.

### 12.3 페이즈 1 #1 라운드 권장 범위 정합성

평균 단발 피해 5~15, HP 분포 40~150, 회피·방패 막기 빈도 10~30% → 라운드당 양측 합산 피해 15~40, 한쪽 HP 평균 80 → **3~6 라운드 평균**. 페이즈 1 #1 §라운드 권장 범위와 정합한다.

## 13. 현재 시스템과의 연관

| 시스템 | 영향 | 처리 방식 |
|--------|------|----------|
| `Mercenary.effectiveXxxWith(EquipmentStatBonus)` | 동결 시 호출 | 변경 없음 |
| `GameConstants.levelBonusPerLevel` (0.1) | effective 스탯에 이미 반영 | 변경 없음 |
| `GameConstants.tiredDebuffMultiplier` (0.8) | 동결 시 ×0.8 | 변경 없음 |
| `EquipmentStatBonus` | snapshot에 합산 후 동결 | 변경 없음 |
| `Mercenary.injure()` / `Mercenary.die()` | Phase 4 일괄 호출 | 변경 없음 |
| `QuestCalculator._statWeights` | M8b 무관 (일반 의뢰 fallback) | 변경 없음 |
| `RoleSynergyMatrix` | 의뢰 성공률용, M8b 무관 | 변경 없음 |
| 체인 주인공 사망률 50% 감소 | §10.6 산식으로 호환 | 변경 없음 |
| M8a 세력 패시브 사망 저항 hook | §10.4 | 페이즈 4 #3 명세 |

## 14. 결정성

페이즈 1 #1 §결정성과 페이즈 1 #2 §12 시드 활용을 그대로 사용한다. §5.1 피해 노이즈, §6~§10 모든 확률 롤은 분리된 PRNG 인스턴스를 사용한다.

```text
damageNoise = Random(seed ^ stableSeed32('dmg|$roundIndex|$pairId'))
hitRoll = Random(seed ^ stableSeed32('hit|$roundIndex|$pairId'))
critRoll = Random(seed ^ stableSeed32('crit|$roundIndex|$pairId'))
evasionRoll = Random(seed ^ stableSeed32('eva|$roundIndex|$pairId'))
shieldRoll = Random(seed ^ stableSeed32('shd|$roundIndex|$pairId'))
riposteRoll = Random(seed ^ stableSeed32('rip|$roundIndex|$pairId'))
deathResistRoll = Random(seed ^ stableSeed32('death|$mercId'))
```

`pairId = stableSeed32('$attackerId|$defenderId')`. 같은 시드 + 같은 라운드 + 같은 공격자/방어자 → 같은 롤 결과. Dart 런타임 `hashCode`는 사용하지 않는다.

## 15. 구현 우선순위 제안

| 우선순위 | 항목 | 이유 |
|----------|------|------|
| 높음 | HP 산식 + 직업군 매트릭스 | 모든 종료 조건 평가의 기반 |
| 높음 | 공격력 산식 + 직업군 산식 분기 | 직업군 정체성 (STR/INT 결합 비율) |
| 높음 | 방어값 산식 + 방패 막기 감소율 | 페이즈 1 #2 §8.3 hook 채우기 |
| 높음 | 피해 산식 단순 차감식 (`max(1, atk-def)`) | 보고서 가독성과 정합 |
| 높음 | 명중률 [50%, 95%] 클램프 | 극단 매치업 보호 |
| 높음 | 회피율 [0%, 75%] 클램프 | 무한 회피 방지 |
| 높음 | 사망 저항 [20%, 80%] + 체인 주인공 산식 | M3 체인 시스템 호환 |
| 중간 | 치명타 직업군 배수 매트릭스 | 직업군 차별성 |
| 중간 | 후방 공격 +10% 치명타 (Flank) | 진형 정책과 정합 |
| 중간 | 보고서 노출 정책 (확률 비노출, 결과 노출) | M8a 톤 계승 |
| 낮음 | 노이즈 정수 반올림 정책 | 시각적 자연스러움 |

## 16. data-generator 지시사항

이 산출물은 공식·구조 설계이며 벌크 데이터 생성을 직접 요구하지 않는다. 모든 매트릭스(직업군 HP/방어/공격/명중/회피/치명타/반격/사망 저항)는 **정적 상수로 코드에 내장**한다.

페이즈 3에서 별도로 필요한 데이터 중 이 산출물이 입력을 제공하는 항목:

| 페이즈 3 산출물 | 본 산식의 입력 기여 |
|-----------------|--------------------|
| 페이즈 3 #1 적 유형 | 적 측 HP/공격/방어 베이스를 본 산식 구조로 표현 |
| 페이즈 3 #3 상태 효과 | 페이즈 1 #4 hook 위치에 들어갈 곱셈/가산 배수 |
| 페이즈 3 #4 전투 로그 템플릿 | 11.2 라인 구성 예시의 어휘 풀 |

## 17. 다음 단계

페이즈 1 #4에서 상태 효과 MVP 타입을 설계한다. 본 산식의 모든 `statusEffectXxxMod` hook(공격력 §3.2, 방어력 §4, 명중 §6, 회피 §8, 치명타 §7, 반격 §9, 피해 §5)이 #4의 상태 효과 정의의 입력이 된다.

페이즈 2 #2 적 유형 능력치 설계에서 본 산식 구조로 적 측 HP/공격/방어/AGI 베이스 분포를 정한다.

페이즈 2 #4 전투 로그 길이·수치 노출 기준 확정에서 §11 노출 정책을 데이터 매트릭스화한다.
