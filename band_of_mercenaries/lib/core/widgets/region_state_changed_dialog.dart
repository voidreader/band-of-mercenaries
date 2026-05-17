import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/investigation/domain/danger_level.dart';
import 'package:band_of_mercenaries/features/investigation/domain/danger_level_changed_event.dart';

/// 지역 위험도 단계 변화 다이얼로그.
///
/// [app.dart]의 `ref.listen(dangerLevelChangedProvider)`가 감지 →
/// `dialogQueueProvider.enqueue()` → `showDialog`로 렌더.
/// 확인 버튼 탭 시 [onDismiss]가 호출되며, 호출측에서
/// `dangerLevelChangedProvider.notifier.state = null` 수행.
class RegionStateChangedDialog extends StatelessWidget {
  final DangerLevelChangedEvent event;
  final VoidCallback onDismiss;

  const RegionStateChangedDialog({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  /// 위험도 단계별 이모지
  static String _emoji(DangerLevel level) {
    return switch (level) {
      DangerLevel.stable => '🟢',
      DangerLevel.peaceful => '🟡',
      DangerLevel.tension => '🟠',
      DangerLevel.threat => '🔴',
    };
  }

  /// 위험도 단계별 캐치프레이즈
  static String _catchphrase(DangerLevel level) {
    return switch (level) {
      DangerLevel.stable => '평화로워졌다',
      DangerLevel.peaceful => '잠잠해졌다',
      DangerLevel.tension => '긴장이 감돈다',
      DangerLevel.threat => '큰 위협이 감지되었다',
    };
  }

  /// 위험도 단계별 부연 설명
  static String _subtitle(DangerLevel level) {
    return switch (level) {
      DangerLevel.stable => '지역이 완전히 안정되었다.',
      DangerLevel.peaceful => '지역의 위험도가 낮아졌다.',
      DangerLevel.tension => '지역이 불안정해지고 있다.',
      DangerLevel.threat => '지역에 심각한 위협이 발생했다.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final toColor = AppTheme.dangerLevelColor(event.to.cacheInt);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 위험도 배지 + 변화 과정
              Text(
                _emoji(event.to),
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 8),
              Text(
                event.regionName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.from.koreanLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    event.to.koreanLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: toColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // 핵심 캐치프레이즈
              Text(
                _catchphrase(event.to),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: toColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // 부연 설명
              Text(
                _subtitle(event.to),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (event.grantedAchievements.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '위업 ${event.grantedAchievements.length}개를 획득했다.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.chainGold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
