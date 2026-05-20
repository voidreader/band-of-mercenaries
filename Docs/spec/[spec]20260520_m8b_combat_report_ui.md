# M8b 페이즈 4 #4 — 전투 보고서 UI 확장 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260519_m8b_combat_turn_structure.md` (페이즈 1 #1) — §M8a 전투 보고서와의 연결 / §보고서 라인이 시뮬레이션 라운드를 압축하는 방식
> - `Docs/balance-design/[balance]20260519_m8b_combat_log_exposure.md` (페이즈 2 #4) — §2 라운드 수 ↔ 보고서 길이 매트릭스 / §3 5 위치 분류 / §4 노출·비노출 매트릭스 / §6 가독성 검증 / §7 scope 7종 차등 / §11 보고서 라인 예시 / §12 UI 확장 명세 입력
> - `Docs/spec/[spec]20260519_m8b_phase4_models.md` (페이즈 4 #2) — CombatReport HiveField 8~14 / CombatantSnapshot / CombatTurn / CombatAction / StatusEffectEvent / EnemySnapshot
> - `Docs/spec/[spec]20260519_m8b_quest_completion_integration.md` (페이즈 4 #3) — [FR-9.1]/[FR-10.1] UI 표시 위임 정책 + §4.2 damageRoll 의미 변경 주의사항
> - 페이즈 3 #4 라인 풀: `Docs/content-data/[combat-log-template]20260519_m8b-combat-report-templates.md` (M8a 96 + M8b 85 = 181행, scope `combat_skill` 신규)
>
> 현행 코드:
> - `band_of_mercenaries/lib/features/quest/view/quest_result_dialog.dart` (642행 — `_QuestResultDialogState` / `_buildSummaryView` / `_buildDetailView` / `_CombatReportSummaryCard`)
> - `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart:230~234` (`showDialog`, `barrierDismissible: false`)
> - `band_of_mercenaries/lib/features/quest/domain/combat_report_model.dart` (typeId 21, HiveField 0~14)
> - `band_of_mercenaries/lib/core/theme/app_theme.dart` (보유 색상: chainGold·namedAccent·eliteAccent·eliteUniqueAccent·settlementAccent·tier3·tier4·dangerStable/Peaceful/Tension/Threat 등)
>
> 작성일: 2026-05-20
> 마일스톤: M8b 페이즈 4 #4 (전투 보고서 UI 확장 — 시뮬레이션 라운드 로그 인라인 표시)

## 1. 개요

`QuestResultDialog`의 상세 보고서 인라인 뷰(`_buildDetailView`)를 확장해, M8b 시뮬레이션이 영속한 라운드 로그(`CombatReport.turns`)·종료 조건(`exitCondition`)·진행도(`objectiveProgress`)·결정적 장면 메타(`CombatAction.decisiveKeywordKey` / `position`)를 노출한다. M8a 기존 보고서(`schemaVersion == null` 또는 `turns == null`)는 현행 UI를 그대로 유지하고, M8b 보고서(`schemaVersion == 1 && turns != null`)일 때만 신규 라운드 로그 섹션을 활성화한다.

본 명세는 UI 표시·인터랙션·테마에 한정한다. 보고서 생성·라운드 로그 압축·시뮬레이션 결과 영속은 페이즈 4 #1·#2·#3 명세에서 이미 완료되었다. 결과 다이얼로그 닫힘 이후 장기 재열람·연대기 통합은 M8b 범위 외(M8.5/M9 위임).

## 2. 요구사항

### 2.1 기능 요구사항

#### 2.1.1 schemaVersion 분기 정책

- **[FR-1]** `_buildDetailView` 진입 시 `report.schemaVersion`을 분기한다.
  - `report.schemaVersion == null || report.turns == null` → **M8a MVP 경로**: 기존 `_buildDetailView` 로직 그대로 (`report.details` 라인을 4px 좌측 보더 카드로 표시 + protagonist/featured Chip).
  - `report.schemaVersion == 1 && report.turns != null` → **M8b 시뮬레이션 경로**: 기존 요약 라인 카드 위에 라운드 로그 섹션(`_CombatReportRoundLogSection`)·종료 조건 배지·objectiveProgress 바·라운드 액션 라인을 추가한다.
  - 두 경로 모두 protagonist/featured Chip Wrap은 공통으로 유지한다.
  - 분기 판정은 외부 헬퍼 함수 `_isM8bReport(CombatReport)`로 추출하여 분기 일관성을 확보한다.

#### 2.1.2 인라인 전환 호환

- **[FR-2]** M8a 페이즈 4 #2에서 도입한 인라인 전환 패턴을 보존한다.
  - `_showDetail: bool` 상태 + `AnimatedSwitcher(duration: 150ms)`로 요약·상세 전환.
  - `ConstrainedBox(maxWidth: 520, maxHeight: 화면×0.82)` 유지.
  - `Navigator.push`로 별도 화면 진입 금지 (CLAUDE.md UI 제약).
  - `barrierDismissible: false` (`dispatch_screen.dart:232`) 유지. 확인 버튼만 dismiss.
  - 페이즈 4 #4 추가 콘텐츠는 모두 기존 `Flexible(child: SingleChildScrollView(...))` 내부에 인라인 배치한다. 신규 다이얼로그·BottomSheet·라우트 추가 금지.

#### 2.1.3 라운드 로그 표시 정책

- **[FR-3]** `report.turns` 리스트를 라운드 단위로 시각화하되, 원본 액션을 그대로 덤프하지 않고 압축 표시한다.
  - **후보 액션**: `turn.actions` 중 `position`이 5종(`entry`/`development`/`crisis`/`resolution`/`aftermath`) 중 하나이고 다음 중 하나를 만족하는 액션이다.
    - `isKill == true`
    - `decisiveKeywordKey != null`
    - `isComboCompression == true`
    - `isCrit == true`
    - `isShielded == true`
    - `isEvaded == true`
    - `actionKind == 'riposte'`
    - `actionKind == 'skipped_stunned'`
    - `actionKind == 'skill' && (skillId != null || statusEffectId != null)`
    - `actionKind == 'dot_tick' && statusEffectId != null && damage >= 1`
    - `damage >= 1`
  - **제외 대상**: `position`이 5종 외 값인 액션, `damage == 0`인 평범한 `basic_attack`, `isHit == false`이면서 `isEvaded == false`인 빗나간 공격, `statusEffectId == null`인 `dot_tick`은 노출하지 않는다.
  - **라운드별 선택**: 각 `CombatTurn`은 후보 액션 중 최대 1개만 표시한다. 한 라운드에 후보가 여러 개 있으면 아래 우선순위로 1개를 선택한다.
    1. `isKill`
    2. `decisiveKeywordKey != null`
    3. `isComboCompression`
    4. `isCrit`
    5. `isShielded` / `isEvaded` / `actionKind == 'riposte'`
    6. `actionKind == 'skill' && statusEffectId != null`
    7. `actionKind == 'dot_tick'`
    8. `damage` 내림차순
    9. 기존 액션 순서
  - **전체 표시 상한**: `lineBudget = report.details.isEmpty ? 4 : report.details.length.clamp(4, 8).toInt()`로 계산하고, 라운드 로그 액션 라인은 전체 `lineBudget`개를 초과하지 않는다. 단, `report.turns.length < lineBudget`이면 실제 선택된 라운드 수만큼만 표시한다.
  - **표시 단위**: 선택된 액션이 있는 라운드만 `R{roundIndex}` 헤더 + 하단 액션 라인으로 묶어 시각적 그룹화한다. 선제 라운드(`phase == 'initiative'`)는 `선제` 배지로 표시한다.

- **[FR-4]** 라운드 액션 라인 텍스트 구성.
  - `actor` / `target` 이름은 `combatantSnapshots` + `enemySnapshots`에서 lookup하여 표시한다(현재 `mercenaryListProvider`는 fallback).
    - 파티 actorId → `combatantSnapshots.firstWhere((s) => s.mercId == actorId).name`, 실패 시 `mercenaryListProvider`에서 시도, 모두 실패 시 actorId를 그대로 표시.
    - 적 actorId → `enemySnapshots.firstWhere((s) => s.instanceId == actorId).name`, 실패 시 actorId 그대로.
  - 액션 라인 본문은 `actionKind` 분기로 한국어 텍스트를 생성한다(템플릿 엔진 미사용 — 페이즈 3 라인 풀은 페이즈 4 #3에서 이미 `report.details`에 압축 반영되었음).
    - `basic_attack` + `isKill` → `"{actor}이 {target}을 쓰러뜨렸다"`
    - `basic_attack` + `isCrit` → `"{actor}의 치명타! {target}에게 {damage}의 피해"`
    - `basic_attack` + `isShielded` → `"{target}이 {actor}의 공격을 방패로 막아 {(shieldMitigation.clamp(0.0, 1.0)*100).toInt()}% 감소"`
    - `basic_attack` + `isEvaded` → `"{target}이 {actor}의 공격을 회피했다"`
    - `basic_attack` 그 외 → `"{actor}의 공격으로 {target}에게 {damage}의 피해"`
    - `skill` + `damage >= 1` → skillId로 staticData.combatSkills lookup 후 `"{actor}의 {skill.displayLabel} — {target}에게 {damage}의 피해"`. 미발견 시 `"{actor}의 스킬 — {target}에게 {damage}의 피해"`.
    - `skill` + `damage == 0` + `statusEffectId != null` → statusEffectId로 staticData.combatStatusEffects lookup 후 `"{actor}의 {skill.displayLabel} — {target}에게 {effect.displayLabel}"`. skill/effect 미발견 시 raw id 대신 각각 `"스킬"` / `"상태 효과"` fallback.
    - `skill` + `damage == 0` + `statusEffectId == null` → `"{actor}의 {skill.displayLabel}"`. 미발견 시 `"{actor}의 스킬"`.
    - `dot_tick` → statusEffectId로 staticData.combatStatusEffects lookup 후 `"{target}이 {effect.displayLabel}로 {damage}의 피해"`. 미발견 시 `"상태 효과"` fallback.
    - `skipped_stunned` → `"{actor}이 기절해 행동하지 못했다"`
    - `extra_action` → `"{actor}의 추가 행동"` (이후 `damage` 표기 포함)
    - `riposte` → `"{actor}의 반격으로 {damage}의 피해"`
  - **damageRoll(1.0/0.5/0.0)은 UI에 노출하지 않는다** (페이즈 4 #3 §4.2 주의사항).
  - 비노출 항목(명중률·회피율·치명타율·HP 절대값·intensity·actionScore·seed 등)은 절대 표시하지 않는다 (페이즈 2 #4 §4.2 매트릭스).

#### 2.1.4 5 위치 분류 시각 표현

- **[FR-5]** 5 위치(`entry`/`development`/`crisis`/`resolution`/`aftermath`)에 따라 라운드 액션 라인의 좌측 보더 색상을 차등한다.
  - `entry` → `AppTheme.textTertiary` (회색)
  - `development` → `AppTheme.textSecondary` (흰색/기본)
  - `crisis` → `AppTheme.dangerTension` (주황)
  - `resolution` → `AppTheme.chainGold` (금색)
  - `aftermath` → `AppTheme.textTertiary` (회색)
  - 헬퍼: `Color _positionBorderColor(String position)` 정적 매핑 (`AppTheme` 확장 또는 dialog 내부 private 함수).
  - 보더 두께는 기존 `_buildDetailView`의 details 카드와 동일하게 `width: 4`. `report.details` 라인의 보더(resultColor)와 시각적 위계 분리.

#### 2.1.5 결정적 장면 강조 배지

- **[FR-6]** `decisiveKeywordKey != null`인 액션은 라인 우측 끝에 결정적 장면 배지를 표시한다.
  - 배지 텍스트는 `staticData.combatReportKeywords`에서 `category == 'decisive' && key == decisiveKeywordKey`인 항목의 `displayText`를 우선 사용한다.
  - 키워드 lookup 실패 시 raw key를 사용자에게 노출하지 않고 `"결정적 장면"`을 표시한다. raw `decisiveKeywordKey`는 디버그 로그/개발자 도구 영역이 아니면 UI에 표시하지 않는다.
  - 배지 스타일: `Container` + `EdgeInsets.symmetric(horizontal: 6, vertical: 2)` + `AppTheme.chainGold.withValues(alpha: 0.15)` 배경 + `AppTheme.chainGold` 1px 테두리 + 11pt 텍스트.
  - `isKill == true`인 액션은 배지 없이도 텍스트 끝에 `'(처치)'` 접미사 추가.

#### 2.1.6 종료 조건 표시

- **[FR-7]** `report.exitCondition`을 라운드 로그 섹션 헤더 직하에 한국어 라벨 배지로 표시한다.
  - 매핑:
    - `aPartyWiped` → "파티 전멸"
    - `bEnemyWiped` → "적 전멸"
    - `cObjectiveAchieved` → "목표 달성"
    - `dRoundLimit` → "라운드 한계"
    - `eFlee` → "도주"
    - `fEscortDead` → "호위 대상 사망"
  - 헬퍼: `String _exitConditionLabel(CombatExitCondition?)` private 함수.
  - 배지 스타일: result_type 색상(`color` 매개변수와 동일) 배경 alpha 0.15 + 동일 색 테두리 + 12pt 폰트.
  - `exitCondition == null`인 경우 배지 자체를 미렌더링.

#### 2.1.7 objectiveProgress 표시

- **[FR-8]** `report.objectiveProgress != null && objectiveProgress > 0` 인 경우에만 progress bar를 렌더링한다.
  - **렌더 조건**: 의뢰 유형을 별도 분기하지 않고 값 기반으로 판단한다. 페이즈 4 #1 시뮬레이터가 objective 개념이 없는 의뢰에 `0.0`을 영속하므로, `objectiveProgress > 0`만으로 호위·탐험류 및 후속 objective 의뢰를 포괄한다.
  - **위젯**: `LinearProgressIndicator(value: objectiveProgress.clamp(0.0, 1.0), backgroundColor: AppTheme.surfaceAlt, valueColor: AlwaysStoppedAnimation(resultColor), minHeight: 6)` + 상단 라벨 "목표 진행도: {(progress*100).toInt()}%".
  - bar 좌우 패딩 8px, 상단 12px 여백, 라벨 우측 정렬.

#### 2.1.8 용병별 기여 표시

- **[FR-9]** 기존 protagonist/featured Chip Wrap을 유지하되 다음을 강화한다.
  - protagonist Chip은 `AppTheme.chainGold` 테두리 + `'주인공: {name}'` 라벨 + bold 폰트.
  - featured Chip은 `AppTheme.borderLight` 테두리 + `name` 라벨.
  - 본 명세는 데미지/킬 카운트 표시를 **포함하지 않는다**. M8a CombatReport 모델은 `featuredMercIds: List<String>`만 보유하고 기여 가중치를 영속하지 않으며, `turns` 리스트를 매번 재집계하는 비용 대비 가치가 낮다(페이즈 4 #1 §결정적 장면 가중치 표는 시뮬레이터 내부 결정용이며 영속 결과에 분해 저장되지 않음). 후속 마일스톤(M8.5)에서 보고서 카드 영상화·통계 화면 도입 시 확장 위임.
  - Chip 표시 영역은 라운드 로그 섹션 아래에 배치. 기존 `_buildDetailView`의 protagonist/featured Wrap 위치를 유지하고, 그 위에 라운드 로그 섹션을 삽입한다.

#### 2.1.9 _CombatReportSummaryCard 요약 카드 호환

- **[FR-10]** 요약 카드(`_CombatReportSummaryCard`)는 페이즈 4 #4 범위 외이며 변경하지 않는다.
  - 요약 카드는 `report.summary` 한 줄만 표시하고 "상세 보고서 보기" 버튼으로 인라인 전환을 트리거한다.
  - M8a/M8b 양쪽에서 동일 표시.
  - 단, 본 명세는 `_CombatReportDetailView`로 클래스를 분리하지 않고 **기존 `_buildDetailView` 메서드를 schemaVersion 분기로 확장**한다(코드 위치 응집).

#### 2.1.10 접근성·테마 일관성

- **[FR-11]** 모든 신규 색상은 `AppTheme`에서 가져온다. 인라인 hex 색상 금지.
  - 노란색·금색·주황색은 모두 `AppTheme.dangerTension` / `AppTheme.chainGold` / `AppTheme.eliteAccent` 중 선택.
  - 결과 색상(`color` 매개변수)은 `_resolveResultStyle`의 기존 매핑을 그대로 사용.
- **[FR-12]** 폰트 사이즈는 기존 `_buildDetailView`의 14pt 본문과 동일 또는 12pt 보조. 새 폰트 사이즈 도입 금지.
- **[FR-13]** 라운드 로그 섹션 자체가 빈 경우(turns 리스트가 empty 또는 노출 가능 액션 0개)에는 섹션 헤더 + exitCondition 배지만 표시하고 빈 라운드 카드는 렌더링하지 않는다. 빈 상태 placeholder 텍스트 금지.

### 2.2 데이터 요구사항

- 신규 Hive 박스: 없음
- 신규 정적 데이터 모델: 없음
- 기존 모델 활용:
  - `CombatReport.schemaVersion` (HiveField 8) — 분기 키
  - `CombatReport.turns` (HiveField 10) — 라운드 로그 source
  - `CombatReport.combatantSnapshots` (HiveField 9) — 파티 이름 lookup
  - `CombatReport.enemySnapshots` (HiveField 13) — 적 이름 lookup
  - `CombatReport.exitCondition` (HiveField 11) — 종료 조건 배지
  - `CombatReport.objectiveProgress` (HiveField 12) — progress bar
  - `CombatAction.actionKind` / `damage` / `isCrit` / `isShielded` / `isEvaded` / `isKill` / `position` / `decisiveKeywordKey` / `skillId` / `statusEffectId` / `shieldMitigation` — 라인 텍스트 + 보더 + 배지
  - `staticData.combatSkills` / `staticData.combatStatusEffects` — skill/effect displayLabel lookup
  - `staticData.combatReportKeywords` — decisive 배지 displayText lookup
- 신규 enum: 없음 (`CombatExitCondition`은 페이즈 4 #2에서 이미 정의됨)

### 2.3 UI 요구사항

- **화면 진입 조건**: `dispatch_screen.dart:230~234`의 기존 `showDialog<void>(barrierDismissible: false)` 흐름 그대로. 사용자가 요약 뷰에서 "상세 보고서 보기" 탭 → `_showDetail = true` → AnimatedSwitcher가 detail 뷰로 전환.
- **위젯 계층** (M8b 분기 시):
  ```
  Dialog
   └ ConstrainedBox(maxWidth: 520, maxHeight: 0.82h)
      └ Padding(20)
         └ AnimatedSwitcher(150ms)
            └ _buildDetailView (M8b 분기)
               └ Column(crossAxisAlignment: start)
                  ├ Row [back IconButton + 의뢰명 Title]
                  ├ SizedBox(12)
                  ├ Flexible
                  │   └ SingleChildScrollView
                  │      └ Column
                  │         ├ for line in report.details:
                  │         │   └ Container(좌측 보더 4px resultColor, surfaceAlt 배경)
                  │         │      └ Text(line, 14pt)
                  │         ├ SizedBox(16)
                  │         ├ _CombatReportRoundLogSection (신규 위젯)
                  │         │   ├ Row [헤더 '전투 라운드 로그' + ExitCondition Badge]
                  │         │   ├ (조건부) Column [progress 라벨 + LinearProgressIndicator]
                  │         │   └ for turn in 압축 선택된 turns(lineBudget 이하):
                  │         │      └ _RoundCard
                  │         │         ├ Row [R{i} 헤더 + 선제 배지(조건부)]
                  │         │         └ selectedAction:
                  │         │            └ _ActionLine
                  │         │               ├ Container(좌측 보더 4px positionBorderColor)
                  │         │               │  └ Row [Text(라인 본문) + 결정적 배지(조건부)]
                  │         ├ SizedBox(12)
                  │         └ Wrap [protagonist/featured Chips] (기존 유지)
                  ├ SizedBox(16)
                  └ ElevatedButton('닫기')
  ```
- **상태 변수**: `_showDetail: bool` (기존). 신규 상태 추가 없음.
- **화면 전환**: 인라인 전환만 (페이즈 4 #2에서 결정된 패턴 유지). Navigator.push 금지.
- **연출/애니메이션**: 기존 AnimatedSwitcher(150ms) 그대로. 라운드 로그 섹션 자체에 추가 애니메이션 없음.
- **테마**:
  - 좌측 보더 색상(5 위치): `AppTheme.textTertiary` (entry/aftermath), `AppTheme.textSecondary` (development), `AppTheme.dangerTension` (crisis), `AppTheme.chainGold` (resolution)
  - 결정적 배지: `AppTheme.chainGold` 테마
  - 종료 조건 배지: result color 기반 alpha 0.15
  - progress bar: `AppTheme.surfaceAlt` 배경 + result color valueColor

### 2.4 검증 요구사항

본 변경은 UI 분기와 표시 정책이 핵심이므로 widget test를 우선 추가한다. 테스트 작성이 과도하게 어려운 경우 최소한 helper 함수 단위 테스트를 분리 가능한 순수 함수로 작성한다.

- **[VT-1] M8a 호환**: `schemaVersion == null` 또는 `turns == null`인 보고서는 기존 details 라인과 protagonist/featured Chip만 표시하고, "전투 라운드 로그" 섹션을 표시하지 않는다.
- **[VT-2] M8b 분기**: `schemaVersion == 1 && turns != null`인 보고서는 "전투 라운드 로그" 섹션, 종료 조건 배지, 선택된 라운드 액션을 표시한다.
- **[VT-3] 표시 상한**: 한 보고서에 `damage >= 1` 액션이 20개 이상 있어도 라운드 액션 라인은 `lineBudget = report.details.isEmpty ? 4 : report.details.length.clamp(4, 8).toInt()`를 초과하지 않는다.
- **[VT-4] decisive 라벨**: `staticData.combatReportKeywords`에 매칭되는 decisive key가 있으면 `displayText`를 표시하고 raw key 문자열은 표시하지 않는다. 매칭 실패 시 `"결정적 장면"`을 표시한다.
- **[VT-5] 비노출 항목**: 다이얼로그 텍스트에 `damageRoll`, seed, HP 절대값, `actionScore`, 명중률/회피율/치명타율 %가 표시되지 않는다.
- **[VT-6] fallback 안정성**: `combatantSnapshots`, `enemySnapshots`, skill/effect 정적 데이터가 누락되어도 다이얼로그 렌더링이 throw 없이 완료된다.
- **[VT-7] 기본 검증 명령**: `band_of_mercenaries/`에서 `flutter analyze`와 관련 테스트(`flutter test test/features/quest/...`)를 통과해야 한다.

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/quest/view/quest_result_dialog.dart` | `_buildDetailView`에 schemaVersion 분기 추가 + 신규 private 헬퍼 메서드(`_isM8bReport`, `_exitConditionLabel`, `_positionBorderColor`, `_buildRoundLogSection`, `_buildRoundCard`, `_buildActionLine`) 추가. private widget class `_CombatReportRoundLogSection` / `_RoundCard` / `_ActionLine` 신규 추가. combatant/enemy 이름 lookup 헬퍼 추가. | M8b 시뮬레이션 라운드 로그 인라인 표시 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| 없음 | 모든 신규 위젯은 `quest_result_dialog.dart` 내부에 private 클래스로 추가 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| 없음 | 모델 변경 없음 |

### 3.4 관련 시스템

- **QuestResultDialog (`quest_result_dialog.dart`)**: 신규 detail 분기 + 라운드 로그 섹션 + 종료 조건 배지 + objectiveProgress bar 추가.
- **CombatReport 모델 (`combat_report_model.dart`)**: HiveField 8~14 활용 (변경 없음).
- **CombatSimulator (페이즈 4 #1)**: 영속한 `turns`/`combatantSnapshots`/`enemySnapshots`/`exitCondition`/`objectiveProgress`가 입력. 변경 없음.
- **CombatReportService (페이즈 4 #3)**: `report.details` 압축 라인을 그대로 활용. 변경 없음.
- **StaticGameData (`staticDataProvider`)**: `combatSkills` / `combatStatusEffects` lookup. 변경 없음.
- **CombatReportKeyword (`combat_report_keywords`)**: `decisiveKeywordKey`의 사용자 표시 라벨 lookup. 모델·동기화 변경 없음.
- **mercenaryListProvider**: 파티 이름 fallback lookup. 변경 없음.
- **dispatch_screen.dart**: showDialog 호출자. 변경 없음 (현행 `barrierDismissible: false` 유지).

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `quest_result_dialog.dart:284~379` (`_buildDetailView`) — 본 명세에서 schemaVersion 분기로 확장하는 메서드. 기존 details 라인 카드 패턴(`Container` + 좌측 보더 + `surfaceAlt` 배경)을 라운드 액션 라인에서도 재사용한다.
- `quest_result_dialog.dart:577~641` (`_CombatReportSummaryCard`) — 요약 카드 패턴. 색상·여백·테두리 일관성 참조.
- `quest_result_dialog.dart:400~471` (`_EliteLootSection`) — 컨테이너 헤더+배지+리스트 패턴. `_CombatReportRoundLogSection`의 외곽 컨테이너 구조 참조.
- `app_theme.dart:121~135` (`dangerLevelColor`/`dangerLevelLabel`) — enum → 색상·라벨 매핑 헬퍼 패턴. `_exitConditionLabel`도 동일 switch 식 패턴 적용.
- `lib/features/movement/view/movement_screen.dart` — `RegionStatusBadgeRow` 배지 패턴(`Container` + alpha 배경 + 테두리 + 12pt 텍스트) 참조.

### 4.2 주의사항

- **schemaVersion 호환성**: M8a 보고서는 `schemaVersion == null` + `turns == null`이다. 신규 분기 조건은 반드시 두 필드 모두 null이 아님을 확인해야 한다. 한쪽만 null인 비정상 데이터(시뮬레이터 fail-soft fallback이 부분 영속된 경우)도 M8a 경로로 처리한다.
- **damageRoll UI 노출 금지**: 페이즈 4 #3 §4.2 — `damageRoll`(1.0/0.5/0.0)은 시뮬레이션 → mercDamage 변환 중간값이며 보고서 영속에 포함되지 않는다. UI에 노출할 필드가 없으므로 자연 호환되지만 향후 모델 확장 시에도 노출하지 않는다.
- **mercenary 이름 lookup 우선순위**: `combatantSnapshots`가 출시 시점 이름 동결값이므로 우선. `mercenaryListProvider`는 사망·방출된 용병 fallback. 둘 다 미발견 시 actorId 그대로 표시(에러 throw 금지).
- **CLAUDE.md UI 제약 준수**: `Navigator.push` 금지, 상태 기반 렌더링만, 신규 화면 라우트 추가 금지.
- **AppTheme 일관성**: 인라인 hex 색상 도입 금지. 신규 색상이 필요하면 `AppTheme`에 상수로 추가하고 본 명세에 명시. 현재 명세는 신규 색상 도입 없음(기존 chainGold·dangerTension·textSecondary·textTertiary 재사용).
- **빈 turns 리스트**: 시뮬레이터 fail-soft + 부분 영속 케이스에서 `turns == []`일 수 있다. `report.turns?.isEmpty == true` 또는 노출 가능 액션이 0개인 경우 빈 카드 미렌더링 ([FR-13]).
- **scope `combat_skill` 라인**: 페이즈 3 #4에서 추가된 라인 풀의 `scope == 'combat_skill'` 라인들은 페이즈 4 #3 `CombatReportService.generate()`에서 이미 `report.details`에 압축 반영된 상태로 입력된다. 본 UI 명세는 `report.details`를 그대로 표시하면 충분하다. 라인 풀의 scope 필드를 UI에서 직접 참조하지 않는다.
- **details 라인 위치 색상**: 페이즈 2 #4 §12.2의 "상세 라인 위치별 색상"은 `CombatReportService`가 생성한 상세 라인이 `combat_report_templates.tags_json.position`과 1:1로 복원 가능할 때 적용할 수 있다. 현 `CombatReport`에는 렌더된 `details`와 `templateIds`만 있으며, fallback details에는 templateId가 없을 수 있다. 본 페이즈에서는 기존 `report.details` 보더는 resultColor로 유지하고, 라운드 로그 액션 라인에만 `CombatAction.position` 기반 위치 색상을 적용한다. details 위치별 보더는 M8.5에서 `templateIds` 정합 검증 후 확장한다.
- **`isShielded == true && shieldMitigation == 0.0`**: 시뮬레이터 가능한 엣지 케이스(방패 발동했으나 감소율 0). 보드(`30% 감소`) 표시 시 `shieldMitigation.clamp(0.0, 1.0)` 적용 후 `(value * 100).toInt()`로 변환. 0 표시도 그대로 허용(거짓 부정 방지).

### 4.3 엣지 케이스

- **report.turns 전부 unfit**: 모든 액션이 노출 대상에서 제외되어 노출 가능 액션 0개. → 라운드 로그 섹션 헤더 + exitCondition 배지 + (조건부) progress bar만 렌더링. 빈 라운드 카드 생성 금지.
- **report.combatantSnapshots == null 이지만 turns != null**: 비정상 영속 (시뮬레이터 부분 fail). 이름 lookup이 모두 fallback(`mercenaryListProvider` → actorId raw)으로 동작. throw 금지.
- **enemy actorId가 어떤 enemySnapshots에도 없음**: 시뮬레이터 fail-soft 부분 영속. actorId 그대로 표시.
- **statusEffectId가 staticData.combatStatusEffects에 없음**: optionalTables 미시드 환경. raw id 대신 `"상태 효과"` fallback 표시.
- **skillId가 staticData.combatSkills에 없음**: 동일. raw id 대신 `"스킬"` fallback 표시.
- **report.exitCondition은 set이지만 turns가 null**: 비정상 영속. M8a 경로로 처리 ([FR-1] 조건 — turns null이면 M8a).
- **objectiveProgress == 0.0 + exitCondition == cObjectiveAchieved**: 시뮬레이터 0 도달 후 즉시 종료. progress bar 미표시 (조건 `progress > 0`로 게이트).
- **objectiveProgress > 1.0**: 시뮬레이터 버그. `clamp(0.0, 1.0)` 적용 후 100% 표시.
- **report.details가 empty + turns != null**: 페이즈 4 #3 [FR-9.1]/[FR-10.1] UI 위임 정책 — details 카드 미렌더링하되 라운드 로그 섹션은 정상 표시.
- **dispatch_screen.dart의 barrierDismissible**: 다이얼로그 외부 탭으로 닫히지 않는 정책 변경 없음.

### 4.4 구현 힌트

- **진입점**: `_QuestResultDialogState._buildDetailView` (line 284). 이 메서드의 본문을 schemaVersion 분기 + M8b 경로 추가로 확장.
- **데이터 흐름**:
  ```
  ActiveQuest.combatReport (HiveField 27, M8a)
    → CombatReport.schemaVersion + turns + exitCondition + objectiveProgress 등 (HiveField 8~14, M8b)
    → _buildDetailView 분기
      → M8b: _CombatReportRoundLogSection 렌더
      → M8a: 기존 details + Chip Wrap 그대로
  ```
- **참조 구현**:
  - `quest_result_dialog.dart:319~347` — Flexible/SingleChildScrollView 내부 Column + Container 카드 패턴.
  - `quest_result_dialog.dart:328~338` — `BorderSide(color: resultColor, width: 4)` 좌측 보더 패턴.
  - `quest_result_dialog.dart:349~364` — `Wrap` + Chip 패턴.
  - `app_theme.dart:121~135` — switch 식으로 enum → 색상·라벨 매핑.
- **확장 지점**:
  - `_buildDetailView` 시작점에 schemaVersion 분기 추가.
  - 기존 `for (final line in report.details)` 블록 직후 `if (_isM8bReport(report)) ... _CombatReportRoundLogSection(...)` 삽입.
  - protagonist/featured Wrap 위치 유지.
  - private 헬퍼 메서드(static + nullable 인자)를 `_QuestResultDialogState` 내부에 추가.
- **신규 위젯 시그니처** (모두 private, 같은 파일 내부):
  ```dart
  class _CombatReportRoundLogSection extends StatelessWidget {
    final CombatReport report;
    final StaticGameData staticData;
    final List<Mercenary> mercs;
    final Color resultColor;
    const _CombatReportRoundLogSection({
      required this.report,
      required this.staticData,
      required this.mercs,
      required this.resultColor,
    });
  }

  class _RoundCard extends StatelessWidget {
    final CombatTurn turn;
    final List<CombatantSnapshot> combatantSnapshots;
    final List<EnemySnapshot> enemySnapshots;
    final List<Mercenary> mercs;
    final StaticGameData staticData;
    const _RoundCard({
      required this.turn,
      required this.combatantSnapshots,
      required this.enemySnapshots,
      required this.mercs,
      required this.staticData,
    });
  }

  class _ActionLine extends StatelessWidget {
    final CombatAction action;
    final String actorName;
    final String? targetName;
    final String? skillLabel;
    final String? statusEffectLabel;
    final String? decisiveLabel;
    const _ActionLine({
      required this.action,
      required this.actorName,
      this.targetName,
      this.skillLabel,
      this.statusEffectLabel,
      this.decisiveLabel,
    });
  }
  ```
- **헬퍼 함수**:
  ```dart
  typedef _SelectedRoundAction = ({CombatTurn turn, CombatAction action});

  bool _isM8bReport(CombatReport r) =>
      r.schemaVersion == 1 && r.turns != null;

  String _exitConditionLabel(CombatExitCondition? c) => switch (c) {
    CombatExitCondition.aPartyWiped => '파티 전멸',
    CombatExitCondition.bEnemyWiped => '적 전멸',
    CombatExitCondition.cObjectiveAchieved => '목표 달성',
    CombatExitCondition.dRoundLimit => '라운드 한계',
    CombatExitCondition.eFlee => '도주',
    CombatExitCondition.fEscortDead => '호위 대상 사망',
    null => '',
  };

  Color _positionBorderColor(String position) => switch (position) {
    'entry' || 'aftermath' => AppTheme.textTertiary,
    'development' => AppTheme.textSecondary,
    'crisis' => AppTheme.dangerTension,
    'resolution' => AppTheme.chainGold,
    _ => AppTheme.textTertiary,
  };

  bool _isKnownPosition(String position) => switch (position) {
    'entry' || 'development' || 'crisis' || 'resolution' || 'aftermath' => true,
    _ => false,
  };

  String _resolveActorName(
    String actorId,
    List<CombatantSnapshot> combatantSnapshots,
    List<EnemySnapshot> enemySnapshots,
    List<Mercenary> mercs,
  ) {
    final combatant =
        combatantSnapshots.where((s) => s.mercId == actorId).firstOrNull;
    if (combatant != null) return combatant.name;
    final enemy =
        enemySnapshots.where((s) => s.instanceId == actorId).firstOrNull;
    if (enemy != null) return enemy.name;
    final merc = mercs.where((m) => m.id == actorId).firstOrNull;
    if (merc != null) return merc.name;
    return actorId;
  }

  bool _isExposableAction(CombatAction a) {
    if (!_isKnownPosition(a.position)) return false;
    if (a.actionKind == 'dot_tick') {
      return a.statusEffectId != null && a.damage >= 1;
    }
    if (a.actionKind == 'skipped_stunned') return true;
    if (a.actionKind == 'riposte') return true;
    if (a.isKill || a.isCrit || a.isShielded) return true;
    if (a.isEvaded) return true;
    if (a.decisiveKeywordKey != null) return true;
    if (a.isComboCompression) return true;
    if (a.actionKind == 'skill' &&
        (a.skillId != null || a.statusEffectId != null)) return true;
    if (a.damage >= 1) return true;
    return false;
  }

  int _actionPriority(CombatAction a) {
    if (a.isKill) return 900;
    if (a.decisiveKeywordKey != null) return 800;
    if (a.isComboCompression) return 700;
    if (a.isCrit) return 600;
    if (a.isShielded || a.isEvaded || a.actionKind == 'riposte') return 500;
    if (a.actionKind == 'skill' && a.statusEffectId != null) return 400;
    if (a.actionKind == 'dot_tick') return 300;
    return 100 + a.damage.clamp(0, 99);
  }

  _SelectedRoundAction? _selectBestActionForTurn(CombatTurn turn) {
    final candidates = turn.actions.where(_isExposableAction).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final priority = _actionPriority(b).compareTo(_actionPriority(a));
      if (priority != 0) return priority;
      return b.damage.compareTo(a.damage);
    });
    return (turn: turn, action: candidates.first);
  }

  List<_SelectedRoundAction> _selectRoundActions(CombatReport report) {
    final turns = report.turns ?? const <CombatTurn>[];
    final lineBudget = report.details.isEmpty
        ? 4
        : report.details.length.clamp(4, 8).toInt();
    return turns
        .map(_selectBestActionForTurn)
        .whereType<_SelectedRoundAction>()
        .take(lineBudget)
        .toList(growable: false);
  }
  ```

## 5. 기획 확인 사항

- **[Q-1]** 라운드 로그 섹션을 신규 private widget 클래스로 분리할지, `_buildDetailView` 내부 `Widget`으로 인라인 작성할지?
  → 처리 방향(본 명세 채택): **private widget 클래스 3종 분리** (`_CombatReportRoundLogSection` / `_RoundCard` / `_ActionLine`). 이유: (a) `_EliteLootSection` 등 기존 패턴과 정합, (b) 단일 메서드가 비대해지지 않도록, (c) 향후 M8.5 단독 화면 추출 시 그대로 이전 가능. 모두 같은 파일 내부 private (`_` 접두) 유지.

- **[Q-2]** 결정적 장면 배지 텍스트에 raw `decisiveKeywordKey`(예: `shield_opens_path`) 그대로 표시할지, 한국어 라벨로 변환할지?
  → 처리 방향(본 명세 채택): **`combat_report_keywords.displayText`를 우선 표시**. 이유: (a) `StaticGameData`가 이미 `combatReportKeywords`를 제공하므로 신규 모델·동기화 변경이 필요 없다, (b) 사용자 UI에 raw key를 노출하면 보고서 몰입감이 떨어진다, (c) lookup 실패 시 `"결정적 장면"` fallback으로 안정성을 유지할 수 있다. raw key 표시는 디버그 로그나 개발자 도구 영역으로 제한한다.

- **[Q-3]** 데미지/킬 카운트 등 용병별 기여 통계를 표시할지?
  → 처리 방향(본 명세 채택): **미표시**. 이유: (a) `CombatReport.featuredMercIds`만 영속되고 기여 가중치는 영속되지 않음, (b) `turns` 재집계는 비용 대비 가치가 낮고 다이얼로그 렌더 부담 증가, (c) M8.5 보고서 영상화·통계 화면 도입 시 카운트 집계 + 막대 차트 등 종합 UI로 확장 위임.

- **[Q-4]** 라운드 로그 섹션의 라운드 카드 최대 개수 제한이 필요한가?
  → 처리 방향(본 명세 채택): **전체 `lineBudget` 상한을 둔다**. 시뮬레이터는 최대 9라운드(선제 1 + 일반 최대 8)를 영속하지만 각 라운드에 여러 `CombatAction`이 존재하므로, UI는 라운드별 최대 1액션 + 전체 `lineBudget` 상한으로 압축한다. 이 정책이 페이즈 2 #4의 4~8줄 가독성 목표와 정합한다.

- **[Q-5]** `_CombatReportSummaryCard`(요약 카드) 자체에 M8b 분기 표시(예: "시뮬레이션 보고서" 배지)를 추가할지?
  → 처리 방향(본 명세 채택): **미추가**. 요약 카드는 페이즈 4 #4 범위 외이며, 사용자 인지 시점은 상세 보고서 진입 후. 요약 카드의 정보 밀도 유지가 우선이며, 요약 텍스트(`report.summary`) 자체가 시뮬레이션·M8a 보고서 모두 동일 톤으로 작성됨.

- **[Q-6]** progress bar 표시 조건을 의뢰 유형(escort/explore)으로 게이트할지, objectiveProgress 값 자체로 게이트할지?
  → 처리 방향(본 명세 채택): **값 기반 게이트** (`objectiveProgress != null && progress > 0`). 이유: (a) 호위·탐험 의뢰 식별 로직(`quest.questTypeId`)이 다이얼로그에 이미 있지만 페이즈 4 #1 시뮬레이터가 호위·탐험 외 의뢰에 objectiveProgress를 0.0으로 영속하므로 자연스럽게 0인 케이스가 걸러짐, (b) 향후 새로운 의뢰 유형이 objective 개념을 도입할 때 추가 분기 불필요.

- **[Q-7]** 종료 조건 배지 색상을 결과 색상(result_type)으로 통일할지, exitCondition별 색상을 별도로 매핑할지?
  → 처리 방향(본 명세 채택): **결과 색상 통일** (`color` 매개변수 alpha 0.15 배경). 이유: (a) result_type ↔ exitCondition은 1:1이 아닌 1:다 관계(예: `dRoundLimit` → success/failure 분기), (b) 색상이 중복 정보를 전달하면 UI 노이즈, (c) 라운드 액션 라인의 5 위치 보더가 이미 위치별 색상 강조 역할.

- **[Q-8]** `report.details`의 결과 색상 보더(현재 width: 4)와 라운드 액션 라인의 5 위치 보더(width: 4) 색상이 동시에 표시될 때 시각적 혼동이 없는지?
  → 처리 방향(본 명세 채택): **위계 분리로 해결**. (a) `report.details` 라인은 보고서의 종합 라인 풀(상위 위계, resultColor 보더), (b) 라운드 액션 라인은 5 위치 메타 강조(하위 위계, 위치별 색상 보더). 두 섹션을 `SizedBox(height: 16)`으로 구분하고 라운드 로그 섹션을 별도 `Container` outerBorder로 감싸 시각적 위계 차별화. 색상 혼동 방지는 라운드 로그 섹션 헤더(`'전투 라운드 로그'` Text + 색상 강조)가 이중 안전망.

---

## 부록 A: 페이즈 2 #4 ↔ 본 명세 매핑 표

| 페이즈 2 #4 항목 | 본 명세 반영 위치 |
|----------------|---------------|
| §2.2 길이 결정 트리 | [FR-3] 표시 라인 상한 = `report.details.isEmpty ? 4 : report.details.length.clamp(4, 8).toInt()` |
| §3.1 5 위치 정의 | [FR-5] 좌측 보더 5색 매핑 |
| §3.2 보고서 길이별 5 위치 분포 | (보고서 생성 시 페이즈 4 #3 측에서 결정, UI 미관여) |
| §4.1 노출 항목 | [FR-4] 액션 라인 텍스트 — damage·crit·shield·evasion·dot·skill·effect label 표시 |
| §4.2 비노출 항목 | [FR-4] 명시적 금지 — damageRoll·intensity·HP 절대값·rate% 미노출 |
| §6.3 protagonist/featured 라인 우선순위 | [FR-9] protagonist Chip 강조 (chainGold + bold) |
| §6.4 톤 키워드 분포 (decisive 12) | [FR-6] `decisiveKeywordKey` 우측 배지 (`combat_report_keywords.displayText` 우선) |
| §7 scope 7종 차등 | (보고서 생성 시 페이즈 4 #3 측에서 결정, UI 미관여) |
| §11.1~§11.3 보고서 라인 예시 | (가독성 참조용 — 실제 라인은 `report.details`로 입력) |
| §12.1 노출 매트릭스 정합 | [FR-4] / [FR-11] 그대로 적용 |
| §12.2 보고서 라인 표시 정책 | [FR-5] 위치별 보더, [FR-6] decisive 배지, [FR-9] protagonist 강조 |
| §12.3 인라인 전환 호환 | [FR-2] 150ms AnimatedSwitcher 유지 |

## 부록 B: 페이즈 4 #2 데이터 모델 ↔ 본 명세 사용 매핑

| 페이즈 4 #2 필드 | 본 명세 사용 |
|---------------|------------|
| `CombatReport.schemaVersion` | [FR-1] 분기 키 |
| `CombatReport.turns` | [FR-3] 라운드 로그 source |
| `CombatReport.combatantSnapshots` | [FR-4] 파티 이름 lookup |
| `CombatReport.enemySnapshots` | [FR-4] 적 이름 lookup |
| `CombatReport.exitCondition` | [FR-7] 종료 조건 배지 |
| `CombatReport.objectiveProgress` | [FR-8] progress bar |
| `CombatReport.statusEffectHistory` | (본 명세에서 미사용 — `turns.actions` 내 `dot_tick` + `statusEffectId`로 충분) |
| `CombatTurn.roundIndex` | [FR-3] R{i} 헤더 |
| `CombatTurn.phase` | [FR-3] 선제 라운드 배지 |
| `CombatTurn.actions` | [FR-3] 노출 가능 액션 필터 + 라인 렌더 |
| `CombatAction.actorId` / `targetIds` | [FR-4] 이름 lookup |
| `CombatAction.actionKind` | [FR-4] 분기 텍스트 |
| `CombatAction.skillId` / `statusEffectId` | [FR-4] staticData displayLabel lookup |
| `CombatAction.damage` / `isCrit` / `isShielded` / `isEvaded` / `isKill` / `shieldMitigation` | [FR-4] 라인 텍스트 |
| `CombatAction.position` | [FR-5] 좌측 보더 색상 |
| `CombatAction.decisiveKeywordKey` | [FR-6] 우측 배지 |
| `CombatAction.isComboCompression` | [FR-3] 노출 우선순위 |
| `CombatExitCondition` (enum 6종) | [FR-7] 한국어 라벨 매핑 |
| `PositionRow` (enum 3종, snapshot 포함) | (본 명세에서 미사용 — UI는 진형 직접 노출 금지, 페이즈 2 #4 §4.2) |
| `BehaviorPattern` (enum 6종, CombatAction.behaviorPattern) | (본 명세에서 미사용 — 액터가 적임을 식별하는 내부 메타, UI 노출 없음) |
