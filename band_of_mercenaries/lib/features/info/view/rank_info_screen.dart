import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/domain/reputation_service.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_formatter.dart';
import 'package:band_of_mercenaries/core/models/passive_effect.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';

/// 정보 탭 "명성" ListTile 탭 시 표시되는 전체 화면.
///
/// 상단: 현재 랭크 배지 + 진행도
/// 중단: F~A 가로 타임라인 (탭 가능)
/// 하단: 선택 등급의 보너스 프리뷰 (기본값 현재 랭크)
///
/// InfoScreen._showRank 상태로 토글됨. onBack은 뒤로가기 콜백.
class RankInfoScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const RankInfoScreen({super.key, required this.onBack});

  @override
  ConsumerState<RankInfoScreen> createState() => _RankInfoScreenState();
}

class _RankInfoScreenState extends ConsumerState<RankInfoScreen> {
  String? _selectedGrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userData = ref.watch(userDataProvider);
    final staticData = ref.watch(staticDataProvider).valueOrNull;

    if (userData == null || staticData == null) {
      return _wrap(theme, const Center(child: Text('랭크 데이터 로딩 중')));
    }

    final reputation = userData.reputation;
    final ranks = [...staticData.ranks]
      ..sort((a, b) => a.requiredReputation.compareTo(b.requiredReputation));
    if (ranks.isEmpty) {
      return _wrap(theme, const Center(child: Text('랭크 데이터 없음')));
    }

    final currentRank = ReputationService.getCurrentRank(reputation, ranks);
    final currentLevel = ReputationService.getRankLevel(reputation, ranks);
    final nextRank = ReputationService.getNextRank(reputation, ranks);

    final selectedGrade = _selectedGrade ?? currentRank.grade;
    final selectedRank = ranks.firstWhere(
      (r) => r.grade == selectedGrade,
      orElse: () => currentRank,
    );
    final selectedEffects = PassiveEffect.parseEffects(selectedRank.bonusJson);
    final selectedReached = reputation >= selectedRank.requiredReputation;

    return _wrap(
      theme,
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 상단: 현재 랭크 배지 + 진행도
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RankBadge(grade: currentRank.grade, active: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          currentRank.name,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (nextRank == null)
                    Text(
                      '최고 등급 도달',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else ...[
                    Text(
                      '평판 $reputation / ${nextRank.requiredReputation} (다음 ${nextRank.grade})',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _progress(reputation, currentRank, nextRank),
                      minHeight: 6,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 중단: 가로 타임라인
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < ranks.length; i++) ...[
                    Flexible(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedGrade = ranks[i].grade),
                        child: _RankBadge(
                          grade: ranks[i].grade,
                          active: i <= currentLevel,
                          selected: ranks[i].grade == selectedGrade,
                        ),
                      ),
                    ),
                    if (i < ranks.length - 1)
                      SizedBox(
                        width: 8,
                        child: Container(
                          height: 2,
                          color: i < currentLevel
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 하단: 선택 등급 보너스 프리뷰
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '[${selectedRank.grade}] ${selectedRank.name}',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(width: 8),
                      if (selectedReached)
                        Text(
                          '(활성)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        )
                      else
                        Text(
                          '(잠금)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (selectedEffects.isEmpty)
                    Text(
                      '보너스 없음',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    )
                  else
                    for (final effect in selectedEffects)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '• ${PassiveBonusFormatter.format(effect)}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            if (selectedReached)
                              Text(
                                '✓ 활성',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrap(ThemeData theme, Widget body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: widget.onBack,
              ),
              const Text(
                '명성',
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
        Expanded(child: body),
      ],
    );
  }

  double _progress(int reputation, Rank current, Rank next) {
    final span = next.requiredReputation - current.requiredReputation;
    if (span <= 0) return 1.0;
    final within = reputation - current.requiredReputation;
    return (within / span).clamp(0.0, 1.0);
  }
}

class _RankBadge extends StatelessWidget {
  final String grade;
  final bool active;
  final bool selected;
  const _RankBadge({
    required this.grade,
    this.active = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = selected
        ? theme.colorScheme.primary
        : (active
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest);
    final fg = selected
        ? theme.colorScheme.onPrimary
        : (active
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.outline);
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Text(
        grade,
        style: theme.textTheme.titleSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
