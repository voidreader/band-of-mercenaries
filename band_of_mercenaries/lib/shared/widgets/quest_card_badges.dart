import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/models/dialog_request.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_data.dart';

/// 퀘스트 카드 배지를 왼→오른쪽 순서로 렌더하는 공유 위젯.
/// 체인 → 지명 → 엘리트 → 변형 섹터 → 세력 순으로 표시.
class QuestCardBadges extends StatelessWidget {
  final QuestLayerInfo info;

  /// Wrap의 가로 간격
  final double spacing;

  /// Wrap의 줄 간격
  final double runSpacing;

  const QuestCardBadges({
    super.key,
    required this.info,
    this.spacing = 6.0,
    this.runSpacing = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];

    // 1. 체인 배지: [체인명 · N/M]
    if (info.chain != null) {
      badges.add(_chainBadge(info.chain!));
    }
    // 2. 지명 배지: ✩ 지명 + hook 서브라벨 (M6 페이즈 4 #3)
    if (info.isNamed) {
      badges.add(_namedBadge(info.namedSublabel));
    }
    // 3. 엘리트 배지: 🔥(보통) / ★(유니크)
    if (info.isElite) {
      badges.add(_eliteBadge(info.isUnique));
    }
    // 4. 변형 섹터 배지: 🏘️/🏛️/✦
    if (info.sectorType != null) {
      badges.add(_sectorBadge(info.sectorType!));
    }
    // 5. 세력 배지: 컬러 원형 + 세력명 (6자 초과 시 앞 3자 + …)
    if (info.faction != null) {
      badges.add(_factionBadge(info.faction!));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: badges,
    );
  }

  Widget _chainBadge(ChainQuestInfo chain) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.chainGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.chainGold, width: 1),
      ),
      child: Text(
        '${chain.chainName} · ${chain.currentStep}/${chain.totalSteps}',
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.chainGold,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 지명 배지: ✩ 지명 + hook 서브라벨 (M6 페이즈 4 #3)
  Widget _namedBadge(String? sublabel) {
    final label = sublabel != null ? '✩ 지명 · $sublabel' : '✩ 지명';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.namedAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.namedAccent, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.namedAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _eliteBadge(bool isUnique) {
    final emoji = isUnique ? '★' : '🔥';
    final color = isUnique ? AppTheme.eliteUniqueAccent : AppTheme.eliteAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        emoji,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _sectorBadge(String sectorType) {
    final emoji = switch (sectorType) {
      'village' => '🏘️',
      'ruins' => '🏛️',
      'hidden' => '✦',
      _ => '?',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _factionBadge(FactionData faction) {
    final color = FactionData.parseColor(faction.color);
    final name = faction.name.length > 6
        ? '${faction.name.substring(0, 3)}…'
        : faction.name;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
