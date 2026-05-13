import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/achievement/view/achievement_unlocked_dialog.dart';

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

class _MemorialCard extends ConsumerWidget {
  final BandAchievement achievement;
  const _MemorialCard({required this.achievement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mercSnapshot = achievement.mercSnapshot;
    final causeName = achievement.payload['cause'] as String? ?? 'unknown';
    final causeLabel = switch (causeName) {
      'diedQuest' => '의뢰에서 잠들다',
      'diedEvent' => '길 위에서 잠들다',
      'released' => '용병단을 떠나다',
      _ => '추모',
    };

    return Card(
      child: ListTile(
        leading: const Icon(Icons.flag, color: AppTheme.memorialGray),
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
      ),
    );
  }
}
