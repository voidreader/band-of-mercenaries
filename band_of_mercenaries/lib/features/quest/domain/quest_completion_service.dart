import 'dart:math';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_narrative_service.dart';
import 'package:band_of_mercenaries/features/quest/domain/role_utils.dart';
import 'package:band_of_mercenaries/core/domain/experience_service.dart';
import 'package:band_of_mercenaries/core/domain/template_engine.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/core/domain/reputation_service.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/facility/domain/construction_service.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_evolution_service.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_service.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/features/inventory/domain/equipment_stat_bonus.dart';
import 'package:band_of_mercenaries/features/inventory/domain/legendary_effect.dart';
import 'package:band_of_mercenaries/core/models/elite_loot_entry.dart';
import 'package:band_of_mercenaries/features/quest/domain/elite_loot_service.dart';
import 'package:band_of_mercenaries/features/settlement/domain/herbalist_service.dart';

class TraitEventResult {
  final String? acquiredTraitKey;
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

class MercDamageResult {
  final String mercId;
  final MercenaryStatus newStatus;
  final DateTime? recoveryEndTime;
  final double damageRoll;
  /// 전설 ⑤ 사망 방지 특수 효과로 사망이 부상으로 다운그레이드된 경우 true.
  final bool legendaryPreventedDeath;
  /// 전설 ⑤ 발동 시 갱신할 쿨다운 만료 시각 (Mercenary.legendaryDeathPreventionCooldownUntil).
  final DateTime? newCooldownUntil;

  const MercDamageResult({
    required this.mercId,
    required this.newStatus,
    this.recoveryEndTime,
    this.damageRoll = 0.0,
    this.legendaryPreventedDeath = false,
    this.newCooldownUntil,
  });
}

class QuestCompletionResult {
  final QuestResult resultType;
  final int rewardGold;
  final int totalWage;
  final int netReward;
  final int xpGain;
  final int repGain;
  final List<MercDamageResult> mercDamages;
  final String? factionTag;
  final int factionRepGain;
  final EliteLootResult? eliteLoot;
  final String? renderedNarrative;
  // region 3 한정 일반 의뢰 신뢰도 점수 (호출측 > 0 체크로 누적 여부 결정)
  final int settlementTrustGain;

  const QuestCompletionResult({
    required this.resultType,
    required this.rewardGold,
    required this.totalWage,
    required this.netReward,
    required this.xpGain,
    required this.repGain,
    required this.mercDamages,
    this.factionTag,
    this.factionRepGain = 0,
    this.eliteLoot,
    this.renderedNarrative,
    this.settlementTrustGain = 0,
  });
}

class QuestCompletionService {
  static QuestCompletionResult calculate({
    required ActiveQuest quest,
    required List<Mercenary> mercs,
    required StaticGameData staticData,
    required int playerRegion,
    required Map<String, int> facilities,
    required double speedMultiplier,
    required Random random,
    CollectedEffects passiveEffects = const CollectedEffects.empty(),
    // 파티 장비 스탯 보정 (mercId → EquipmentStatBonus)
    Map<String, EquipmentStatBonus> partyEquipmentBonuses = const {},
    // 파티 전설 유니크 효과 리스트
    List<LegendaryEffect> legendaryEffects = const [],
    // 용병별 쿨다운 맵 (mercId → legendaryDeathPreventionCooldownUntil)
    Map<String, DateTime?> mercCooldowns = const {},
    // 엘리트 드랍 테이블 엔트리
    List<EliteLootEntry> eliteLootEntries = const [],
    // 체인 퀘스트 단계 여부 (true 시 death_rate 50% 감산)
    bool isChainStep = false,
    TemplateEngine? templateEngine,
    UserData? userData,
    List<FactionState> factionStates = const [],
    Map<String, String>? sectorChanges,
    int currentTrustLevel = 1,
    int currentInfraTier = 1,
  }) {
    // quest_pools에서 pool 조회 — is_fixed override 적용 여부 판정에 사용
    final pool = staticData.questPools.where((p) => p.id == quest.questPoolId).firstOrNull;

    final partyPower = QuestCalculator.calculatePartyPower(
      mercs,
      quest.questTypeId,
      equipmentBonuses: partyEquipmentBonuses,
    );
    final difficulty = staticData.difficulties.firstWhere(
      (d) => d.level == quest.difficulty.clamp(1, 5),
      orElse: () => staticData.difficulties.first,
    );
    final questType = staticData.questTypes.firstWhere((t) => t.id == quest.questTypeId);
    final distancePenalty = (quest.region - playerRegion).abs();

    // 성공률 판정 (트레잇 + 패시브 보너스 적용)
    final allTraitIds = mercs.expand((m) => m.allTraitIds).toSet().toList();
    final passiveSuccessBonus = PassiveBonusService.getQuestSuccessRateBonus(
      passiveEffects,
      questType: quest.questTypeId,
      partySize: mercs.length,
    );
    // 전설 ① success_rate_bonus 누적 (quest_type별 또는 all 적용)
    double legendarySuccessBonus = 0.0;
    for (final e in legendaryEffects) {
      if (e is LegendarySuccessRateBonus &&
          (e.questType == 'all' || e.questType == quest.questTypeId)) {
        legendarySuccessBonus += e.value * 100.0;
      }
    }
    // trait + legendary ① 합산값을 ±10%p 공유 clamp 적용 후 성공률 반환
    final baseSuccessRate = QuestCalculator.calculateSuccessRate(
      partyPower: partyPower,
      enemyPower: difficulty.enemyPower,
      traitBonuses: allTraitIds,
      questTypeId: quest.questTypeId,
      distancePenalty: distancePenalty,
      random: random,
      allTraits: staticData.traits,
      partySize: mercs.length,
      partyRoles: RoleUtils.extractRoles(mercs, staticData.jobs),
      legendarySuccessBonus: legendarySuccessBonus,
    );
    final successRate = (baseSuccessRate + passiveSuccessBonus).clamp(5.0, 95.0);

    final roll = random.nextDouble() * 100;
    // 전설 ② result_upgrade: 성공 → 대성공 승격 (첫 적중 시 break)
    var resultType = QuestCalculator.determineResult(successRate: successRate, roll: roll);
    if (resultType == QuestResult.success) {
      for (final e in legendaryEffects) {
        if (e is LegendaryResultUpgrade) {
          final upgradeRoll = random.nextDouble();
          if (upgradeRoll <= e.chance) {
            resultType = QuestResult.greatSuccess;
            break;
          }
        }
      }
    }

    // 보상 계산 (가산 방식으로 통합)
    final passiveRewardBonus = PassiveBonusService.getQuestRewardMultiplier(
      passiveEffects,
      quest.questTypeId,
    ) - 1.0;
    final trackBonus = quest.isFactionExclusive
        ? (quest.isAdvancedTrack == true
            ? GameConstants.trackRewardAdvanced
            : GameConstants.trackRewardBasic)
        : 0.0;
    int rewardGold = 0;
    int totalWage = 0;
    if (resultType == QuestResult.greatSuccess || resultType == QuestResult.success) {
      rewardGold = QuestCalculator.calculateReward(
        baseReward: questType.baseReward,
        rewardMultiplier: difficulty.rewardMultiplier,
        isGreatSuccess: resultType == QuestResult.greatSuccess,
        trackBonus: trackBonus,
        passiveRewardBonus: passiveRewardBonus,
        // is_fixed=true 행은 기존 보상 경로(baseReward 등) 우회 (REQ-14)
        rewardGoldOverride: pool?.isFixed == true ? pool?.rewardGoldOverride : null,
      );
      // REQ-13: 채집 의뢰 골드 보상 단계별 배수
      if (quest.questPoolId == 'dustvile_chore_03' &&
          (resultType == QuestResult.greatSuccess || resultType == QuestResult.success)) {
        rewardGold = (rewardGold * HerbalistService.gatheringMultiplier(currentTrustLevel, infraTier: currentInfraTier)).round();
      }
      // FR-11: 지명 의뢰 보상 배수 (결과 배수 직후, 칭호/세력/랭크 효과 직전)
      if (pool != null && pool.isNamed) {
        final flags = pool.specialFlags;
        final namedRewardMulti = (flags['named_reward_multiplier'] as num?)?.toDouble() ?? 1.0;
        rewardGold = (rewardGold * namedRewardMulti).round();
      }
      final mercTiers = mercs.map((merc) {
        final job = staticData.jobs.firstWhere(
          (j) => j.id == merc.jobId,
          orElse: () => staticData.jobs.first,
        );
        return job.tier;
      }).toList();
      totalWage = QuestCalculator.calculateTotalWage(mercTiers, staticData.mercenaryWages);
    }

    final netReward = rewardGold > 0 ? rewardGold - totalWage : 0;

    // XP 계산
    final xpMultiplier = ExperienceService.resultMultiplier(resultType);
    double trainingBonus = 0.0;
    final trainingLevel = facilities['training'] ?? 0;
    if (trainingLevel > 0) {
      final trainingFacility = staticData.facilities.firstWhere(
        (f) => f.id == 'training',
        orElse: () => staticData.facilities.first,
      );
      trainingBonus = ConstructionService.getEffectValue(trainingFacility, trainingLevel);
    }
    final xpGain = ExperienceService.calculateXpGain(
      difficulty: quest.difficulty.clamp(1, 5),
      resultMultiplier: xpMultiplier,
      facilityBonus: trainingBonus,
      passiveXpBonus: PassiveBonusService.getMercenaryXpBonus(passiveEffects),
      // is_fixed=true 행은 기본 XP 계산에 bonus 가산 (REQ-14)
      rewardXpBonusOverride: pool?.isFixed == true ? pool?.rewardXpBonusOverride : null,
    );

    // 명성 계산 (용병단 장비 reputation_gain_modifier 반영)
    int repGain = 0;
    if (resultType == QuestResult.greatSuccess || resultType == QuestResult.success) {
      repGain = ReputationService.calculateQuestReputation(
        difficulty: quest.difficulty.clamp(1, 5),
        isGreatSuccess: resultType == QuestResult.greatSuccess,
        reputationGainModifier: PassiveBonusService.getReputationGainModifier(passiveEffects),
      );
      // FR-11: 지명 의뢰 명성 배수 (결과 배수 직후, 칭호/세력/랭크 효과 직전)
      if (pool != null && pool.isNamed) {
        final flags = pool.specialFlags;
        final namedRepMulti = (flags['named_reputation_multiplier'] as num?)?.toDouble() ?? 1.0;
        repGain = (repGain * namedRepMulti).round();
      }
    }

    // 데미지 계산
    double recoveryReduction = 0.0;
    final infirmaryLevel = facilities['infirmary'] ?? 0;
    if (infirmaryLevel > 0) {
      final infirmaryFacility = staticData.facilities.firstWhere(
        (f) => f.id == 'infirmary',
        orElse: () => staticData.facilities.first,
      );
      recoveryReduction = ConstructionService.getEffectValue(infirmaryFacility, infirmaryLevel);
    }

    double injuryReduction = 0.0;
    final fieldHospitalFacility = staticData.facilities.where((f) => f.id == 'field_hospital').firstOrNull;
    if (fieldHospitalFacility != null) {
      final fieldHospitalLevel = facilities['field_hospital'] ?? 0;
      injuryReduction = ConstructionService.getEffectValue(fieldHospitalFacility, fieldHospitalLevel);
    }

    // 부상률에 패시브 injury_rate_modifier 배수 적용
    final effectiveInjuryRate = difficulty.injuryRate *
        (1.0 - injuryReduction) *
        PassiveBonusService.getInjuryRateMultiplier(passiveEffects);

    // 체인 퀘스트 단계 시 사망률 50% 감산
    final effectiveDeathRate = difficulty.deathRate * (isChainStep ? 0.5 : 1.0);

    final now = DateTime.now();
    final mercDamages = <MercDamageResult>[];
    for (final merc in mercs) {
      if (resultType == QuestResult.failure || resultType == QuestResult.criticalFailure) {
        final damageRoll = random.nextDouble();
        final damageResult = QuestCalculator.calculateDamage(
          roll: damageRoll,
          deathRate: effectiveDeathRate,
          injuryRate: effectiveInjuryRate,
          traitId: merc.traitId,
          traitIds: merc.allTraitIds,
          allTraits: staticData.traits,
          legendaryEffects: legendaryEffects,
        );
        if (damageResult == DamageResult.dead) {
          // 전설 ⑤ 사망 방지: 쿨다운 미만료 시 부상으로 다운그레이드
          final special = legendaryEffects.whereType<LegendarySpecial>().firstOrNull;
          final cooldownUntil = mercCooldowns[merc.id];
          final canPrevent = special != null && (cooldownUntil == null || now.isAfter(cooldownUntil));
          if (canPrevent) {
            final baseRecoverySeconds = (difficulty.level * 10 * 60 / speedMultiplier).round();
            final passiveRecoveryMultiplier = PassiveBonusService.getRecoveryTimeMultiplier(
              passiveEffects,
              'injured',
            );
            final adjustedRecoverySeconds = (baseRecoverySeconds * (1.0 - recoveryReduction) * passiveRecoveryMultiplier).round();
            mercDamages.add(MercDamageResult(
              mercId: merc.id,
              newStatus: MercenaryStatus.injured,
              recoveryEndTime: now.add(Duration(seconds: adjustedRecoverySeconds)),
              damageRoll: damageRoll,
              legendaryPreventedDeath: true,
              newCooldownUntil: now.add(Duration(hours: special.cooldownHours)),
            ));
          } else {
            mercDamages.add(MercDamageResult(mercId: merc.id, newStatus: MercenaryStatus.dead, damageRoll: damageRoll));
          }
        } else if (damageResult == DamageResult.injured) {
          final baseRecoverySeconds = (difficulty.level * 10 * 60 / speedMultiplier).round();
          final passiveRecoveryMultiplier = PassiveBonusService.getRecoveryTimeMultiplier(
            passiveEffects,
            'injured',
          );
          final adjustedRecoverySeconds = (baseRecoverySeconds * (1.0 - recoveryReduction) * passiveRecoveryMultiplier).round();
          mercDamages.add(MercDamageResult(
            mercId: merc.id,
            newStatus: MercenaryStatus.injured,
            recoveryEndTime: now.add(Duration(seconds: adjustedRecoverySeconds)),
            damageRoll: damageRoll,
          ));
        } else {
          mercDamages.add(MercDamageResult(mercId: merc.id, newStatus: MercenaryStatus.normal, damageRoll: damageRoll));
        }
      } else {
        final tiredSeconds = (5 * 60 / speedMultiplier).round();
        mercDamages.add(MercDamageResult(
          mercId: merc.id,
          newStatus: MercenaryStatus.tired,
          recoveryEndTime: now.add(Duration(seconds: tiredSeconds)),
        ));
      }
    }

    // 세력 평판 보상 (성공/대성공 시에만 지급)
    final factionRepGain = (quest.factionTag != null &&
            (resultType == QuestResult.greatSuccess ||
                resultType == QuestResult.success))
        ? (quest.reputationReward ?? 0)
        : 0;

    // 엘리트 드랍 롤 (대실패 제외, eliteId 존재 시에만)
    EliteLootResult? eliteLoot;
    if (quest.isElite && resultType != QuestResult.criticalFailure) {
      eliteLoot = EliteLootService.rollDrops(
        eliteId: quest.eliteId!,
        lootEntries: eliteLootEntries,
        random: random,
      );
    }

    String? renderedNarrative;
    if (templateEngine != null && userData != null) {
      final seed = DateTime.now().millisecondsSinceEpoch + quest.id.hashCode;
      renderedNarrative = QuestNarrativeService.renderNarrative(
        quest: quest,
        partyMercs: mercs,
        staticData: staticData,
        userData: userData,
        factionStates: factionStates,
        templateEngine: templateEngine,
        sectorChanges: sectorChanges,
        seed: seed,
      );
    }

    // region 3 한정 일반 의뢰 신뢰도 점수 계산 (REQ-32, D-5)
    // 체인/거점사건 step, 외부 세력 태그, 외부 리전, 실패 시 0 유지
    const questTrustReward = {1: 2, 2: 3, 3: 5, 4: 0, 5: 0};
    int settlementTrustGain = 0;
    if (quest.region == 3 &&
        !quest.isChainQuest &&
        quest.factionTag == null &&
        (resultType == QuestResult.success ||
            resultType == QuestResult.greatSuccess)) {
      settlementTrustGain = questTrustReward[quest.difficulty] ?? 0;
    }

    return QuestCompletionResult(
      resultType: resultType,
      rewardGold: rewardGold,
      totalWage: totalWage,
      netReward: netReward,
      xpGain: xpGain,
      repGain: repGain,
      mercDamages: mercDamages,
      factionTag: quest.factionTag,
      factionRepGain: factionRepGain,
      eliteLoot: eliteLoot,
      renderedNarrative: renderedNarrative,
      settlementTrustGain: settlementTrustGain,
    );
  }
}
