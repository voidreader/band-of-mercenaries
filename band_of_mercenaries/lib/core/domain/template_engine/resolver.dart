part of '../template_engine.dart';

/// 변수 [namespace].[field]를 [ctx]에서 해결하여 String 또는 null 반환.
String? _resolveVariable(String namespace, String field, TemplateContext ctx) {
  switch (namespace) {
    case 'merc':
      final merc = ctx.merc;
      if (merc == null) return null;
      return _resolveMercField(field, merc);

    case 'quest':
      final quest = ctx.quest;
      if (quest == null) return null;
      return _resolveQuestField(field, quest, ctx: ctx);

    case 'region':
      return _resolveRegionField(field, ctx.region, ctx);

    case 'world':
      return _resolveWorldField(field, ctx);

    default:
      return null;
  }
}

String? _resolveMercField(String field, Mercenary merc) {
  switch (field) {
    case 'name':
      return merc.name;
    case 'job':
      // jobs 테이블 조회는 외부 책임 — jobId를 그대로 반환
      return merc.jobId;
    case 'tier':
      // Mercenary에 tier 직접 필드 없음 — jobs 테이블 조회는 외부 책임
      return null;
    case 'level':
      return merc.level.toString();
    case 'str':
      return merc.effectiveStr.toString();
    case 'int':
      return merc.effectiveIntelligence.toString();
    case 'vit':
      return merc.effectiveVit.toString();
    case 'agi':
      return merc.effectiveAgi.toString();
    case 'state':
      return merc.status.name;
    default:
      return null;
  }
}

String? _resolveQuestField(String field, ActiveQuest quest, {TemplateContext? ctx}) {
  switch (field) {
    case 'name':
      return quest.questName;
    case 'type':
      return quest.questTypeId;
    case 'type_ko':
      // quest_types.name FK 조회 필요 — 호출부에서 fallback 사용 권장
      return null;
    case 'result':
      return quest.result?.name;
    case 'difficulty':
      return quest.difficulty.toString();
    case 'reward_gold':
      return quest.rewardGold?.toString();
    case 'net_profit':
      final reward = quest.rewardGold;
      final wage = quest.totalWage;
      final cost = quest.dispatchCost;
      if (reward == null || wage == null || cost == null) return null;
      return (reward - wage - cost).toString();
    case 'enemy':
      return ctx?.enemyName ?? '적';
    case 'is_elite':
      return quest.isElite.toString();
    case 'elite_name':
      // eliteId FK 조회는 외부 책임 — 이름 해결은 호출부가 fallback으로 처리
      return null;
    default:
      return null;
  }
}

String? _resolveRegionField(String field, Region? region, TemplateContext ctx) {
  switch (field) {
    case 'name':
      return region?.regionName;
    case 'tier':
      return region?.regionTier.toString();
    case 'tier_ko':
      // 한국어 티어명 변환은 외부 책임 — fallback 사용 권장
      return null;
    case 'sector':
      return ctx.currentSectorIndex?.toString();
    case 'knowledge':
      // Region 모델에 knowledge 필드 없음 — RegionState 별도 조회 필요
      return null;
    case 'sector_type':
      final idx = ctx.currentSectorIndex;
      if (idx == null) return 'standard';
      return ctx.sectorChanges?[idx] ?? 'standard';
    default:
      return null;
  }
}

String? _resolveWorldField(String field, TemplateContext ctx) {
  switch (field) {
    case 'rank':
      // ranks 테이블 별도 조회 필요 — 호출부 책임
      return null;
    case 'rank_ko':
      return null;
    case 'gold':
      return ctx.user.gold.toString();
    case 'joined_factions':
      return ctx.factionStates.where((f) => f.isJoined).length.toString();
    default:
      return null;
  }
}
