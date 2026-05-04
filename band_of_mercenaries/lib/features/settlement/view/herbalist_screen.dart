import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/investigation/domain/settlement_trust_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/settlement/domain/herbalist_service.dart';
import 'package:band_of_mercenaries/features/settlement/domain/settlement_npc_data.dart';
import 'package:band_of_mercenaries/features/settlement/domain/village_facility.dart';
import 'package:band_of_mercenaries/features/settlement/view/herbalist_heal_dialog.dart';

class HerbalistScreen extends ConsumerWidget {
  final VoidCallback onClose;
  const HerbalistScreen({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gameTickProvider);

    final trust = ref.watch(settlementTrustProvider(GameConstants.startingRegionId));
    final level = trust.level;
    final greeting = SettlementNpcData.greetingFor(VillageFacility.herbalist, level);

    final userData = ref.watch(userDataProvider);
    final mercs = ref.watch(mercenaryListProvider);
    final now = DateTime.now();

    final cost = HerbalistService.calculateCost(level);
    final cooldownMinutes = HerbalistService.calculateCooldownMinutes(level);

    final cooldownEnd = userData?.herbalistCooldownEndTime;
    final isCooldownActive = cooldownEnd != null && now.isBefore(cooldownEnd);
    final remainingMin = isCooldownActive
        ? cooldownEnd.difference(now).inMinutes + 1
        : 0;

    final healTargets = mercs.where((m) =>
        !m.isDispatched &&
        m.status != MercenaryStatus.dead &&
        (m.status == MercenaryStatus.injured || m.status == MercenaryStatus.tired)).toList();

    final hasTargets = healTargets.isNotEmpty;
    final hasGold = (userData?.gold ?? 0) >= cost;

    final canHeal = !isCooldownActive && hasTargets && hasGold;

    String? disabledReason;
    if (!hasTargets) {
      disabledReason = '회복 대상 용병이 없습니다';
    } else if (!hasGold) {
      disabledReason = '골드가 부족합니다 (${cost}G 필요)';
    } else if (isCooldownActive) {
      disabledReason = '다음 사용까지 $remainingMin분';
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NpcHeader(greeting: greeting, level: level),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _HealButton(
                  cost: cost,
                  cooldownMinutes: cooldownMinutes,
                  canHeal: canHeal,
                  disabledReason: disabledReason,
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => HerbalistHealDialog(trustLevel: level),
                  ),
                ),
                const SizedBox(height: 8),
                _GatheringInfoTile(enabled: level >= 2),
                const SizedBox(height: 8),
                _MaterialHintTile(enabled: level >= 2),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('닫기', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NpcHeader extends StatelessWidget {
  final String greeting;
  final int level;

  const _NpcHeader({required this.greeting, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌿', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '네리스',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.tier1Bg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Text(
                        '약초상',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textHint,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '"$greeting"',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealButton extends StatelessWidget {
  final int cost;
  final int cooldownMinutes;
  final bool canHeal;
  final String? disabledReason;
  final VoidCallback onTap;

  const _HealButton({
    required this.cost,
    required this.cooldownMinutes,
    required this.canHeal,
    required this.disabledReason,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canHeal ? onTap : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            child: const Text('즉시 회복'),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${cost}G · 쿨다운 $cooldownMinutes분',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
        ),
        if (disabledReason != null) ...[
          const SizedBox(height: 2),
          Text(
            disabledReason!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.tier5),
          ),
        ],
      ],
    );
  }
}

class _GatheringInfoTile extends StatelessWidget {
  final bool enabled;

  const _GatheringInfoTile({required this.enabled});

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return _DisabledExpansionPlaceholder(label: '채집 정보 보기');
    }
    return ExpansionTile(
      title: const Text(
        '채집 정보 보기',
        style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: const [
        _InfoRow('마른 약초', '마른 초원 / 더스트빌 외곽'),
        _InfoRow('산버섯', '폐광 입구'),
        _InfoRow('접착 수액', '먼지로 덮인 길'),
      ],
    );
  }
}

class _MaterialHintTile extends StatelessWidget {
  final bool enabled;

  const _MaterialHintTile({required this.enabled});

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return _DisabledExpansionPlaceholder(label: '재료 힌트 보기');
    }
    return ExpansionTile(
      title: const Text(
        '재료 힌트 보기',
        style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: const [
        _InfoRow('회복 재료', '마른 약초·접착 수액 → 약초상에 단계 2부터 풀이 추가됩니다'),
        _InfoRow('잡재료', '파견용 식량은 마을 광장 노점에서 구매 가능합니다 (M5 예정)'),
      ],
    );
  }
}

class _DisabledExpansionPlaceholder extends StatelessWidget {
  final String label;

  const _DisabledExpansionPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.textHint),
        ),
        trailing: const Icon(Icons.lock_outline, size: 16, color: AppTheme.textHint),
        subtitle: const Text(
          '신뢰도 2단계 이상에서 해금',
          style: TextStyle(fontSize: 11, color: AppTheme.textHint),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textHint,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
