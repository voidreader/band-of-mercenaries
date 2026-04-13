# Phase A: 트레잇 라이프사이클 완성 — 개발 명세서

> 기획 문서: `docs/content-design/20260413_phase_a_trait_lifecycle.md`
> 작성일: 2026-04-13
> 담당자: claude

## 1. 개요

트레잇 시스템의 생성-성장-소멸 흐름을 완성한다. 후천 트레잇 삭제 시스템(골드 비용 + 의무실 레벨 해금)을 추가하고, 여행 이벤트에서 빈 선천 슬롯에 트레잇을 부여하는 메커니즘을 구현한다. 부수적으로, 현재 SnackBar만 표시하는 `_onTraitTap`을 TraitDetailDialog로 연결하는 작업도 포함한다.

## 2. 요구사항

### 2.1 기능 요구사항

#### 파트 1: 트레잇 삭제

- [FR-1] 트레잇 삭제 가능 여부 검증
  - 대상: `acquired`, `evolved` 타입만 삭제 가능. `innate`는 불가
  - 파견 중(`isDispatched == true`) 용병의 트레잇은 삭제 불가
  - 의무실 레벨 조건: acquired → 레벨 2 이상, evolved → 레벨 4 이상
  - 골드 잔액 조건: 비용 이상의 골드 보유 필요

- [FR-2] 트레잇 삭제 비용
  - `acquired` 트레잇: 200G
  - `evolved` 트레잇: 500G
  - 골드는 삭제 확정 시 즉시 차감

- [FR-3] 트레잇 삭제 실행
  - 용병의 `traitIds`에서 해당 키 제거
  - 용병의 `traitHistory`에 해당 키 추가 (재획득 방지)
  - 용병의 `deletedTraitIds`(신규 필드)에 해당 키 추가 (히스토리 구분 표시용)
  - 활동 로그에 `traitDeleted` 타입으로 기록

- [FR-4] TraitDetailDialog 연결
  - `mercenary_detail_overlay.dart`의 `_onTraitTap`에서 SnackBar 대신 TraitDetailDialog를 showDialog로 표시
  - TraitDetailDialog에 필요한 모든 정적 데이터(transitions, comboEvolutions, conflicts, synergies) 전달

- [FR-5] 트레잇 삭제 UI
  - TraitDetailDialog 하단에 [삭제] 버튼 추가
  - 조건 미충족 시 비활성화 + 사유 텍스트 표시
  - 삭제 가능 시 빨간색 버튼: `[삭제 — {비용}G]`
  - 확인 다이얼로그: 트레잇명, 효과, 비용, "삭제 후 재획득 불가" 경고, [취소]/[삭제] 버튼

- [FR-6] 히스토리 삭제 구분 표시
  - TraitHistorySection에서 `deletedTraitIds`에 포함된 트레잇은 `(삭제)`로 표시
  - 기존 진화/조합 매칭 로직보다 우선 체크

#### 파트 2: 여행 이벤트 ↔ 선천 트레잇

- [FR-7] TravelEvent 모델 확장
  - `targetCategory` 필드 추가 (nullable String)
  - Supabase travel_events 테이블에 `target_category` 컬럼 추가

- [FR-8] 신규 여행 이벤트 데이터 (3종)
  - `te_harsh_terrain`: Physical 카테고리, T2-T5, encounter/trait_innate
  - `te_old_traveler`: Background 카테고리, T1-T4, encounter/trait_innate
  - `te_natural_talent`: Talent 카테고리, T3-T5, luck/trait_innate

- [FR-9] 선천 트레잇 이벤트 필터링 + 재롤링
  - `rollEvent`에서 `trait_innate` 이벤트가 선택된 경우:
    - 용병단에 해당 카테고리의 빈 선천 슬롯을 가진 용병이 없으면 → 이벤트 무효, 재롤링
    - 해당 카테고리에 부여 가능한 선천 트레잇이 없으면 → 이벤트 무효, 재롤링
  - 재롤링 상한: 3회. 모두 실패 시 이벤트 없음 처리

- [FR-10] 선천 트레잇 부여 로직
  - `_applyEventEffect`에 `trait_innate` case 추가
  - 대상 용병: 해당 카테고리 빈 슬롯 보유 용병 중 랜덤 1명
  - 부여 트레잇: 해당 카테고리의 `type == 'innate'` 중 랜덤 1개 (보유 트레잇 제외, 충돌 트레잇 제외)
  - `mercenaryRepository.addTrait()`으로 추가
  - 활동 로그에 `traitAcquired` 타입으로 기록

- [FR-11] 여행 이벤트 결과 UI 확장
  - `trait_innate` 이벤트 시 기존 AlertDialog를 확장하여 대상 용병명 + 획득 트레잇 정보 표시
  - 이벤트 발동 시 `lastTravelEventProvider` 외에 추가 상태(대상 용병 ID, 부여 트레잇 키) 저장 필요

### 2.2 데이터 요구사항

- **Hive 모델 변경:**
  - `Mercenary` (HiveType 1): `@HiveField(17) List<String> deletedTraitIds` 추가
  - `ActivityLogType` (HiveType 6): `@HiveField(8) traitDeleted` 추가

- **Freezed 모델 변경:**
  - `TravelEvent`: `@JsonKey(name: 'target_category') String? targetCategory` 추가

- **Supabase 테이블 변경:**
  - `travel_events`: `target_category TEXT` 컬럼 추가
  - `travel_events`: 3행 INSERT (te_harsh_terrain, te_old_traveler, te_natural_talent)
  - `data_versions`: travel_events 버전 증가

- **상수 추가 (GameConstants):**
  - `traitDeletionCostAcquired: 200`
  - `traitDeletionCostEvolved: 500`
  - `traitDeletionMinInfirmaryLevelAcquired: 2`
  - `traitDeletionMinInfirmaryLevelEvolved: 4`

### 2.3 UI 요구사항

- **TraitDetailDialog 삭제 버튼:**
  - 다이얼로그 하단 actions 영역에 조건부 표시
  - 비활성 사유 4종: 선천 트레잇 / 의무실 레벨 부족 / 파견 중 / 골드 부족
  - 활성 시: 빨간색 `TextButton` 또는 `ElevatedButton`

- **삭제 확인 다이얼로그:**
  - AlertDialog로 구현
  - 트레잇명, 효과 텍스트, 비용, 경고 문구 표시
  - [취소] / [삭제] 버튼 (삭제는 빨간색)

- **여행 이벤트 결과 확장:**
  - 기존 `AlertDialog`(`home_screen.dart:82-94`)를 `trait_innate` 이벤트 시 확장
  - 이벤트 설명 + 대상 용병명 + 획득 트레잇 이름/카테고리/설명 표시

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `lib/features/mercenary/domain/mercenary_model.dart` | `@HiveField(17) List<String> deletedTraitIds` 추가, 생성자 초기화 | FR-3 |
| `lib/features/mercenary/data/mercenary_repository.dart` | `deleteTrait()` 메서드 추가 | FR-3 |
| `lib/features/mercenary/view/trait_detail_dialog.dart` | 삭제 버튼 + 확인 다이얼로그 추가, 콜백 파라미터 추가 | FR-5 |
| `lib/features/mercenary/view/mercenary_detail_overlay.dart` | `_onTraitTap`을 TraitDetailDialog showDialog로 변경 | FR-4 |
| `lib/features/mercenary/view/trait_history_section.dart` | `deletedTraitIds` 파라미터 추가, `(삭제)` 분기 추가 | FR-6 |
| `lib/core/constants/game_constants.dart` | 삭제 비용/레벨 상수 4개 추가 | FR-2 |
| `lib/core/domain/activity_log_model.dart` | `ActivityLogType.traitDeleted` 추가 | FR-3 |
| `lib/core/models/travel_event.dart` | `targetCategory` 필드 추가 | FR-7 |
| `lib/features/movement/domain/travel_event_service.dart` | `rollEvent` 재롤링 로직 추가, `trait_innate` 필터링 | FR-9 |
| `lib/features/movement/domain/movement_provider.dart` | `_applyEventEffect`에 `trait_innate` case 추가, 부여 결과 상태 저장 | FR-10 |
| `lib/features/home/view/home_screen.dart` | 여행 이벤트 결과 다이얼로그에 선천 트레잇 획득 UI 추가 | FR-11 |

> 모든 경로는 `band_of_mercenaries/` 프로젝트 루트 기준

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `lib/features/mercenary/domain/trait_deletion_service.dart` | 삭제 가능 여부 검증, 비용 계산 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `lib/features/mercenary/domain/mercenary_model.g.dart` | HiveField(17) 추가 → hive_generator 재생성 |
| `lib/core/domain/activity_log_model.g.dart` | HiveField(8) 추가 → hive_generator 재생성 |
| `lib/core/models/travel_event.freezed.dart` | targetCategory 필드 추가 → freezed 재생성 |
| `lib/core/models/travel_event.g.dart` | targetCategory 필드 추가 → json_serializable 재생성 |

`dart run build_runner build` 필수

### 3.4 관련 시스템

- **트레잇 시스템**: 삭제 서비스 추가, 기존 TraitAcquisitionService의 traitHistory 체크 로직이 삭제된 트레잇 재획득도 자연 방지
- **시설 시스템**: 의무실 레벨을 삭제 해금 조건으로 사용. `userData.facilities['infirmary']`로 접근
- **이동 시스템**: TravelEventService 확장, MovementProvider에 새 effectType 처리 추가
- **경제 시스템**: 삭제 비용 골드 차감. `userDataProvider.notifier.spendGold()` 사용
- **활동 로그**: `traitDeleted` 타입 추가

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

| 참조 파일 | 참고할 패턴 |
|-----------|------------|
| `mercenary_repository.dart:86-91` (`addTrait`) | `deleteTrait`의 역방향 구현 패턴. traitIds 리스트 조작 + save |
| `mercenary_repository.dart:94-98` (`evolveTrait`) | traitHistory 추가 패턴. `[...merc.traitHistory, key]` |
| `trait_acquisition_service.dart:11-43` | 트레잇 검증 로직 구조 (타입 체크, 히스토리 체크, 충돌 체크). TraitDeletionService 설계 참고 |
| `movement_provider.dart:156-194` (`_applyEventEffect`) | effectType switch 분기 패턴. `trait_innate` case 추가 위치 |
| `travel_event_service.dart:14-25` (`rollEvent`) | 이벤트 롤 + 필터링 패턴. 재롤링 확장 지점 |
| `home_screen.dart:82-94` | 여행 이벤트 AlertDialog 패턴. 확장 대상 |
| `quest_completion_service.dart:144-152` | 의무실 레벨 접근 패턴: `userData.facilities['infirmary'] ?? 0` + `FacilityService.getEffectValue()` |

### 4.2 주의사항

- `mercenary_model.dart`에 HiveField 추가 시 기존 필드 번호를 절대 변경하지 않는다. 새 필드는 반드시 17번 사용
- `ActivityLogType`에 enum 추가 시 기존 HiveField 번호 유지. 새 값은 반드시 8번 사용
- `TravelEvent`는 freezed 모델이므로 `targetCategory`를 nullable(`String?`)로 선언해야 기존 12종 이벤트와 호환
- `rollEvent`의 재롤링은 동일 확률 판정 내에서만 수행. 확률 자체를 재판정하지 않음
- TraitDetailDialog는 StatelessWidget이므로 삭제 후 다이얼로그를 닫고 상태를 갱신해야 함 (Navigator.pop 후 mercenaryListProvider refresh)

### 4.3 엣지 케이스

- **삭제 직후 진화 조건 충족**: 삭제로 슬롯이 비면 다음 퀘스트 완료 시 새 트레잇 획득 가능. 정상 동작
- **모든 후천 슬롯이 삭제된 트레잇으로 차 있는 경우**: traitHistory에 기록되어 재획득 불가. acquiredCount는 현재 traitIds 기준이므로 새 트레잇 획득 가능. 정상 동작
- **여행 이벤트: 용병 0명**: `mercenaryListProvider`가 빈 리스트 → 빈 슬롯 보유 용병 없음 → 재롤링 → 이벤트 없음. 정상 동작
- **여행 이벤트: 빈 슬롯은 있지만 충돌 없는 트레잇이 없는 경우**: 부여 가능 트레잇 필터링 결과 빈 리스트 → 이벤트 무효 처리
- **여행 이벤트: delay + trait_innate 조합**: trait_innate는 delay가 아니므로 `_completeMovement`에서 `_applyEventEffect` 호출됨. 정상 동작
- **삭제 중 앱 종료**: Hive save는 atomic. 골드 차감과 트레잇 제거가 별도 save라면 중간 상태 가능. deleteTrait에서 골드 차감과 트레잇 제거를 동일 트랜잭션 내에서 처리 권장

### 4.4 구현 힌트

#### 파트 1: 트레잇 삭제

- **진입점**: `MercenaryDetailOverlay._onTraitTap` (`mercenary_detail_overlay.dart:346`)
- **데이터 흐름**:
  ```
  TraitSlotGrid.onTraitTap → _onTraitTap → showDialog(TraitDetailDialog)
    → [삭제] 버튼 탭 → 확인 다이얼로그
    → 확인 → TraitDeletionService.canDelete() 검증
    → userDataProvider.spendGold(cost)
    → mercenaryRepository.deleteTrait(mercId, traitKey)
    → activityLogProvider.addLog(message, traitDeleted)
    → Navigator.pop + mercenaryListProvider.refresh()
  ```
- **참조 구현**:
  - `mercenary_repository.dart:86-91` — addTrait의 역방향으로 deleteTrait 구현
  - `mercenary_detail_overlay.dart:49-62` — 정적 데이터 resolve 패턴 (TraitDetailDialog에 전달할 데이터)
  - `quest_completion_service.dart:144-152` — 의무실 레벨 접근 패턴
- **확장 지점**:
  - `mercenary_model.dart:69` 다음에 `@HiveField(17) List<String> deletedTraitIds;` 추가
  - `mercenary_model.dart:88-91` 생성자에 `deletedTraitIds` 파라미터 + 초기화 추가
  - `mercenary_repository.dart:106` 다음에 `deleteTrait()` 메서드 추가
  - `trait_detail_dialog.dart` build 메서드 actions 영역에 삭제 버튼 위젯 추가
  - `trait_history_section.dart:62` `_buildHistoryEntry` 시작 부분에 deletedTraitIds 체크 분기 삽입

#### 파트 2: 여행 이벤트 ↔ 선천 트레잇

- **진입점**: `MovementNotifier.startMovement` (`movement_provider.dart:61`) → `TravelEventService.rollEvent`
- **데이터 흐름**:
  ```
  startMovement → TravelEventService.rollEvent (재롤링 포함)
    → trait_innate 이벤트 선택 시: 빈 슬롯 검증 → 이벤트 저장
    → _completeMovement → _applyEventEffect
    → trait_innate case: 대상 용병 선택 → 트레잇 선택 → addTrait
    → lastTravelEventTraitResultProvider(신규)에 결과 저장
    → HomeScreen에서 확장된 AlertDialog 표시
  ```
- **참조 구현**:
  - `travel_event_service.dart:14-25` — rollEvent 확장. 반환값이 trait_innate일 때 유효성 검증 + 재롤링 루프
  - `movement_provider.dart:156-194` — _applyEventEffect switch에 `case 'trait_innate':` 추가
  - `trait_acquisition_service.dart:45-57` — 충돌 체크 로직 (_hasConflict) 재사용
- **확장 지점**:
  - `travel_event.dart:12` 다음에 `@JsonKey(name: 'target_category') String? targetCategory,` 추가
  - `travel_event_service.dart:14` — rollEvent 시그니처에 용병 리스트/트레잇 데이터/충돌 데이터 파라미터 추가 또는 별도 메서드
  - `movement_provider.dart:88-93` — rollEvent 호출부에 추가 파라미터 전달
  - `movement_provider.dart:193` 다음에 `case 'trait_innate':` 분기 추가
  - `home_screen.dart:82-94` — event.effectType == 'trait_innate' 분기로 확장 UI

#### TraitDeletionService 설계

```dart
class TraitDeletionService {
  /// 삭제 가능 여부와 사유를 반환
  static TraitDeletionResult canDelete({
    required TraitData trait,
    required Mercenary mercenary,
    required int infirmaryLevel,
    required int currentGold,
  });

  /// 삭제 비용 계산
  static int deletionCost(TraitData trait);
}

/// 삭제 검증 결과
class TraitDeletionResult {
  final bool canDelete;
  final String? reason; // 불가 사유 (null이면 삭제 가능)
  final int cost;
}
```

## 5. 기획 확인 사항

- [Q-1] TraitDetailDialog가 MercenaryDetailOverlay에 연결되어 있지 않았다 (SnackBar만 표시). 이번 스펙에 연결 작업 포함 → **확인: 포함한다**
- [Q-2] traitHistory 삭제 구분 방식. 방안 B 채택 — Mercenary에 `deletedTraitIds` (HiveField 17) 추가, 히스토리에서 `(삭제)` 구분 표시 → **확인: 방안 B**
- [Q-3] Supabase 데이터 변경 범위. 방안 B 채택 — Flutter 모델 변경 + Supabase 마이그레이션 SQL 모두 이 스펙에 포함 → **확인: 방안 B**

## 6. Supabase 마이그레이션

### 6.1 travel_events 테이블 스키마 변경

```sql
ALTER TABLE travel_events ADD COLUMN target_category TEXT;
```

### 6.2 신규 이벤트 데이터 삽입

```sql
INSERT INTO travel_events (id, name, type, effect_type, magnitude, min_tier, max_tier, description, target_category) VALUES
('te_harsh_terrain', '혹독한 지형', 'encounter', 'trait_innate', 0, 2, 5, '척박한 환경을 지나며 단련되었다.', 'Physical'),
('te_old_traveler', '노련한 여행자와의 조우', 'encounter', 'trait_innate', 0, 1, 4, '길에서 만난 노인이 옛 이야기를 들려주었다.', 'Background'),
('te_natural_talent', '재능의 발현', 'luck', 'trait_innate', 0, 3, 5, '위기 상황에서 숨겨진 재능이 발현되었다.', 'Talent');
```

### 6.3 기존 이벤트 target_category 업데이트

기존 12종 이벤트는 `target_category = NULL`로 유지 (trait_innate가 아니므로 사용하지 않음).

### 6.4 data_versions 업데이트

```sql
UPDATE data_versions SET version = version + 1 WHERE table_name = 'travel_events';
```
