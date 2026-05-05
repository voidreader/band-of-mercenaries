import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/navigation_provider.dart';
import 'package:band_of_mercenaries/features/crafting/view/recipe_list_section.dart';
import 'package:band_of_mercenaries/features/investigation/domain/settlement_trust_provider.dart';
import 'package:band_of_mercenaries/features/settlement/domain/settlement_npc_data.dart';
import 'package:band_of_mercenaries/features/settlement/domain/village_facility.dart';

/// 더스트빌 낡은 대장간 화면 — 신뢰도 2단계 이상 시 제작 레시피 목록 표시.
class OldSmithyScreen extends ConsumerWidget {
  const OldSmithyScreen({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trust = ref.watch(settlementTrustProvider(GameConstants.startingRegionId));
    final level = trust.level;
    final greeting = SettlementNpcData.greetingFor(VillageFacility.oldSmithy, level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: onClose,
                color: AppTheme.textPrimary,
              ),
              const Text(
                '낡은 대장간',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NpcHeader(greeting: greeting),
                const Divider(height: 24),
                if (level < 2)
                  const _EmptySmithyMessage()
                else
                  RecipeListSection(onClose: onClose),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          onClose();
                          ref.read(currentTabProvider.notifier).state = 5;
                        },
                        child: const Text('인벤토리에서 재료 보기'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onClose,
                        child: const Text('닫기'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NpcHeader extends StatelessWidget {
  final String greeting;
  const _NpcHeader({required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('⚒️', style: TextStyle(fontSize: 32)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '하겐',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptySmithyMessage extends StatelessWidget {
  const _EmptySmithyMessage();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            '대장장이가 아직 일거리를 주지 않았습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            '마을 신뢰도를 쌓으면 제작이 시작됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }
}
