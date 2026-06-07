// M8.5 페이즈 4 #4 — 용병 상세 히든 스탯 섹션
// lv1+ 해금된 스탯만 카드로 표시. 전체 lv0이면 SizedBox.shrink() 반환.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/models/hidden_stat_data.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

/// 용병 상세 오버레이의 히든 스탯 섹션.
/// hiddenStatAccent(보라) border + 헤더 + lv1+ 스탯 카드 × N.
/// 해금된 스탯이 0개이면 SizedBox.shrink() 반환.
class HiddenStatsSection extends ConsumerWidget {
  final Mercenary merc;

  const HiddenStatsSection({required this.merc, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(staticDataProvider).valueOrNull;
    if (staticData == null) return const SizedBox.shrink();

    final allStats = staticData.hiddenStats;
    if (allStats.isEmpty) return const SizedBox.shrink();

    // lv1+ 해금된 스탯만 필터링
    final unlockedStats = allStats
        .where((s) => (merc.hiddenStats[s.id] ?? 0) >= 1)
        .toList();

    // 해금된 스탯이 없으면 섹션 전체 숨김
    if (unlockedStats.isEmpty) return const SizedBox.shrink();

    // 콘텐츠가 있을 때만 상단 16px 간격 포함 (overlay에서 SizedBox 생략 대응)
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.hiddenStatAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.hiddenStatAccent, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Text(
              '✦ 히든 스탯 ${unlockedStats.length}종',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.hiddenStatAccent,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            // 해금된 스탯 카드 목록
            ...unlockedStats.asMap().entries.map((entry) {
              final idx = entry.key;
              final stat = entry.value;
              return Padding(
                padding: EdgeInsets.only(top: idx == 0 ? 0 : 6),
                child: _HiddenStatCard(stat: stat, merc: merc),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// 히든 스탯 1개 카드.
/// iconKey 기반 아이콘 + 이름 lv{n} + 진행도 바 + 효과 줄.
class _HiddenStatCard extends StatelessWidget {
  final HiddenStatData stat;
  final Mercenary merc;

  const _HiddenStatCard({required this.stat, required this.merc});

  // combatEffectsJson / passiveEffectsJson / postRewardEffectsJson 키→한국어 라벨 매핑.
  // 값은 per-lv 배율. 실제 수치 = value × lv.
  static const Map<String, String> _combatEffectLabels = {
    'death_resistance': '사망 저항',
    'despair_immune_chance': '절망 면제',
    'critical_rate': '치명타',
    'evasion': '회피',
    'mez_immune_chance': 'mez 면제',
    'strong_attack_evasion': '강공격 회피',
    'action_score': '행동 우선순위',
    'featured_score': '결정적 장면',
    'hit_chance': '명중',
  };

  static const Map<String, String> _passiveEffectTypeLabels = {
    'recovery_time_reduction': '부상 회복',
    'reputation_gain_modifier': '명성 가산',
  };

  static const Map<String, String> _postRewardEffectLabels = {
    'item_drop_chance': '드랍 보너스',
  };

  /// 수치를 퍼센트 문자열로 변환. 1.0 이상이면 정수형으로 표시.
  String _fmtValue(num raw) {
    if (raw >= 1.0 || raw <= -1.0) {
      final intVal = raw.round();
      return intVal >= 0 ? '+$intVal' : '$intVal';
    }
    final pct = raw * 100;
    final rounded = pct.toStringAsFixed(0);
    return pct >= 0 ? '+$rounded%' : '$rounded%';
  }

  /// lv 기준 효과 줄 목록 생성.
  List<String> _buildEffectLines(int lv) {
    final lines = <String>[];

    // 1. combat_effects_json — 평면 맵 {"key": perLvValue}
    final combat = stat.combatEffectsJson;
    for (final entry in combat.entries) {
      final perLv = entry.value;
      final total = (perLv is num) ? perLv * lv : 0;
      final label = _combatEffectLabels[entry.key] ?? entry.key;
      lines.add('$label ${_fmtValue(total)}');
    }

    // 2. passive_effects_json — {"effects": [{"type": ..., "status"?: ..., "value": ...}]}
    final passive = stat.passiveEffectsJson;
    if (passive != null) {
      final effects = passive['effects'];
      if (effects is List) {
        for (final eff in effects) {
          if (eff is! Map) continue;
          final type = eff['type'] as String? ?? '';
          final perLv = eff['value'];
          if (perLv is! num) continue;
          final total = perLv * lv;
          final label = _passiveEffectTypeLabels[type] ?? type;
          lines.add('$label ${_fmtValue(total)}');
        }
      }
    }

    // 3. post_reward_effects_json — 평면 맵 {"key": perLvValue}
    final post = stat.postRewardEffectsJson;
    if (post != null) {
      for (final entry in post.entries) {
        final perLv = entry.value;
        final total = (perLv is num) ? perLv * lv : 0;
        final label = _postRewardEffectLabels[entry.key] ?? entry.key;
        lines.add('$label ${_fmtValue(total)} (후처리)');
      }
    }

    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final lv = merc.hiddenStats[stat.id] ?? 0;
    final counter = merc.stats[stat.counterKey] ?? 0;
    final thresholds = stat.levelThresholds;
    final isMax = lv >= thresholds.length;

    // 진행도 계산: lv5(max)는 충만, 나머지는 현재 카운트 / 다음 임계
    double progress;
    String progressLabel;
    if (isMax) {
      progress = 1.0;
      progressLabel = '★ 최대 도달';
    } else {
      final nextThreshold = thresholds[lv]; // lv는 0-based index 아님 — lv1이면 index 1
      final prevThreshold = lv > 0 ? thresholds[lv - 1] : 0;
      final span = nextThreshold - prevThreshold;
      final current = (counter - prevThreshold).clamp(0, span);
      progress = span > 0 ? (current / span).clamp(0.0, 1.0) : 0.0;
      progressLabel = '$counter / $nextThreshold';
    }

    // iconKey: 이모지 1자이면 그대로, 아니면 기본 아이콘
    final iconKey = stat.iconKey;
    final bool hasEmoji =
        iconKey.isNotEmpty && iconKey != 'default' && iconKey.runes.length == 1;

    final effectLines = _buildEffectLines(lv);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.hiddenStatAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 행: 아이콘 + 이름 + lv
          Row(
            children: [
              if (hasEmoji)
                Text(iconKey, style: const TextStyle(fontSize: 14))
              else
                const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: AppTheme.hiddenStatAccent,
                ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${stat.name} lv$lv',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.hiddenStatAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // lv5 최대 배지
              if (isMax)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.hiddenStatAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    '★ 최대 도달',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.hiddenStatAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          // 진행도 바 + 라벨
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor:
                        AppTheme.hiddenStatAccent.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.hiddenStatAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                progressLabel,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textHint,
                ),
              ),
            ],
          ),
          // 효과 줄
          if (effectLines.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...effectLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  line,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
