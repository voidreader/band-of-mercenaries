# M8b 페이즈 4 #4 — 전투 보고서 UI 확장 구현 계획서

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260520_m8b_combat_report_ui.md`
> 실행 일자: 2026-05-20
> 마일스톤: M8b 페이즈 4 #4

## 1. 구현 결과 요약

`QuestResultDialog._buildDetailView`를 `CombatReport.schemaVersion == 1 && turns != null` 분기로 확장하여 M8b 시뮬레이션 라운드 로그·종료 조건 배지·objectiveProgress bar·결정적 장면 배지를 인라인 표시한다. M8a 보고서(`schemaVersion == null` 또는 `turns == null`)는 기존 details + Chip Wrap만 표시하여 자연 호환.

신규 widget 3종(`_CombatReportRoundLogSection`/`_RoundCard`/`_ActionLine`)과 file-scope private 헬퍼 9종(+ 1 typedef)을 같은 파일 내부에 응집 추가. 모델·Provider·Supabase·build_runner 변경 없음.

## 2. 변경 파일 목록

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/quest/view/quest_result_dialog.dart` | 수정 | `_buildDetailView`에 `isM8b` 분기 + `_CombatReportRoundLogSection` 인라인 삽입 / `_buildMercChip` protagonist Chip 강화(chainGold + bold) / file-scope 헬퍼 9종 + typedef 1종 추가 / private widget 3종 추가 / import 5개 추가(`combat_action`/`combat_turn`/`combatant_snapshot`/`enemy_snapshot`/`combat_enums_hive`). 642행 → 1095행 |
| `band_of_mercenaries/test/features/quest/view/quest_result_dialog_test.dart` | 신규 | 9개 위젯 테스트(VT-1~VT-6 + sub-case). 픽스처 빌더 7종 + `_pumpDialog` 헬퍼. `test/features/quest/view/` 디렉토리 신설. 683행 |

## 3. 실행 모드 및 검증 결과

### 실행 모드
- **병렬 모드** (TASK 수 2개 < 5). TASK-1·TASK-2 의존성으로 인해 순차 실행.

### 검증 모드
- **경량 검증** (TASK 수 2개 ≤ 2). main 직접 명세 검증 + flutter-reviewer 1회 호출.

### 검증 결과 요약

| 단계 | 결과 |
|------|------|
| PHASE 1 (planner) | 통합 계획 리포트 1회 출력 + REQ 13종 식별 + TASK 2종 분해 |
| PHASE 2 TASK-1 (coder) | PASS — analyze PASS, build_runner N/A |
| PHASE 2 TASK-2 (coder) | PASS — analyze PASS, 9/9 테스트 PASS |
| PHASE 2.5 빌드 게이트 | PASS — `flutter analyze` PASS + `flutter test` 602/602 PASS (593 + 9 신규) |
| PHASE 3 main 명세 검증 | PASS — REQ-1~REQ-13 모두 명세대로 구현 |
| PHASE 3 flutter-reviewer | APPROVE (with warnings) — medium 이슈 3건 |
| 폴리시 적용 후 재검증 | analyze PASS + 9/9 PASS |

### 해소된 이슈 (PHASE 3 폴리시 적용)

- **[ISSUE-2] [flutter-reviewer]** `_RoundCard.build`에서 `_selectBestActionForTurn` 중복 호출 → `_RoundCard` 시그니처에 `CombatAction action` 인자 추가. 부모(`_CombatReportRoundLogSection`)가 이미 선택한 action을 그대로 전달. `_RoundCard.build` 내부 재선택 + null guard 제거.
- **[ISSUE-3] [flutter-reviewer]** `report.details.length.clamp(4, 8).toInt()`의 불필요한 `.toInt()` 토캐스트 → `.clamp(4, 8)`로 정리(Dart 3 extension이 `int` 좁힘 반환).

### 후속 이월 이슈

- **[ISSUE-1] [flutter-reviewer]** 한국어 조사 처리(받침 분기) — `_ActionLine._buildLineText()` 4곳에서 `이/가`·`을/를` 받침 분기 미적용. 명세 외 polish 영역으로 reviewer가 후속 마일스톤 이월 가능하다고 명시. M8.5/M9에서 `_josa` 헬퍼 도입과 함께 일괄 처리 권장.

## 4. 핵심 시그니처

### file-scope 헬퍼

```dart
typedef _SelectedRoundAction = ({CombatTurn turn, CombatAction action});

bool _isM8bReport(CombatReport r) =>
    r.schemaVersion == 1 && r.turns != null;

String _exitConditionLabel(CombatExitCondition? c);  // 6 case switch + null fallback
Color _positionBorderColor(String position);          // 5 위치 → AppTheme 색상
bool _isKnownPosition(String position);               // 5종 in
String _resolveActorName(String actorId, List<CombatantSnapshot>, List<EnemySnapshot>, List<Mercenary>);
bool _isExposableAction(CombatAction a);              // 명세 §4.4 정합
int _actionPriority(CombatAction a);                  // 9단계 우선순위
_SelectedRoundAction? _selectBestActionForTurn(CombatTurn turn);
List<_SelectedRoundAction> _selectRoundActions(CombatReport report);  // lineBudget 적용
```

### 신규 private widget

```dart
class _CombatReportRoundLogSection extends StatelessWidget {
  final CombatReport report;
  final StaticGameData staticData;
  final List<Mercenary> mercs;
  final Color resultColor;
}

class _RoundCard extends StatelessWidget {
  final CombatTurn turn;
  final CombatAction action;  // 부모가 선택한 action을 그대로 전달 (ISSUE-2 해소)
  final List<CombatantSnapshot> combatantSnapshots;
  final List<EnemySnapshot> enemySnapshots;
  final List<Mercenary> mercs;
  final StaticGameData staticData;
}

class _ActionLine extends StatelessWidget {
  final CombatAction action;
  final String actorName;
  final String? targetName;
  final String? skillLabel;
  final String? statusEffectLabel;
  final String? decisiveLabel;
}
```

## 5. build_runner 재실행 필요 파일

없음. 모델 변경 없음.

## 6. CLAUDE.md 금지사항 준수 여부

위반 없음.

- ✓ 한국어 코멘트·UI 텍스트 유지 (조사 처리 polish는 ISSUE-1로 후속 위임)
- ✓ `Navigator.push` 없음 (상태 기반 인라인 전환 유지)
- ✓ `barrierDismissible: false` 유지 (`dispatch_screen.dart:232` 변경 없음)
- ✓ `AnimatedSwitcher(150ms)` 유지
- ✓ 인라인 hex 색상 도입 없음 (`AppTheme` 상수만 사용)
- ✓ feature 모듈 구조 준수 (view 계층 내 응집)
- ✓ 코멘트 정책 준수 (WHY 코멘트 최소화, 섹션 구분 주석 2개 한정)
- ✓ damageRoll·HP 절대값·rate% 등 비노출 항목 UI 미노출

## 7. 검증 명령

```bash
cd band_of_mercenaries && flutter analyze
cd band_of_mercenaries && flutter test
cd band_of_mercenaries && flutter test test/features/quest/view/quest_result_dialog_test.dart
```

모두 통과 상태(2026-05-20 기준 602/602 PASS).
