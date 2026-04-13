import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/data/supabase_initializer.dart';
import 'package:band_of_mercenaries/core/data/sync_service.dart';
import 'package:band_of_mercenaries/core/data/settings_keys.dart';
import 'package:band_of_mercenaries/core/data/data_loader.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/shared/widgets/bottom_nav_bar.dart';
import 'package:band_of_mercenaries/features/home/view/home_screen.dart';
import 'package:band_of_mercenaries/features/movement/view/movement_screen.dart';
import 'package:band_of_mercenaries/features/quest/view/dispatch_screen.dart';
import 'package:band_of_mercenaries/features/mercenary/view/recruit_screen.dart';
import 'package:band_of_mercenaries/features/settings/view/settings_screen.dart';
import 'package:band_of_mercenaries/core/providers/mercenary_detail_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/view/mercenary_detail_overlay.dart';

final currentTabProvider = StateProvider<int>((ref) => 2); // Home is default

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
    SettingsScreen(),
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
