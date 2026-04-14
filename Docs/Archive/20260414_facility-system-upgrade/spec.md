# 시설 시스템 고도화 개발 명세서

> 기획 문서: `docs/content-design/20260414_facility_system_design.md`
> 밸런스 리포트: `docs/balance-design/20260414_facility_balance.md`
> 작성일: 2026-04-14

## 1. 개요

현재 4종/최대Lv5/즉시 업그레이드 방식의 시설 시스템을 **12종/최대Lv25/건설 시간 도입/공식 기반 효과 스케일링** 구조로 전면 재설계한다. 건설 큐 1개 제한으로 전략적 선택을 강제하고, 하단 네비게이션에 시설 전용 탭을 추가한다. 신규 8종 시설의 기능 해금(milestone)은 stub으로 두고, 수치 효과(패시브 보너스)만 구현한다.

## 2. 요구사항

### 2.1 기능 요구사항

- [FR-1] **Facility 모델 확장**: Supabase에 추가된 13개 컬럼(description, category, base_cost, cost_multiplier, lv1_cost, lv2_cost, base_time, time_multiplier, lv1_time, lv2_time, max_effect, alpha, milestones)을 Facility freezed 모델에 반영
  - 기존 `costs`/`values` 배열 필드는 유지 (하위 호환)
  - 신규 필드는 모두 snake_case @JsonKey

- [FR-2] **공식 기반 비용 계산**: `FacilityService`에 공식 기반 메서드 추가
  - 골드 비용: `Lv1→lv1_cost, Lv2→lv2_cost, Lv3+→base_cost × cost_multiplier^(level-3)`
  - 건설 시간(분): `Lv1→lv1_time, Lv2→lv2_time, Lv3+→base_time × time_multiplier^(level-3)`
  - 효과값: `max_effect × ln(1 + level × alpha) / ln(1 + 25 × alpha)`
  - 기존 배열 기반 메서드(`getUpgradeCost`, `getEffectValue`)를 공식 기반으로 교체. 기존 4종도 공식 사용

- [FR-3] **건설 큐 시스템**: 한 번에 하나의 시설만 건설 가능
  - UserData에 건설 상태 필드 추가: `constructionFacilityId`, `constructionStartTime`, `constructionEndTime`
  - 건설 시작: 골드 차감 + 건설 상태 기록
  - 건설 완료: 게임 틱(1초)에서 `constructionEndTime` 도달 체크 → 시설 레벨 +1 → 건설 상태 초기화 → 활동 로그 기록
  - 건설 취소: 전액 환불 + 건설 상태 초기화
  - 건설 중에도 해당 시설의 현재 레벨 효과 유지
  - 시간 가속(개발용 speedMultiplier) 적용: 건설 시작 시 `endTime`을 speedMultiplier 반영하여 계산. 속도 변경 시 기존 건설의 endTime도 재계산

- [FR-4] **하단 네비게이션 6탭 확장**: 기존 5탭에 시설 탭 추가
  - 탭 순서: 이동(0) / 파견(1) / 홈(2) / 모집(3) / **시설(4)** / 설정(5)
  - 기존 설정 탭에서 시설 관리 섹션 제거

- [FR-5] **시설 화면 전면 재설계**: 12종 시설 관리 전용 화면
  - 상단: 건설 큐 상태 바 (건설 중 시설명, 잔여 시간 카운트다운, 취소 버튼)
  - 본문: 시설 리스트 (카드형, 현재 레벨/효과/다음 레벨 비용·시간/업그레이드 버튼)
  - 시설 카드 탭 시: 상세 패널 확장 (효과 상세, 다음 레벨 미리보기, 해금 이정표 타임라인)
  - 업그레이드 버튼 비활성 조건: 최대 레벨, 골드 부족, 다른 시설 건설 중

- [FR-6] **홈 화면 건설 위젯**: 건설 진행 중일 때 홈 화면에 미니 위젯 표시
  - 시설명, 진행률 바, 잔여 시간
  - 탭 시 시설 탭으로 이동

- [FR-7] **12종 시설 수치 효과 적용**: 각 시설의 패시브 보너스를 해당 시스템에 반영
  - 훈련소(xp_bonus): QuestCompletionService — 기존 로직을 공식 기반으로 교체
  - 의무실(recovery_reduction): QuestCompletionService — 기존 로직을 공식 기반으로 교체
  - 주둔지(max_mercenaries): MercenaryProvider, HomeScreen — 기존 로직을 공식 기반으로 교체
  - 정보망(quest_count): QuestProvider — 기존 로직을 공식 기반으로 교체
  - 대장간(equipment_bonus): stub (아이템 시스템 미구현)
  - 주점(recruit_bonus): RecruitmentService — 고티어 모집 확률 보정 적용
  - 연구소(research_efficiency): stub (지역 조사 시스템 미구현)
  - 방어시설(damage_reduction): TravelEventService/MovementProvider — 피해 이벤트 magnitude 감소
  - 금고(idle_bonus): IdleRewardService — 방치형 보상 상한 증가
  - 게시판(quest_quality): QuestProvider — 고난도 퀘스트 출현 가중치 증가
  - 이동수단(travel_reduction): MovementProvider — 이동 시간 단축 적용
  - 야전병원(injury_reduction): QuestCompletionService — 부상 확률 감소

- [FR-8] **기능 해금 이정표 stub**: milestones JSONB 데이터를 UI에 표시하되 실제 기능은 미구현
  - 시설 상세에서 이정표 타임라인 표시 (달성 레벨 vs 현재 레벨)
  - 해금된 이정표: 강조 색상 + 체크 표시
  - 미해금 이정표: 회색 + 잠금 아이콘 + 필요 레벨 표시
  - 실제 기능(훈련 배치, 응급치료, 사망 방지 등)은 향후 별도 구현

- [FR-9] **건설 완료 알림**: 건설 완료 시 활동 로그 기록 + 화면 팝업
  - 활동 로그: "훈련소가 Lv6으로 업그레이드되었습니다"
  - 시설 탭이 아닌 다른 화면에 있을 때도 알림

- [FR-10] **기존 max_level 통합**: 기존 4종의 max_level을 25로 변경
  - Supabase에서 기존 4종의 max_level UPDATE (현재 하위 호환을 위해 유지 중)
  - Flutter 코드에서 공식 기반으로 전환 완료 후 배열 기반 로직 제거

### 2.2 데이터 요구사항

**Hive 수정 — UserData 모델:**

| 필드 | HiveField | 타입 | 설명 |
|------|-----------|------|------|
| constructionFacilityId | 21 | String? | 건설 중인 시설 ID (null = 건설 없음) |
| constructionStartTime | 22 | DateTime? | 건설 시작 시각 |
| constructionEndTime | 23 | DateTime? | 건설 완료 예정 시각 |

기존 `facilities` (HiveField 11, Map<String, int>)는 그대로 유지. 키가 4개에서 12개로 확장됨.

**정적 데이터 모델 — Facility 확장:**

| 신규 필드 | Dart 타입 | JSON Key | 설명 |
|----------|---------|----------|------|
| description | String | description | 시설 설명 |
| category | String | category | 비용 티어 (core/standard/premium/expensive) |
| baseCost | int | base_cost | Lv3+ 비용 기본값 |
| costMultiplier | double | cost_multiplier | 비용 배율 |
| lv1Cost | int | lv1_cost | Lv1 고정 비용 |
| lv2Cost | int | lv2_cost | Lv2 고정 비용 |
| baseTime | int | base_time | Lv3+ 시간 기본값 (분) |
| timeMultiplier | double | time_multiplier | 시간 배율 |
| lv1Time | int | lv1_time | Lv1 고정 시간 (분) |
| lv2Time | int | lv2_time | Lv2 고정 시간 (분) |
| maxEffect | double | max_effect | 최대 효과값 |
| alpha | double | alpha | 로그 곡선 파라미터 |
| milestones | List<Map<String, dynamic>> | milestones | 해금 이정표 |

**Supabase 변경 (이미 적용됨):**
- facilities 테이블: 13개 컬럼 추가 + 8개 행 추가 (총 12행)
- data_versions: facilities 버전 +1

**추가 Supabase 작업:**
- 기존 4종의 max_level을 25로 UPDATE (Flutter 코드 전환 완료 후)

### 2.3 UI 요구사항

**시설 탭 화면 구조:**

```
┌─────────────────────────────────────┐
│ [건설 큐 상태 바]                      │
│ 🔨 훈련소 Lv5→Lv6 건설 중             │
│ ████████░░ 3:42:15 남음  [취소]       │
├─────────────────────────────────────┤
│ 시설 목록 (스크롤)                     │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 훈련소            Lv.5          │ │
│ │ XP +34.2%                      │ │
│ │ 다음: +38.5% | 1,125G | 52분   │ │
│ │ [▼ 상세]        [업그레이드]     │ │
│ ├─────────────────────────────────┤ │
│ │ ● Lv5 훈련 배치 해금 ✓         │ │
│ │ ○ Lv10 집중 훈련         🔒    │ │
│ │ ○ Lv20 동시 훈련 슬롯+1  🔒    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 의무실            Lv.4          │ │
│ │ ...                             │ │
│ └─────────────────────────────────┘ │
│ ...                                 │
└─────────────────────────────────────┘
```

**홈 화면 건설 미니 위젯:**

```
┌─────────────────────────────────────┐
│ 🔨 훈련소 Lv6 건설 중 — 3:42:15     │
│ ████████████░░░░ 68%                │
└─────────────────────────────────────┘
```

- 건설 중이 아닐 때는 미표시
- 탭 시 시설 탭(index 4)으로 전환

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `lib/core/models/facility.dart` | 13개 신규 필드 추가 (freezed) | FR-1 Facility 모델 확장 |
| `lib/core/models/user_data.dart` | HiveField 21~23 건설 큐 필드 추가 | FR-3 건설 큐 |
| `lib/features/mercenary/domain/facility_service.dart` | 공식 기반 메서드로 전면 교체 | FR-2 공식 기반 계산 |
| `lib/features/settings/view/facility_screen.dart` | 전면 재설계 (12종, 건설큐, 이정표) | FR-5 시설 화면 |
| `lib/core/providers/game_state_provider.dart` | 건설 시작/취소/완료 메서드 추가 | FR-3 건설 큐 관리 |
| `lib/core/providers/timer_provider.dart` | 게임 틱에서 건설 완료 체크 추가 | FR-3 건설 완료 감지 |
| `lib/app.dart` | 하단 탭 5→6개 확장, 시설 탭 추가 | FR-4 탭 확장 |
| `lib/shared/widgets/bottom_nav_bar.dart` | 6번째 탭 아이템 추가 | FR-4 탭 확장 |
| `lib/features/home/view/home_screen.dart` | 건설 미니 위젯 섹션 추가 | FR-6 홈 위젯 |
| `lib/features/quest/domain/quest_completion_service.dart` | 공식 기반 훈련소/의무실/야전병원 효과 | FR-7 수치 효과 |
| `lib/features/mercenary/domain/mercenary_provider.dart` | 공식 기반 주둔지 효과 | FR-7 수치 효과 |
| `lib/features/quest/domain/quest_provider.dart` | 공식 기반 정보망/게시판 효과 | FR-7 수치 효과 |
| `lib/features/movement/domain/movement_provider.dart` | 이동수단 시간 단축 효과 추가 | FR-7 수치 효과 |
| `lib/features/movement/domain/travel_event_service.dart` | 방어시설 피해 감소 효과 추가 | FR-7 수치 효과 |
| `lib/features/mercenary/domain/recruitment_service.dart` | 주점 모집 확률 보정 추가 | FR-7 수치 효과 |
| `lib/core/domain/idle_reward_service.dart` | 금고 방치 보상 상한 증가 | FR-7 수치 효과 |
| `lib/core/providers/static_data_provider.dart` | StaticGameData에 확장된 Facility 필드 호환 확인 | FR-1 데이터 로딩 |
| `lib/features/settings/view/settings_screen.dart` | 시설 관리 섹션 제거 (전용 탭으로 이동) | FR-4 탭 분리 |
| `lib/core/constants/game_constants.dart` | 시설 관련 상수 정리 (baseMercenaryMax 이동 등) | FR-2 정리 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `lib/features/facility/view/facility_tab_screen.dart` | 시설 전용 탭 화면 (건설 큐 + 시설 리스트) |
| `lib/features/facility/view/facility_card.dart` | 시설 카드 위젯 (레벨, 효과, 이정표 확장) |
| `lib/features/facility/view/construction_queue_bar.dart` | 건설 큐 상태 바 위젯 |
| `lib/features/facility/view/milestone_timeline.dart` | 이정표 타임라인 위젯 |
| `lib/features/facility/domain/construction_service.dart` | 건설 시간/비용 공식 계산, 건설 관리 로직 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `lib/core/models/facility.dart` | freezed 모델 필드 추가 → `.freezed.dart`, `.g.dart` 재생성 |
| `lib/core/models/user_data.dart` | HiveField 추가 → `.g.dart` 재생성 (Hive 어댑터) |

`dart run build_runner build` 필수 실행.

### 3.4 관련 시스템

- **게임 틱 시스템**: 건설 완료 체크 로직 추가 (퀘스트 완료/이동 도착과 동일 패턴)
- **시간 가속**: 건설 시간에 speedMultiplier 적용. 속도 변경 시 endTime 재계산
- **활동 로그**: 건설 완료 시 로그 기록 추가
- **하단 네비게이션**: 5→6탭 확장
- **정적 데이터 동기화**: 12종 시설 데이터 동기화 (SyncService 변경 없음, 기존 facilities 테이블 그대로)

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **건설 타이머**: `lib/features/movement/domain/movement_provider.dart`의 이동 타이머 패턴 참조. `moveEndTime` → `constructionEndTime`, `isMoving` → `constructionFacilityId != null` 동일 구조
- **게임 틱 완료 체크**: `lib/core/providers/timer_provider.dart`에서 퀘스트 완료/이동 도착을 1초 간격으로 체크하는 패턴. 건설 완료도 동일하게 추가
- **활동 로그 기록**: `lib/core/domain/activity_log_service.dart`의 `addLog()` 패턴 참조
- **시간 가속 endTime 재계산**: `lib/core/providers/game_state_provider.dart`의 시간 가속 시 퀘스트/이동 endTime 재계산 로직 참조
- **전체화면 오버레이**: 용병 상세 오버레이(`selectedMercenaryIdProvider`)와 유사한 패턴으로 시설 상세 확장 가능

### 4.2 주의사항

- `ConstrainedBox(maxWidth: 430)` 내에서 작동해야 함. Navigator.push 사용 금지, 상태 기반 렌더링 사용 (CLAUDE.md 웹 UI 규칙)
- `build_runner` 실행 후 생성 파일 확인 필수
- UserData HiveField 번호 21~23은 기존 최대(HiveField 20: isMoving) 다음 번호 사용
- Hive 어댑터 변경 시 기존 데이터 호환성 확인 (새 필드는 nullable로 선언하여 기존 데이터 로드 시 null 허용)
- `analysis_options.yaml`의 `avoid_print: true` 준수

### 4.3 엣지 케이스

- **앱 종료 후 재시작**: 건설 endTime이 이미 과거일 수 있음 → 시작 시 즉시 완료 처리 (방치형 보상과 동일 패턴)
- **시간 가속 변경**: 건설 중 속도를 변경하면 endTime을 비례 재계산. 이미 과거가 되면 즉시 완료
- **골드 부족 후 취소**: 건설 시작 시 골드를 선차감하므로, 취소 시 전액 환불. 환불 후 골드가 음수가 되지 않도록 확인 (선차감이므로 발생하지 않음)
- **기존 플레이어 마이그레이션**: 기존 시설 레벨(0~5) 유지. 새 효과 공식으로 전환 시 기존 Lv5의 효과가 소폭 변경됨 (예: 훈련소 +50% → +34%). 이는 의도된 리밸런싱
- **빈 시설 맵**: 신규 플레이어는 facilities 맵이 빈 상태. 모든 시설 Lv0으로 처리

### 4.4 구현 힌트

**진입점:**
- 시설 탭: `app.dart`의 `MainShell` → screens 배열에 `FacilityTabScreen` 추가 (index 4)
- 건설 완료 체크: `timer_provider.dart`의 게임 틱 스트림 리스너
- 건설 관리: `game_state_provider.dart`의 `UserDataNotifier`에 메서드 추가

**데이터 흐름:**
```
[업그레이드 버튼 탭]
→ FacilityTabScreen → UserDataNotifier.startConstruction(facilityId)
→ ConstructionService.calculateCost(facility, nextLevel) → 골드 차감
→ ConstructionService.calculateBuildTime(facility, nextLevel, speedMultiplier) → endTime 계산
→ UserData에 constructionFacilityId/Start/EndTime 저장 → Hive 저장

[게임 틱 매 초]
→ timer_provider → constructionEndTime 체크
→ 완료 시 → UserDataNotifier.completeConstruction()
→ facilities[id] += 1 → constructionFacilityId = null → Hive 저장
→ 활동 로그 기록 → UI 갱신

[효과 적용]
→ 각 Service에서 ConstructionService.getEffectValue(facility, level) 호출
→ 로그 스케일 공식으로 계산 → 기존 배열 기반 대체
```

**참조 구현:**
- 이동 타이머 패턴: `movement_provider.dart` — `startMovement()`에서 endTime 계산, 틱에서 도착 체크, 도착 시 상태 초기화
- 시설 효과 적용: `quest_completion_service.dart:118-152` — 기존 훈련소/의무실 효과 적용 부분을 공식 기반으로 교체
- 탭 구조: `app.dart:68-74` — screens 배열에 시설 화면 추가

**확장 지점:**
- `app.dart` screens 배열: index 4에 FacilityTabScreen 삽입, 기존 Settings를 index 5로 이동
- `bottom_nav_bar.dart`: 6번째 BottomNavigationBarItem 추가 (아이콘: Icons.construction 또는 Icons.apartment)
- `timer_provider.dart` 게임 틱 리스너: 퀘스트 완료 체크 다음에 건설 완료 체크 추가
- `game_state_provider.dart`: `upgradeFacility()` → `startConstruction()`으로 교체. 기존 메서드는 제거 또는 deprecated

## 5. 기획 확인 사항

- [Q-1] 시설 화면 위치 → **C: 하단 탭 6개로 확장, 시설 전용 탭** (확인됨)
- [Q-2] 건설 취소 환불 → **A: 전액 환불** (확인됨)
- [Q-3] 시간 가속 적용 → **건설 시간에도 적용** (확인됨)
- [Q-4] 구현 범위 → **12종 전체, 수치 효과만 구현, 기능 해금은 stub** (확인됨)
- [Q-5] 기존 Lv5 효과값 변경 (훈련소 +50% → +34%) → 의도된 리밸런싱으로 처리 (기획서에서 Lv25=+80% 로그 곡선 확정)
