import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/data/supabase_initializer.dart';
import 'package:band_of_mercenaries/core/data/sync_service.dart';
import 'package:band_of_mercenaries/core/data/settings_keys.dart';
import 'package:band_of_mercenaries/core/data/data_loader.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/shared/widgets/bottom_nav_bar.dart';
import 'package:band_of_mercenaries/features/home/view/home_screen.dart';
import 'package:band_of_mercenaries/features/movement/view/movement_screen.dart';
import 'package:band_of_mercenaries/features/quest/view/dispatch_screen.dart';
import 'package:band_of_mercenaries/features/mercenary/view/recruit_screen.dart';
import 'package:band_of_mercenaries/features/info/view/info_screen.dart';
import 'package:band_of_mercenaries/features/facility/view/facility_tab_screen.dart';
import 'package:band_of_mercenaries/features/facility/domain/construction_completion_provider.dart';
import 'package:band_of_mercenaries/features/investigation/domain/investigation_notifier.dart';
import 'package:band_of_mercenaries/features/investigation/domain/investigation_completion_provider.dart';
import 'package:band_of_mercenaries/features/investigation/domain/investigation_result.dart';
import 'package:band_of_mercenaries/features/investigation/view/investigation_widget.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/providers/mercenary_detail_provider.dart';
import 'package:band_of_mercenaries/core/providers/navigation_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/reputation_rank_up_provider.dart';
import 'package:band_of_mercenaries/core/providers/dialog_queue_provider.dart';
import 'package:band_of_mercenaries/core/models/dialog_request.dart';
import 'package:band_of_mercenaries/features/mercenary/view/mercenary_detail_overlay.dart';
import 'package:band_of_mercenaries/features/home/view/rank_up_overlay.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_provider.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_service.dart';
import 'package:band_of_mercenaries/features/chain_quest/view/chain_completed_dialog.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_transformed_provider.dart';
import 'package:band_of_mercenaries/features/investigation/view/region_transform_dialog.dart';

class BandOfMercenariesApp extends StatelessWidget {
  const BandOfMercenariesApp({super.key});

  // 모바일과 유사한 해상도로 웹에서도 동작하도록 최대 너비 제한
  static const double _maxMobileWidth = 430;
  static const double _maxMobileHeight = 932;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Band of Mercenaries',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const _MobileFrame(),
    );
  }
}

class _MobileFrame extends StatelessWidget {
  const _MobileFrame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: BandOfMercenariesApp._maxMobileWidth,
            maxHeight: BandOfMercenariesApp._maxMobileHeight,
          ),
          child: const MainShell(),
        ),
      ),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  static const _screens = [
    MovementScreen(),
    DispatchScreen(),
    HomeScreen(),
    RecruitScreen(),
    FacilityTabScreen(),
    InfoScreen(),
  ];

  /// 큐 다이얼로그 표시 중 중복 표시 방지 플래그
  bool _isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveLastActiveTime();
    }
    if (state == AppLifecycleState.resumed) {
      _syncOnResume();
    }
  }

  Future<void> _syncOnResume() async {
    final cacheBox = Hive.box<String>(HiveInitializer.staticDataCacheBoxName);
    final syncService = SyncService(
      client: SupabaseInitializer.client,
      dataLoader: DataLoader(cacheBox: cacheBox),
    );

    final status = await syncService.sync();
    if (status == SyncStatus.updated || status == SyncStatus.fullDownload) {
      ref.invalidate(staticDataProvider);
    }
  }

  void _saveLastActiveTime() {
    final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
    settingsBox.put(SettingsKeys.lastActiveTime, DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);
    final selectedMercId = ref.watch(selectedMercenaryIdProvider);

    ref.listen(gameTickProvider, (prev, next) {
      ref.read(userDataProvider.notifier).checkConstructionCompletion();
      ref.read(investigationNotifierProvider.notifier).checkCompletion();
      // 1시간 주기 (3600초) 휴면 체인 퀘스트 점검
      final tick = (next.value?.millisecondsSinceEpoch ?? 0) ~/ 1000;
      if (tick > 0 && tick % 3600 == 0) {
        final progresses = ref.read(chainQuestProgressProvider).valueOrNull ?? [];
        unawaited(
          ref.read(chainQuestServiceProvider).checkDormant(progresses: progresses),
        );
      }
    });

    // ── 도메인 Provider → 큐 enqueue 어댑터 (5개 채널) ──────────────────────

    // 건설 완료 (medium)
    ref.listen<String?>(constructionCompletedProvider, (_, next) {
      if (next == null) return;
      final staticData = ref.read(staticDataProvider).value;
      final facilityName =
          staticData?.facilities.where((f) => f.id == next).firstOrNull?.name ?? next;
      final userData = ref.read(userDataProvider);
      final newLevel = userData?.facilities[next] ?? 1;
      ref.read(activityLogProvider.notifier).addLog(
        '$facilityName이(가) Lv.$newLevel(으)로 업그레이드되었습니다',
        ActivityLogType.facilityUpgrade,
      );
      ref.read(dialogQueueProvider.notifier).enqueue(DialogRequest(
        id: 'constructionComplete_${next}_${DateTime.now().millisecondsSinceEpoch}',
        priority: DialogPriority.medium,
        dialogType: DialogTypeRegistry.constructionComplete,
        payload: {'facilityId': next, 'facilityName': facilityName, 'newLevel': newLevel},
        builder: (ctx, dismiss) => AlertDialog(
          title: const Text('건설 완료'),
          content: Text('$facilityName이(가) 업그레이드되었습니다!'),
          actions: [
            ElevatedButton(
              onPressed: dismiss,
              child: const Text('확인'),
            ),
          ],
        ),
      ));
      ref.read(constructionCompletedProvider.notifier).state = null;
    });

    // 지역 조사 완료 (medium)
    ref.listen<InvestigationResult?>(investigationCompletedProvider, (_, next) {
      if (next == null) return;
      final mercs = ref.read(mercenaryListProvider);
      final mercName = mercs.where((m) => m.id == next.mercId).firstOrNull?.name ?? next.mercId;
      final capturedResult = next;
      ref.read(dialogQueueProvider.notifier).enqueue(DialogRequest(
        id: 'investigationResult_${next.mercId}_${DateTime.now().millisecondsSinceEpoch}',
        priority: DialogPriority.medium,
        dialogType: DialogTypeRegistry.investigationResult,
        payload: {'mercId': next.mercId, 'mercName': mercName},
        builder: (ctx, dismiss) => InvestigationResultDialog(
          result: capturedResult,
          mercName: mercName,
        ),
      ));
      ref.read(investigationCompletedProvider.notifier).state = null;
    });

    // 명성 랭크업 (critical)
    ref.listen<RankUpEvent?>(reputationRankUpProvider, (_, next) {
      if (next == null) return;
      final capturedEvent = next;
      ref.read(dialogQueueProvider.notifier).enqueue(DialogRequest(
        id: 'rankUp_${next.to.grade}_${DateTime.now().millisecondsSinceEpoch}',
        priority: DialogPriority.critical,
        dialogType: DialogTypeRegistry.rankUp,
        payload: {'toGrade': next.to.grade},
        builder: (ctx, dismiss) => RankUpOverlay(
          event: capturedEvent,
          onDismiss: dismiss,
        ),
      ));
      ref.read(reputationRankUpProvider.notifier).state = null;
    });

    // 체인 퀘스트 완주 (high)
    ref.listen<ChainCompletedEvent?>(chainCompletedProvider, (_, next) {
      if (next == null) return;
      final capturedEvent = next;
      ref.read(dialogQueueProvider.notifier).enqueue(DialogRequest(
        id: 'chainCompleted_${next.chainId}_${DateTime.now().millisecondsSinceEpoch}',
        priority: DialogPriority.high,
        dialogType: DialogTypeRegistry.chainCompleted,
        payload: {'chainId': next.chainId},
        builder: (ctx, dismiss) => ChainCompletedDialog(
          event: capturedEvent,
          onDismiss: dismiss,
        ),
      ));
      ref.read(chainCompletedProvider.notifier).state = null;
    });

    // 지역 변형 (high)
    ref.listen<RegionTransformedEvent?>(regionTransformedProvider, (_, next) {
      if (next == null) return;
      final capturedEvent = next;
      ref.read(dialogQueueProvider.notifier).enqueue(DialogRequest(
        id: 'regionTransform_${next.regionId}_${DateTime.now().millisecondsSinceEpoch}',
        priority: DialogPriority.high,
        dialogType: DialogTypeRegistry.regionTransform,
        payload: {'regionId': next.regionId},
        builder: (ctx, dismiss) => RegionTransformDialog(
          event: capturedEvent,
          onDismiss: dismiss,
        ),
      ));
      ref.read(regionTransformedProvider.notifier).state = null;
    });

    // ── 큐 → 단일 표시 listen ────────────────────────────────────────────────
    ref.listen<List<DialogRequest>>(dialogQueueProvider, (prev, next) {
      if (next.isEmpty || _isShowingDialog) return;
      _isShowingDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _isShowingDialog = false;
          return;
        }
        final head = next.first;
        showDialog<void>(
          context: context,
          barrierDismissible: head.priority != DialogPriority.critical,
          builder: (ctx) => head.builder(ctx, () => Navigator.of(ctx).pop()),
        ).then((_) {
          if (!mounted) {
            _isShowingDialog = false;
            return;
          }
          ref.read(dialogQueueProvider.notifier).dequeue();
          _isShowingDialog = false;
        });
      });
    });

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _screens[currentTab],
            if (selectedMercId != null)
              MercenaryDetailOverlay(mercenaryId: selectedMercId),
          ],
        ),
      ),
      bottomNavigationBar: selectedMercId == null
          ? BottomNavBar(
              currentIndex: currentTab,
              onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
            )
          : null,
    );
  }
}
