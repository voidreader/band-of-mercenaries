# 2026-04-09 요구사항 업데이트 설계

> 원본: `Docs/Requirement/20260409_req.md`

## 개요

8개 영역에 걸친 밸런스 조정, 기능 개선, 신규 기능, 버그 수정.
구현 순서: 버그 수정 → 밸런스 → 기존 시스템 개선 → 신규 기능.

---

## 1. 버그 수정

### 1-1. 시간 가속 모드 수정

**문제**: `gameTickProvider`가 고정 1초 간격. `speedMultiplierProvider`는 duration 계산에만 반영되어 실제 시간 가속이 안 됨.

**해결**: `virtualTimeProvider` 도입.
- `gameTickProvider`는 1초 간격 유지 (UI 갱신 주기)
- 매 틱마다 `virtualNow += speedMultiplier초`를 누적
- 모든 endTime 비교를 `virtualNow` 기준으로 변경 (`_checkCompletions`, `_checkArrival`, `_checkTimers`)
- 속도 변경 시 virtualNow를 실제 시각 기준으로 리셋하여 불일치 방지

**영향 범위**:
- `core/providers/timer_provider.dart` — virtualTimeProvider 추가
- `features/quest/domain/quest_provider.dart` — 완료 체크 로직
- `features/movement/domain/movement_provider.dart` — 도착 체크 로직
- `features/mercenary/domain/mercenary_provider.dart` — 상태 회복 체크 로직

### 1-2. 퀘스트 완료 화면 깜빡임 + 확인 버튼 먹통

**문제**: `dispatch_screen.dart`의 `build()` 내에서 매 렌더 사이클마다 completed 퀘스트를 감지하고 `addPostFrameCallback`으로 다이얼로그를 띄움. 다이얼로그가 중첩 호출되면서 깜빡임 + 버튼 먹통.

**해결**:
- 다이얼로그 표시 상태를 `_isShowingResult` 플래그로 관리
- completed 퀘스트 ID를 `_shownResultIds` Set으로 추적하여 중복 표시 방지
- `build()` 내 감지 로직을 `ref.listen()`으로 이동하여 상태 변경 시에만 트리거
- 다이얼로그는 한 번에 하나만 표시되도록 보장

**영향 범위**:
- `features/quest/view/dispatch_screen.dart`

---

## 2. 밸런스 — 파견 비용 구조 변경

**현재**: `Difficulty.json`에 고정 비용 20/50/100/200/400G.

**변경**: 난이도별 최소~최대 범위, 퀘스트 소요시간에 따라 선형 보간.

### Difficulty.json 변경

| 난이도 | MinDispatchCost | MaxDispatchCost |
|--------|-----------------|-----------------|
| 1      | 5               | 30              |
| 2      | 10              | 60              |
| 3      | 20              | 100             |
| 4      | 35              | 150             |
| 5      | 50              | 200             |

기존 `DispatchCost` 필드를 `MinDispatchCost`, `MaxDispatchCost`로 교체.

### 비용 계산 공식

```
duration = baseDuration * (1 + (difficulty - 1) * 0.2)
maxDuration = 144  // 최대 baseDuration(80) * 난이도5 보정(1.8)
ratio = clamp(duration / maxDuration, 0, 1)
cost = minCost + (maxCost - minCost) * ratio
```

**영향 범위**:
- `assets/json/Difficulty.json` — 필드 변경
- `core/models/` — Difficulty 모델 필드 변경
- `features/quest/domain/quest_calculator.dart` — `calculateDispatchCost()` 메서드 추가
- `features/quest/domain/quest_provider.dart` — 비용 차감 로직
- `features/quest/view/dispatch_screen.dart` — 비용 표시

---

## 3. 퀘스트 시스템 개선

### 3-1. 첫 실행 시 퀘스트 자동 생성

- `questListProvider` 초기화 시 퀘스트가 0개이면 자동으로 `generateQuests()` 호출
- 별도 생성 버튼 불필요

### 3-2. 1시간마다 대기 중 퀘스트 갱신

- `ActiveQuest` 모델에 `createdAt` (DateTime) 필드 추가
- 게임 틱에서 대기 중(pending) 퀘스트의 `createdAt`이 1시간 경과했는지 체크 (virtualTime 기준)
- 경과한 퀘스트는 삭제 후 새 퀘스트로 교체
- 각 퀘스트 카드에 "갱신까지 MM:SS" 카운트다운 표시 (퀘스트별 개별 타이머, 생성 시점 기준 1시간)

### 3-3. 퀘스트 채우기 버튼

- 활성 퀘스트(pending + inProgress) 합산이 최대 개수(5 + 정보망 보너스) 미만일 때 "퀘스트 채우기" 버튼 표시
- 버튼 누르면 부족한 수만큼 새 퀘스트 생성
- 최대 개수 이상이면 버튼 숨김

### 3-4. 파견 인원 선택 바텀시트

**현재**: 퀘스트 선택 시 화면 하단 인라인 리스트로 용병 표시.

**변경**:
- 퀘스트 탭 시 `DraggableScrollableSheet` 바텀시트 올라옴
- 바텀시트 내용: 사용 가능 용병 리스트 (체크박스 선택) + 선택된 인원 수 + 파견 버튼
- 바텀시트 높이: 화면의 40%~80% 드래그 조절
- 부상/사망/파견 중 용병은 비활성 표시

**영향 범위**:
- `features/quest/domain/quest_model.dart` — `createdAt` 필드 추가
- `features/quest/domain/quest_generator.dart` — 자동 생성 로직
- `features/quest/domain/quest_provider.dart` — 갱신 체크, 채우기 로직
- `features/quest/view/dispatch_screen.dart` — 갱신 타이머 UI, 채우기 버튼, 바텀시트

---

## 4. 홈 화면 개선

### 4-1. 용병단 요약 대시보드

랭크 섹션 아래, 야영지 위에 카드형 대시보드:
- 보유 용병: 총원 / 최대
- 파견 중: 파견 인원 수
- 상태: 정상/부상/사망 인원 수 (아이콘 + 숫자)
- 총 전투력: 사용 가능 용병의 전투력 합산

2x2 그리드로 간결하게 표시.

### 4-2. 최근 활동 로그

- `ActivityLog` 모델 신규 생성 (`timestamp`, `message`, `type`)
- 로그 타입: 퀘스트 결과, 용병 상태 변경, 이동 완료, 용병 모집/방출, 레벨업
- Hive에 `activityLogs` 박스 추가, 최대 50개 유지
- UI: 타임스탬프 + 메시지, 타입별 아이콘/색상 구분
- 각 이벤트 발생 로직에서 로그 추가 호출

### 4-3. 퀘스트 완료 알림 (홈 화면)

- 홈 화면 진행 상황 패널에서 완료된 퀘스트에 "완료!" 배지 표시
- 해당 항목 탭 시 결과 다이얼로그 표시 (기존 `QuestResultDialog` 재사용)
- 결과 확인 후 퀘스트 정리

**영향 범위**:
- `features/home/view/home_screen.dart` — 대시보드, 로그, 완료 알림 UI
- `features/home/domain/` — ActivityLog 모델, ActivityLogNotifier
- `features/home/data/` — ActivityLogRepository (Hive)
- 각 이벤트 발생 지점 — 로그 기록 호출 추가

---

## 5. 이동 제한

- `movementProvider`에서 이동 시작 전 파견 중(inProgress) 퀘스트 존재 여부 체크
- 파견 중인 용병이 있으면:
  - 이동 버튼 비활성화 (`onPressed: null`)
  - 버튼 텍스트를 "파견된 용병이 있습니다"로 변경
- 파견 완료 후 자동으로 버튼 활성화 복구

**영향 범위**:
- `features/movement/view/movement_screen.dart` — 버튼 상태 분기
- `features/movement/domain/movement_provider.dart` — 이동 가능 여부 체크 (questListProvider 참조)

---

## 6. 용병 방출

- 모집 화면에 용병별 "방출" 버튼 추가
- **방출 조건**: 파견 중이 아닌 용병만 방출 가능
- **퇴직금**: 인건비(티어별) × 레벨. 골드 부족 시 방출 불가
- **확인 다이얼로그**: "용병 [이름]을 방출합니다. 퇴직금 [N]G가 차감됩니다. 방출된 용병은 다시 모집할 수 없습니다."
- **영구 제거**: 방출된 용병 ID를 `dismissedMercenaryIds` Set에 저장 (Hive). 모집 시 동일 ID 재등장 방지
- **활동 로그**: 방출 시 로그 기록

**영향 범위**:
- `features/mercenary/view/recruit_screen.dart` — 방출 버튼, 확인 다이얼로그
- `features/mercenary/domain/mercenary_provider.dart` — 방출 로직, 퇴직금 차감
- `features/mercenary/data/mercenary_repository.dart` — dismissedMercenaryIds 저장

---

## 7. 방치형 오프라인 골드 보상

- **마지막 접속 시간 저장**: 앱 백그라운드 진입 시 `lastActiveTime`을 Hive에 저장 (`WidgetsBindingObserver`의 `AppLifecycleState.paused`)
- **접속 시 계산**: 앱 시작 시 `DateTime.now() - lastActiveTime`으로 미접속 시간 산출
- **보상**: 분당 1G, 최대 480분(8시간) = 480G 상한
- **보상 팝업**: 미접속 시간 1분 이상이면 "부재 중 [N]G를 획득했습니다" 팝업 표시 후 골드 지급
- **시간 가속 미적용**: 실제 미접속 시간 기준

**영향 범위**:
- `main.dart` 또는 `app.dart` — WidgetsBindingObserver, 보상 계산/팝업
- `core/data/` — lastActiveTime Hive 저장/조회
- `core/providers/game_state.dart` — 골드 지급
