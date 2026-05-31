import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/providers/dialog_queue_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/achievement_service.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/achievement/view/achievement_unlocked_dialog.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/title/domain/achievement_hook_context_builder.dart';
import 'package:band_of_mercenaries/features/title/domain/title_service_provider.dart';

/// AchievementService 싱글턴 Provider.
///
/// game_state_provider와의 순환 참조를 피하기 위해 achievement_provider.dart에서 분리.
/// renderedAchievementProvider 등 userDataProvider 의존 Provider는 achievement_provider.dart에 유지.
///
/// templates는 staticDataProvider 로딩 완료 전이면 빈 리스트로 시작 — fail-soft.
final achievementServiceProvider = Provider<AchievementService>((ref) {
  final box = Hive.box<BandAchievement>(
    HiveInitializer.bandAchievementBoxName,
  );
  final staticData = ref.watch(staticDataProvider).maybeWhen(
        data: (d) => d,
        orElse: () => null,
      );

  return AchievementService(
    box: box,
    uuid: const Uuid(),
    addLog: (message, type) =>
        ref.read(activityLogProvider.notifier).addLog(message, type),
    enqueueDialog: (req) =>
        ref.read(dialogQueueProvider.notifier).enqueue(req),
    templates: staticData?.bandAchievementTemplates ?? const [],
    buildAchievementDialog: (achievement, grantedTitles, onDismiss) =>
        AchievementUnlockedDialog(
          achievement: achievement,
          grantedTitles: grantedTitles,
          onDismiss: onDismiss,
        ),
    evaluateAchievementHook: (ach, ctx) async {
      return await ref.read(titleServiceProvider).evaluateAchievementHook(ach, ctx);
    },
    buildHookContext: (ach) => buildAchievementHookContext(ref, ach),
    getMercenary: (mercId) {
      final list = ref.read(mercenaryListProvider);
      for (final m in list) {
        if (m.id == mercId) return m;
      }
      return null;
    },
    updateMercenary: (merc) async {
      // battleMemory는 UI 비노출 영속 데이터이므로 state 재로딩 불필요.
      // 다음 mercenaryListProvider _load 시 자연 반영.
      return merc.save();
    },
  );
});
