# M2a 장비 효과 적용 구현 계획 및 산출물 리포트

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260419_m2a-item-equipment-effects.md`
> 작성일: 2026-04-19
> 검증 모드: 풀 검증 (verifier 서브에이전트, 재호출 1회 포함)
> 최종 판정: **PASS**

---

## 1. 구현 계획 요약

planner가 16 TASK, 6단계 실행 순서로 분해. main이 코더 병렬 호출로 집행하고 verifier가 최종 검증.

### 실행 단계

| 단계 | 구성 태스크 (의존) | 주요 산출 |
|:---:|---|---|
| 1 (병렬) | T1, T2, T7, T11 | freezed 값 객체 3종 · PassiveEffect 2 variant · ReputationService · UserDataNotifier |
| 2 (병렬) | T3(T1), T5(T2), T6(T2) | Mercenary HiveField 18 · PassiveBonusService · PassiveBonusFormatter (core/info 2종) |
| 3 (병렬) | T4(T1), T8(T1,T3) | ItemEffectService + 테스트 · QuestCalculator 시그니처 |
| 4 (병렬) | T9(T4), T10(T4,5,7,8), T14(T4,T11) | EquipmentEffectContext · QuestCompletionService 통합 + quest_provider · GuildEquipmentScreen |
| 5 (병렬) | T12+T13(T4,T9), T15(T14), T16(T8,T9) | EquipmentSlotGrid + overlay 삽입 · info_screen 진입점 · DispatchDetailPage |

TASK-13(overlay 섹션 삽입)은 TASK-12 코더가 함께 처리하여 별도 6단계 실행 없이 흡수.

### 사용자 확인 항목

명세서 §5 Q-1 ~ Q-7은 이미 결정됨. 계획 수립 중 추가로 **gameTickProvider/quest_provider 수정 필요성**을 식별하여 사용자에게 확인, **A안(범위 포함)** 승인 받고 진행.

---

## 2. 변경 파일 목록

### 신규 생성 (11개, 테스트 포함)

| 경로 | 역할 |
|---|---|
| `lib/features/inventory/domain/equipment_stat_bonus.dart` | `EquipmentStatBonus` freezed + `+` 연산자 extension |
| `lib/features/inventory/domain/legendary_effect.dart` | `LegendaryEffect` sealed 5 variant + `fromJson` |
| `lib/features/inventory/domain/personal_equipment_effect.dart` | `PersonalEquipmentEffect` freezed (statBonus + legendary) |
| `lib/features/inventory/domain/item_effect_service.dart` | effect_json 파싱 + 수집 서비스 (정적 메서드 5) |
| `lib/features/inventory/domain/equipment_effect_context.dart` | Ref / WidgetRef 기반 장비 수집 헬퍼 (비동기 4 + 동기 2) |
| `lib/features/mercenary/view/equipment_slot_grid.dart` | 용병 개인 장비 6슬롯 그리드 + `equipmentRefreshProvider` |
| `lib/features/mercenary/view/equipment_equip_sheet.dart` | 개인 장비 장착 시트 |
| `lib/features/info/view/guild_equipment_screen.dart` | 용병단 장비 3슬롯 화면 |
| `lib/features/info/view/guild_equipment_equip_sheet.dart` | 용병단 장비 장착 시트 |
| `test/features/inventory/domain/item_effect_service_test.dart` | ItemEffectService 37 테스트 |
| `test/core/domain/passive_bonus_service_equipment_test.dart` | 장비 소스 통합 + 신규 2 메서드 8 테스트 |
| `test/features/quest/domain/quest_completion_legendary_test.dart` | 전설 ①②③⑤ 결정론 + 공유 clamp 9 테스트 |

### 수정 (14개)

| 경로 | 주요 변경 |
|---|---|
| `lib/core/models/passive_effect.dart` | `InjuryRateModifierEffect` · `ReputationGainModifierEffect` variant 2종 + fromJson case |
| `lib/core/domain/passive_bonus_service.dart` | `collect()` 시그니처 확장 + `getInjuryRateMultiplier` + `getReputationGainModifier` |
| `lib/core/domain/passive_bonus_formatter.dart` | `format` switch에 2 variant case |
| `lib/features/info/domain/passive_bonus_formatter.dart` | `describeEffect` switch에 2 variant case + `_pctSigned` 헬퍼 |
| `lib/core/domain/reputation_service.dart` | `calculateQuestReputation({reputationGainModifier})` |
| `lib/features/mercenary/domain/mercenary_model.dart` | `@HiveField(18) DateTime? legendaryDeathPreventionCooldownUntil` + `effectiveStrWith` 계열 4 메서드 |
| `lib/features/quest/domain/quest_calculator.dart` | `calculatePartyPower({equipmentBonuses})` + `calculateDamage({legendaryEffects})` + 3 successRate 메서드에 `legendarySuccessBonus` 파라미터 (ISSUE-1 수정) |
| `lib/features/quest/domain/quest_completion_service.dart` | `calculate` 시그니처 확장 + MercDamageResult 2 필드 + 전설 ①②⑤ 분기 + 부상률 곱셈 + 명성 수정자 |
| `lib/features/quest/domain/quest_provider.dart` | 장비 소스 수집 + passiveEffects 합산 + legendaryPreventedDeath write |
| `lib/features/mercenary/data/mercenary_repository.dart` | `setLegendaryCooldown(mercId, until)` |
| `lib/core/providers/game_state_provider.dart` | `UserDataNotifier.setGuildBanner` + `setGuildArtifact` |
| `lib/features/mercenary/view/mercenary_detail_overlay.dart` | `EquipmentSlotGrid` 삽입 (프로필 헤더 → EquipmentSlotGrid → TraitSlotGrid) |
| `lib/features/info/view/info_screen.dart` | `_showGuildEquipment` 상태 + ListTile 3번째 항목 + 분기 |
| `lib/features/quest/view/dispatch_detail_page.dart` | `EquipmentEffectContext.forPartySync` + `calculatePartyPower(equipmentBonuses: ...)` |

---

## 3. 설계 핵심

### 장비 효과 호출 흐름

```
[파견 프리뷰]
DispatchDetailPage
 → EquipmentEffectContext.forPartySync(ref, mercIds)       // 동기, staticData 미로드 시 zero
 → QuestCalculator.calculatePartyPower(..., equipmentBonuses: map)
    ↳ merc.effectiveStrWith(bonus) 사용
 → calculateSuccessRateBreakdown / Preview

[파견 완료]
QuestCompletionService.calculate
 ① EquipmentEffectContext.forParty(ref, mercIds)           // 파티 장비 보정
 ② 전설 효과 수집: 각 merc의 legendariesFor
 ③ 용병단 효과: guildEquipmentEffects
 ④ 전설 ④ reward_bonus → QuestRewardMultiplierEffect('all') 변환
 ⑤ mercCooldowns: {mercId: legendaryDeathPreventionCooldownUntil}
 ⑥ passiveEffects = basePassive + guildEquipments + personalEquipmentLegendaries
 → calculatePartyPower(equipmentBonuses: partyEquipmentBonuses)
 → calculateSuccessRate(legendarySuccessBonus: Σ전설①%p)   // ±10%p 공유 clamp
 → 전설 ② 승격 roll (같은 Random)
 → calculateDamage(legendaryEffects: 파티전체)             // 전설 ③ 가산
 → 전설 ⑤ dead → injured 다운그레이드 + cooldownUntil 세트
 → injuryRate × getInjuryRateMultiplier(passiveEffects)    // 곱셈 스태킹
 → calculateQuestReputation(reputationGainModifier: getReputationGainModifier(ce))
 → quest_provider: legendaryPreventedDeath ? setLegendaryCooldown(mercId, until)
```

### 공용 상한 공유 위치

| 레이어 | 위치 | 공식 |
|---|---|---|
| 성공률 ±10%p | `calculateSuccessRate` 내부 | `(rawTrait + legendarySuccessBonus).clamp(-10.0, 10.0)` — trait+전설① 공유 |
| 성공률 5~95 | `calculateSuccessRate` 반환 | `clamp(5.0, 95.0)` |
| 보상 +0.80 | `calculateReward` | `(trackBonus + passiveRewardBonus).clamp(0.0, 0.80)` — 세력/명성/전설④/용병단 공유 |
| 부상률 하한 0.10 | `getInjuryRateMultiplier` | `(1.0 + Σ).clamp(0.10, 1.0)` — 곱셈 |
| 명성 상한 +0.30 | `getReputationGainModifier` | `sum.clamp(0.0, 0.30)` — 가산 |

### 전설 5 카테고리 경로

| 카테고리 | 진입점 | 적용 방식 |
|:---:|---|---|
| ① success_rate_bonus | `QuestCompletionService`가 %p 누적 → `calculateSuccessRate(legendarySuccessBonus)` | trait과 공유 ±10%p clamp |
| ② result_upgrade | `QuestCompletionService`의 determineResult 직후 | 같은 Random 추가 roll → greatSuccess 승격 |
| ③ damage_resistance | `calculateDamage(legendaryEffects)` | trait mod와 가산 후 clamp(0, 1) |
| ④ reward_bonus | `quest_provider` → `QuestRewardMultiplierEffect('all')` 변환 → `PassiveBonusService.collect` | +0.80 공유 상한 |
| ⑤ special | `QuestCompletionService` dead 분기 | `legendaryDeathPreventionCooldownUntil` 확인 → injured 다운그레이드 + `MercDamageResult.legendaryPreventedDeath` 플래그 → quest_provider가 Hive write |

---

## 4. 검증 모드 및 결과

- **검증 모드**: 풀 검증 (TASK 수 16 ≥ 3)
- **결과**:
  - 1차 verifier: FAIL (ISSUE-1 발견)
  - ISSUE-1 수정 재작업: coder 재호출 1회
  - 2차 verifier: **PASS** (잔여 이슈 없음)
- `flutter analyze`: `No issues found!`
- `flutter test`: **341/341 passed** (기존 312 + 신규 29)

### 수정된 이슈 목록

**[ISSUE-1] 전설 ① success_rate_bonus 공유 ±10%p clamp 미적용**
- 원인: `QuestCompletionService`가 `legendarySuccessBonus`를 외부에서 `baseSuccessRate`에 가산하여 최종 5~95 clamp만 적용되고, trait과의 공유 상한이 작동하지 않음.
- 수정:
  1. `QuestCalculator.calculateSuccessRate` / `calculateSuccessRatePreview` / `calculateSuccessRateBreakdown` 3 메서드에 `double legendarySuccessBonus = 0.0` 파라미터 추가.
  2. 내부 `final traitBonus = (rawTraitBonus + legendarySuccessBonus).clamp(-10.0, 10.0);`로 합산 후 공유 clamp.
  3. `QuestCompletionService`가 외부 가산 경로를 제거하고 calculator 파라미터로 전달.
  4. `quest_completion_legendary_test.dart`에 공유 clamp 검증 3 테스트 추가.

---

## 5. build_runner 재생성 파일

구현 중 2회 실행(Stage 1 완료 후, Stage 2 완료 후):

| 파일 | 이유 |
|---|---|
| `lib/core/models/passive_effect.freezed.dart` | sealed class에 variant 2 추가 |
| `lib/features/inventory/domain/equipment_stat_bonus.freezed.dart` | freezed 신규 |
| `lib/features/inventory/domain/legendary_effect.freezed.dart` | freezed sealed 신규 (5 variant) |
| `lib/features/inventory/domain/personal_equipment_effect.freezed.dart` | freezed 신규 |
| `lib/features/mercenary/domain/mercenary_model.g.dart` | HiveField(18) 추가로 hive_generator 재생성 |

---

## 6. CLAUDE.md 준수 확인

- HiveField 순차 할당(17 → 18) 준수
- 한국어 주석 + UI 텍스트
- `avoid_print` (디버그 시 `debugPrint`)
- Navigator.push 미사용 (상태 기반 렌더링 + showModalBottomSheet)
- `ConstrainedBox(maxWidth: 430)` 모바일 프레임 제약 내 레이아웃
- 기존 패턴 재사용 (`TraitSlotGrid`의 `Wrap + FractionallySizedBox(widthFactor: 0.5)` / `PassiveBonusContext`의 Ref 헬퍼 / 정보 탭 `_showCodex / _showRank` 상태 기반 전환)
- 하위 호환 기본값 인자로 기존 호출부 무수정 유지

**위반 사항: 없음**

---

## 7. 후속 작업 안내

- `finalize-feature` 스킬 실행 시 git commit + CHANGELOG fragment + CLAUDE.md 갱신이 일괄 처리됨.
- 본 스킬(implement-agent)에서는 commit / 문서 아카이브 수행하지 않음.
- data-generator 페이즈 3에서 실제 6개 개인 장비 + 4개 용병단 장비 Supabase 적재 필요.
- 정수 시스템(페이즈 4 산출물 3)에서 `Mercenary.permanent*` HiveField 추가 시 `effectiveStrWith` 공식을 `(base + permanent + equipment)`로 확장.
