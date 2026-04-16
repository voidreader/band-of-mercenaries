// band_of_mercenaries/lib/features/info/view/faction_codex_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_codex_providers.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_data.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';

class FactionCodexScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onSelectFaction;

  const FactionCodexScreen({
    super.key,
    required this.onBack,
    required this.onSelectFaction,
  });

  @override
  ConsumerState<FactionCodexScreen> createState() =>
      _FactionCodexScreenState();
}

class _FactionCodexScreenState extends ConsumerState<FactionCodexScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeScrollToTarget();
    });
  }

  void _maybeScrollToTarget() {
    final targetId = ref.read(factionCodexScrollTargetProvider);
    if (targetId == null) return;

    final factions = ref.read(factionListProvider);
    final repo = ref.read(factionStateRepositoryProvider);
    final allStates = repo.getAll();
    final stateMap = _buildStateMap(allStates);
    final sorted = _sortedFactions(factions, stateMap);
    final index = sorted.indexWhere((f) => f.id == targetId);
    if (index < 0) return;

    const itemHeight = 76.0;
    final offset = (index * itemHeight).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    ref.read(factionCodexScrollTargetProvider.notifier).state = null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, FactionState> _buildStateMap(List<FactionState> states) {
    return {for (final s in states) s.factionId: s};
  }

  int _displayClueLevel(FactionData faction, FactionState? state) {
    if (faction.visibilityType == 'public') {
      // 공개 세력: 최소 level 1 (이름 항상 노출)
      return max(1, state?.maxClueLevel ?? 0);
    }
    return state?.maxClueLevel ?? 0;
  }

  List<FactionData> _sortedFactions(
    List<FactionData> factions,
    Map<String, FactionState> stateMap,
  ) {
    final publicFactions = <FactionData>[];
    final discovered = <FactionData>[];
    final undiscovered = <FactionData>[];

    for (final f in factions) {
      final state = stateMap[f.id];
      if (f.visibilityType == 'public') {
        publicFactions.add(f);
      } else if (state != null && state.clueRecords.isNotEmpty) {
        discovered.add(f);
      } else {
        undiscovered.add(f);
      }
    }

    // 발견된 비밀/지역 세력: clueLevel 내림차순
    discovered.sort((a, b) {
      final aLevel = stateMap[a.id]?.maxClueLevel ?? 0;
      final bLevel = stateMap[b.id]?.maxClueLevel ?? 0;
      return bLevel.compareTo(aLevel);
    });

    return [...publicFactions, ...discovered, ...undiscovered];
  }

  Color _parseFactionColor(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      final value = int.parse(
        cleaned.length == 6 ? 'FF$cleaned' : cleaned,
        radix: 16,
      );
      return Color(value);
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // factionRefreshProvider를 watch해서 join/leave 후 자동 갱신
    ref.watch(factionRefreshProvider);

    final factions = ref.watch(factionListProvider);
    final repo = ref.read(factionStateRepositoryProvider);
    final allStates = repo.getAll();
    final stateMap = _buildStateMap(allStates);
    final sorted = _sortedFactions(factions, stateMap);

    final hasUndiscovered = factions.any((f) {
      if (f.visibilityType == 'public') return false;
      final state = stateMap[f.id];
      return state == null || state.clueRecords.isEmpty;
    });

    return Column(
      children: [
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
                color: AppTheme.textPrimary,
              ),
              const SizedBox(width: 4),
              const Text(
                '세력 도감',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.border),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length + (hasUndiscovered ? 1 : 0),
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              if (hasUndiscovered && index == sorted.length) {
                return _UnknownFactionRow();
              }
              final faction = sorted[index];
              final state = stateMap[faction.id];
              final clueLevel = _displayClueLevel(faction, state);
              final joined = state?.isJoined ?? false;

              return _FactionCard(
                faction: faction,
                clueLevel: clueLevel,
                joined: joined,
                factionColor: clueLevel >= 1
                    ? _parseFactionColor(faction.color)
                    : Colors.grey,
                onTap: () => widget.onSelectFaction(faction.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FactionCard extends StatelessWidget {
  final FactionData faction;
  final int clueLevel;
  final bool joined;
  final Color factionColor;
  final VoidCallback onTap;

  const _FactionCard({
    required this.faction,
    required this.clueLevel,
    required this.joined,
    required this.factionColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: factionColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          clueLevel >= 1 ? faction.name : '???',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (joined)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: factionColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: factionColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            '가입',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: factionColor,
                            ),
                          ),
                        )
                      else
                        _StarProgress(clueLevel: clueLevel),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clueLevel >= 2 ? faction.description : '???',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: AppTheme.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StarProgress extends StatelessWidget {
  final int clueLevel;
  const _StarProgress({required this.clueLevel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < clueLevel;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          size: 16,
          color: filled ? Colors.amber : AppTheme.textHint,
        );
      }),
    );
  }
}

class _UnknownFactionRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '??? (미발견 세력이 있습니다)',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textHint,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
