# UI 개선: 파견 화면, 퀘스트 완료 팝업, 최근활동

- **날짜**: 2026-04-11
- **상태**: 설계 완료
- **원본**: `Docs/20260411_fix.md`

## 개요

파견 화면의 UX 개선(전체화면 전환), 퀘스트 완료 팝업에 보상 상세 내역 추가, 홈 화면 최근활동 스크롤 지원 등 3가지 영역의 UI 수정.

---

## 1. 파견 화면: 전체화면 파견 페이지

### 변경 내용

현재 바텀시트(`showModalBottomSheet`) 방식을 **전체화면 파견 페이지**로 교체한다.

### 현재 문제

- 바텀시트가 화면의 50%까지만 올라옴 (max 80%)
- 선택한 퀘스트 정보가 바텀시트에 미표시
- 사망/파견중 용병이 리스트에 표시되어 불필요한 스크롤 유발
- 비용 요약 + 파견 버튼이 스크롤 영역 안에 있어 매번 스크롤 필요
- '파견 출발' 버튼이 Android 하단 내비게이션에 가려짐 (SafeArea 미적용)

### 설계

**화면 전환 방식**: 퀘스트 카드 탭 시 `Navigator.push`로 전체화면 페이지(`DispatchDetailPage`)로 이동. 뒤로가기로 퀘스트 목록 복귀.

**레이아웃 3단 구조**:

```
┌─────────────────────────────┐
│ [←] 🗡 고블린 소탕           │  ← 상단 고정: AppBar 영역
│ 난이도 ★★ · 보상 120G · 5분  │     퀘스트 이름, 타입, 난이도, 보상, 소요시간
├─────────────────────────────┤
│ 파견 가능한 용병 (3명)        │  ← 중앙 스크롤: 용병 목록
│ ☑ 김철수 · 전사 · ⚔48  정상  │     - 사망 용병: 제외 (표시하지 않음)
│ ☐ 이영희 · 궁수 · ⚔35  정상  │     - 파견중 용병: 제외 (표시하지 않음)
│ ☐ 정하늘 · 성직자 · ⚔22 부상 │     - 부상 용병: 표시하되 선택 불가 + 빨간 "부상" 태그
├─────────────────────────────┤
│ 성공률: 72%  순수익: +85G     │  ← 하단 고정: 요약 + 버튼
│ ┌─────────────────────────┐ │     SafeArea 적용으로 Android/iOS 하단 가림 방지
│ │       파견 출발           │ │
│ └─────────────────────────┘ │
│         (SafeArea)          │
└─────────────────────────────┘
```

**용병 필터링 규칙**:

| 상태 | 표시 여부 | 선택 가능 | 시각 처리 |
|------|-----------|-----------|-----------|
| 정상 | O | O | 기본 스타일 |
| 피곤함 | O | O | 기본 스타일 (능력치 80% 반영됨) |
| 부상 | O | X | 투명도 낮춤 + 빨간 "부상" 태그 |
| 사망 | X | - | 목록에서 제외 |
| 파견중 | X | - | 목록에서 제외 |

**상단 고정 영역** (퀘스트 정보):
- 뒤로가기 아이콘 + 퀘스트 이름
- 퀘스트 타입, 난이도, 기본 보상(G), 소요시간

**중앙 스크롤 영역** (용병 목록):
- `ListView.builder`로 구현
- 각 항목: 체크박스 + 이름 + 직업 + 전투력 + 상태 태그
- 타이틀: "파견 가능한 용병 (N명)" — N은 필터링 후 표시 중인 용병 수

**하단 고정 영역** (비용 요약 + 버튼):
- 성공률, 예상 순수익 (용병 미선택 시 "-")
- '파견 출발' 버튼 (용병 미선택 또는 골드 부족 시 비활성)
- `SafeArea`로 감싸서 Android/iOS 하단 영역 확보

### 영향받는 파일

- `lib/features/quest/view/dispatch_screen.dart`: `_showDispatchBottomSheet` 제거, 퀘스트 카드 탭 시 `Navigator.push`로 변경
- 신규 파일 `lib/features/quest/view/dispatch_detail_page.dart`: 전체화면 파견 페이지 위젯

---

## 2. 퀘스트 완료 팝업: 보상 상세 내역 추가

### 변경 내용

퀘스트 완료 팝업에 보상 상세 내역 섹션 추가 + 버튼 텍스트를 "보상 수령"으로 변경.

### 현재 문제

- 팝업에 보상 정보가 없어 플레이어가 얼마를 벌었는지 모름
- 버튼 텍스트가 단순 "확인"

### 설계

**데이터 문제**: 현재 `ActiveQuest` 모델에 보상 관련 필드가 없다. `_completeQuest`에서 보상을 계산하고 바로 적용하지만 그 값을 저장하지 않는다. 팝업에서 보상을 표시하려면 두 가지 방법이 있다:

1. **ActiveQuest에 보상 필드 추가** (HiveField) — 완료 시 저장
2. **팝업에서 재계산** — staticData로부터 다시 계산

**선택: 방법 1 (ActiveQuest에 필드 추가)**

이유:
- 대성공 2배 보상 등 결과에 따른 실제 적용 값을 정확히 보여줌
- 재계산 시 동일한 로직을 두 곳에서 실행하는 중복 발생
- 한 번 계산한 값을 저장하는 것이 자연스러움

**ActiveQuest 모델 추가 필드** (모두 nullable, 완료 전에는 null):

```dart
@HiveField(12)
int? rewardGold;       // 기본 보상 (grossReward, 실패 시 0)

@HiveField(13)
int? totalWage;        // 인건비 (실패 시 0)

@HiveField(14)
int? dispatchCost;     // 파견 비용 (파견 시 선차감된 금액)

@HiveField(15)
int? earnedXp;         // 획득 경험치 (용병 1인당)

@HiveField(16)
int? earnedReputation; // 획득 명성
```

팝업에서 순수익 = `rewardGold - totalWage - dispatchCost`로 계산하여 표시.

참고: `dispatchCost`는 파견 시점에 선차감되므로 `dispatch()` 메서드에서 저장한다. `rewardGold`, `totalWage`, `earnedXp`, `earnedReputation`은 `_completeQuest()`에서 저장한다.

**팝업 레이아웃** (기존 구조 + 보상 섹션 추가):

```
┌───────────────────────┐
│     퀘스트 완료         │
│  고블린 소탕 · 난이도 ★★ │
│                       │
│   ┌─── 성공! ───┐     │
│   └─────────────┘     │
│                       │
│ 용병 상태              │
│ 김철수 ········ 무사 귀환 │
│ 이영희 ········ 부상     │
│                       │
│ 보상 내역              │  ← 신규 섹션
│ 기본 보상 ······· 120G  │
│ 파견 비용 ····· -20G   │
│ 인건비 ········ -15G   │
│ ─────────────────     │
│ 순수익 ········ +85G   │
│ 획득 경험치 ···· +24 XP │
│ 획득 명성 ······ +5    │
│                       │
│ ┌─────────────────┐   │
│ │ 🪙 85G 보상 수령  │   │  ← 버튼 텍스트 변경
│ └─────────────────┘   │
└───────────────────────┘
```

**실패/대실패 시 보상 내역**:
- 기본 보상: 0G, 인건비: 0G (실패 시 보상 없음)
- 파견 비용은 선차감되었으므로 표시 (이미 지출된 비용)
- 순수익: `-{dispatchCost}G` (파견비 손실)
- 경험치: 표시 (실패해도 XP는 획득)
- 명성: 0 (실패 시 미획득)
- 버튼 텍스트: "확인" (보상이 없으므로 "보상 수령" 대신)

### 영향받는 파일

- `lib/features/quest/domain/quest_model.dart`: `ActiveQuest`에 `rewardGold`, `totalWage`, `dispatchCost`, `earnedXp`, `earnedReputation` 필드 추가 (HiveField 12~16)
- `lib/features/quest/domain/quest_provider.dart`:
  - `dispatch()`: `dispatchCost` 저장
  - `_completeQuest()`: `rewardGold`, `totalWage`, `earnedXp`, `earnedReputation` 저장
- `lib/features/quest/view/quest_result_dialog.dart`: 보상 섹션 추가, 버튼 텍스트 변경
- `build_runner` 재실행 필요 (`quest_model.g.dart` 재생성)

---

## 3. 홈 화면 최근활동: 스크롤 지원

### 변경 내용

최근활동을 10개 고정 표시에서 스크롤 가능하도록 변경. 최대 100개까지 표시.

### 현재 문제

- 활동 로그가 10개까지만 보이고 스크롤 불가
- 저장소 최대 50개

### 설계

**UI 변경** (`_buildActivityLog`):
- 현재: `Column` + `logs.take(10).map(...)` (스크롤 없음)
- 변경: 고정 높이 컨테이너 안에 `ListView.builder` 적용
- 초기에 보이는 항목: 약 10개 (컨테이너 높이 기준)
- 스크롤로 볼 수 있는 최대 개수: `min(logs.length, 100)`
- 컨테이너 높이: 로그 1개 행 높이(약 24px) x 10 = 약 240px 고정

**저장소 변경** (`ActivityLogRepository`):
- `maxLogs`: 50 → 100

### 영향받는 파일

- `lib/features/home/view/home_screen.dart`: `_buildActivityLog()` 메서드 — `Column` → 고정 높이 `ListView.builder`
- `lib/features/home/data/activity_log_repository.dart`: `maxLogs` 50 → 100

---

## 변경 범위 요약

| 영역 | 파일 | 변경 유형 |
|------|------|-----------|
| 파견 화면 | `dispatch_screen.dart` | 바텀시트 제거, Navigator.push로 변경 |
| 파견 화면 | `dispatch_detail_page.dart` (신규) | 전체화면 파견 페이지 |
| 퀘스트 팝업 | `quest_model.dart` | 보상 필드 5개 추가 (HiveField 12~16) |
| 퀘스트 팝업 | `quest_provider.dart` | 보상 값 저장 로직 |
| 퀘스트 팝업 | `quest_result_dialog.dart` | 보상 섹션 + 버튼 텍스트 |
| 최근활동 | `home_screen.dart` | Column → ListView.builder |
| 최근활동 | `activity_log_repository.dart` | maxLogs 50 → 100 |
| 코드 생성 | `quest_model.g.dart` | build_runner 재생성 |
