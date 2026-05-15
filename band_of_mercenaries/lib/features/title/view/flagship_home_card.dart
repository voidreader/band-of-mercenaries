import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/title_data.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/mercenary_detail_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/title/domain/flagship_provider.dart';
import 'package:band_of_mercenaries/features/title/domain/title_provider.dart';
import 'package:band_of_mercenaries/shared/widgets/tier_badge.dart';

/// 홈 야영지 — 간판 용병 카드 (M6 페이즈 4 #2)
class FlagshipHomeCard extends ConsumerWidget {
  const FlagshipHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gameTickProvider);
    final merc = ref.watch(flagshipMercenaryProvider);
    final userData = ref.watch(userDataProvider);
    final isManual = userData?.flagshipMercId != null;

    if (merc == null) {
      return const _EmptyFlagshipCard();
    }

    final staticData = ref.watch(staticDataProvider).valueOrNull;
    final job = staticData?.jobs.where((j) => j.id == merc.jobId).firstOrNull;
    final jobName = job?.name ?? merc.jobId;
    final jobTier = job?.tier ?? 1;

    // titleIds → TitleData 매핑
    final titles = ref.watch(titlesProvider);
    final titlesById = {for (final t in titles) t.id: t};
    final mercTitles = merc.titleIds
        .map((id) => titlesById[id])
        .whereType<TitleData>()
        .toList();

    // recruitedAt → 일수
    final days = merc.recruitedAt == null
        ? null
        : DateTime.now().difference(merc.recruitedAt!).inDays;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: GestureDetector(
        onTap: () =>
            ref.read(selectedMercenaryIdProvider.notifier).state = merc.id,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.chainGold.withValues(alpha: 0.06),
            border: Border.all(color: AppTheme.chainGold, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: "★ 우리 용병단의 얼굴" + 자동/수동 라벨
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '★ 우리 용병단의 얼굴',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.chainGold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    isManual ? '수동' : '자동 선정',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // 본문: TierBadge + 이름/직업/일수/칭호 + 파견 중 배지
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 좌측: TierBadge (42×42 원형 유사 크기)
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                      child: TierBadge(
                        tier: jobTier,
                        fontSize: 14,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 중앙: 이름, 직업·레벨, 일수, 칭호 칩
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이름 + 직업·레벨
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: merc.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text:
                                    '  T$jobTier $jobName · Lv ${merc.level}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),

                        // 용병단 합류 일수
                        Text(
                          days == null
                              ? '신규'
                              : '우리 용병단에 $days일째',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textHint,
                          ),
                        ),

                        // 칭호 칩 Wrap (최대 3개 + "+N종" overflow)
                        if (mercTitles.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _TitleChipsWrap(titles: mercTitles),
                        ],
                      ],
                    ),
                  ),

                  // 우측: 파견 중 배지
                  if (merc.isDispatched) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.eliteBg,
                        border: Border.all(
                            color: AppTheme.eliteAccent.withValues(
                                alpha: 0.4)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        '파견 중',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.eliteAccent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 6),

              // 하단 힌트
              Align(
                alignment: Alignment.centerRight,
                child: const Text(
                  '탭 → 용병 상세',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

/// 간판 용병이 없을 때 표시되는 빈 카드
class _EmptyFlagshipCard extends StatelessWidget {
  const _EmptyFlagshipCard();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
              color: AppTheme.chainGold.withValues(alpha: 0.3), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '용병단의 새 간판을 기다립니다 — 새 용병을 모집해 보세요',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppTheme.textHint,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// 칭호 칩 Wrap — 최대 3개 표시 후 "+N종" overflow
class _TitleChipsWrap extends StatelessWidget {
  final List<TitleData> titles;

  const _TitleChipsWrap({required this.titles});

  @override
  Widget build(BuildContext context) {
    const maxVisible = 3;
    final visible = titles.take(maxVisible).toList();
    final overflow = titles.length - maxVisible;

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        for (final t in visible)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.chainGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              t.name,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.chainGold,
              ),
            ),
          ),
        if (overflow > 0)
          Text(
            '+$overflow종',
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textHint,
            ),
          ),
      ],
    );
  }
}
