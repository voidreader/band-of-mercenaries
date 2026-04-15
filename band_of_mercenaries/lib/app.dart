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
import 'package:band_of_mercenaries/features/mercenary/view/mercenary_detail_overlay.dart';

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
    });

    ref.listen<String?>(constructionCompletedProvider, (_, next) {
      if (next == null) return;
      final staticData = ref.read(staticDataProvider).value;
      final facilityName = staticData?.facilities
          .where((f) => f.id == next)
          .firstOrNull
          ?.name ?? next;
      final userData = ref.read(userDataProvider);
      final newLevel = userData?.facilities[next] ?? 1;
      ref.read(activityLogProvider.notifier).addLog(
        '$facilityName이(가) Lv.$newLevel(으)로 업그레이드되었습니다',
        ActivityLogType.facilityUpgrade,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('건설 완료'),
            content: Text('$facilityName이(가) 업그레이드되었습니다!'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(constructionCompletedProvider.notifier).state = null;
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      });
    });

    ref.listen<InvestigationResult?>(investigationCompletedProvider, (_, next) {
      if (next == null) return;
      final mercs = ref.read(mercenaryListProvider);
      final mercName = mercs.where((m) => m.id == next.mercId).firstOrNull?.name ?? next.mercId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => InvestigationResultDialog(result: next, mercName: mercName),
        ).then((_) {
          ref.read(investigationCompletedProvider.notifier).state = null;
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
