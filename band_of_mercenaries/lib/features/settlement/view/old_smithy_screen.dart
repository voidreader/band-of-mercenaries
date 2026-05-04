import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/features/investigation/domain/settlement_trust_provider.dart';
import 'package:band_of_mercenaries/features/settlement/domain/settlement_npc_data.dart';
import 'package:band_of_mercenaries/features/settlement/domain/village_facility.dart';

class OldSmithyScreen extends ConsumerWidget {
  final VoidCallback onClose;
  const OldSmithyScreen({super.key, required this.onClose});

  int _repairReward(int level) {
    if (level >= 4) return 60;
    if (level >= 3) return 50;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustInfo = ref.watch(settlementTrustProvider(GameConstants.startingRegionId));
    final level = trustInfo.level;
    final userData = ref.watch(userDataProvider);

    ref.watch(gameTickProvider);

    final DateTime? lastRepairAt = userData?.lastSmithyRepairAt;
    final bool repairCooldownExpired = lastRepairAt == null ||
        DateTime.now().difference(lastRepairAt) >= const Duration(hours: 24);

    Duration? remainingCooldown;
    if (!repairCooldownExpired) {
      final nextAvailableAt = lastRepairAt.add(const Duration(hours: 24));
      final remaining = nextAvailableAt.difference(DateTime.now());
      remainingCooldown = remaining.isNegative ? null : remaining;
    }

    final greeting = SettlementNpcData.greetingFor(VillageFacility.oldSmithy, level);
    final reward = _repairReward(level);

    return Scaffold(
      appBar: AppBar(
        title: const Text('낡은 대장간'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onClose,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NpcHeader(greeting: greeting),
            const SizedBox(height: 16),
            _CraftGoalTile(unlocked: level >= 2),
            const SizedBox(height: 8),
            _RepairMissionTile(
              unlocked: level >= 3,
              cooldownExpired: repairCooldownExpired,
              remainingCooldown: remainingCooldown,
              reward: reward,
              onClaim: () async {
                await ref.read(userDataProvider.notifier).addGold(reward);
                await ref.read(userDataProvider.notifier).setSmithyRepairAt(DateTime.now());
                ref.read(activityLogProvider.notifier).addLog(
                  '낡은 대장간 수리 의뢰 완료 (+${reward}G)',
                  ActivityLogType.smithyRepairCompleted,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('+${reward}G 획득'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            _MaterialHintTile(unlocked: level >= 2),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onClose,
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
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

class _CraftGoalTile extends StatelessWidget {
  final bool unlocked;
  const _CraftGoalTile({required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      enabled: unlocked,
      title: Text(
        '제작 목표 보기',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: unlocked ? AppTheme.textPrimary : AppTheme.textHint,
        ),
      ),
      trailing: unlocked ? null : const Icon(Icons.lock_outline, size: 18, color: AppTheme.textHint),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '광부의 단검 (녹슨 쇳조각 ×3 / 마른 가죽끈 ×1)',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              SizedBox(height: 4),
              Text(
                '수습대장의 검 (녹슨 쇳조각 ×5 / 가죽끈 ×2)',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              SizedBox(height: 8),
              Text(
                'M5 제작 시스템에서 활성화됩니다.',
                style: TextStyle(fontSize: 12, color: AppTheme.textHint),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RepairMissionTile extends StatelessWidget {
  final bool unlocked;
  final bool cooldownExpired;
  final Duration? remainingCooldown;
  final int reward;
  final VoidCallback onClaim;

  const _RepairMissionTile({
    required this.unlocked,
    required this.cooldownExpired,
    required this.remainingCooldown,
    required this.reward,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final bool canClaim = unlocked && cooldownExpired;

    String buttonLabel;
    if (!unlocked) {
      buttonLabel = '수리 의뢰 확인 (단계 3 해금)';
    } else if (!cooldownExpired && remainingCooldown != null) {
      final hours = remainingCooldown!.inHours;
      final minutes = remainingCooldown!.inMinutes % 60;
      buttonLabel = '다음 의뢰까지 $hours시간 $minutes분';
    } else {
      buttonLabel = '수리 의뢰 확인 (+${reward}G)';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '수리 의뢰',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (unlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.tier2Bg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '+${reward}G',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.tier2,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canClaim ? onClaim : null,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialHintTile extends StatelessWidget {
  final bool unlocked;
  const _MaterialHintTile({required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      enabled: unlocked,
      title: Text(
        '재료 힌트 보기',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: unlocked ? AppTheme.textPrimary : AppTheme.textHint,
        ),
      ),
      trailing: unlocked ? null : const Icon(Icons.lock_outline, size: 18, color: AppTheme.textHint),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '폐광 (섹터 2): 녹슨 쇳조각 / 낡은 곡괭이',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              SizedBox(height: 4),
              Text(
                '마른 초원 (섹터 3): 마른 가죽끈',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              SizedBox(height: 4),
              Text(
                '먼지로 덮인 길 (섹터 4): 여행자 짐 더미',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              SizedBox(height: 4),
              Text(
                '더스트빌 (섹터 1): 일상 잡재료',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
