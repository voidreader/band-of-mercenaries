# 이동 선택지 시스템 구현 계획서

Skill used: implement-agent

## 구현 개요

이동 완료 시점에 회상 팝업을 표시하고, 플레이어가 선택지를 고르면 결과 서사와 효과를 적용하는 시스템. `travel_choice_events` / `travel_choice_options` / `travel_choice_results` 3개 정적 테이블을 Supabase에서 동기화하고, `TravelChoiceService` 순수 서비스로 롤링·필터링·결과 해소를 처리. `pendingTravelChoiceProvider` StateProvider 이벤트 채널로 도메인→뷰 계층 전달.

## 태스크 실행 결과

| TASK | 내용 | 결과 |
|------|------|------|
| TASK-1 | `TravelChoiceEventData` Freezed 모델 생성 | 완료 |
| TASK-2 | `TravelChoiceOptionData` Freezed 모델 생성 | 완료 |
| TASK-3 | `TravelChoiceResultData` Freezed 모델 생성 + fallbackResult | 완료 |
| TASK-4 | `SyncService` allTables 3개 테이블 등록 | 완료 |
| TASK-5 | `StaticGameData` 3개 필드 추가 + DataLoader 등록 | 완료 |
| TASK-6 | `UserData` HiveField(21) `choiceEventId` 추가 | 완료 |
| TASK-7 | `ActivityLogType` HiveField(21) `travelChoiceCompleted` 추가 | 완료 |
| TASK-8 | `MovementRepository.setChoiceEventId` / `choiceEventId` getter 추가 | 완료 |
| TASK-9 | `TravelChoiceService` 순수 서비스 신규 생성 (rollChoiceEvent / selectProtagonist / filterVisibleOptions / resolveResult / summarizeEffect) | 완료 |
| TASK-10 | `TravelChoiceRecallData` + `pendingTravelChoiceProvider` 신규 생성 | 완료 |
| TASK-11 | `MovementNotifier.startMovement` 선택지 롤링 + `_completeMovement` recall trigger + `applyTravelChoiceEffect` 추가 | 완료 |
| TASK-12 | `TravelChoiceRecallDialog` ConsumerStatefulWidget 신규 생성 | 완료 |
| TASK-13 | `home_screen.dart` `pendingTravelChoiceProvider` ref.listen 연결 + 이전 코드 위젯 추출 + ActivityLogType 아이콘 추가 | 완료 |
| TASK-14 | build_runner 코드 생성 | 완료 |
| TASK-15 | `TravelChoiceService` 단위 테스트 19개 | 완료 |

## 변경 파일 목록

### 신규 생성
| 파일 경로 | 변경 유형 | 설명 |
|-----------|-----------|------|
| `lib/core/models/travel_choice_event_data.dart` | 신규 | Freezed 정적 모델 |
| `lib/core/models/travel_choice_option_data.dart` | 신규 | Freezed 정적 모델 |
| `lib/core/models/travel_choice_result_data.dart` | 신규 | Freezed 정적 모델 + fallbackResult |
| `lib/features/movement/domain/travel_choice_service.dart` | 신규 | 순수 서비스 (5개 static 메서드) |
| `lib/features/movement/domain/travel_choice_recall_provider.dart` | 신규 | TravelChoiceRecallData + pendingTravelChoiceProvider |
| `lib/features/movement/view/travel_choice_recall_dialog.dart` | 신규 | 2단계 다이얼로그 위젯 |
| `test/features/movement/domain/travel_choice_service_test.dart` | 신규 | 단위 테스트 19개 |

### 수정
| 파일 경로 | 변경 유형 | 설명 |
|-----------|-----------|------|
| `lib/core/models/user_data.dart` | 수정 | HiveField(21) choiceEventId 추가 |
| `lib/core/domain/activity_log_model.dart` | 수정 | HiveField(21) travelChoiceCompleted 추가 |
| `lib/core/providers/static_data_provider.dart` | 수정 | StaticGameData 3개 필드 + DataLoader 등록 |
| `lib/core/data/sync_service.dart` | 수정 | allTables 3개 테이블 추가 |
| `lib/features/movement/data/movement_repository.dart` | 수정 | setChoiceEventId / choiceEventId getter 추가 |
| `lib/features/movement/domain/movement_provider.dart` | 수정 | rollChoiceEvent + _triggerChoiceRecall + applyTravelChoiceEffect |
| `lib/features/home/view/home_screen.dart` | 수정 | pendingTravelChoiceProvider ref.listen + 위젯 추출 (flutter-reviewer) |

### 코드 생성 (build_runner)
| 파일 | 사유 |
|------|------|
| `lib/core/models/travel_choice_event_data.freezed.dart` | 신규 Freezed |
| `lib/core/models/travel_choice_event_data.g.dart` | 신규 JsonSerializable |
| `lib/core/models/travel_choice_option_data.freezed.dart` | 신규 Freezed |
| `lib/core/models/travel_choice_option_data.g.dart` | 신규 JsonSerializable |
| `lib/core/models/travel_choice_result_data.freezed.dart` | 신규 Freezed |
| `lib/core/models/travel_choice_result_data.g.dart` | 신규 JsonSerializable |
| `lib/core/models/user_data.g.dart` | choiceEventId 필드 추가 |

### 기존 테스트 호환성 수정
| 파일 | 수정 내용 |
|------|-----------|
| `test/features/inventory/view/inventory_screen_test.dart` | StaticGameData 생성자에 3개 필드 추가 |
| `test/features/quest/domain/quest_completion_service_test.dart` | 동일 |
| `test/features/quest/domain/special_flag_processor_test.dart` | 동일 |
| `test/features/quest/domain/quest_narrative_service_test.dart` | 동일 |

## Q&A 결정사항

- **Q1 updateStatus**: `updateStatus` 메서드 사용 (이미 구현됨)
- **Q2 선택지 노출 순서**: 제안대로 일반 선택지 상단 Row + 숨겨진 선택지 하단 Column(✦ prefix)
- **Q3 addItem 직접 호출**: `item_drop` 효과는 `InventoryRepository.addItem` 직접 호출 (M2a 구현 확인)
- **Q4 빈 슬롯 체크**: 기획서/명세서 규정대로 빈 선천 슬롯 없으면 skip

## 주요 구현 결정사항

- **확률 계산**: `P = min(base + coeff × distance, 0.30)` — tier별 coeff(1-2: 0.08, 3-4: 0.10, 5: 0.12), base는 명세서 기본값
- **이벤트 전달**: `pendingTravelChoiceProvider` StateProvider 이벤트 채널 패턴 (chainCompleted / regionTransformed와 동일)
- **효과 적용 위치**: `applyTravelChoiceEffect`는 `MovementNotifier`에 위임 (view→data 레이어 경계 준수)
- **`_triggerChoiceRecall` 빈 옵션 처리**: `filterVisibleOptions` 결과가 비어 있으면 publish 없이 skip
- **choiceEventId 보존**: UserData HiveField(21)에 저장하여 앱 재시작 시에도 recall 가능
- **trait_innate 효과**: 빈 선천 슬롯 없으면 `innate_slot_full` fallback effectType으로 처리

## 검증 결과

**검증 모드**: 풀 검증 (TASK 15개)

| 라운드 | verifier | flutter-reviewer | 결과 |
|--------|----------|-----------------|------|
| 1차 (빌드 에러 후) | PASS | BLOCK (HIGH 4건) | FAIL |
| 2차 | PASS | BLOCK (HIGH 4건) | FAIL |
| 3차 | — | BLOCK (HIGH 2건 — 기존 코드 포함) | FAIL |
| 4차 (최종) | — | APPROVE | PASS |

**수정된 이슈:**
- `_onOptionSelected` await 후 `context` 사용 → `if (!mounted) return;` 추가
- view→data 직접 접근 → `applyTravelChoiceEffect`를 `MovementNotifier`로 이동
- `_buildOptionButtons` private 메서드 → `_OptionButtonsSection` StatelessWidget 추출
- `applyTravelChoiceEffect` gold/reputation await 누락 → await 추가
- `_buildDashboard`/`_dashItem` private 메서드 → `_DashboardSection`/`_DashItem` StatelessWidget 추출 (기존 코드)
- inline widget tree → `_TravelEventDialog` StatelessWidget 추출 (기존 코드)
- Colors 리터럴 → AppTheme 상수
- `_TravelEventDialog._buildContent()` → `_TravelEventDialogContent` StatelessWidget 추출
- `AppTheme.surface.withValues(alpha: 0.05)` → `AppTheme.surfaceAlt`

**잔여 이슈 (비차단):**
- `_HomeScreenState.build()` 381줄 대규모 분리 (기존 코드 구조 문제, 별도 리팩토링 스프린트에서 처리)
- `_onOptionSelected` 내 `setState` 직전 `mounted` 중복 가드 (MEDIUM)
- `Random()` 매번 새 인스턴스 생성 (MEDIUM)
- `effectType` String switch exhaustive 미보장 (LOW)

**최종 테스트**: 19/19 통과 (신규 테스트), flutter analyze No issues found
