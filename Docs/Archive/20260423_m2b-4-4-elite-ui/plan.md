# 엘리트 UI 구현 계획서

Skill used : implement-spec

## 구현 개요

M2b 4-3에서 구현된 엘리트 퀘스트/드랍 로직에 시각 피드백을 추가한다. 파견 카드 색상·배지, 파견 상세 서사 카드, 완료 팝업 드랍 섹션 3개 위치에 엘리트 2계층(보통/유니크) 구분 UI를 구현했다.

## 변경 파일 목록

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | 수정 | `EliteLootResult` import 추가; `pendingEliteLootProvider` 신규 StateProvider 추가; `_applyCompletionResult` 내 eliteLoot → provider 저장 코드 추가 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` | 수정 | `EliteLootResult` import 추가; `_buildQuestCard` 엘리트 사이드바·배지·이름색 분기; `_showResult`에서 pendingEliteLootProvider 읽기 → QuestResultDialog 전달 + 정리 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_detail_page.dart` | 수정 | `EliteMonsterData` import 추가; 헤더 Container 이후 엘리트 서사 카드 Builder 조건부 삽입 |
| `band_of_mercenaries/lib/features/quest/view/quest_result_dialog.dart` | 수정 | `EliteLootResult` import 추가; 생성자에 `EliteLootResult? eliteLoot` 파라미터 추가; `_buildEliteLootSection` 메서드 신규; 드랍 섹션 조건부 표시; 버튼 골드 합산 |

## 신규 생성 파일

없음

## build_runner 재실행 필요 파일

없음 (HiveField/Freezed/json_serializable 변경 없음)

## 구현 결과

- `pendingEliteLootProvider`: `pendingTraitEventsProvider` 패턴과 동일하게 구현
- `firstWhereOrNull` (collection 패키지) 대신 `.where(...).firstOrNull` Dart 내장 패턴 사용
- `flutter analyze`: No issues
- `flutter test`: 372/372 통과

## CLAUDE.md 금지사항 위반

없음
