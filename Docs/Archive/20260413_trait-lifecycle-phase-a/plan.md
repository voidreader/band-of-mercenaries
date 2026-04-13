# Phase A: 트레잇 라이프사이클 완성 — 구현 계획 및 결과

Skill used : implement-agent

> 명세서: `Docs/20260413_trait-lifecycle-phase-a.md`
> 작성일: 2026-04-13

## 1. 구현 계획

### 설계 방향

기존 feature 모듈의 view/domain/data 3계층 구조를 유지하면서, 파트 1(트레잇 삭제)과 파트 2(여행 이벤트 선천 트레잇 부여)를 독립적으로 구현했다. 비즈니스 로직은 static 메서드 기반 서비스 클래스에 위임하는 기존 패턴을 따랐다.

### 실행 순서

| 단계 | 태스크 | 내용 | 병렬 |
|------|--------|------|------|
| 1 | TASK-1, 2, 3, 4, 5 | 모델/상수/enum 변경 | 예 |
| 2 | TASK-14 | build_runner 실행 | - |
| 3 | TASK-6, 7, 8 | 서비스/리포지토리/뷰 | 예 |
| 4 | TASK-9, 11, 12 | UI/프로바이더 | 예 |
| 5 | TASK-10 | TraitDetailDialog + TraitHistorySection 통합 | - |
| 6 | TASK-13 | HomeScreen trait_innate UI 통합 | - |

## 2. 변경 파일 목록

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `lib/core/constants/game_constants.dart` | 수정 | 삭제 비용/레벨 상수 4개 추가 |
| `lib/features/mercenary/domain/mercenary_model.dart` | 수정 | HiveField(17) `deletedTraitIds` 추가 |
| `lib/core/domain/activity_log_model.dart` | 수정 | HiveField(8) `traitDeleted` enum 값 추가 |
| `lib/core/models/travel_event.dart` | 수정 | `targetCategory` nullable String 필드 추가 |
| `lib/features/mercenary/domain/trait_acquisition_service.dart` | 수정 | `_hasConflict` → `hasConflict` public 전환 |
| `lib/features/mercenary/domain/trait_deletion_service.dart` | **신규** | `TraitDeletionService` + `TraitDeletionResult` |
| `lib/features/mercenary/data/mercenary_repository.dart` | 수정 | `deleteTrait()` 메서드 추가 |
| `lib/features/mercenary/view/trait_history_section.dart` | 수정 | `deletedTraitIds` 파라미터, `(삭제)` 분기 |
| `lib/features/mercenary/view/trait_detail_dialog.dart` | 수정 | 삭제 버튼 + 확인 다이얼로그 |
| `lib/features/mercenary/view/mercenary_detail_overlay.dart` | 수정 | `_onTraitTap` → showDialog 연결, `onDelete` 콜백 |
| `lib/features/home/view/home_screen.dart` | 수정 | `_logIcon` traitDeleted + trait_innate UI 확장 |
| `lib/features/movement/domain/movement_provider.dart` | 수정 | trait_innate 재롤링/부여 + `lastTravelEventTraitResultProvider` |

### 코드 생성 파일 (build_runner 재생성 완료)

| 파일 경로 | 이유 |
|-----------|------|
| `lib/features/mercenary/domain/mercenary_model.g.dart` | HiveField(17) 추가 |
| `lib/core/domain/activity_log_model.g.dart` | HiveField(8) 추가 |
| `lib/core/models/travel_event.freezed.dart` | targetCategory 필드 추가 |
| `lib/core/models/travel_event.g.dart` | targetCategory 필드 추가 |

## 3. Verifier 검증 결과

### 정적 분석
- `flutter analyze`: PASS — info-level 경고 4개 (기존 `dispatch_screen.dart`, 이번 변경과 무관)

### 테스트
- `flutter test`: 176/176 전체 통과

### 요구사항 충족

| FR | 결과 | 설명 |
|----|------|------|
| FR-1 | PASS | `TraitDeletionService.canDelete()` — innate→파견중→의무실→골드 순서 검증 |
| FR-2 | PASS | `deletionCost()` — acquired 200G, evolved 500G |
| FR-3 | PASS | `MercenaryRepository.deleteTrait()` — traitIds 제거 + traitHistory + deletedTraitIds + save |
| FR-4 | PASS | `MercenaryDetailOverlay` — showDialog(TraitDetailDialog) 연결 |
| FR-5 | PASS | `TraitDetailDialog` — 삭제 버튼 + 확인 다이얼로그 |
| FR-6 | PASS | `TraitHistorySection` — deletedTraitIds → `(삭제)` 빨간 라벨 |
| FR-7 | PASS | `TravelEvent` — `targetCategory` nullable String |
| FR-8 | N/A | Supabase SQL — 서버 측 작업 |
| FR-9 | PASS | `startMovement()` — trait_innate 재롤링 (최대 3회) |
| FR-10 | PASS | `_applyEventEffect` — trait_innate case 전체 구현 |
| FR-11 | PASS | `HomeScreen` — trait_innate 확장 AlertDialog |

### 검증 횟수
- 1회 검증, PASS

## 4. CLAUDE.md 금지사항 위반

없음

## 5. Supabase 마이그레이션 (미실행)

아래 SQL은 Supabase에서 별도 실행 필요:

```sql
-- 1. 스키마 변경
ALTER TABLE travel_events ADD COLUMN target_category TEXT;

-- 2. 신규 이벤트 삽입
INSERT INTO travel_events (id, name, type, effect_type, magnitude, min_tier, max_tier, description, target_category) VALUES
('te_harsh_terrain', '혹독한 지형', 'encounter', 'trait_innate', 0, 2, 5, '척박한 환경을 지나며 단련되었다.', 'Physical'),
('te_old_traveler', '노련한 여행자와의 조우', 'encounter', 'trait_innate', 0, 1, 4, '길에서 만난 노인이 옛 이야기를 들려주었다.', 'Background'),
('te_natural_talent', '재능의 발현', 'luck', 'trait_innate', 0, 3, 5, '위기 상황에서 숨겨진 재능이 발현되었다.', 'Talent');

-- 3. 버전 업데이트
UPDATE data_versions SET version = version + 1 WHERE table_name = 'travel_events';
```
