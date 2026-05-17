import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/constants/m7_constants.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/domain/reputation_service.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_distance_calculator.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';

class LivingsphereJumpBar extends ConsumerWidget {
  final int selectedRegion;
  final ValueChanged<int> onJump;
  const LivingsphereJumpBar({super.key, required this.selectedRegion, required this.onJump});

  String _envIcon(List<String> tags) {
    if (tags.contains('mountain')) return '🏔️';
    if (tags.contains('coast')) return '🌊';
    if (tags.contains('forest')) return '🌳';
    if (tags.contains('swamp')) return '🌫️';
    if (tags.contains('ruins')) return '🏛️';
    if (tags.contains('plains')) return '🌾';
    return '🌍';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider);
    final staticData = ref.watch(staticDataProvider).valueOrNull;
    if (userData == null || staticData == null) return const SizedBox.shrink();
    if (!M7Constants.livingsphereRegions.contains(userData.region)) return const SizedBox.shrink();

    final repo = ref.watch(regionStateRepositoryProvider);
    final adjacencyMap = staticData.regionAdjacencyMap;

    return SizedBox(
      height: 64,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: M7Constants.livingsphereRegions.map((regionId) {
            final region = staticData.regions.where((r) => r.region == regionId).firstOrNull;
            if (region == null) return const SizedBox.shrink();

            final distance = MovementDistanceCalculator.calculate(
              fromRegion: userData.region,
              fromSector: userData.sector,
              toRegion: regionId,
              toSector: 1,
              adjacencyMap: adjacencyMap,
            );
            final moveSec = UserData.calculateMoveTime(distance).inSeconds;
            final minutes = (moveSec / 60).ceil();

            final accessible = ReputationService.isRegionAccessible(
                region.regionTier, userData.reputation, staticData.ranks);
            final isCurrent = regionId == userData.region;
            final isSelected = regionId == selectedRegion;

            final state = repo.getState(regionId);
            final dangerLevel = state?.currentDangerLevel ?? 2;
            final dangerColor = AppTheme.dangerLevelColor(dangerLevel);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: accessible && !userData.isMoving ? () => onJump(regionId) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.15)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCurrent
                          ? AppTheme.primary
                          : (accessible ? AppTheme.border : AppTheme.borderLight),
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_envIcon(region.environmentTags)} ${region.regionName}',
                        style: TextStyle(
                          fontSize: 11,
                          color: accessible ? AppTheme.textPrimary : AppTheme.textHint,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('$minutes분',
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.textTertiary)),
                        const SizedBox(width: 4),
                        Icon(Icons.circle, size: 8, color: dangerColor),
                        if (!accessible) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.lock, size: 10, color: AppTheme.textHint),
                        ],
                      ]),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
