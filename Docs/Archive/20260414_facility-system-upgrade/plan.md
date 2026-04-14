# 시설 시스템 고도화 — 구현 계획 및 결과

Skill used : implement-agent

> 명세서: `Docs/20260414_facility-system-upgrade.md`
> 기획 문서: `docs/content-design/20260414_facility_system_design.md`
> 밸런스 리포트: `docs/balance-design/20260414_facility_balance.md`
> 작성일: 2026-04-14

---

## 1. 구현 계획

### 실행 전략

30개 태스크를 4개 Batch + 1개 ISSUE 수정으로 그룹화하여 실행:

| Batch | 태스크 | 내용 | 결과 |
|-------|--------|------|------|
| Batch 1 | T1~T3, T19, T28 | 모델/인프라 (Facility 13필드, UserData HF12~14, ActivityLogType, 상수, navigation_provider) | 완료 |
| build_runner | T4 | 코드 생성 (15 outputs, 7.7s) | 완료 |
| Batch 2 | T5~T7, T20 | 핵심 서비스 (ConstructionService, FacilityService 전환, GameStateProvider 건설큐, completionProvider) | 완료 |
| Batch 3 | T8~T18 | 효과 적용 (9개 서비스/화면 수정, T9/T10 skip) | 완료 |
| Batch 4 | T21~T30 | UI (4개 신규 위젯, 6탭 확장, 홈 위젯, 설정 정리, 삭제) | 완료 |
| ISSUE-1 | - | 활동 로그 기록 누락 수정 (app.dart) | 완료 |

### 태스크 T9/T10 Skip 사유

- T9 (MercenaryProvider 주둔지): FacilityService.getMaxMercenaries가 T6에서 내부적으로 ConstructionService를 사용하도록 전환되었으므로 호출 코드 변경 불필요
- T10 (QuestProvider 정보망): FacilityService.getExtraQuestCount가 T6에서 내부 전환되었으므로 변경 불필요

---

## 2. 변경 파일 목록

### 수정 파일 (19개)

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `lib/core/models/facility.dart` | freezed 필드 추가 | 13개 nullable 필드 (description~milestones) |
| `lib/core/models/user_data.dart` | HiveField 추가 | HF12~14 건설큐 (constructionFacilityId/StartTime/EndTime) |
| `lib/core/domain/activity_log_model.dart` | enum 추가 | `@HiveField(9) facilityUpgrade` |
| `lib/core/constants/game_constants.dart` | 상수 추가 | `maxFacilityLevel = 25` |
| `lib/core/providers/game_state_provider.dart` | 메서드 추가 | startConstruction/completeConstruction/cancelConstruction/recalculateConstructionTimer/checkConstructionCompletion |
| `lib/features/mercenary/domain/facility_service.dart` | 전면 교체 | ConstructionService 위임, canUpgrade에 currentConstructionId 추가 |
| `lib/app.dart` | 6탭 + 팝업 + tick | FacilityTabScreen index 4 삽입, gameTickProvider listen, constructionCompletedProvider listen + 활동 로그 |
| `lib/shared/widgets/bottom_nav_bar.dart` | 탭 추가 | '🏗 시설' 탭 index 4 |
| `lib/features/home/view/home_screen.dart` | 위젯 + 로그 | 건설 미니 위젯, _logIcon facilityUpgrade case |
| `lib/features/quest/domain/quest_completion_service.dart` | 효과 전환 | ConstructionService 사용 + 야전병원 효과 추가 |
| `lib/features/mercenary/domain/mercenary_provider.dart` | 효과 추가 | 주점 recruitBonus 전달 |
| `lib/features/mercenary/data/mercenary_repository.dart` | 파라미터 추가 | recruit에 recruitBonus |
| `lib/features/mercenary/domain/recruitment_service.dart` | 확률 보정 | selectTier에 recruitBonus, 고티어 확률 분배 |
| `lib/features/quest/domain/quest_provider.dart` | 변경 없음 | T6 내부 전환으로 skip |
| `lib/features/movement/domain/movement_provider.dart` | 효과 추가 | 이동수단 travelReduction + 방어시설 damageReduction |
| `lib/features/movement/domain/travel_event_service.dart` | 메서드 추가 | applyDamageReduction static 유틸리티 |
| `lib/features/movement/view/movement_screen.dart` | UI 추가 | 이동수단 효과 시간 표시 + 보조 텍스트 |
| `lib/core/domain/idle_reward_service.dart` | 파라미터 추가 | idleBonusAmount로 상한 가변화 |
| `lib/main.dart` | 금고 연결 | vault 효과값 계산 후 IdleRewardService 전달 |
| `lib/features/settings/view/settings_screen.dart` | 탭 제거 + 재계산 | FacilityScreen 제거, ConsumerWidget 전환, 속도변경 시 건설타이머 재계산 |

### 신규 생성 파일 (6개)

| 파일 경로 | 역할 |
|-----------|------|
| `lib/core/providers/navigation_provider.dart` | currentTabProvider 분리 (순환 의존 방지) |
| `lib/features/facility/domain/construction_service.dart` | 공식 기반 비용/시간/효과 계산 |
| `lib/features/facility/domain/construction_completion_provider.dart` | 건설 완료 전역 알림 Provider |
| `lib/features/facility/view/facility_tab_screen.dart` | 시설 탭 메인 화면 |
| `lib/features/facility/view/facility_card.dart` | 시설 카드 위젯 |
| `lib/features/facility/view/construction_queue_bar.dart` | 건설 큐 상태 바 |
| `lib/features/facility/view/milestone_timeline.dart` | 이정표 타임라인 |

### 삭제 파일 (1개)

| 파일 경로 | 사유 |
|-----------|------|
| `lib/features/settings/view/facility_screen.dart` | 신규 facility_tab_screen.dart로 대체 |

### 코드 생성 파일 (build_runner)

| 파일 경로 | 사유 |
|-----------|------|
| `lib/core/models/facility.freezed.dart` | freezed 모델 필드 변경 |
| `lib/core/models/facility.g.dart` | json_serializable 필드 변경 |
| `lib/core/models/user_data.g.dart` | HiveField 추가 |
| `lib/core/domain/activity_log_model.g.dart` | HiveField enum 추가 |

---

## 3. 검증 결과

### verifier 1차 검증: FAIL (이슈 1건)

| 항목 | 결과 | 비고 |
|------|------|------|
| FR-1 모델 확장 | PASS | 13개 필드 추가 확인 |
| FR-2 공식 계산 | PASS | calculateCost/BuildTime/getEffectValue 공식 일치 |
| FR-3 건설 큐 | PASS | start/complete/cancel 메서드 + HiveField 12~14 |
| FR-4 6탭 네비 | PASS | screens[4]=FacilityTabScreen, items 6개 |
| FR-5 시설 화면 | PASS | 4개 신규 위젯 존재 |
| FR-6 홈 미니 위젯 | PASS | 건설 중 표시 + 탭 이동 |
| FR-7 시설 효과 | PASS | 9종 구현 + 3종 stub |
| FR-8 이정표 stub | PASS | UI만 표시 |
| FR-9 건설 알림 | **FAIL** | 활동 로그 누락 |
| FR-10 max_level | PASS | GameConstants.maxFacilityLevel=25 |

### ISSUE-1 수정 후 재검증: PASS

- app.dart에 activity_log import 추가 + constructionCompletedProvider 리스너 내 addLog 호출

### flutter analyze 최종 결과

- 에러: 0건
- 경고: 0건
- info: 4건 (기존 dispatch_screen.dart, 이번 변경과 무관)

---

## 4. CLAUDE.md 위반 사항

없음.

---

## 5. 후속 작업

- `flutter analyze` info 4건은 기존 코드 이슈 (dispatch_screen.dart)
- 기존 4종 시설의 Supabase `max_level`을 25로 UPDATE하는 작업은 이 코드가 배포된 후 진행
- 기능 해금 이정표(milestone)의 실제 기능 구현은 별도 태스크로 진행
- 게시판(quest_quality), 대장간(equipment_bonus), 연구소(research_efficiency)의 실제 효과 적용은 해당 시스템 구현 시 연동
