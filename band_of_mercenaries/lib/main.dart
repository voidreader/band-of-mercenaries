import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInitializer.initialize();
  runApp(const ProviderScope(child: AppBootstrap()));
}

class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(staticDataProvider);

    return staticData.when(
      data: (_) {
        final userData = ref.watch(userDataProvider);
        if (userData == null) {
          // First launch — initialize new game
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(userDataProvider.notifier).initializeNewGame();
          });
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        return _IdleRewardWrapper(child: const BandOfMercenariesApp());
      },
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => MaterialApp(
        home: Scaffold(body: Center(child: Text('로딩 실패: $e'))),
      ),
    );
  }
}

class _IdleRewardWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const _IdleRewardWrapper({required this.child});

  @override
  ConsumerState<_IdleRewardWrapper> createState() => _IdleRewardWrapperState();
}

class _IdleRewardWrapperState extends ConsumerState<_IdleRewardWrapper> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      _checked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkIdleReward());
    }
    return widget.child;
  }

  void _checkIdleReward() {
    final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
    final lastActiveMs = settingsBox.get('lastActiveTime') as int?;
    if (lastActiveMs == null) return;

    final lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveMs);
    final now = DateTime.now();
    final absentMinutes = now.difference(lastActive).inMinutes;

    if (absentMinutes < 1) return;

    final rewardMinutes = absentMinutes.clamp(0, 480);
    final reward = rewardMinutes;

    if (reward <= 0) return;

    ref.read(userDataProvider.notifier).addGold(reward);

    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('부재 보상'),
          content: Text(
            '${absentMinutes > 480 ? "8시간 이상" : "$absentMinutes분"} 동안 부재하셨습니다.\n'
            '${reward}G를 획득했습니다!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }

    settingsBox.put('lastActiveTime', now.millisecondsSinceEpoch);
  }
}
