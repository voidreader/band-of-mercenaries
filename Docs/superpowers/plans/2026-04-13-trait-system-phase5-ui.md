# Phase 5: 트레잇 시스템 UI 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 트레잇 시스템의 모든 백엔드 기능(획득/진화/충돌)을 플레이어에게 노출하는 UI 레이어를 구축한다.

**Architecture:** 앱 레벨 `selectedMercenaryIdProvider`로 전체화면 용병 상세 오버레이를 제어한다. 퀘스트 완료 후 획득/진화 알림을 `await showDialog` 체이닝으로 순차 표시하며, 진화는 카드 비교형 선택 UI를 통해 플레이어가 경로를 결정한다. `quest_provider`의 자동 적용 로직에서 진화 부분만 UI 위임으로 변경한다.

**Tech Stack:** Flutter, Riverpod (StateProvider/ConsumerWidget), Hive, Material 3

**Spec:** `docs/superpowers/specs/2026-04-13-trait-system-phase5-ui-design.md`

---

## 파일 구조

### 신규 파일

| 파일 | 역할 |
|------|------|
| `lib/core/providers/mercenary_detail_provider.dart` | `selectedMercenaryIdProvider` 정의 |
| `lib/features/mercenary/view/mercenary_detail_overlay.dart` | 전체화면 용병 상세 오버레이 |
| `lib/features/mercenary/view/trait_slot_grid.dart` | 선천/후천 슬롯 그리드 위젯 |
| `lib/features/mercenary/view/behavior_stats_section.dart` | 23개 행동 지표 접기/펼치기 |
| `lib/features/mercenary/view/trait_history_section.dart` | 진화/소멸 히스토리 |
| `lib/features/mercenary/view/trait_detail_dialog.dart` | 트레잇 상세 팝업 |
| `lib/features/mercenary/view/trait_acquisition_dialog.dart` | 트레잇 획득 알림 |
| `lib/features/mercenary/view/trait_evolution_dialog.dart` | 진화 경로 선택 (카드 비교형) |
| `test/features/mercenary/view/trait_slot_grid_test.dart` | 슬롯 렌더링 로직 테스트 |
| `test/features/mercenary/view/behavior_stats_section_test.dart` | 지표 표시 로직 테스트 |

### 수정 파일

| 파일 | 변경 내용 |
|------|----------|
| `lib/app.dart:114-125` | `build()`에 Stack 오버레이 추가 |
| `lib/features/mercenary/view/mercenary_card.dart:9,47` | `onTap` 콜백 파라미터 추가 |
| `lib/features/mercenary/view/recruit_screen.dart` | MercenaryCard에 onTap 전달 |
| `lib/features/quest/domain/quest_completion_service.dart:24-42` | 트레잇 후보 필드 추가 |
| `lib/features/quest/domain/quest_provider.dart:329-393` | 진화 자동적용 → 후보 반환으로 변경 |
| `lib/features/quest/view/dispatch_screen.dart:218-239` | `_showResult`에 팝업 체이닝 추가 |
| `lib/features/quest/view/dispatch_detail_page.dart` | MercenaryCard 사용 부분에 onTap 전달 |

---

### Task 1: selectedMercenaryIdProvider 생성

**Files:**
- Create: `lib/core/providers/mercenary_detail_provider.dart`

- [ ] **Step 1: Provider 파일 생성**

```dart
// lib/core/providers/mercenary_detail_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedMercenaryIdProvider = StateProvider<String?>((ref) => null);
```

- [ ] **Step 2: Commit**

```bash
cd band_of_mercenaries && git add lib/core/providers/mercenary_detail_provider.dart
git commit -m "feat: add selectedMercenaryIdProvider for mercenary detail overlay"
```

---

### Task 2: MercenaryCard에 onTap 콜백 추가

**Files:**
- Modify: `lib/features/mercenary/view/mercenary_card.dart`
- Modify: `lib/features/mercenary/view/recruit_screen.dart`
- Modify: `lib/features/quest/view/dispatch_detail_page.dart`

- [ ] **Step 1: MercenaryCard에 onTap 파라미터 추가**

`mercenary_card.dart`에서 `onTap` optional callback을 추가하고 카드를 `GestureDetector`로 감싼다.

```dart
class MercenaryCard extends StatelessWidget {
  final Mercenary mercenary;
  final Job job;
  final List<TraitData> traits;
  final VoidCallback? onTap;  // 추가

  const MercenaryCard({
    super.key,
    required this.mercenary,
    required this.job,
    this.traits = const [],
    this.onTap,  // 추가
  });
```

`build()` 메서드의 반환값에서 기존 `Container`를 `GestureDetector`로 감싼다:

```dart
  @override
  Widget build(BuildContext context) {
    // ... 기존 코드 유지 ...

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // ... 기존 Container 내용 전체 ...
      ),
    );
  }
```

- [ ] **Step 2: recruit_screen.dart에서 onTap 전달**

`recruit_screen.dart`에서 `MercenaryCard` 생성 시 (약 line 155 근처):

```dart
MercenaryCard(
  mercenary: merc,
  job: mercJob,
  traits: mercTraits,
  onTap: () => ref.read(selectedMercenaryIdProvider.notifier).state = merc.id,
),
```

import 추가: `import 'package:band_of_mercenaries/core/providers/mercenary_detail_provider.dart';`

- [ ] **Step 3: dispatch_detail_page.dart에서 onTap 전달**

`dispatch_detail_page.dart`에서 용병 리스트 표시 부분을 찾아 동일하게 onTap 전달. (ListTile 형태일 수 있으므로, 용병 이름/정보 탭 시 상세 화면으로 이동하는 long press 또는 info 아이콘 추가)

import 추가: `import 'package:band_of_mercenaries/core/providers/mercenary_detail_provider.dart';`

- [ ] **Step 4: Commit**

```bash
cd band_of_mercenaries && git add lib/features/mercenary/view/mercenary_card.dart lib/features/mercenary/view/recruit_screen.dart lib/features/quest/view/dispatch_detail_page.dart
git commit -m "feat: add onTap callback to MercenaryCard for detail navigation"
```

---

### Task 3: TraitSlotGrid 위젯 구현

**Files:**
- Create: `lib/features/mercenary/view/trait_slot_grid.dart`
- Create: `test/features/mercenary/view/trait_slot_grid_test.dart`

- [ ] **Step 1: 슬롯 렌더링 로직 테스트 작성**

```dart
// test/features/mercenary/view/trait_slot_grid_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/view/trait_slot_grid.dart';

void main() {
  group('buildAcquiredSlots', () {
    test('2개 보유 시 빈 슬롯 2개 추가', () {
      final ownedCategories = ['CombatStyle', 'Survival'];
      final slots = TraitSlotGrid.buildAcquiredSlotCategories(
        ownedCategoryKeys: ownedCategories,
        maxAcquired: 4,
      );
      expect(slots.length, 4);
      expect(slots[0], 'CombatStyle');
      expect(slots[1], 'Survival');
      // 나머지 2개는 acquiredCategories 순서 기준
      expect(slots.where((s) => !ownedCategories.contains(s)).length, 2);
    });

    test('4개 보유 시 빈 슬롯 0개', () {
      final ownedCategories = ['CombatStyle', 'Survival', 'Behavior', 'Mental'];
      final slots = TraitSlotGrid.buildAcquiredSlotCategories(
        ownedCategoryKeys: ownedCategories,
        maxAcquired: 4,
      );
      expect(slots.length, 4);
    });

    test('0개 보유 시 빈 슬롯 4개', () {
      final slots = TraitSlotGrid.buildAcquiredSlotCategories(
        ownedCategoryKeys: [],
        maxAcquired: 4,
      );
      expect(slots.length, 4);
    });
  });
}
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```bash
cd band_of_mercenaries && flutter test test/features/mercenary/view/trait_slot_grid_test.dart
```

Expected: FAIL (TraitSlotGrid not defined)

- [ ] **Step 3: TraitSlotGrid 위젯 구현**

```dart
// lib/features/mercenary/view/trait_slot_grid.dart
import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';

class TraitSlotGrid extends StatelessWidget {
  final List<TraitData> innateTraits;   // 보유 선천 트레잇
  final List<TraitData> acquiredTraits; // 보유 후천 트레잇
  final Set<String> evolvableTraitKeys; // 진화 가능 표시할 키
  final void Function(TraitData trait)? onTraitTap;

  const TraitSlotGrid({
    super.key,
    required this.innateTraits,
    required this.acquiredTraits,
    this.evolvableTraitKeys = const {},
    this.onTraitTap,
  });

  static const innateCategories = ['Physical', 'Background', 'Talent'];
  static const acquiredCategoriesOrder = ['CombatStyle', 'Survival', 'Behavior', 'Mental', 'Experience'];

  /// 보유 카테고리 + 빈 슬롯 카테고리를 합쳐 maxAcquired 개 반환
  static List<String> buildAcquiredSlotCategories({
    required List<String> ownedCategoryKeys,
    required int maxAcquired,
  }) {
    final result = <String>[...ownedCategoryKeys];
    final remaining = maxAcquired - ownedCategoryKeys.length;
    if (remaining > 0) {
      final empty = acquiredCategoriesOrder
          .where((c) => !ownedCategoryKeys.contains(c))
          .take(remaining);
      result.addAll(empty);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final acquiredCategoryKeys = acquiredTraits.map((t) => t.categoryKey).toList();
    final slotCategories = buildAcquiredSlotCategories(
      ownedCategoryKeys: acquiredCategoryKeys,
      maxAcquired: GameConstants.maxAcquiredTraits,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 선천 슬롯
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '🔒 선천 트레잇',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        Row(
          children: innateCategories.map((cat) {
            final trait = innateTraits.where((t) => t.categoryKey == cat).firstOrNull;
            return Expanded(
              child: _buildSlot(
                categoryKey: cat,
                trait: trait,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // 후천 슬롯
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '⬆ 후천 트레잇 (${acquiredTraits.length}/${GameConstants.maxAcquiredTraits})',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: slotCategories.map((cat) {
            final trait = acquiredTraits.where((t) => t.categoryKey == cat).firstOrNull;
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 56) / 2, // 2열
              child: _buildSlot(
                categoryKey: cat,
                trait: trait,
                showEvoBadge: trait != null && evolvableTraitKeys.contains(trait.key),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSlot({
    required String categoryKey,
    TraitData? trait,
    bool showEvoBadge = false,
  }) {
    final color = AppTheme.traitCategoryColors[categoryKey] ?? AppTheme.textHint;
    final isFilled = trait != null;

    return GestureDetector(
      onTap: isFilled && onTraitTap != null ? () => onTraitTap!(trait) : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isFilled ? color.withValues(alpha: 0.08) : Colors.transparent,
          border: Border.all(
            color: isFilled ? color.withValues(alpha: 0.25) : AppTheme.borderLight,
            style: isFilled ? BorderStyle.solid : BorderStyle.none,
          ),
          borderRadius: BorderRadius.circular(6),
        ).copyWith(
          border: isFilled
              ? Border.all(color: color.withValues(alpha: 0.25))
              : Border.all(color: AppTheme.textHint.withValues(alpha: 0.2), style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Text(categoryKey, style: TextStyle(fontSize: 9, color: isFilled ? AppTheme.textTertiary : AppTheme.textHint)),
            const SizedBox(height: 2),
            Text(
              isFilled ? trait.name : '—',
              style: TextStyle(
                fontSize: 11,
                color: isFilled ? color : AppTheme.textHint,
                fontWeight: isFilled ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            if (showEvoBadge) ...[
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF176).withValues(alpha: 0.12),
                  border: Border.all(color: const Color(0xFFFFF176).withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text('⚡ 진화 가능', style: TextStyle(fontSize: 8, color: Color(0xFFFFF176))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 테스트 실행 → 통과 확인**

```bash
cd band_of_mercenaries && flutter test test/features/mercenary/view/trait_slot_grid_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd band_of_mercenaries && git add lib/features/mercenary/view/trait_slot_grid.dart test/features/mercenary/view/trait_slot_grid_test.dart
git commit -m "feat: add TraitSlotGrid widget with innate/acquired slot visualization"
```

---

### Task 4: BehaviorStatsSection 위젯 구현

**Files:**
- Create: `lib/features/mercenary/view/behavior_stats_section.dart`
- Create: `test/features/mercenary/view/behavior_stats_section_test.dart`

- [ ] **Step 1: 한국어 매핑 테스트 작성**

```dart
// test/features/mercenary/view/behavior_stats_section_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/view/behavior_stats_section.dart';

void main() {
  test('statLabelKo returns Korean label for known keys', () {
    expect(BehaviorStatsSection.statLabelKo('total_dispatch_count'), '총 파견');
    expect(BehaviorStatsSection.statLabelKo('consecutive_success'), '연속 성공');
  });

  test('statLabelKo returns key for unknown keys', () {
    expect(BehaviorStatsSection.statLabelKo('unknown_stat'), 'unknown_stat');
  });

  test('summarize picks 4 key stats', () {
    final stats = {
      'total_dispatch_count': 23,
      'success_count': 15,
      'consecutive_success': 3,
      'total_gold_earned': 5200,
      'failure_count': 8,
    };
    final summary = BehaviorStatsSection.summarize(stats);
    expect(summary.length, 4);
    expect(summary[0], contains('23'));
    expect(summary[1], contains('15'));
  });
}
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```bash
cd band_of_mercenaries && flutter test test/features/mercenary/view/behavior_stats_section_test.dart
```

Expected: FAIL

- [ ] **Step 3: BehaviorStatsSection 구현**

```dart
// lib/features/mercenary/view/behavior_stats_section.dart
import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';

class BehaviorStatsSection extends StatefulWidget {
  final Map<String, int> stats;

  const BehaviorStatsSection({super.key, required this.stats});

  static const Map<String, String> _labelMap = {
    'total_dispatch_count': '총 파견',
    'success_count': '성공',
    'failure_count': '실패',
    'great_success_count': '대성공',
    'great_failure_count': '대실패',
    'solo_dispatch_count': '솔로 파견',
    'team_dispatch_count': '팀 파견',
    'high_difficulty_count': '고난이도 성공',
    'low_difficulty_count': '저난이도 성공',
    'raid_count': '토벌',
    'hunt_count': '사냥',
    'escort_count': '호위',
    'explore_count': '탐색',
    'near_death_count': '아사 직전',
    'injury_count': '부상',
    'survived_great_failure': '대실패 생존',
    'tier_max_visited': '최고 티어 방문',
    'unique_region_count': '지역 탐험',
    'total_travel_distance': '총 이동거리',
    'total_gold_earned': '총 수입',
    'current_level': '현재 레벨',
    'consecutive_success': '연속 성공',
    'consecutive_failure': '연속 실패',
  };

  static String statLabelKo(String key) => _labelMap[key] ?? key;

  static List<String> summarize(Map<String, int> stats) {
    return [
      '파견 ${stats['total_dispatch_count'] ?? 0}회',
      '성공 ${stats['success_count'] ?? 0}회',
      '연속성공 ${stats['consecutive_success'] ?? 0}',
      '금화 ${stats['total_gold_earned'] ?? 0}G',
    ];
  }

  @override
  State<BehaviorStatsSection> createState() => _BehaviorStatsSectionState();
}

class _BehaviorStatsSectionState extends State<BehaviorStatsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final summary = BehaviorStatsSection.summarize(widget.stats);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📊 행동 지표', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                Text(_expanded ? '▲ 접기' : '▼ 펼치기', style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
              ],
            ),
          ),
          if (!_expanded) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: summary.map((s) => Text(s, style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary))).toList(),
            ),
          ],
          if (_expanded) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: BehaviorStatsSection._labelMap.keys.map((key) {
                final value = widget.stats[key] ?? 0;
                final label = BehaviorStatsSection.statLabelKo(key);
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 72) / 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                      Text('$value', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 테스트 실행 → 통과 확인**

```bash
cd band_of_mercenaries && flutter test test/features/mercenary/view/behavior_stats_section_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd band_of_mercenaries && git add lib/features/mercenary/view/behavior_stats_section.dart test/features/mercenary/view/behavior_stats_section_test.dart
git commit -m "feat: add BehaviorStatsSection with collapsible 23 stat indicators"
```

---

### Task 5: TraitHistorySection 위젯 구현

**Files:**
- Create: `lib/features/mercenary/view/trait_history_section.dart`

- [ ] **Step 1: TraitHistorySection 구현**

```dart
// lib/features/mercenary/view/trait_history_section.dart
import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_transition.dart';
import 'package:band_of_mercenaries/core/models/trait_combo_evolution.dart';

class TraitHistorySection extends StatelessWidget {
  final List<String> traitHistory;
  final List<TraitData> allTraits;
  final List<TraitTransition> transitions;
  final List<TraitComboEvolution> comboEvolutions;

  const TraitHistorySection({
    super.key,
    required this.traitHistory,
    required this.allTraits,
    required this.transitions,
    required this.comboEvolutions,
  });

  String _traitName(String key) {
    return allTraits.where((t) => t.key == key).firstOrNull?.name ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📜 트레잇 히스토리', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (traitHistory.isEmpty)
            const Text('아직 진화 기록이 없습니다', style: TextStyle(fontSize: 11, color: AppTheme.textHint))
          else
            ...traitHistory.map((key) => _buildHistoryEntry(key)),
        ],
      ),
    );
  }

  Widget _buildHistoryEntry(String key) {
    // 단일 진화 매칭
    final singleMatch = transitions.where((t) => t.fromTraitKey == key).firstOrNull;
    if (singleMatch != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(_traitName(key), style: const TextStyle(fontSize: 11, color: AppTheme.textHint, decoration: TextDecoration.lineThrough)),
            const Text(' → ', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
            Text(_traitName(singleMatch.toTraitKey), style: TextStyle(fontSize: 11, color: AppTheme.traitCategoryColors['CombatStyle'] ?? AppTheme.textSecondary)),
            const Text(' (진화)', style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
          ],
        ),
      );
    }

    // 조합 진화 매칭
    final comboMatch = comboEvolutions.where(
      (c) => c.requiredTrait1 == key || c.requiredTrait2 == key,
    ).firstOrNull;
    if (comboMatch != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(_traitName(comboMatch.requiredTrait1), style: const TextStyle(fontSize: 11, color: AppTheme.textHint, decoration: TextDecoration.lineThrough)),
            const Text(' + ', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
            Text(_traitName(comboMatch.requiredTrait2), style: const TextStyle(fontSize: 11, color: AppTheme.textHint, decoration: TextDecoration.lineThrough)),
            const Text(' → ', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
            Text(_traitName(comboMatch.resultTraitKey), style: const TextStyle(fontSize: 11, color: Color(0xFFFFF176))),
            const Text(' (조합)', style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
          ],
        ),
      );
    }

    // 매칭 없음
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '${_traitName(key)} (소멸)',
        style: const TextStyle(fontSize: 11, color: AppTheme.textHint, decoration: TextDecoration.lineThrough),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd band_of_mercenaries && git add lib/features/mercenary/view/trait_history_section.dart
git commit -m "feat: add TraitHistorySection with evolution/combo history display"
```

---

### Task 6: MercenaryDetailOverlay 구현

**Files:**
- Create: `lib/features/mercenary/view/mercenary_detail_overlay.dart`
- Modify: `lib/app.dart:114-125`

- [ ] **Step 1: MercenaryDetailOverlay 구현**

```dart
// lib/features/mercenary/view/mercenary_detail_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/mercenary_detail_provider.dart';
import 'package:band_of_mercenaries/core/domain/experience_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_evolution_service.dart';
import 'package:band_of_mercenaries/features/mercenary/view/trait_slot_grid.dart';
import 'package:band_of_mercenaries/features/mercenary/view/behavior_stats_section.dart';
import 'package:band_of_mercenaries/features/mercenary/view/trait_history_section.dart';
import 'package:band_of_mercenaries/features/mercenary/view/trait_detail_dialog.dart';
import 'package:band_of_mercenaries/shared/widgets/status_badge.dart';

class MercenaryDetailOverlay extends ConsumerWidget {
  final String mercenaryId;

  const MercenaryDetailOverlay({super.key, required this.mercenaryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mercs = ref.watch(mercenaryListProvider);
    final staticData = ref.watch(staticDataProvider);

    final merc = mercs.where((m) => m.id == mercenaryId).firstOrNull;
    if (merc == null) return const SizedBox.shrink();

    return staticData.when(
      data: (data) {
        final job = data.jobs.firstWhere((j) => j.id == merc.jobId, orElse: () => data.jobs.first);
        final tierColor = AppTheme.tierColor(job.tier);
        final allTraitData = merc.allTraitIds.map((key) => data.traits.where((t) => t.key == key).firstOrNull).whereType<dynamic>().toList();
        final innateTraits = allTraitData.where((t) => t.type == 'innate').toList().cast<dynamic>();
        final acquiredTraits = allTraitData.where((t) => t.type != 'innate').toList().cast<dynamic>();

        // 진화 가능 키 계산
        final singleCandidates = TraitEvolutionService.checkSingleEvolutions(
          stats: merc.stats,
          currentTraitIds: merc.allTraitIds,
          transitions: data.traitTransitions,
          allTraits: data.traits,
        );
        final comboCandidates = TraitEvolutionService.checkComboEvolutions(
          currentTraitIds: merc.allTraitIds,
          comboEvolutions: data.traitComboEvolutions,
          allTraits: data.traits,
        );
        final evolvableKeys = <String>{
          ...singleCandidates.map((c) => c.fromKey),
          ...comboCandidates.expand((c) => [c.trait1Key, c.trait2Key]),
        };

        final isMaxLevel = merc.level >= ExperienceService.maxLevel;
        final xpProgress = isMaxLevel ? 1.0 : () {
          final current = ExperienceService.levelThresholds[merc.level - 1];
          final next = ExperienceService.levelThresholds[merc.level];
          if (next <= current) return 1.0;
          return ((merc.xp - current) / (next - current)).clamp(0.0, 1.0);
        }();

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                // Header bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => ref.read(selectedMercenaryIdProvider.notifier).state = null,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.arrow_back, size: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('용병 상세', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Profile header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceAlt,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(child: Text('⚔️', style: TextStyle(fontSize: 20))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(merc.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(3)),
                                          child: Text('Lv.${merc.level}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.amber.shade800)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text('T${job.tier} ${job.name}', style: TextStyle(fontSize: 12, color: tierColor, fontWeight: FontWeight.w500)),
                                        const Text(' · ', style: TextStyle(color: AppTheme.textHint)),
                                        StatusBadge(status: merc.status),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ATK ${merc.effectiveAtk} · DEF ${merc.effectiveDef} · HP ${merc.effectiveHp} · SPD ${merc.speed}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                                    ),
                                    if (!isMaxLevel) ...[
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: xpProgress,
                                          minHeight: 4,
                                          backgroundColor: Colors.amber.shade50,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade600),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('XP ${merc.xp} / ${ExperienceService.levelThresholds[merc.level]}',
                                          style: const TextStyle(fontSize: 9, color: AppTheme.textHint)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Section 2: Trait slots
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: TraitSlotGrid(
                            innateTraits: allTraitData.where((t) => t.type == 'innate').toList(),
                            acquiredTraits: allTraitData.where((t) => t.type != 'innate').toList(),
                            evolvableTraitKeys: evolvableKeys,
                            onTraitTap: (trait) => showDialog(
                              context: context,
                              builder: (_) => TraitDetailDialog(
                                trait: trait,
                                mercenary: merc,
                                allTraits: data.traits,
                                transitions: data.traitTransitions,
                                comboEvolutions: data.traitComboEvolutions,
                                conflicts: data.traitConflicts,
                                synergies: data.traitSynergies,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Section 3: Behavior stats
                        BehaviorStatsSection(stats: merc.stats),
                        const SizedBox(height: 10),

                        // Section 4: Trait history
                        TraitHistorySection(
                          traitHistory: merc.traitHistory,
                          allTraits: data.traits,
                          transitions: data.traitTransitions,
                          comboEvolutions: data.traitComboEvolutions,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
```

- [ ] **Step 2: app.dart에 오버레이 Stack 추가**

`app.dart`의 `build()` 메서드 (line 115-125) 변경:

기존:
```dart
return Scaffold(
  body: SafeArea(child: _screens[currentTab]),
  bottomNavigationBar: BottomNavBar(
    currentIndex: currentTab,
    onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
  ),
);
```

변경:
```dart
final selectedMercId = ref.watch(selectedMercenaryIdProvider);

return Scaffold(
  body: SafeArea(
    child: Stack(
      children: [
        _screens[currentTab],
        if (selectedMercId != null)
          MercenaryDetailOverlay(mercenaryId: selectedMercId),
      ],
    ),
  ),
  bottomNavigationBar: selectedMercId == null
      ? BottomNavBar(
          currentIndex: currentTab,
          onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
        )
      : null,
);
```

import 추가:
```dart
import 'package:band_of_mercenaries/core/providers/mercenary_detail_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/view/mercenary_detail_overlay.dart';
```

- [ ] **Step 3: 앱 실행 및 수동 테스트**

```bash
cd band_of_mercenaries && flutter run -d chrome
```

모집 탭에서 용병 카드 탭 → 상세 화면 오버레이 표시 확인. ← 버튼으로 복귀 확인.

- [ ] **Step 4: Commit**

```bash
cd band_of_mercenaries && git add lib/features/mercenary/view/mercenary_detail_overlay.dart lib/app.dart
git commit -m "feat: add MercenaryDetailOverlay with profile, slots, stats, history"
```

---

### Task 7: TraitDetailDialog 구현

**Files:**
- Create: `lib/features/mercenary/view/trait_detail_dialog.dart`

- [ ] **Step 1: TraitDetailDialog 구현**

```dart
// lib/features/mercenary/view/trait_detail_dialog.dart
import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/trait_transition.dart';
import 'package:band_of_mercenaries/core/models/trait_combo_evolution.dart';
import 'package:band_of_mercenaries/core/models/trait_conflict.dart';
import 'package:band_of_mercenaries/core/models/trait_synergy.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

class TraitDetailDialog extends StatelessWidget {
  final TraitData trait;
  final Mercenary mercenary;
  final List<TraitData> allTraits;
  final List<TraitTransition> transitions;
  final List<TraitComboEvolution> comboEvolutions;
  final List<TraitConflict> conflicts;
  final List<TraitSynergy> synergies;

  const TraitDetailDialog({
    super.key,
    required this.trait,
    required this.mercenary,
    required this.allTraits,
    required this.transitions,
    required this.comboEvolutions,
    required this.conflicts,
    required this.synergies,
  });

  String _traitName(String key) => allTraits.where((t) => t.key == key).firstOrNull?.name ?? key;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.traitCategoryColors[trait.categoryKey] ?? AppTheme.textHint;
    final typeLabel = switch (trait.type) {
      'innate' => '선천',
      'acquired' => '후천(acquired)',
      'evolved' => '후천(evolved)',
      _ => trait.type,
    };

    // 단일 진화 경로
    final singleEvos = transitions.where((t) => t.fromTraitKey == trait.key).toList();
    // 조합 진화 경로
    final comboEvos = comboEvolutions.where(
      (c) => c.requiredTrait1 == trait.key || c.requiredTrait2 == trait.key,
    ).toList();
    // 충돌 관계
    final traitConflicts = conflicts.where((c) => c.traitKey == trait.key).toList();
    // 시너지 (이 트레잇이 innate이고 target에게 시너지를 줄 때)
    final traitSynergies = synergies.where((s) => s.innateTraitKey == trait.key).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trait.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
                          Text('${trait.categoryKey} · $typeLabel', style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, size: 20, color: AppTheme.textHint),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                if (trait.description.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(6)),
                    child: Text(trait.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5)),
                  ),
                if (trait.description.isNotEmpty) const SizedBox(height: 10),

                // Effect
                if (trait.effectText.isNotEmpty) ...[
                  const Text('효과', style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                    child: Text(trait.effectText, style: const TextStyle(fontSize: 12, color: Colors.green)),
                  ),
                  const SizedBox(height: 10),
                ],

                // Evolution paths (only for acquired)
                if (trait.type == 'acquired' && (singleEvos.isNotEmpty || comboEvos.isNotEmpty)) ...[
                  const Text('⚡ 진화 경로', style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(6)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final evo in singleEvos) ...[
                          _buildSingleEvoRow(evo, color),
                          const SizedBox(height: 4),
                        ],
                        if (singleEvos.isNotEmpty && comboEvos.isNotEmpty)
                          const Divider(height: 12, color: AppTheme.borderLight),
                        for (final combo in comboEvos) ...[
                          _buildComboEvoRow(combo, color),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Evolved badge
                if (trait.type == 'evolved')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF176).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('✨ 진화 완료 (최종 형태)', style: TextStyle(fontSize: 11, color: Color(0xFFFFF176))),
                  ),
                if (trait.type == 'evolved') const SizedBox(height: 10),

                // Synergies (innate traits)
                if (traitSynergies.isNotEmpty) ...[
                  const Text('🤝 시너지', style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.06),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: traitSynergies.map((s) => Text(
                        '→ ${_traitName(s.targetTraitKey)} 획득 조건 ${s.reductionPercent.toInt()}% 감소',
                        style: const TextStyle(fontSize: 11, color: Colors.blue),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Conflicts
                if (traitConflicts.isNotEmpty) ...[
                  const Text('⚠ 충돌 관계', style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.06),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: traitConflicts.map((c) => Text(
                        '🚫 ${_traitName(c.conflictTraitKey)} — 동시 보유 불가',
                        style: const TextStyle(fontSize: 11, color: Colors.red),
                      )).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleEvoRow(TraitTransition evo, Color fromColor) {
    // 진행도 계산
    final conditionEntries = evo.conditionJson.entries.where((e) => e.key != 'max_quest_type_count').toList();
    final allMet = conditionEntries.every((e) {
      final required = (e.value as num).toInt();
      final current = mercenary.stats[e.key] ?? 0;
      return current >= required;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(trait.name, style: TextStyle(fontSize: 11, color: fromColor)),
            const Text(' → ', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
            Text(_traitName(evo.toTraitKey), style: const TextStyle(fontSize: 11, color: Color(0xFFFFF176), fontWeight: FontWeight.w600)),
            const Text(' (단일)', style: TextStyle(fontSize: 9, color: AppTheme.textHint)),
            if (allMet) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFFFFF176).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
                child: const Text('⚡ 가능!', style: TextStyle(fontSize: 8, color: Color(0xFFFFF176))),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        ...conditionEntries.map((e) {
          final required = (e.value as num).toInt();
          final current = mercenary.stats[e.key] ?? 0;
          final ratio = required > 0 ? (current / required).clamp(0.0, 1.0) : 1.0;
          final barColor = ratio >= 0.75 ? Colors.green : (ratio >= 0.5 ? Colors.orange : Colors.red);
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: const TextStyle(fontSize: 9, color: AppTheme.textHint)),
                  Text('$current / $required', style: TextStyle(fontSize: 9, color: barColor)),
                ],
              ),
              const SizedBox(height: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(value: ratio, minHeight: 3, backgroundColor: AppTheme.borderLight, valueColor: AlwaysStoppedAnimation(barColor)),
              ),
              const SizedBox(height: 4),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildComboEvoRow(TraitComboEvolution combo, Color fromColor) {
    final otherKey = combo.requiredTrait1 == trait.key ? combo.requiredTrait2 : combo.requiredTrait1;
    final hasOther = mercenary.allTraitIds.contains(otherKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(trait.name, style: TextStyle(fontSize: 11, color: fromColor)),
            const Text(' + ', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
            Text(_traitName(otherKey), style: TextStyle(fontSize: 11, color: hasOther ? Colors.purple : AppTheme.textHint)),
            const Text(' → ', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
            Text(_traitName(combo.resultTraitKey), style: const TextStyle(fontSize: 11, color: Color(0xFFFFF176), fontWeight: FontWeight.w600)),
            const Text(' (조합)', style: TextStyle(fontSize: 9, color: AppTheme.textHint)),
          ],
        ),
        Text(
          hasOther ? '${_traitName(otherKey)} 보유 중 — 조합 가능' : '${_traitName(otherKey)} 미보유',
          style: TextStyle(fontSize: 9, color: hasOther ? Colors.green : AppTheme.textHint),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd band_of_mercenaries && git add lib/features/mercenary/view/trait_detail_dialog.dart
git commit -m "feat: add TraitDetailDialog with evolution progress, synergy, conflicts"
```

---

### Task 8: TraitAcquisitionDialog 구현

**Files:**
- Create: `lib/features/mercenary/view/trait_acquisition_dialog.dart`

- [ ] **Step 1: TraitAcquisitionDialog 구현**

```dart
// lib/features/mercenary/view/trait_acquisition_dialog.dart
import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';

class TraitAcquisitionDialog extends StatelessWidget {
  final TraitData trait;
  final String mercenaryName;

  const TraitAcquisitionDialog({
    super.key,
    required this.trait,
    required this.mercenaryName,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.traitCategoryColors[trait.categoryKey] ?? AppTheme.textHint;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✨ 새 트레잇 획득!', style: TextStyle(fontSize: 14, color: Color(0xFFFFF176))),
            const SizedBox(height: 12),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 6),
            Text(trait.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            Text('${trait.categoryKey} · 후천(acquired)', style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
            const SizedBox(height: 12),
            if (trait.description.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(6)),
                child: Text(trait.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5)),
              ),
            if (trait.description.isNotEmpty) const SizedBox(height: 10),
            if (trait.effectText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                child: Text(trait.effectText, style: const TextStyle(fontSize: 12, color: Colors.green)),
              ),
            if (trait.effectText.isNotEmpty) const SizedBox(height: 10),
            Text(
              '$mercenaryName의 ${trait.categoryKey} 슬롯에 배치되었습니다',
              style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd band_of_mercenaries && git add lib/features/mercenary/view/trait_acquisition_dialog.dart
git commit -m "feat: add TraitAcquisitionDialog for post-quest trait notification"
```

---

### Task 9: TraitEvolutionDialog 구현

**Files:**
- Create: `lib/features/mercenary/view/trait_evolution_dialog.dart`

- [ ] **Step 1: TraitEvolutionDialog 구현 (카드 비교형)**

```dart
// lib/features/mercenary/view/trait_evolution_dialog.dart
import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_evolution_service.dart';

/// 진화 선택 결과. null이면 보류.
class EvolutionChoice {
  final bool isSingle;
  final SingleEvolutionCandidate? single;
  final ComboEvolutionCandidate? combo;

  EvolutionChoice.fromSingle(SingleEvolutionCandidate c) : isSingle = true, single = c, combo = null;
  EvolutionChoice.fromCombo(ComboEvolutionCandidate c) : isSingle = false, single = null, combo = c;
}

class TraitEvolutionDialog extends StatefulWidget {
  final String mercenaryName;
  final List<TraitData> currentTraits; // 현재 보유 후천 트레잇
  final List<SingleEvolutionCandidate> singleCandidates;
  final List<ComboEvolutionCandidate> comboCandidates;
  final List<TraitData> allTraits;

  const TraitEvolutionDialog({
    super.key,
    required this.mercenaryName,
    required this.currentTraits,
    required this.singleCandidates,
    required this.comboCandidates,
    required this.allTraits,
  });

  @override
  State<TraitEvolutionDialog> createState() => _TraitEvolutionDialogState();
}

class _TraitEvolutionDialogState extends State<TraitEvolutionDialog> {
  int? _selectedIndex;

  TraitData? _traitData(String key) => widget.allTraits.where((t) => t.key == key).firstOrNull;
  String _traitName(String key) => _traitData(key)?.name ?? key;

  List<_EvoCard> get _cards {
    final cards = <_EvoCard>[];
    for (final s in widget.singleCandidates) {
      cards.add(_EvoCard(
        isSingle: true,
        resultKey: s.toKey,
        consumedKeys: [s.fromKey],
        freedCategory: null, // 같은 카테고리, 해방 없음
        single: s,
        combo: null,
      ));
    }
    for (final c in widget.comboCandidates) {
      final resultTrait = _traitData(c.resultKey);
      final t1Cat = _traitData(c.trait1Key)?.categoryKey;
      final t2Cat = _traitData(c.trait2Key)?.categoryKey;
      final resultCat = resultTrait?.categoryKey;
      // 해방되는 슬롯: 재료 카테고리 중 결과 카테고리가 아닌 것
      String? freed;
      if (resultCat != null) {
        if (t1Cat != resultCat) freed = t1Cat;
        else if (t2Cat != resultCat) freed = t2Cat;
      }
      cards.add(_EvoCard(
        isSingle: false,
        resultKey: c.resultKey,
        consumedKeys: [c.trait1Key, c.trait2Key],
        freedCategory: freed,
        single: null,
        combo: c,
      ));
    }
    return cards;
  }

  @override
  void initState() {
    super.initState();
    final cards = _cards;
    if (cards.length == 1) _selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards;
    final isSingleType = widget.comboCandidates.isEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSingleType ? '⚡ 단일 진화 가능!' : '⚡ 조합 진화 가능!',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFFFF176)),
                ),
                const SizedBox(height: 4),
                Text(
                  cards.length > 1 ? '진화 경로를 선택하세요' : '진화하시겠습니까?',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(widget.mercenaryName, style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                const SizedBox(height: 12),

                // 현재 보유 재료
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(6)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('현재 보유', style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: widget.currentTraits.map((t) {
                          final color = AppTheme.traitCategoryColors[t.categoryKey] ?? AppTheme.textHint;
                          final isConsumed = _selectedIndex != null && cards[_selectedIndex!].consumedKeys.contains(t.key);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isConsumed ? Colors.red.withValues(alpha: 0.1) : color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              t.name,
                              style: TextStyle(
                                fontSize: 10,
                                color: isConsumed ? Colors.red : color,
                                decoration: isConsumed ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 결과 카드 리스트
                ...cards.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final card = entry.value;
                  final isSelected = _selectedIndex == idx;
                  final resultTrait = _traitData(card.resultKey);
                  final resultColor = resultTrait != null
                      ? (AppTheme.traitCategoryColors[resultTrait.categoryKey] ?? AppTheme.textHint)
                      : AppTheme.textHint;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = idx),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFF176).withValues(alpha: 0.06) : AppTheme.surfaceAlt,
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFFF176).withValues(alpha: 0.4) : AppTheme.borderLight,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_traitName(card.resultKey), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: resultColor)),
                                  Text('${resultTrait?.categoryKey ?? ''} (evolved)', style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary)),
                                ],
                              ),
                              if (isSelected)
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(color: Color(0xFFFFF176), shape: BoxShape.circle),
                                  child: const Center(child: Text('✓', style: TextStyle(fontSize: 11, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700))),
                                ),
                            ],
                          ),
                          if (resultTrait?.effectText.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(resultTrait!.effectText, style: const TextStyle(fontSize: 11, color: Colors.green)),
                          ],
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            children: [
                              ...card.consumedKeys.map((k) => Text(
                                _traitName(k),
                                style: const TextStyle(fontSize: 10, color: Colors.red, decoration: TextDecoration.lineThrough),
                              )),
                              const Text('→', style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
                              if (card.freedCategory != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text('${card.freedCategory} 슬롯 해방', style: const TextStyle(fontSize: 9, color: Colors.green)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 12),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text('보류'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedIndex == null ? null : () {
                          final card = cards[_selectedIndex!];
                          if (card.isSingle) {
                            Navigator.of(context).pop(EvolutionChoice.fromSingle(card.single!));
                          } else {
                            Navigator.of(context).pop(EvolutionChoice.fromCombo(card.combo!));
                          }
                        },
                        child: Text(
                          _selectedIndex != null ? '${_traitName(cards[_selectedIndex!].resultKey)}(으)로 진화' : '진화 실행',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EvoCard {
  final bool isSingle;
  final String resultKey;
  final List<String> consumedKeys;
  final String? freedCategory;
  final SingleEvolutionCandidate? single;
  final ComboEvolutionCandidate? combo;

  _EvoCard({
    required this.isSingle,
    required this.resultKey,
    required this.consumedKeys,
    required this.freedCategory,
    required this.single,
    required this.combo,
  });
}
```

- [ ] **Step 2: Commit**

```bash
cd band_of_mercenaries && git add lib/features/mercenary/view/trait_evolution_dialog.dart
git commit -m "feat: add TraitEvolutionDialog with card comparison and path selection"
```

---

### Task 10: quest_provider 변경 — 진화 자동적용을 후보 반환으로

**Files:**
- Modify: `lib/features/quest/domain/quest_completion_service.dart:24-42`
- Modify: `lib/features/quest/domain/quest_provider.dart:329-393`

- [ ] **Step 1: QuestCompletionResult에 트레잇 관련 필드 추가**

`quest_completion_service.dart`의 `QuestCompletionResult` 클래스 (line 24-42):

```dart
class QuestCompletionResult {
  final QuestResult resultType;
  final int rewardGold;
  final int totalWage;
  final int netReward;
  final int xpGain;
  final int repGain;
  final List<MercDamageResult> mercDamages;

  // Phase 5: 트레잇 관련 결과 (용병별)
  final Map<String, TraitEventResult> traitEvents;

  const QuestCompletionResult({
    required this.resultType,
    required this.rewardGold,
    required this.totalWage,
    required this.netReward,
    required this.xpGain,
    required this.repGain,
    required this.mercDamages,
    this.traitEvents = const {},
  });
}
```

같은 파일에 `TraitEventResult` 클래스 추가:

```dart
import 'package:band_of_mercenaries/features/mercenary/domain/trait_evolution_service.dart';

class TraitEventResult {
  final String? acquiredTraitKey;       // 획득된 트레잇 (이미 적용됨)
  final List<SingleEvolutionCandidate> singleEvoCandidates;
  final List<ComboEvolutionCandidate> comboEvoCandidates;

  const TraitEventResult({
    this.acquiredTraitKey,
    this.singleEvoCandidates = const [],
    this.comboEvoCandidates = const [],
  });

  bool get hasEvents =>
      acquiredTraitKey != null ||
      singleEvoCandidates.isNotEmpty ||
      comboEvoCandidates.isNotEmpty;
}
```

- [ ] **Step 2: quest_provider 변경 — 진화 부분 후보 수집으로**

`quest_provider.dart`의 `_applyCompletionResult` 메서드에서 line 329-393 영역을 변경한다.

**기존 로직 (line 340-393):**
- 획득 → 자동 적용 + 로그
- 단일 진화 → 자동 적용 + 로그
- 조합 진화 → 자동 적용 + 로그

**변경 로직:**
- 획득 → 자동 적용 + 로그 (기존 유지)
- 단일 진화 → 후보 목록만 수집 (적용하지 않음)
- 조합 진화 → 후보 목록만 수집 (적용하지 않음)
- traitEvents 맵에 결과 저장

구체적으로 `_applyCompletionResult`의 `for (final merc in mercs)` 루프 내부에서 진화 관련 코드를 변경:

```dart
        // (기존 획득 코드 유지: lines 331-349)

        final updatedMerc = mercRepo.getAll().firstWhere((m) => m.id == merc.id);
        final currentTraitIds = updatedMerc.allTraitIds;

        // 단일 진화 후보 수집 (적용하지 않음)
        final singleCandidates = TraitEvolutionService.checkSingleEvolutions(
          stats: newStats,
          currentTraitIds: currentTraitIds,
          transitions: staticData.traitTransitions,
          allTraits: staticData.traits,
        );

        // 조합 진화 후보 수집 (단일 진화가 없을 때만)
        List<ComboEvolutionCandidate> comboCandidates = [];
        if (singleCandidates.isEmpty) {
          comboCandidates = TraitEvolutionService.checkComboEvolutions(
            currentTraitIds: currentTraitIds,
            comboEvolutions: staticData.traitComboEvolutions,
            allTraits: staticData.traits,
          );
        }

        // 트레잇 이벤트 결과 저장
        final acquiredKey = candidates.isNotEmpty ? candidates.first : null;
        traitEvents[merc.id] = TraitEventResult(
          acquiredTraitKey: acquiredKey,
          singleEvoCandidates: singleCandidates,
          comboEvoCandidates: comboCandidates,
        );
```

`_applyCompletionResult`의 시작 부분에 `final traitEvents = <String, TraitEventResult>{};` 를 추가하고, 메서드 끝에서 quest의 완료 결과에 포함시킨다. 단, 현재 `_applyCompletionResult`는 `void`이므로, traitEvents를 별도 상태로 노출해야 한다.

**접근법:** `QuestListNotifier`에 `traitEventsProvider`를 별도로 관리한다.

`quest_provider.dart` 파일 상단에 추가:

```dart
import 'package:band_of_mercenaries/features/quest/domain/quest_completion_service.dart' show TraitEventResult;

final pendingTraitEventsProvider = StateProvider<Map<String, Map<String, TraitEventResult>>>((ref) => {});
// key: questId, value: { mercId: TraitEventResult }
```

`_applyCompletionResult` 끝에서 (line 402 근처, `ref.read(mercenaryListProvider.notifier).refresh()` 전):

```dart
    if (traitEvents.values.any((e) => e.hasEvents)) {
      final current = ref.read(pendingTraitEventsProvider);
      ref.read(pendingTraitEventsProvider.notifier).state = {
        ...current,
        quest.id: traitEvents,
      };
    }
```

- [ ] **Step 3: 기존 테스트 실행**

```bash
cd band_of_mercenaries && flutter test
```

기존 테스트가 깨지지 않는지 확인. `QuestCompletionResult` 생성자에 새 필드가 optional이므로 기존 코드와 호환된다.

- [ ] **Step 4: Commit**

```bash
cd band_of_mercenaries && git add lib/features/quest/domain/quest_completion_service.dart lib/features/quest/domain/quest_provider.dart
git commit -m "feat: change quest_provider to collect evolution candidates instead of auto-applying"
```

---

### Task 11: dispatch_screen 팝업 체이닝 구현

**Files:**
- Modify: `lib/features/quest/view/dispatch_screen.dart:218-239`

- [ ] **Step 1: _showResult에 팝업 체이닝 추가**

`dispatch_screen.dart`의 `_showResult` 메서드를 변경:

```dart
  Future<void> _showResult(BuildContext context, ActiveQuest quest, WidgetRef ref) async {
    // 1. 기존 퀘스트 결과 다이얼로그
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuestResultDialog(quest: quest),
    );

    // 2. 트레잇 이벤트 체이닝
    if (mounted) {
      final events = ref.read(pendingTraitEventsProvider)[quest.id];
      if (events != null) {
        await _showTraitEvents(context, ref, events);
        // 처리 완료 후 제거
        final current = ref.read(pendingTraitEventsProvider);
        ref.read(pendingTraitEventsProvider.notifier).state = Map.from(current)..remove(quest.id);
      }
    }

    // 3. 다이얼로그 닫힘 후 퀘스트 정리
    ref.read(questListProvider.notifier).clearCompleted(quest.id);
    _isShowingResult = false;
    // 다음 완료된 퀘스트가 있으면 표시
    if (mounted) {
      final quests = ref.read(questListProvider);
      final nextCompleted = quests.where(
        (q) => q.status == QuestStatus.completed && !_shownResultIds.contains(q.id),
      ).toList();
      if (nextCompleted.isNotEmpty) {
        _isShowingResult = true;
        _shownResultIds.add(nextCompleted.first.id);
        _showResult(context, nextCompleted.first, ref);
      }
    }
  }

  Future<void> _showTraitEvents(
    BuildContext context,
    WidgetRef ref,
    Map<String, TraitEventResult> events,
  ) async {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return;
    final mercs = ref.read(mercenaryListProvider);
    final mercRepo = ref.read(mercenaryRepositoryProvider);

    for (final entry in events.entries) {
      final mercId = entry.key;
      final event = entry.value;
      final merc = mercs.where((m) => m.id == mercId).firstOrNull;
      if (merc == null || !mounted) continue;

      // 획득 알림
      if (event.acquiredTraitKey != null) {
        final traitData = staticData.traits.where((t) => t.key == event.acquiredTraitKey).firstOrNull;
        if (traitData != null && mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => TraitAcquisitionDialog(trait: traitData, mercenaryName: merc.name),
          );
        }
      }

      // 진화 선택
      if (event.singleEvoCandidates.isNotEmpty || event.comboEvoCandidates.isNotEmpty) {
        if (!mounted) break;
        final currentTraits = merc.allTraitIds
            .map((key) => staticData.traits.where((t) => t.key == key).firstOrNull)
            .whereType<TraitData>()
            .where((t) => t.type != 'innate')
            .toList();

        final choice = await showDialog<EvolutionChoice?>(
          context: context,
          barrierDismissible: false,
          builder: (_) => TraitEvolutionDialog(
            mercenaryName: merc.name,
            currentTraits: currentTraits,
            singleCandidates: event.singleEvoCandidates,
            comboCandidates: event.comboEvoCandidates,
            allTraits: staticData.traits,
          ),
        );

        if (choice != null) {
          if (choice.isSingle) {
            final s = choice.single!;
            await mercRepo.evolveTrait(mercId, s.fromKey, s.toKey);
            final fromTrait = staticData.traits.where((t) => t.key == s.fromKey).firstOrNull;
            final toTrait = staticData.traits.where((t) => t.key == s.toKey).firstOrNull;
            if (fromTrait != null && toTrait != null) {
              ref.read(activityLogProvider.notifier).addLog(
                '${merc.name}의 "${fromTrait.name}"이(가) "${toTrait.name}"(으)로 진화!',
                ActivityLogType.traitEvolved,
              );
            }
          } else {
            final c = choice.combo!;
            await mercRepo.comboEvolveTrait(mercId, c.trait1Key, c.trait2Key, c.resultKey);
            final t1 = staticData.traits.where((t) => t.key == c.trait1Key).firstOrNull;
            final t2 = staticData.traits.where((t) => t.key == c.trait2Key).firstOrNull;
            final result = staticData.traits.where((t) => t.key == c.resultKey).firstOrNull;
            if (t1 != null && t2 != null && result != null) {
              ref.read(activityLogProvider.notifier).addLog(
                '${merc.name}의 "${t1.name}" + "${t2.name}" → "${result.name}"(으)로 조합 진화!',
                ActivityLogType.traitEvolved,
              );
            }
          }
          ref.read(mercenaryListProvider.notifier).refresh();
        }
      }
    }
  }
```

import 추가:
```dart
import 'package:band_of_mercenaries/features/mercenary/view/trait_acquisition_dialog.dart';
import 'package:band_of_mercenaries/features/mercenary/view/trait_evolution_dialog.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_completion_service.dart' show TraitEventResult;
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/features/mercenary/data/mercenary_repository.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
```

- [ ] **Step 2: Commit**

```bash
cd band_of_mercenaries && git add lib/features/quest/view/dispatch_screen.dart
git commit -m "feat: add trait acquisition/evolution popup chaining after quest result"
```

---

### Task 12: 통합 테스트 및 정적 분석

**Files:** (변경 없음, 검증만)

- [ ] **Step 1: 정적 분석**

```bash
cd band_of_mercenaries && flutter analyze
```

경고나 에러가 있으면 수정한다.

- [ ] **Step 2: 기존 테스트 실행**

```bash
cd band_of_mercenaries && flutter test
```

모든 기존 테스트가 통과하는지 확인. `QuestCompletionResult`에 새 optional 필드를 추가했으므로 기존 테스트는 깨지지 않아야 한다.

- [ ] **Step 3: 앱 실행 및 수동 E2E 테스트**

```bash
cd band_of_mercenaries && flutter run -d chrome
```

테스트 시나리오:
1. 모집 탭 → 용병 카드 탭 → 상세 화면 표시 확인
2. 상세 화면 → 트레잇 슬롯 확인 (선천/후천 구분, 빈 슬롯 표시)
3. 채워진 트레잇 탭 → 상세 팝업 (설명, 효과, 진화경로, 충돌)
4. 행동 지표 접기/펼치기
5. ← 버튼으로 복귀
6. 파견 실행 → 완료 대기 → 결과 팝업 → (트레잇 획득 시) 획득 알림 → (진화 가능 시) 진화 선택
7. 파견 상세에서 용병 카드 탭 → 상세 화면 진입 가능 확인

- [ ] **Step 4: 발견된 이슈 수정 후 최종 커밋**

```bash
cd band_of_mercenaries && git add -A
git commit -m "fix: Phase 5 통합 테스트 후 수정사항"
```
