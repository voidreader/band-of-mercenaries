import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speedMult = ref.watch(speedMultiplierProvider);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('설정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          const Text('시간 가속 모드', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('개발/테스트용 시간 가속 설정', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final speed in [1.0, 10.0, 100.0])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: speed == speedMult
                        ? ElevatedButton(
                            onPressed: () {},
                            child: Text('x${speed.toInt()}'),
                          )
                        : OutlinedButton(
                            onPressed: () => ref.read(speedMultiplierProvider.notifier).state = speed,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppTheme.border),
                            ),
                            child: Text('x${speed.toInt()}', style: const TextStyle(color: AppTheme.textSecondary)),
                          ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('현재 배속: x${speedMult.toInt()}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
        ],
      ),
    );
  }
}
