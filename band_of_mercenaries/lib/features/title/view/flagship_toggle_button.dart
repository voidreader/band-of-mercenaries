import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/title/domain/flagship_provider.dart';

/// 용병 상세 내 간판 용병 4상태 토글 버튼.
///
/// 상태 분류:
///   1. 자동 + 이 용병 간판: 라벨 표시 + [수동 고정] 버튼
///   2. 자동 + 다른 용병 간판: [★ 간판으로 지정 (수동)] 버튼
///   3. 수동 + 이 용병 간판: [간판 해제 → 자동 복귀] 버튼
///   4. 수동 + 다른 용병 간판: [★ 이 용병으로 변경] 버튼
class FlagshipToggleButton extends ConsumerWidget {
  final Mercenary mercenary;

  const FlagshipToggleButton({required this.mercenary, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider);
    final currentFlagship = ref.watch(flagshipMercenaryProvider);

    final flagshipMercId = userData?.flagshipMercId;
    final isManual = flagshipMercId != null;
    final isThisMerc = currentFlagship?.id == mercenary.id;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isThisMerc
              ? AppTheme.chainGold.withValues(alpha: 0.5)
              : AppTheme.borderLight.withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: _buildContent(context, ref, isManual: isManual, isThisMerc: isThisMerc),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref, {
    required bool isManual,
    required bool isThisMerc,
  }) {
    // 상태 1: 자동 + 이 용병 간판
    if (!isManual && isThisMerc) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '현재 자동 간판 — 이 용병이 노출 중',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.chainGold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 28,
            child: ElevatedButton(
              onPressed: () => _setManualFlagship(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.chainGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('★ 수동 간판으로 고정'),
            ),
          ),
        ],
      );
    }

    // 상태 2: 자동 + 다른 용병 간판
    if (!isManual && !isThisMerc) {
      return Center(
        child: SizedBox(
          height: 28,
          child: ElevatedButton(
            onPressed: () => _setManualFlagship(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.chainGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('★ 간판으로 지정 (수동)'),
          ),
        ),
      );
    }

    // 상태 3: 수동 + 이 용병 간판
    if (isManual && isThisMerc) {
      return Center(
        child: SizedBox(
          height: 28,
          child: OutlinedButton(
            onPressed: () => _clearFlagship(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.borderLight),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('간판 해제 → 자동 복귀'),
          ),
        ),
      );
    }

    // 상태 4: 수동 + 다른 용병 간판
    return Center(
      child: SizedBox(
        height: 28,
        child: ElevatedButton(
          onPressed: () => _setManualFlagship(context, ref),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.chainGold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            textStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('★ 이 용병으로 변경'),
        ),
      ),
    );
  }

  Future<void> _setManualFlagship(BuildContext context, WidgetRef ref) async {
    await ref.read(userDataProvider.notifier).setFlagshipMercId(mercenary.id);
    ref.read(activityLogProvider.notifier).addLog(
          '간판 용병이 ${mercenary.name}으로 지정되었다',
          ActivityLogType.titleUnlocked,
        );
  }

  Future<void> _clearFlagship(BuildContext context, WidgetRef ref) async {
    await ref.read(userDataProvider.notifier).clearFlagship();
    ref.read(activityLogProvider.notifier).addLog(
          '간판 용병 자동 선정으로 돌아왔다',
          ActivityLogType.titleUnlocked,
        );
  }
}
