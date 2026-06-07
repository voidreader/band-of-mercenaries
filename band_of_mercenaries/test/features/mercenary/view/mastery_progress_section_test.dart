// MasteryProgressSection 위젯 테스트 (M8.5 페이즈 4 #4)
//
// 검증 범위:
//   [TS-1] 보유 칭호는 ✓ 달성 배지, 미보유는 진행도 바를 표시한다.
//   [TS-2] 전 카운터 0 AND 전용 칭호 진행 0이면 섹션 숨김(SizedBox.shrink()).
//   [TS-3] 카운터/임계 매핑 정확 (예: solo_completion_count=3 → "3/5" 진행도).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:band_of_mercenaries/core/models/title_data.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/view/mastery_progress_section.dart';
import 'package:band_of_mercenaries/features/title/domain/title_provider.dart';

// ── 헬퍼 ─────────────────────────────────────────────────────────────────────

/// 4종 전용 칭호 TitleData 목록 생성 헬퍼.
/// hookCondition에 stat_key와 threshold를 포함한다.
List<TitleData> _masteryTitles() {
  return [
    TitleData(
      id: 'title_lone_wolf',
      name: '외로운 늑대',
      description: '단독 의뢰 완수 칭호',
      hookType: 'action_stat',
      hookCondition: {'stat_key': 'solo_completion_count', 'threshold': 5},
    ),
    TitleData(
      id: 'title_silver_pair',
      name: '은빛 쌍검',
      description: '페어 완수 칭호',
      hookType: 'action_stat',
      hookCondition: {'stat_key': 'pair_completion_count', 'threshold': 8},
    ),
    TitleData(
      id: 'title_three_kings',
      name: '삼왕의 계약',
      description: '소수정예 완수 칭호',
      hookType: 'action_stat',
      hookCondition: {'stat_key': 'small_party_count', 'threshold': 10},
    ),
    TitleData(
      id: 'title_unyielding_solo',
      name: '불굴의 독행자',
      description: '단독 대성공 칭호',
      hookType: 'action_stat',
      hookCondition: {'stat_key': 'solo_great_success_count', 'threshold': 1},
    ),
  ];
}

/// 최소 필드를 채운 Mercenary 생성 헬퍼.
Mercenary _makeMerc({
  Map<String, int>? stats,
  List<String>? titleIds,
  String id = 'merc-mastery-1',
}) {
  return Mercenary(
    id: id,
    name: '숙련 용병',
    jobId: 'warrior',
    traitId: 'brave',
    str: 10,
    intelligence: 10,
    vit: 10,
    agi: 10,
    stats: stats,
    titleIds: titleIds,
  );
}

/// StaticGameData 생성 헬퍼 (titles만 커스텀).
StaticGameData _makeStaticData(List<TitleData> titles) {
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
    titles: titles,
    factionContacts: const [],
    factionReactions: const [],
    factionShopItems: const [],
    combatReportTemplates: const [],
    combatReportKeywords: const [],
    combatSkills: const [],
    combatStatusEffects: const [],
    enemyArchetypes: const [],
    hiddenStats: const [],
    battleMemoryTemplates: const [],
  );
}

/// ProviderScope + overrides로 위젯 pump 헬퍼.
Future<void> _pump(
  WidgetTester tester,
  Mercenary merc, {
  List<TitleData>? allTitles,
  List<TitleData>? ownedTitles,
}) async {
  final titles = allTitles ?? _masteryTitles();
  final owned = ownedTitles ?? [];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        staticDataProvider.overrideWith(
          (ref) async => _makeStaticData(titles),
        ),
        titlesProvider.overrideWith(
          (ref) => titles,
        ),
        mercenaryTitlesProvider.overrideWith(
          (ref, _) => owned,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MasteryProgressSection(merc: merc),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ── 테스트 ────────────────────────────────────────────────────────────────────

void main() {
  group('MasteryProgressSection 위젯 테스트', () {
    // ── [TS-2] 전 카운터 0 + 전용 칭호 진행 0 → 섹션 숨김 ──────────────
    testWidgets('[TS-2] 전 카운터 0이고 전용 칭호 진행 0이면 섹션이 숨겨진다', (tester) async {
      // given: 솔로/페어/소수 의뢰를 한 번도 안 한 용병
      final merc = _makeMerc(
        stats: {
          'solo_completion_count': 0,
          'solo_great_success_count': 0,
          'pair_completion_count': 0,
          'small_party_count': 0,
        },
      );

      // when
      await _pump(tester, merc);

      // then: 섹션 헤더 없음
      expect(find.textContaining('개인 숙련도'), findsNothing);
    });

    // ── [TS-2] stats가 빈 맵일 때도 섹션 숨김 ───────────────────────────
    testWidgets('[TS-2] stats 빈 맵(기본값)이면 섹션 숨김', (tester) async {
      // given: stats가 빈 맵인 신규 용병
      final merc = _makeMerc(stats: {});

      // when
      await _pump(tester, merc);

      // then: 섹션이 없음
      expect(find.textContaining('개인 숙련도'), findsNothing);
    });

    // ── [TS-1] 보유 칭호는 ✓ 달성 배지 표시 ──────────────────────────────
    testWidgets('[TS-1] 보유 칭호는 달성 텍스트와 함께 표시된다', (tester) async {
      // given: title_lone_wolf를 보유한 용병 (solo_completion_count = 5)
      final merc = _makeMerc(
        stats: {'solo_completion_count': 5},
        titleIds: ['title_lone_wolf'],
      );
      final titles = _masteryTitles();
      final ownedTitles = titles.where((t) => t.id == 'title_lone_wolf').toList();

      // when
      await _pump(tester, merc, allTitles: titles, ownedTitles: ownedTitles);

      // then: "✓"와 "외로운 늑대", "달성" 텍스트가 있어야 한다
      expect(find.textContaining('✓'), findsOneWidget);
      expect(find.textContaining('외로운 늑대'), findsOneWidget);
      expect(find.textContaining('달성'), findsOneWidget);
    });

    // ── [TS-1] 미보유 칭호는 진행도 바 + 카운터/임계 표시 ─────────────
    testWidgets('[TS-1] 미보유 칭호는 진행도 바와 카운터/임계 텍스트를 표시한다', (tester) async {
      // given: title_lone_wolf 미보유, solo_completion_count = 3
      final merc = _makeMerc(
        stats: {'solo_completion_count': 3},
      );
      final titles = _masteryTitles();

      // when
      await _pump(tester, merc, allTitles: titles, ownedTitles: []);

      // then: 진행도 바(LinearProgressIndicator)와 "3/5" 텍스트가 있어야 한다
      expect(find.byType(LinearProgressIndicator), findsWidgets);
      expect(find.text('3/5'), findsOneWidget);
    });

    // ── [TS-3] 카운터/임계 매핑 정확성 ──────────────────────────────────
    testWidgets('[TS-3] solo_completion_count=3이면 "외로운 늑대 3/5" 진행도 표시', (tester) async {
      // given: solo_completion_count = 3, 칭호 미보유
      final merc = _makeMerc(
        stats: {'solo_completion_count': 3},
      );
      final titles = _masteryTitles();

      // when
      await _pump(tester, merc, allTitles: titles, ownedTitles: []);

      // then: 칭호명 "외로운 늑대"와 "3/5" 진행도 텍스트 표시
      expect(find.textContaining('외로운 늑대'), findsOneWidget);
      expect(find.text('3/5'), findsOneWidget);
    });

    // ── [TS-3] pair_completion_count 매핑 정확성 ─────────────────────────
    testWidgets('[TS-3] pair_completion_count=4이면 "4/8" 진행도 표시', (tester) async {
      // given
      final merc = _makeMerc(
        stats: {'pair_completion_count': 4},
      );
      final titles = _masteryTitles();

      // when
      await _pump(tester, merc, allTitles: titles, ownedTitles: []);

      // then
      expect(find.textContaining('은빛 쌍검'), findsOneWidget);
      expect(find.text('4/8'), findsOneWidget);
    });

    // ── [TS-3] small_party_count 매핑 정확성 ─────────────────────────────
    testWidgets('[TS-3] small_party_count=7이면 "7/10" 진행도 표시', (tester) async {
      // given
      final merc = _makeMerc(
        stats: {'small_party_count': 7},
      );
      final titles = _masteryTitles();

      // when
      await _pump(tester, merc, allTitles: titles, ownedTitles: []);

      // then
      expect(find.textContaining('삼왕의 계약'), findsOneWidget);
      expect(find.text('7/10'), findsOneWidget);
    });

    // ── 칭호 정적 데이터 없을 때 해당 칭호 skip ──────────────────────────
    testWidgets('전용 칭호 정적 데이터 미존재 시 해당 칭호 행 skip(fail-soft)', (tester) async {
      // given: 빈 titles 정적 데이터, solo_completion_count=3
      final merc = _makeMerc(
        stats: {'solo_completion_count': 3},
      );

      // when: titles 빈 목록
      await _pump(tester, merc, allTitles: [], ownedTitles: []);

      // then: 섹션 표시 여부에 관계없이 예외 없음
      // (totalCounters>0이므로 섹션은 표시될 수 있으나 칭호 행 없음)
      expect(tester.takeException(), isNull);
    });

    // ── 카운터 > 0이면 섹션 표시 ─────────────────────────────────────────
    testWidgets('solo_completion_count=1이면 전용 칭호 진행 0이어도 섹션을 표시한다', (tester) async {
      // given: solo_completion_count = 1 (totalCounters > 0)
      final merc = _makeMerc(
        stats: {'solo_completion_count': 1},
      );
      final titles = _masteryTitles();

      // when
      await _pump(tester, merc, allTitles: titles, ownedTitles: []);

      // then: 섹션 헤더 표시
      expect(find.textContaining('개인 숙련도'), findsOneWidget);
    });
  });
}
