import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/facility_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/view/mercenary_card.dart';

class RecruitScreen extends ConsumerWidget {
  const RecruitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider);
    final mercs = ref.watch(mercenaryListProvider);
    final staticData = ref.watch(staticDataProvider);
    final speedMult = ref.watch(speedMultiplierProvider);
    ref.watch(gameTickProvider);

    if (userData == null) return const Center(child: CircularProgressIndicator());

    final aliveMercs = mercs.where((m) => m.status != MercenaryStatus.dead).toList();
    final freeRecruitCooldown = Duration(seconds: (2 * 3600 / speedMult).round());
    final nextFreeRecruit = userData.lastFreeRecruit.add(freeRecruitCooldown);
    final canFreeRecruit = DateTime.now().isAfter(nextFreeRecruit);
    final remaining = nextFreeRecruit.difference(DateTime.now());

    return staticData.when(
      data: (data) {
        final barracksData = data.facilities.where((f) => f.id == 'barracks').firstOrNull;
        final barracksLevel = userData.facilities['barracks'] ?? 0;
        final maxMercs = barracksData != null
            ? FacilityService.getMaxMercenaries(barracksData, barracksLevel)
            : FacilityService.baseMercenaryMax;
        final isAtCapacity = aliveMercs.length >= maxMercs;

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
                Row(
                  children: [
                    Text('용병: ${aliveMercs.length} / $maxMercs',
                        style: TextStyle(
                          fontSize: 14,
                          color: isAtCapacity ? AppTheme.tier5 : AppTheme.textTertiary,
                          fontWeight: isAtCapacity ? FontWeight.w700 : FontWeight.normal,
                        )),
                  ],
                ),
              ],
            ),
          ),

          // Recruit buttons
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                if (isAtCapacity)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.tier5Bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.tier5.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      '정원 초과 — 막사를 업그레이드하거나 용병을 해고하세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.tier5, fontWeight: FontWeight.w500),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canFreeRecruit && !isAtCapacity
                            ? () async {
                                await ref.read(mercenaryListProvider.notifier).recruit();
                                userData.lastFreeRecruit = DateTime.now();
                                await userData.save();
                              }
                            : null,
                        child: Column(
                          children: [
                            Text(isAtCapacity ? '정원 초과' : '무료 모집'),
                            Text(
                              isAtCapacity
                                  ? ''
                                  : (canFreeRecruit
                                      ? '가능!'
                                      : '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}'),
                              style: TextStyle(fontSize: 12, color: canFreeRecruit ? Colors.white70 : Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: userData.gold >= 100 && !isAtCapacity
                            ? () async {
                                await ref.read(userDataProvider.notifier).spendGold(100);
                                await ref.read(mercenaryListProvider.notifier).recruit();
                              }
                            : null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            Text(isAtCapacity ? '정원 초과' : '골드 모집',
                                style: const TextStyle(color: AppTheme.textPrimary)),
                            const Text('100G', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Mercenary list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('내 용병단', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: aliveMercs.length,
              itemBuilder: (_, i) {
                final merc = aliveMercs[i];
                final job = data.jobs.firstWhere((j) => j.id == merc.jobId);
                final trait = data.traits.firstWhere((t) => t.id == merc.traitId);
                return MercenaryCard(mercenary: merc, job: job, trait: trait);
              },
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
