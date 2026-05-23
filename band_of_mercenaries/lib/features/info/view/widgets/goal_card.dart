import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/providers/navigation_provider.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/crafting/domain/material_jump_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_codex_providers.dart';
import 'package:band_of_mercenaries/features/info/domain/info_screen_auto_show_providers.dart';
import 'package:band_of_mercenaries/features/info/domain/livingsphere_dashboard_models.dart';
import 'package:band_of_mercenaries/features/movement/domain/livingsphere_movement_target_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/dispatch_focus_provider.dart';
import 'package:band_of_mercenaries/features/settlement/domain/settlement_facility_target_provider.dart';
import 'package:band_of_mercenaries/features/settlement/domain/village_facility.dart';

/// 30분/8시간 목표 카드 — LivingsphereDetailScreen에서 2종 노출.
/// 자동 추천(▶) 또는 핀(★) 후보, 대안 3개, 점프 버튼, fallback stub.
class GoalCard extends ConsumerWidget {
  final GoalRecommendation recommendation;

  /// 핀 토글 콜백 (null이면 핀 버튼 미표시).
  final VoidCallback? onPinToggle;

  const GoalCard({
    super.key,
    required this.recommendation,
    this.onPinToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slot = recommendation.slot;
    final slotLabel =
        slot == GoalSlot.short30Min ? '다음 30분 목표' : '다음 8시간 목표';
    final primary = recommendation.primary;

    return Card(
      elevation: 0,
      color: AppTheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 $slotLabel',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (recommendation.isFallback)
              _buildFallback(context, ref, slot)
            else if (primary != null) ...[
              _buildPrimaryRow(context, ref, primary, recommendation.pinned),
              if (recommendation.alternatives.isNotEmpty) ...[
                const Divider(height: 16),
                ...recommendation.alternatives
                    .map((candidate) => _buildAlternativeRow(context, ref, candidate)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryRow(
    BuildContext context,
    WidgetRef ref,
    GoalCandidate primary,
    bool pinned,
  ) {
    return Row(
      children: [
        Text(
          pinned ? '★' : '▶',
          style: const TextStyle(fontSize: 14, color: AppTheme.chainGold),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            primary.label,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onPinToggle != null)
          TextButton(
            onPressed: onPinToggle,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(48, 36),
            ),
            child: Text(
              pinned ? '핀 해제' : '★ 핀 고정',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        if (primary.jumpTarget != null)
          IconButton(
            icon: const Icon(Icons.arrow_forward, size: 18),
            onPressed: () => _executeJump(ref, primary.jumpTarget!),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: '이동',
          ),
      ],
    );
  }

  Widget _buildAlternativeRow(
    BuildContext context,
    WidgetRef ref,
    GoalCandidate candidate,
  ) {
    return InkWell(
      onTap: candidate.jumpTarget != null
          ? () => _executeJump(ref, candidate.jumpTarget!)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Text(
              '○ ',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            Expanded(
              child: Text(
                candidate.label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context, WidgetRef ref, GoalSlot slot) {
    final label = slot == GoalSlot.short30Min
        ? '다음 의뢰를 시작하세요'
        : '위업 컬렉션을 채워보세요';
    final jumpTarget = slot == GoalSlot.short30Min
        ? const GoalJumpTarget.dispatch()
        : const GoalJumpTarget.chronicle();

    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        TextButton(
          onPressed: () => _executeJump(ref, jumpTarget),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(48, 36),
          ),
          child: const Text('→ 이동', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  /// GoalJumpTarget sealed switch — 점프 액션 실행.
  /// target provider publish + currentTabProvider 변경.
  void _executeJump(WidgetRef ref, GoalJumpTarget target) {
    switch (target) {
      case GoalJumpTargetMovement():
        if (target.regionId != null) {
          ref.read(livingsphereMovementTargetProvider.notifier).state =
              target.regionId;
        }
        ref.read(currentTabProvider.notifier).state = 0;
      case GoalJumpTargetDispatch():
        if (target.questPoolId != null) {
          ref.read(dispatchFocusQuestPoolIdProvider.notifier).state =
              target.questPoolId;
        }
        ref.read(currentTabProvider.notifier).state = 1;
      case GoalJumpTargetSettlementFacility():
        ref.read(livingsphereMovementTargetProvider.notifier).state =
            target.regionId;
        ref.read(settlementFacilityTargetProvider.notifier).state =
            target.facility;
        ref.read(currentTabProvider.notifier).state = 0;
      case GoalJumpTargetInventory():
        if (target.itemId != null) {
          ref.read(materialJumpTargetItemIdProvider.notifier).state =
              target.itemId;
        } else {
          ref.read(infoScreenAutoShowInventoryProvider.notifier).state = true;
        }
        ref.read(currentTabProvider.notifier).state = 5;
      case GoalJumpTargetSmithy():
        ref.read(livingsphereMovementTargetProvider.notifier).state = 3;
        ref.read(settlementFacilityTargetProvider.notifier).state =
            VillageFacility.oldSmithy;
        ref.read(currentTabProvider.notifier).state = 0;
      case GoalJumpTargetFaction():
        if (target.factionId != null) {
          ref.read(factionCodexScrollTargetProvider.notifier).state =
              target.factionId;
        } else {
          ref.read(infoScreenAutoShowCodexProvider.notifier).state = true;
        }
        ref.read(currentTabProvider.notifier).state = 5;
      case GoalJumpTargetChronicle():
        ref.read(infoScreenAutoShowChronicleProvider.notifier).state = true;
        ref.read(currentTabProvider.notifier).state = 5;
    }
  }
}
