import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_service.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/achievement/domain/memorial_cause.dart';
import 'package:band_of_mercenaries/features/achievement/domain/mercenary_snapshot_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_completion_side_effects.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/title/domain/title_service.dart';

// ---------------------------------------------------------------------------
// 기존 사이드이펙트 테스트용 픽스처
// ---------------------------------------------------------------------------

ActiveQuest _exclusiveQuest() => ActiveQuest(
  id: 'active_runtime_id',
  questPoolId: 'pool_faction_contract',
  questTypeId: 'raid',
  difficulty: 1,
  region: 17,
  questName: '세력 전용 의뢰',
  isAdvancedTrack: false,
);

ActiveQuest _chainQuest() => ActiveQuest(
  id: 'chain_runtime_id',
  questPoolId: 'chain_pool',
  questTypeId: 'raid',
  difficulty: 1,
  region: 42,
  questName: '연계 보상 의뢰',
  isChainStep: true,
  chainId: 'settlement_42_test',
  chainStep: 3,
);

// ---------------------------------------------------------------------------
// Hive 임시 박스 셋업/해제 헬퍼
// ---------------------------------------------------------------------------

late Directory _tempDir;
late Box<BandAchievement> _achievementBox;

Future<void> _setUpHive() async {
  _tempDir = Directory.systemTemp.createTempSync('side_effects_test_');
  Hive.init(_tempDir.path);
  if (!Hive.isAdapterRegistered(17)) {
    Hive.registerAdapter(BandAchievementTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(19)) {
    Hive.registerAdapter(MemorialCauseAdapter());
  }
  if (!Hive.isAdapterRegistered(18)) {
    Hive.registerAdapter(MercenarySnapshotAdapter());
  }
  if (!Hive.isAdapterRegistered(16)) {
    Hive.registerAdapter(BandAchievementAdapter());
  }
  _achievementBox = await Hive.openBox<BandAchievement>(
    'side_effects_test_box',
  );
}

Future<void> _tearDownHive() async {
  await _achievementBox.close();
  await Hive.deleteBoxFromDisk('side_effects_test_box');
  _tempDir.deleteSync(recursive: true);
}

// ---------------------------------------------------------------------------
// AchievementService 생성 헬퍼
// ---------------------------------------------------------------------------

/// getMercenary 콜백을 외부에서 주입할 수 있는 팩토리.
AchievementService _makeAchievementService({
  Mercenary? Function(String mercId)? getMercenary,
}) {
  return AchievementService(
    box: _achievementBox,
    uuid: const Uuid(),
    addLog: (msg, type) {},
    enqueueDialog: (req) {},
    templates: const [],
    buildAchievementDialog: (achievement, titles, onDismiss) =>
        const SizedBox.shrink(),
    getMercenary: getMercenary,
    updateMercenary: getMercenary != null ? (merc) async {} : null,
  );
}

// ---------------------------------------------------------------------------
// TitleService 생성 헬퍼
// ---------------------------------------------------------------------------

TitleService _makeTitleService({
  required Mercenary? Function(String mercId) getMercenary,
}) {
  return TitleService(
    titles: const [],
    getMercenary: getMercenary,
    updateMercenaryTitles: (mercId, titleIds) async {},
    addLog: (msg, type) {},
    enqueueDialog: (req) {},
    hasAchievement: (templateId) => false,
    bandAchievements: () => const [],
    staticData: _emptyStaticData(),
    buildTitleDialog: ({
      required title,
      required mercSnapshot,
      required reasonText,
      required onDismiss,
    }) =>
        const SizedBox.shrink(),
  );
}

// ---------------------------------------------------------------------------
// StaticGameData 최소 픽스처
// ---------------------------------------------------------------------------

StaticGameData _emptyStaticData() => StaticGameData(
  difficulties: [],
  jobs: [],
  traits: [],
  traitCategories: [],
  traitConflicts: [],
  traitTransitions: [],
  traitComboEvolutions: [],
  traitSynergies: [],
  regions: [],
  questTypes: [],
  questPools: [],
  personNames: [],
  travelEvents: [],
  facilities: [],
  ranks: [],
  mercenaryWages: [],
  regionDiscoveries: [],
  factions: [],
  items: [],
  eliteMonsters: [],
  eliteLootEntries: [],
  chainQuests: [],
  questNarratives: [],
  travelChoiceEvents: [],
  travelChoiceOptions: [],
  travelChoiceResults: [],
  regionAdjacencies: [],
  regionSectors: [],
  craftingRecipes: [],
  questPoolMaterialDrops: [],
  bandAchievementTemplates: [],
  titles: [],
  factionContacts: [],
  factionReactions: [],
  factionShopItems: [],
  combatReportTemplates: [],
  combatReportKeywords: [],
  combatSkills: [],
  combatStatusEffects: [],
  enemyArchetypes: [],
  hiddenStats: [],
  battleMemoryTemplates: [],
);

// ---------------------------------------------------------------------------
// main()
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // 기존 QuestCompletionSideEffects 테스트 (변경 없음)
  // =========================================================================

  group('QuestCompletionSideEffects', () {
    test('전용 퀘스트 쿨다운 키는 런타임 quest id가 아니라 questPoolId를 사용한다', () {
      final key = QuestCompletionSideEffects.factionCooldownKey(
        _exclusiveQuest(),
      );

      expect(key, 'pool_faction_contract');
      expect(key, isNot('active_runtime_id'));
    });

    test('체인 보상 재료 획득 지역은 시작 지역이 아니라 완료한 퀘스트 지역이다', () {
      final regionId = QuestCompletionSideEffects.materialAcquiredRegion(
        _chainQuest(),
      );

      expect(regionId, 42);
    });
  });

  // =========================================================================
  // M8.5 페이즈 4 #3 — achievement_granted battleMemory trailing fail-soft 검증
  // 명세 §3.5: getMercenary=null 반환 시 battleMemory skip, 위업 본체 정상 발급 확인.
  // =========================================================================

  group('achievement_granted battleMemory trailing — getMercenary=null 시 fail-soft', () {
    setUp(_setUpHive);
    tearDown(_tearDownHive);

    test('getMercenary가 null 반환해도 grant()는 예외 없이 BandAchievement를 반환한다', () async {
      // getMercenary는 항상 null 반환 (용병 룩업 실패 시뮬레이션)
      final service = _makeAchievementService(
        getMercenary: (_) => null,
      );

      final result = await service.grant(
        'test_achievement_001',
        payload: const {'test': true},
      );

      // 위업 본체는 정상 발급
      expect(result, isNotNull, reason: 'getMercenary=null이어도 위업 발급 성공');
      expect(result!.templateId, 'test_achievement_001');
      expect(_achievementBox.values.length, 1);
    });

    test('getMercenary=null 시 battleMemory skip — box에 achievement만 1개 존재', () async {
      final service = _makeAchievementService(
        getMercenary: (_) => null,
      );

      await service.grant('test_achievement_002');

      // battleMemory trailing이 실행되지 않아도 achievement는 저장됨
      expect(_achievementBox.values.length, 1);
      expect(_achievementBox.values.first.templateId, 'test_achievement_002');
    });

    test('getMercenary=null + mercSnapshot non-null 시에도 grant 정상 반환', () async {
      // battleMemory trailing 내부 if 조건: getMercenary != null 이 false → 분기 자체 실행 안 됨
      final service = _makeAchievementService(
        getMercenary: (_) => null,
      );
      final snapshot = MercenarySnapshot(
        id: 'merc_999',
        name: '영웅',
        jobId: 'warrior',
        jobName: '전사',
        tier: 2,
      );

      final result = await service.grant(
        'test_achievement_003',
        mercSnapshot: snapshot,
      );

      expect(result, isNotNull);
      expect(result!.mercSnapshot?.id, 'merc_999');
      // battleMemory trailing이 skip됐어도 본체는 저장
      expect(_achievementBox.values.length, 1);
    });

    test('멱등성: 동일 templateId를 두 번 grant해도 두 번째는 null 반환 + box 항목 1개', () async {
      final service = _makeAchievementService();

      final first = await service.grant('idempotent_001');
      final second = await service.grant('idempotent_001');

      expect(first, isNotNull);
      expect(second, isNull, reason: '중복 발급 차단');
      expect(_achievementBox.values.length, 1);
    });
  });

  // =========================================================================
  // M8.5 페이즈 4 #3 — title_granted battleMemory trailing fail-soft 검증
  // TitleService hook 메서드들에서 getMercenary=null 반환 시
  // _grantTitle을 호출하지 않고 예외 없이 종료한다.
  // 명세 §3.5: "getMercenary=null 콜백 주입 → grant/_grantTitle 호출이 예외 없이 완료"
  // =========================================================================

  group('title_granted battleMemory trailing — getMercenary=null 시 _grantTitle skip', () {
    test('evaluateAchievementHook: getMercenary=null 반환 시 예외 없이 빈 목록 반환', () async {
      // titles=[] → 루프 미실행이지만 getMercenary=null 인터페이스 계약 검증.
      final service = _makeTitleService(getMercenary: (_) => null);
      final achievement = _makeDummyAchievement();
      final ctx = AchievementHookContext(achievement: achievement);

      final granted = await service.evaluateAchievementHook(achievement, ctx);

      // 예외 없이 완료 + 발급된 칭호 없음 (skip)
      expect(granted, isEmpty);
    });

    test('evaluateActionStatHook: getMercenary=null 반환 시 early return (예외 없음)', () async {
      // getMercenary null → merc == null 분기 → 즉시 return
      final service = _makeTitleService(getMercenary: (_) => null);

      await expectLater(
        service.evaluateActionStatHook('non_existent_merc'),
        completes,
      );
    });

    test('evaluateStatusHook: getMercenary=null 반환 시 early return (예외 없음)', () async {
      final service = _makeTitleService(getMercenary: (_) => null);

      await expectLater(
        service.evaluateStatusHook(
          'non_existent_merc',
          MercenaryStatus.normal,
          const {},
        ),
        completes,
      );
    });

    test('evaluateFactionReputationHook: getMercenary=null 반환 시 칭호 미발급 (예외 없음)', () async {
      // 내부에서 getMercenary(targetMercId) == null → continue/return
      final service = _makeTitleService(getMercenary: (_) => null);

      await expectLater(
        service.evaluateFactionReputationHook(
          factionId: 'faction_warriors',
          oldRep: 0,
          newRep: 31,
          targetMercId: 'non_existent_merc',
        ),
        completes,
      );
    });
  });
}

// ---------------------------------------------------------------------------
// 보조 헬퍼
// ---------------------------------------------------------------------------

/// 위업 hook 테스트용 더미 BandAchievement (Hive box 미사용, in-memory).
BandAchievement _makeDummyAchievement() {
  return BandAchievement(
    id: 'test_id',
    type: BandAchievementType.achievement,
    achievedAt: DateTime.utc(2026, 1, 1),
    templateId: 'dummy_template',
  );
}
