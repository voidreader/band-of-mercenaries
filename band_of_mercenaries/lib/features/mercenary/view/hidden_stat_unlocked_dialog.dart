import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/hidden_stat_unlocked_provider.dart';

/// 은닉 스탯 해금 축하 다이얼로그.
///
/// [app.dart]의 `ref.listen(hiddenStatUnlockedProvider)`가 감지 →
/// `dialogQueueProvider.enqueue()` → `showDialog`로 렌더.
/// 확인 버튼 탭 시 [onDismiss]가 호출된다.
/// `barrierDismissible: true` — 우선순위 medium으로 적용.
class HiddenStatUnlockedDialog extends StatelessWidget {
  final HiddenStatUnlockEvent event;
  final VoidCallback onDismiss;

  const HiddenStatUnlockedDialog({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.hiddenStatAccent, width: 1.5),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.psychology, color: AppTheme.hiddenStatAccent),
          const SizedBox(width: 8),
          const Text('잠재력 발견'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 발견 문구
          Text(
            '${event.mercName}에게서 새로운 잠재력을 발견했습니다',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          // 스탯명 + 레벨
          Text(
            '${event.statName}  Lv.1',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.hiddenStatAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          // 설명
          Text(
            event.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          // 효과 목록
          if (event.effects.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...event.effects.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '┝ ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.hiddenStatAccent,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        line,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.hiddenStatAccent,
                        ),
                      ),
                    ),
                  ],
                ),
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
