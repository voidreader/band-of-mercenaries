import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/shared/widgets/bottom_nav_bar.dart';
import 'package:band_of_mercenaries/features/home/view/home_screen.dart';
import 'package:band_of_mercenaries/features/movement/view/movement_screen.dart';
import 'package:band_of_mercenaries/features/quest/view/dispatch_screen.dart';
import 'package:band_of_mercenaries/features/mercenary/view/recruit_screen.dart';
import 'package:band_of_mercenaries/features/settings/view/settings_screen.dart';

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

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = [
    MovementScreen(),
    DispatchScreen(),
    HomeScreen(),
    RecruitScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    return Scaffold(
      body: SafeArea(child: _screens[currentTab]),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentTab,
        onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
      ),
    );
  }
}
