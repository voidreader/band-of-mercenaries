import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_codex_providers.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_data.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';

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
    final factions = ref.watch(factionListProvider);
    final faction = factions.where((f) => f.id == factionId).firstOrNull;

    final repo = ref.read(factionStateRepositoryProvider);
    final state = repo.getState(factionId);

    final uniqueDiscoveryCount =
        state?.clueRecords.map((r) => r.discoveryId).toSet().length ?? 0;
    final maxClueLevel = uniqueDiscoveryCount.clamp(0, 3);

    final displayName = maxClueLevel >= 1 ? (faction?.name ?? '???') : '???';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 바
          _TopBar(displayName: displayName, onBack: onBack),
          // 본문
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
                    maxClueLevel: maxClueLevel,
                  ),
          ),
        ],
      ),
    );
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
  final int maxClueLevel;

  const _FactionBody({
    required this.faction,
    required this.state,
    required this.maxClueLevel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticDataAsync = ref.watch(staticDataProvider);

    final clueRecords = state?.clueRecords ?? <FactionClueRecord>[];
    final sortedRecords = List<FactionClueRecord>.of(clueRecords)
      ..sort((a, b) => a.foundAt.compareTo(b.foundAt));

    final discoveredRegionIds =
        clueRecords.map((r) => r.regionId).toSet().toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 세력 이름
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '세력명',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textHint,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                maxClueLevel >= 1 ? faction.name : '???',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 설명
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '설명',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textHint,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                maxClueLevel >= 2 ? faction.description : '???',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 이념 (maxClueLevel >= 2 일 때만 표시)
        if (maxClueLevel >= 2) ...[
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '이념',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textHint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  faction.philosophy,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
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
              const Text(
                '활동 티어',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textHint,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                maxClueLevel >= 2
                    ? '티어 ${faction.tierRange[0]}~${faction.tierRange[1]}'
                    : '???',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
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
              Text(
                '발견 기록 (${sortedRecords.length}건)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textHint,
                ),
              ),
              const SizedBox(height: 4),
              if (sortedRecords.isEmpty)
                const Text(
                  '아직 발견된 기록이 없습니다',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textHint,
                  ),
                )
              else
                ...sortedRecords.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${r.foundAt.toLocal()} — regionId: ${r.regionId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 발견 리전 목록
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '발견 리전 (${discoveredRegionIds.length}곳)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textHint,
                ),
              ),
              const SizedBox(height: 4),
              if (discoveredRegionIds.isEmpty)
                const Text(
                  '아직 없음',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textHint,
                  ),
                )
              else
                staticDataAsync.maybeWhen(
                  data: (staticData) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: discoveredRegionIds.map((regionId) {
                      final region = staticData.regions
                          .where((r) => r.region == regionId)
                          .firstOrNull;
                      final regionName = region?.regionName ?? 'regionId: $regionId';
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(color: AppTheme.textTertiary),
                            ),
                            Expanded(
                              child: Text(
                                regionName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  orElse: () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: discoveredRegionIds
                        .map(
                          (regionId) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'regionId: $regionId',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
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
