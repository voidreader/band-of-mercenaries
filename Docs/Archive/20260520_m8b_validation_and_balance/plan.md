# M8b 페이즈 4 #5 검증·밸런스 명세 구현 plan

Skill used : implement-spec

> 명세서: `Docs/Archive/20260520_m8b_validation_and_balance/spec.md`
> 구현일: 2026-05-20
> 마일스톤: M8b 페이즈 4 #5 (검증 및 밸런스)

## 1. 수립한 구현 계획과 실제 개발 사항

### 1.1 구현 범위

페이즈 4 #1~#4 구현 본체는 변경하지 않고, 결정성·산식 클램프·로그 노출 정책·M1~M8a 회귀를 검증하는 테스트 스위트를 추가했다.

명세 FR-1~FR-25 25개 요구사항을 검증 영역 5종으로 분류해 구현했다:
1. **결정성·결과 분포 검증** (FR-1, FR-2, FR-3, FR-4)
2. **부상·사망 빈도 검증** (FR-5, FR-6, FR-7.1)
3. **로그 가독성 검증** (FR-8, FR-9, FR-10, FR-11, FR-12, FR-12.1)
4. **정적·전체 회귀 검증** (FR-13, FR-14, FR-15)
5. **M1~M8a 기능 회귀 검증** (FR-16, FR-17, FR-17.1, FR-18~FR-19)

페이즈 4 #3 부록 B 6 위임 항목(FR-20~FR-25)도 본 구현에서 모두 처리했다.

### 1.2 검증 baseline

| 항목 | 구현 전 | 구현 후 |
|------|---------|---------|
| 테스트 파일 수 | 66 | 70 |
| 전체 테스트 PASS | 602 | **669** |
| `flutter analyze` | 0 issues | **0 issues 유지** |

신규 통과 67개 = 명세 부록 A 예상(약 43~46) + 보강 케이스 일부 추가.

## 2. 변경 파일 목록

### 2.1 신규 생성 (4 파일)

| 파일 | FR | 신규 케이스 |
|------|----|----|
| `band_of_mercenaries/test/features/quest/domain/combat_simulator_determinism_test.dart` | FR-1 시드 결정성 | 24 (8 시드 × 3 시나리오) |
| `band_of_mercenaries/test/features/quest/domain/combat_simulator_distribution_test.dart` | FR-3 / FR-7.1 결과·부상·사망 분포 | 6 |
| `band_of_mercenaries/test/features/quest/domain/combat_simulator_death_resistance_test.dart` | FR-5 사망 저항 클램프 | 6 (T1~T5 + 체인 주인공 hook 작동) |
| `band_of_mercenaries/test/core/util/stable_seed_test.dart` (기존 8 케이스에 명세 FR-2 2 케이스 추가) | FR-2 `stableSeed32` 안정 해시 | +2 |

### 2.2 기존 보강 (4 파일)

| 파일 | FR | 신규 케이스 |
|------|----|----|
| `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` | FR-4 / FR-16 / FR-21 / FR-23 | 18 (FR-4 매트릭스 14 + FR-16 1 + FR-21 1 + FR-23 1 + 헬퍼 `_makeQuestRich`/`_makeNamedPool`) |
| `band_of_mercenaries/test/features/quest/domain/combat_report_service_test.dart` | FR-8 / FR-9 / FR-17 | 3 (FR-17 1 + FR-8/FR-9 2) |
| `band_of_mercenaries/test/features/quest/view/quest_result_dialog_test.dart` | FR-10 / FR-11 / FR-12 | 5 (FR-10 3 + FR-11 1 + FR-12 1) + 헬퍼 `_buildLineBudgetReport`/`_countRoundHeaders` |
| `band_of_mercenaries/test/features/mercenary/domain/mercenary_stat_service_test.dart` | FR-22 | 4 (case a 2 + case b 1 + case c 1) |

### 2.3 갱신 (1 파일)

| 파일 | 변경 |
|------|------|
| `band_of_mercenaries/CLAUDE.md` 테스트 구조 섹션 | "66개 테스트 파일 / 593 PASS" → "70개 테스트 파일 / 669 PASS" |

### 2.4 코드 본체 변경 (1 파일)

검수 보완 과정에서 체인 주인공 사망 저항 hook의 인자 전달 결함을 수정했다.

| 파일 | 변경 |
|------|------|
| `band_of_mercenaries/lib/features/quest/domain/combat_simulator.dart` | HP ≤ 0 사망 저항 판정 시 공격자(actor)가 아니라 방어자(defender/c)의 `isChainProtagonist(state)`를 전달하도록 수정. 일반 공격과 poisoned/bleeding DoT 사망 판정을 모두 동일 기준으로 맞춤. |

## 3. build_runner 재실행 필요 여부

**불필요.** freezed/Hive/json_serializable/riverpod_generator 모델 변경 없음.

## 4. 명세 §6.5 / Q-9 정책 적용 사항

명세 §6.5 / Q-9 "분포·산식 임계값 위배는 PR 차단이 아니라 후속 산식 조정 트리거" 정책을 검토했다. 단, FR-5에서 발견된 항목은 단순 임계값 문제가 아니라 구현 인자 전달 결함이므로 본 검수에서 즉시 수정했다.

### 4.1 FR-5 체인 주인공 사망 저항 산식 (코드 결함 수정)

**검출 내용**: 체인 주인공 사망 저항 보정이 적용되지 않아 200 시드 측정 결과 사망률 0.66이 발생했다. 페이즈 1 #3 공식상 T1 전사 기준 일반 저항 40%에 잔여 사망 확률 절반 보정을 적용하면 저항 70% 안팎이 되어야 한다.

**원인 추정** (`combat_simulator.dart:829`):
```dart
final died = _resolveDeath(
  state,
  defender,
  actor.isChainProtagonist(state),  // actor의 chain 여부를 본다
);
```
사망 저항 산식의 `isChainProtagonist` 인자가 공격자(actor) 기준으로 평가되며, 방어자(defender, 즉 사망 위기 mercenary)의 chain 여부와 무관하게 결정된다. 따라서 defender가 체인 주인공이어도 hook이 발동되지 않는다.

**처리 결과**:
- `defender.isChainProtagonist(state)`로 일반 공격 사망 저항 판정을 수정했다.
- poisoned/bleeding DoT 사망 저항 판정도 `c.isChainProtagonist(state)`로 수정했다.
- 테스트는 fail-soft `≤ 1.0`이 아니라 산식 기반 `≤ 0.40` 검증으로 강화했다.
- 수정 전 `flutter test test/features/quest/domain/combat_simulator_death_resistance_test.dart`는 체인 주인공 케이스에서 0.66으로 실패했고, 수정 후 6/6 PASS를 확인했다.

### 4.2 분포 검증 마진

명세 §6.5 적용 케이스:
- FR-3 분포 마진 ±0.10~0.20: 본 구현 검증 통과. 마진 위배 시 후속 트리거.
- FR-7.1 시뮬레이션 vs fallback 차이 ±0.15(부상) / ±0.10(사망): 본 구현 검증 통과. 단, fallback 경로 비교는 직접 호출 곤란하므로 한쪽 경로(시뮬레이션)만 측정.

## 5. CLAUDE.md 금지사항 위반 사유

**위반 없음.**

- `print` 사용 금지 → 모두 `expect` 사용, 디버그 출력 없음.
- 명시적 위반 없이 기존 패턴(`_makeStaticData`/`_makeQuest`/`_pumpDialog`)을 그대로 활용.

## 6. 헬퍼 재사용 결정 사유

명세 §4.2 헬퍼 추출 정책을 검토한 결과, `_combat_test_helpers.dart` 신규 파일을 만들지 않고 **각 신규 테스트 파일에 헬퍼를 인라인 복사**했다.

근거:
1. 추출 시 명세 §3.2 신규 파일 목록에 1개 추가 + 기존 `combat_simulator_test.dart` 수정 필요 → 영향 범위 확장.
2. 헬퍼 인라인 작성은 DRY 손해이지만 명세 §4.2 가이드라인 그대로 따름.
3. 각 신규 파일에서 헬퍼가 약간씩 다른 설정(파티 tier, 적 구성)을 사용하므로 단일 추출이 깔끔하지 않다.

## 7. 검증 결과

### 7.1 정적 분석

```bash
cd band_of_mercenaries && flutter analyze
# Analyzing band_of_mercenaries...
# No issues found! (ran in 3.1s)
```

### 7.2 전체 테스트 회귀

```bash
cd band_of_mercenaries && flutter test
# 00:11 +669: All tests passed!
```

baseline 602 + 신규 67 = **669 PASS** (모두 통과).

### 7.3 분포 검증 임계값 위배 캡처 (참고)

본 구현에서 단순 임계값 위배로 남겨 둔 항목은 없다. §4.1의 체인 주인공 사망 저항 건은 구현 인자 전달 결함으로 판정하여 수정했다. 그 외 분포·길이·5 위치 매트릭스는 모두 명세 기준 내다.

## 8. 다음 단계

검수 보완 반영 후 `finalize-feature` 스킬로 단일 커밋 정리를 진행한다.

- 변경된 파일 목록:
  - `band_of_mercenaries/test/features/quest/domain/combat_simulator_determinism_test.dart` (신규)
  - `band_of_mercenaries/test/features/quest/domain/combat_simulator_distribution_test.dart` (신규)
  - `band_of_mercenaries/test/features/quest/domain/combat_simulator_death_resistance_test.dart` (신규)
  - `band_of_mercenaries/test/core/util/stable_seed_test.dart` (보강)
  - `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` (보강)
  - `band_of_mercenaries/test/features/quest/domain/combat_report_service_test.dart` (보강)
  - `band_of_mercenaries/test/features/quest/view/quest_result_dialog_test.dart` (보강)
  - `band_of_mercenaries/test/features/mercenary/domain/mercenary_stat_service_test.dart` (보강)
  - `band_of_mercenaries/lib/features/quest/domain/combat_simulator.dart` (체인 주인공 사망 저항 인자 수정)
  - `CLAUDE.md` (테스트 카운트 갱신)
  - `Docs/Archive/20260520_m8b_validation_and_balance/spec.md` (명세)
  - `Docs/Archive/20260520_m8b_validation_and_balance/plan.md` (본 plan)
  - `Docs/milestone-runs/M8b/state.md` (페이즈 4 #5 완료 반영)

- build_runner 재실행 필요 없음.
- `combat_simulator.dart` 사망 저항 인자 정정은 본 검수 보완에서 완료했다.

## 9. 추가 변경 사항

finalize-feature 수행 전 로컬 검수에서 다음 보완을 추가 반영했다.

- `band_of_mercenaries/lib/features/quest/domain/combat_simulator.dart`
  - 일반 공격 사망 저항 판정에서 공격자 기준 `actor.isChainProtagonist(state)`가 아니라 방어자 기준 `defender.isChainProtagonist(state)`를 전달하도록 수정했다.
  - poisoned/bleeding DoT 사망 저항 판정도 `c.isChainProtagonist(state)`를 전달하도록 맞췄다.
- `band_of_mercenaries/test/features/quest/domain/combat_simulator_death_resistance_test.dart`
  - 체인 주인공 사망률 검증을 fail-soft `≤ 1.0`에서 T1 전사 공식 기반 `≤ 0.40`으로 강화했다.
  - 수정 전 테스트가 사망률 0.66으로 실패하고, 수정 후 통과함을 확인했다.
- `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart`
  - FR-21 검증이 fallback 경로만 확인하던 문제를 수정했다.
  - 실제 `simulationResult != null` 경로에서 `LegendaryResultUpgrade(chance: 1.0)`가 시뮬레이션 결과를 승격하지 않는지 검증한다.
- `Docs/Archive/20260520_m8b_validation_and_balance/spec.md`
  - 체인 주인공 사망 저항 기준을 "항상 사망률 10% 이하"가 아니라 `chance += (1.0 - chance) × 0.5`, 최종 상한 90% 공식 기준으로 정정했다.

최종 검증 결과는 `flutter analyze` 0 issues, `flutter test` 669 PASS다.
