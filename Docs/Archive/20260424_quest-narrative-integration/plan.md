# 퀘스트 서사 통합 구현 계획서

Skill used: implement-agent

## 구현 개요

`quest_narratives` 88행 데이터에서 `quest_type × result_type × is_elite` 매트릭스로 서사 템플릿을 선택하고, TemplateEngine으로 렌더링 후 `ActiveQuest.renderedNarrative`에 저장. 완료 팝업과 활동 로그에 서사를 표시.

## 태스크 실행 결과

| TASK | 내용 | 결과 |
|------|------|------|
| TASK-1 | `QuestNarrativeData` Freezed 모델 신규 생성 | 완료 |
| TASK-2 | `QuestPool.enemyName` 필드 추가 | 완료 |
| TASK-3 | `TemplateContext.enemyName` + Resolver `{quest.enemy}` 해결 | 완료 |
| TASK-4 | `ActiveQuest.renderedNarrative` HiveField(25) 추가 | 완료 |
| TASK-5 | `QuestCalculator.statWeightsFor()` public 메서드 | 완료 |
| TASK-6 | `QuestNarrativeService` 신규 생성 | 완료 |
| TASK-7 | StaticGameData + SyncService `quest_narratives` 등록 | 완료 |
| TASK-8 | `QuestCompletionService` 서사 렌더 + seed 통합 | 완료 |
| TASK-9 | `quest_provider` ActiveQuest 저장 + 활동 로그 통합 | 완료 |
| TASK-10 | `QuestResultDialog` 서사 영역 Container 삽입 | 완료 |
| TASK-11 | build_runner 코드 생성 | 완료 |
| TASK-12 | `QuestNarrativeService` 단위 테스트 (11개) | 완료 |
| TASK-13 | TemplateEngine 렌더 통합 테스트 (4개) | 완료 |
| 추가 | flutter-reviewer HIGH 이슈 수정 (위젯 추출 + 색상 상수화) | 완료 |

## 변경 파일 목록

### 신규 생성
| 파일 경로 | 변경 유형 | 설명 |
|-----------|-----------|------|
| `lib/core/models/quest_narrative_data.dart` | 신규 | Freezed 정적 모델 |
| `lib/features/quest/domain/quest_narrative_service.dart` | 신규 | pickTemplate / pickProtagonist / renderNarrative |
| `test/features/quest/domain/quest_narrative_service_test.dart` | 신규 | 단위 테스트 11개 |
| `test/features/quest/domain/quest_narrative_render_test.dart` | 신규 | 렌더 통합 테스트 4개 |

### 수정
| 파일 경로 | 변경 유형 | 설명 |
|-----------|-----------|------|
| `lib/core/models/quest_pool.dart` | 수정 | `enemyName` 필드 추가 |
| `lib/features/quest/domain/quest_model.dart` | 수정 | `renderedNarrative` HiveField(25) 추가 |
| `lib/features/quest/domain/quest_completion_service.dart` | 수정 | 서사 렌더 + seed 통합, `QuestCompletionResult.renderedNarrative` 추가 |
| `lib/features/quest/domain/quest_calculator.dart` | 수정 | `statWeightsFor()` public 메서드 추가 |
| `lib/features/quest/view/quest_result_dialog.dart` | 수정 | 서사 영역 Container 삽입, `_build*` → 위젯 클래스 추출, 색상 상수화 |
| `lib/core/data/sync_service.dart` | 수정 | `quest_narratives` 테이블 등록 |
| `lib/core/providers/static_data_provider.dart` | 수정 | `StaticGameData.questNarratives` 필드 추가 |
| `lib/core/domain/template_context.dart` | 수정 | `enemyName` 필드 추가 |
| `lib/core/domain/template_engine/resolver.dart` | 수정 | `{quest.enemy}` 해결 로직 (`ctx.enemyName ?? '적'`) |
| `lib/features/quest/domain/quest_provider.dart` | 수정 | ActiveQuest 저장 + 활동 로그 포맷 통합 |
| `lib/core/theme/app_theme.dart` | 수정 | 엘리트 색상 상수 6개 추가 |
| `lib/features/quest/view/dispatch_screen.dart` | 수정 | 엘리트 색상 리터럴 → AppTheme 상수 교체 |
| `lib/features/quest/view/dispatch_detail_page.dart` | 수정 | 엘리트 색상 리터럴 → AppTheme 상수 교체, Colors.green/red → AppTheme 교체 |

### 코드 생성 (build_runner)
| 파일 | 사유 |
|------|------|
| `lib/core/models/quest_narrative_data.freezed.dart` | 신규 Freezed |
| `lib/core/models/quest_narrative_data.g.dart` | 신규 JsonSerializable |
| `lib/core/models/quest_pool.freezed.dart` | enemyName 필드 추가 |
| `lib/core/models/quest_pool.g.dart` | enemyName 필드 추가 |
| `lib/features/quest/domain/quest_model.g.dart` | renderedNarrative 필드 추가 |
| `lib/core/domain/template_context.freezed.dart` | enemyName 필드 추가 |

### 기존 테스트 호환성 수정
| 파일 | 수정 내용 |
|------|-----------|
| `test/features/inventory/view/inventory_screen_test.dart` | `StaticGameData` 생성자에 `questNarratives: const []` 추가 |
| `test/features/quest/domain/quest_completion_service_test.dart` | 동일 |
| `test/features/quest/domain/special_flag_processor_test.dart` | 동일 |

## 주요 구현 결정사항

- **활동 로그 포맷**: `'퀘스트 "이름" 결과! — 서사'` (Q-1 사용자 승인 A안)
- **`{quest.enemy}` 해결**: TemplateContext.enemyName 사전 주입 방식 (옵션 A). resolver가 `ctx.enemyName ?? '적'` 반환
- **sectorChanges 타입**: `RegionState.sectorChanges`가 `Map<String, String>` 타입이므로 변환 불필요
- **체인 퀘스트 우회**: `quest.isChainQuest == true` 시 `renderNarrative` 즉시 null 반환
- **seed 생성**: `DateTime.now().millisecondsSinceEpoch + quest.id.hashCode`

## 검증 결과

**검증 모드**: 풀 검증 (TASK 13개)

| 라운드 | verifier | flutter-reviewer | 결과 |
|--------|----------|-----------------|------|
| 1차 | PASS | BLOCK (HIGH 3건) | FAIL |
| 2차 (HIGH 이슈 수정 후) | — | APPROVE | PASS |

**수정된 이슈 (1차 → 2차):**
- `_build*` private 메서드 → `_EliteLootSection`, `_MercStatusRow`, `_RewardRow` StatelessWidget 추출
- 엘리트 색상 리터럴 3개 파일 → `AppTheme.elite*` 상수 교체
- `Colors.green`/`Colors.red` → `AppTheme.success`/`AppTheme.criticalFailure` 교체

**잔여 LOW 이슈**: 그라디언트 보조 색상 리터럴 2곳 (`dispatch_screen.dart`, `dispatch_detail_page.dart`) — 차단 사유 아님, 다음 리팩토링 사이클 처리 권장

**최종 테스트**: 15/15 통과 (신규 테스트), flutter analyze No issues found
