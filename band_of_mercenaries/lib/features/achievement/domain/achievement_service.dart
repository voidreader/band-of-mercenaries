import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/models/band_achievement_template.dart';
import 'package:band_of_mercenaries/core/models/dialog_request.dart';
import 'package:band_of_mercenaries/core/models/title_data.dart';
import 'package:band_of_mercenaries/core/providers/dialog_queue_provider.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/achievement/domain/memorial_cause.dart';
import 'package:band_of_mercenaries/features/achievement/domain/mercenary_snapshot_model.dart';
import 'package:band_of_mercenaries/features/title/domain/title_service.dart'
    show AchievementHookContext;

/// 위업·연대기 발급 진입점.
///
/// 6 hook(체인·거점사건·거점소속·명성·엘리트·제작) 통합 진입점으로 사용된다.
/// 모든 사이드이펙트(box.add / ActivityLog 미러 / dialog enqueue)는 fail-soft 처리.
/// 멱등성은 [hasAchievement] 사전 체크 + recordMemorial의 (mercId, cause) 조합 사전 검사로 보장.
class AchievementService {
  AchievementService({
    required this.box,
    required this.uuid,
    required this.addLog,
    required this.enqueueDialog,
    required this.templates,
    required this.buildAchievementDialog,
    this.evaluateAchievementHook,
    this.buildHookContext,
  });

  final Box<BandAchievement> box;
  final Uuid uuid;
  final void Function(String message, ActivityLogType type) addLog;
  final void Function(DialogRequest req) enqueueDialog;
  final List<BandAchievementTemplate> templates;

  /// 다이얼로그 위젯 빌더 — Provider 바인딩 시점에 주입.
  /// AchievementUnlockedDialog가 후속 TASK에서 생성되므로 서비스 자체는 위젯 타입에 의존하지 않는다.
  final Widget Function(
    BandAchievement achievement,
    List<TitleData> grantedTitles,
    VoidCallback onDismiss,
  ) buildAchievementDialog;

  /// 칭호 hook 평가 콜백 (M6 페이즈 4 #2) — nullable, 페이즈 4 #1 호환.
  final Future<List<TitleData>> Function(
    BandAchievement achievement,
    AchievementHookContext context,
  )? evaluateAchievementHook;

  /// hook 컨텍스트 빌더 콜백 (M6 페이즈 4 #2) — nullable, 페이즈 4 #1 호환.
  final AchievementHookContext Function(BandAchievement achievement)?
      buildHookContext;

  /// 위업 발급. 멱등성 보장 ([hasAchievement] 사전 체크).
  ///
  /// 사이드이펙트 3종 순차 실행(try/catch fail-soft):
  /// 1. bandAchievements 박스 add (영구 저장)
  /// 2. ActivityLog 미러 1행
  /// 3. dialog enqueue — 단, `reputation_rank` 카테고리는 RankUpDialog 본체 인라인이 대체하므로 생략
  ///
  /// 반환: 신규 발급 시 [BandAchievement], 중복/실패 시 null.
  Future<BandAchievement?> grant(
    String templateId, {
    MercenarySnapshot? mercSnapshot,
    int? regionId,
    Map<String, dynamic> payload = const {},
  }) async {
    try {
      if (hasAchievement(templateId)) return null;

      final achievement = BandAchievement(
        id: uuid.v4(),
        type: BandAchievementType.achievement,
        achievedAt: DateTime.now(),
        templateId: templateId,
        mercSnapshot: mercSnapshot,
        regionId: regionId,
        payload: payload,
      );
      await box.add(achievement);

      final template = _findTemplate(templateId);
      final name = template?.name ?? '알 수 없는 위업';
      final mercName = mercSnapshot?.name;
      final logMessage = mercName == null
          ? '★ 위업: $name'
          : '★ 위업: $name — $mercName';
      addLog(logMessage, ActivityLogType.achievementUnlocked);

      // (2.5) 칭호 hook 평가 (M6 페이즈 4 #2) — fail-soft. 콜백 nullable로 페이즈 4 #1 호환.
      List<TitleData> grantedTitles = const [];
      try {
        if (evaluateAchievementHook != null && buildHookContext != null) {
          final ctx = buildHookContext!(achievement);
          grantedTitles = await evaluateAchievementHook!(achievement, ctx);
        }
      } on Exception catch (e) {
        debugPrint('[BOM][Title] hook 평가 실패: $e');
      }

      // reputation_rank 카테고리는 RankUpDialog 본체 인라인 연출이 대체하므로 별도 다이얼로그 큐 enqueue 생략.
      final category = _categoryOf(templateId);
      if (category != 'reputation_rank') {
        enqueueDialog(
          DialogRequest(
            id: 'achievement:${achievement.id}',
            priority: DialogPriority.high,
            dialogType: DialogTypeRegistry.achievementUnlocked,
            payload: {
              'achievementId': achievement.id,
              'templateId': templateId,
              'name': name,
              'mercSnapshotName': mercName,
              'regionId': regionId,
              'grantedTitles': grantedTitles.map((t) => t.name).toList(),
              ...payload,
            },
            builder: (context, onDismiss) =>
                buildAchievementDialog(achievement, grantedTitles, onDismiss),
          ),
        );
      }

      return achievement;
    } on Exception catch (e) {
      debugPrint('[BOM][Achievement] grant 실패 ($templateId): $e');
      return null;
    }
  }

  /// 추모 기록. dialog enqueue X, ActivityLog X
  /// (사망/방출 이벤트가 자체 활동 로그를 이미 기록함).
  ///
  /// 멱등성: 동일 (mercSnapshot.id, cause) 조합 사전 중복 검사로 차단.
  Future<BandAchievement?> recordMemorial(
    MemorialCause cause,
    MercenarySnapshot mercSnapshot, {
    Map<String, dynamic> payload = const {},
  }) async {
    try {
      final duplicate = box.values.any(
        (a) =>
            a.type == BandAchievementType.memorial &&
            a.mercSnapshot?.id == mercSnapshot.id &&
            a.payload['cause'] == cause.name,
      );
      if (duplicate) return null;

      final templateId = 'memorial:${cause.name}';
      final achievement = BandAchievement(
        id: uuid.v4(),
        type: BandAchievementType.memorial,
        achievedAt: DateTime.now(),
        templateId: templateId,
        mercSnapshot: mercSnapshot,
        regionId: null,
        payload: {'cause': cause.name, ...payload},
      );
      await box.add(achievement);
      return achievement;
    } on Exception catch (e) {
      debugPrint('[BOM][Achievement] recordMemorial 실패 (${cause.name}): $e');
      return null;
    }
  }

  /// 동일 templateId의 위업이 이미 발급되었는지 동기 조회. 6 hook 멱등성 보장에 사용.
  bool hasAchievement(String templateId) => box.values.any(
        (a) =>
            a.type == BandAchievementType.achievement &&
            a.templateId == templateId,
      );

  /// 전체 위업·추모 기록을 시간 desc로 정렬해 반환.
  List<BandAchievement> getAll() =>
      box.values.toList()
        ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

  /// templateId의 `:` 앞 prefix를 카테고리로 추출.
  /// 예) `chain_completed:chain_roadside_shrine` → `chain_completed`
  String _categoryOf(String templateId) {
    final idx = templateId.indexOf(':');
    return idx < 0 ? templateId : templateId.substring(0, idx);
  }

  BandAchievementTemplate? _findTemplate(String templateId) {
    for (final t in templates) {
      if (t.id == templateId) return t;
    }
    return null;
  }
}
