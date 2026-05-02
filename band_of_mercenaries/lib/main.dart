import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/data/supabase_initializer.dart';
import 'package:band_of_mercenaries/core/data/sync_service.dart';
import 'package:band_of_mercenaries/core/data/data_loader.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 전역 에러 캡처 — 향후 Crashlytics/Sentry 연동 포인트
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // 외부 에러 리포팅 서비스 연동
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack, library: 'root'),
    );
    // 외부 에러 리포팅 서비스 연동
    return true;
  };

  await HiveInitializer.initialize();
  await SupabaseInitializer.initialize();
  runApp(const ProviderScope(child: AppBootstrap()));
}

class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({super.key});

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  late Future<SyncStatus> _syncFuture;

  @override
  void initState() {
    super.initState();
    _syncFuture = _performSync();
  }

  Future<SyncStatus> _performSync() async {
    final cacheBox = Hive.box<String>(HiveInitializer.staticDataCacheBoxName);
    final syncService = SyncService(
      client: SupabaseInitializer.client,
      dataLoader: DataLoader(cacheBox: cacheBox),
    );
    return syncService.sync();
  }

  void _retry() {
    setState(() {
      _syncFuture = _performSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SyncStatus>(
      future: _syncFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('데이터 동기화 중...'),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('서버 연결에 실패했습니다.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('재시도'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const _PostSyncApp();
      },
    );
  }
}

class _PostSyncApp extends ConsumerWidget {
  const _PostSyncApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(staticDataProvider);

    return staticData.when(
      data: (_) {
        final userData = ref.watch(userDataProvider);
        if (userData == null) {
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
        home: Scaffold(body: Center(child: Text('데이터 로딩 실패: $e'))),
      ),
    );
  }
}

