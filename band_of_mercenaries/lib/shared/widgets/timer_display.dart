import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';

class TimerDisplay extends StatelessWidget {
  final Duration remaining;
  final String label;

  const TimerDisplay({super.key, required this.remaining, required this.label});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        Text(
          '${_formatDuration(remaining)} 남음',
          style: const TextStyle(fontSize: 14, color: AppTheme.timerBlue, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
