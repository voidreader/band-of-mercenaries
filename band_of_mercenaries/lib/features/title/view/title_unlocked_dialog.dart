import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/title_data.dart';
import 'package:band_of_mercenaries/features/achievement/domain/mercenary_snapshot_model.dart';

/// 칭호 해금 다이얼로그 — action_stat / status hook 전용. (FR-34)
///
/// AchievementUnlockedDialog 패턴 준용. barrierDismissible: false 는 dialogQueue 에서 처리.
class TitleUnlockedDialog extends StatelessWidget {
  final TitleData title;
  final MercenarySnapshot mercSnapshot;
  final String reasonText;
  final VoidCallback onDismiss;

  const TitleUnlockedDialog({
    required this.title,
    required this.mercSnapshot,
    required this.reasonText,
    required this.onDismiss,
    super.key,
  });

  /// effectJson 첫 번째 효과를 사람이 읽기 쉬운 한 줄 문구로 변환.
  String _buildEffectLine() {
    final effects = title.effectJson['effects'];
    if (effects == null || effects is! List || effects.isEmpty) {
      return '';
    }
    final first = effects.first as Map<String, dynamic>?;
    if (first == null) return '';
    final type = first['type'] as String? ?? '';
    final value = first['value'];
    // 알려진 type 매핑
    const typeLabels = {
      'quest_reward_multiplier': '의뢰 보상',
      'success_rate_bonus': '성공률',
      'mercenary_xp_bonus': '경험치',
      'dispatch_cost_reduction': '파견 비용',
      'injury_recovery_speed': '부상 회복',
      'idle_reward_rate': '방치 보상 비율',
    };
    final label = typeLabels[type] ?? type;
    if (value == null) return label;
    final valueStr = value is double
        ? (value >= 0 ? '+${(value * 100).toStringAsFixed(0)}%' : '${(value * 100).toStringAsFixed(0)}%')
        : (value is int
            ? (value >= 0 ? '+${(value * 100)}%' : '${(value * 100)}%')
            : value.toString());
    return '$label $valueStr';
  }

  @override
  Widget build(BuildContext context) {
    final effectLine = _buildEffectLine();

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.chainGold, width: 1.5),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          const Text(
            '┝ 새로운 칭호',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.chainGold,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // 칭호명
          Text(
            title.name,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          // mercSnapshot 박스
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${mercSnapshot.name}  (T${mercSnapshot.tier} ${mercSnapshot.jobName})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (reasonText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reasonText,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 효과 한 줄
          if (effectLine.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              effectLine,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: onDismiss,
          child: const Text('확인'),
        ),
      ],
    );
  }
}
