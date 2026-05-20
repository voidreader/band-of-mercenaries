# M8b 실행 상태

> 시작: 2026-05-19T11:30:00+09:00
> 마지막 업데이트: 2026-05-20T19:00:00+09:00
> 현재 페이즈: 4
> 상태: completed

## 로드맵 요구사항 요약

M8b "진짜 전투의 시작"은 M8a의 전투 보고서 MVP를 실제 턴 기반 전투 시뮬레이터로 확장한다. 이 단계부터 일부 특별 의뢰(세력·지명·엘리트·연계)는 기존 성공률 계산 결과를 설명하는 보고서가 아니라, 파티원과 적이 턴 단위로 행동한 결과가 성공·실패·부상·사망을 만든다. 일반 의뢰는 `QuestCalculator` fallback으로 유지하며, 전투는 실시간 조작 화면이 아니라 파견 완료 후 읽는 보고서로 제공한다.

선행 의존성: M8a archived 완료. `CombatReport` 모델(typeId 21) + `ActiveQuest.combatReport` HiveField 27 + `combat_report_templates`(96행) + `combat_report_keywords`(40행) + `QuestResultDialog` 인라인 상세 전환 기반.

## 포함 범위

- 파견 시작 시점 전투 스냅샷 고정.
- 턴 순서, 선제권, 공격자/방어자 판정.
- 기본 공격, HP, 피해량, 명중, 회피, 치명타, 방어 계산.
- 직업군 대표 스킬 6~10개.
- 버프, 디버프, 광역 공격, 메즈, 지속 피해 등 상태 효과 MVP 8~12개.
- 전투 종료 결과와 보상, 부상, 사망, 위업, 칭호, 지역 상태 변화 연결.

## 페이즈 1: 컨텐츠 설계

**상태**: completed

계획된 산출물:
- [x] 1. 전투 턴 구조 설계
  - 참고 문서: `Docs/roadmap/master_roadmap.md` M8b 섹션, `Docs/Archive/20260519_m8a_faction_combat_report/`(M8a 전투 보고서 MVP), `QuestCompletionService` 흐름
  - 권장 내용: 선제 라운드 → 일반 라운드 반복 → 마무리 판정 흐름, 파견 시작 시점 스냅샷 고정 정책, 적용 대상 의뢰 범위(세력·지명·엘리트·연계) 확정
  - 산출물: `Docs/content-design/[content]20260519_m8b_combat_turn_structure.md`
  - 완료: 2026-05-19T12:05:00+09:00
- [x] 2. 선제권·행동 순서·공격자/방어자 판정 설계
  - 참고 문서: 페이즈 1 산출물 1, 기존 트레잇·직업군 데이터(`traits`, `jobs`, `RoleSynergyMatrix`)
  - 권장 내용: AGI·직업군·트레잇·전장 조건 가중치, 회피·반격 트리거, 다단 행동 규칙
  - 산출물: `Docs/content-design/[content]20260519_m8b_initiative_and_action_order.md`
  - 완료: 2026-05-19T12:35:00+09:00
- [x] 3. 기본 공격·피해량·명중·회피·치명타 공식 설계
  - 참고 문서: 페이즈 1 산출물 1, 2, `Mercenary.effectiveXxx` 스탯 로직, `QuestCalculator._statWeights`
  - 권장 내용: STR/INT/VIT/AGI 사용 공식, 방어 계산, 노출 수치 기준(피해량/치명타/회피/사망 저항)
  - 산출물: `Docs/content-design/[content]20260519_m8b_combat_formulas.md`
  - 완료: 2026-05-19T13:05:00+09:00
- [x] 4. 상태 효과 MVP 타입 설계
  - 참고 문서: 페이즈 1 산출물 1~3, `traits`/`trait_categories`, M8a 전투 보고서 결정적 장면 키워드
  - 권장 내용: 버프/디버프/광역/메즈/지속 피해 8~12 타입의 발동·해제·중첩 규칙, 상태 ID·키워드 매핑
  - 산출물: `Docs/content-design/[content]20260519_m8b_status_effects.md`
  - 완료: 2026-05-19T13:35:00+09:00

## 페이즈 2: 직업군 스킬·적 유형 설계

**상태**: completed

계획된 산출물:
- [x] 1. 직업군 대표 스킬 6~10개
  - 입력 의존: 페이즈 1 전체
  - 권장 내용: warrior/rogue/ranger/mage/support/specialist 각 1개+, 트리거·쿨다운·효과·상태효과 연결
  - 산출물: `Docs/balance-design/[balance]20260519_m8b_class_skills.md`
  - 완료: 2026-05-19T14:10:00+09:00
- [x] 2. 적 유형 20~30개 능력치·행동 패턴
  - 입력 의존: 페이즈 1 전체
  - 권장 내용: 일반/엘리트/유니크 분포, AI 행동 패턴, 전장 분위기 매핑(`combat_report_keywords` category=battlefield 참조)
  - 산출물: `Docs/balance-design/[balance]20260519_m8b_enemy_types.md`
  - 완료: 2026-05-19T14:25:00+09:00
- [x] 3. 상태 효과 8~12개 수치 확정
  - 입력 의존: 페이즈 1 산출물 4 + 페이즈 2 산출물 1, 2
  - 권장 내용: 지속 턴·강도·중첩 한도 수치화, 회복/해제 트리거
  - 산출물: `Docs/balance-design/[balance]20260519_m8b_status_effect_values.md`
  - 완료: 2026-05-19T14:40:00+09:00
- [x] 4. 전투 로그 길이·수치 노출 기준 확정
  - 입력 의존: 페이즈 1 전체 + 페이즈 2 산출물 1, 2, 3
  - 권장 내용: 보고서 라운드 수 분포, 피해량·치명타·상태 지속 노출 기준, M8a 전투 보고서 길이 매트릭스와 정합, 가독성 검증
  - 산출물: `Docs/balance-design/[balance]20260519_m8b_combat_log_exposure.md`
  - 완료: 2026-05-19T14:55:00+09:00

## 페이즈 3: 데이터 생성

**상태**: completed

> 데이터 생성 전 `types/enemy.md`·`types/combat-skill.md`·`types/status-effect.md`·`types/combat-log-template.md` 타입 스펙 존재 여부를 확인한다. 부재 시 (a) 타입 스펙을 우선 작성하거나 (b) SQL/수동 데이터 생성으로 전환할지 페이즈 3 시작 시 결정한다.
>
> **2026-05-19T15:15:00+09:00 결정**: 타입 스펙 4종 모두 부재 → **(b) SQL/수동 데이터 생성 병행** 채택 (M7/M8a 정책과 동일). 신규 테이블 3개(`enemies`/`combat_skills`/`combat_status_effects`) DDL + 시드 SQL을 페이즈 3 산출물로 생성. `combat_report_templates`는 M8a 기존 테이블에 scope CHECK 확장 ALTER + 신규 85행 INSERT.

계획된 산출물:
- [x] 1. 적 유형 26개
  - 입력 의존: 페이즈 2 산출물 2
  - 대상 테이블: `enemies` (신규 — DDL + 26 시드)
  - 산출물:
    - `Docs/content-data/[enemy]20260519_m8b-enemies.csv` (26 시드 데이터)
    - `Docs/content-data/[enemy]20260519_m8b-enemies.md` (DDL + 설명서)
  - 완료: 2026-05-19T15:35:00+09:00
- [x] 2. 전투 스킬 시드 16개
  - 입력 의존: 페이즈 2 산출물 1
  - 대상 테이블: `combat_skills` (신규 — DDL + 16 시드)
  - 범위: 파티 측 직업군 대표 스킬 10개 + 적 전용 스킬 6개
  - 산출물:
    - `Docs/content-data/[combat-skill]20260519_m8b-combat-skills.csv` (16 시드 데이터)
    - `Docs/content-data/[combat-skill]20260519_m8b-combat-skills.md` (DDL + 설명서)
  - 완료: 2026-05-19T15:55:00+09:00
- [x] 3. 상태 효과 10개
  - 입력 의존: 페이즈 2 산출물 3
  - 대상 테이블: `combat_status_effects` (신규 — DDL + 10 시드)
  - 산출물:
    - `Docs/content-data/[status-effect]20260519_m8b-combat-status-effects.csv` (10 시드 데이터)
    - `Docs/content-data/[status-effect]20260519_m8b-combat-status-effects.md` (DDL + 설명서)
  - 완료: 2026-05-19T16:10:00+09:00
- [x] 4. 전투 로그 템플릿 85개 추가 (M8a 96 + M8b 85 = 181)
  - 입력 의존: 페이즈 1 전체 + 페이즈 2 산출물 4 + 페이즈 3 산출물 1, 2, 3
  - 대상 테이블: M8a `combat_report_templates` ALTER (scope CHECK 확장 `combat_skill` 추가) + 85행 INSERT
  - 산출물:
    - `Docs/content-data/[combat-log-template]20260519_m8b-combat-report-templates.csv` (85 시드)
    - `Docs/content-data/[combat-log-template]20260519_m8b-combat-report-templates.md` (ALTER + 분포 + 설명서)
  - 완료: 2026-05-19T16:30:00+09:00

## 페이즈 4: 개발 명세

**상태**: completed (5/5 산출물 모두 완료, 페이즈 4 #5 명세 작성 완료 — 구현 단계 진행 가능)

계획된 산출물:
- [x] 1. `CombatSimulator` 순수 서비스 명세
  - 입력 의존: 페이즈 1 전체 + 페이즈 2 산출물 1, 2, 3
  - 권장 내용: 턴 루프 구조, 입력/출력 계약, 시드 결정성, 콜백 DI
  - 산출물: `Docs/spec/[spec]20260519_m8b_combat_simulator.md`
  - 완료: 2026-05-19T17:05:00+09:00
- [x] 2. 신규 모델 명세 (`CombatantSnapshot` 외 5종)
  - 입력 의존: 페이즈 1 전체 + 페이즈 2 산출물 1, 2, 3
  - 권장 내용: `CombatantSnapshot`/`CombatTurn`/`CombatAction`/`CombatStatusEffect`/확장된 `CombatReport`. Hive typeId 22+ 할당, `ActiveQuest.combatReport` HiveField 27 호환
  - 산출물: `Docs/spec/[spec]20260519_m8b_phase4_models.md`
  - 완료: 2026-05-19T17:59:00+09:00
- [x] 3. `QuestCompletionService` 통합 명세
  - 입력 의존: 페이즈 4 산출물 1, 2 + M8a 전투 보고서 시스템 연결
  - 권장 내용: 특별 의뢰 분기 → `CombatSimulator` 호출 → 결과 → 부상/사망/위업/칭호/지역 상태 연결, `QuestCalculator` fallback 보존
  - 산출물: `Docs/spec/[spec]20260519_m8b_quest_completion_integration.md`
  - 완료: 2026-05-19T22:00:00+09:00
- [x] 4. 전투 보고서 UI 확장 명세
  - 입력 의존: 페이즈 4 산출물 1, 2 + 페이즈 3 산출물 4
  - 권장 내용: 라운드 로그 표시, 용병별 기여, 결정적 장면 강조, M8a `QuestResultDialog` 인라인 전환 호환
  - 산출물:
    - `Docs/spec/[spec]20260520_m8b_combat_report_ui.md` (명세, 40.9KB)
    - `Docs/spec/[spec]20260520_m8b_combat_report_ui_plan.md` (구현 plan, 6.0KB)
  - 구현 커밋: `ddc80eb feat: m8b-combat-report-ui 구현 — schemaVersion 분기/라운드 로그 섹션/lineBudget 압축/5 위치 색상/decisive 배지`
  - 완료: 2026-05-20T08:30:00+09:00
- [x] 5. 검증 및 밸런스 명세
  - 입력 의존: 페이즈 4 산출물 1~4 통합
  - 권장 내용: 전투 결과 분포 검증, 부상/사망 빈도 검증, 로그 가독성 검증, `flutter analyze`/`flutter test` 검증 계획, M1~M8a 회귀 검증 절차
  - 산출물: `Docs/Archive/20260520_m8b_validation_and_balance/spec.md` (검증·밸런스 명세, 약 36KB, FR-1~FR-25 + Q-1~Q-10 + 부록 A/B/C)
  - 검증 결과: spec-pipeline → spec-writer Sonnet → verify-spec Opus 1회 **PASS** (5/5 항목)
  - 완료: 2026-05-20T09:00:00+09:00

## 페이즈 간 의존

- 페이즈 2 전체 → 페이즈 1 전체 입력
- 페이즈 3 항목 1 → 페이즈 2 항목 2
- 페이즈 3 항목 2 → 페이즈 2 항목 1
- 페이즈 3 항목 3 → 페이즈 2 항목 3
- 페이즈 3 항목 4 → 페이즈 1 전체 + 페이즈 2 항목 4 + 페이즈 3 항목 1, 2, 3
- 페이즈 4 항목 1~2 → 페이즈 1 전체 + 페이즈 2 항목 1~3
- 페이즈 4 항목 3 → 페이즈 4 항목 1, 2 + M8a 전투 보고서 시스템 연결
- 페이즈 4 항목 4 → 페이즈 4 항목 1, 2 + 페이즈 3 항목 4
- 페이즈 4 항목 5 → 페이즈 4 항목 1~4 통합

## 완료 기준

- [x] 세력·지명·엘리트·연계 의뢰 중 지정된 대상이 실제 턴 전투로 계산된다.
- [x] 기본 공격, 스킬, 피해량, 명중/회피/치명타, 상태 효과가 전투 로그에 기록된다.
- [x] 선제권과 행동 순서가 AGI, 직업군, 트레잇에 따라 달라진다.
- [x] 부상/사망 결과가 기존 용병 상태 시스템과 호환된다.
- [x] 기존 성공률 기반 일반 의뢰가 `QuestCalculator` fallback으로 정상 동작한다.
- [x] 전투 보고서는 M8a 호환 인라인 전환을 유지하며 라운드 로그·기여·결정적 장면을 구분한다.
- [x] M1~M8a 기능 회귀 이상 없음 (`flutter analyze` 0 issues, `flutter test` 669 PASS).

## 실행 이력

- 2026-05-18T00:00:00+09:00: M8b 사전 골격 작성 (state.md planned 상태, 페이즈 계획 초안 4개).
- 2026-05-19T11:30:00+09:00: milestone-runner 신규 시작. 사전 골격 베이스로 산출물 계획을 구체화하여 4페이즈 계획 승인 (페이즈 1: 4개 / 페이즈 2: 4개 / 페이즈 3: 4개 / 페이즈 4: 5개). 상태 in_progress로 전환.
- 2026-05-19T11:30:00+09:00: 페이즈 1 시작. 첫 산출물은 "전투 턴 구조 설계"이다.
- 2026-05-19T12:05:00+09:00: 페이즈 1 산출물 1 "전투 턴 구조 설계" 완료 (`Docs/content-design/[content]20260519_m8b_combat_turn_structure.md`). 4 페이즈 흐름(사전→선제 라운드 0~1회→일반 라운드 1~8회→마무리), 종료 조건 6종 (a)~(f), `combatSimulationEligible`을 `combatReportEligible`과 분리, 스냅샷 동결 시점 `quest.startTime` 직후, 시드 = `stableSeed32(startTime|questId)`, `CombatReport` 모델 HiveField 8+ optional 확장 후보, fallback `QuestCalculator`로 안전 가드 채택.
- 2026-05-19T12:35:00+09:00: 페이즈 1 산출물 2 "선제권·행동 순서·공격자/방어자 판정 설계" 완료 (`Docs/content-design/[content]20260519_m8b_initiative_and_action_order.md`). 라운드 일괄 정렬 방식 채택(ATB 미채택), 선제 점수 격차 임계값 |delta|≥15로 선제 라운드 발동, `actionScore = effectiveAgi + roleActionWeight + traitBonus + battlefield + noise(±3)` 산식, 직업군 선제/행동 가중치 매트릭스 2종 분리, 진형 3열(전열/중열/후열) + 접근형/원거리 표적 정책, 회피→방패 막기→반격 판정 순서(반격에서 반격 없음), 트레잇 카테고리·키워드 매핑(진영 합산 상한 +15), 전장 8 태그 × 6 직업군 매트릭스, 다단 행동(광역/연속/추가) 행동 순서 1번 소모 채택.
- 2026-05-19T13:05:00+09:00: 페이즈 1 산출물 3 "기본 공격·피해량·명중·회피·치명타 공식 설계" 완료 (`Docs/content-design/[content]20260519_m8b_combat_formulas.md`). HP 산식 `vit×roleCoef + roleFlat + tierBonus + level×6`(T1 33~58 vs T5 169~229 분포), 공격 산식 직업군 분기(warrior STR×1.2 / mage INT×1.2 / rogue STR×0.7+AGI×0.4 등), 피해 `rawDamage` 계산 후 `max(1, round(rawDamage))` 최종 클램프, 명중 [50%, 95%] / 회피 [0%, 75%] / 치명타 [5%, 60%] / 반격 [0%, 60%] / 일반 사망저항 [20%, 80%] 클램프, 체인 주인공 보호 `+ (1-resist)×0.5` 및 최종 90% 상한, 보고서 노출 정책(피해 정수 노출 / HP·확률 비노출), 7 PRNG 인스턴스(dmg/hit/crit/eva/shd/rip/death) 분리와 안정 해시로 결정성 보장, 모든 매트릭스 정적 상수 내장 채택. T3 vs T3 검증 결과 라운드 1~3 피해 → 6라운드 평균이 페이즈 1 #1 권장 범위(3~6)와 정합.
- 2026-05-19T13:35:00+09:00: 페이즈 1 산출물 4 "상태 효과 MVP 타입 설계" 완료 (`Docs/content-design/[content]20260519_m8b_status_effects.md`). 10 타입 카탈로그(buff 4 / debuff 3 / mez 1 / dot 2), 페이즈 1 #3 hook 매핑 결합 규칙(공격·방어 곱셈 / 명중·회피 가산 / 치명타·반격·일반피해 hook MVP 미매핑은 페이즈 2 #1 스킬 직접 처리), stunned 정렬 포함·행동 시점 스킵 / 회피·반격 정상, DoT 분리 산식(bleeding 비례형 라운드 종료 / poisoned 절대형 라운드 시작 / stack 상한 3), 중첩 정책(buff/debuff/mez refresh, DoT stack), 해제 트리거 5종, ID 네이밍 `{kind}_{effect}[_{direction}]` snake_case, 보고서 노출 정책(라벨·지속 턴·DoT 피해 정수 노출 / intensity·applyChance 비노출) 채택.
- 2026-05-19T13:35:00+09:00: 페이즈 1 종료 — 4/4 산출물 모두 완료. 상태 paused로 갱신하고 페이즈 2 승인 대기.
- 2026-05-19T13:50:55+09:00: 페이즈 1 검수 보완 반영. 전투 스냅샷·압축 턴 로그 영속화 정책을 `CombatReport` HiveField 8+ 확장 후보로 정정하고, `hashCode` 기반 시드를 `stableSeed32` 안정 해시로 교체했다. 피해량 최종 클램프, 체인 주인공 사망 저항 예외 상한(90%), 추가 행동 `extraAction` 플래그 정책, `quest.startTime` 용어를 문서 4개에 반영했다.
- 2026-05-19T14:10:00+09:00: 페이즈 2 시작. 페이즈 2 산출물 1 "직업군 대표 스킬 6~10개" 완료 (`Docs/balance-design/[balance]20260519_m8b_class_skills.md`). 10 스킬 카탈로그(warrior 2·rogue 1·ranger 2·mage 2·support 2·specialist 1), specialist `skill_specialist_adaptive_footwork` 보강, §1.3 적 측 카탈로그 공유 9 + 파티 전용 1(`cleansing_word`), §4.1 페이즈 1 #3 hook 7/8 활성·§4.3 페이즈 1 #4 상태 효과 6/10 직접 활성, §5 페이즈 1 #4 §1.5 미매핑 hook 직접 표현 패턴(`marksman_focus` critRate +0.15), §6 콤보 패턴 4종, §7 자동 발동 결정 트리, §8.3 적 전용 신규 후보 6종(`bleeding_cut`·`armor_break`·`poison_bite`·`taunt_roar`·`summon`·`self_dispel`), §10 `CombatSkill` 데이터 구조 22 컬럼 풀, Supabase jobs role 분포 확인(warrior 26 / specialist 16 / mage 16 / support 10 / ranger 9 / rogue 8).
- 2026-05-19T14:25:00+09:00: 페이즈 2 산출물 2 "적 유형 20~30개 능력치·행동 패턴" 완료 (`Docs/balance-design/[balance]20260519_m8b_enemy_types.md`). 26 적 카탈로그(일반 17 신규 + 일반 엘리트 5 + 유니크 4), `elite_monsters` 40행 보존 + 매핑 9행만 FK 참조, §1.4 모든 적 6 직업군 매핑(페이즈 1 #3 산식 정합), §5 적 전용 6 신규 스킬 정식 정의(`skill_enemy_bleeding_cut`·`armor_break`·`poison_bite`·`taunt_roar`·`summon`·`self_dispel`), §6 26행 중 19행에 14 스킬 분배(페이즈 2 #1 §1.3 정합), `poison_bite`는 `enemy_trial_beast` 1종 제한 배정, §7 적 측 진형 자동 배치 6 직업군 그대로, §8 behaviorPattern 6종(aggressive/opportunist/caster/supporter/defender/berserker), §9 M8a 활성 8 세력 매핑 + 6 세력 M9+ 위임, §10 M7 핵심 7리전 적 풀 매칭, §11 M8a `combat_report_keywords` enemy 9/10 매핑 + 신규 5 후보, §12 매복 의뢰 후보 12행(70.6%), §14 `EnemyArchetype` 19 컬럼 + `EnemySnapshot` 14 필드 동결. Supabase elite_monsters 40행·factions 14행·combat_report_keywords 40행 분포 확인.
- 2026-05-19T14:40:00+09:00: 페이즈 2 산출물 3 "상태 효과 8~12개 수치 확정" 완료 (`Docs/balance-design/[balance]20260519_m8b_status_effect_values.md`). 10 상태 효과 default 정밀 값(buff 4: 0.10~0.20 / 1~3턴, debuff 3: 0.10~0.25 / 2~3턴, mez 1: 1턴, dot 2: stack 1/3턴), §3 DoT 시뮬레이션(bleeding 비례 18~24% 누적 / poisoned 절대 stack 1 intensity 3 저HP 즉사 위협), §4 다중 결합 시뮬(battle_fury 0.30 × mass_blind 0.20 → ×1.04 곱셈 정합), §5 클램프 도달 빈도(명중 95% marksman+trait ranger만 도달 / 회피 75% MVP 미도달 / 치명타 60% 미도달 — 5~50% 자연 분포), §6 default vs 오버라이드 매트릭스(직접 활성 8개 + 환경 활성 1개 + poison 제한 활성 1개), §7 트레잇 자동 부여(vigilant→buff_evasion_up 0.10/1턴, huntsman→buff_accuracy_up 0.05/1턴) + 환경(mist_field→debuff_accuracy_down 0.10/2턴 적군 전원), §10.2 페이즈 3 #3 시드 10행 정밀 값 명시.
- 2026-05-19T14:55:00+09:00: 페이즈 2 산출물 4 "전투 로그 길이·수치 노출 기준 확정" 완료 (`Docs/balance-design/[balance]20260519_m8b_combat_log_exposure.md`). M8a `combat_report_templates`(96행 + scope 7종/line_type 2종) + `combat_report_keywords`(40행) 분포 분석, §2 라운드 ↔ 길이 매핑(1~3R: 2/4, 6R: 3/6, 8R: 4/8), §3 5 위치 분류(`tags_json.position` 메타로 영속 — entry/development/crisis/resolution/aftermath, M8a line_type=detail 호환), §4 노출/비노출 매트릭스 통합(노출 17 / 비노출 14 항목), §7 scope 7종 차등 길이(unique_elite·chain_final veryHigh 8줄 / elite·chain_step·settlement_event·faction_named(adv) high 6줄 / faction_named(basic)·quest_type normal 5줄), §8 다중 결합 7 케이스 + 콤보 패턴 4종 압축, §9 신규 80행 분포 권고(M8a 96 + M8b 80 = 176, 권장 120~180 안) + 신규 scope `combat_skill` 도입, §10 라인 풀 분할(M8.5/M9에 70 추가 위임), §11 라인 예시 3종(unique_elite/faction_named basic/chain_final critical_failure). 페이즈 2 4/4 산출물 완료 → 페이즈 2 completed 갱신, 페이즈 종료 체크포인트로 이동.
- 2026-05-19T15:05:00+09:00: 페이즈 2 산출물 4개 모두에 대해 코덱스 보완 적용. (1) `class_skills.md` — rogue 2→1종, specialist 0→1종(`skill_specialist_adaptive_footwork`·`buff_evasion_up` 활성) — 총 10종 유지. (2) `enemy_types.md` — 적 전용 스킬 5→6종(`skill_enemy_bleeding_cut` 신규), `enemy_bandit_assassin`·`enemy_elite_goblin_raider` 스킬 매핑 갱신. (3) `status_effect_values.md` — 적 전용 6 스킬 권고 수치 반영, `buff_evasion_up` default duration 1→2턴, 미사용 3종→2종. (4) `combat_log_exposure.md` — `adaptive_footwork`·`bleeding_cut` 라인 후보 추가. 페이즈 3 영향: 양적 차이만 (combat_skills 15→16행 / `buff_evasion_up` 활성 영역 확장). 페이즈 3 시작에 결정·구조 변경 영향 없음.
- 2026-05-19T15:15:00+09:00: 페이즈 3 시작. 타입 스펙 4종 부재 → SQL/수동 데이터 생성 병행(M7/M8a 정책 동일) 채택. 첫 산출물은 "적 유형 26개" — `enemies` 신규 테이블 DDL + 26 시드 INSERT SQL.
- 2026-05-19T15:35:00+09:00: 페이즈 3 산출물 1 "적 유형 26개" 완료 (CSV `Docs/content-data/[enemy]20260519_m8b-enemies.csv` + MD `Docs/content-data/[enemy]20260519_m8b-enemies.md`). 19 컬럼 DDL(enemy_kind/role/behavior_pattern CHECK + tier 1~5 + elite_monster_id FK + JSONB 3종 + 인덱스 4종) + 26 시드(일반 17 / 일반 엘리트 5 / 유니크 4). role 분포 warrior 11·rogue 4·ranger 4·mage 5·support 1·specialist 1, tier T2~T3 집중(9+10=19), behaviorPattern 6종 활용(opportunist 7 / berserker 6 / aggressive 5 / caster 5 / defender 2 / supporter 1), 매복 호환 12행, M8a 활성 8 세력 매핑 22행 + 미매핑 4행(M9+ 위임), 14 스킬 활용(`skill_enemy_bleeding_cut`·`skill_enemy_poison_bite` 코덱스 보완 반영), 페이즈 1 #3 HP/공격/방어 산식 정합 검증 5 표본 (±3~24 보스 강화 보정). 페이즈 3 #2 시드 후 enemies_skill_ids_valid CHECK ALTER 후속 명시.
- 2026-05-19T15:55:00+09:00: 페이즈 3 산출물 2 "전투 스킬 시드 16개" 완료 (CSV `Docs/content-data/[combat-skill]20260519_m8b-combat-skills.csv` + MD `Docs/content-data/[combat-skill]20260519_m8b-combat-skills.md`). 23 컬럼 DDL(role/trigger_kind/action_cost/targeting_kind/dispel_kind CHECK + cooldown/multi_hit/intensity/apply_chance 클램프 + 인덱스 3종) + 16 시드(파티 10 + 적 6). role 분포 warrior 4·rogue 3·ranger 2·mage 4·support 2·specialist 1, trigger 분포 passive 1·active 4·triggered 11, action_cost 분포 action 14·extraAction 1·passive 1, targeting 분포 self 5·single_enemy 5·aoe_enemy 2·aoe_ally 3, 9 unique status_effect_id 참조(buff 4·debuff 2·mez 1·dot 2 = 9 — debuff_accuracy_down 환경 전용 미참조). 오버라이드 2 스킬(battle_fury 0.30/3턴, taunt_roar 0.15) + default 7 스킬. multi_hit 1(volley_shot=3) + max_uses 2(battle_fury/summon=1 전투). 페이즈 3 #1 enemies.skill_ids 14 참조 모두 본 시드에서 정의됨. 페이즈 3 #3 시드 후 combat_skills_status_effect_fk FK ALTER + enemies_skill_ids_valid CHECK ALTER 후속 명시.
- 2026-05-19T16:10:00+09:00: 페이즈 3 산출물 3 "상태 효과 10개" 완료 (CSV `Docs/content-data/[status-effect]20260519_m8b-combat-status-effects.csv` + MD `Docs/content-data/[status-effect]20260519_m8b-combat-status-effects.md`). 9 컬럼 DDL(kind/stack_policy/apply_method CHECK + duration 1~5 / intensity 0.0~3.0 클램프 + 인덱스 1종) + 10 시드(buff 4 / debuff 3 / mez 1 / dot 2). apply_method 5종 분포(multiplicative 4·additive 4·proportional 1·absolute 1·none 1), stack_policy 분포(refresh 8 / stack 2), hook_target 7종(attack·defense·hit·evasion·action_skip·round_end·round_start). `buff_evasion_up` default_duration 1→2 코덱스 보완 반영(`skill_specialist_adaptive_footwork` 활성화). DoT 누적 시뮬 정합(bleeding 비례 20%/68% 단계 / poisoned 절대 stack 1 즉사 위협). 다중 결합 시뮬(battle_fury 0.30 × mass_blind 0.20 = 1.04 곱셈). 페이즈 3 #2 9 unique status_effect_id 참조 모두 본 시드에서 정의됨. 페이즈 3 #3 직후 combat_skills_status_effect_fk FK ALTER 후속 명시.
- 2026-05-19T16:30:00+09:00: 페이즈 3 산출물 4 "전투 로그 템플릿 85행 추가" 완료 (CSV `Docs/content-data/[combat-log-template]20260519_m8b-combat-report-templates.csv` + MD `Docs/content-data/[combat-log-template]20260519_m8b-combat-report-templates.md`). M8a 96 + M8b 85 = 총 181행(권장 120~180 +1, 정밀 조정 가능). scope CHECK 확장 ALTER(`combat_skill` 신규 추가) + 85행 INSERT(chain_final 4 / chain_step 4 / elite 8 / unique_elite 8 / settlement_event 4 / faction_named 10 / quest_type 4 / scene 20 / combat_skill 23). tags_json 5 메타 필드(position/skill_id/status_effect_id/decisive_keyword_key/is_combo_compression). 16/16 스킬 매핑, 9/10 상태 효과 매핑(`debuff_accuracy_down` 환경 전용 제외), M8a decisive 5/12 + injury 5/6 키워드 활용. combat_report_keywords 5 신규 enemy 키워드 INSERT SQL 명시(권고). 페이즈 4 #2 모델 호환 명세 위임. 페이즈 3 4/4 산출물 모두 완료 → 페이즈 3 completed 갱신, 페이즈 종료 체크포인트로 이동.
- 2026-05-19T16:45:00+09:00: 페이즈 3 산출물 검수 보완 반영. `enemy_trial_beast`를 페이즈 2 결정과 맞춰 `skill_enemy_poison_bite` 담당 적으로 수정하고, 전투 로그 85행 총량을 유지한 채 `crt_m8b_skill_enemy_poison_01`을 추가하여 16/16 스킬과 9/10 상태 효과(`debuff_accuracy_down` 환경 전용 제외)가 로그 템플릿에 매핑되도록 정합화했다.
- 2026-05-19T16:55:00+09:00: 페이즈 3 산출물 검수 보완 영향 분석 완료(schema migration 불필요). 페이즈 4 시작. 사용자 결정: 5개 산출물을 개별 명세로 분리 진행(통합 명세 미채택). 첫 산출물은 `CombatSimulator` 순수 서비스 명세.
- 2026-05-19T17:05:00+09:00: 페이즈 4 산출물 1 `CombatSimulator` 순수 서비스 명세 검수 보완 완료. 장비 보정 입력(`partyEquipmentBonuses`) 누락, `TemplateEngine` 불필요 입력, `RegionState.regionEnvironmentTags` 오참조, `QuestCompletionResult.copyWith` 오기, 페이즈 3 #4 최종 수량(85행/181행/`combat_skill` 23행) 미반영 표현을 수정했다.
- 2026-05-19T17:59:00+09:00: 페이즈 4 산출물 2 "신규 모델 명세" 완료 (`Docs/spec/[spec]20260519_m8b_phase4_models.md`, 50.8KB). 모델 9종을 두 그룹으로 분리 — 그룹 A 정적 카탈로그 3종(`CombatSkill`/`CombatStatusEffect`/`EnemyArchetype`, freezed+json_serializable, Hive typeId 미할당) + 그룹 B 시뮬레이션 영속 6종(`CombatSimulationResult`/`CombatTurn`/`CombatAction`/`StatusEffectEvent`/`CombatantSnapshot`/`EnemySnapshot`, 일반 Hive 클래스 + hive_generator, typeId 22~30). enum 10종(정적 7 + Hive 3 — `CombatExitCondition`/`BehaviorPattern`/`PositionRow`). `CombatReport`(typeId 21) HiveField 8~14 확장(`schemaVersion`/`combatantSnapshots`/`turns`/`exitCondition`/`objectiveProgress`/`enemySnapshots`/`statusEffectHistory`). `StaticGameData` 3 컬렉션 추가(combatSkills/combatStatusEffects/enemyArchetypes). `SyncService.allTables` 37→40 + `optionalTables` 3 항목 추가. `HiveInitializer` 어댑터 9개 등록.
- 2026-05-19T19:17:00+09:00: 페이즈 4 산출물 2 구현 완료 plan 작성 (`Docs/spec/[spec]20260519_m8b_phase4_models_plan.md`, 9.8KB). implement-agent로 8개 TASK 순차 격리 실행 — TASK-1 정적 카탈로그 enum 7 + freezed 모델 3 / TASK-2 Hive 모델 6 + Hive enum 3 (typeId 22~30) / TASK-3 CombatReport HiveField 8~14 확장 / TASK-4 StaticGameData + staticDataProvider 로딩 / TASK-5 SyncService allTables + optionalTables 3 / TASK-6 HiveInitializer 어댑터 9 / TASK-7 Supabase 마이그레이션 4건 + data_versions / TASK-8 build_runner 14 파일 자동 생성. PHASE 2.5 빌드 게이트에서 테스트 6 파일의 `StaticGameData(...)` 호출 누락이 발견되어 dart-build-resolver 외과적 수정. PHASE 3 final integration APPROVE. 신규 코드 파일: `lib/core/models/combat_enums.dart`·`combat_skill.dart`·`combat_status_effect.dart`·`enemy_archetype.dart` + `lib/features/quest/domain/combat_action.dart`·`combat_enums_hive.dart` + 자동 생성 freezed/g.dart 14건. 수정: `hive_initializer.dart`·`static_data_provider.dart`·`combat_report_model.dart`.
- 2026-05-19T20:27:00+09:00: 페이즈 4 산출물 1 구현 완료 plan 작성 (`Docs/spec/[spec]20260519_m8b_combat_simulator_plan.md`, 9.6KB). `CombatSimulator` 순수 서비스 구현 완료.
- 2026-05-19T21:00:00+09:00: milestone-runner 재개 — 페이즈 4 산출물 2 매칭 완료. 다음 액션은 페이즈 4 산출물 3 "`QuestCompletionService` 통합 명세".
- 2026-05-19T21:35:00+09:00: 페이즈 4 산출물 1·2 검수 보완 완료. `CombatSimulationResult`에 `combatantSnapshots`/`enemySnapshots` HiveField 11~12를 추가하여 `CombatReport` 확장 필드와 연결 가능한 반환 계약을 마련했다. `CombatSimulator`는 탐험·조사·호위 목표 달성 시 `cObjectiveAchieved` 종료 조건을 반환하고, 사망 저항으로 부상 처리된 용병 액션은 `isKill=false`로 남긴다. 적 공격을 방패로 막은 파티 용병은 `shieldBlock` 결정적 장면 점수를 획득한다. 회귀 테스트 `combat_simulator_test.dart` 4개를 실제 시뮬레이션 호출 기반으로 보강했고, `dart run build_runner build --delete-conflicting-outputs`와 `dart format`을 실행했다.
- 2026-05-19T22:00:00+09:00: 페이즈 4 산출물 3 "QuestCompletionService 통합 명세" 완료 (`Docs/spec/[spec]20260519_m8b_quest_completion_integration.md`, 약 36KB, FR-1~FR-15 + Q-1~Q-8). spec-pipeline 흐름으로 spec-writer → verify-spec Opus 1회 PASS(15/15 REQ). 핵심 — `QuestCompletionService.calculate()` 시그니처에 `regionState: RegionState?` 1 인자 추가, `QuestCompletionResult`에 `combatSimulationEligible`/`simulationResult` 2 필드 추가, 내부 흐름 7단계 재구성, `_isChainSimulationStep`/`_factionReputation`/`_convertSimulationToMercDamages` 3 private static helper, `CombatReportService.generate(simulationResult:)` 시그니처 확장 + `CombatReport.HiveField 8~14` 최소 임베드, `quest_provider._completeQuest`에서 `chain_protagonist_id` 런타임 플래그 병합, 엘리트 유니크 위업/region_state trailing 2곳에 `resultType ∈ {success, greatSuccess}` guard, fail-soft fallback 5종.
- 2026-05-19T22:30:00+09:00: 페이즈 4 산출물 3 구현 완료 (`Docs/spec/[spec]20260519_m8b_quest_completion_integration_plan.md`). implement-agent 병렬 모드 4 TASK 모두 1회 PASS (TASK-1 [haiku]·TASK-3 [sonnet] 1단계 병렬 → TASK-2 [opus] → TASK-4 [sonnet]). PHASE 2.5 빌드 게이트 `flutter analyze` 0 issues + build_runner 불필요(모델 변경 없음). PHASE 3 풀 검증 verifier PASS(15/15 REQ) + flutter-reviewer APPROVE. 전체 테스트 593 PASS / 66 파일.
- 2026-05-20T00:00:00+09:00: finalize-feature 완료. 커밋 `56fa5b9 feat: m8b 페이즈 4 — 턴 전투 시뮬레이터/의존 모델/QuestCompletionService 통합`. 페이즈 4 #1·#2·#3 통합 커밋(35 신규 + 9 수정 코드 파일 + 6 spec/plan + Archive 통합 폴더 + CHANGELOG fragment + CLAUDE.md typeId 표/정적 데이터 테이블 카운트 37→40/게임 핵심 시스템 로직 갱신). `.claude/settings.local.json` 1줄은 환경 권한 설정으로 스테이징 제외.
- 2026-05-20T00:30:00+09:00: milestone-runner 재개 — 페이즈 4 산출물 3 매칭 완료. 다음 액션은 페이즈 4 산출물 4 "전투 보고서 UI 확장 명세".
- 2026-05-20T08:30:00+09:00: milestone-runner 재개 — 페이즈 4 산출물 4 매칭 완료. 명세(`Docs/spec/[spec]20260520_m8b_combat_report_ui.md`, 40.9KB) + 구현 plan(`Docs/spec/[spec]20260520_m8b_combat_report_ui_plan.md`, 6.0KB) + 구현 커밋(`ddc80eb`)까지 모두 완료. 다음 액션은 페이즈 4 산출물 5 "검증 및 밸런스 명세".
- 2026-05-20T09:00:00+09:00: 페이즈 4 산출물 5 "검증 및 밸런스 명세" 완료 (`Docs/Archive/20260520_m8b_validation_and_balance/spec.md`, 약 36KB, FR-1~FR-25 + Q-1~Q-10 + 부록 A/B/C). spec-pipeline 흐름으로 spec-writer Sonnet → verify-spec Opus 1회 **PASS** (5/5 항목). 핵심 — 5 검증 영역(결정성·결과 분포 / 부상·사망 빈도 / 로그 가독성 / 정적 검증 + 회귀 / M1~M8a 회귀), 페이즈 4 #3 부록 B 6 위임 항목 모두 처리(FR-20~FR-25), 신규 4~5 테스트 파일 + 기존 3~4 테스트 보강 약 43~46 신규 케이스 (baseline 602 → 약 645~650 예상), PR 차단(FR-12/13/14) vs 후속 산식 조정 트리거(FR-3/5/7.1 등) 분리 정책(Q-9). 페이즈 4 5/5 완료 → 페이즈 종료 체크포인트 + 마일스톤 완료 보고로 이동.
- 2026-05-20T18:53:00+09:00: 페이즈 4 산출물 5 구현 검수 보완 완료. `combat_simulator.dart`의 사망 저항 판정이 공격자 기준 `actor.isChainProtagonist(state)`를 전달하던 결함을 방어자 기준 `defender.isChainProtagonist(state)`로 수정하고, poisoned/bleeding DoT 사망 판정도 동일 기준으로 정리했다. `combat_simulator_death_resistance_test.dart`는 fail-soft `≤ 1.0` 검증을 제거하고 T1 전사 체인 주인공 공식(저항 40% → 70%) 기준 사망률 `≤ 0.40`으로 강화했다. `quest_completion_service_test.dart`의 FR-21은 실제 시뮬레이션 활성 의뢰에서 `LegendaryResultUpgrade`가 결과를 승격하지 않는지 검증하도록 보강했다.
- 2026-05-20T19:00:00+09:00: M8b 마일스톤 완료 보고. 상태 `completed` 전환. 완료 기준 7항목 모두 PASS. 구현 커밋 3개(`56fa5b9`·`ddc80eb`·`d06031c`), 테스트 669 PASS, `flutter analyze` 0 issues.
