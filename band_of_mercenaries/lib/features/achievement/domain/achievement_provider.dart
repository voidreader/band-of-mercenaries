import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/domain/template_context.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/template_engine_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_service_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';

// achievementServiceProvider는 achievement_service_provider.dart에서 정의.
// 순환 참조 방지를 위해 분리됨 (game_state_provider.dart에서 직접 사용).
export 'package:band_of_mercenaries/features/achievement/domain/achievement_service_provider.dart'
    show achievementServiceProvider;

/// bandAchievementsBox를 watch하여 시간 desc 정렬된 리스트를 emit하는 StateNotifier.
final bandAchievementsProvider =
    StateNotifierProvider<BandAchievementsNotifier, List<BandAchievement>>(
  (ref) => BandAchievementsNotifier(ref),
);

class BandAchievementsNotifier extends StateNotifier<List<BandAchievement>> {
  BandAchievementsNotifier(this.ref) : super(const []) {
    _loadAndWatch();
  }

  final Ref ref;
  StreamSubscription? _sub;

  void _loadAndWatch() {
    final service = ref.read(achievementServiceProvider);
    state = service.getAll();

    // service.box를 재사용해 Hive.box 중복 호출 제거.
    _sub = service.box.watch().listen((_) {
      if (!mounted) return;
      // stale closure 방지를 위해 ref.read로 최신 service 참조.
      state = ref.read(achievementServiceProvider).getAll();
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }
}

/// achievementId별 TemplateEngine 렌더 결과를 캐싱하는 family Provider.
///
/// 동일 위업의 description은 발급 후 변화 없으므로 family 캐싱이 안전.
/// templateId/template 미존재 시 fail-soft fallback:
///   - template 없음 → templateId 그대로 반환
///   - user 없음 → 원본 템플릿 반환(빈 컨텍스트 렌더 회피)
final renderedAchievementProvider =
    Provider.family<String, String>((ref, achievementId) {
  final list = ref.watch(bandAchievementsProvider);
  final achievement = list.where((a) => a.id == achievementId).firstOrNull;
  if (achievement == null) return '';

  final staticData = ref.watch(staticDataProvider).valueOrNull;
  if (staticData == null) return achievement.templateId;

  final template = staticData.bandAchievementTemplates
      .where((t) => t.id == achievement.templateId)
      .firstOrNull;
  if (template == null) return achievement.templateId;

  // 위업 description은 발급 후 변하지 않으므로 read 1회 사용. golden/위치 변경 시 재렌더 불필요.
  final user = ref.read(userDataProvider);
  if (user == null) return template.descriptionTemplate;

  final region = achievement.regionId != null
      ? staticData.regions
          .where((r) => r.region == achievement.regionId)
          .firstOrNull
      : null;

  final engine = ref.watch(templateEngineProvider);
  // mercSnapshot은 영속 보존된 발급 시점 정보지만, TemplateContext.merc는 Mercenary 본체 타입을
  // 요구하므로 직접 binding 불가. {merc.*} 토큰이 필요한 템플릿은 description 내에서
  // mercSnapshot.name 등을 별도 표시 위젯에 위임하고, 여기서는 region·user 컨텍스트만 사용한다.
  return engine.render(
    template.descriptionTemplate,
    TemplateContext(
      user: user,
      region: region,
      evaluationScope: EvaluationScope.mercenary,
    ),
  );
});
