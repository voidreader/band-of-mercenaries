# 엘리트 UI 개발 명세서

> 기획 문서: `Docs/spec/[wip]20260423_m2b-4-4-elite-ui_progress.md`
> 참고 목업: `.superpowers/brainstorm/97424-1776935663/content/elite-ui-mockup.html`
> 작성일: 2026-04-23

## 1. 개요

파견 화면과 퀘스트 완료 팝업에 엘리트 몬스터 2계층(보통/유니크) 시각 구분을 추가한다. 파견 카드에는 색상·배지로 즉시 식별 가능하게 하고, 파견 상세에는 서사 텍스트 카드를 삽입하며, 완료 팝업에는 드랍 결과 섹션을 표시한다. `pendingEliteLootProvider`를 통해 `EliteLootResult`를 팝업 호출 측으로 전달한다.

---

## 2. 요구사항

### 2.1 기능 요구사항

- **[FR-1]** 파견 화면(`dispatch_screen.dart`) 퀘스트 카드 엘리트 시각 분기
  - 조건: `quest.isElite == true` (`quest.eliteId != null`)
  - `eliteData`: `data.eliteMonsters.firstWhereOrNull((m) => m.id == quest.eliteId)` 로 조회
  - 보통 엘리트(`eliteData.isUnique == false`):
    - 좌측 사이드바(width: 3): `Color(0xFFe65100)` (deepOrange)
    - 배지 배경: `Color(0xFF3d2800)`
    - 배지 텍스트: `'🔥 엘리트'`, 색상 `Color(0xFFffb74d)` (orange[300])
    - 퀘스트 이름 색상: `Color(0xFFffb74d)`
    - 테두리: `Color(0xFF4d2600)`
  - 유니크 엘리트(`eliteData.isUnique == true`):
    - 좌측 사이드바(width: 3): `Color(0xFF7b1fa2)` (purple[800])
    - 배지 배경: `Color(0xFF2d1a4d)`
    - 배지 텍스트: `'★ 유니크'`, 색상 `Color(0xFFce93d8)` (purple[200])
    - 퀘스트 이름 색상: `Color(0xFFce93d8)`
    - 테두리: `Color(0xFF3d1a5c)`
  - 세력 배지와의 관계: 엘리트 퀘스트는 세력 태그를 갖지 않으므로 두 배지가 동시 표시되지 않는다. 단, 방어적으로 `quest.isElite`를 우선 처리한다.
  - 서사 텍스트는 카드에 미표시

- **[FR-2]** 파견 상세(`dispatch_detail_page.dart`) 엘리트 서사 카드
  - 조건: `quest.isElite && eliteData != null`
  - 삽입 위치: 헤더 Container(라인 118~179) **이후**, 용병 목록 Expanded(라인 181) **이전**
  - 보통 엘리트: `eliteData.description` 표시
    - 배경: `LinearGradient(colors: [Color(0xFF1a0d00), Color(0xFF2d1500)])`
    - 테두리: `Color(0xFFe65100)`
    - 아이콘 `🔥` + 제목 `'엘리트 몬스터'`
  - 유니크 엘리트: `eliteData.title!` (헤더) + `eliteData.lore!` (본문)
    - 배경: `LinearGradient(colors: [Color(0xFF1a0028), Color(0xFF2d0040)])`
    - 테두리: `Color(0xFF7b1fa2)`
    - 아이콘 `★` + 제목 `eliteData.title`
  - 여백: `margin: EdgeInsets.fromLTRB(14, 8, 14, 0)`, `padding: EdgeInsets.all(12)`
  - `eliteData`가 null이면(데이터 미로드) 이 위젯 미표시

- **[FR-3]** 퀘스트 완료 팝업(`quest_result_dialog.dart`) 드랍 섹션
  - `QuestResultDialog` 생성자에 `final EliteLootResult? eliteLoot` 파라미터 추가
  - 드랍 섹션 import 추가: `elite_loot_service.dart`, `core/models/elite_monster_data.dart`
  - 표시 조건: `eliteLoot != null && (eliteLoot.bonusGold > 0 || eliteLoot.itemDrops.isNotEmpty)`
  - 위치: 보상 내역 Container 아래 `SizedBox(height: 12)` + 드랍 Container
  - 드랍 섹션 Container 구조:
    ```
    decoration: BoxDecoration(
      color: [보통=Color(0xFF1a0d00) / 유니크=Color(0xFF1a0028)],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: [보통=0xFFe65100 / 유니크=0xFF7b1fa2]),
    )
    ```
  - `eliteData`(색상 결정용): `data.eliteMonsters.firstWhereOrNull((m) => m.id == quest.eliteId)` — null이면 보통 색상 기본값
  - 헤더: `Text('🔥 엘리트 드랍' / '★ 유니크 드랍')`, 색상 각각 적용
  - `eliteLoot.bonusGold > 0`이면: `_buildRewardRow('추가 골드', '+${eliteLoot.bonusGold}G', 주황 or 보라)`
  - `eliteLoot.itemDrops`의 각 itemId:
    - `data.items.firstWhereOrNull((i) => i.id == itemId)?.name ?? itemId` 로 이름 조회
    - `_buildRewardRow(아이템명, '획득', 주황 or 보라)`
  - 버튼 골드 합산: `netProfit + (eliteLoot?.bonusGold ?? 0)` — 버튼 텍스트만 합산 표시
  - 보상 내역 섹션의 순수익 행은 `netProfit` 유지 (변경 없음)

- **[FR-4]** `pendingEliteLootProvider` 신규 추가 및 팝업 전달
  - `quest_provider.dart` 내 `pendingTraitEventsProvider`(라인 64) 아래:
    ```dart
    final pendingEliteLootProvider = StateProvider<Map<String, EliteLootResult>>((ref) => {});
    ```
  - `_applyCompletionResult`(라인 429~)에서 eliteLoot 처리 블록(라인 461~471) 이후:
    ```dart
    if (eliteLoot != null) {
      final current = ref.read(pendingEliteLootProvider);
      ref.read(pendingEliteLootProvider.notifier).state = {...current, quest.id: eliteLoot};
    }
    ```
  - `dispatch_screen.dart`의 `_showResult` 함수(라인 365)에서 dialog 호출 전:
    ```dart
    final eliteLoot = ref.read(pendingEliteLootProvider)[quest.id];
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuestResultDialog(quest: quest, eliteLoot: eliteLoot),
    );
    ```
  - dialog 닫힘 후(트레잇 이벤트 처리 뒤, `clearCompleted` 이전):
    ```dart
    final currentLoot = ref.read(pendingEliteLootProvider);
    if (currentLoot.containsKey(quest.id)) {
      ref.read(pendingEliteLootProvider.notifier).state = Map.from(currentLoot)..remove(quest.id);
    }
    ```

### 2.2 데이터 요구사항

- 신규 Provider: `pendingEliteLootProvider = StateProvider<Map<String, EliteLootResult>>` (`quest_provider.dart` 내)
- Hive 박스 변경: **없음** (build_runner 재실행 불필요)
- Freezed 모델 변경: **없음**

### 2.3 UI 요구사항

> Visual Companion 목업: `.superpowers/brainstorm/97424-1776935663/content/elite-ui-mockup.html`

- **퀘스트 카드 엘리트 배지 구조**:
  - 사이드바(width: 3 Container): `_buildQuestCard` 내 `isExclusive` 사이드바(라인 237~247) 패턴과 동일 — `quest.isElite`이면 엘리트 색상, `isExclusive`이면 세력 색상 (우선순위: `isElite > isExclusive`)
  - 배지: 세력 배지 Container(라인 261~287) 패턴 재사용. `faction != null`인 경우 처럼 조건부 추가
  - 퀘스트명 색상: `isElite`이면 엘리트/유니크 색상, 그렇지 않으면 기본 스타일

- **서사 카드 화면 진입 조건**: `quest.isElite == true`이고 `DispatchDetailPage`에 진입 시 자동 표시
- **완료 팝업 전환**: 기존 `_showResult` 흐름 유지 → dialog 직전에 `pendingEliteLootProvider`에서 읽어 전달

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | `pendingEliteLootProvider` 신규 StateProvider 추가; `_applyCompletionResult` 내 eliteLoot 저장 코드 추가 | FR-4 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` | `_buildQuestCard` 엘리트 사이드바·배지·이름색 분기; `_showResult`에서 `pendingEliteLootProvider` 읽어 QuestResultDialog에 전달 + 정리 | FR-1, FR-4 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_detail_page.dart` | 헤더 Container 이후 엘리트 서사 카드 위젯 조건부 삽입 | FR-2 |
| `band_of_mercenaries/lib/features/quest/view/quest_result_dialog.dart` | 생성자에 `EliteLootResult? eliteLoot` 파라미터 추가; 드랍 섹션 렌더링; 버튼 텍스트 골드 합산 | FR-3 |

### 3.2 신규 생성 파일

없음

### 3.3 코드 생성 필요 파일

없음 (HiveField 변경 없음, Freezed/json_serializable 변경 없음)

### 3.4 관련 시스템

- 퀘스트 완료 흐름: `QuestCompletionService` → `_applyCompletionResult` → `pendingEliteLootProvider` (읽기만, 계산 변경 없음)
- 트레잇 이벤트 팝업 체이닝: `_showResult`에서 QuestResultDialog 닫힘 → 트레잇 팝업 → clearCompleted 순서 유지

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `dispatch_screen.dart:237~247` — 세력 전용 퀘스트 사이드바(width: 3 Container) 패턴 재사용
- `dispatch_screen.dart:261~287` — 세력 배지(Container > Row > Text) 패턴 재사용
- `quest_provider.dart:64` — `pendingTraitEventsProvider = StateProvider<Map<String, ...>>` 동일 구조
- `dispatch_screen.dart:373~381` — 트레잇 이벤트 읽기/정리 패턴 (`Map.from(current)..remove(quest.id)`)

### 4.2 주의사항

- `QuestResultDialog`는 `ConsumerWidget`이므로 `staticData.when(data: (data) { ... })` 내부에서 `data.eliteMonsters`, `data.items` 조회 가능
- `pendingEliteLootProvider` 정리는 `clearCompleted` **이전**에 수행해야 quest.id가 아직 유효한 상태에서 제거 가능
- `dispatch_detail_page.dart`의 서사 카드 삽입은 `staticData.when(data: (data) { return Column(children: [...]) })` 내부 Column에서 수행 — data 컨텍스트 내에서만 eliteMonsters 접근 가능
- `dispatch_screen.dart`의 `_buildQuestCard`는 `StaticGameData data` 파라미터를 이미 받으므로 `data.eliteMonsters` 직접 사용 가능
- CLAUDE.md의 `avoid_print: true` — 디버그 print 사용 금지

### 4.3 엣지 케이스

- `quest.eliteId`가 non-null이지만 `eliteMonsters`에서 못 찾는 경우:
  - 카드: 사이드바/배지만 표시 (isUnique 판단 불가 → 보통 색상 기본값 사용)
  - 서사 카드: 미표시
  - 드랍 섹션: 보통 색상 기본값 사용
- `eliteLoot.itemDrops`에 `items` 테이블에 없는 itemId: `itemId` 그대로 표시 (fallback)
- 실패/대실패 결과 → `eliteLoot == null` → 드랍 섹션 미표시 (보상 내역만 표시)
- `pendingEliteLootProvider`에 quest.id가 없는 경우(비엘리트 퀘스트): `QuestResultDialog(eliteLoot: null)` 전달, 팝업 내 조건부 렌더링으로 처리

### 4.4 구현 힌트

- **진입점**:
  1. `dispatch_screen.dart:_buildQuestCard` — 카드 시각 분기 (FR-1)
  2. `dispatch_detail_page.dart:build()` Column 내 삽입 위치 — 라인 179(헤더 끝) ~ 라인 181(Expanded 시작) 사이 (FR-2)
  3. `quest_provider.dart:_applyCompletionResult:471` 이후 — eliteLoot 저장 (FR-4)
  4. `dispatch_screen.dart:_showResult:365~369` — dialog 호출 직전에서 읽어 전달 (FR-4)

- **데이터 흐름**:
  ```
  QuestCompletionService.calculate() → QuestCompletionResult.eliteLoot
    → _applyCompletionResult → pendingEliteLootProvider[quest.id] = eliteLoot
    → dispatch_screen._showResult → ref.read(pendingEliteLootProvider)[quest.id]
    → QuestResultDialog(eliteLoot: ...)
    → dialog 닫힘 후 pendingEliteLootProvider에서 제거
  ```

- **참조 구현**:
  - `quest_provider.dart:609~615` — `pendingTraitEventsProvider` 저장 패턴 (엘리트 loot 저장 동일 방식)
  - `dispatch_screen.dart:373~381` — 트레잇 이벤트 읽기/정리 패턴 (eliteLoot 정리 동일 방식)

- **확장 지점**:
  - `dispatch_screen.dart:_buildQuestCard` → `isExclusive` 사이드바(라인 237) 이전에 `quest.isElite` 사이드바 조건 추가
  - `dispatch_detail_page.dart` → Column children 배열(라인 115의 `children: [`)에서 헤더 Container(children[0]) 다음에 조건부 서사 카드 삽입

---

## 5. 기획 확인 사항

- [Q-1] 데이터 전달 방식 → **방안 B 확정**: `QuestResultDialog`에 `EliteLootResult? eliteLoot` 파라미터 추가. HiveField 변경 없음
- [Q-2] 서사 툴팁 UX → **방안 B 확정**: 파견 상세(DispatchDetailPage) 상단 서사 섹션. 카드에는 배지·색상만
- [Q-3] UI 목업 → **"아주 좋다" 확인 완료**
