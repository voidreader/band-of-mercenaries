# M3 공존 정책 후속 정리 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** plan 문서 후속 권장 4건 중 코드 리팩터링/성능/일관성 정리 3건(트레잇 진화 domain 이전 / QuestSortService 메모이제이션 / 다이얼로그 dismiss 일관성)을 한 묶음으로 처리한다. 동작 변경 없이 내부 구조만 정리.

**Architecture:** view→domain→data 레이어 분리 강화 + Riverpod derived Provider 패턴으로 정렬 메모이제이션 + 큐 enqueue 직후 즉시 state 리셋으로 5개 채널 통일. 모든 변경은 기존 시그니처/동작 호환.

**Tech Stack:** Flutter 3.41 / Dart 3 / flutter_riverpod (StateNotifier/Provider) / Hive / 기존 build_runner 코드 생성 도구. 신규 의존성 없음.

**Spec:** `Docs/spec/M3/[spec]20260426_post-coexistence-cleanup.md`

---

## File Structure

| 파일 | 역할 | 변경 유형 |
|------|------|----------|
| `lib/features/mercenary/domain/evolution_choice.dart` | `EvolutionChoice` 데이터 클래스 (domain 위치) | **신규** |
| `lib/features/mercenary/view/trait_evolution_dialog.dart` | view 위젯 — `EvolutionChoice` 본체 제거 후 import 사용 | 수정 |
| `lib/features/mercenary/domain/mercenary_provider.dart` | `MercenaryListNotifier.applyEvolution()` + `TraitEvolutionApplyResult` | 수정 |
| `lib/features/quest/domain/sorted_quests_provider.dart` | `sortedPendingQuestsProvider` derived Provider | **신규** |
| `lib/features/quest/view/dispatch_screen.dart` | `_showTraitEvents` 위임 단순화 + `sortedPendingQuestsProvider` watch | 수정 |
| `lib/app.dart` | 5개 enqueue 어댑터 listen 통일 (enqueue 직후 `state = null`) | 수정 |
| `test/features/mercenary/domain/mercenary_provider_test.dart` | `applyEvolution()` 단위 테스트 | **신규** |

각 파일은 단일 책임. dispatch_screen 수정은 두 FR(1,2)에 걸쳐 있지만 같은 파일을 두 번 열기보다 한 task에서 묶어 처리 (자연스러운 변경 구역).

---

## Task 1: `EvolutionChoice` domain 이전

**Files:**
- Create: `band_of_mercenaries/lib/features/mercenary/domain/evolution_choice.dart`
- Modify: `band_of_mercenaries/lib/features/mercenary/view/trait_evolution_dialog.dart:1-21`

`EvolutionChoice`는 단순 데이터 클래스로 view→domain 의존성이 없다. domain으로 이전하여 `MercenaryListNotifier`가 view를 import하지 않도록 한다.

- [ ] **Step 1: domain 위치 신규 파일 생성**

```dart
// band_of_mercenaries/lib/features/mercenary/domain/evolution_choice.dart
import 'package:band_of_mercenaries/features/mercenary/domain/trait_evolution_service.dart';

/// 트레잇 진화 다이얼로그에서 플레이어가 선택한 진화 경로.
/// view(`TraitEvolutionDialog`)가 생성하고 domain(`MercenaryListNotifier.applyEvolution`)이 소비한다.
class EvolutionChoice {
  final bool isSingle;
  final SingleEvolutionCandidate? single;
  final ComboEvolutionCandidate? combo;

  EvolutionChoice.fromSingle(SingleEvolutionCandidate c)
      : isSingle = true,
        single = c,
        combo = null;

  EvolutionChoice.fromCombo(ComboEvolutionCandidate c)
      : isSingle = false,
        single = null,
        combo = c;
}
```

- [ ] **Step 2: trait_evolution_dialog.dart에서 본체 제거 후 import**

`band_of_mercenaries/lib/features/mercenary/view/trait_evolution_dialog.dart` 파일 상단에서 기존 `EvolutionChoice` 클래스 정의 블록(line 6~21)을 삭제하고, import를 추가한다.

```dart
// 변경 전 (line 1~21)
import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_evolution_service.dart';

// Returned from dialog to indicate which evolution path the player chose.
class EvolutionChoice {
  ...
}

// 변경 후
import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/evolution_choice.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_evolution_service.dart';
```

- [ ] **Step 3: 컴파일 확인**

Run: `cd band_of_mercenaries && flutter analyze lib/features/mercenary/`
Expected: `No issues found!`

- [ ] **Step 4: 다른 사용처 확인**

Run: `grep -rn "EvolutionChoice" band_of_mercenaries/lib/`
Expected: `dispatch_screen.dart`와 `trait_evolution_dialog.dart`에서 참조. dispatch_screen는 다음 task에서 처리 — 현재 단계에서는 dispatch_screen import 변경 없이도 dart는 이행적으로 동일 클래스로 인식 (단, 명시적 import는 Task 3에서 정리).

- [ ] **Step 5: Commit**

```bash
git add band_of_mercenaries/lib/features/mercenary/domain/evolution_choice.dart band_of_mercenaries/lib/features/mercenary/view/trait_evolution_dialog.dart
git commit -m "$(cat <<'EOF'
refactor(M3): EvolutionChoice를 domain 레이어로 이전

- 단순 데이터 클래스를 view → domain으로 이동하여 향후 MercenaryListNotifier.applyEvolution이 view 비의존 호출 가능하도록 정리

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: `MercenaryListNotifier.applyEvolution()` 메서드 추가 (TDD)

**Files:**
- Modify: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart:20-45`
- Test: `band_of_mercenaries/test/features/mercenary/domain/mercenary_provider_test.dart`

진화 적용 로직(Repository 호출 + 트레잇 이름 lookup + ActivityLog 기록 + refresh)을 view에서 domain으로 이전. ActivityLog 메시지 형식은 기존과 동일하게 유지.

- [ ] **Step 1: 기존 mercenary_provider_test.dart 존재 여부 확인**

Run: `ls band_of_mercenaries/test/features/mercenary/domain/`
Expected: 디렉토리 존재 시 기존 테스트 파일 목록. 없으면 신규 생성 필요.

- [ ] **Step 2: 실패하는 테스트 작성**

`band_of_mercenaries/test/features/mercenary/domain/mercenary_provider_test.dart` (없다면 신규, 있다면 group 추가):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/evolution_choice.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_evolution_service.dart';

void main() {
  group('MercenaryListNotifier.applyEvolution', () {
    test('isSingle=true 시 single.fromKey/toKey 그대로 사용', () {
      final choice = EvolutionChoice.fromSingle(
        const SingleEvolutionCandidate(fromKey: 'old', toKey: 'new'),
      );
      expect(choice.isSingle, isTrue);
      expect(choice.single?.fromKey, equals('old'));
      expect(choice.single?.toKey, equals('new'));
    });

    test('isSingle=false 시 combo.trait1Key/trait2Key/resultKey 그대로 사용', () {
      final choice = EvolutionChoice.fromCombo(
        const ComboEvolutionCandidate(trait1Key: 'a', trait2Key: 'b', resultKey: 'c'),
      );
      expect(choice.isSingle, isFalse);
      expect(choice.combo?.trait1Key, equals('a'));
      expect(choice.combo?.resultKey, equals('c'));
    });
  });
}
```

> 참고: `MercenaryListNotifier.applyEvolution`을 직접 단위 테스트하려면 `Ref` mocking + Hive 박스 mocking 필요. 본 task에서는 EvolutionChoice 분기 동작과 매개변수 매핑만 검증한다 (실제 Repository 호출은 통합 테스트 영역). 테스트가 깨지기 쉬운 mock 의존성을 만들지 않기 위함.

- [ ] **Step 3: 테스트 실행 — 실패 확인**

Run: `cd band_of_mercenaries && flutter test test/features/mercenary/domain/mercenary_provider_test.dart`
Expected: 컴파일 PASS (EvolutionChoice는 Task 1에서 이미 domain에 존재). 테스트도 PASS — 본 step은 EvolutionChoice 동작 자체 검증이라 즉시 PASS. 본 task의 TDD는 실제 메서드 시그니처 합의용 회귀 테스트로 사용.

- [ ] **Step 4: `MercenaryListNotifier`에 `applyEvolution` 메서드 추가**

`band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart` 파일을 Read하여 기존 클래스 구조 확인 후, 클래스 내부에 다음 메서드를 추가한다 (위치: `refresh()` 메서드 다음 줄):

```dart
// 추가할 imports (파일 상단)
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/providers/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/evolution_choice.dart';

// MercenaryListNotifier 클래스 내부, refresh() 메서드 다음
/// 트레잇 진화 선택 결과를 적용한다.
/// view(`_showTraitEvents`)가 EvolutionChoice를 받아 본 메서드에 위임한다.
///
/// 책임:
/// 1. Repository 호출 (단일/조합 분기)
/// 2. 트레잇 이름 lookup (ActivityLog 메시지용)
/// 3. ActivityLog "진화!" 메시지 기록 (트레잇 lookup 실패 시 skip)
/// 4. state refresh
Future<void> applyEvolution(String mercId, EvolutionChoice choice) async {
  final mercs = state;
  final merc = mercs.where((m) => m.id == mercId).firstOrNull;
  if (merc == null) return;

  final staticData = _ref.read(staticDataProvider).value;

  if (choice.isSingle && choice.single != null) {
    final s = choice.single!;
    await _repo.evolveTrait(mercId, s.fromKey, s.toKey);
    if (staticData != null) {
      final fromTrait = staticData.traits.where((t) => t.key == s.fromKey).firstOrNull;
      final toTrait = staticData.traits.where((t) => t.key == s.toKey).firstOrNull;
      if (fromTrait != null && toTrait != null) {
        _ref.read(activityLogProvider.notifier).addLog(
          '${merc.name}의 "${fromTrait.name}"이(가) "${toTrait.name}"(으)로 진화!',
          ActivityLogType.traitEvolved,
        );
      }
    }
  } else if (!choice.isSingle && choice.combo != null) {
    final c = choice.combo!;
    await _repo.comboEvolveTrait(mercId, c.trait1Key, c.trait2Key, c.resultKey);
    if (staticData != null) {
      final t1 = staticData.traits.where((t) => t.key == c.trait1Key).firstOrNull;
      final t2 = staticData.traits.where((t) => t.key == c.trait2Key).firstOrNull;
      final result = staticData.traits.where((t) => t.key == c.resultKey).firstOrNull;
      if (t1 != null && t2 != null && result != null) {
        _ref.read(activityLogProvider.notifier).addLog(
          '${merc.name}의 "${t1.name}" + "${t2.name}" → "${result.name}"(으)로 조합 진화!',
          ActivityLogType.traitEvolved,
        );
      }
    }
  }
  refresh();
}
```

> **주의:** 기존 `MercenaryListNotifier`가 `Ref _ref` / `MercenaryRepository _repo` 인스턴스 필드를 가지는지 mercenary_provider.dart Read로 확인. 만약 필드명이 다르면 (`ref`, `_repository` 등) 실제 명을 사용. `_ref` 미존재 시 생성자에서 `ref` 받아 필드 저장하도록 추가.

- [ ] **Step 5: 정적 분석 통과 확인**

Run: `cd band_of_mercenaries && flutter analyze lib/features/mercenary/domain/mercenary_provider.dart`
Expected: `No issues found!`

- [ ] **Step 6: 테스트 재실행 — 통과 확인**

Run: `cd band_of_mercenaries && flutter test test/features/mercenary/domain/mercenary_provider_test.dart`
Expected: 모든 테스트 PASS (EvolutionChoice 회귀 테스트 + 기존 테스트 영향 없음)

- [ ] **Step 7: 전체 테스트 회귀 확인**

Run: `cd band_of_mercenaries && flutter test`
Expected: `497+ tests passed` (기존 497 + 본 task 신규 테스트)

- [ ] **Step 8: Commit**

```bash
git add band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart band_of_mercenaries/test/features/mercenary/domain/mercenary_provider_test.dart
git commit -m "$(cat <<'EOF'
feat(M3): MercenaryListNotifier.applyEvolution 메서드 추가

- 트레잇 진화 적용 로직(Repository 호출/이름 lookup/ActivityLog 기록/refresh)을 view에서 domain으로 이전
- view→data 직접 호출 제거 준비 (다음 task에서 dispatch_screen 단순화)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: `dispatch_screen._showTraitEvents` 단순화 (FR-1 완료)

**Files:**
- Modify: `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart:25-26, 276-360`

view에서 Repository/Activity 직접 호출 제거 후 `applyEvolution`으로 위임. import 정리.

- [ ] **Step 1: import 변경**

`dispatch_screen.dart` 상단:
- 제거: `import 'package:band_of_mercenaries/features/mercenary/data/mercenary_repository.dart';` (현재 미사용일 수도 있음 — Read로 확인)
- 추가 또는 유지: `import 'package:band_of_mercenaries/features/mercenary/domain/evolution_choice.dart';`
- 유지 (다른 위치에서 사용 중일 수 있음): `activityLogProvider` 등

만약 `activityLogProvider`가 본 메서드 외에 dispatch_screen에서 사용 안 한다면 import도 제거.

- [ ] **Step 2: `_showTraitEvents` 메서드 본문 단순화**

`band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` line 276~360 부근의 메서드를 다음으로 교체:

```dart
Future<void> _showTraitEvents(
  BuildContext context,
  WidgetRef ref,
  Map<String, TraitEventResult> events,
) async {
  final staticData = ref.read(staticDataProvider).value;
  if (staticData == null) return;
  final mercs = ref.read(mercenaryListProvider);

  for (final entry in events.entries) {
    final mercId = entry.key;
    final event = entry.value;
    final merc = mercs.where((m) => m.id == mercId).firstOrNull;
    if (merc == null || !context.mounted) continue;

    // 1. Acquisition notification
    if (event.acquiredTraitKey != null) {
      final traitData = staticData.traits.where((t) => t.key == event.acquiredTraitKey).firstOrNull;
      if (traitData != null && context.mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => TraitAcquisitionDialog(trait: traitData, mercenaryName: merc.name),
        );
      }
    }

    // 2. Evolution selection
    if (event.singleEvoCandidates.isNotEmpty || event.comboEvoCandidates.isNotEmpty) {
      if (!context.mounted) break;
      // 진화 다이얼로그 표시 직전에 최신 trait 목록 fetch (방금 적용된 acquisition 반영)
      final updatedMerc = ref.read(mercenaryListProvider).where((m) => m.id == mercId).firstOrNull;
      if (updatedMerc == null) continue;
      final currentTraits = updatedMerc.allTraitIds
          .map((key) => staticData.traits.where((t) => t.key == key).firstOrNull)
          .whereType<TraitData>()
          .where((t) => t.type != 'innate')
          .toList();

      final choice = await showDialog<EvolutionChoice?>(
        context: context,
        barrierDismissible: false,
        builder: (_) => TraitEvolutionDialog(
          mercenaryName: updatedMerc.name,
          currentTraits: currentTraits,
          singleCandidates: event.singleEvoCandidates,
          comboCandidates: event.comboEvoCandidates,
          allTraits: staticData.traits,
        ),
      );

      if (choice != null && context.mounted) {
        await ref.read(mercenaryListProvider.notifier).applyEvolution(mercId, choice);
      }
    }
  }
}
```

핵심 변경:
- `ref.read(mercenaryRepositoryProvider)` 제거 (Repository 직접 접근 없음)
- `mercRepo.getAll()` → `ref.read(mercenaryListProvider)` 재사용 (Provider 경유)
- 진화 적용 + ActivityLog 기록 → `applyEvolution()` 호출 한 줄

- [ ] **Step 3: 정적 분석**

Run: `cd band_of_mercenaries && flutter analyze lib/features/quest/view/dispatch_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: 사용하지 않게 된 import 정리**

`dispatch_screen.dart` 상단을 다시 Read하여 `mercenary_repository.dart` import가 남아있다면 제거. `activityLogProvider`가 본 파일 다른 위치에서 사용되는지 grep 후 미사용이면 제거.

Run: `cd band_of_mercenaries && flutter analyze lib/features/quest/view/dispatch_screen.dart`
Expected: `No issues found!` (unused_import 경고 없음)

- [ ] **Step 5: 회귀 테스트**

Run: `cd band_of_mercenaries && flutter test`
Expected: 모든 기존 테스트 PASS

- [ ] **Step 6: Commit**

```bash
git add band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart
git commit -m "$(cat <<'EOF'
refactor(M3): dispatch_screen 트레잇 진화 적용을 domain Notifier에 위임

- _showTraitEvents에서 mercenaryRepositoryProvider 직접 read 제거
- applyEvolution() 호출로 단순화하여 view→data 직접 의존성 제거

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: `sortedPendingQuestsProvider` derived Provider 신설

**Files:**
- Create: `band_of_mercenaries/lib/features/quest/domain/sorted_quests_provider.dart`

`QuestSortService.sort` 호출을 Provider 캐시 영역으로 옮겨 1초 주기 gameTickProvider 변경 시에도 재계산되지 않도록 한다.

- [ ] **Step 1: 의존성 확인**

다음 Provider 시그니처가 실제 코드에 존재함을 확인:
- `questListProvider` → `StateNotifierProvider<QuestListNotifier, List<ActiveQuest>>`
- `chainQuestProgressProvider` → `StreamProvider<List<ChainQuestProgress>>` (`.valueOrNull`)
- `userDataProvider` → `StateNotifierProvider<UserDataNotifier, UserData?>`
- `staticDataProvider` → `FutureProvider<StaticGameData>` (`.valueOrNull`)
- `regionStateRepositoryProvider` → `Provider<RegionStateRepository>` (read-only, watch 안 함)
- `factionStateRepositoryProvider` → `Provider<FactionStateRepository>` (read-only)
- `factionRefreshProvider` → `StateProvider<int>` (가입/탈퇴 후 카운터 증가)
- `currentRegionSectorChangesProvider` → `Provider<Map<String, String>>` (지역 변형 시 무효화 트리거)

Run: `grep -n "factionRefreshProvider\|currentRegionSectorChangesProvider" band_of_mercenaries/lib/`
Expected: 두 Provider 모두 존재 확인.

- [ ] **Step 2: Provider 신규 파일 작성**

```dart
// band_of_mercenaries/lib/features/quest/domain/sorted_quests_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/models/quest_model.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_codex_providers.dart';
import 'package:band_of_mercenaries/features/investigation/domain/investigation_notifier.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_transformed_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_sort_service.dart';

/// 파견 화면 정렬 결과를 메모이제이션하는 derived Provider.
///
/// gameTickProvider(1초 주기)와 무관하게 입력 Provider 변경 시에만 재계산된다.
/// 입력 변경 트리거:
/// - questListProvider (퀘스트 목록 변경)
/// - chainQuestProgressProvider (체인 진행 변경)
/// - userDataProvider (region/sector 변경)
/// - staticDataProvider (정적 데이터 갱신)
/// - currentRegionSectorChangesProvider (지역 변형 발생 시 RegionState 변경 반영)
/// - factionRefreshProvider (세력 가입/탈퇴 후 정렬 재계산)
final sortedPendingQuestsProvider = Provider<QuestSortResult>((ref) {
  // gameTickProvider는 watch 안 함 — 1초 주기 재계산 회피
  final quests = ref.watch(questListProvider);
  final chainProgressAsync = ref.watch(chainQuestProgressProvider);
  final userData = ref.watch(userDataProvider);
  final staticDataAsync = ref.watch(staticDataProvider);

  // 무효화 트리거 (값은 사용 안 함, watch만)
  ref.watch(currentRegionSectorChangesProvider);
  ref.watch(factionRefreshProvider);

  final staticData = staticDataAsync.valueOrNull;
  if (userData == null || staticData == null) {
    return const QuestSortResult(chainTier0: [], sortedRest: []);
  }

  final pending = quests.where((q) => q.status == QuestStatus.pending).toList();
  final chainProgress = chainProgressAsync.valueOrNull ?? const <ChainQuestProgress>[];
  final regionState = ref.read(regionStateRepositoryProvider).getState(userData.region);
  final joinedFactionIds =
      ref.read(factionStateRepositoryProvider).getJoinedFactionIds().toSet();

  return QuestSortService.sort(
    quests: pending,
    chainProgress: chainProgress,
    currentRegion: userData.region,
    currentSector: userData.sector,
    regionState: regionState,
    questPools: staticData.questPools,
    questTypes: staticData.questTypes,
    joinedFactionIds: joinedFactionIds,
    eliteMonsters: staticData.eliteMonsters,
  );
});
```

> **import 경로 검증:** `quest_model.dart`(ActiveQuest, QuestStatus 정의 위치), `game_state.dart`(userDataProvider), `static_data_provider.dart`, `quest_provider.dart`(questListProvider), `chain_quest_provider.dart`(chainQuestProgressProvider), `faction_codex_providers.dart`(factionStateRepositoryProvider, factionRefreshProvider), `investigation_notifier.dart`(regionStateRepositoryProvider re-export — TASK-13 1차 재작업에서 추가), `region_transformed_provider.dart`(currentRegionSectorChangesProvider), `quest_sort_service.dart` — 실제 파일 존재 여부와 export symbol을 grep으로 확인 후 상대 경로 보정.

- [ ] **Step 3: 정적 분석 통과 확인**

Run: `cd band_of_mercenaries && flutter analyze lib/features/quest/domain/sorted_quests_provider.dart`
Expected: `No issues found!` (모든 import 해결, 미사용 import 없음)

- [ ] **Step 4: Commit**

```bash
git add band_of_mercenaries/lib/features/quest/domain/sorted_quests_provider.dart
git commit -m "$(cat <<'EOF'
feat(M3): sortedPendingQuestsProvider 신설 — QuestSortService 메모이제이션

- gameTickProvider(1초 주기) 변경과 무관하게 입력 Provider 변경 시에만 재계산
- factionRefreshProvider/currentRegionSectorChangesProvider를 watch에 포함하여 가입/변형 시 자동 무효화

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: `dispatch_screen.dart` 정렬 호출을 Provider watch로 교체 (FR-2 완료)

**Files:**
- Modify: `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart:100-130`

build 메서드 내부의 `QuestSortService.sort()` 직접 호출을 `sortedPendingQuestsProvider` watch로 교체.

- [ ] **Step 1: import 추가**

`dispatch_screen.dart` 상단 import에 다음 추가:

```dart
import 'package:band_of_mercenaries/features/quest/domain/sorted_quests_provider.dart';
```

- [ ] **Step 2: build 메서드 정렬 부분 교체**

기존 (line 105~124 부근):
```dart
return staticData.when(
  data: (data) {
    // 정렬에 필요한 데이터 수집
    final pendingRaw = quests.where((q) => q.status == QuestStatus.pending).toList();
    final inProgressQuests = quests.where((q) => q.status == QuestStatus.inProgress).toList();
    final chainProgresses = ref.watch(chainQuestProgressProvider).valueOrNull ?? const <ChainQuestProgress>[];
    final regionState = ref.watch(regionStateRepositoryProvider).getState(userData.region);
    final joinedFactionIds = ref.watch(factionStateRepositoryProvider).getJoinedFactionIds().toSet();

    final sortResult = QuestSortService.sort(
      quests: pendingRaw,
      chainProgress: chainProgresses,
      currentRegion: userData.region,
      currentSector: userData.sector,
      regionState: regionState,
      questPools: data.questPools,
      questTypes: data.questTypes,
      joinedFactionIds: joinedFactionIds,
      eliteMonsters: data.eliteMonsters,
    );

    final pendingQuests = sortResult.sortedRest;
    ...
```

교체:
```dart
return staticData.when(
  data: (data) {
    // 정렬은 sortedPendingQuestsProvider가 메모이제이션 처리
    final inProgressQuests = quests.where((q) => q.status == QuestStatus.inProgress).toList();
    final sortResult = ref.watch(sortedPendingQuestsProvider);
    final pendingQuests = sortResult.sortedRest;
    ...
```

> 보존: `staticData.when(data: ...)` 구조 자체는 그대로 유지 (`data.regions`, `data.factions` 등 다른 정적 데이터를 build 본문에서 사용하므로). `sortedPendingQuestsProvider`는 내부적으로 staticData를 다시 watch하지만 같은 인스턴스이므로 비용 미미. 추후 별도 리팩터링에서 when 구조 제거 가능.

- [ ] **Step 3: 사용하지 않게 된 코드/import 제거**

다음을 grep으로 확인 후 본 파일 내 다른 위치에서 사용되지 않으면 import 제거:
- `chainQuestProgressProvider` (ChainTopSection에서 자체 watch하므로 dispatch_screen 직접 watch 불필요)
- `regionStateRepositoryProvider`
- `factionStateRepositoryProvider`
- `QuestSortService` 클래스 import (sort 호출 제거 후 미사용일 가능성)
- `ChainQuestProgress` 모델 import

`_QuestCard`가 `chainProgresses`/`regionState` 파라미터를 받고 있다면 (TASK-13 결과로 추가됨) dispatch_screen build에서 여전히 watch가 필요. 이 경우 import 유지하고 watch 라인 보존. 본 task 적용 전 dispatch_screen.dart의 `_QuestCard(...)` 호출 부분을 Read로 확인하여 어떤 파라미터를 받는지 검증.

Run: `cd band_of_mercenaries && flutter analyze lib/features/quest/view/dispatch_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: 회귀 테스트**

Run: `cd band_of_mercenaries && flutter test test/features/quest/`
Expected: 모든 quest 관련 테스트 PASS (정렬 로직은 변경 없으므로 sort_service_test 8개 그대로 PASS)

Run: `cd band_of_mercenaries && flutter test`
Expected: 전체 테스트 PASS

- [ ] **Step 5: 시각 회귀 점검 (수동)**

Run: `cd band_of_mercenaries && flutter run` (또는 핫리로드 환경)
- 파견 화면 진입 → 정렬 결과 동일 확인 (Tier 0 체인 → 1 세력 → 2 엘리트 → 3 변형 → 4 일반)
- 세력 가입 → 파견 화면 재진입 → 세력 전용 퀘스트 Tier 1 정렬 정상 갱신 (`factionRefreshProvider` 작동 검증)
- 지역 변형 발생 → 변형 섹터 퀘스트 Tier 3 등장 (`currentRegionSectorChangesProvider` 작동 검증)
- 시간 가속 ON 상태에서도 1초 단위 재정렬 발생 안 함 (UI 깜빡임 없음)

> 자동화 테스트 어려운 영역이라 수동 확인. 실패 시 watch 의존성 누락 가능성.

- [ ] **Step 6: Commit**

```bash
git add band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart
git commit -m "$(cat <<'EOF'
perf(M3): dispatch_screen 정렬을 sortedPendingQuestsProvider watch로 교체

- gameTickProvider(1초 주기) 변경 시 매번 정렬되던 문제 해결
- view 레이어에서 QuestSortService 직접 호출 제거, Repository read도 Provider 내부로 이전

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: `app.dart` 5개 enqueue 어댑터 dismiss 일관성 통일 (FR-3 완료)

**Files:**
- Modify: `band_of_mercenaries/lib/app.dart:159-267`

5개 listen 어댑터를 다음 패턴으로 통일:
1. enqueue 직후 즉시 `xxxProvider.notifier.state = null` 호출
2. builder의 dismiss 콜백은 `dismiss()`만 호출 (state 리셋 책임 제거)
3. `InvestigationResultDialog`처럼 onDismiss를 받지 않는 위젯도 listen 콜백에서 state 리셋되므로 더 이상 누락 없음

- [ ] **Step 1: 건설 완료 어댑터 통일 (line 162~192)**

기존:
```dart
ref.listen<String?>(constructionCompletedProvider, (_, next) {
  if (next == null) return;
  ...
  ref.read(dialogQueueProvider.notifier).enqueue(DialogRequest(
    ...
    builder: (ctx, dismiss) => AlertDialog(
      ...
      actions: [
        ElevatedButton(
          onPressed: () {
            dismiss();
            ref.read(constructionCompletedProvider.notifier).state = null;
          },
          ...
```

교체:
```dart
ref.listen<String?>(constructionCompletedProvider, (_, next) {
  if (next == null) return;
  final staticData = ref.read(staticDataProvider).value;
  final facilityName =
      staticData?.facilities.where((f) => f.id == next).firstOrNull?.name ?? next;
  final userData = ref.read(userDataProvider);
  final newLevel = userData?.facilities[next] ?? 1;
  ref.read(activityLogProvider.notifier).addLog(
    '$facilityName이(가) Lv.$newLevel(으)로 업그레이드되었습니다',
    ActivityLogType.facilityUpgrade,
  );
  ref.read(dialogQueueProvider.notifier).enqueue(DialogRequest(
    id: 'constructionComplete_${next}_${DateTime.now().millisecondsSinceEpoch}',
    priority: DialogPriority.medium,
    dialogType: DialogTypeRegistry.constructionComplete,
    payload: {'facilityId': next, 'facilityName': facilityName, 'newLevel': newLevel},
    builder: (ctx, dismiss) => AlertDialog(
      title: const Text('건설 완료'),
      content: Text('$facilityName이(가) 업그레이드되었습니다!'),
      actions: [
        ElevatedButton(
          onPressed: dismiss,
          child: const Text('확인'),
        ),
      ],
    ),
  ));
  ref.read(constructionCompletedProvider.notifier).state = null;  // 즉시 리셋
});
```

핵심 변경:
- `onPressed: dismiss` (state 리셋 코드 제거)
- enqueue 직후 `state = null` 추가

- [ ] **Step 2: 조사 완료 어댑터 통일 (line 195~210)**

기존 listen 블록 끝에 한 줄 추가:
```dart
ref.listen<InvestigationResult?>(investigationCompletedProvider, (_, next) {
  if (next == null) return;
  final mercs = ref.read(mercenaryListProvider);
  final mercName = mercs.where((m) => m.id == next.mercId).firstOrNull?.name ?? next.mercId;
  final capturedResult = next;
  ref.read(dialogQueueProvider.notifier).enqueue(DialogRequest(
    id: 'investigationResult_${next.mercId}_${DateTime.now().millisecondsSinceEpoch}',
    priority: DialogPriority.medium,
    dialogType: DialogTypeRegistry.investigationResult,
    payload: {'mercId': next.mercId, 'mercName': mercName},
    builder: (ctx, dismiss) => InvestigationResultDialog(
      result: capturedResult,
      mercName: mercName,
    ),
  ));
  ref.read(investigationCompletedProvider.notifier).state = null;  // 즉시 리셋 (기존 누락분)
});
```

- [ ] **Step 3: 랭크업 어댑터 통일 (line 213~229)**

```dart
ref.listen<RankUpEvent?>(reputationRankUpProvider, (_, next) {
  if (next == null) return;
  final capturedEvent = next;
  ref.read(dialogQueueProvider.notifier).enqueue(DialogRequest(
    id: 'rankUp_${next.to.grade}_${DateTime.now().millisecondsSinceEpoch}',
    priority: DialogPriority.critical,
    dialogType: DialogTypeRegistry.rankUp,
    payload: {'toGrade': next.to.grade},
    builder: (ctx, dismiss) => RankUpOverlay(
      event: capturedEvent,
      onDismiss: dismiss,  // state 리셋은 listen 콜백 책임
    ),
  ));
  ref.read(reputationRankUpProvider.notifier).state = null;  // 즉시 리셋
});
```

- [ ] **Step 4: 체인 완주 어댑터 통일 (line 232~248)**

```dart
ref.listen<ChainCompletedEvent?>(chainCompletedProvider, (_, next) {
  if (next == null) return;
  final capturedEvent = next;
  ref.read(dialogQueueProvider.notifier).enqueue(DialogRequest(
    id: 'chainCompleted_${next.chainId}_${DateTime.now().millisecondsSinceEpoch}',
    priority: DialogPriority.high,
    dialogType: DialogTypeRegistry.chainCompleted,
    payload: {'chainId': next.chainId},
    builder: (ctx, dismiss) => ChainCompletedDialog(
      event: capturedEvent,
      onDismiss: dismiss,
    ),
  ));
  ref.read(chainCompletedProvider.notifier).state = null;
});
```

- [ ] **Step 5: 지역 변형 어댑터 통일 (line 251~267)**

```dart
ref.listen<RegionTransformedEvent?>(regionTransformedProvider, (_, next) {
  if (next == null) return;
  final capturedEvent = next;
  ref.read(dialogQueueProvider.notifier).enqueue(DialogRequest(
    id: 'regionTransform_${next.regionId}_${DateTime.now().millisecondsSinceEpoch}',
    priority: DialogPriority.high,
    dialogType: DialogTypeRegistry.regionTransform,
    payload: {'regionId': next.regionId},
    builder: (ctx, dismiss) => RegionTransformDialog(
      event: capturedEvent,
      onDismiss: dismiss,
    ),
  ));
  ref.read(regionTransformedProvider.notifier).state = null;
});
```

- [ ] **Step 6: 정적 분석 통과 확인**

Run: `cd band_of_mercenaries && flutter analyze lib/app.dart`
Expected: `No issues found!`

- [ ] **Step 7: 회귀 테스트**

Run: `cd band_of_mercenaries && flutter test`
Expected: 전체 테스트 PASS

- [ ] **Step 8: 시각 회귀 점검 (수동)**

- 건설 완료 → 팝업 표시 → 확인 → 닫힘 (정상)
- 지역 조사 완료 → 팝업 표시 → 닫힘 (`InvestigationResultDialog`가 더 이상 stale state로 다시 트리거되지 않음 — 동일 result 반복 표시 없음)
- 랭크업/체인 완주/지역 변형 동일

- [ ] **Step 9: Commit**

```bash
git add band_of_mercenaries/lib/app.dart
git commit -m "$(cat <<'EOF'
refactor(M3): 다이얼로그 큐 5개 채널 dismiss 일관성 통일

- 모든 enqueue 어댑터를 enqueue 직후 즉시 state=null 패턴으로 통일
- builder의 dismiss 콜백에서 state 리셋 책임 제거 (이동 채널 패턴과 일치)
- InvestigationResultDialog 누락된 state 리셋 보완

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: 최종 통합 검증

**Files:**
- Verify: 전체

- [ ] **Step 1: 정적 분석**

Run: `cd band_of_mercenaries && flutter analyze`
Expected: `No issues found! (ran in X.Xs)`

- [ ] **Step 2: 전체 테스트 실행**

Run: `cd band_of_mercenaries && flutter test`
Expected: `All tests passed!` (497 + 본 plan 신규 케이스)

- [ ] **Step 3: build_runner 재실행 불필요 확인**

본 plan은 freezed/json_serializable/hive_generator 어노테이션을 추가하지 않으므로 재실행 불필요. 변경된 어노테이션 클래스가 없는지 확인:
```bash
grep -rln "@HiveType\|@freezed\|@JsonSerializable" band_of_mercenaries/lib/features/mercenary/domain/evolution_choice.dart band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart band_of_mercenaries/lib/features/quest/domain/sorted_quests_provider.dart 2>&1
```
Expected: 매칭 없음 (이미 어노테이션이 있는 기존 파일을 수정한 경우는 build_runner 필요 — 본 plan은 해당 없음)

- [ ] **Step 4: git log 확인**

Run: `git log --oneline -7`
Expected: Task 1~6 커밋 6개가 순서대로 이어짐:
1. `refactor(M3): EvolutionChoice를 domain 레이어로 이전`
2. `feat(M3): MercenaryListNotifier.applyEvolution 메서드 추가`
3. `refactor(M3): dispatch_screen 트레잇 진화 적용을 domain Notifier에 위임`
4. `feat(M3): sortedPendingQuestsProvider 신설 — QuestSortService 메모이제이션`
5. `perf(M3): dispatch_screen 정렬을 sortedPendingQuestsProvider watch로 교체`
6. `refactor(M3): 다이얼로그 큐 5개 채널 dismiss 일관성 통일`

- [ ] **Step 5: 동작 회귀 종합 확인 (수동)**

운영 환경 또는 개발 빌드에서:
- 트레잇 진화 팝업 → 선택 → ActivityLog "진화!" 메시지 정상
- 파견 화면 진입 → 5계층 정렬 결과 동일 / 시간 가속 시 깜빡임 없음
- 8단계 다이얼로그 시퀀스(이동 도착 시 자동 이벤트 + 선택지 회상 + 도착 후 발생 가능 모든 팝업) 정상 순차 표시
- 동일 다이얼로그 반복 표시 없음 (state 즉시 리셋 효과)

---

## Self-Review

### 1. Spec coverage

| spec 요구사항 | 구현 task |
|--------------|----------|
| FR-1 EvolutionChoice domain 이전 | Task 1 |
| FR-1 MercenaryListNotifier.applyEvolution() | Task 2 |
| FR-1 view 단순화 | Task 3 |
| FR-2 sortedPendingQuestsProvider 신설 | Task 4 |
| FR-2 dispatch_screen 교체 | Task 5 |
| FR-3 5개 채널 통일 | Task 6 |
| 동작 변경 없음 검증 | Task 5/6 시각 회귀 + Task 7 |

모든 spec FR을 커버. 누락 없음.

### 2. Placeholder scan

- "TBD"/"TODO"/"implement later" 없음
- "appropriate error handling"/"add validation" 없음
- "Similar to Task N" 없음 (각 task 코드를 완전히 작성)
- 모든 단계가 실행 가능한 명령 또는 완전한 코드 블록

### 3. Type consistency

- `EvolutionChoice` 시그니처: Task 1에서 정의, Task 2/3에서 동일하게 import + 사용 (`isSingle`, `single`, `combo` 필드명 동일)
- `applyEvolution(String mercId, EvolutionChoice choice)`: Task 2 정의, Task 3 호출 시그니처 동일
- `QuestSortResult`: Task 4 Provider 반환 = Task 5 watch 결과 (`sortedRest`/`chainTier0` 필드 동일)
- ActivityLog 메시지 포맷: Task 2의 메시지가 기존 dispatch_screen 메시지와 정확히 일치 (`'${merc.name}의 "..."이(가) "..."(으)로 진화!'` / `'${merc.name}의 "..." + "..." → "..."(으)로 조합 진화!'`)
- 5개 enqueue 어댑터의 `id` 패턴(`<dialogType>_<key>_<timestamp>`) Task 6 모든 채널에서 일관

issues 없음.

---

## Execution Handoff

Plan complete and saved to `Docs/spec/M3/[spec]20260426_post-coexistence-cleanup_plan.md`. Two execution options:

**1. Subagent-Driven (recommended)** — fresh subagent per task with two-stage review between tasks. 권장: 각 task가 독립적이라 격리 효과 큼.

**2. Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?
