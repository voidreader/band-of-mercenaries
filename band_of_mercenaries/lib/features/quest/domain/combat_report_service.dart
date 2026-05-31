import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:band_of_mercenaries/core/domain/template_context.dart';
import 'package:band_of_mercenaries/core/domain/template_engine.dart';
import 'package:band_of_mercenaries/core/models/combat_report_keyword.dart';
import 'package:band_of_mercenaries/core/models/combat_report_template.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_report_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_simulation_result.dart';
import 'package:band_of_mercenaries/features/quest/domain/emotional_reaction_config.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_narrative_service.dart';
import 'package:band_of_mercenaries/features/quest/domain/status_effect_event.dart';

/// 전투 보고서 중요도 레벨. 외부 노출 불필요.
enum ImportanceLevel { normal, high, veryHigh }

/// M8a 페이즈 4 #2: 전투 보고서 생성 서비스.
///
/// `combatReportEligible == true`인 의뢰 완료 직후 1회 호출되어
/// 요약 1줄 + 상세 N줄(중요도별 4~8)을 가중 랜덤 추첨 + TemplateEngine 렌더링으로 생성한다.
/// 정적 helper, ref 의존 없음. 실패 시 null 반환(fail-soft).
class CombatReportService {
  CombatReportService._();

  static CombatReport? generate({
    required ActiveQuest quest,
    required List<Mercenary> partyMercs,
    required QuestResult resultType,
    required StaticGameData staticData,
    required UserData userData,
    required List<FactionState> factionStates,
    required TemplateEngine templateEngine,
    RegionState? regionState,
    Map<String, String>? sectorChanges,
    int? seed,
    CombatSimulationResult? simulationResult,
  }) {
    // 1. seed 결정 + 단일 Random 사용 (재현성)
    final effectiveSeed =
        seed ?? DateTime.now().millisecondsSinceEpoch ^ quest.id.hashCode;
    final random = Random(effectiveSeed);

    // 2. result_type snake_case 키
    final resultKey = _resultTypeKey(resultType);

    // 3. 중요도 판정
    final importance = _resolveImportance(quest, staticData, factionStates);

    // 4. scope 시퀀스 (좁은 → 넓은)
    final scopeChain = _resolveScopeChain(quest, staticData);

    final templates = staticData.combatReportTemplates;

    // 5. 요약 1줄 선택
    final summary = _pickSummary(
      scopeChain: scopeChain,
      resultKey: resultKey,
      templates: templates,
      random: random,
      quest: quest,
    );
    if (summary == null && simulationResult == null) return null;

    // 6. 상세 N줄 선택
    final details = _pickDetails(
      scopeChain: scopeChain,
      resultKey: resultKey,
      importance: importance,
      templates: templates,
      random: random,
      quest: quest,
    );
    if (details.isEmpty && simulationResult == null) return null;

    // 7. 주인공 선택
    // simulationResult가 있으면 시뮬레이터가 결정한 protagonist 우선
    Mercenary? protagonist;
    if (simulationResult != null &&
        simulationResult.protagonistMercId != null) {
      protagonist = partyMercs
          .where((m) => m.id == simulationResult.protagonistMercId)
          .firstOrNull;
    }
    protagonist ??= QuestNarrativeService.pickProtagonist(
      partyMercs,
      quest.questTypeId,
    );

    // simulationResult가 있으면 protagonist null이어도 fallback 보고서 생성 (FR-9.2)
    if (protagonist == null && simulationResult == null) return null;

    // partyMercs가 비어 있으면 렌더링 불가 — abort
    if (protagonist == null && partyMercs.isEmpty) return null;

    // 8. 보조 선택
    final ally = protagonist != null
        ? (_pickAlly(partyMercs, protagonist, random) ?? protagonist)
        : null;

    // 9. featuredMercIds dedup
    final List<String> featuredMercIds;
    if (simulationResult != null &&
        simulationResult.featuredMercIds.isNotEmpty) {
      featuredMercIds = List<String>.from(simulationResult.featuredMercIds);
    } else if (protagonist != null) {
      featuredMercIds = <String>{
        protagonist.id,
        if (ally != null) ally.id,
      }.toList(growable: false);
    } else {
      featuredMercIds = const [];
    }

    // 10. enemyName 결정
    final enemyName = _resolveEnemyName(
      quest: quest,
      staticData: staticData,
      random: random,
    );

    // 11. 템플릿 렌더링
    // protagonist null이면 partyMercs.first를 context용으로 사용
    final contextMerc = protagonist ?? partyMercs.firstOrNull;
    if (contextMerc == null) return null;

    final region = staticData.regions
        .where((r) => r.region == quest.region)
        .firstOrNull;
    final convertedSectorChanges = sectorChanges?.map(
      (k, v) => MapEntry(int.tryParse(k) ?? -1, v),
    );
    final context = TemplateContext(
      user: userData,
      quest: quest,
      merc: contextMerc,
      region: region,
      factionStates: factionStates,
      sectorChanges: convertedSectorChanges,
      currentSectorIndex: userData.sector,
      allyName: ally?.name,
      enemyName: enemyName,
      eliteId: quest.eliteId,
      seed: effectiveSeed,
      evaluationScope: EvaluationScope.mercenary,
    );

    final renderedSummary = summary != null
        ? templateEngine.render(summary.template, context)
        : _fallbackSimulationSummary(quest, resultType, simulationResult);
    final renderedDetails = details.isNotEmpty
        ? details
              .map((t) => templateEngine.render(t.template, context))
              .toList(growable: false)
        : _fallbackSimulationDetails(simulationResult);

    // 12. toneTags 평탄화 + dedup
    final tagSet = <String>{};
    final tplsForTags = <CombatReportTemplate>[
      if (summary != null) summary,
      ...details,
    ];
    for (final tpl in tplsForTags) {
      final tags = tpl.parsedTags;
      for (final key in const ['tone', 'beat', 'scene', 'mood', 'faction']) {
        final value = tags[key];
        if (value is String && value.isNotEmpty) {
          tagSet.add(value);
        } else if (value is List) {
          for (final v in value) {
            if (v is String && v.isNotEmpty) tagSet.add(v);
          }
        }
      }
    }

    // M8b 페이즈 4 #3 — simulationResult.toneTags 합집합
    if (simulationResult != null) {
      tagSet.addAll(simulationResult.toneTags);
    }

    // 13. templateIds
    final templateIds = <String>[
      if (summary != null) summary.id,
      ...details.map((t) => t.id),
    ];

    // 14. 감정 장면 섹션 (M8.5 페이즈 4 #3 FR-17)
    // simulationResult.statusEffectHistory에서 emotional_ apply 이벤트를 추출하여
    // scope='emotional' 템플릿으로 보고서 하단에 최대 3줄 추가.
    // 빈 풀이면 fail-soft skip (renderedDetails 그대로 유지).
    final List<String> finalDetails;
    {
      final emotionalLines = _buildEmotionalScenes(
        simulationResult: simulationResult,
        templates: templates,
        resultKey: resultKey,
        quest: quest,
        context: context,
        templateEngine: templateEngine,
        random: random,
      );
      finalDetails = emotionalLines.isEmpty
          ? renderedDetails
          : [...renderedDetails, ...emotionalLines];
    }

    // 15. CombatReport 반환
    return CombatReport(
      summary: renderedSummary,
      details: finalDetails,
      seed: effectiveSeed,
      protagonistMercId: simulationResult?.protagonistMercId ?? protagonist?.id,
      featuredMercIds: featuredMercIds,
      toneTags: tagSet.toList(growable: false),
      createdAt: DateTime.now(),
      templateIds: templateIds,
      // M8b 페이즈 4 #3 — simulationResult가 있으면 구조 필드 최소 임베드
      schemaVersion: simulationResult != null ? 1 : null,
      combatantSnapshots: simulationResult?.combatantSnapshots,
      turns: simulationResult?.turns,
      exitCondition: simulationResult?.exitCondition,
      objectiveProgress: simulationResult?.objectiveProgress,
      enemySnapshots: simulationResult?.enemySnapshots,
      statusEffectHistory: simulationResult?.statusEffectHistory,
    );
  }

  // ===========================================================================
  // private helpers
  // ===========================================================================

  /// M8.5 페이즈 4 #3 FR-17 — 감정 장면 섹션 생성.
  ///
  /// 1. statusEffectHistory에서 effectId.startsWith('emotional_') && eventType=='apply'
  ///    인 이벤트를 추출.
  /// 2. 추출된 effectId를 우선순위(투지 > 분노 > 슬픔 > 절망) 순으로 정렬하고
  ///    중복 effectId 제거 후 상위 3개까지 사용.
  /// 3. 각 effectId에 매칭되는 scope='emotional' 템플릿 풀에서 가중 랜덤 선택.
  /// 4. TemplateEngine으로 렌더링. 최대 3줄 반환.
  /// 5. scope='emotional' 템플릿이 없으면 빈 리스트 반환(fail-soft skip).
  static List<String> _buildEmotionalScenes({
    required CombatSimulationResult? simulationResult,
    required List<CombatReportTemplate> templates,
    required String resultKey,
    required ActiveQuest quest,
    required TemplateContext context,
    required TemplateEngine templateEngine,
    required Random random,
  }) {
    if (simulationResult == null) return const [];

    // 1. emotional apply 이벤트 추출 (중복 effectId 제거)
    final emotionalEffectIds = _extractEmotionalEffectIds(
      simulationResult.statusEffectHistory,
    );
    if (emotionalEffectIds.isEmpty) return const [];

    // 2. scope='emotional' 템플릿 풀 존재 확인 (fail-soft skip)
    final emotionalPool = templates
        .where(
          (t) =>
              t.scope == 'emotional' &&
              (t.resultType == null || t.resultType == resultKey) &&
              (t.questType == null || t.questType == quest.questTypeId) &&
              (t.factionId == null || t.factionId == quest.factionTag),
        )
        .toList(growable: false);
    if (emotionalPool.isEmpty) return const [];

    // 3. 우선순위 정렬된 effectId별 템플릿 선택 + 렌더링 (최대 3줄)
    final result = <String>[];
    final usedTemplateIds = <String>{};

    for (final effectId in emotionalEffectIds) {
      if (result.length >= 3) break;

      // TODO(Q-1): combat_report_templates emotion 매칭 컬럼 확정 후 정합 — 현재
      // tags_json.emotion 또는 tags_json.effect_id 키로 effectId를 매칭하는 잠정 로직.
      // DB 스키마에 전용 컬럼(예: emotion_type, source_effect_id) 확정 시 이 필터를 교체할 것.
      final candidates = emotionalPool
          .where((t) {
            if (usedTemplateIds.contains(t.id)) return false;
            final tags = t.parsedTags;
            // tags_json.emotion 키 매칭 시도 (예: {"emotion": "determination"})
            final emotionTag = tags['emotion'];
            if (emotionTag is String && emotionTag.isNotEmpty) {
              return effectId == 'emotional_$emotionTag';
            }
            // tags_json.effect_id 키 매칭 시도 (예: {"effect_id": "emotional_rage"})
            final effectIdTag = tags['effect_id'];
            if (effectIdTag is String && effectIdTag.isNotEmpty) {
              return effectId == effectIdTag;
            }
            // 매칭 키 미확정: effectId 전용 태그가 없는 템플릿은 이 effectId에서 사용하지 않음.
            // 전체 emotional 풀을 공유 사용하려면 위 2개 키 중 하나로 확정 후 수정.
            return false;
          })
          .toList(growable: false);

      // 매칭 템플릿이 없으면 전체 emotional 풀에서 fallback 선택
      if (candidates.isEmpty) {
        debugPrint(
          '[BOM][CombatReport] emotional 매칭 키 미확정 — 전풀 fallback',
        );
      }
      final fallbackCandidates = candidates.isNotEmpty
          ? candidates
          : emotionalPool
                .where((t) => !usedTemplateIds.contains(t.id))
                .toList(growable: false);

      final picked = _weightedPick(fallbackCandidates, random);
      if (picked == null) continue;

      usedTemplateIds.add(picked.id);
      result.add(templateEngine.render(picked.template, context));
    }

    return result;
  }

  /// statusEffectHistory에서 emotional_ apply 이벤트를 추출하고
  /// 우선순위(투지 > 분노 > 슬픔 > 절망) 순으로 중복 제거 후 반환.
  static List<String> _extractEmotionalEffectIds(
    List<StatusEffectEvent> history,
  ) {
    // apply 이벤트 중 emotional_ prefix를 가진 것만 추출 (중복 effectId 제거)
    final seen = <String>{};
    final extracted = <String>[];
    for (final event in history) {
      if (event.eventType != 'apply') continue;
      if (!event.effectId.startsWith('emotional_')) continue;
      if (seen.contains(event.effectId)) continue;
      seen.add(event.effectId);
      extracted.add(event.effectId);
    }

    // EmotionalReactionConfig.priority 순서(determination/rage/sorrow/despair)로 정렬
    const priorityOrder = EmotionalReactionConfig.priority;
    extracted.sort((a, b) {
      // "emotional_" prefix 제거 후 priority 리스트에서 인덱스 비교
      final aKind = a.replaceFirst('emotional_', '');
      final bKind = b.replaceFirst('emotional_', '');
      final aIdx = priorityOrder.indexOf(aKind);
      final bIdx = priorityOrder.indexOf(bKind);
      // priority 리스트에 없는 effectId는 최후순위로
      final aRank = aIdx < 0 ? priorityOrder.length : aIdx;
      final bRank = bIdx < 0 ? priorityOrder.length : bIdx;
      final cmp = aRank.compareTo(bRank);
      return cmp != 0 ? cmp : a.compareTo(b);
    });

    return extracted;
  }

  static String _fallbackSimulationSummary(
    ActiveQuest quest,
    QuestResult resultType,
    CombatSimulationResult? simulationResult,
  ) {
    final resultLabel = switch (resultType) {
      QuestResult.greatSuccess => '대성공',
      QuestResult.success => '성공',
      QuestResult.failure => '실패',
      QuestResult.criticalFailure => '대실패',
    };
    final exitLabel = simulationResult?.exitCondition.name;
    final suffix = exitLabel == null ? '' : ' ($exitLabel)';
    return '${quest.questName} 전투 기록: $resultLabel$suffix';
  }

  static List<String> _fallbackSimulationDetails(
    CombatSimulationResult? simulationResult,
  ) {
    if (simulationResult == null) {
      return const ['전투 상세 기록이 남지 않았다.'];
    }
    final injured = simulationResult.injuredMercIds.length;
    final deceased = simulationResult.deceasedMercIds.length;
    final rounds = simulationResult.turns.length;
    return [
      '전투는 $rounds개 턴 기록으로 보존되었다.',
      '부상 $injured명, 사망 $deceased명으로 정리되었다.',
    ];
  }

  /// QuestResult enum → 템플릿 매칭용 snake_case 키 (Q-9).
  static String _resultTypeKey(QuestResult result) {
    switch (result) {
      case QuestResult.greatSuccess:
        return 'great_success';
      case QuestResult.success:
        return 'success';
      case QuestResult.failure:
        return 'failure';
      case QuestResult.criticalFailure:
        return 'critical_failure';
    }
  }

  /// 중요도 판정 (FR-7 의사코드).
  static ImportanceLevel _resolveImportance(
    ActiveQuest quest,
    StaticGameData staticData,
    List<FactionState> factionStates,
  ) {
    // 1. 엘리트
    if (quest.eliteId != null) {
      final elite = staticData.eliteMonsters
          .where((e) => e.id == quest.eliteId)
          .firstOrNull;
      if (elite?.isUnique == true) return ImportanceLevel.veryHigh;
      return ImportanceLevel.high;
    }
    // 2. 연계 퀘스트
    if (quest.isChainQuest && quest.chainId != null) {
      final isFinal = _isChainFinalStep(quest, staticData);
      if (isFinal) return ImportanceLevel.veryHigh;
      return ImportanceLevel.high;
    }
    // 3. 신뢰 세력 지명
    final isFactionNamed =
        (quest.specialFlags ?? const {})['faction_named'] == true;
    if (isFactionNamed) {
      final isAdvancedTrack = quest.isAdvancedTrack == true;
      final factionReputation = quest.factionTag == null
          ? 0
          : factionStates
                    .where((s) => s.factionId == quest.factionTag)
                    .firstOrNull
                    ?.currentReputation ??
                0;
      final reputationOk = factionReputation >= 31;
      if (isAdvancedTrack || reputationOk) return ImportanceLevel.high;
      return ImportanceLevel.normal;
    }
    // 4. 기존 지명 의뢰
    final pool = staticData.questPools
        .where((p) => p.id == quest.questPoolId)
        .firstOrNull;
    if (pool?.isNamed == true) return ImportanceLevel.high;
    // 5. fallback
    return ImportanceLevel.normal;
  }

  /// chain 최종 단계 판정.
  ///
  /// ChainQuestData는 행 단위(step/totalSteps 필드)이므로 동일 chainId의 행 중
  /// totalSteps 최댓값과 비교한다. quest.chainStep은 0-based 이므로 +1 후 비교.
  static bool _isChainFinalStep(ActiveQuest quest, StaticGameData staticData) {
    final chainSteps = staticData.chainQuests
        .where((c) => c.chainId == quest.chainId)
        .toList(growable: false);
    if (chainSteps.isEmpty) return false;
    final maxStep = chainSteps.fold<int>(
      0,
      (max, c) => c.totalSteps > max ? c.totalSteps : max,
    );
    return (quest.chainStep ?? -1) + 1 == maxStep;
  }

  /// scope 시퀀스 (좁은 → 넓은). 마지막 fallback은 항상 'scene' (detail 보충풀).
  static List<String> _resolveScopeChain(
    ActiveQuest quest,
    StaticGameData staticData,
  ) {
    final result = <String>[];

    // chain_final / chain_step / settlement_event
    if (quest.isChainQuest) {
      final isFinal = _isChainFinalStep(quest, staticData);
      if (quest.isSettlementStep) {
        result.addAll(['settlement_event', 'chain_step', 'quest_type']);
      } else if (isFinal) {
        result.addAll(['chain_final', 'chain_step', 'quest_type']);
      } else {
        result.addAll(['chain_step', 'quest_type']);
      }
    } else if (quest.isElite) {
      final elite = staticData.eliteMonsters
          .where((e) => e.id == quest.eliteId)
          .firstOrNull;
      if (elite?.isUnique == true) {
        result.addAll(['unique_elite', 'elite', 'quest_type']);
      } else {
        result.addAll(['elite', 'quest_type']);
      }
    } else if ((quest.specialFlags ?? const {})['faction_named'] == true) {
      result.addAll(['faction_named', 'quest_type']);
    } else {
      result.add('quest_type');
    }

    // detail 보충풀
    result.add('scene');
    return result;
  }

  /// importance별 상세 줄 수 균등 분포 추첨 (Q-8) + 풀 크기 클램프.
  static int _resolveDetailLineCount(
    ImportanceLevel importance,
    Random random,
    int poolSize,
  ) {
    int min;
    int max;
    switch (importance) {
      case ImportanceLevel.normal:
        min = 4;
        max = 4;
        break;
      case ImportanceLevel.high:
        min = 5;
        max = 7;
        break;
      case ImportanceLevel.veryHigh:
        min = 6;
        max = 8;
        break;
    }
    final target = random.nextInt(max - min + 1) + min;
    if (poolSize <= 0) return 0;
    return target > poolSize ? poolSize : target;
  }

  /// 요약 1줄 가중 랜덤 선택. 좁은 scope부터 순회.
  static CombatReportTemplate? _pickSummary({
    required List<String> scopeChain,
    required String resultKey,
    required List<CombatReportTemplate> templates,
    required Random random,
    required ActiveQuest quest,
  }) {
    for (final scope in scopeChain) {
      // scope == 'scene'은 detail 보충풀로만 사용
      if (scope == 'scene') continue;
      final candidates = templates
          .where(
            (t) =>
                t.lineType == 'summary' &&
                t.scope == scope &&
                (t.resultType == null || t.resultType == resultKey) &&
                (t.questType == null || t.questType == quest.questTypeId) &&
                (t.factionId == null || t.factionId == quest.factionTag),
          )
          .toList(growable: false);
      final picked = _weightedPick(candidates, random);
      if (picked != null) return picked;
    }
    return null;
  }

  /// 상세 N줄 비복원 가중 샘플. scope 순회 + scene 보충풀.
  static List<CombatReportTemplate> _pickDetails({
    required List<String> scopeChain,
    required String resultKey,
    required ImportanceLevel importance,
    required List<CombatReportTemplate> templates,
    required Random random,
    required ActiveQuest quest,
  }) {
    final picked = <CombatReportTemplate>[];
    final pickedIds = <String>{};

    // 전체 매칭 풀 크기 추산 (모든 scope 합산, 클램프용)
    int totalPoolSize = 0;
    final perScopeCandidates = <List<CombatReportTemplate>>[];
    for (final scope in scopeChain) {
      final candidates = templates
          .where(
            (t) =>
                t.lineType == 'detail' &&
                t.scope == scope &&
                (t.resultType == null || t.resultType == resultKey) &&
                (t.questType == null || t.questType == quest.questTypeId) &&
                (t.factionId == null || t.factionId == quest.factionTag),
          )
          .toList(growable: false);
      perScopeCandidates.add(candidates);
      totalPoolSize += candidates.length;
    }

    final targetCount = _resolveDetailLineCount(
      importance,
      random,
      totalPoolSize,
    );
    if (targetCount <= 0) return const [];

    for (final candidates in perScopeCandidates) {
      if (picked.length >= targetCount) break;
      // 비복원 샘플
      final remaining = candidates
          .where((t) => !pickedIds.contains(t.id))
          .toList();
      while (picked.length < targetCount && remaining.isNotEmpty) {
        final p = _weightedPick(remaining, random);
        if (p == null) break;
        picked.add(p);
        pickedIds.add(p.id);
        remaining.removeWhere((t) => t.id == p.id);
      }
    }

    return picked;
  }

  /// 보조 용병 선택 (protagonist 제외 무작위 1명).
  static Mercenary? _pickAlly(
    List<Mercenary> partyMercs,
    Mercenary protagonist,
    Random random,
  ) {
    final others = partyMercs
        .where((m) => m.id != protagonist.id)
        .toList(growable: false);
    if (others.isEmpty) return null;
    return others[random.nextInt(others.length)];
  }

  /// enemyName 4단계 우선순위 결정 (FR-4 단계 10).
  static String? _resolveEnemyName({
    required ActiveQuest quest,
    required StaticGameData staticData,
    required Random random,
  }) {
    // (a) 엘리트
    if (quest.eliteId != null) {
      final eliteName = staticData.eliteMonsters
          .where((e) => e.id == quest.eliteId)
          .map((e) => e.name)
          .firstOrNull;
      if (eliteName != null) return eliteName;
    }
    // (b) quest_pool.enemyName
    final poolEnemyName = staticData.questPools
        .where((p) => p.id == quest.questPoolId)
        .map((p) => p.enemyName)
        .firstOrNull;
    if (poolEnemyName != null && poolEnemyName.isNotEmpty) {
      return poolEnemyName;
    }
    // (c) combat_report_keywords category == 'enemy' 가중 랜덤
    final enemyKeywords = staticData.combatReportKeywords
        .where((k) {
          if (k.category != 'enemy') return false;
          final tags = k.parsedTags;
          final regionTag = tags['region'];
          final questTypeTag = tags['quest_type'];
          final regionMatch = _matchesTagValue(
            regionTag,
            quest.region.toString(),
          );
          final questTypeMatch = _matchesTagValue(
            questTypeTag,
            quest.questTypeId,
          );
          return regionMatch || questTypeMatch;
        })
        .toList(growable: false);
    final picked = _weightedPickKeyword(enemyKeywords, random);
    if (picked != null) return picked.displayText;
    // (d) null fallback (resolver에서 '적' 처리)
    return null;
  }

  /// 태그 값 매칭 — `String`/`num`/`List<String>` 모두 허용.
  static bool _matchesTagValue(Object? tagValue, String target) {
    if (tagValue == null) return false;
    if (tagValue is String) return tagValue == target;
    if (tagValue is num) return tagValue.toString() == target;
    if (tagValue is List) {
      for (final v in tagValue) {
        if (v is String && v == target) return true;
        if (v is num && v.toString() == target) return true;
      }
    }
    return false;
  }

  /// 가중 랜덤 1개 선택 (템플릿). 빈 리스트면 null.
  static CombatReportTemplate? _weightedPick(
    List<CombatReportTemplate> candidates,
    Random random,
  ) {
    if (candidates.isEmpty) return null;
    final totalWeight = candidates.fold<double>(
      0.0,
      (sum, c) => sum + c.weight.toDouble(),
    );
    if (totalWeight <= 0) return candidates.first;
    double roll = random.nextDouble() * totalWeight;
    for (final c in candidates) {
      roll -= c.weight.toDouble();
      if (roll <= 0) return c;
    }
    return candidates.last;
  }

  /// 가중 랜덤 1개 선택 (키워드). 빈 리스트면 null.
  static CombatReportKeyword? _weightedPickKeyword(
    List<CombatReportKeyword> candidates,
    Random random,
  ) {
    if (candidates.isEmpty) return null;
    final totalWeight = candidates.fold<double>(
      0.0,
      (sum, c) => sum + c.weight.toDouble(),
    );
    if (totalWeight <= 0) return candidates.first;
    double roll = random.nextDouble() * totalWeight;
    for (final c in candidates) {
      roll -= c.weight.toDouble();
      if (roll <= 0) return c;
    }
    return candidates.last;
  }
}
