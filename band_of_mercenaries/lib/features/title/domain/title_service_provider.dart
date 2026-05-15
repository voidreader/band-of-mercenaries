import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/providers/dialog_queue_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/title/domain/title_provider.dart';
import 'package:band_of_mercenaries/features/title/domain/title_service.dart';
import 'package:band_of_mercenaries/features/title/view/title_unlocked_dialog.dart';

/// TitleService 콜백 DI Provider.
///
/// 순환 참조 회피를 위해 `title_service.dart`와 분리. (AchievementService 패턴 준용)
///
/// `buildTitleDialog`: TitleUnlockedDialog 위젯을 생성하여 반환한다.
final titleServiceProvider = Provider<TitleService>((ref) {
  final staticData = ref.watch(staticDataProvider).requireValue;
  final titles = ref.watch(titlesProvider);
  // achievementServiceProvider / bandAchievementsProvider 의존을 피해 사이클을 끊고
  // bandAchievements 박스를 직접 조회 (M6 페이즈 4 #2).
  final achievementsBox = Hive.box<BandAchievement>(
    HiveInitializer.bandAchievementBoxName,
  );

  return TitleService(
    titles: titles,
    getMercenary: (id) {
      final list = ref.read(mercenaryListProvider);
      for (final m in list) {
        if (m.id == id) return m;
      }
      return null;
    },
    updateMercenaryTitles: (id, ids) => ref.read(mercenaryListProvider.notifier).updateTitleIds(id, ids),
    addLog: (msg, type) =>
        ref.read(activityLogProvider.notifier).addLog(msg, type),
    enqueueDialog: (req) =>
        ref.read(dialogQueueProvider.notifier).enqueue(req),
    hasAchievement: (tplId) => achievementsBox.values.any(
      (a) =>
          a.type == BandAchievementType.achievement && a.templateId == tplId,
    ),
    bandAchievements: () => achievementsBox.values.toList()
      ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt)),
    staticData: staticData,
    buildTitleDialog: ({
      required title,
      required mercSnapshot,
      required reasonText,
      required onDismiss,
    }) {
      return TitleUnlockedDialog(
        title: title,
        mercSnapshot: mercSnapshot,
        reasonText: reasonText,
        onDismiss: onDismiss,
      );
    },
  );
});
