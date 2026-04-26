import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/domain/template_context.dart';
import 'package:band_of_mercenaries/core/providers/template_engine_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/models/travel_choice_option_data.dart';
import 'package:band_of_mercenaries/core/models/travel_choice_result_data.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_provider.dart';
import 'package:band_of_mercenaries/features/movement/domain/travel_choice_recall_provider.dart';
import 'package:band_of_mercenaries/features/movement/domain/travel_choice_service.dart';

class TravelChoiceRecallDialog extends ConsumerStatefulWidget {
  final TravelChoiceRecallData data;
  final VoidCallback onDismiss;

  const TravelChoiceRecallDialog({
    required this.data,
    required this.onDismiss,
    super.key,
  });

  @override
  ConsumerState<TravelChoiceRecallDialog> createState() =>
      _TravelChoiceRecallDialogState();
}

class _TravelChoiceRecallDialogState
    extends ConsumerState<TravelChoiceRecallDialog> {
  int _stage = 0;
  TravelChoiceOptionData? _selectedOption;
  TravelChoiceResultData? _resolvedResult;
  String _renderedNarrative = '';

  Future<void> _onOptionSelected(TravelChoiceOptionData option) async {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return;

    final engine = ref.read(templateEngineProvider);
    final userData = ref.read(userDataProvider);
    if (userData == null) return;

    final region = staticData.regions
        .where((r) => r.region == userData.region)
        .firstOrNull;

    final mercCtx = TemplateContext(
      user: userData,
      merc: widget.data.protagonist,
      region: region,
      evaluationScope: EvaluationScope.mercenary,
    );

    final resolved = TravelChoiceService.resolveResult(
      option: option,
      allResults: staticData.travelChoiceResults,
      engine: engine,
      mercContext: mercCtx,
      random: Random(),
    );

    await ref
        .read(movementProvider.notifier)
        .applyTravelChoiceEffect(resolved, widget.data.protagonist);

    if (!mounted) return;

    final renderedNarrative = engine.render(resolved.narrative, mercCtx);

    ref.read(activityLogProvider.notifier).addLog(
      '길에서 ${widget.data.event.name} — [${option.label}] → ${TravelChoiceService.summarizeEffect(resolved)}',
      ActivityLogType.travelChoiceCompleted,
    );

    setState(() {
      _resolvedResult = resolved;
      _renderedNarrative = renderedNarrative;
      _selectedOption = option;
      _stage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == 0) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(widget.data.event.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.data.renderedSituation,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _OptionButtonsSection(
                normalOptions: widget.data.visibleOptions
                    .where((o) => o.riskLevel != 'hidden')
                    .toList(),
                hiddenOptions: widget.data.hiddenOptions,
                onSelected: _onOptionSelected,
              ),
            ],
          ),
        ),
      );
    }

    final result = _resolvedResult!;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        _selectedOption?.label ?? widget.data.event.name,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Text(
                _renderedNarrative,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _EffectSummaryRow(result: result),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onDismiss,
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButtonsSection extends StatelessWidget {
  final List<TravelChoiceOptionData> normalOptions;
  final List<TravelChoiceOptionData> hiddenOptions;
  final void Function(TravelChoiceOptionData) onSelected;

  const _OptionButtonsSection({
    required this.normalOptions,
    required this.hiddenOptions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (normalOptions.isNotEmpty)
          Row(
            children: [
              for (int i = 0; i < normalOptions.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onSelected(normalOptions[i]),
                    child: Text(
                      normalOptions[i].label,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ],
          ),
        for (final option in hiddenOptions) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => onSelected(option),
            child: Text('✦ ${option.label}'),
          ),
        ],
      ],
    );
  }
}

class _EffectSummaryRow extends StatelessWidget {
  final TravelChoiceResultData result;

  const _EffectSummaryRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = _buildEffect();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (String, String, Color) _buildEffect() {
    final mag = result.effectMagnitude;
    switch (result.effectType) {
      case 'gold':
        final sign = mag >= 0 ? '+' : '';
        return ('💰', '골드 $sign${mag.toInt()}', mag >= 0 ? AppTheme.success : AppTheme.failure);
      case 'reputation':
        final sign = mag >= 0 ? '+' : '';
        return ('⭐', '명성 $sign${mag.toInt()}', AppTheme.tier4);
      case 'injury':
        return ('🩹', '부상', AppTheme.failure);
      case 'heal_tired':
        return mag > 0
            ? ('💚', '피로 회복', AppTheme.success)
            : ('😓', '피로 부여', AppTheme.failure);
      case 'trait_innate':
        return ('✨', '선천 트레잇 획득', AppTheme.tier3);
      case 'trait_acquired':
        return ('📚', '트레잇 학습 가속 24h', AppTheme.timerBlue);
      case 'item':
        return ('🎁', '아이템 획득', AppTheme.tier2);
      default:
        return ('—', '아무 일 없음', AppTheme.textHint);
    }
  }
}
