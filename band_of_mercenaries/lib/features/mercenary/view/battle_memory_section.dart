import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/domain/template_context.dart';
import 'package:band_of_mercenaries/core/models/battle_memory_template.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/navigation_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/template_engine_provider.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/info_screen_auto_show_providers.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/battle_memory_entry.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/title/domain/title_provider.dart';

/// 슬픔(💧) 감정 전용 옅은 블루 — AppTheme 미정의이므로 위젯 로컬 const.
const Color _sorrowBlue = Color(0xFF64B5F6);

/// 용병 상세 오버레이의 전투 기억 섹션 (FR-2).
///
/// `merc.battleMemories`를 timestamp desc 정렬해 BattleMemoryCard 리스트로 렌더.
/// 빈 List면 빈 상태 문구. 컨테이너 톤은 titles_section.dart 정합.
class BattleMemorySection extends ConsumerWidget {
  final Mercenary merc;

  const BattleMemorySection({required this.merc, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // timestamp desc(최신 위) 정렬 — 원본 List 비변경(읽기 전용).
    final memories = [...merc.battleMemories]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 콘텐츠가 있을 때(항상) 상단 16px 간격 포함 (overlay에서 SizedBox 생략 대응)
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
              '📖 전투 기억 ${memories.length}/30',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.hiddenStatAccent,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            if (memories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '아직 기억이 없습니다. 이 용병이 의뢰를 수행하면 사건이 누적됩니다.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textHint,
                  ),
                ),
              )
            else
              ...memories.asMap().entries.map((entry) {
                final idx = entry.key;
                return Padding(
                  padding: EdgeInsets.only(top: idx == 0 ? 0 : 4),
                  child: BattleMemoryCard(entry: entry.value, merc: merc),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// 전투 기억 1건 카드 (FR-3·FR-3a·FR-7·FR-7a·FR-8).
///
/// 공개 위젯 — 용병 상세 섹션과 ChronicleScreen 추모 펼침에서 재사용한다.
/// [merc]는 templateData 컨텍스트(`{merc.name}`)용. 추모 펼침처럼 본체가 없으면 null 허용.
class BattleMemoryCard extends ConsumerWidget {
  final BattleMemoryEntry entry;

  /// templateData 렌더 컨텍스트용 용병 본체. 추모 시 null 허용(templateData 값만 사용).
  final Mercenary? merc;

  const BattleMemoryCard({required this.entry, required this.merc, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (entry.entryType) {
      case 'achievement_granted':
        return _buildAchievementCard(context, ref);
      case 'title_granted':
        return _buildTitleCard(context, ref);
      default:
        // 템플릿 렌더 4종 (emotional_apply/hidden_stat_unlock/
        // solo_great_success/unique_elite_first_kill) + 미상 entryType.
        return _buildTemplateCard(context, ref);
    }
  }

  // ── 템플릿 렌더 4종 ───────────────────────────────────────────────────

  Widget _buildTemplateCard(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(staticDataProvider).valueOrNull;
    final templates = staticData?.battleMemoryTemplates ?? const <BattleMemoryTemplate>[];

    // entry_type 일치 AND (source_event_match==null 와일드카드 OR sourceEventId 매칭)
    final pool = templates.where((t) {
      if (t.entryType != entry.entryType) return false;
      final match = t.sourceEventMatch;
      if (match == null) return true;
      return _matchesSourceEvent(entry.sourceEventId, match);
    }).toList();

    String body;
    if (pool.isEmpty) {
      // 템플릿 미발견(빈 캐시 포함) → FR-3a fallback 문구 (카드 유지)
      body = _fallbackLine(entry.entryType);
    } else {
      // 결정적 선택: templateKey 1순위, 없으면 id asc 첫 행
      final selected = (entry.templateKey != null
              ? pool.firstWhereOrNull((t) => t.id == entry.templateKey)
              : null) ??
          (pool.toList()..sort((a, b) => a.id.compareTo(b.id))).first;
      body = _renderTemplate(ref, selected.template);
      if (body.trim().isEmpty) body = _fallbackLine(entry.entryType);
    }

    return _shell(body: body);
  }

  /// TemplateContext 빌드 + 렌더.
  ///
  /// TemplateContext는 templateData Map을 직접 받지 않으므로,
  /// entry.templateData의 enemy/ally를 enemyName/allyName으로 매핑하고,
  /// merc 본체(+ user)를 주입한다. user 미초기화 시 fail-soft(원본 템플릿 반환).
  String _renderTemplate(WidgetRef ref, String template) {
    final user = ref.read(userDataProvider);
    if (user == null) return template;
    final engine = ref.watch(templateEngineProvider);

    final data = entry.templateData;
    final enemyName = data['enemy'] as String?;
    final allyName = data['ally'] as String?;

    return engine.render(
      template,
      TemplateContext(
        user: user,
        merc: merc,
        enemyName: enemyName,
        allyName: allyName,
        evaluationScope: EvaluationScope.mercenary,
      ),
    );
  }

  // ── lookup 렌더 2종 ───────────────────────────────────────────────────

  /// achievement_granted: sourceEventId(`achievement:{templateId}`) → 위업 lookup.
  Widget _buildAchievementCard(BuildContext context, WidgetRef ref) {
    final templateId = _idAfterPrefix(entry.sourceEventId, 'achievement:');
    if (templateId == null) return const SizedBox.shrink();

    final achievements = ref.watch(bandAchievementsProvider);
    final achievement =
        achievements.firstWhereOrNull((a) => a.templateId == templateId);
    if (achievement == null) return const SizedBox.shrink();

    // 발급 시점 위업명(렌더 캐싱) 사용. 빈 문자열이면 templateId fallback.
    final name = ref.watch(renderedAchievementProvider(achievement.id));
    final label = name.trim().isEmpty ? templateId : name;

    return _shell(
      iconOverride: '★',
      colorOverride: AppTheme.chainGold,
      body: label,
      onTap: () {
        // 정보 탭(index 5) + ChronicleScreen 자동 진입 (goal_card 동선 재사용)
        ref.read(infoScreenAutoShowChronicleProvider.notifier).state = true;
        ref.read(currentTabProvider.notifier).state = 5;
      },
    );
  }

  /// title_granted: sourceEventId(`title:{titleId}`) → 칭호 lookup.
  /// 탭 무동작(정보 표시 전용, FR-8 Q-4 1차 허용).
  Widget _buildTitleCard(BuildContext context, WidgetRef ref) {
    final titleId = _idAfterPrefix(entry.sourceEventId, 'title:');
    if (titleId == null) return const SizedBox.shrink();

    final titles = ref.watch(titlesProvider);
    final title = titles.firstWhereOrNull((t) => t.id == titleId);
    if (title == null) return const SizedBox.shrink();

    return _shell(
      iconOverride: '★',
      colorOverride: AppTheme.chainGold,
      body: title.name,
    );
  }

  // ── 공통 카드 셸 ──────────────────────────────────────────────────────

  Widget _shell({
    required String body,
    String? iconOverride,
    Color? colorOverride,
    VoidCallback? onTap,
  }) {
    final (icon, color) = iconOverride != null && colorOverride != null
        ? (iconOverride, colorOverride)
        : _iconColorFor(entry);

    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: TextStyle(fontSize: 14, color: color)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              body,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            relativeTime(entry.timestamp),
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }

  // ── 정적 헬퍼 ─────────────────────────────────────────────────────────

  /// sourceEventId가 source_event_match와 매칭되는지 판별.
  /// `*` suffix는 접두 매칭(와일드카드)으로 취급, 그 외는 정확 일치 또는 접두 포함.
  static bool _matchesSourceEvent(String sourceEventId, String match) {
    if (match.endsWith('*')) {
      return sourceEventId.startsWith(match.substring(0, match.length - 1));
    }
    if (sourceEventId == match) return true;
    return sourceEventId.startsWith(match);
  }

  /// `prefix{id}` 형태에서 prefix 이후 식별자 추출. 미일치 시 null.
  static String? _idAfterPrefix(String sourceEventId, String prefix) {
    if (!sourceEventId.startsWith(prefix)) return null;
    final id = sourceEventId.substring(prefix.length);
    return id.isEmpty ? null : id;
  }

  /// entryType별 아이콘·색상 매핑 (FR-7, 9행).
  /// emotional_apply 세부는 sourceEventId(emotional_*) 또는
  /// templateData['emotion']로 판별.
  static (String icon, Color color) _iconColorFor(BattleMemoryEntry entry) {
    switch (entry.entryType) {
      case 'emotional_apply':
        final emotion = _resolveEmotion(entry);
        switch (emotion) {
          case 'rage':
            return ('⚡', AppTheme.dangerRed);
          case 'despair':
            return ('🌑', AppTheme.memorialGray);
          case 'sorrow':
            return ('💧', _sorrowBlue);
          case 'determination':
            return ('✨', AppTheme.chainGold);
          default:
            return ('✨', AppTheme.hiddenStatAccent);
        }
      case 'hidden_stat_unlock':
        return ('✨', AppTheme.hiddenStatAccent);
      case 'achievement_granted':
        return ('★', AppTheme.chainGold);
      case 'title_granted':
        return ('★', AppTheme.chainGold);
      case 'solo_great_success':
        return ('⭐', AppTheme.namedAccent);
      case 'unique_elite_first_kill':
        return ('🔥', AppTheme.eliteUniqueAccent);
      default:
        return ('•', AppTheme.textSecondary);
    }
  }

  /// emotional_apply 세부 감정(rage/despair/sorrow/determination) 판별.
  static String? _resolveEmotion(BattleMemoryEntry entry) {
    final src = entry.sourceEventId;
    for (final e in const ['rage', 'despair', 'sorrow', 'determination']) {
      if (src.contains('emotional_$e') || src.contains(e)) return e;
    }
    final data = entry.templateData['emotion'];
    if (data is String && data.isNotEmpty) return data;
    return null;
  }

  /// 상대 시간 표시 (FR-7a).
  static String relativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.isNegative) return '방금 전';
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${diff.inDays ~/ 7}주 전';
  }

  /// 템플릿 미발견/빈 캐시 시 entryType별 fallback 1줄 (FR-3a).
  static String _fallbackLine(String entryType) {
    switch (entryType) {
      case 'emotional_apply':
        return '감정에 휩싸였다.';
      case 'hidden_stat_unlock':
        return '새로운 잠재력이 깨어났다.';
      case 'solo_great_success':
        return '단독 의뢰를 대성공으로 마쳤다.';
      case 'unique_elite_first_kill':
        return '강대한 적을 쓰러뜨렸다.';
      default:
        return '전투의 기억이 남았다.';
    }
  }
}
