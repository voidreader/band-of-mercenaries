import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_provider.dart';
import 'package:band_of_mercenaries/core/domain/reputation_service.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/shared/widgets/timer_display.dart';

class MovementScreen extends ConsumerStatefulWidget {
  const MovementScreen({super.key});

  @override
  ConsumerState<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends ConsumerState<MovementScreen> {
  int _selectedRegion = 1;
  int _selectedSector = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = ref.read(userDataProvider);
      if (userData != null) {
        setState(() {
          _selectedRegion = userData.region;
          _selectedSector = userData.sector;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    final staticData = ref.watch(staticDataProvider);
    final quests = ref.watch(questListProvider);
    final hasDispatchedQuests = quests.any((q) => q.status == QuestStatus.inProgress);
    ref.watch(gameTickProvider);

    if (userData == null) return const Center(child: CircularProgressIndicator());

    return staticData.when(
      data: (data) {
        final currentRegion = data.regions.firstWhere((r) => r.region == userData.region);
        final targetRegion = data.regions.firstWhere(
          (r) => r.region == _selectedRegion,
          orElse: () => currentRegion,
        );
        final distance = UserData.calculateDistance(
          userData.region, userData.sector, _selectedRegion, _selectedSector,
        );
        final speedMult = ref.watch(speedMultiplierProvider);
        final moveTime = UserData.calculateMoveTime(distance, speedMultiplier: speedMult);
        final isTargetAccessible = ReputationService.isRegionAccessible(
          targetRegion.regionTier, userData.reputation, data.ranks,
        );
        // Find the rank required to access this tier
        final requiredRank = data.ranks.firstWhere(
          (r) => r.unlockTier >= targetRegion.regionTier,
          orElse: () => data.ranks.last,
        );

        return Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('💰 ${userData.gold}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('대륙 ${userData.continent} : 지역 ${userData.region} : 섹터 ${userData.sector}',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    // Moving indicator
                    if (userData.isMoving && userData.moveEndTime != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.tier3Bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TimerDisplay(
                          label: '🗺 이동 중 → 지역 ${userData.moveTargetRegion}',
                          remaining: userData.moveEndTime!.difference(DateTime.now()),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Current location
                    Text('현재 위치', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
                    const SizedBox(height: 4),
                    Text('${currentRegion.regionName} (지역 ${userData.region} : 섹터 ${userData.sector})',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Tier ${currentRegion.regionTier} · 추천 전투력 ${currentRegion.recommendPower}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
                    const SizedBox(height: 20),

                    // Region selector
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        children: [
                          const Text('지역 선택', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: userData.isMoving ? null : () {
                                  setState(() {
                                    if (_selectedRegion > 1) _selectedRegion--;
                                  });
                                },
                                icon: const Text('◀', style: TextStyle(fontSize: 16)),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.surface,
                                  side: const BorderSide(color: AppTheme.border),
                                ),
                              ),
                              const SizedBox(width: 14),
                              SizedBox(
                                width: 130,
                                child: Column(
                                  children: [
                                    Text('지역 $_selectedRegion',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                    Text('${targetRegion.regionName} · Tier ${targetRegion.regionTier}',
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
                                    if (!isTargetAccessible) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.tier5Bg,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '잠김',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.tier5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              IconButton(
                                onPressed: userData.isMoving ? null : () {
                                  setState(() {
                                    if (_selectedRegion < 199) _selectedRegion++;
                                  });
                                },
                                icon: const Text('▶', style: TextStyle(fontSize: 16)),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.surface,
                                  side: const BorderSide(color: AppTheme.border),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Sector selector
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        children: [
                          const Text('섹터 선택', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: List.generate(10, (i) {
                              final sector = i + 1;
                              final isSelected = sector == _selectedSector;
                              return GestureDetector(
                                onTap: userData.isMoving ? null : () {
                                  setState(() => _selectedSector = sector);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.primary : AppTheme.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: isSelected ? null : Border.all(color: AppTheme.border),
                                  ),
                                  child: Text(
                                    '$sector',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Travel time & button
                    if (distance > 0)
                      Text(
                        '이동 소요시간: ',
                        style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary),
                      ),
                    if (distance > 0)
                      Text(
                        '약 ${moveTime.inSeconds}초',
                        style: const TextStyle(fontSize: 14, color: AppTheme.timerBlue, fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: 10),
                    if (!isTargetAccessible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.tier5Bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.tier5.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '이 지역은 잠겨 있습니다. 필요 등급: ${requiredRank.name}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.tier5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (userData.isMoving || distance == 0 || !isTargetAccessible || hasDispatchedQuests)
                            ? null
                            : () {
                                ref.read(movementProvider.notifier)
                                    .startMovement(_selectedRegion, _selectedSector);
                              },
                        child: Text(
                          userData.isMoving
                              ? '이동 중...'
                              : hasDispatchedQuests
                                  ? '파견된 용병이 있습니다'
                                  : '이동 시작',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
