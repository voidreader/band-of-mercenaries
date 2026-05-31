import 'package:flutter/widgets.dart';

import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/models/dialog_request.dart';
import 'package:band_of_mercenaries/core/models/title_data.dart';
import 'package:band_of_mercenaries/core/providers/dialog_queue_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/achievement/domain/mercenary_snapshot_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/battle_memory_entry.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

/// 위업 발급 시 칭호 hook 평가에 필요한 보조 컨텍스트.
///
/// `hook_target` 5종 분기(`require_protagonist` / `last_dispatch_protagonist` /
/// `most_dispatched_to_region_3` / `top_contributor_24h` / `first_only`) 정보를
/// 한 번에 구성하여 [TitleService.evaluateAchievementHook]에 전달한다.
class AchievementHookContext {
  final BandAchievement achievement;
  final MercenarySnapshot? protagonist;
  final List<String> aliveDispatchableMercIds;

  /// mercId → region별 dispatch 누적 (예: region 3 한정 또는 통합).
  final Map<String, int> regionDispatchCounts;

  final String? lastDispatchTopMercId;
  final String? top24hContributorMercId;

  const AchievementHookContext({
    required this.achievement,
    this.protagonist,
    this.aliveDispatchableMercIds = const [],
    this.regionDispatchCounts = const {},
    this.lastDispatchTopMercId,
    this.top24hContributorMercId,
  });
}

/// 칭호 발급 진입점.
///
/// 3종 hook(`achievement` / `action_stat` / `status`)을 받아 정합 조건을 만족하는
/// 칭호를 mercenary에 발급한다. 모든 사이드이펙트(타이틀 영속화 / ActivityLog 미러 /
/// dialog enqueue)는 fail-soft trailing 패턴으로 처리한다.
///
/// 콜백 DI 패턴(`AchievementService`와 동일)으로 직접 Provider 의존성 없이 외부 주입.
class TitleService {
  TitleService({
    required this.titles,
    required this.getMercenary,
    required this.updateMercenaryTitles,
    required this.addLog,
    required this.enqueueDialog,
    required this.hasAchievement,
    required this.bandAchievements,
    required this.staticData,
    required this.buildTitleDialog,
  });

  final List<TitleData> titles;
  final Mercenary? Function(String mercId) getMercenary;
  final Future<void> Function(String mercId, List<String> titleIds)
      updateMercenaryTitles;
  final void Function(String message, ActivityLogType type) addLog;
  final void Function(DialogRequest req) enqueueDialog;
  final bool Function(String templateId) hasAchievement;
  final List<BandAchievement> Function() bandAchievements;
  final StaticGameData staticData;

  /// 다이얼로그 위젯 빌더 — Provider 바인딩 시점에 주입.
  /// TitleUnlockedDialog가 TASK-14에서 생성되므로 서비스 자체는 위젯 타입에 의존하지 않는다.
  final Widget Function({
    required TitleData title,
    required MercenarySnapshot mercSnapshot,
    required String reasonText,
    required VoidCallback onDismiss,
  }) buildTitleDialog;

  /// 위업 발급 hook 평가. (FR-10)
  ///
  /// `achievement.type == achievement` 인 경우만 평가. `hook_target` 5종 분기로
  /// targetMercId를 결정한 뒤 [_grantTitle]을 호출한다. 발급된 [TitleData] 목록을
  /// 반환하여 호출측(AchievementService)이 본체 다이얼로그 payload에 통합할 수 있게 한다.
  ///
  /// fail-soft: hook_target 분기에서 정보 부족 시 silent skip.
  Future<List<TitleData>> evaluateAchievementHook(
    BandAchievement achievement,
    AchievementHookContext context,
  ) async {
    if (achievement.type != BandAchievementType.achievement) {
      return const [];
    }

    final grantedNow = <TitleData>[];
    for (final title in titles.where((t) => t.hookType == 'achievement')) {
      final cond = title.hookCondition;

      // 1) templateId 정확 매칭 또는 prefix 매칭
      final tplId = cond['achievement_template_id'] as String?;
      final prefix = cond['achievement_template_id_prefix'] as String?;
      bool tplMatch = false;
      if (tplId != null) tplMatch = achievement.templateId == tplId;
      if (!tplMatch && prefix != null) {
        tplMatch = achievement.templateId.startsWith(prefix);
      }
      if (!tplMatch) continue;

      // 2) first_only — prefix 매칭에서 동일 prefix가 이전에 발급된 적 있으면 차단
      if (cond['first_only'] == true && prefix != null) {
        final earlierGrants = bandAchievements()
            .where((a) =>
                a.type == BandAchievementType.achievement &&
                a.templateId.startsWith(prefix) &&
                a.id != achievement.id)
            .toList();
        if (earlierGrants.isNotEmpty) continue;
      }

      // 3) hook_target 분기로 targetMercId 결정
      final hookTarget =
          cond['hook_target'] as String? ?? 'require_protagonist';
      String? targetMercId;
      switch (hookTarget) {
        case 'require_protagonist':
          targetMercId = context.protagonist?.id;
          break;
        case 'last_dispatch_protagonist':
          targetMercId = context.lastDispatchTopMercId;
          break;
        case 'most_dispatched_to_region_3':
          if (context.regionDispatchCounts.isNotEmpty) {
            final sorted = context.regionDispatchCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            targetMercId = sorted.first.key;
          }
          break;
        case 'top_contributor_24h':
          targetMercId = context.top24hContributorMercId;
          break;
        case 'first_only':
          targetMercId = context.protagonist?.id;
          break;
        default:
          targetMercId = context.protagonist?.id;
      }
      if (targetMercId == null) continue;

      // 4) mercenary 유효성 검사 + 중복 차단
      final merc = getMercenary(targetMercId);
      if (merc == null || merc.status == MercenaryStatus.dead) continue;
      if (merc.titleIds.contains(title.id)) continue;

      await _grantTitle(merc, title);
      grantedNow.add(title);
    }
    return grantedNow;
  }

  /// 행동 지표 임계치 hook 평가. (FR-11)
  ///
  /// `mercenary.stats[statKey]`를 `threshold`와 비교하여 매칭 시 칭호를 발급하고
  /// TitleUnlockedDialog를 high priority로 enqueue한다.
  Future<void> evaluateActionStatHook(String mercId) async {
    final merc = getMercenary(mercId);
    if (merc == null || merc.status == MercenaryStatus.dead) return;

    for (final title in titles.where((t) => t.hookType == 'action_stat')) {
      if (merc.titleIds.contains(title.id)) continue;

      final cond = title.hookCondition;
      final statKey = cond['stat_key'] as String?;
      final threshold = cond['threshold'];
      final operator = cond['operator'] as String? ?? '>=';
      if (statKey == null || threshold == null) continue;

      final value = merc.stats[statKey] ?? 0;
      final thresholdInt =
          threshold is int ? threshold : (threshold as num).toInt();
      bool matches;
      switch (operator) {
        case '>=':
          matches = value >= thresholdInt;
          break;
        case '>':
          matches = value > thresholdInt;
          break;
        case '==':
          matches = value == thresholdInt;
          break;
        default:
          matches = false;
      }
      if (!matches) continue;

      await _grantTitle(merc, title);

      // dialog enqueue
      final snapshot = _makeSnapshot(merc);
      final reasonText =
          _buildActionStatReasonText(title, statKey, thresholdInt);
      enqueueDialog(_makeTitleUnlockedRequest(title, snapshot, reasonText));
    }
  }

  /// mercenary 상태 변화 hook 평가. (FR-12)
  ///
  /// `trigger_status == newStatus.name` 매칭 + 선택적 chain context 매칭을
  /// 모두 만족할 때 칭호를 발급한다.
  Future<void> evaluateStatusHook(
    String mercId,
    MercenaryStatus newStatus,
    Map<String, dynamic> context,
  ) async {
    final merc = getMercenary(mercId);
    if (merc == null || merc.status == MercenaryStatus.dead) return;

    for (final title in titles.where((t) => t.hookType == 'status')) {
      if (merc.titleIds.contains(title.id)) continue;

      final cond = title.hookCondition;
      final triggerStatus = cond['trigger_status'] as String?;
      if (triggerStatus == null) continue;
      if (triggerStatus != newStatus.name) continue;

      // 선택적 context 매칭 (chain_id + require_chain_completion)
      final ctxCond = cond['context'] as Map<String, dynamic>?;
      if (ctxCond != null) {
        final chainId = ctxCond['chain_id'] as String?;
        final requireCompletion = ctxCond['require_chain_completion'] == true;
        if (chainId != null) {
          final chainProgressMap = context['chainProgressMap'] as Map?;
          if (chainProgressMap == null) continue;
          final progress = chainProgressMap[chainId];
          if (progress == null) continue;
          if (requireCompletion) {
            // ChainQuestProgress.status는 ChainQuestStatus enum.
            // 동적 접근으로 enum.name 또는 toString() 결과에서 'completed' 포함 여부 확인.
            final dynamic progressStatus = (progress as dynamic).status;
            final statusStr = progressStatus?.toString() ?? '';
            if (!statusStr.contains('completed')) continue;
          }
        }
      }

      await _grantTitle(merc, title);

      // dialog enqueue
      final snapshot = _makeSnapshot(merc);
      final reasonText = title.narrativeHint ?? '${title.name} 조건 충족';
      enqueueDialog(_makeTitleUnlockedRequest(title, snapshot, reasonText));
    }
  }

  /// 세력 평판 임계값 도달 시 칭호 발급 hook.
  ///
  /// FR-E2: hook_type == 'faction_reputation' title들 중 hook_condition.faction_id가
  /// 일치하고 oldRep < threshold && newRep >= threshold인 경우, hook_target에 명시된
  /// mercenary(M8a는 last_dispatch_protagonist)에게 칭호를 발급한다.
  ///
  /// targetMercId가 null이거나 사망/이미 보유 시 silent skip.
  /// _grantTitle 호출 후 TitleUnlockedDialog enqueue (evaluateActionStatHook 패턴).
  Future<void> evaluateFactionReputationHook({
    required String factionId,
    required int oldRep,
    required int newRep,
    required String? targetMercId,
  }) async {
    if (targetMercId == null) return;
    for (final title in titles.where((t) => t.hookType == 'faction_reputation')) {
      final cond = title.hookCondition;
      if (cond['faction_id'] != factionId) continue;
      final threshold = (cond['threshold'] as num?)?.toInt();
      if (threshold == null) continue;
      if (!(oldRep < threshold && newRep >= threshold)) continue;
      final merc = getMercenary(targetMercId);
      if (merc == null) continue;
      if (merc.status == MercenaryStatus.dead) continue;
      if (merc.titleIds.contains(title.id)) continue;
      await _grantTitle(merc, title);
      final snapshot = _makeSnapshot(merc);
      final reasonText = title.narrativeHint ?? '${title.name} 조건 충족';
      enqueueDialog(_makeTitleUnlockedRequest(title, snapshot, reasonText));
    }
  }

  /// 칭호 영속화 + ActivityLog 미러. (FR-13)
  ///
  /// dialog enqueue는 호출측(evaluateActionStatHook / evaluateStatusHook)이 담당.
  /// evaluateAchievementHook는 AchievementService payload에 grantedTitles 통합.
  Future<void> _grantTitle(Mercenary mercenary, TitleData title) async {
    final newIds = [...mercenary.titleIds, title.id];
    await updateMercenaryTitles(mercenary.id, newIds);
    addLog(
      '┝ ${mercenary.name}이(가) "${title.name}" 칭호를 얻었다',
      ActivityLogType.titleUnlocked,
    );
    // FR-15: battleMemory trailing — 칭호 부여 기록.
    try {
      final entry = BattleMemoryEntry(
        mercId: mercenary.id,
        entryType: 'title_granted',
        sourceEventId: 'title:${title.id}',
        timestamp: DateTime.now(),
        templateKey: null,
        templateData: const {},
      );
      mercenary.addBattleMemory(entry);
      // battleMemory는 UI 비노출 영속 데이터이므로 state 재로딩 불필요.
      // 다음 mercenaryListProvider _load 시 자연 반영.
      await mercenary.save();
    } on Exception catch (e) {
      debugPrint('[BOM][Title] battleMemory trailing 실패 (${title.id}): $e');
    }
  }

  /// action_stat hook 발급 시 노출할 한국어 자연 문구.
  String _buildActionStatReasonText(
    TitleData title,
    String statKey,
    int threshold,
  ) {
    const labels = {
      'raid_count': '도적 소탕',
      'total_dispatch_count': '누적 파견',
      'explore_count': '정찰',
      'escort_count': '호위 의뢰',
    };
    final label = labels[statKey] ?? statKey;
    return '$threshold회의 $label 활동';
  }

  /// dialog enqueue용 [DialogRequest] 생성 헬퍼.
  ///
  /// [DialogTypeRegistry.titleUnlocked] 상수로 dialogType을 참조한다.
  DialogRequest _makeTitleUnlockedRequest(
    TitleData title,
    MercenarySnapshot snapshot,
    String reasonText,
  ) {
    return DialogRequest(
      id: 'title_unlocked:${title.id}:${snapshot.id}:'
          '${DateTime.now().millisecondsSinceEpoch}',
      priority: DialogPriority.high,
      dialogType: DialogTypeRegistry.titleUnlocked,
      payload: {
        'titleId': title.id,
        'titleName': title.name,
        'mercSnapshot': {
          'id': snapshot.id,
          'name': snapshot.name,
          'jobId': snapshot.jobId,
          'jobName': snapshot.jobName,
          'tier': snapshot.tier,
          'titleIds': snapshot.titleIds,
        },
        'reasonText': reasonText,
      },
      builder: (context, onDismiss) => buildTitleDialog(
        title: title,
        mercSnapshot: snapshot,
        reasonText: reasonText,
        onDismiss: onDismiss,
      ),
    );
  }

  /// Mercenary → MercenarySnapshot 변환 헬퍼.
  /// job 조회 실패 시 staticData.jobs.first로 fallback.
  MercenarySnapshot _makeSnapshot(Mercenary merc) {
    final job = staticData.jobs.firstWhere(
      (j) => j.id == merc.jobId,
      orElse: () => staticData.jobs.first,
    );
    return MercenarySnapshot.fromMercenary(
      merc,
      jobName: job.name,
      tier: job.tier,
    );
  }
}
