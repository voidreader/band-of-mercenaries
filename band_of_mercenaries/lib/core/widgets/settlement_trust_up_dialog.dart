import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/investigation/domain/trust_level_up_event.dart';

/// 마을 신뢰도 단계 승급 축하 다이얼로그.
///
/// [app.dart]의 `ref.listen(settlementTrustLevelUpProvider)`가 감지 →
/// `dialogQueueProvider.enqueue()` → `showDialog`로 렌더.
/// 확인 버튼 탭 시 [onDismiss]가 호출되며, 호출측에서
/// `settlementTrustLevelUpProvider.notifier.state = null` 수행.
class SettlementTrustUpDialog extends StatelessWidget {
  final TrustLevelUpEvent event;
  final VoidCallback onDismiss;

  const SettlementTrustUpDialog({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  /// 단계별 이모지
  static String _emoji(int level) {
    switch (level) {
      case 2:
        return '🌾';
      case 3:
        return '🏘️';
      case 4:
        return '🏘️';
      default:
        return '🌾';
    }
  }

  /// 단계명
  static String _levelName(int level) {
    switch (level) {
      case 1:
        return '의심';
      case 2:
        return '인지';
      case 3:
        return '친근';
      case 4:
        return '소속';
      default:
        return '의심';
    }
  }

  /// 단계별 핵심 캐치프레이즈
  static String _catchphrase(int level) {
    switch (level) {
      case 2:
        return '쓸 만한 외지인';
      case 3:
        return '이웃처럼 대해주는';
      case 4:
        return '이제 우리 마을 사람';
      default:
        return '낯선 외지인';
    }
  }

  /// 단계별 부연 설명
  static String _subtitle(int level) {
    switch (level) {
      case 2:
        return '마을 사람들이 일을 맡기기 시작했다.';
      case 3:
        return '마을 사람들이 친근하게 인사한다.';
      case 4:
        return '폐광이 다시 열렸다. 광장에서 잔치가 열린다.';
      default:
        return '마을 사람들이 경계한다.';
    }
  }

  /// 단계별 배지 색상.
  /// AppTheme에 secondary/tertiary 정적 상수가 없으므로 colorScheme에서 조회.
  static Color _badgeColor(int level, ColorScheme colorScheme) {
    switch (level) {
      case 1:
        return AppTheme.surface;
      case 2:
        return colorScheme.secondary;
      case 3:
        return colorScheme.tertiary;
      case 4:
        return AppTheme.primary;
      default:
        return AppTheme.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final badgeColor = _badgeColor(event.toLevel, colorScheme);
    // 배지 배경이 어두운 경우(primary = 0xFF1A1A1A) 글자를 흰색으로 처리
    final badgeTextColor =
        badgeColor.computeLuminance() < 0.3 ? Colors.white : AppTheme.textPrimary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 단계 배지 + 단계명
              _LevelBadge(
                emoji: _emoji(event.toLevel),
                levelName: _levelName(event.toLevel),
                settlementName: event.settlementName,
                badgeColor: badgeColor,
                badgeTextColor: badgeTextColor,
              ),
              const SizedBox(height: 8),
              // 핵심 캐치프레이즈
              Text(
                _catchphrase(event.toLevel),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // 부연 설명
              Text(
                _subtitle(event.toLevel),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // 보상 섹션 (값이 있는 항목만 표시)
              _RewardSection(event: event, theme: theme),
              const SizedBox(height: 16),
              // 확인 버튼
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onDismiss,
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 단계 배지 헤더 위젯 (이모지 + 거점명 + 단계명).
class _LevelBadge extends StatelessWidget {
  final String emoji;
  final String levelName;
  final String settlementName;
  final Color badgeColor;
  final Color badgeTextColor;

  const _LevelBadge({
    required this.emoji,
    required this.levelName,
    required this.settlementName,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 40),
        ),
        const SizedBox(height: 8),
        Text(
          settlementName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '신뢰도 단계: $levelName',
            style: theme.textTheme.labelMedium?.copyWith(
              color: badgeTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// 보상 섹션 — non-null이고 > 0인 항목만 렌더.
class _RewardSection extends StatelessWidget {
  final TrustLevelUpEvent event;
  final ThemeData theme;

  const _RewardSection({required this.event, required this.theme});

  @override
  Widget build(BuildContext context) {
    final hasGold = (event.rewardGold ?? 0) > 0;
    final hasXp = (event.rewardXp ?? 0) > 0;
    final hasRep = (event.rewardReputation ?? 0) > 0;

    if (!hasGold && !hasXp && !hasRep) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasGold)
          _RewardRow(
            icon: Icons.monetization_on_outlined,
            label: '보너스 골드 +${event.rewardGold}G',
            theme: theme,
          ),
        if (hasXp) ...[
          if (hasGold) const SizedBox(height: 4),
          _RewardRow(
            icon: Icons.star_border_rounded,
            label: '용병 경험치 +${event.rewardXp} XP',
            theme: theme,
          ),
        ],
        if (hasRep) ...[
          if (hasGold || hasXp) const SizedBox(height: 4),
          _RewardRow(
            icon: Icons.shield_outlined,
            label: '명성 +${event.rewardReputation}',
            theme: theme,
          ),
        ],
      ],
    );
  }
}

/// 보상 한 줄 표시 위젯.
class _RewardRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _RewardRow({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text(
          '→ $label',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
