import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/facility.dart';
import 'package:band_of_mercenaries/features/facility/domain/construction_service.dart';
import 'package:band_of_mercenaries/features/facility/view/milestone_timeline.dart';

class FacilityCard extends StatefulWidget {
  final Facility facility;
  final int currentLevel;
  final bool isConstructing;
  final bool canUpgrade;
  final VoidCallback? onUpgrade;

  const FacilityCard({
    super.key,
    required this.facility,
    required this.currentLevel,
    required this.isConstructing,
    required this.canUpgrade,
    required this.onUpgrade,
  });

  @override
  State<FacilityCard> createState() => _FacilityCardState();
}

class _FacilityCardState extends State<FacilityCard> {
  bool _isExpanded = false;

  String _effectDescription(String effectType, double value) {
    return switch (effectType) {
      'xp_bonus' => '경험치 +${(value * 100).round()}%',
      'recovery_reduction' => '회복시간 -${(value * 100).round()}%',
      'max_mercenaries' => '용병 상한 +${value.round()}명',
      'quest_count' => '퀘스트 +${value.round()}개',
      'recruit_bonus' => '고티어 모집 +${(value * 100).round()}%',
      'damage_reduction' => '여행 피해 -${(value * 100).round()}%',
      'idle_bonus' => '방치 보상 +${value.round()}G',
      'travel_reduction' => '이동시간 -${(value * 100).round()}%',
      'injury_reduction' => '부상률 -${(value * 100).round()}%',
      'equipment_bonus' => '장비 효과 +${(value * 100).round()}% (준비 중)',
      'research_efficiency' => '조사 효율 +${(value * 100).round()}% (준비 중)',
      'quest_quality' => '고보상 퀘스트 +${(value * 100).round()}% (준비 중)',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final facility = widget.facility;
    final currentLevel = widget.currentLevel;
    final isMaxLevel = currentLevel >= facility.maxLevel;
    final currentValue = ConstructionService.getEffectValue(facility, currentLevel);
    final nextCost = isMaxLevel ? null : ConstructionService.calculateCost(facility, currentLevel + 1);
    final nextBuildMinutes = isMaxLevel ? 0 : ConstructionService.calculateBuildTimeMinutes(facility, currentLevel + 1);

    String upgradeButtonText;
    if (isMaxLevel) {
      upgradeButtonText = '최대 레벨';
    } else if (widget.isConstructing) {
      upgradeButtonText = '건설 중';
    } else if (!widget.canUpgrade) {
      upgradeButtonText = '골드 부족';
    } else {
      upgradeButtonText = '업그레이드 (${nextCost}G)';
    }

    final isUpgradeEnabled = !isMaxLevel && widget.canUpgrade && !widget.isConstructing;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    facility.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isMaxLevel ? AppTheme.tier5Bg : AppTheme.tier3Bg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isMaxLevel ? 'Lv.$currentLevel (최대)' : 'Lv.$currentLevel',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isMaxLevel ? AppTheme.tier5 : AppTheme.tier3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (currentLevel > 0)
              Text(
                _effectDescription(facility.effectType, currentValue),
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              )
            else
              const Text(
                '미건설',
                style: TextStyle(fontSize: 13, color: AppTheme.textHint),
              ),
            if (!isMaxLevel && nextCost != null) ...[
              const SizedBox(height: 2),
              Text(
                '다음: ${_effectDescription(facility.effectType, ConstructionService.getEffectValue(facility, currentLevel + 1))} | ${nextCost}G | $nextBuildMinutes분',
                style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _isExpanded ? '상세 ▲' : '상세 ▼',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: isUpgradeEnabled ? widget.onUpgrade : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: Text(upgradeButtonText),
                ),
              ],
            ),
            Visibility(
              visible: _isExpanded,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (facility.description != null && facility.description!.isNotEmpty) ...[
                      Text(
                        facility.description!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                      ),
                      const SizedBox(height: 8),
                    ],
                    MilestoneTimeline(
                      milestones: facility.milestones,
                      currentLevel: currentLevel,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
