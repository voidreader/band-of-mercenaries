// LivingsphereDashboardService 단위 테스트.
//
// 검증 범위:
//   - 명세 §4.6 곡선 4단계 단조 증가 + 손 계산 수치 ±2% 허용 오차
//   - clamp 6 케이스 (dangerScore 양극단·infrastructureTier 범위 외·RegionState null fallback)
//   - weights 합 = 1.0
//   - influence 분기 (untouched/joined/hostile)
//
// 테스트 격리:
//   - 임시 Hive 디렉토리에 박스를 열어 BandAchievement / RegionState 직접 주입
//     (BandAchievementsNotifier가 box.watch 의존하므로 Hive 우회 불가)
//   - staticDataProvider / chainQuestProgressProvider / craftingServiceProvider /
//     factionStateRepositoryProvider는 ProviderContainer overrides로 주입

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/models/crafting_recipe_data.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/achievement/domain/mercenary_snapshot_model.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_provider.dart';
import 'package:band_of_mercenaries/features/crafting/domain/crafting_provider.dart';
import 'package:band_of_mercenaries/features/crafting/domain/crafting_service.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_dashboard_models.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_dashboard_service.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_metrics_config.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';

// ============================================================================
// Hive 셋업 (임시 디렉토리)
// ============================================================================

late Directory _tempDir;

Future<void> _setUpHive() async {
  _tempDir =
      Directory.systemTemp.createTempSync('livingsphere_dashboard_test_');
  Hive.init(_tempDir.path);

  void registerIfAbsent<T>(int typeId, TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  // 본 테스트가 사용하는 typeId만 등록 (다른 박스는 열지 않음).
  registerIfAbsent(8, RegionStateAdapter());
  registerIfAbsent(16, BandAchievementAdapter());
  registerIfAbsent(17, BandAchievementTypeAdapter());
  registerIfAbsent(18, MercenarySnapshotAdapter());

  await Hive.openBox<RegionState>(HiveInitializer.regionStateBoxName);
  await Hive.openBox<BandAchievement>(HiveInitializer.bandAchievementBoxName);
}

Future<void> _tearDownHive() async {
  await Hive.close();
  _tempDir.deleteSync(recursive: true);
}

// ============================================================================
// Fake Repositories
// ============================================================================

/// FactionStateRepository.getState만 override (Hive box 의존 회피).
class _FakeFactionStateRepository extends FactionStateRepository {
  _FakeFactionStateRepository(this._states);
  final Map<String, FactionState> _states;

  @override
  FactionState? getState(String factionId) => _states[factionId];
}

/// CraftingService.evaluateState만 override.
class _FakeCraftingService implements CraftingService {
  _FakeCraftingService(this._unlockedRecipeIds);
  final Set<String> _unlockedRecipeIds;

  @override
  RecipeState evaluateState(CraftingRecipeData recipe) {
    return _unlockedRecipeIds.contains(recipe.id)
        ? RecipeState.ready
        : RecipeState.locked;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ============================================================================
// Fixture
// ============================================================================

class _TestFixture {
  _TestFixture({
    this.dangerScore,
    this.infrastructureTier,
    this.triggeredDiscoveries = const <String>[],
    this.questPoolCompletionCounts = const <String, int>{},
    this.firstAcquiredMaterials = const <String>[],
    this.unlockedRecipeIds = const <String>[],
    this.achievementTemplateIds = const <String>[],
    this.factions = const <String, _FactionFixture>{},
    this.chainStep,
    this.skipRegionState = false,
  });

  final int? dangerScore;
  final int? infrastructureTier;
  final List<String> triggeredDiscoveries;
  final Map<String, int> questPoolCompletionCounts;
  final List<String> firstAcquiredMaterials;
  final List<String> unlockedRecipeIds;
  final List<String> achievementTemplateIds;
  final Map<String, _FactionFixture> factions;
  final int? chainStep;
  final bool skipRegionState;
}

class _FactionFixture {
  const _FactionFixture({required this.reputation, required this.joined});
  final int reputation;
  final bool joined;
}

/// 38필드 StaticGameData를 빈 list로 채우되 craftingRecipes만 [recipeIds]에서 생성.
StaticGameData _buildStaticData(List<String> recipeIds) {
  final recipes = recipeIds
      .map((id) => CraftingRecipeData(
            id: id,
            name: id,
            resultItemId: 'item_$id',
            inputs: const [],
          ))
      .toList();
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
    regionAdjacencies: const [],
    regionSectors: const [],
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
    craftingRecipes: recipes,
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
    hiddenStats: const [],
    battleMemoryTemplates: const [],
  );
}

/// fixture에서 Hive box / Provider override를 모두 구성한 ProviderContainer 반환.
Future<ProviderContainer> _buildContainer(_TestFixture f) async {
  // 1) Hive 박스 초기화 (테스트 간 격리).
  final regionBox =
      Hive.box<RegionState>(HiveInitializer.regionStateBoxName);
  final achBox =
      Hive.box<BandAchievement>(HiveInitializer.bandAchievementBoxName);
  await regionBox.clear();
  await achBox.clear();

  if (!f.skipRegionState) {
    final rs = RegionState(
      regionId: 3,
      dangerScore: f.dangerScore,
      infrastructureTier: f.infrastructureTier,
      triggeredDiscoveries: List.of(f.triggeredDiscoveries),
      questPoolCompletionCounts: Map.of(f.questPoolCompletionCounts),
      firstAcquiredMaterialIds: List.of(f.firstAcquiredMaterials),
    );
    await regionBox.add(rs);
  }

  for (final tid in f.achievementTemplateIds) {
    await achBox.add(BandAchievement(
      id: 'ach_$tid',
      type: BandAchievementType.achievement,
      achievedAt: DateTime(2026, 1, 1),
      templateId: tid,
    ));
  }

  // 2) FactionState map 구성.
  final factionStates = <String, FactionState>{};
  f.factions.forEach((id, ff) {
    factionStates[id] = FactionState(
      factionId: id,
      reputation: ff.reputation,
      joined: ff.joined,
    );
  });

  // 3) ChainQuestProgress 리스트.
  final chainProgress = f.chainStep != null
      ? [
          ChainQuestProgress(
            chainId: LivingsphereMetricsConfig.settlementChainId,
            currentStep: f.chainStep!,
            startedAt: DateTime(2026, 1, 1),
          ),
        ]
      : <ChainQuestProgress>[];

  final staticData = _buildStaticData(f.unlockedRecipeIds);

  final container = ProviderContainer(
    overrides: [
      factionStateRepositoryProvider
          .overrideWithValue(_FakeFactionStateRepository(factionStates)),
      staticDataProvider.overrideWith((ref) async => staticData),
      chainQuestProgressProvider
          .overrideWith((ref) => Stream.value(chainProgress)),
      craftingServiceProvider.overrideWithValue(
        _FakeCraftingService(f.unlockedRecipeIds.toSet()),
      ),
    ],
  );

  // FutureProvider / StreamProvider 첫 emit을 강제 resolve하여
  // valueOrNull이 안정적으로 set되도록 한다. 두 번 await하는 이유는
  // Stream.value override가 microtask 큐를 한 번 더 돌아야
  // AsyncValue.data가 캐시되는 Riverpod 동작 때문.
  await container.read(staticDataProvider.future);
  await container.read(chainQuestProgressProvider.future);
  await container.read(chainQuestProgressProvider.future);

  return container;
}

/// 호출자 측에서 `Ref<Object?>`를 얻기 위한 proxy Provider.
final _proxyRefProvider = Provider<Ref<Object?>>((ref) => ref);

double _readTotal(ProviderContainer container) {
  // _buildContainer에서 pre-warm이 끝났으므로 sync read만 호출.
  final ref = container.read(_proxyRefProvider);
  return LivingsphereDashboardService.computeSnapshot(ref).totalCompletionPct;
}

LivingsphereDashboardSnapshot _readSnapshot(ProviderContainer container) {
  final ref = container.read(_proxyRefProvider);
  return LivingsphereDashboardService.computeSnapshot(ref);
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  setUpAll(() async {
    await _setUpHive();
  });

  tearDownAll(() async {
    await _tearDownHive();
  });

  group('LivingsphereDashboardService 곡선 4단계', () {
    test('#1 신규 시작 — 모든 분자 0, dangerScore=0 → ≈ 10.0%', () async {
      final container = await _buildContainer(_TestFixture(
        dangerScore: 0,
        infrastructureTier: null,
      ));
      addTearDown(container.dispose);

      final total = _readTotal(container);
      // stability = (100-0)/200*100 = 50% × 0.20 = 10
      expect(total, closeTo(10.0, 1.0));
    });

    test('#2 1~3시간 — dangerScore=-20, Tier=2, chainStep=2, '
        'discoveries=1, firstAcquired=1, recipes=2, 1세력 joined rep 5 → ≈ 29%', () async {
      final container = await _buildContainer(_TestFixture(
        dangerScore: -20,
        infrastructureTier: 2,
        chainStep: 2,
        triggeredDiscoveries: const ['disc_dustvile_pyegwang_normal'],
        firstAcquiredMaterials: const ['mat_herb_dust_resin'],
        unlockedRecipeIds: const [
          'recipe_dustvile_banner_repair',
          'recipe_dustvile_hide_bundle',
        ],
        factions: const {
          'faction_adventurers_guild':
              _FactionFixture(reputation: 5, joined: true),
        },
      ));
      addTearDown(container.dispose);

      final total = _readTotal(container);
      // stab=60% × 0.20 = 12.0
      // infra=33.33% × 0.20 = 6.67
      // event=(2+1+0)/11=27.27% × 0.20 = 5.45
      // resource=(1/5*50)+(2/10*50)=20% × 0.15 = 3.0
      // influence=joined rep5 → 50+(5/100)*50=52.5 + 2× untouched(0) / 3 = 17.5% × 0.10 = 1.75
      // achievement=0
      // total ≈ 28.87%
      expect(total, closeTo(28.87, 2.0));
    });

    test('#3 5~10시간 — dangerScore=-60, Tier=3, chainStep=6, '
        'discoveries=2, statePool=1, firstAcquired=3, recipes=5, '
        '2세력 joined rep30 → ≈ 58%', () async {
      final container = await _buildContainer(_TestFixture(
        dangerScore: -60,
        infrastructureTier: 3,
        chainStep: 6,
        triggeredDiscoveries: const [
          'disc_dustvile_pyegwang_normal',
          'disc_dustvile_pyegwang_hidden',
        ],
        questPoolCompletionCounts: const {'qp_m7_r3_cave_bats': 1},
        firstAcquiredMaterials: const [
          'mat_herb_dust_resin',
          'mat_relic_pyegwang_pickaxe_head',
          'mat_relic_pyegwang_shard',
        ],
        unlockedRecipeIds: const [
          'recipe_dustvile_banner_repair',
          'recipe_dustvile_hide_bundle',
          'recipe_dustvile_ore_polished',
          'recipe_dustvile_armor_solid',
          'recipe_dustvile_herbalist_seal',
        ],
        factions: const {
          'faction_adventurers_guild':
              _FactionFixture(reputation: 30, joined: true),
          'faction_merchants_alliance':
              _FactionFixture(reputation: 30, joined: true),
        },
      ));
      addTearDown(container.dispose);

      final total = _readTotal(container);
      // stab=80% × 0.20 = 16
      // infra=66.7% × 0.20 = 13.34
      // event=(6+2+1)/11=81.8% × 0.20 = 16.36
      // resource=(3/5*50)+(5/10*50)=55% × 0.15 = 8.25
      // influence=2× joined rep30(65) + 1 untouched(0) / 3 = 43.3% × 0.10 = 4.33
      // achievement=0
      // total ≈ 58.28%
      expect(total, closeTo(58.28, 3.0));
    });

    test('#4 Tier 4 직전 — dangerScore=-90, Tier=4, chainStep=6, '
        'discoveries=3, statePool=2, firstAcquired=5, recipes=9, '
        '3세력 joined rep60, 4/5 위업 → ≈ 93%', () async {
      final container = await _buildContainer(_TestFixture(
        dangerScore: -90,
        infrastructureTier: 4,
        chainStep: 6,
        triggeredDiscoveries:
            LivingsphereMetricsConfig.region3DiscoveryIds.toList(),
        questPoolCompletionCounts: const {
          'qp_m7_r3_cave_bats': 1,
          'qp_m7_r3_safe_escort': 1,
        },
        firstAcquiredMaterials:
            LivingsphereMetricsConfig.region3MaterialIds.toList(),
        unlockedRecipeIds:
            LivingsphereMetricsConfig.region3RecipeIds.take(9).toList(),
        factions: const {
          'faction_adventurers_guild':
              _FactionFixture(reputation: 60, joined: true),
          'faction_merchants_alliance':
              _FactionFixture(reputation: 60, joined: true),
          'faction_warriors_guild':
              _FactionFixture(reputation: 60, joined: true),
        },
        achievementTemplateIds: LivingsphereMetricsConfig
            .region3AchievementTemplateIds
            .take(4)
            .toList(),
      ));
      addTearDown(container.dispose);

      final total = _readTotal(container);
      // stab=95% × 0.20 = 19
      // infra=100% × 0.20 = 20
      // event=11/11=100% × 0.20 = 20
      // resource=(5/5*50)+(9/10*50)=95% × 0.15 = 14.25
      // influence=3× joined rep60(80) / 3 = 80% × 0.10 = 8.0
      // achievement=4/5=80% × 0.15 = 12
      // total ≈ 93.25%
      expect(total, closeTo(93.25, 2.0));
    });

    test('#5 완전 클리어 — 모든 분자=분모, 평균 rep 100 → 100.0%', () async {
      final container = await _buildContainer(_TestFixture(
        dangerScore: -100,
        infrastructureTier: 4,
        chainStep: 6,
        triggeredDiscoveries:
            LivingsphereMetricsConfig.region3DiscoveryIds.toList(),
        questPoolCompletionCounts: const {
          'qp_m7_r3_cave_bats': 1,
          'qp_m7_r3_safe_escort': 1,
        },
        firstAcquiredMaterials:
            LivingsphereMetricsConfig.region3MaterialIds.toList(),
        unlockedRecipeIds:
            LivingsphereMetricsConfig.region3RecipeIds.toList(),
        factions: const {
          'faction_adventurers_guild':
              _FactionFixture(reputation: 100, joined: true),
          'faction_merchants_alliance':
              _FactionFixture(reputation: 100, joined: true),
          'faction_warriors_guild':
              _FactionFixture(reputation: 100, joined: true),
        },
        achievementTemplateIds:
            LivingsphereMetricsConfig.region3AchievementTemplateIds.toList(),
      ));
      addTearDown(container.dispose);

      final total = _readTotal(container);
      expect(total, closeTo(100.0, 0.1));
    });

    test('단조 증가 — #1 → #2 → #3 → #4 → #5는 항상 증가', () async {
      final fixtures = [
        _TestFixture(dangerScore: 0),
        _TestFixture(
          dangerScore: -20,
          infrastructureTier: 2,
          chainStep: 2,
        ),
        _TestFixture(
          dangerScore: -60,
          infrastructureTier: 3,
          chainStep: 4,
        ),
        _TestFixture(
          dangerScore: -90,
          infrastructureTier: 4,
          chainStep: 6,
        ),
      ];

      final stages = <double>[];
      for (final fixture in fixtures) {
        final c = await _buildContainer(fixture);
        stages.add(_readTotal(c));
        c.dispose();
      }

      for (var i = 1; i < stages.length; i++) {
        expect(
          stages[i],
          greaterThan(stages[i - 1]),
          reason: '단계 $i가 단계 ${i - 1}보다 커야 한다: '
              '${stages[i]} > ${stages[i - 1]}',
        );
      }
    });
  });

  group('LivingsphereDashboardService clamp', () {
    test('clamp #1 — dangerScore=+150 (허용 범위 외) → stability=0%', () async {
      final container = await _buildContainer(_TestFixture(dangerScore: 150));
      addTearDown(container.dispose);

      final snapshot = _readSnapshot(container);
      final stab = snapshot.metrics[MetricKey.stability]!;
      expect(stab.percent, equals(0.0));
    });

    test('clamp #2 — dangerScore=-150 (허용 범위 외) → stability=100%', () async {
      final container = await _buildContainer(_TestFixture(dangerScore: -150));
      addTearDown(container.dispose);

      final snapshot = _readSnapshot(container);
      final stab = snapshot.metrics[MetricKey.stability]!;
      expect(stab.percent, equals(100.0));
    });

    test('clamp #3 — infrastructureTier=5 (허용 외) → 100% 클램프', () async {
      final container =
          await _buildContainer(_TestFixture(infrastructureTier: 5));
      addTearDown(container.dispose);

      final snapshot = _readSnapshot(container);
      final infra = snapshot.metrics[MetricKey.infrastructure]!;
      expect(infra.percent, equals(100.0));
      expect(infra.currentValue, equals(4));
    });

    test('clamp #4 — infrastructureTier=0 (허용 외) → 0% 클램프', () async {
      final container =
          await _buildContainer(_TestFixture(infrastructureTier: 0));
      addTearDown(container.dispose);

      final snapshot = _readSnapshot(container);
      final infra = snapshot.metrics[MetricKey.infrastructure]!;
      expect(infra.percent, equals(0.0));
      expect(infra.currentValue, equals(1));
    });

    test('clamp #5 — RegionState 미존재 → null fallback (stab=50%, infra=0%)',
        () async {
      final container =
          await _buildContainer(_TestFixture(skipRegionState: true));
      addTearDown(container.dispose);

      final snapshot = _readSnapshot(container);
      expect(snapshot.metrics[MetricKey.stability]!.percent, equals(50.0));
      expect(snapshot.metrics[MetricKey.infrastructure]!.percent, equals(0.0));
      expect(snapshot.metrics[MetricKey.eventCompletion]!.percent, equals(0.0));
      expect(snapshot.metrics[MetricKey.resourceCraft]!.percent, equals(0.0));
    });

    test('clamp #6 — chainStep>6 (이론상 불가능하지만 cap 검증) → 6으로 제한',
        () async {
      final container = await _buildContainer(_TestFixture(chainStep: 10));
      addTearDown(container.dispose);

      final snapshot = _readSnapshot(container);
      final event = snapshot.metrics[MetricKey.eventCompletion]!;
      // (6+0+0)/11 ≈ 54.55%
      expect(event.percent, closeTo(54.55, 0.1));
      expect(event.currentValue, equals(6));
    });
  });

  group('LivingsphereDashboardService 산식 검증', () {
    test('weights 합 = 1.0', () {
      final sum =
          LivingsphereMetricsConfig.weights.values.fold(0.0, (a, b) => a + b);
      expect(sum, closeTo(1.0, 0.0001));
    });

    test('snapshot.regionId는 항상 3', () async {
      final container = await _buildContainer(_TestFixture());
      addTearDown(container.dispose);

      final snapshot = _readSnapshot(container);
      expect(snapshot.regionId, equals(3));
    });

    test('snapshot.metrics는 6 키 모두 존재', () async {
      final container = await _buildContainer(_TestFixture());
      addTearDown(container.dispose);

      final snapshot = _readSnapshot(container);
      expect(snapshot.metrics.keys.toSet(), equals(MetricKey.values.toSet()));
    });

    test('influence — hostile 세력은 reputation에 따라 0~20% 점수', () async {
      final container = await _buildContainer(_TestFixture(
        factions: const {
          'faction_adventurers_guild':
              _FactionFixture(reputation: -100, joined: false),
          'faction_merchants_alliance':
              _FactionFixture(reputation: -50, joined: false),
          'faction_warriors_guild':
              _FactionFixture(reputation: -1, joined: false),
        },
      ));
      addTearDown(container.dispose);

      final snapshot = _readSnapshot(container);
      final influence = snapshot.metrics[MetricKey.influence]!;
      // hostile rep=-100 → 0, rep=-50 → 10, rep=-1 → 19.8 → 평균 ≈ 9.93
      expect(influence.percent, closeTo(9.93, 0.5));
    });

    test('influence — 세력 미설정 시 모두 untouched(0)', () async {
      final container = await _buildContainer(_TestFixture());
      addTearDown(container.dispose);

      final snapshot = _readSnapshot(container);
      expect(snapshot.metrics[MetricKey.influence]!.percent, equals(0.0));
    });
  });
}
