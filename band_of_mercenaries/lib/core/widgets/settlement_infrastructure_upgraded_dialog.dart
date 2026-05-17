import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/settlement/domain/infrastructure_upgrade_event.dart';
import 'package:band_of_mercenaries/features/settlement/domain/settlement_infrastructure_config.dart';

/// M7 페이즈 4 #4 — 인프라 단계 승급 다이얼로그
class SettlementInfrastructureUpgradedDialog extends StatelessWidget {
  final InfrastructureUpgradeEvent event;
  final VoidCallback onDismiss;

  const SettlementInfrastructureUpgradedDialog({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  static const Map<int, String> _tierBody = {
    2: '광장에 새 이정표가 세워졌다. 외지 용병의 활약이 마을에 변화를 가져온다.',
    3: '외래 상인의 좌판이 광장에 들어섰다. 더스트빌이 변방 생활권의 거점이 되어간다.',
    4: '광장에 영구 잔치 분위기가 감돈다. 더스트빌이 변방의 중심으로 자리매김했다.',
  };

  @override
  Widget build(BuildContext context) {
    final tierName =
        SettlementInfrastructureConfig.infraTierNames[event.toTier] ?? '';
    final body = _tierBody[event.toTier] ?? '';

    return AlertDialog(
      title: Text(
        '$tierName 단계 진입',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppTheme.chainGold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(body, style: const TextStyle(fontSize: 14)),
          if (event.rewardGold != null ||
              event.rewardXp != null ||
              event.rewardReputation != null) ...[
            const SizedBox(height: 12),
            if (event.rewardGold != null)
              Text('💰 ${event.rewardGold}G',
                  style: const TextStyle(fontSize: 13)),
            if (event.rewardXp != null)
              Text('⭐ ${event.rewardXp} XP',
                  style: const TextStyle(fontSize: 13)),
            if (event.rewardReputation != null)
              Text('🎖️ ${event.rewardReputation} 명성',
                  style: const TextStyle(fontSize: 13)),
          ],
          if (event.toTier == 4 &&
              event.grantedAchievements
                  .contains('infrastructure_tier:tier_4')) ...[
            const SizedBox(height: 8),
            const Text(
              "🏆 위업 '변방의 영주' 획득",
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.chainGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('확인'),
        ),
      ],
    );
  }
}
