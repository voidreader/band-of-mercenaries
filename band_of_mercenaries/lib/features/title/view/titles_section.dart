import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/models/title_data.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/title/domain/title_provider.dart';
import 'package:band_of_mercenaries/features/title/view/flagship_toggle_button.dart';

/// 용병 상세 오버레이의 칭호 섹션.
/// chainGold border + 헤더 + TitleCard × N + FlagshipToggleButton.
/// titleIds가 비어있으면 안내 문구 표시.
class TitlesSection extends ConsumerWidget {
  final Mercenary mercenary;

  const TitlesSection({required this.mercenary, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titles = ref.watch(mercenaryTitlesProvider(mercenary.id));

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.chainGold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.chainGold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Text(
            '★ 칭호 ${titles.length}종',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.chainGold,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          // 칭호 목록 또는 빈 상태
          if (titles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '아직 칭호가 없습니다 — 위업으로 이름을 남겨 보세요',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textHint,
                ),
              ),
            )
          else
            ...titles.asMap().entries.map((entry) {
              final idx = entry.key;
              final title = entry.value;
              return Padding(
                padding: EdgeInsets.only(top: idx == 0 ? 0 : 4),
                child: _TitleCard(title: title),
              );
            }),
          const SizedBox(height: 8),
          // 간판 토글 버튼
          FlagshipToggleButton(mercenary: mercenary),
        ],
      ),
    );
  }
}

/// 칭호 1개 카드.
class _TitleCard extends StatelessWidget {
  final TitleData title;

  const _TitleCard({required this.title});

  /// effectJson 첫 번째 효과를 한 줄 문구로 변환.
  /// TitleUnlockedDialog._buildEffectLine 패턴 준용.
  String _buildEffectLine() {
    final effects = title.effectJson['effects'];
    if (effects == null || effects is! List || effects.isEmpty) return '';
    final first = effects.first as Map<String, dynamic>?;
    if (first == null) return '';
    final type = first['type'] as String? ?? '';
    final value = first['value'];
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
        ? (value >= 0
            ? '+${(value * 100).toStringAsFixed(0)}%'
            : '${(value * 100).toStringAsFixed(0)}%')
        : (value is int
            ? (value >= 0 ? '+${(value * 100)}%' : '${(value * 100)}%')
            : value.toString());
    return '$label $valueStr';
  }

  @override
  Widget build(BuildContext context) {
    final effectLine = _buildEffectLine();
    final iconKey = title.iconKey;
    // iconKey가 이모지 1자이면 그대로 표시, 아니면 SizedBox
    final bool hasEmoji = iconKey.isNotEmpty &&
        iconKey != 'default' &&
        iconKey.runes.length == 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 아이콘
          if (hasEmoji)
            Text(iconKey, style: const TextStyle(fontSize: 14))
          else
            const SizedBox(width: 14),
          const SizedBox(width: 6),
          // 이름 + narrativeHint
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.chainGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (title.narrativeHint != null &&
                    title.narrativeHint!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    title.narrativeHint!,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 효과 한 줄
          if (effectLine.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              effectLine,
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
