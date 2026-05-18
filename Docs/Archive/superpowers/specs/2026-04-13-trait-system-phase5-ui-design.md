# Phase 5: 트레잇 시스템 UI 설계

> 작성일: 2026-04-13
> 기반 기획: `Docs/content-design/20260412_trait_system_design.md`
> 로드맵: `Docs/Trait-Roadmap.md` Phase 5 (⑮⑯⑰)

---

## 범위

Phase 1-4에서 구현된 트레잇 백엔드(모델, 싱크, 획득/진화 엔진)를 플레이어에게 노출하는 UI 레이어.

| # | 작업 | 설명 |
|---|------|------|
| ⑮ | 용병 상세 화면 | 전체화면 오버레이, 트레잇 슬롯 시각화, 행동 지표, 히스토리 |
| ⑯ | 획득/진화 알림 팝업 | 퀘스트 결과 후 체이닝 팝업, 진화 경로 선택 |
| ⑰ | 트레잇 상세 팝업 | 트레잇 탭 시 풍부한 정보 팝업 (효과, 진화경로, 진행도, 시너지, 충돌) |

### 범위 외

- 빈 슬롯 탭 시 후보 목록/진행도 표시 (향후 확장)
- 활동 로그 연동 (별도 작업)
- operation-bom 웹앱 확장 (Phase 6)

---

## 설계 결정 요약

| 항목 | 결정 | 근거 |
|------|------|------|
| 진입 방식 | 앱 레벨 전체화면 상태 오버레이 | ConstrainedBox 안전, 기존 DispatchDetailPage 패턴 일관성, 어디서든 진입 가능 |
| 상세 화면 구조 | 단일 스크롤 | 모든 정보를 한 화면에, 행동 지표만 접기/펼치기 |
| 트레잇 상세 팝업 | 풍부 (진행도 바 포함) | 빌드 최적화를 위한 충분한 정보 제공 |
| 알림 타이밍 | 별도 후속 팝업 체이닝 | 각 이벤트에 집중, 진화 선택 분리 |
| 진화 선택 UI | 카드 비교형 + 경로 선택 | 비가역적 결정이므로 명확한 비교 필요 |
| 빈 슬롯 탭 | 아무 반응 없음 | MVP 범위, 향후 확장 가능 |

---

## 1. 용병 상세 오버레이 (MercenaryDetailOverlay)

### 진입 방식

앱 레벨 StateProvider `selectedMercenaryIdProvider`로 관리한다.

```
// 새로운 Provider
final selectedMercenaryIdProvider = StateProvider<String?>((_) => null);
```

- 값이 `null`이면 상세 화면 비노출
- 값이 설정되면 현재 탭 위에 전체화면 오버레이 렌더링
- `MercenaryCard` 위젯에 `onTap` 핸들러 추가 → `ref.read(selectedMercenaryIdProvider.notifier).state = merc.id`

### 오버레이 렌더링 위치

`app.dart`의 `MainShell` 빌드 메서드에서 현재 탭 화면 위에 `Stack`으로 조건부 렌더링한다. DispatchDetailPage가 DispatchScreen 내부에서 상태 전환하는 것과 달리, 이 오버레이는 탭과 무관하게 최상위에 렌더링된다.

```
Stack(
  children: [
    _screens[currentTab],
    if (selectedMercId != null)
      MercenaryDetailOverlay(mercenaryId: selectedMercId),
  ],
)
```

### 뒤로가기

- 좌상단 ← 버튼 → `selectedMercenaryIdProvider`를 `null`로 설정
- Android 백 버튼도 동일 처리 (`WillPopScope` 또는 동등 처리)

### 화면 구조 (단일 스크롤)

위에서 아래로 4개 섹션이 세로 스크롤:

#### 섹션 1: 프로필 헤더

| 요소 | 내용 |
|------|------|
| 직업 아이콘 | 중앙 정렬, 원형 배경 |
| 이름 + 레벨 | `김철수 Lv.3` |
| 직업 + 티어 + 상태 | `T3 검투사 · 정상` (상태 색상 적용) |
| 전투 스탯 | `⚔ ATK · 🛡 DEF · ❤ HP · 💨 SPD` 인라인 |
| XP 바 | 프로그레스 바 + `650 / 1000` 텍스트 |

기존 `MercenaryCard`와 유사하되 더 넓은 공간 활용.

#### 섹션 2: 트레잇 슬롯 그리드 (TraitSlotGrid)

두 그룹으로 분리 표시:

**선천 슬롯 (최대 3)**
- 가로 3열 (`Physical` / `Background` / `Talent`)
- 각 슬롯: 카테고리 라벨 + 트레잇 이름
- 채워진 슬롯: 카테고리별 색상 배경 + 실선 테두리
- 빈 슬롯: 회색 점선 테두리 + `—` 텍스트
- 라벨: `🔒 선천 트레잇`

**후천 슬롯 (최대 4)**
- 2×2 그리드 (`CombatStyle` / `Survival` / `Behavior` / `Mental` / `Experience` 중 최대 4)
- 5개 카테고리 중 4개만 보유 가능하므로 실제 보유+빈 슬롯 합이 5를 넘지 않음
- 후천 슬롯 표시 방식: 보유 중인 슬롯 + 아직 보유하지 않은 카테고리 중 빈 슬롯 (최대 `4 - 보유수`개)
- 채워진 슬롯에 진화 가능 힌트: `⚡ 진화 가능` 뱃지 (조건 충족 시)
- 라벨: `⬆ 후천 트레잇 (2/4)` 형식
- 채워진 슬롯 탭 → TraitDetailDialog 열기
- 빈 슬롯 탭 → 반응 없음

**후천 슬롯 렌더링 로직:**
1. 현재 보유한 후천 트레잇의 카테고리 슬롯을 먼저 표시
2. 나머지 빈 카테고리 중 `maxAcquiredTraits - 현재보유수` 개만 빈 슬롯으로 표시
3. 예: 2개 보유(CombatStyle, Survival) → 빈 슬롯 2개(나머지 3개 중 2개를 표시)
4. 빈 슬롯에 표시할 카테고리는 acquiredCategories 순서 기준으로 보유하지 않은 것 중 앞에서부터 선택

#### 섹션 3: 행동 지표 (BehaviorStatsSection)

- 기본 접혀있음 (collapsed)
- 헤더: `📊 행동 지표` + 주요 4개 요약 인라인 (`파견 23회 · 성공 15회 · 연속성공 3 · 금화 5,200G`)
- 헤더 탭 → 펼침/접음 토글
- 펼쳤을 때: 23개 지표를 2열 그리드로 표시 (키: 값 형태)
- 지표 키는 한국어로 변환하여 표시 (`total_dispatch_count` → `총 파견`)

**한국어 지표 이름 매핑:**

| 키 | 한국어 |
|----|--------|
| total_dispatch_count | 총 파견 |
| success_count | 성공 |
| failure_count | 실패 |
| great_success_count | 대성공 |
| great_failure_count | 대실패 |
| solo_dispatch_count | 솔로 파견 |
| team_dispatch_count | 팀 파견 |
| high_difficulty_count | 고난이도 성공 |
| low_difficulty_count | 저난이도 성공 |
| raid_count | 토벌 |
| hunt_count | 사냥 |
| escort_count | 호위 |
| explore_count | 탐색 |
| near_death_count | 아사 직전 |
| injury_count | 부상 |
| survived_great_failure | 대실패 생존 |
| tier_max_visited | 최고 티어 방문 |
| unique_region_count | 지역 탐험 |
| total_travel_distance | 총 이동거리 |
| total_gold_earned | 총 수입 |
| current_level | 현재 레벨 |
| consecutive_success | 연속 성공 |
| consecutive_failure | 연속 실패 |

#### 섹션 4: 트레잇 히스토리 (TraitHistorySection)

- `mercenary.traitHistory`에 기록된 소멸 트레잇 표시
- 각 항목: 취소선 처리된 원본 트레잇 → 진화 결과 트레잇 (있을 경우)
- 히스토리가 비어있으면: `아직 진화 기록이 없습니다` 회색 텍스트
- 현재 `traitHistory`는 소멸된 트레잇 키만 저장하므로, 진화 결과를 함께 표시하려면 `traitTransitions`/`traitComboEvolutions` 데이터에서 역추적

**히스토리 표시 방식:**
- `traitHistory`의 각 키에 대해 `traitTransitions`에서 `fromTraitKey`가 일치하는 항목을 찾음
- 찾으면: `원본이름 → 결과이름 (단일 진화)` 형식
- `traitComboEvolutions`에서 `requiredTrait1` 또는 `requiredTrait2`가 일치하는 항목도 검색
- 찾으면: `원본1 + 원본2 → 결과 (조합 진화)` 형식
- 어디에도 매칭되지 않으면: `원본이름 (소멸)` 표시

---

## 2. 트레잇 상세 팝업 (TraitDetailDialog)

채워진 트레잇 슬롯을 탭하면 `showDialog`로 표시.

### 표시 정보

| 섹션 | 내용 | 데이터 소스 |
|------|------|------------|
| 헤더 | 트레잇 이름 + 카테고리 색상 도트 + `카테고리 · 타입(innate/acquired/evolved)` | `TraitData.name`, `categoryKey`, `type` |
| 설명 | 트레잇 설명문 | `TraitData.description` |
| 효과 | effectText 표시 (녹색) | `TraitData.effectText` |
| 진화 경로 | 단일 진화: `현재 → 결과` + 조건 진행도 바. 조합 진화: `현재 + X → 결과` | `traitTransitions`, `traitComboEvolutions`, `mercenary.stats` |
| 시너지 | 선천 트레잇에 의한 획득 조건 감소 정보 | `traitSynergies` |
| 충돌 관계 | 동시 보유 불가 트레잇 목록 | `traitConflicts` |
| 획득 조건 | 이미 보유한 트레잇이면 달성 완료 표시 | `TraitData.acquisitionCondition` |

### 조건부 표시 로직

- **선천(innate) 트레잇**: 진화 경로 없음 (선천은 진화 불가). 효과 + 시너지 정보만 표시
- **후천 acquired 트레잇**: 진화 경로 + 진행도 바 표시. 조합 가능한 레시피도 표시
- **후천 evolved 트레잇**: 진화 경로 없음 (이미 최종 형태). "진화 완료" 뱃지 표시
- 진화 경로가 없는 경우: 해당 섹션 숨김
- 충돌 관계가 없는 경우: 해당 섹션 숨김
- 시너지가 없는 경우: 해당 섹션 숨김

### 진화 조건 진행도 바

`TraitTransition.conditionJson`의 각 키에 대해:
- `mercenary.stats[key]` (현재값) / `conditionJson[key]` (목표값) 비율을 프로그레스 바로 표시
- 색상: 75% 이상 녹색, 50-74% 주황, 50% 미만 빨강
- 모든 조건 충족 시: `⚡ 지금 진화 가능!` 강조 뱃지

---

## 3. 팝업 체이닝 (퀘스트 완료 후)

### 현재 로직 (Phase 4)

```
quest_provider._applyCompletionResult():
  1. MercenaryStatService.updateStatsAfterQuest() → 지표 갱신
  2. TraitAcquisitionService.checkAcquisitionCandidates() → 첫 번째 후보 자동 적용
  3. TraitEvolutionService.checkSingleEvolutions() → 첫 번째 자동 적용
  4. TraitEvolutionService.checkComboEvolutions() → 첫 번째 자동 적용
```

### 변경 후 로직

```
quest_provider._applyCompletionResult():
  1. MercenaryStatService.updateStatsAfterQuest() → 지표 갱신
  2. TraitAcquisitionService.checkAcquisitionCandidates() → 후보 목록 반환
  3. 후보가 있으면 첫 번째를 자동 적용 (mercenaryRepository.addTrait)
  4. 적용된 트레잇 반영 후 TraitEvolutionService.checkSingleEvolutions() → 후보 목록 반환 (적용하지 않음)
  5. TraitEvolutionService.checkComboEvolutions() → 후보 목록 반환 (적용하지 않음)
  6. 결과를 QuestCompletionResult에 포함하여 UI로 전달
```

획득은 자동 적용 (플레이어 선택 없음), 진화는 UI에서 플레이어 선택 후 적용.

### QuestCompletionResult 확장

기존 퀘스트 결과에 트레잇 관련 필드 추가:

```dart
// 새로운 필드 (quest completion result에 포함)
List<String> acquiredTraitCandidates;         // 획득 후보 키 목록
List<SingleEvolutionCandidate> singleEvoCandidates;  // 단일 진화 후보
List<ComboEvolutionCandidate> comboEvoCandidates;    // 조합 진화 후보
```

### 팝업 체이닝 흐름

```
QuestResultDialog (기존 보상 표시)
  → 사용자 닫기
  → [acquiredTraitCandidates 비어있지 않으면]
      TraitAcquisitionDialog 표시
        → 첫 번째 후보 자동 적용 + "획득!" 알림
        → 사용자 닫기
  → [singleEvoCandidates 비어있지 않으면]
      TraitEvolutionDialog 표시 (단일 진화 선택)
        → 사용자 선택 or 보류
        → 적용 후 닫기
  → [comboEvoCandidates 비어있지 않으면 AND 단일 진화를 하지 않았으면]
      TraitEvolutionDialog 표시 (조합 진화 선택)
        → 사용자 선택 or 보류
        → 적용 후 닫기
```

단일 진화와 조합 진화는 퀘스트당 최대 1회이므로, 단일 진화를 실행했으면 조합 진화 팝업은 건너뛴다. 보류한 경우에도 조합 진화 팝업은 표시한다.

### 체이닝 구현 방식

`dispatch_screen.dart`의 `ref.listen`에서 퀘스트 완료 감지 후:
1. `QuestResultDialog`를 `await showDialog`로 표시
2. 닫힌 후 `acquiredTraitCandidates` 확인 → `await showDialog(TraitAcquisitionDialog)`
3. 닫힌 후 진화 후보 확인 → `await showDialog(TraitEvolutionDialog)`

각 팝업은 `await`로 순차 실행되어 자연스럽게 체이닝된다.

---

## 4. 트레잇 획득 알림 (TraitAcquisitionDialog)

퀘스트 완료 후 트레잇을 획득했을 때 표시되는 알림 팝업.

### 표시 내용

- 헤더: `✨ 새 트레잇 획득!`
- 트레잇 이름 (카테고리 색상) + 카테고리 + 타입
- 설명 텍스트
- 효과 텍스트
- 슬롯 배치 안내: `Behavior 슬롯에 배치되었습니다`
- 확인 버튼

### 적용 시점

`quest_provider`에서 첫 번째 후보를 자동 적용 완료한 후, 결과를 UI에 전달한다. 팝업은 알림 용도이며 플레이어 선택은 없다.

획득 후보가 여러 개일 경우: 첫 번째만 적용 (기존 로직 유지). 한 퀘스트에 한 트레잇 획득 제한은 유지한다.

---

## 5. 진화 선택 팝업 (TraitEvolutionDialog)

### 카드 비교형 레이아웃

**상단: 현재 보유 재료**
- 현재 보유 중인 후천 트레잇을 필 형태로 나열
- 선택한 경로의 재료가 되는 트레잇을 하이라이트

**중앙: 결과 카드 리스트**
- 각 진화 경로를 카드로 표시
- 카드 내용:
  - 결과 트레잇 이름 (evolved, 카테고리)
  - 효과 텍스트
  - 소멸 트레잇 (취소선)
  - 슬롯 해방 정보 (조합 진화인 경우)
- 선택된 카드: 노란색 테두리 + 체크마크

**하단: 버튼**
- `보류` — 진화하지 않음. 다음 퀘스트에서 조건이 여전히 충족되면 다시 표시
- `[트레잇명]으로 진화` — 선택한 경로로 진화 실행

### 단일 진화 vs 조합 진화

같은 `TraitEvolutionDialog` 위젯을 사용하되:
- 단일 진화: 소멸 정보가 `원본 → 결과` (같은 카테고리, 슬롯 해방 없음)
- 조합 진화: 소멸 정보가 `재료1 + 재료2 → 결과` + 슬롯 해방 표시

후보가 1개뿐인 경우에도 카드 형태로 보여주되, 선택이 아닌 확인 형태로 표시 (자동 선택 상태).

### 적용 시점

사용자가 진화 버튼을 탭한 후:
- 단일: `mercenaryRepository.evolveTrait(mercId, fromKey, toKey)`
- 조합: `mercenaryRepository.comboEvolveTrait(mercId, trait1Key, trait2Key, resultKey)`

보류 시: 아무것도 적용하지 않고 팝업 닫기.

---

## 6. MercenaryCard 변경

기존 `mercenary_card.dart`에 최소한의 변경:

- `onTap` 추가: 카드 전체를 `GestureDetector`로 감싸고 `selectedMercenaryIdProvider` 설정
- 기존 트레잇 필(pill) 표시는 유지 (상세 화면과 중복이지만 목록에서의 빠른 확인용)

---

## 7. 파일 구조

### 신규 파일

```
lib/features/mercenary/view/
├── mercenary_detail_overlay.dart    # 전체화면 상세 오버레이
├── trait_slot_grid.dart             # 선천/후천 슬롯 그리드 위젯
├── trait_detail_dialog.dart         # 트레잇 상세 팝업
├── trait_acquisition_dialog.dart    # 트레잇 획득 알림 팝업
├── trait_evolution_dialog.dart      # 진화 선택 팝업 (카드 비교형)
├── behavior_stats_section.dart      # 행동 지표 접기/펼치기 섹션
└── trait_history_section.dart       # 트레잇 히스토리 타임라인
```

### 수정 파일

```
lib/app.dart                                    # Stack 오버레이 추가, selectedMercenaryIdProvider 감시
lib/features/mercenary/view/mercenary_card.dart  # onTap 추가
lib/features/quest/view/dispatch_screen.dart     # 팝업 체이닝 로직
lib/features/quest/domain/quest_provider.dart    # 자동 적용 → 후보 반환으로 변경
lib/core/providers/                              # selectedMercenaryIdProvider 추가
```

---

## 8. 데이터 의존성

UI에서 필요한 데이터와 접근 경로:

| 데이터 | Provider/Source | 용도 |
|--------|----------------|------|
| 용병 정보 | `mercenaryListProvider` | 프로필, 스탯, traitIds, traitHistory, stats |
| 트레잇 정의 | `staticDataProvider → traits` | 이름, 설명, 효과, 카테고리 |
| 카테고리 | `staticDataProvider → traitCategories` | 슬롯 타입 구분, 색상 |
| 단일 진화 | `staticDataProvider → traitTransitions` | 진화 경로, 조건 |
| 조합 진화 | `staticDataProvider → traitComboEvolutions` | 조합 레시피 |
| 충돌 관계 | `staticDataProvider → traitConflicts` | 충돌 트레잇 표시 |
| 시너지 | `staticDataProvider → traitSynergies` | 시너지 표시 |
| 카테고리 색상 | `AppTheme.traitCategoryColors` | 모든 트레잇 UI 색상 |
