// HiddenStatsSection 위젯 테스트 (M8.5 페이즈 4 #4)
//
// 검증 범위:
//   [TS-1] lv0 스탯은 렌더되지 않는다.
//   [TS-2] 전 스탯 lv0이면 섹션이 SizedBox.shrink() (아무 카드/헤더 없음)된다.
//   [TS-3] lv5(max)는 "★ 최대 도달" 배지 + 진행도 바 100% 충만.
//   [TS-4] 진행도 텍스트 = 카운터/다음 임계 형식.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:band_of_mercenaries/core/models/hidden_stat_data.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/view/hidden_stats_section.dart';

// ── 헬퍼 ─────────────────────────────────────────────────────────────────────

/// 최소 필드를 채운 Mercenary 생성 헬퍼.
Mercenary _makeMerc({
  Map<String, int>? hiddenStats,
  Map<String, int>? stats,
}) {
  return Mercenary(
    id: 'merc-test-1',
    name: '테스트 용병',
    jobId: 'warrior',
    traitId: 'brave',
    str: 10,
    intelligence: 10,
    vit: 10,
    agi: 10,
    hiddenStats: hiddenStats,
    stats: stats,
  );
}

/// HiddenStatData 생성 헬퍼.
HiddenStatData _makeStat({
  required String id,
  required String counterKey,
  List<int> levelThresholds = const [1, 3, 7, 15, 30],
  Map<String, dynamic> combatEffectsJson = const {'death_resistance': 0.06},
  String iconKey = 'default',
}) {
  return HiddenStatData(
    id: id,
    name: id == 'fortitude' ? '불굴' : '투지',
    description: '테스트 스탯 설명',
    counterKey: counterKey,
    levelThresholds: levelThresholds,
    combatEffectsJson: combatEffectsJson,
    iconKey: iconKey,
  );
}

/// StaticGameData에서 hiddenStats만 채운 fake 데이터 반환.
StaticGameData _makeStaticData(List<HiddenStatData> hiddenStats) {
  return StaticGameData(
    difficulties: const [],
    jobs: const [],
    traits: const [],
    traitCategories: const [],
    traitConflicts: const [],
    traitTransitions: const [],
    traitComboEvolutions: const [],
    traitSynergies: const [],
    regions: const [],
    questTypes: const [],
    questPools: const [],
    personNames: const [],
    travelEvents: const [],
    facilities: const [],
    ranks: const [],
    mercenaryWages: const [],
    regionDiscoveries: const [],
    factions: const [],
    items: const [],
    eliteMonsters: const [],
    eliteLootEntries: const [],
    chainQuests: const [],
    questNarratives: const [],
    travelChoiceEvents: const [],
    travelChoiceOptions: const [],
    travelChoiceResults: const [],
    regionAdjacencies: const [],
    regionSectors: const [],
    craftingRecipes: const [],
    questPoolMaterialDrops: const [],
    bandAchievementTemplates: const [],
    titles: const [],
    factionContacts: const [],
    factionReactions: const [],
    factionShopItems: const [],
    combatReportTemplates: const [],
    combatReportKeywords: const [],
    combatSkills: const [],
    combatStatusEffects: const [],
    enemyArchetypes: const [],
    hiddenStats: hiddenStats,
    battleMemoryTemplates: const [],
  );
}

/// ProviderScope + MaterialApp으로 위젯 pump 헬퍼.
Future<void> _pump(
  WidgetTester tester,
  Mercenary merc,
  List<HiddenStatData> hiddenStats,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        staticDataProvider.overrideWith(
          (ref) async => _makeStaticData(hiddenStats),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HiddenStatsSection(merc: merc),
          ),
        ),
      ),
    ),
  );
  // staticDataProvider(FutureProvider) 비동기 로딩 완료 대기
  await tester.pumpAndSettle();
}

// ── 테스트 ────────────────────────────────────────────────────────────────────

void main() {
  group('HiddenStatsSection 위젯 테스트', () {
    // ── [TS-2] 전 스탯 lv0이면 섹션 숨김 ──────────────────────────────────
    testWidgets('[TS-2] 전 스탯 lv0이면 섹션이 SizedBox.shrink()(헤더/카드 없음)', (tester) async {
      // given: hiddenStats가 모두 lv0(빈 맵)인 용병
      final merc = _makeMerc(
        hiddenStats: {},
        stats: {'fortitude_counter': 0},
      );
      final statList = [
        _makeStat(id: 'fortitude', counterKey: 'fortitude_counter'),
        _makeStat(id: 'grit', counterKey: 'grit_counter'),
      ];

      // when
      await _pump(tester, merc, statList);

      // then: 헤더 텍스트와 카드가 없어야 한다
      expect(find.textContaining('히든 스탯'), findsNothing);
      expect(find.textContaining('불굴'), findsNothing);
      expect(find.textContaining('투지'), findsNothing);
    });

    // ── [TS-1] lv0 스탯은 렌더되지 않음 ─────────────────────────────────
    testWidgets('[TS-1] lv0 스탯은 렌더되지 않고 lv1+ 스탯만 표시', (tester) async {
      // given: 불굴은 lv2, 투지는 lv0
      final merc = _makeMerc(
        hiddenStats: {'fortitude': 2, 'grit': 0},
        stats: {'fortitude_counter': 5},
      );
      final statList = [
        _makeStat(id: 'fortitude', counterKey: 'fortitude_counter'),
        _makeStat(id: 'grit', counterKey: 'grit_counter'),
      ];

      // when
      await _pump(tester, merc, statList);

      // then: 불굴은 표시, 투지는 숨겨진다
      expect(find.textContaining('불굴'), findsOneWidget);
      expect(find.textContaining('투지'), findsNothing);
    });

    // ── [TS-3] lv5(max)는 "★ 최대 도달" 배지 + 진행도 바 100% ─────────
    testWidgets('[TS-3] lv5 스탯은 "★ 최대 도달" 배지를 표시한다', (tester) async {
      // given: 불굴이 lv5(최대), thresholds 길이 = 5
      final merc = _makeMerc(
        hiddenStats: {'fortitude': 5},
        stats: {'fortitude_counter': 30},
      );
      final statList = [
        _makeStat(
          id: 'fortitude',
          counterKey: 'fortitude_counter',
          levelThresholds: [1, 3, 7, 15, 30],
        ),
      ];

      // when
      await _pump(tester, merc, statList);

      // then: "★ 최대 도달" 배지가 표시되어야 한다 (배지 + 진행도 라벨로 2개 이상)
      expect(find.textContaining('★ 최대 도달'), findsAtLeastNWidgets(1));
      // lv5 표기 확인
      expect(find.textContaining('불굴 lv5'), findsOneWidget);
    });

    // ── [TS-3] lv5 진행도 바는 1.0(충만) ────────────────────────────────
    testWidgets('[TS-3] lv5 진행도 바는 LinearProgressIndicator value 1.0', (tester) async {
      // given: 불굴 lv5
      final merc = _makeMerc(
        hiddenStats: {'fortitude': 5},
        stats: {'fortitude_counter': 30},
      );
      final statList = [
        _makeStat(id: 'fortitude', counterKey: 'fortitude_counter'),
      ];

      // when
      await _pump(tester, merc, statList);

      // then: LinearProgressIndicator가 value 1.0으로 렌더됨
      final progressFinder = tester.widgetList<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressFinder.isNotEmpty, isTrue);
      expect(progressFinder.first.value, equals(1.0));
    });

    // ── [TS-4] 진행도 텍스트 = 카운터/다음 임계 형식 ─────────────────────
    testWidgets('[TS-4] 미최대 스탯의 진행도는 "카운터 / 다음임계" 형식', (tester) async {
      // given: 불굴 lv1, 카운터 = 2, 다음 임계 = thresholds[1] = 3
      final merc = _makeMerc(
        hiddenStats: {'fortitude': 1},
        stats: {'fortitude_counter': 2},
      );
      final statList = [
        _makeStat(
          id: 'fortitude',
          counterKey: 'fortitude_counter',
          levelThresholds: [1, 3, 7, 15, 30],
        ),
      ];

      // when
      await _pump(tester, merc, statList);

      // then: "2 / 3" 진행도 텍스트가 표시된다
      expect(find.text('2 / 3'), findsOneWidget);
    });

    // ── 빈 hiddenStats 캐시(staticData.hiddenStats=[]) 시 섹션 숨김 ──────
    testWidgets('hiddenStats 캐시가 빈 리스트이면 섹션을 숨긴다(fail-soft)', (tester) async {
      // given: 용병이 hiddenStats를 가지고 있어도 정적 데이터가 비어있으면 숨김
      final merc = _makeMerc(
        hiddenStats: {'fortitude': 3},
      );

      // when: hiddenStats 빈 캐시 주입
      await _pump(tester, merc, const []);

      // then: 섹션 렌더 없음
      expect(find.textContaining('히든 스탯'), findsNothing);
    });
  });
}
