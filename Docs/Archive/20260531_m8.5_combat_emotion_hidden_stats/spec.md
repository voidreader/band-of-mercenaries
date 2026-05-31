# 전투 시뮬레이터 감정 반응·히든 스탯·전투 기억 hook 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260521_m8.5_combat_emotional_reactions.md` (M8.5 페이즈 1 #3 — 감정 4종)
> - `Docs/content-design/[content]20260521_m8.5_hidden_stats.md` (M8.5 페이즈 1 #4 — 히든 스탯 5종)
> - `Docs/content-design/[content]20260521_m8.5_battle_memory.md` (M8.5 페이즈 1 #5 — 전투 기억)
> - `Docs/balance-design/[balance]20260521_m8.5_emotional_reaction_values.md` (M8.5 페이즈 2 #3 — 감정 수치)
> - `Docs/balance-design/[balance]20260522_m8.5_hidden_stat_values.md` (M8.5 페이즈 2 #4 — 히든 스탯 수치)
> 작성일: 2026-05-31
> 마일스톤: M8.5 페이즈 4 #3
> 페이즈 3 위임: 본 명세에 DB 시드 인라인 통합 — `combat_status_effects` ALTER+4행 / `combat_report_templates` ALTER+20행 / `hidden_stats` CREATE+5행 / `battle_memory_templates` CREATE+30행

## 1. 개요

M8b `CombatSimulator`의 결정적 전투 결과 위에 세 겹의 "재미 가시화" 레이어를 추가한다. (1) 위기 사건을 4 **감정 반응**(분노·절망·슬픔·투지)으로 번역하고, (2) 그 사건을 누적해 5 **히든 스탯**(불굴·투지·운·공포 저항·전장 감각)을 점진 해금하며, (3) 의미 있는 사건을 용병 개별 **전투 기억**으로 영구 보존한다. 본 명세는 데이터 모델·정적 데이터·시뮬레이터 hook·완료 trailing·히든 스탯 해금 다이얼로그까지를 다룬다. 용병 상세 화면의 `HiddenStatsSection`/`BattleMemorySection`/`ChronicleScreen` 통합 UI는 **페이즈 4 #4로 분리**한다.

핵심 설계 제약(기획 문서 정합):
- 신규 Hive typeId는 **1개**(`BattleMemoryEntry` = 31)만 도입한다. 감정 발동은 기존 `StatusEffectEvent`로 기록한다.
- `CombatStatusEffect` 모델 필드는 **추가하지 않는다**. emotional 4행은 기존 `hookTarget`/`applyMethod`/`kind` 스키마로 표현하고, 시뮬레이터의 effectId 전용 helper가 산식을 처리한다.
- 신규 `PassiveEffect` 타입을 **만들지 않는다**. 히든 스탯은 M8b hook 직접 가산 + 기존 `PassiveEffect`(recoveryTimeReduction/reputationGainModifier) + `QuestCompletionService` 전용 후처리(drop)의 3계층으로 적용한다.
- 모든 신규 trailing·hook은 **fail-soft**(try/catch)로 격리해 시뮬레이션·완료 무결성을 깨지 않는다.

## 2. 요구사항

### 2.1 기능 요구사항

#### A. 감정 반응 (4종)

- **[FR-1] `combat_status_effects` kind='emotional' 4행 도입**
  - kind CHECK에 `'emotional'` 추가(§2.2 SQL). 신규 컬럼 없음.
  - 4행: `emotional_rage`/`emotional_despair`/`emotional_sorrow`/`emotional_determination`. 전부 `stack_policy='ignore'`.
  - `combat_status_effects`는 이미 `StaticGameData.combatStatusEffects` 필드 + `staticDataProvider` 로더로 등록되어 있으므로 **모델/로더 변경 불요**. ALTER+INSERT만.

- **[FR-2] `EmotionalReactionConfig` 정적 상수**
  - 신규 파일 `band_of_mercenaries/lib/features/quest/domain/emotional_reaction_config.dart`.
  - 발동 확률(rage 0.60+0.20 / sorrow 0.50+0.30 / despair 0.80, 면제 / determination 1.00), 트리거 임계값(despairPartyHpThreshold 0.25, determinationCombatantHpThreshold 0.30), sorrowSkipChance 0.50, 투지 가산(deathResist +0.20, evasion +0.15), 분노 파생(atk +0.30, def -0.20), 절망 파생(hit -0.20, eva -0.15), 우선순위 리스트 `['determination','rage','sorrow','despair']`. (밸런스 §9.1 그대로)

- **[FR-3] `TraitEmotionalKeywords` 정적 상수**
  - 같은 파일 또는 인접. 실제 `traits.key` 기준 13키: rageBoost {vengeful, berserker_talent, madman, slayer} / sorrowBoost {guardian, empathic, team_player, mentor} / despairImmune {iron_will, unyielding, hardened, fearless, composed}. 정확 key 포함(contains) 판정. (밸런스 §7.1)
  - 매칭은 `_Combatant.traitIds`(전투원 런타임에 trait 접근 가능, 탐색 확인)로 수행.

- **[FR-4] `CombatSimulator` Phase 3 감정 trigger 4종 trailing**
  - `_runPhase3` 라운드 흐름(combat_simulator.dart Phase 3, 라인 319-412)에 trailing 삽입:
    - 행동 직전: `emotional_sorrow` 보유자 50% skip 평가 → `recordSkippedTurn`(기존 mez 패턴, actionKind 신규 `skipped_emotional_sorrow`)
    - 액션 후 `_resolveDeath` 반환 `true`(사망) → **분노** 광역 평가 / 반환 `false && injured` (중상 생존) → **슬픔** 인접 row 1명 평가
    - 액션 종료 후 파티 HP 합계 최초 <25% → **절망** 광역 평가(전투 단위 latch `despairTriggered`)
    - 액션 종료 후 trigger mercId HP 최초 <30% → **투지** 본인 평가(전투 단위 latch `determinationTriggeredMercIds`, eligible = flagship/solo(`pool.partySizeMax==1`)/chain protagonist)
  - 감정 trigger는 즉시 `_applyStatusEffect`를 호출하지 않고 `roundEmotionTriggers` 후보 목록에 누적한다. 정상 라운드는 `_tickStatusEffects` 이후, `CombatTurn` 추가 이전에 `flushEmotionTriggers`를 1회 실행해 §FR-5 우선순위를 적용한다. DoT로 조기 종료되는 라운드는 exit `CombatTurn` 추가 직전에 flush한다. 이렇게 적용된 emotional duration은 다음 라운드부터 감소한다.
  - DoT 사망/중상도 동일 후보 채널을 사용한다. `_applyDotRoundStart`/`_applyDotRoundEnd`는 `_resolveDeath` 결과를 버리지 말고 `DeathResolutionEvent(targetId, died, injured, sourceActionKind:'dot_tick')` 또는 동등 helper를 통해 감정·히든 스탯 후보 수집에 전달한다.
  - 감정 적용 = 기존 `_applyStatusEffect`로 emotional effectId 부여 + `statusEffectHistory`에 apply 이벤트(roundIndex 포함) 기록. 각 trigger 후보 수집과 flush는 try/catch fail-soft.

- **[FR-5] 우선순위·중복 방지**
  - 한 라운드 다중 트리거 시 `roundEmotionTriggers`를 우선순위 desc(`determination > rage > sorrow > despair`)로 평가한다. 같은 전투원은 이미 emotional 보유 시 skip(`stack_policy=ignore` + "1명 1감정")하며, 같은 라운드 후보 중 같은 mercId에는 가장 높은 우선순위 1개만 적용한다.
  - 같은 우선순위 내 정렬은 `(roundIndex ASC, priorityRank ASC, mercId ASC, sourceActionIndex ASC)`로 결정한다. `priorityRank`는 determination=0, rage=1, sorrow=2, despair=3이다. `sourceActionIndex`가 없으면 `0`으로 처리한다. 동일 seed·동일 입력에서 `statusEffectHistory`와 `battleMemoryEvents` 순서가 동일해야 한다. (밸런스 §8.2 알고리즘)

- **[FR-6] 감정 효과 산식 (effectId 전용 helper)**
  - `CombatStatusEffect.applyMethod`/`hookTarget`는 현재 산식에서 미사용(effectId별 하드코딩) — emotional 4종도 effectId 전용 분기로 처리:
    - 분노: 공격 `×(1+0.30)`, 방어 `×(1-0.20)` (기존 attack/defense 곱연산 지점에 emotional 합산)
    - 절망: 명중 `-0.20`, 회피 `-0.15` (signed additive, hit/evasion 산식에 직접 차감)
    - 슬픔: `apply_method='none'`, 행동 직전 50% skip
    - 투지: 사망 저항 `+0.20`(§FR-7), 회피 `+0.15`
  - 일반 buff/debuff와 공존(multiplicative 누적). emotional끼리만 1개.

- **[FR-7] 투지 사망 저항 cap 정합**
  - `_evaluateDeathResist`(combat_simulator.dart 라인 1505-1531)는 이미 `deathResistanceCaps` + `effectiveMax = max(perMercCap, baseCap)` 구현됨. 투지 +0.20은 **clamp 직전 합산**에 추가: `chance += determinationBonus` → 기존 `chance.clamp(0.0, effectiveMax)` 통과. cap 통과 후 별도 가산 금지. 솔로 cap 0.95와 겹쳐도 0.95 초과 불가. (밸런스 §3.5)

#### B. 히든 스탯 (5종)

- **[FR-8] `hidden_stats` 신규 정적 테이블 + 5행**
  - 신규 테이블(41번째). 5행: fortitude/grit/luck/fear_resistance/battle_sense. (§2.2 SQL, 밸런스 §6.1 그대로)
  - `HiddenStatData` freezed 모델 신규(10 필드: id/name/description/counterKey/levelThresholds/combatEffectsJson/passiveEffectsJson/postRewardEffectsJson/iconKey/narrativeHint).
  - `StaticGameData.hiddenStats: List<HiddenStatData>` 필드 + `staticDataProvider` 로더 + `SyncService.allTables`/`optionalTables` 등록.

- **[FR-9] `HiddenStatBonusResolver` 정적 helper**
  - 신규 파일 `band_of_mercenaries/lib/features/quest/domain/hidden_stat_bonus_resolver.dart`. (밸런스 §6.2 그대로)
  - `resolveHookBonus({hook, hiddenStats})` — death_resistance(fort×0.02)/despair_immune_chance(grit×0.08)/critical_rate(luck×0.01)/evasion(luck×0.01)/mez_immune_chance(fear×0.05)/strong_attack_evasion(fear×0.015)/action_score(battle×0.5)/featured_score(battle×0.2)/hit_chance(battle×0.01).
  - `collectPassiveBonuses(hiddenStats)` — fort>0이면 recoveryTimeReduction(status:'injured', value: fort×0.04), grit>0이면 reputationGainModifier(value: grit×0.015). 양수 저장.
  - `itemDropBonus(hiddenStats)` — (luck×0.005).clamp(0, 0.025).
  - `computeLevel(counter)` — thresholds [1,3,7,15,30] 누적.

- **[FR-10] `Mercenary.hiddenStats` HiveField 26 + 5 카운터 키**
  - `Mercenary` HiveField 26 `Map<String,int> hiddenStats`(default `{}`). 마지막 점유 25(recruitedAt) 확인됨.
  - `Mercenary.stats`(HiveField 14)에 5 신규 카운터 키 `{id}_event_count`. 모델 변경 없음(Map 값 추가).

- **[FR-11] `CombatSimulator` 히든 스탯 hook 가산**
  - Phase 1에서 `_Combatant`에 `hiddenStats` 로드(현재 _Combatant는 hiddenStats 미보유 → 필드 추가).
  - 각 hook 계산식(death_resistance/hit/evasion/critical/mez_immune/action_score/featured_score/strong_attack_evasion)에 `HiddenStatBonusResolver.resolveHookBonus` 가산 후 기존 clamp 통과. despair_immune은 절망 발동 확률 차감(`(0.80 - grit×0.08).clamp(0, 0.80)`, despairImmune 트레잇 보유 시 0).
  - 운 evasion + 공포 강공격 evasion + 투지 evasion 모두 evasion clamp [0,0.75] 동일 채널 합산.

- **[FR-12] 히든 스탯 카운터 증가 + lv 임계 평가**
  - **CombatSimulator 내부 사건** → `CombatSimulationResult.hiddenStatEvents`(HiveField 13, `Map<String,Map<String,int>>` = mercId→counterKey→delta) 결과 반환. 사건별 counterKey와 delta는 아래 표를 그대로 적용한다.
  - **QuestCompletionService trailing** → hiddenStatEvents 적용 + 솔로 완수/대성공·체인 주인공 위기 극복 카운터 추가 + lv 임계 평가(`computeLevel`) + lv 상승 시 `merc.hiddenStats[id] = newLv`. lv1 도달 → §FR-16 enqueue. fail-soft.

| 사건 | 발생 위치 | counterKey | delta | 중복 규칙 |
|------|----------|------------|-------|-----------|
| 사망 저항으로 생존(`_resolveDeath` died=false) | `CombatSimulator` | `fortitude_event_count` | +1 | 같은 전투에서 용병별 최대 3회 |
| `emotional_determination` apply | `CombatSimulator` flush | `fortitude_event_count` | +1 | apply 1회당 1회 |
| 솔로 의뢰 완수(`pool.partySizeMax == 1` && success/greatSuccess) | 완료 trailing | `fortitude_event_count` | +2 | 의뢰당 대상 용병 1회 |
| `emotional_despair` 면제(트레잇 또는 grit 확률 차단) | `CombatSimulator` | `grit_event_count` | +1 | 용병별 전투당 1회 |
| 솔로 의뢰 대성공 | 완료 trailing | `grit_event_count` | +3 | 의뢰당 대상 용병 1회, 솔로 완수 +2와 별도 |
| 체인 주인공 위기 극복(HP<30% 기록 후 전투 종료 생존) | 완료 trailing | `grit_event_count` | +2 | 체인 주인공 1회 |
| 치명타 발동 | `CombatSimulator` | `luck_event_count` | +1 | 발동마다 |
| 회피 성공 | `CombatSimulator` | `luck_event_count` | +1 | 회피마다 |
| 보상 아이템 드랍 획득 | 완료 trailing | `luck_event_count` | +1 | 용병별 의뢰당 1회 |
| 결정적 장면 기여 점수 >= 5 | `_runPhase4` 직전 | `luck_event_count` | +1 | 용병별 전투당 1회 |
| mez 면제 | `CombatSimulator` | `fear_resistance_event_count` | +1 | 면제마다 |
| 유니크 엘리트 전투 생존 | 완료 trailing | `fear_resistance_event_count` | +1 | 파견 생존자별 1회 |
| 적 단발 피해 >= maxHp*0.30 회피·방패 막기 | `CombatSimulator` | `fear_resistance_event_count` | +1 | 용병별 전투당 최대 3회 |
| 치명타 처치 | `CombatSimulator` | `battle_sense_event_count` | +1 | 처치마다 |
| 결정적 장면 기여 점수 >= 5 | `_runPhase4` 직전 | `battle_sense_event_count` | +1 | 용병별 전투당 1회 |
| 결정적 장면 기여 점수 >= 10 | `_runPhase4` 직전 | `battle_sense_event_count` | +1 추가 | >=5 보상과 합산해 총 +2 |
| 명중 성공(계산된 hitChance <= 0.50) | `CombatSimulator` | `battle_sense_event_count` | +1 | 용병별 전투당 최대 5회 |

  - `hiddenStatEvents`는 같은 mercId/counterKey에 delta를 합산한 Map으로 반환한다. 순서가 필요한 기억 이벤트와 달리 카운터 Map은 순서를 의미하지 않는다.

#### C. 전투 기억

- **[FR-13] `BattleMemoryEntry` 신규 Hive 모델 (typeId 31)**
  - 6 필드(mercId/entryType/sourceEventId/timestamp/templateKey?/templateData). 현재 최대 typeId 30 확인됨.
  - `Mercenary.battleMemories: List<BattleMemoryEntry>` HiveField 27(default `[]`) + 30 cap FIFO helper.

- **[FR-14] `battle_memory_templates` 신규 정적 테이블 + 30행**
  - 신규 테이블(42번째). 30행 분포(emotional_apply 12 + hidden_stat_unlock 10 + solo_great_success 3 + unique_elite_first_kill 5). (§2.2 SQL)
  - `BattleMemoryTemplate` freezed 모델(5 필드: id/entryType/sourceEventMatch?/template/weight) + `StaticGameData.battleMemoryTemplates` + 로더 + SyncService 등록(optionalTables 포함).

- **[FR-15] 전투 기억 6 entryType 기록 trailing**
  - `emotional_apply`: CombatSimulator emotional trigger 직후 `CombatSimulationResult.battleMemoryEvents`(HiveField 14, `List<BattleMemoryEntry>`) 후보 추가(순수 시뮬레이터는 Mercenary 직접 변경 금지) → QuestCompletionService trailing이 영속 반영.
  - `hidden_stat_unlock`: lv1·lv5 도달 시(§FR-12) `sourceEventId='hidden_{statId}_{lv}'`.
  - `solo_great_success`: `pool.partySizeMax==1 && greatSuccess` → `sourceEventId='quest:{poolId}'`.
  - `unique_elite_first_kill`: 유니크 엘리트 첫 처치 시 파견 전원 → `sourceEventId='elite:{eliteId}'`.
  - `achievement_granted`: `AchievementService.grant` mercSnapshot 주인공일 때 본인 본체 lookup 후 추가(`sourceEventId='achievement:{templateId}'`, lookup 실패 시 skip).
  - `title_granted`: `TitleService._grantTitle` 직후(`sourceEventId='title:{titleId}'`).
  - 모든 trailing fail-soft. `MercenarySnapshot.fromMercenary`가 hiddenStats/battleMemories 자동 동결(별도 코드 불요).

#### D. 다이얼로그 (사용자 결정: #3 포함)

- **[FR-16] 히든 스탯 lv1 해금 다이얼로그**
  - `hiddenStatUnlockedProvider: StateProvider<HiddenStatUnlockEvent?>` 신규(이벤트 채널 패턴 — publish 직후 enqueue + state=null 즉시 리셋).
  - `HiddenStatUnlockedDialog` 위젯 신규(medium priority). `DialogTypeRegistry`에 `hiddenStatUnlocked` 등록.
  - lv1 해금 시에만 enqueue. lv2~lv5 승급은 `ActivityLogType.hiddenStatLevelUp` 1줄.

#### E. 노출 (보고서)

- **[FR-17] `CombatReportService` scope='emotional' 분기**
  - `combat_report_templates` scope CHECK에 `'emotional'` 추가 + 20행 INSERT. `combat_report_templates`는 이미 등록된 테이블 → ALTER+INSERT만, 모델 변경 불요.
  - `CombatReportService.generate`(combat_report_service.dart)가 `simulationResult.statusEffectHistory`에서 `effectId.startsWith('emotional_') && eventType=='apply'` 추출 → scope='emotional' 풀 매칭 → 보고서 하단 "감정 장면" 섹션(전투당 최대 3줄, 우선순위 투지>분노>슬픔>절망). 빈 풀이면 fail-soft skip. 별도 dialog 없음(`QuestResultDialog` 인라인).

#### F. PassiveBonus / 활동 로그

- **[FR-18] `PassiveBonusService.collect` hiddenStatEffects 인자**
  - `collect(...)`에 `List<PassiveEffect> hiddenStatEffects = const []` 추가(passive_bonus_service.dart 라인 29 다음) + `buffer.addAll(hiddenStatEffects)`(라인 53 다음). 기존 호출부는 default로 호환. `QuestCompletionService`/회복 계산 호출부에서 `HiddenStatBonusResolver.collectPassiveBonuses` 주입.
  - `fortitude`의 `recoveryTimeReduction(status:'injured')`는 **해당 용병 개인 효과**다. 부상 종료 시각 계산 시 damage 대상 mercenary의 `hiddenStats`만 `collectPassiveBonuses`로 변환해 기존 `PassiveBonusService.getRecoveryTimeMultiplier`에 합산한다.
  - `grit`의 `reputationGainModifier`는 **파티 최고 grit lv 1명만 적용**한다. 파티 전체 합산을 금지하며, 동률이면 `mercId` 오름차순 1명을 선택한다. 기존 세력·랭크·장비·칭호 명성 보너스와 같은 `getReputationGainModifier` 상한(+0.30)을 공유한다.

- **[FR-19] 운 item_drop 후처리 + `ActivityLogType` 2종**
  - 운 드랍 보너스는 `QuestCompletionService` 보상 트랜잭션에서 참가자 중 `luck` 최고 lv 1명만 `itemDropBonus` 적용(합산 금지).
  - `ActivityLogType.hiddenStatUnlocked` = **HiveField 41**, `hiddenStatLevelUp` = **HiveField 42**. (정정: 기획서 40/41은 stale — 40은 `soloQuestInjuredReturn`이 점유 중)

### 2.2 데이터 요구사항

#### 신규/수정 Hive 모델

| 모델 | typeId | 변경 | HiveField |
|------|--------|------|-----------|
| `BattleMemoryEntry` | **31** (신규) | 신규 모델 | 0 mercId / 1 entryType / 2 sourceEventId / 3 timestamp / 4 templateKey? / 5 templateData |
| `Mercenary` | 1 | 필드 2개 추가 | 26 `hiddenStats: Map<String,int>` / 27 `battleMemories: List<BattleMemoryEntry>` |
| `MercenarySnapshot` | 18 | 필드 2개 추가 | 6 `hiddenStats: Map<String,int>` / 7 `battleMemories: List<BattleMemoryEntry>` |
| `CombatSimulationResult` | 22 | 필드 2개 추가 | 13 `hiddenStatEvents: Map<String,Map<String,int>>` / 14 `battleMemoryEvents: List<BattleMemoryEntry>` (15는 #6 주간 기여도 예약) |
| `ActivityLogType` (enum) | 6 | 값 2개 추가 | 41 `hiddenStatUnlocked` / 42 `hiddenStatLevelUp` |

> 검증된 점유 현황: Mercenary 마지막 25, MercenarySnapshot 마지막 5, CombatSimulationResult 마지막 12, ActivityLogType 마지막 40, 최대 typeId 30. 모두 가용.

기존 Hive 세이브 호환을 위해 신규 필드는 반드시 nullable constructor 인자로 받은 뒤 기본값으로 보정한다.

- `Mercenary.hiddenStats`: constructor 인자 `Map<String,int>? hiddenStats` → `Map<String,int>.from(hiddenStats ?? const {})`.
- `Mercenary.battleMemories`: constructor 인자 `List<BattleMemoryEntry>? battleMemories` → `List<BattleMemoryEntry>.from(battleMemories ?? const [])`.
- `MercenarySnapshot.hiddenStats`: `Map<String,int>.from(hiddenStats ?? mercenary.hiddenStats)`로 동결한다.
- `MercenarySnapshot.battleMemories`: `List<BattleMemoryEntry>.from(battleMemories ?? mercenary.battleMemories)`로 동결한다.
- `CombatSimulationResult.hiddenStatEvents`: constructor 인자 nullable 허용 후 `{}` fallback.
- `CombatSimulationResult.battleMemoryEvents`: constructor 인자 nullable 허용 후 `[]` fallback.

`BattleMemoryEntry.entryType`은 6종(`emotional_apply`/`hidden_stat_unlock`/`achievement_granted`/`title_granted`/`solo_great_success`/`unique_elite_first_kill`)을 허용한다. `battle_memory_templates.entry_type` CHECK는 템플릿 기반 렌더가 필요한 4종만 허용하며, `achievement_granted`와 `title_granted`는 원본 위업·칭호 데이터 lookup으로 렌더한다.

#### 신규 정적 데이터 모델 (freezed, Hive 아님)

| 모델 | 필드 |
|------|------|
| `HiddenStatData` | id / name / description / counter_key / level_thresholds(JSONB) / combat_effects_json / passive_effects_json? / post_reward_effects_json? / icon_key / narrative_hint? |
| `BattleMemoryTemplate` | id / entry_type / source_event_match? / template / weight |

#### Supabase SQL (페이즈 3 위임 인라인)

```sql
-- (1) combat_status_effects: kind CHECK 확장 + 4행 (밸런스 §9 그대로)
ALTER TABLE combat_status_effects DROP CONSTRAINT IF EXISTS combat_status_effects_kind_check;
ALTER TABLE combat_status_effects ADD CONSTRAINT combat_status_effects_kind_check
  CHECK (kind IN ('buff','debuff','mez','dot','emotional'));
INSERT INTO combat_status_effects (id, kind, display_label, hook_target, stack_policy, apply_method, default_intensity, default_duration_turns, description) VALUES
('emotional_rage','emotional','분노','["attack","defense"]'::jsonb,'ignore','multiplicative',0.30,3,'동료의 죽음을 본 용병이 천둥같은 분노로 적을 헤집는다 (공격 +30%, 방어 -20%)'),
('emotional_despair','emotional','절망','["hit","evasion"]'::jsonb,'ignore','additive',-0.20,3,'전멸 직전의 무력감이 손을 떨리게 한다 (명중 -20%, 회피 -15%)'),
('emotional_sorrow','emotional','슬픔','["action_skip"]'::jsonb,'ignore','none',0.50,2,'동료의 비명에 잠시 손을 멈춘다 (50% 확률 행동 스킵)'),
('emotional_determination','emotional','투지','["death_resistance","evasion"]'::jsonb,'ignore','additive',0.20,4,'바닥을 짚고 일어서는 영웅적 결심 (사망 저항 +20%, 회피 +15%)');

-- (2) combat_report_templates: scope CHECK 확장 + 20행 (scope='emotional', 4 감정 × 5 변형, weight 1)
ALTER TABLE combat_report_templates DROP CONSTRAINT IF EXISTS combat_report_templates_scope_check;
ALTER TABLE combat_report_templates ADD CONSTRAINT combat_report_templates_scope_check
  CHECK (scope IN ('chain_final','chain_step','settlement_event','unique_elite','elite','faction_named','quest_type','scene','combat_skill','emotional'));
-- INSERT 20행: tags_json.emotion_id 로 감정 매칭. 한국어 톤(분노=폭주/절망=무력/슬픔=위축/투지=영웅적), {merc.name}/{ally.name}/{enemy.name} 변수. 변형별 1~2문장.

-- (3) hidden_stats: 신규 테이블 + 5행 (밸런스 §6.1 그대로)
CREATE TABLE hidden_stats (
  id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT NOT NULL,
  counter_key TEXT NOT NULL, level_thresholds JSONB NOT NULL,
  combat_effects_json JSONB NOT NULL, passive_effects_json JSONB, post_reward_effects_json JSONB,
  icon_key TEXT NOT NULL DEFAULT 'default', narrative_hint TEXT);
-- INSERT 5행: fortitude/grit/luck/fear_resistance/battle_sense, level_thresholds 전부 [1,3,7,15,30],
--   combat/passive/post_reward effects_json 은 밸런스 §6.1 그대로. passive는 fort/grit만, post_reward는 luck만.

-- (4) battle_memory_templates: 신규 테이블 + 30행
CREATE TABLE battle_memory_templates (
  id TEXT PRIMARY KEY, entry_type TEXT NOT NULL, source_event_match TEXT,
  template TEXT NOT NULL, weight INT NOT NULL DEFAULT 1,
  CONSTRAINT battle_memory_templates_entry_type_check
    CHECK (entry_type IN ('emotional_apply','hidden_stat_unlock','solo_great_success','unique_elite_first_kill')));
-- INSERT 30행: emotional_apply 12(rage/despair/sorrow/determination 각 3) + hidden_stat_unlock 10(hidden_*_1 5 + hidden_*_5 5) + solo_great_success 3 + unique_elite_first_kill 5.
--   achievement_granted/title_granted 는 lookup 렌더이므로 템플릿 미포함.
```

> `combat_status_effects`/`combat_report_templates`는 기존 등록 테이블이라 ALTER+INSERT만 필요(모델/로더/SyncService 변경 불요). `hidden_stats`/`battle_memory_templates`만 신규 등록.

### 2.3 UI 요구사항

신규 화면 없음. 신규 위젯은 `HiddenStatUnlockedDialog` 1종(다이얼로그)만 본 명세 범위.

- **화면 진입 조건**: lv1 히든 스탯 해금 시 `hiddenStatUnlockedProvider` publish → `dialogQueueProvider.enqueue`(medium) → `app.dart` 단일 ref.listen 표시.
- **위젯 계층**: `AlertDialog`(또는 기존 `*UnlockedDialog` 패턴 정합) — 아이콘 + "{merc.name}에게서 새로운 잠재력 발견" + 스탯명 lv1 + description + 효과 2~3줄 + [확인].
- **화면 전환**: 상태 기반(다이얼로그 큐). `Navigator.push` 금지(CLAUDE.md). `barrierDismissible` true(critical 아님).
- **연출**: 기존 `AchievementUnlockedDialog`/`TitleUnlockedDialog` 톤 정합. `AppTheme.hiddenStatAccent`(보라계) 신규 색상 — 정의는 본 명세, 본격 적용은 페이즈 4 #4.
- **분리**: 용병 상세 `HiddenStatsSection`/`BattleMemorySection`, `ChronicleScreen` memorial 펼침은 **페이즈 4 #4**.

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `lib/features/mercenary/domain/mercenary_model.dart` | HiveField 26 hiddenStats / 27 battleMemories 추가 | FR-10, FR-13 |
| `lib/features/achievement/domain/mercenary_snapshot_model.dart` | HiveField 6 hiddenStats / 7 battleMemories + fromMercenary 동결 | FR-15 |
| `lib/features/quest/domain/combat_simulation_result.dart` | HiveField 13 hiddenStatEvents / 14 battleMemoryEvents | FR-12, FR-15 |
| `lib/core/domain/activity_log_model.dart` | HiveField 41 hiddenStatUnlocked / 42 hiddenStatLevelUp | FR-19 |
| `lib/features/quest/domain/combat_simulator.dart` | _Combatant hiddenStats 필드 / hook 가산(FR-11) / Phase 3 emotional trigger 4종(FR-4~6) / 투지 death_resist 합산(FR-7) / hiddenStatEvents·battleMemoryEvents 결과(FR-12·15) / 슬픔 skip 분기 | 감정·히든 스탯 시뮬레이터 통합 |
| `lib/features/quest/domain/combat_simulator_constants.dart` | seedKey 추가(필요 시 sorrow/emotional 도메인), decisive/action 상수 정합 | PRNG 도메인 분리 |
| `lib/features/quest/domain/quest_provider.dart` (`_applyCompletionResult`) | hiddenStatEvents 적용+lv 평가(라인 1207-1329 인근) / battleMemoryEvents 적용(combatReport 저장 라인 937 인근) / 6 entryType trailing / 솔로·체인 카운터 / lv1 enqueue / 운 drop 후처리(라인 1428-1508 인근) | FR-12·15·16·19 |
| `lib/features/quest/domain/quest_completion_service.dart` | PassiveBonus hiddenStatEffects 주입 / 운 drop 후처리 경로 | FR-18·19 |
| `lib/features/quest/domain/combat_report_service.dart` | scope='emotional' 추출 + 감정 장면 섹션 | FR-17 |
| `lib/core/domain/passive_bonus_service.dart` | collect()에 hiddenStatEffects 인자(라인 29·53) | FR-18 |
| `lib/features/achievement/domain/achievement_service.dart` | grant() mercSnapshot 주인공 battleMemory trailing(라인 93-102 인근) | FR-15 |
| `lib/features/title/domain/title_service.dart` | _grantTitle() battleMemory trailing(라인 288-295) | FR-15 |
| `lib/core/data/sync_service.dart` | allTables + optionalTables에 hidden_stats / battle_memory_templates 등록(라인 59·76 인근) | FR-8·14 |
| `lib/core/providers/static_data_provider.dart` | StaticGameData hiddenStats / battleMemoryTemplates 필드·생성자·로더(라인 88·130·282 인근) | FR-8·14 |
| `lib/core/theme/...` (AppTheme) | hiddenStatAccent 색상 추가 | FR-16 |
| `lib/core/providers/dialog_queue_provider.dart` 또는 DialogTypeRegistry 위치 | hiddenStatUnlocked 타입 등록 | FR-16 |
| `lib/app.dart` | (기존 ref.listen 패턴 정합 — 신규 provider 연결 필요 시) | FR-16 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `lib/features/quest/domain/emotional_reaction_config.dart` | EmotionalReactionConfig + TraitEmotionalKeywords (FR-2·3) |
| `lib/features/quest/domain/hidden_stat_bonus_resolver.dart` | HiddenStatBonusResolver (FR-9) |
| `lib/features/mercenary/domain/battle_memory_entry.dart` | BattleMemoryEntry Hive 모델 typeId 31 (FR-13) |
| `lib/core/models/hidden_stat_data.dart` | HiddenStatData freezed 정적 모델 (FR-8) |
| `lib/core/models/battle_memory_template.dart` | BattleMemoryTemplate freezed 정적 모델 (FR-14) |
| `lib/features/mercenary/domain/hidden_stat_unlocked_provider.dart` (또는 인접) | hiddenStatUnlockedProvider + HiddenStatUnlockEvent (FR-16) |
| `lib/features/mercenary/view/hidden_stat_unlocked_dialog.dart` | HiddenStatUnlockedDialog 위젯 (FR-16) |

### 3.3 코드 생성 필요 파일 (build_runner)

| 파일 | 이유 |
|------|------|
| `mercenary_model.g.dart` | Mercenary HiveField 추가 |
| `mercenary_snapshot_model.g.dart` | MercenarySnapshot HiveField 추가 |
| `combat_simulation_result.g.dart` | CombatSimulationResult HiveField 추가 |
| `activity_log_model.g.dart` | ActivityLogType 값 추가 |
| `battle_memory_entry.g.dart` | 신규 Hive 모델 + Adapter 등록(HiveInitializer) |
| `hidden_stat_data.freezed.dart` / `.g.dart` | 신규 freezed+json |
| `battle_memory_template.freezed.dart` / `.g.dart` | 신규 freezed+json |

> `HiveInitializer`에 `BattleMemoryEntryAdapter`(typeId 31) 등록 필요.

### 3.4 관련 시스템

- **턴 전투 시뮬레이터**: emotional trigger·히든 스탯 hook 가산. 결정성 유지(latch + 우선순위 desc + mercId 정렬, 신규 PRNG 도메인 키).
- **의뢰 완료(QuestCompletionService/quest_provider)**: 카운터·lv·battleMemory·drop trailing(모두 fail-soft).
- **전투 보고서**: scope='emotional' 감정 장면.
- **위업·칭호**: grant/_grantTitle battleMemory trailing.
- **정적 데이터 동기화**: 신규 테이블 2개(optionalTables).
- **다이얼로그 큐**: hiddenStatUnlocked(medium).
- **PassiveBonus**: hiddenStatEffects 채널.

### 3.5 검증 요구사항

구현자는 아래 테스트를 추가하거나 기존 테스트에 케이스를 보강한다. 각 항목은 PASS/FAIL 판정 가능한 형태여야 한다.

| 테스트 파일 | 필수 검증 |
|-------------|-----------|
| `test/features/quest/domain/combat_simulator_determinism_test.dart` | 동일 seed·동일 입력에서 emotional `statusEffectHistory`, `hiddenStatEvents`, `battleMemoryEvents`가 동일하다. |
| `test/features/quest/domain/combat_simulator_test.dart` | 분노/슬픔/절망/투지 trigger가 조건별로 후보 수집 후 priority flush를 거쳐 1명 1감정만 적용된다. |
| `test/features/quest/domain/combat_simulator_death_resistance_test.dart` | 투지 +0.20과 불굴 lv 보너스가 clamp 이전에 더해지고 솔로 cap 0.95를 초과하지 않는다. |
| `test/features/quest/domain/combat_simulator_test.dart` | DoT 사망·중상도 `_resolveDeath` 결과를 통해 감정 후보와 `fortitude_event_count`를 생성한다. |
| `test/features/quest/domain/combat_report_service_test.dart` | `scope='emotional'` 템플릿이 있으면 감정 장면 최대 3줄이 우선순위 순으로 추가되고, 템플릿이 없으면 보고서 생성이 실패하지 않는다. |
| `test/features/quest/domain/quest_completion_service_test.dart` | `hiddenStatEvents` 적용 후 thresholds [1,3,7,15,30]에 따라 lv가 상승하고 lv1만 `hiddenStatUnlocked` enqueue 대상이 된다. |
| `test/features/quest/domain/quest_completion_service_test.dart` | `luck` item_drop 보너스와 `grit` 명성 보너스는 파티 최고 lv 1명만 적용된다. |
| `test/core/domain/passive_bonus_service_test.dart` | `hiddenStatEffects`가 기존 세력·랭크·장비·칭호 효과와 같은 상한을 공유한다. |
| `test/features/mercenary/domain/mercenary_model_test.dart` | 기존 Hive 필드가 없는 Mercenary/CombatSimulationResult 데이터를 읽어도 신규 Map/List 필드가 빈 값으로 초기화된다. |
| `test/features/mercenary/domain/mercenary_model_test.dart` | `battleMemories`가 31개 이상이면 가장 오래된 항목부터 제거되어 30개만 남는다. |
| `test/features/quest/domain/quest_completion_side_effects_test.dart` | `achievement_granted`/`title_granted` memory trailing은 본체 mercenary lookup 실패 시 skip되고 본 흐름을 실패시키지 않는다. |

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- 사망 저항 cap: `combat_simulator.dart:1505-1531` `_evaluateDeathResist`(effectiveMax 패턴) — 투지 가산 지점.
- 상태 효과 적용/기록: `_applyStatusEffect`(라인 1651-1663), `_tickStatusEffects`(1687-1696), `StatusEffectEvent`(roundIndex 포함).
- mez skip: `actionKind:'skipped_stunned'`(라인 527) — 슬픔 `skipped_emotional_sorrow` 동형.
- 행동 기여 점수: `_accumulateDecisive`(2251-2259), protagonist 선정(`_runPhase4` 447-473).
- 완료 trailing fail-soft: `quest_provider.dart` 솔로 trailing(1331-1527), 유니크 엘리트 hook(990-1039), region trailing(1041-1072) — 동형 try/catch.
- 카운터 업데이트: `MercenaryStatService.updateStatsAfterQuest` + `mercRepo.updateStats`(quest_provider 1237·1323·1361).
- PassiveEffect 컨테이너 파싱: `PassiveEffect.parseEffects({"effects":[...]})`(passive_effect.dart 190-197).
- 정적 테이블 등록: M8b `combat_skills`/`enemies` 패턴(static_data_provider 262-281, sync_service optionalTables 66-76).
- 이벤트 채널 다이얼로그: `AchievementUnlockedDialog`/`TitleUnlockedDialog` + provider publish 직후 enqueue + state=null(CLAUDE.md "이벤트 채널 패턴").

### 4.2 주의사항

- `CombatSimulator`는 **순수 도메인**: `Mercenary`/Hive 직접 변경 금지. 히든 스탯 카운터·전투 기억은 결과(hiddenStatEvents/battleMemoryEvents)로 반환하고 `quest_provider` trailing이 영속 반영.
- 결정성: emotional 평가에 `Math.random()`/`hashCode` 금지. `stableSeed32` + 신규 도메인 키. latch(`despairTriggered`/`determinationTriggeredMercIds`)로 전투 단위 중복 차단.
- `default_intensity=-0.20`(절망) signed 허용 — 데이터 검증에 `>=0` 제약 추가 금지.
- 30 cap FIFO: `battleMemories.length > 30` 시 `removeAt(0)`.
- 운 drop·item_drop은 PassiveEffect 신규 타입 만들지 말고 QuestCompletion 후처리. 파티 최고 lv 1명만.
- `ActivityLogType` 번호는 **41/42**(기획서 40/41은 stale). verify 시 이 정정 반영 확인.

### 4.3 엣지 케이스

- emotional 트리거 시 생존 파티 0명/대상 후보 없음 → 미발동.
- DoT 사망/중상도 동일 채널(`_resolveDeath` 반환 분기) 통과.
- 히든 스탯 lv5 도달 후 카운터 계속 누적(영구), lv는 max 5 고정.
- 동일 사건이 emotional 기록(시각화)과 hiddenStat 카운터(영속) 둘 다 기록(다른 채널).
- battleMemory lookup(위업/칭호) 실패 → 렌더 skip(#4 UI), 기록 자체는 sourceEventId만 보존.
- 죽은 mercenary는 본체 없음 → achievement_granted trailing은 본체 lookup 실패 시 skip.
- `hidden_stats`/`battle_memory_templates` 캐시 빈 경우(배포 전) → 효과·기록·다이얼로그 fail-soft skip(optionalTables).

### 4.4 구현 힌트

- 진입점: `gameTickProvider` → `quest_provider._checkCompletions`(739-752) → `_completeQuest`(754-884) → `QuestCompletionService.calculate`(180-197 simulate) → `_applyCompletionResult`(886-1856 trailing).
- 데이터 흐름(감정·기억): `CombatSimulator.simulate` → `CombatSimulationResult.{statusEffectHistory, hiddenStatEvents, battleMemoryEvents}` → `_applyCompletionResult` trailing → `Mercenary.{hiddenStats, stats, battleMemories}` 영속 + `hiddenStatUnlockedProvider` enqueue → `CombatReportService.generate` scope='emotional'.
- 데이터 흐름(효과): `Mercenary.hiddenStats` → `_Combatant.hiddenStats`(Phase 1) → `HiddenStatBonusResolver.resolveHookBonus`(hook 계산) / `collectPassiveBonuses`(PassiveBonusService).
- 확장 지점: 시뮬레이터 hook 가산은 기존 hit/evasion/crit/death_resist 산식의 "+statusMod" 직후. emotional trigger는 Phase 3 라운드 행동 루프 trailing. 완료 trailing은 `_applyCompletionResult` 솔로 trailing(1527) 인근 + combatReport 저장(937) 인근.

## 5. 기획 확인 사항

- [Q-1] (다이얼로그 경계) → **결정**: provider+enqueue+`HiddenStatUnlockedDialog`+`DialogTypeRegistry`까지 #3 포함. 용병 상세 `HiddenStatsSection`/`BattleMemorySection`/`ChronicleScreen`은 #4. (사용자 2026-05-31 결정)
- [Q-2] (`ActivityLogType` 번호) → **정정**: hiddenStatUnlocked=41, hiddenStatLevelUp=42. 기획서 40/41은 M8.5 #2 `soloQuestInjuredReturn`(40) 추가 이전 작성분이라 stale. 코드 실측 반영.
- [Q-3] (`CombatSimulationResult` HiveField 13) → **확인**: CLAUDE.md "다음 13"과 실측(마지막 12) 일치. hiddenStatEvents=13, battleMemoryEvents=14, 15는 #6 weeklyContributionDelta 예약 유지.
- [Q-4] (combat_report_templates scope CHECK 기존 목록) → 본 명세는 탐색 기준 9 scope에 'emotional' 추가로 기재. 구현 시 실제 DB 현재 CHECK 목록을 SELECT로 재확인 후 ALTER(누락 scope 없이 전체 재선언). data-generator/SQL 적용 단계에서 검증.
- [Q-5] (emotional 보고서 템플릿 매칭 키) → `combat_report_templates`에 emotion 매칭 컬럼이 `tags_json.emotion_id`인지 기존 스키마 확인 필요. 기존 M8a 컬럼 구조(`tags_json`/별도 컬럼)에 맞춰 SQL 조정. 구현 시 실 테이블 스키마 확인.
