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
  ConsumerState<FactionCodexScreen> createState() => _FactionCodexScreenState();
}

class _FactionCodexScreenState extends ConsumerState<FactionCodexScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetId = ref.read(factionCodexScrollTargetProvider);
      if (targetId == null) return;

      final factions = ref.read(factionListProvider);
      final repo = ref.read(factionStateRepositoryProvider);
      final allStates = repo.getAll();

      final sortedFactions = _sortedFactions(factions, allStates);
      final index = sortedFactions.indexWhere((f) => f.id == targetId);
      if (index < 0) return;

      // 카드 높이(약 76px) + 구분선 기준 대략적인 오프셋 계산
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
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _maxClueLevel(FactionState? state) {
    if (state == null || state.clueRecords.isEmpty) return 0;
    final uniqueCount =
        state.clueRecords.map((r) => r.discoveryId).toSet().length;
    return min(3, uniqueCount);
  }

  List<FactionData> _sortedFactions(
    List<FactionData> factions,
    List<FactionState> allStates,
  ) {
    final stateMap = <String, FactionState>{};
    for (final s in allStates) {
      stateMap[s.factionId] = s;
    }

    final discovered = <FactionData>[];
    final undiscovered = <FactionData>[];

    for (final f in factions) {
      final state = stateMap[f.id];
      if (state != null && state.clueRecords.isNotEmpty) {
        discovered.add(f);
      } else {
        undiscovered.add(f);
      }
    }

    // 발견된 세력: maxClueLevel 내림차순 정렬
    discovered.sort((a, b) {
      final aLevel = _maxClueLevel(stateMap[a.id]);
      final bLevel = _maxClueLevel(stateMap[b.id]);
      return bLevel.compareTo(aLevel);
    });

    return [...discovered, ...undiscovered];
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
    final factions = ref.watch(factionListProvider);
    final repo = ref.read(factionStateRepositoryProvider);
    final allStates = repo.getAll();

    final stateMap = <String, FactionState>{};
    for (final s in allStates) {
      stateMap[s.factionId] = s;
    }

    final sortedFactions = _sortedFactions(factions, allStates);
    final discoveredCount =
        sortedFactions.where((f) {
          final state = stateMap[f.id];
          return state != null && state.clueRecords.isNotEmpty;
        }).length;
    final hasUndiscovered = factions.length > discoveredCount;

    return Column(
      children: [
        // 상단 바
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
        // 세력 카드 리스트
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sortedFactions.length + (hasUndiscovered ? 1 : 0),
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              // 미발견 행 (리스트 맨 마지막)
              if (hasUndiscovered && index == sortedFactions.length) {
                return _UnknownFactionRow();
              }

              final faction = sortedFactions[index];
              final state = stateMap[faction.id];
              final clueLevel = _maxClueLevel(state);
              final isDiscovered = clueLevel > 0;

              return _FactionCard(
                faction: faction,
                clueLevel: clueLevel,
                isDiscovered: isDiscovered,
                factionColor: isDiscovered
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
  final bool isDiscovered;
  final Color factionColor;
  final VoidCallback onTap;

  const _FactionCard({
    required this.faction,
    required this.clueLevel,
    required this.isDiscovered,
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
            // 좌측 어센트 바
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: factionColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // 정보 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 세력 이름
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
                      // 별 3개 진행도
                      _StarProgress(clueLevel: clueLevel),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 설명
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
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textHint,
              size: 20,
            ),
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
