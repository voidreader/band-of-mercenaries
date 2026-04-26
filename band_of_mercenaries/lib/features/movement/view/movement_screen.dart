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
import 'package:band_of_mercenaries/shared/widgets/card_container.dart';
import 'package:band_of_mercenaries/features/facility/domain/construction_service.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_transformed_provider.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_provider.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';

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
    final sectorChanges = ref.watch(currentRegionSectorChangesProvider);

    // 체인 대상 리전 ID 집합: active 상태 체인의 현재 단계 targetRegionId/regionId 수집
    final chainProgressList = ref.watch(chainQuestProgressProvider).valueOrNull ?? [];

    if (userData == null) return const Center(child: CircularProgressIndicator());

    return staticData.when(
      data: (data) {
        // active 체인 진행 중인 단계의 대상 리전→섹터 매핑 계산.
        // value에 null이 포함되면 해당 region 전체 섹터 하이라이트(섹터 미지정 fallback).
        // targetSectorId는 1-based(1..10) — UserData.sector / 화면 표시 sector 값과 동일.
        final chainTargetSectors = <int, Set<int?>>{};
        for (final progress in chainProgressList) {
          if (progress.status != ChainQuestStatus.active) continue;
          final step = data.chainQuests.where(
            (q) => q.chainId == progress.chainId && q.step == progress.currentStep,
          ).firstOrNull;
          if (step == null) continue;
          final regionId = step.targetRegionId ?? step.regionId;
          if (regionId == null) continue;
          chainTargetSectors
              .putIfAbsent(regionId, () => <int?>{})
              .add(step.targetSectorId);
        }
        final isInvestigating = userData.investigatingMercId != null;
        final currentRegion = data.regions.firstWhere((r) => r.region == userData.region);
        final targetRegion = data.regions.firstWhere(
          (r) => r.region == _selectedRegion,
          orElse: () => currentRegion,
        );
        final distance = UserData.calculateDistance(
          userData.region, userData.sector, _selectedRegion, _selectedSector,
        );
        final speedMult = ref.watch(speedMultiplierProvider);
        double travelReduction = 0.0;
        final transportFacility = data.facilities.where((f) => f.id == 'transport').firstOrNull;
        if (transportFacility != null) {
          final transportLevel = userData.facilities['transport'] ?? 0;
          travelReduction = ConstructionService.getEffectValue(transportFacility, transportLevel);
        }
        final rawMoveTime = UserData.calculateMoveTime(distance, speedMultiplier: speedMult);
        final moveTime = Duration(seconds: (rawMoveTime.inSeconds * (1.0 - travelReduction)).round());
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
                    CardContainer(
                      color: AppTheme.surfaceAlt,
                      padding: const EdgeInsets.all(14),
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
                    CardContainer(
                      color: AppTheme.surfaceAlt,
                      padding: const EdgeInsets.all(14),
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
                              final sectorKey = i.toString(); // 저장 키는 0-based
                              final transformType = sectorChanges[sectorKey];
                              final isSelected = sector == _selectedSector;
                              // 체인 매칭: targetSectorId 일치 또는 섹터 미지정(null=region 전체) fallback
                              final targets = chainTargetSectors[_selectedRegion];
                              final isChainTarget = targets != null &&
                                  (targets.contains(null) || targets.contains(sector));
                              return GestureDetector(
                                onTap: userData.isMoving ? null : () {
                                  setState(() => _selectedSector = sector);
                                },
                                child: _SectorTile(
                                  sector: sector,
                                  transformType: transformType,
                                  isSelected: isSelected,
                                  isChainTarget: isChainTarget,
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
                    if (distance > 0 && travelReduction > 0)
                      Text(
                        '이동수단 효과: -${(travelReduction * 100).round()}%',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
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
                    if (isInvestigating)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.tier3Bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.tier3.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            '조사가 진행 중이라 이동할 수 없습니다',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppTheme.tier3, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (userData.isMoving || distance == 0 || !isTargetAccessible || hasDispatchedQuests || isInvestigating)
                            ? null
                            : () {
                                ref.read(movementProvider.notifier)
                                    .startMovement(_selectedRegion, _selectedSector);
                              },
                        child: Text(
                          isInvestigating
                              ? '조사 진행 중'
                              : userData.isMoving
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
      error: (e, _) => const Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다')),
    );
  }

}

class _SectorTile extends StatelessWidget {
  final int sector;
  final String? transformType;
  final bool isSelected;
  final bool isChainTarget;

  const _SectorTile({
    required this.sector,
    required this.transformType,
    required this.isSelected,
    required this.isChainTarget,
  });

  Color _transformColor(String type) => switch (type) {
    'village' => AppTheme.transformVillage,
    'ruins' => AppTheme.transformRuins,
    'hidden' => AppTheme.transformHidden,
    _ => AppTheme.transformFallback,
  };

  String _transformIcon(String type) => switch (type) {
    'village' => '🏘️',
    'ruins' => '🏛️',
    'hidden' => '✨',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    // 체인 대상 리전이면 금색 테두리 우선, 아니면 변형 색상 또는 기본 색상
    final borderColor = isChainTarget
        ? AppTheme.chainGold
        : (transformType != null
            ? _transformColor(transformType!)
            : (isSelected ? Colors.white : AppTheme.border));
    final borderWidth = (isChainTarget || transformType != null) ? 2.0 : 1.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$sector',
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (transformType != null)
                Text(
                  _transformIcon(transformType!),
                  style: const TextStyle(fontSize: 10),
                ),
            ],
          ),
        ),
        // 체인 대상 리전이면 우상단에 "체인" 마이크로 배지 표시
        if (isChainTarget)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.chainGold,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                '체인',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
