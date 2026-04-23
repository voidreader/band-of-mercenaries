import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_codex_providers.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_data.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_join_service.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_formatter.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';

class FactionDetailScreen extends ConsumerWidget {
  final String factionId;
  final VoidCallback onBack;

  const FactionDetailScreen({
    super.key,
    required this.factionId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 가입/탈퇴 후 갱신 트리거
    ref.watch(factionRefreshProvider);

    final factions = ref.watch(factionListProvider);
    final faction = factions.where((f) => f.id == factionId).firstOrNull;

    final repo = ref.read(factionStateRepositoryProvider);
    final state = repo.getState(factionId);

    final clueLevel = _resolvedClueLevel(faction, state);
    final displayName = clueLevel >= 1 ? (faction?.name ?? '???') : '???';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(displayName: displayName, onBack: onBack),
          Expanded(
            child: faction == null
                ? const Center(
                    child: Text(
                      '세력 정보를 찾을 수 없습니다',
                      style: TextStyle(color: AppTheme.textHint),
                    ),
                  )
                : _FactionBody(
                    faction: faction,
                    state: state,
                    clueLevel: clueLevel,
                    onJoin: () => _handleJoin(context, ref, faction, repo),
                    onLeave: () => _handleLeave(ref, faction, repo),
                  ),
          ),
        ],
      ),
    );
  }

  int _resolvedClueLevel(FactionData? faction, FactionState? state) {
    if (faction == null) return 0;
    if (faction.visibilityType == 'public') {
      return (state?.maxClueLevel ?? 0).clamp(1, 3);
    }
    return state?.maxClueLevel ?? 0;
  }

  Future<void> _handleJoin(
    BuildContext context,
    WidgetRef ref,
    FactionData faction,
    FactionStateRepository repo,
  ) async {
    // 이해충돌 세력 탈퇴 경고 다이얼로그
    if (faction.conflictFactionIds.isNotEmpty) {
      final joinedFactionIds = repo.getJoinedFactionIds();
      final conflictingJoined = faction.conflictFactionIds
          .where((id) => joinedFactionIds.contains(id))
          .toList();

      if (conflictingJoined.isNotEmpty) {
        final staticData = ref.read(staticDataProvider).value;
        final conflictNames = conflictingJoined.map((id) {
          return staticData?.factions
                  .where((f) => f.id == id)
                  .firstOrNull
                  ?.name ??
              id;
        }).join(', ');

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text(
              '이해충돌 경고',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            content: Text(
              '$conflictNames\n\n위 세력과 이해충돌 관계입니다. 가입 시 해당 세력의 평판이 -100이 되고 탈퇴 처리됩니다.',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  '가입',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await repo.applyConflictPenalty(conflictingJoined);
      }
    }

    await repo.join(faction.id);
    ref.read(factionRefreshProvider.notifier).state++;
  }

  Future<void> _handleLeave(
    WidgetRef ref,
    FactionData faction,
    FactionStateRepository repo,
  ) async {
    await repo.leave(faction.id);
    ref.read(factionRefreshProvider.notifier).state++;
  }
}

class _TopBar extends StatelessWidget {
  final String displayName;
  final VoidCallback onBack;

  const _TopBar({required this.displayName, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 4,
        right: 16,
        bottom: 0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            color: AppTheme.textPrimary,
          ),
          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactionBody extends ConsumerWidget {
  final FactionData faction;
  final FactionState? state;
  final int clueLevel;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  const _FactionBody({
    required this.faction,
    required this.state,
    required this.clueLevel,
    required this.onJoin,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticDataAsync = ref.watch(staticDataProvider);
    final userData = ref.watch(userDataProvider);
    final repo = ref.read(factionStateRepositoryProvider);

    final clueRecords = state?.clueRecords ?? <FactionClueRecord>[];
    final sortedRecords = List<FactionClueRecord>.of(clueRecords)
      ..sort((a, b) => a.foundAt.compareTo(b.foundAt));
    final discoveredRegionIds =
        clueRecords.map((r) => r.regionId).toSet().toList();

    final reputation = state?.currentReputation ?? 0;
    final joined = state?.isJoined ?? false;

    // 가입 가능 여부 계산
    final allFactions = ref.watch(factionListProvider);
    final joinedIds = repo.getJoinedFactionIds();
    final currentRank = staticDataAsync.value?.ranks != null && userData != null
        ? _getCurrentRank(userData.reputation, staticDataAsync.value!.ranks)
        : 'F';

    final canJoin = !joined &&
        FactionJoinService.canJoin(
          factionId: faction.id,
          reputation: reputation,
          joinNeedsClue: faction.joinNeedsClue,
          maxClueLevel: clueLevel,
          joinRankMin: faction.joinRankMin,
          currentRank: currentRank,
          conflictFactionIds: faction.conflictFactionIds,
          currentlyJoinedFactionIds: joinedIds,
        );

    // 이해충돌 세력 이름
    final conflictNames = faction.conflictFactionIds.map((id) {
      return allFactions.where((f) => f.id == id).firstOrNull?.name ?? id;
    }).toList();

    final passiveDesc =
        PassiveBonusFormatter.describe(faction.passiveBonusJson);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 세력명 + 분류
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('세력명',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textHint)),
                        const SizedBox(height: 4),
                        Text(
                          clueLevel >= 1 ? faction.name : '???',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  _VisibilityBadge(visibilityType: faction.visibilityType),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 평판 바
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('세력 평판',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textHint)),
                  Text(
                    '$reputation / ${joined ? 100 : 10}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ReputationBar(reputation: reputation, joined: joined),
              if (!joined && reputation >= 1)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '가입 후 최대 100까지 상승 가능',
                    style: TextStyle(fontSize: 11, color: AppTheme.textHint),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 가입 조건 + 버튼
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('가입',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textHint)),
              const SizedBox(height: 8),
              _JoinConditions(
                  faction: faction,
                  clueLevel: clueLevel,
                  currentRank: currentRank,
                  reputation: reputation),
              if (conflictNames.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '이해충돌: ${conflictNames.join(', ')}',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
              const SizedBox(height: 12),
              if (joined)
                OutlinedButton(
                  onPressed: onLeave,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red)),
                  child: const Text('탈퇴'),
                )
              else
                ElevatedButton(
                  onPressed: canJoin ? onJoin : null,
                  child: Text(canJoin ? '가입' : '가입 불가'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 패시브 보너스
        if (clueLevel >= 2 && passiveDesc.isNotEmpty) ...[
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('패시브 보너스 (가입 즉시)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textHint)),
                const SizedBox(height: 4),
                Text(passiveDesc,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // 설명
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('설명',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textHint)),
              const SizedBox(height: 4),
              Text(
                clueLevel >= 2 ? faction.description : '???',
                style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 이념
        if (clueLevel >= 2) ...[
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('이념',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textHint)),
                const SizedBox(height: 4),
                Text(faction.philosophy,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // 활동 티어
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('활동 티어',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textHint)),
              const SizedBox(height: 4),
              Text(
                clueLevel >= 2
                    ? '티어 ${faction.tierRange[0]}~${faction.tierRange[1]}'
                    : '???',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 발견 기록
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('발견 기록 (${sortedRecords.length}건)',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textHint)),
              const SizedBox(height: 4),
              if (sortedRecords.isEmpty)
                const Text('아직 발견된 기록이 없습니다',
                    style: TextStyle(fontSize: 13, color: AppTheme.textHint))
              else
                ...sortedRecords.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${r.foundAt.toLocal()} — regionId: ${r.regionId}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 발견 리전
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('발견 리전 (${discoveredRegionIds.length}곳)',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textHint)),
              const SizedBox(height: 4),
              if (discoveredRegionIds.isEmpty)
                const Text('아직 없음',
                    style: TextStyle(fontSize: 13, color: AppTheme.textHint))
              else
                staticDataAsync.maybeWhen(
                  data: (staticData) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: discoveredRegionIds.map((regionId) {
                      final region = staticData.regions
                          .where((r) => r.region == regionId)
                          .firstOrNull;
                      final name =
                          region?.regionName ?? 'regionId: $regionId';
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(children: [
                          const Text('• ',
                              style: TextStyle(
                                  color: AppTheme.textTertiary)),
                          Expanded(
                              child: Text(name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary))),
                        ]),
                      );
                    }).toList(),
                  ),
                  orElse: () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: discoveredRegionIds
                        .map((id) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('regionId: $id',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary)),
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _getCurrentRank(int reputation, List<Rank> ranks) {
    final sorted = List<Rank>.of(ranks)
      ..sort((a, b) => b.requiredReputation.compareTo(a.requiredReputation));
    for (final rank in sorted) {
      if (reputation >= rank.requiredReputation) return rank.grade;
    }
    return 'F';
  }
}

class _ReputationBar extends StatelessWidget {
  final int reputation;
  final bool joined;

  const _ReputationBar({required this.reputation, required this.joined});

  @override
  Widget build(BuildContext context) {
    // -100~+100 범위를 0.0~1.0으로 정규화
    final normalized = ((reputation + 100) / 200).clamp(0.0, 1.0);
    final color = reputation < 0
        ? Colors.red
        : reputation == 0
            ? AppTheme.textHint
            : Colors.green;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 8,
            backgroundColor: AppTheme.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('-100',
                style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
            Text('0',
                style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
            Text('+100',
                style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
          ],
        ),
      ],
    );
  }
}

class _JoinConditions extends StatelessWidget {
  final FactionData faction;
  final int clueLevel;
  final String currentRank;
  final int reputation;

  const _JoinConditions({
    required this.faction,
    required this.clueLevel,
    required this.currentRank,
    required this.reputation,
  });

  @override
  Widget build(BuildContext context) {
    final conditions = <Widget>[];

    // 평판 > 0 조건 (실제 값 기반)
    conditions.add(_ConditionRow(
      label: '세력 평판 > 0',
      met: reputation > 0,
    ));

    // clue 조건
    if (faction.joinNeedsClue) {
      conditions.add(_ConditionRow(
        label: '거점 발견 (★★★)',
        met: clueLevel >= 3,
      ));
    }

    // 랭크 조건
    if (faction.joinRankMin != null) {
      final sufficient =
          FactionJoinService.isRankSufficient(currentRank, faction.joinRankMin!);
      conditions.add(_ConditionRow(
        label: '랭크 ${faction.joinRankMin} 이상 (현재: $currentRank)',
        met: sufficient,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: conditions,
    );
  }
}

class _ConditionRow extends StatelessWidget {
  final String label;
  final bool met;

  const _ConditionRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: met ? Colors.green : AppTheme.textHint,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? AppTheme.textPrimary : AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  final String visibilityType;

  const _VisibilityBadge({required this.visibilityType});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (visibilityType) {
      'secret' => ('비밀', Colors.orange),
      'regional' => ('지역·종족', Colors.blue),
      _ => ('공개', Colors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: child,
    );
  }
}
