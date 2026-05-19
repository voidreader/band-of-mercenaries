# M8b 페이즈 4 #1 — CombatSimulator 순수 서비스 구현 plan

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260519_m8b_combat_simulator.md`
> 작성일: 2026-05-19
> 마일스톤: M8b 페이즈 4 #1 (CombatSimulator 순수 도메인 서비스)

## 1. 수립한 구현 계획과 실제 개발 사항

### 1.1 PHASE 1 통합 계획 (planner 결과 요약)

5개 TASK로 분해, 순차 격리 모드 적용:

| # | TASK | 복잡도 | 모델 |
|---|------|--------|------|
| 1 | `stable_seed.dart` FNV-1a 32-bit | mechanical | haiku |
| 2 | `combat_simulator_constants.dart` 매트릭스 상수 | mechanical | haiku |
| 3 | `combat_simulator.dart` 본체 (4 페이즈 + 산식 hook + 결정 트리 + 표적 결정 + 상태 효과 결합 + 메타데이터, 단일 파일) | **architecture** | **opus** |
| 4 | `stable_seed_test.dart` FNV-1a 결정성 테스트 | mechanical | haiku |
| 5 | `combat_simulator_test.dart` placeholder smoke | mechanical | haiku |

실행 순서: TASK-1·TASK-2 → TASK-3·TASK-4 → TASK-5.

### 1.2 실제 개발 결과

- 모든 5 TASK PASS (재시도 1회 — TASK-3 flutter-reviewer 5 이슈 외과적 수정 후 재리뷰 PASS)
- 빌드 게이트 0 issues
- PHASE 3-C final integration APPROVE

특이사항:
- TASK-1 coder가 TASK-4(테스트)도 함께 처리
- TASK-2 coder가 경로 prefix 누락(레포 루트 lib/)에 파일 생성 → main이 mv로 정상 위치로 복구

## 2. 변경 파일 목록

### 2.1 신규 생성 파일 (5개)

| 파일 경로 | 유형 | 설명 |
|-----------|------|------|
| `band_of_mercenaries/lib/core/util/stable_seed.dart` | 신규 (14행) | FNV-1a 32-bit `int stableSeed32(String)`. Dart hashCode 대체 결정성 보장 |
| `band_of_mercenaries/lib/features/quest/domain/combat_simulator_constants.dart` | 신규 (약 700행) | 17 그룹 매트릭스 상수 — 트레잇 키워드 8 / 직업군 12+종 / 환경 4 / 사망저항 / clamp 7 / 결정적 장면 9 / toneTags / 보고서 길이·5위치 / PRNG 도메인 키 12 prefix / AGI 계수 / 직업군 분류 |
| `band_of_mercenaries/lib/features/quest/domain/combat_simulator.dart` | 신규 (2338행) | `CombatSimulator.simulate({...}) → CombatSimulationResult?` 정적 서비스. 4 페이즈 + 60+ private static helper |
| `band_of_mercenaries/test/core/util/stable_seed_test.dart` | 신규 | 8 test PASS — FNV-1a 결정성·32-bit 범위·빈 문자열·유니코드·PRNG 도메인 키 분리 |
| `band_of_mercenaries/test/features/quest/domain/combat_simulator_test.dart` | 신규 | 1 smoke PASS — symbol export 확인. 본격 검증은 페이즈 4 #5 위임 |

### 2.2 수정 파일

없음 — 명세서 §3.1 명시. `QuestCompletionService`/`quest_provider`/`CombatReportService` 통합은 페이즈 4 #3 위임.

## 3. 실행 모드 / 검증 모드 / 결과 요약

### 3.1 실행 모드
- **순차 격리 모드** (TASK 수 5)
- 5개 TASK 모두 continuous execution
- coder → 미니 verifier → 미니 flutter-reviewer 사이클

### 3.2 검증 모드
- **PHASE 3-C 순차 격리 final integration sanity check**
- main 직접 통합 점검 + flutter-reviewer 1회 호출

### 3.3 결과 요약

| TASK | coder | verifier | flutter-reviewer | 비고 |
|------|-------|----------|------------------|------|
| TASK-1 | PASS | PASS | APPROVE | — |
| TASK-4 | PASS (TASK-1 coder가 동시 처리) | PASS | APPROVE | 8 test PASS |
| TASK-2 | PASS (경로 1회 mv 복구) | PASS (재검증) | APPROVE | 17 그룹 / 75 상수 |
| TASK-3 | PASS (1회 재작업) | PASS (with warnings, MVP 위임) | APPROVE (재리뷰 후) | 2348→2338행, 5 이슈 외과적 수정 |
| TASK-5 | PASS | PASS | APPROVE | 1 smoke PASS |
| PHASE 2.5 | analyze 0 issues | — | — | build_runner 불필요 |
| PHASE 3-C | — | (생략) | APPROVE | 8 통합 포인트 정합 |

전체 verifier PASS 5회 / flutter-reviewer APPROVE 5회 / 재시도 1회 (TASK-3).

수정된 이슈 목록 (TASK-3 재작업):
- **ISSUE-1** (medium): `_assignFormationIndices<T>` dynamic 캐스팅 → `_assignFormationIndicesParty`/`_assignFormationIndicesEnemy` 분리
- **ISSUE-2** (medium): `_statusEffectAdditive`/`_statusEffectMultiplicativeMod` 중복 → `_sumStatusIntensities` 단일 통합 + 호출처 7곳 교체
- **ISSUE-3** (medium): `as double` + `double.maxFinite` → `.clamp(1, 999999).toDouble()`
- **ISSUE-4** (low): dispel 죽은 삼항 → `(aoeAlly || party) ? allies : targets`
- **ISSUE-5** (low): 사기 도주 주석 → `// (e) 사기 도주 eFlee: M8b 페이즈 4 #5 위임.`

## 4. build_runner 재실행 필요 파일

없음. 본 사이클은 freezed/Hive 모델 신규 정의 0건. 페이즈 4 #2가 이미 모델·어댑터 처리.

`flutter analyze` 최종: 0 issues.

## 5. 명세 외 결정 사항 (verifier PASS with warnings 5건, 모두 명세 §4.2 MVP 단순화 허용)

verifier가 보고한 이슈는 모두 명세 §4.2 §주의사항 "MVP 단순화는 fail-soft 정합 범위 내 허용" 정신상 PASS:

| # | 이슈 | 심각도 | 위임 |
|---|------|--------|------|
| 1 | `dispelRng` 인스턴스 미생성 (결정론적 정렬로 대체) | low | 결과 정합. 향후 확률 dispel 도입 시 마련 |
| 2 | `battle_fury` extraAction immediate queue 미적용 (일반 행동 슬롯 사용) | medium | 페이즈 4 #5 정밀화 위임 |
| 3 | `skill_enemy_summon` 동적 전투원 추가 미구현 (스킬 발동만 마킹) | medium | 페이즈 4 #5 위임 |
| 4 | 사기 ±20 명세 vs ±10 구현 (brave/coward 단순 분기) | low | 직업군·세력 패시브 hook 페이즈 4 #5 |
| 5 | `endRoundIndex` 별도 필드 부재 (`roundIndex` 단일 필드로 의도 충족) | low | TASK-2 모델 책임 경계 |

추가 coder 결정사항 (명세 외 정책):
- `quest.chainProtagonistId` 부재 → `quest.specialFlags['chain_protagonist_id']` fallback (페이즈 4 #3 통합 위임)
- `EnemySnapshot.enemyKeywordKey` → archetype id fallback (toneTags용, 페이즈 3 #4 데이터 매칭 전제)
- `mezApply` 결정적 장면 점수 호출자 책임 위임
- `pool == null` 시 `quest.factionTag`/`quest.specialFlags` fallback (명세 §4.2 명시)

## 6. CLAUDE.md 금지사항 위반

위반 없음.
- ref/Hive/Provider 직접 접근 0건 (순수 함수)
- `Mercenary.injure/die` 직접 호출 0건 (마킹만)
- Dart `String.hashCode`/`Object.hashCode`/`DateTime.hashCode` 사용 0건 (`stableSeed32`만)
- PRNG 인스턴스 도메인 키별 매 액션 새 생성 (재사용 금지)

## 7. 핵심 시그니처 (Public API)

```dart
class CombatSimulator {
  CombatSimulator._();
  
  /// M8b 전투 시뮬레이터 진입점.
  /// `combatSimulationEligible` 게이트는 호출 측(페이즈 4 #3)이 담당.
  static CombatSimulationResult? simulate({
    required ActiveQuest quest,
    required List<Mercenary> partyMercs,
    QuestPool? pool,
    required StaticGameData staticData,
    required UserData userData,
    required List<FactionState> factionStates,
    RegionState? regionState,
    Map<String, EquipmentStatBonus> partyEquipmentBonuses = const {},
    int? seed,
  });
}
```

```dart
// FNV-1a 32-bit 안정 해시. String.hashCode 대체.
int stableSeed32(String input);
```

## 8. 후속 단계

본 명세 구현이 완료되어 다음 페이즈가 자연스럽게 이어진다:

1. **페이즈 4 #3 (QuestCompletionService 통합)**: `simulate()` 호출 흐름 + `combatSimulationEligible` 게이트 + 결과 통합 (`resultType`/`mercDamages` 오버라이드) + `CombatReportService.generate(..., simulationResult:)` 확장
2. **페이즈 4 #4 (UI)**: `CombatReport.schemaVersion == 1` 분기로 M8b 시뮬레이션 결과 표시
3. **페이즈 4 #5 (검증·테스트)**: 결정성·종료 조건·산식 hook 단위 테스트 정식 작성. medium 이슈 2건(battle_fury immediate / summon 동적 추가) 정밀화. 사기 ±20 모달 정밀화. 7 미사용 매트릭스 상수 활성화 (comboCompressionPriority/meleeRoles/rangedRoles/moraleFleeRatio/reportLengthByRoundCount/positionDistributionByLength/seedKeyDispel)

## 9. 명세서 매핑 표 (FR-1~FR-20 ↔ 구현 위치)

| FR | 구현 위치 |
|----|---------|
| FR-1~FR-3 (진입점) | `combat_simulator.dart:38~89` |
| FR-4 (출력 11 필드) | `combat_simulator.dart:466~478` |
| FR-5 (마킹만) | injure/die 호출 0건 (grep 확인) |
| FR-6 (Phase 1) | `_runPhase1` 54~262 |
| FR-7 (적 그룹) | `_buildEnemyGroup` 2032~2105 |
| FR-8 (Phase 2) | `_runPhase2` 268~300 |
| FR-9 (Phase 3) | `_runPhase3` 306~399 |
| FR-10 (Phase 4) | `_runPhase4` + protagonist/featured/toneTags 420~478, 1743~1836 |
| FR-10.2 (objectiveProgress) | `_computeObjectiveProgress` 1770~1790 |
| FR-11 (액션 산식) | `_resolveAction` + 6 hook 함수 |
| FR-11.5 (사망 저항) | `_resolveDeath` + clamp |
| FR-12 (PRNG 10) | 13 `Random(seed ^ stableSeed32(...))` (dispel은 결정론 대체) |
| FR-13 (트레잇 매트릭스) | `combat_simulator_constants.dart` + vigilant/huntsman 자동 부여 188~223 |
| FR-13.5 (환경 자동 부여) | `mist_field` → 적군 `debuff_accuracy_down` 169~186 |
| FR-14 (파티 9 단계) | `_selectPartySkill` 1043~1124 |
| FR-15 (적 9 단계) | `_selectEnemySkill` 1146~1190 |
| FR-16 (표적 정책) | `_selectTargets` + `_selectSingleEnemyByRole` + `_frontProtectedEnemies` 1210~1283 |
| FR-17 (상태 효과 부여) | `_applyStatusEffect` 1418~1500 |
| FR-17.5 (결합) | `_executeDispel` + `_sumStatusIntensities` |
| FR-18.5 (메타데이터) | `CombatAction` 6 필드 호출점들 |
| FR-19 (stableSeed32) | `core/util/stable_seed.dart` |
| FR-20 (fail-soft) | `simulate()` try/catch 54~89 + 필수 정적 데이터 가드 |
