import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_effect_service.dart';
import 'package:band_of_mercenaries/features/quest/domain/role_synergy_matrix.dart';
import 'package:band_of_mercenaries/features/quest/domain/role_utils.dart';

class MercenarySynergySection extends StatelessWidget {
  final Mercenary merc;
  final dynamic job;
  final List<TraitData> allTraits;

  const MercenarySynergySection({
    super.key,
    required this.merc,
    required this.job,
    required this.allTraits,
  });

  static String _questKoreanName(String typeId) {
    switch (typeId) {
      case 'raid':
        return '약탈';
      case 'hunt':
        return '토벌';
      case 'escort':
        return '호위';
      case 'explore':
        return '탐험';
      default:
        return typeId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = job?.role as String? ?? 'specialist';
    final traitIds = merc.allTraitIds;
    const questTypes = ['raid', 'hunt', 'escort', 'explore'];

    final traitRows = <Widget>[];
    for (final typeId in questTypes) {
      final bonus = TraitEffectService.calculateSuccessRateBonus(
        traitIds: traitIds,
        allTraits: allTraits,
        questTypeId: typeId,
        partySize: 1,
      );
      if (bonus.abs() >= 0.1) {
        traitRows.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '${_questKoreanName(typeId)}: ${bonus > 0 ? '+' : ''}${bonus.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ));
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이 용병의 상성 (${RoleUtils.koreanName(role)})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final typeId in questTypes)
                  MercenaryRoleBonusChip(
                    label: _questKoreanName(typeId),
                    bonus: RoleSynergyMatrix.singleBonus(role, typeId),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '트레잇 시너지',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            if (traitRows.isEmpty)
              Text(
                '해당 없음',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: traitRows,
              ),
          ],
        ),
      ),
    );
  }
}

class MercenaryRoleBonusChip extends StatelessWidget {
  final String label;
  final double bonus;
  const MercenaryRoleBonusChip({super.key, required this.label, required this.bonus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    if (bonus >= 5) {
      color = theme.colorScheme.primary;
    } else if (bonus < 0) {
      color = theme.colorScheme.error;
    } else {
      color = theme.textTheme.bodyMedium?.color ?? Colors.black;
    }
    final sign = bonus > 0 ? '+' : '';
    return Text(
      '$label $sign${bonus.toStringAsFixed(0)}',
      style: theme.textTheme.bodyMedium?.copyWith(color: color),
    );
  }
}
