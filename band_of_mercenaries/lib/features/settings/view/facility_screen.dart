import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/facility.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/facility_service.dart';

class FacilityScreen extends ConsumerWidget {
  const FacilityScreen({super.key});

  String _effectDescription(Facility facility, int currentLevel) {
    final nextLevel = currentLevel + 1;
    if (nextLevel > facility.maxLevel) {
      final value = FacilityService.getEffectValue(facility, currentLevel);
      return switch (facility.effectType) {
        'xp_bonus' => '경험치 +${(value * 100).round()}%',
        'recovery_reduction' => '부상 회복시간 -${(value * 100).round()}%',
        'max_mercenaries' =>
          '최대 용병 수 ${FacilityService.baseMercenaryMax + value.round()}명',
        'quest_count' =>
          '퀘스트 생성 ${FacilityService.baseQuestCount + value.round()}개',
        _ => '',
      };
    }
    final nextValue = FacilityService.getEffectValue(facility, nextLevel);
    return switch (facility.effectType) {
      'xp_bonus' => '경험치 +${(nextValue * 100).round()}%',
      'recovery_reduction' => '부상 회복시간 -${(nextValue * 100).round()}%',
      'max_mercenaries' =>
        '최대 용병 수 ${FacilityService.baseMercenaryMax + nextValue.round()}명',
      'quest_count' =>
        '퀘스트 생성 ${FacilityService.baseQuestCount + nextValue.round()}개',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticDataAsync = ref.watch(staticDataProvider);
    final userData = ref.watch(userDataProvider);

    if (userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return staticDataAsync.when(
      data: (staticData) {
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: staticData.facilities.length,
          itemBuilder: (context, index) {
            final facility = staticData.facilities[index];
            final currentLevel = userData.facilities[facility.id] ?? 0;
            final isMaxLevel = currentLevel >= facility.maxLevel;
            final upgradeCost = FacilityService.getUpgradeCost(facility, currentLevel);
            final canUpgrade = upgradeCost != null && userData.gold >= upgradeCost;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          facility.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isMaxLevel
                                ? AppTheme.tier5Bg
                                : AppTheme.tier3Bg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isMaxLevel
                                ? 'Lv.$currentLevel (최대)'
                                : 'Lv.$currentLevel / ${facility.maxLevel}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isMaxLevel
                                  ? AppTheme.tier5
                                  : AppTheme.tier3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isMaxLevel
                          ? _effectDescription(facility, currentLevel)
                          : '업그레이드 시: ${_effectDescription(facility, currentLevel)}',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textTertiary),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isMaxLevel || !canUpgrade
                            ? null
                            : () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('${facility.name} 업그레이드'),
                                    content: Text(
                                      'Lv.${currentLevel + 1}로 업그레이드하시겠습니까?\n비용: ${upgradeCost}G',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('취소'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('확인'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await ref
                                      .read(userDataProvider.notifier)
                                      .upgradeFacility(facility.id, upgradeCost);
                                }
                              },
                        child: Text(
                          isMaxLevel
                              ? '최대 레벨'
                              : (canUpgrade
                                  ? '업그레이드 (${upgradeCost}G)'
                                  : '골드 부족 (${upgradeCost}G 필요)'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}
