import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
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
      data: (data) => Column(
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
                Text('용병단 ${aliveMercs.length}명', style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary)),
              ],
            ),
          ),

          // Recruit buttons
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: canFreeRecruit
                        ? () async {
                            await ref.read(mercenaryListProvider.notifier).recruit();
                            userData.lastFreeRecruit = DateTime.now();
                            await userData.save();
                          }
                        : null,
                    child: Column(
                      children: [
                        const Text('무료 모집'),
                        Text(
                          canFreeRecruit ? '가능!' : '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 12, color: canFreeRecruit ? Colors.white70 : Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: userData.gold >= 100
                        ? () async {
                            await ref.read(userDataProvider.notifier).spendGold(100);
                            await ref.read(mercenaryListProvider.notifier).recruit();
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    child: const Column(
                      children: [
                        Text('골드 모집', style: TextStyle(color: AppTheme.textPrimary)),
                        Text('100G', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                      ],
                    ),
                  ),
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
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
