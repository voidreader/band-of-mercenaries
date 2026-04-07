import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        return const BandOfMercenariesApp();
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
