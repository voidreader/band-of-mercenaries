import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/models/title_data.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/achievement/view/achievement_unlocked_dialog.dart';
import 'package:band_of_mercenaries/features/achievement/domain/mercenary_snapshot_model.dart';
import 'package:band_of_mercenaries/features/mercenary/view/battle_memory_section.dart';
import 'package:band_of_mercenaries/features/title/domain/title_provider.dart';

class ChronicleScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const ChronicleScreen({super.key, this.onBack});

  @override
  ConsumerState<ChronicleScreen> createState() => _ChronicleScreenState();
}

class _ChronicleScreenState extends ConsumerState<ChronicleScreen> {
  // 빈 Set = 전체 표시, 선택된 항목이 있으면 해당 카테고리만 표시
  Set<String> _selectedCategories = {};
  int _displayLimit = 50;

  // (카테고리 id, 표시 레이블, 아이콘) 순서 7종
  static const _categories = <(String, String, IconData)>[
    ('chain_completed', '체인', Icons.link),
    ('settlement_event_completed', '거점사건', Icons.home_work),
    ('settlement_trust_belonging', '거점소속', Icons.handshake),
    ('reputation_rank', '명성', Icons.military_tech),
    ('elite_unique_first_kill', '엘리트', Icons.local_fire_department),
    ('craft_first_rare', '제작', Icons.construction),
    ('memorial', '추모', Icons.flag),
  ];

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(bandAchievementsProvider);

    // 카테고리 필터: 빈 set이면 전체, 아니면 선택 카테고리만
    final filtered = _selectedCategories.isEmpty
        ? achievements
        : achievements.where((a) {
            final category = a.type == BandAchievementType.memorial
                ? 'memorial'
                : _categoryOf(a.templateId);
            return _selectedCategories.contains(category);
          }).toList();

    final displayed = filtered.take(_displayLimit).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
        ),
        title: const Text('용병단 연대기'),
      ),
      body: Column(
        children: [
          // 카테고리 필터 칩 행 (다중 선택, 빈 상태 = 전체)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((entry) {
                  final (id, label, icon) = entry;
                  final selected = _selectedCategories.contains(id);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      avatar: Icon(
                        icon,
                        size: 16,
                        color: selected ? AppTheme.chainGold : null,
                      ),
                      label: Text(label),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedCategories = {..._selectedCategories, id};
                          } else {
                            _selectedCategories = {
                              ..._selectedCategories,
                            }..remove(id);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: achievements.isEmpty
                ? Center(
                    child: Text(
                      '용병단의 여정이 곧 시작됩니다.\n첫 위업을 기다립니다.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textHint,
                          ),
                    ),
                  )
                : ListView.builder(
                    itemCount: displayed.length +
                        (displayed.length < filtered.length ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= displayed.length) {
                        // 페이징: 50개 단위 lazy load
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _displayLimit += 50),
                              child: const Text('더 보기'),
                            ),
                          ),
                        );
                      }
                      final achievement = displayed[index];
                      return achievement.type == BandAchievementType.memorial
                          ? _MemorialCard(achievement: achievement)
                          : _AchievementCard(achievement: achievement);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // templateId에서 ':' 앞 카테고리 부분만 추출
  String _categoryOf(String templateId) {
    final idx = templateId.indexOf(':');
    return idx < 0 ? templateId : templateId.substring(0, idx);
  }
}

class _AchievementCard extends ConsumerWidget {
  final BandAchievement achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(staticDataProvider).valueOrNull;
    final template = staticData?.bandAchievementTemplates
        .where((t) => t.id == achievement.templateId)
        .firstOrNull;
    final name = template?.name ?? '알 수 없는 위업';
    final renderedDescription =
        ref.watch(renderedAchievementProvider(achievement.id));

    final category = _categoryOf(achievement.templateId);
    final icon = _iconForCategory(category);

    return Card(
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (_) => AchievementUnlockedDialog(achievement: achievement),
        ),
        child: ListTile(
          leading: Icon(icon, color: AppTheme.chainGold),
          title: Text(
            name,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: Text(
            renderedDescription.isEmpty
                ? (template?.descriptionTemplate ?? achievement.templateId)
                : renderedDescription,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ),
      ),
    );
  }

  // templateId에서 ':' 앞 카테고리 부분만 추출
  String _categoryOf(String templateId) {
    final idx = templateId.indexOf(':');
    return idx < 0 ? templateId : templateId.substring(0, idx);
  }

  IconData _iconForCategory(String category) {
    return switch (category) {
      'chain_completed' => Icons.link,
      'settlement_event_completed' => Icons.home_work,
      'settlement_trust_belonging' => Icons.handshake,
      'reputation_rank' => Icons.military_tech,
      'elite_unique_first_kill' => Icons.local_fire_department,
      'craft_first_rare' => Icons.construction,
      _ => Icons.auto_awesome,
    };
  }
}

/// 추모 카드 (FR-6).
///
/// 기본 접힘 상태에서 탭 시 펼침(`_expanded`)으로 전환.
/// `mercSnapshot == null`(구버전 추모)이면 펼침 비활성 — 기존 표시만 유지.
class _MemorialCard extends ConsumerStatefulWidget {
  final BandAchievement achievement;
  const _MemorialCard({required this.achievement});

  @override
  ConsumerState<_MemorialCard> createState() => _MemorialCardState();
}

class _MemorialCardState extends ConsumerState<_MemorialCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final mercSnapshot = widget.achievement.mercSnapshot;
    final causeName =
        widget.achievement.payload['cause'] as String? ?? 'unknown';
    final causeLabel = switch (causeName) {
      'diedQuest' => '의뢰에서 잠들다',
      'diedEvent' => '길 위에서 잠들다',
      'released' => '용병단을 떠나다',
      _ => '추모',
    };

    // mercSnapshot이 null이면(구버전 추모) 펼침 기능 비활성
    final canExpand = mercSnapshot != null;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 접힘 헤더 (항상 표시)
          InkWell(
            onTap: canExpand
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: ListTile(
              leading:
                  const Icon(Icons.flag, color: AppTheme.memorialGray),
              title: Text(
                mercSnapshot != null
                    ? '${mercSnapshot.name} (T${mercSnapshot.tier} ${mercSnapshot.jobName})'
                    : causeLabel,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.memorialGray,
                    ),
              ),
              subtitle: Text(
                causeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.memorialGray,
                    ),
              ),
              // 펼침 가능할 때만 토글 아이콘 표시
              trailing: canExpand
                  ? Text(
                      _expanded ? '▲' : '▼',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textHint,
                      ),
                    )
                  : null,
            ),
          ),
          // 펼침 영역
          if (_expanded && mercSnapshot != null)
            _buildExpandedContent(context, mercSnapshot),
        ],
      ),
    );
  }

  /// 펼침 영역: 칭호 칩 + 히든 스탯 요약 + 전투 기억 목록.
  Widget _buildExpandedContent(
    BuildContext context,
    MercenarySnapshot mercSnapshot,
  ) {
    final allTitles = ref.watch(titlesProvider);
    final staticData = ref.watch(staticDataProvider).valueOrNull;

    // 1) 보유 칭호 칩 — titleIds → TitleData lookup, 실패 skip
    final titleChips = mercSnapshot.titleIds
        .map((id) => allTitles.firstWhereOrNull((t) => t.id == id))
        .whereType<TitleData>()
        .toList();

    // 2) 히든 스탯 lv1+ 요약 줄
    // mercSnapshot.hiddenStats: Map<String,int> (id → lv)
    final lv1PlusEntries = mercSnapshot.hiddenStats.entries
        .where((e) => e.value >= 1)
        .toList();

    String? hiddenStatSummary;
    if (lv1PlusEntries.isNotEmpty) {
      final parts = lv1PlusEntries.map((e) {
        final stat =
            staticData?.hiddenStats.firstWhereOrNull((s) => s.id == e.key);
        final name = stat?.name ?? e.key;
        return '$name lv${e.value}';
      }).toList();
      hiddenStatSummary = parts.join(' · ');
    }

    // 3) 전투 기억 목록 — timestamp desc 정렬
    final memories = [...mercSnapshot.battleMemories]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 세 항목 모두 비어 있으면 "기록 없음" 1줄
    final allEmpty =
        titleChips.isEmpty && hiddenStatSummary == null && memories.isEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (allEmpty)
            Text(
              '기록 없음',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textHint,
                  ),
            )
          else ...[
            // 1) 보유 칭호 칩
            if (titleChips.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: titleChips.map((t) {
                  return Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    label: Text(
                      t.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.chainGold,
                      ),
                    ),
                    side: const BorderSide(
                      color: AppTheme.chainGold,
                      width: 0.8,
                    ),
                    backgroundColor:
                        AppTheme.chainGold.withValues(alpha: 0.08),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            // 2) 히든 스탯 lv1+ 요약
            if (hiddenStatSummary != null) ...[
              Text(
                hiddenStatSummary,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.hiddenStatAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
            ],
            // 3) 전투 기억 목록 (30개 전체, timestamp desc)
            if (memories.isNotEmpty) ...[
              const Text(
                '📖 전투 기억',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ...memories.asMap().entries.map((e) {
                return Padding(
                  padding: EdgeInsets.only(top: e.key == 0 ? 0 : 4),
                  // BattleMemoryCard: merc=null — 추모(본체 없음) 허용
                  child: BattleMemoryCard(entry: e.value, merc: null),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}
