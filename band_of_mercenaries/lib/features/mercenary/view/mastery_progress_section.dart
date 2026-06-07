import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/models/title_data.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/title/domain/title_provider.dart';

/// 솔로/소수정예 개인 숙련도 섹션 (FR-4, FR-4a).
///
/// 4 카운터(solo_completion_count / solo_great_success_count /
/// pair_completion_count / small_party_count) 요약과
/// 전용 4 칭호 진행도를 표시한다.
///
/// 전 카운터 0 AND 전용 칭호 진행 0이면 [SizedBox.shrink()] 반환 — 노이즈 방지.
class MasteryProgressSection extends ConsumerWidget {
  final Mercenary merc;

  const MasteryProgressSection({required this.merc, super.key});

  /// 전용 4 칭호 ID (순서 고정).
  static const _masteryTitleIds = [
    'title_lone_wolf',
    'title_silver_pair',
    'title_three_kings',
    'title_unyielding_solo',
  ];

  /// FR-4a: hookCondition 추출 실패 시 사용하는 상수 fallback 테이블.
  /// key: titleId → (stat_key, threshold)
  static const _fallbackThresholds = <String, (String, int)>{
    'title_lone_wolf': ('solo_completion_count', 5),
    'title_silver_pair': ('pair_completion_count', 8),
    'title_three_kings': ('small_party_count', 10),
    'title_unyielding_solo': ('solo_great_success_count', 1),
  };

  /// hookCondition에서 stat_key와 threshold를 동적 추출.
  /// 추출 실패 시 fallback 상수 테이블에서 반환.
  (String, int)? _resolveStatKey(TitleData title) {
    final cond = title.hookCondition;
    final statKey = cond['stat_key'] as String?;
    final rawThreshold = cond['threshold'];
    if (statKey != null && rawThreshold != null) {
      final threshold = rawThreshold is int
          ? rawThreshold
          : (rawThreshold as num).toInt();
      return (statKey, threshold);
    }
    // fallback 상수 테이블
    return _fallbackThresholds[title.id];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTitles = ref.watch(titlesProvider);
    final ownedTitles = ref.watch(mercenaryTitlesProvider(merc.id));
    final ownedIds = ownedTitles.map((t) => t.id).toSet();

    // 4 카운터 값 추출
    final solo = merc.stats['solo_completion_count'] ?? 0;
    final soloGreat = merc.stats['solo_great_success_count'] ?? 0;
    final pair = merc.stats['pair_completion_count'] ?? 0;
    final small = merc.stats['small_party_count'] ?? 0;
    final totalCounters = solo + soloGreat + pair + small;

    // 전용 4 칭호 데이터 매핑 (정적 데이터 미동기화 시 해당 칭호 skip)
    final masteryEntries = <_MasteryEntry>[];
    for (final titleId in _masteryTitleIds) {
      final titleData = allTitles.firstWhereOrNull((t) => t.id == titleId);
      if (titleData == null) continue; // 정적 데이터 없으면 skip

      final resolved = _resolveStatKey(titleData);
      if (resolved == null) continue; // 임계값 추출 불가 skip

      final (statKey, threshold) = resolved;
      final current = merc.stats[statKey] ?? 0;
      final isOwned = ownedIds.contains(titleId);
      masteryEntries.add(_MasteryEntry(
        title: titleData,
        statKey: statKey,
        threshold: threshold,
        current: current,
        isOwned: isOwned,
      ));
    }

    // 전용 칭호 진행 여부: 미보유 칭호 중 카운터 > 0이거나 보유 칭호가 있는 경우
    final anyTitleProgress = masteryEntries.any((e) => e.current > 0);

    // 전 카운터 0 AND 전용 칭호 진행 0이면 섹션 숨김
    if (totalCounters == 0 && !anyTitleProgress) {
      return const SizedBox.shrink();
    }

    // 콘텐츠가 있을 때만 상단 16px 간격 포함 (overlay에서 SizedBox 생략 대응)
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.namedAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.namedAccent, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            const Text(
              '⭐ 개인 숙련도',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.namedAccent,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            // 카운터 요약 (0보다 큰 항목만 표시)
            _CounterSummary(solo: solo, soloGreat: soloGreat, pair: pair, small: small),
            // 전용 칭호 진행도 목록
            if (masteryEntries.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...masteryEntries.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Padding(
                  padding: EdgeInsets.only(top: idx == 0 ? 0 : 6),
                  child: _MasteryTitleRow(entry: item),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

/// 카운터 요약 위젯. 0보다 큰 항목만 Wrap으로 나열.
class _CounterSummary extends StatelessWidget {
  final int solo;
  final int soloGreat;
  final int pair;
  final int small;

  const _CounterSummary({
    required this.solo,
    required this.soloGreat,
    required this.pair,
    required this.small,
  });

  /// 4 카운터 요약 라벨 테이블.
  static const _counterLabels = <String, String>{
    'solo_completion_count': '단독 완수',
    'solo_great_success_count': '단독 대성공',
    'pair_completion_count': '페어 완수',
    'small_party_count': '소수 완수',
  };

  @override
  Widget build(BuildContext context) {
    final items = <MapEntry<String, int>>[
      MapEntry('solo_completion_count', solo),
      MapEntry('solo_great_success_count', soloGreat),
      MapEntry('pair_completion_count', pair),
      MapEntry('small_party_count', small),
    ].where((e) => e.value > 0).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: items.map((e) {
        final label = _counterLabels[e.key] ?? e.key;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              '${e.value}',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.namedAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// 칭호별 숙련도 행 데이터 모델.
class _MasteryEntry {
  final TitleData title;
  final String statKey;
  final int threshold;
  final int current;
  final bool isOwned;

  const _MasteryEntry({
    required this.title,
    required this.statKey,
    required this.threshold,
    required this.current,
    required this.isOwned,
  });
}

/// 칭호 1개의 진행도 행.
/// 보유 → ✓ 달성 배지, 미보유 → 진행도 바.
class _MasteryTitleRow extends StatelessWidget {
  final _MasteryEntry entry;

  const _MasteryTitleRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry.isOwned) {
      // 보유 칭호: ✓ 달성 배지만 (중복 카드 금지)
      return Row(
        children: [
          const Text(
            '✓',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.namedAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            entry.title.name,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.namedAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '달성',
            style: TextStyle(
              fontSize: 9,
              color: AppTheme.textHint,
            ),
          ),
        ],
      );
    }

    // 미보유 칭호: 진행도 바
    final clamped = entry.current.clamp(0, entry.threshold);
    final progress = entry.threshold > 0 ? clamped / entry.threshold : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.title.name,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${entry.current}/${entry.threshold}',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textHint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: AppTheme.namedAccent.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.namedAccent,
            ),
          ),
        ),
      ],
    );
  }
}
