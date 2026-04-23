# M2b 4-4 엘리트 UI — spec-pipeline 진행 상황 (WIP)

> 작성일: 2026-04-23  
> 상태: **4단계(명세서 생성) 대기** — 1~3단계 완료, 사용자 확인 완료

---

## 재개 방법

다음 세션에서 `/spec-pipeline` 이 파일을 참고하여 **4단계(명세서 생성)부터** 바로 시작한다.

```
/spec-pipeline @Docs/spec/[wip]20260423_m2b-4-4-elite-ui_progress.md
```

→ 위 명령 대신, 다음 세션에서 직접 이렇게 요청해도 됨:
"m2b 4-4 엘리트 UI 명세서 작성 이어서 진행해줘"

---

## 입력 기획 문서

- `Docs/spec/[spec]20260423_m2b-4-3-elite-quest-loot_plan.md` — Phase 4-3 구현 결과 (QuestCompletionResult.eliteLoot 구조)
- `Docs/content-design/[content]20260420_elite_monster_catalog.md` — 엘리트 2계층 구조, 서사 텍스트

---

## 완료된 단계

### 1단계: 기획 문서 분석 ✅

**대상 기능**: M2b 4-4 — 파견 화면 보통·유니크 2계층 구분 UI + 퀘스트 완료 팝업 드랍 결과 리스트

**핵심 동작**:
- 파견 화면 퀘스트 카드: 보통 엘리트(주황 사이드바·배지·아이콘) vs 유니크 엘리트(보라 사이드바·배지·아이콘)
- 파견 상세(DispatchDetailPage) 상단: 엘리트 서사 카드 (보통=description / 유니크=title+lore)
- 퀘스트 완료 팝업(QuestResultDialog): EliteLootResult 기반 드랍 섹션 추가

---

### 2단계: 코드베이스 탐색 ✅

**핵심 파일 및 구조**:

| 파일 | 역할 | 관련 발견 |
|------|------|----------|
| `features/quest/view/dispatch_screen.dart` | 파견 화면 (퀘스트 카드) | `_buildQuestCard()` 202-363줄. `quest.questName` 표시. 세력 배지 패턴(242-287줄) 재사용 가능 |
| `features/quest/view/dispatch_detail_page.dart` | 파견 상세 | 상단 헤더 구조 확인. 엘리트 서사 카드 삽입 위치 = 헤더 바로 아래 |
| `features/quest/view/quest_result_dialog.dart` | 완료 팝업 | `final ActiveQuest quest` 단일 인자. 보상 77-112줄. 엘리트 섹션 없음 |
| `features/quest/domain/quest_completion_service.dart` | 완료 계산 | `QuestCompletionResult.eliteLoot: EliteLootResult?` 존재 확인 |
| `features/quest/domain/elite_loot_service.dart` | 드랍 판정 | `EliteLootResult { bonusGold: int, itemDrops: List<String> }` |
| `features/quest/domain/quest_model.dart` | 퀘스트 모델 | `HiveField(20) String? eliteId` + `bool get isElite => eliteId != null` |
| `core/models/elite_monster_data.dart` | 엘리트 데이터 | `name, description, isUnique, tier, typeFamily, lore?, title?` |
| `core/providers/static_data_provider.dart` | 정적 데이터 | `StaticGameData.eliteMonsters: List<EliteMonsterData>` 확인 |

**quest_provider.dart 완료 팝업 호출 흐름**:
- `_completeQuest()` → `QuestCompletionService.calculate()` → `QuestCompletionResult` (eliteLoot 포함)
- `_applyCompletionResult()` → eliteLoot 인벤토리 적재
- 현재 팝업: `showQuestResultDialog(quest)` — eliteLoot 미전달

---

### 2.5단계: UI 목업 시각화 ✅

목업 파일: `.superpowers/brainstorm/97424-1776935663/content/elite-ui-mockup.html`  
(서버 종료 후 파일만 남음 — 내용은 아래 3단계 결정사항으로 명세서에 반영)

**확정된 UI 디자인**:

#### 파견 카드 (dispatch_screen.dart `_buildQuestCard`)
- 보통 엘리트: 좌측 사이드바 `#e65100`(주황) + 배지 `[엘리트]`(주황) + 아이콘 🔥 + 제목색 `#ffb74d` + 테두리 `#4d2600`
- 유니크 엘리트: 좌측 사이드바 `#7b1fa2`(보라) + 배지 `[유니크]`(보라) + 아이콘 ★ + 제목색 `#ce93d8` + 테두리 `#3d1a5c`
- 서사 텍스트는 카드에 없음

#### 파견 상세 (dispatch_detail_page.dart)
- `quest.isElite` 시 헤더 다음 위치에 서사 카드 삽입
- 보통: `EliteMonsterData.description` (주황 테두리 `#e65100`, 다크 주황 그라디언트 배경)
- 유니크: `EliteMonsterData.title` + `EliteMonsterData.lore` (보라 테두리 `#7b1fa2`, 다크 보라 그라디언트 배경)
- 데이터: `staticData.eliteMonsters.firstWhereOrNull((m) => m.id == quest.eliteId)`

#### 완료 팝업 (quest_result_dialog.dart)
- 생성자에 `EliteLootResult? eliteLoot` 파라미터 추가 (방안 B)
- 드랍 섹션 표시 조건: `eliteLoot != null && (eliteLoot.bonusGold > 0 || eliteLoot.itemDrops.isNotEmpty)`
- 실패/대실패: eliteLoot == null → 섹션 미표시
- 아이템명: `staticData.items.firstWhereOrNull((i) => i.id == itemId)?.name ?? itemId`
- 버튼 골드 합산: `netProfit + (eliteLoot?.bonusGold ?? 0)`
- 색상: isUnique 시 보라 / 보통은 주황 (EliteMonsterData 조회 필요)

---

### 3단계: 기획 의도 확인 ✅ (사용자 확인 완료)

| 질문 | 선택 | 내용 |
|------|------|------|
| Q-1 데이터 전달 방식 | **방안 B** | QuestResultDialog에 `EliteLootResult? eliteLoot` 파라미터 추가. HiveField 변경 없음 |
| Q-2 서사 툴팁 UX | **방안 B** | 파견 상세(DispatchDetailPage) 상단에 서사 섹션. 카드에는 배지·색상만 |
| Q-3 UI 목업 | **진행** | 목업 확인 완료, "아주 좋다" 피드백 |

---

## 다음 세션에서 할 일

### [4단계] 명세서 생성 → `Docs/spec/[spec]20260423_m2b-4-4-elite-ui.md`

위 모든 정보를 바탕으로 spec-writer 형식의 명세서를 작성한다.

**수정 대상 파일**:
1. `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` — `_buildQuestCard()` 엘리트 분기
2. `band_of_mercenaries/lib/features/quest/view/dispatch_detail_page.dart` — 엘리트 서사 카드 위젯 삽입
3. `band_of_mercenaries/lib/features/quest/view/quest_result_dialog.dart` — 생성자 + 드랍 섹션
4. 퀘스트 완료 팝업 호출 측 (`quest_provider.dart`) — `eliteLoot` 파라미터 전달

**빌드 재실행 불필요** (HiveField 변경 없음, Freezed 모델 변경 없음)

### [2단계 재확인 필요]
- `dispatch_detail_page.dart` 실제 헤더 구조 → 명세서 작성 전 Read로 확인
- `quest_provider.dart` 팝업 호출 코드 라인 → eliteLoot 전달 위치 특정

### [5단계] 구현 방식 추천 (PASS 후)

### [verify-spec] Opus sub-agent 검증

---

## 참고: 색상 상수

| 용도 | 색상 | 비고 |
|------|------|------|
| 보통 엘리트 사이드바/테두리 | `#e65100` (deepOrange) | `AppTheme` 상수 없으면 인라인 |
| 보통 엘리트 배지 배경 | `#3d2800` | |
| 보통 엘리트 제목 | `#ffb74d` (orange[300]) | |
| 유니크 사이드바/테두리 | `#7b1fa2` (purple[800]) | |
| 유니크 배지 배경 | `#2d1a4d` | |
| 유니크 제목 | `#ce93d8` (purple[200]) | |
