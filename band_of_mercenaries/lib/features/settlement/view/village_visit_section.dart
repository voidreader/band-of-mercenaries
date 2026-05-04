import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/shared/widgets/card_container.dart';
import 'package:band_of_mercenaries/features/investigation/domain/settlement_trust_provider.dart';
import 'package:band_of_mercenaries/features/settlement/domain/settlement_npc_data.dart';
import 'package:band_of_mercenaries/features/settlement/domain/village_facility.dart';
import 'package:band_of_mercenaries/features/settlement/view/chief_house_screen.dart';
import 'package:band_of_mercenaries/features/settlement/view/old_smithy_screen.dart';
import 'package:band_of_mercenaries/features/settlement/view/herbalist_screen.dart';

class VillageVisitSection extends ConsumerWidget {
  final VillageFacility? selectedFacility;
  final ValueChanged<VillageFacility> onSelect;
  final VoidCallback onClose;

  const VillageVisitSection({
    super.key,
    required this.selectedFacility,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = selectedFacility;
    if (selected != null) {
      return switch (selected) {
        VillageFacility.chiefHouse => ChiefHouseScreen(onClose: onClose),
        VillageFacility.oldSmithy => OldSmithyScreen(onClose: onClose),
        VillageFacility.herbalist => HerbalistScreen(onClose: onClose),
      };
    }

    final trust = ref.watch(settlementTrustProvider(GameConstants.startingRegionId));
    final level = trust.level;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            '💬 ${SettlementNpcData.squareGossip[level] ?? ''}',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textTertiary,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 16),
        _FacilityCard(
          facility: VillageFacility.chiefHouse,
          emoji: '🧓',
          title: '촌장 집',
          subtitle: '마을 사건과 신뢰도를 확인할 수 있다',
          onSelect: onSelect,
        ),
        const SizedBox(height: 10),
        _FacilityCard(
          facility: VillageFacility.oldSmithy,
          emoji: '⚒️',
          title: '낡은 대장간',
          subtitle: 'M5 제작 시스템 진입점 + 수리 의뢰',
          onSelect: onSelect,
        ),
        const SizedBox(height: 10),
        _FacilityCard(
          facility: VillageFacility.herbalist,
          emoji: '🌿',
          title: '약초상',
          subtitle: '1회성 즉시 회복 + 채집 정보',
          onSelect: onSelect,
        ),
      ],
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final VillageFacility facility;
  final String emoji;
  final String title;
  final String subtitle;
  final ValueChanged<VillageFacility> onSelect;

  const _FacilityCard({
    required this.facility,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: EdgeInsets.zero,
      color: AppTheme.surfaceAlt,
      child: InkWell(
        onTap: () => onSelect(facility),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppTheme.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
