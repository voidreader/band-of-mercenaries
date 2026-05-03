import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/data/supabase_initializer.dart';
import 'package:band_of_mercenaries/core/data/sync_service.dart';
import 'package:band_of_mercenaries/core/data/data_loader.dart';
import 'package:band_of_mercenaries/core/data/region_migration_service.dart';
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

class _PostSyncApp extends ConsumerStatefulWidget {
  const _PostSyncApp();

  @override
  ConsumerState<_PostSyncApp> createState() => _PostSyncAppState();
}

class _PostSyncAppState extends ConsumerState<_PostSyncApp> {
  Future<void>? _migrationFuture;
  /// initializeNewGame() 중복 호출 방지 가드
  bool _newGameInitiated = false;

  /// build() 내 직접 변이 방지 — 1회만 Future 생성하여 캡슐화
  Future<void> _ensureMigrationStarted(StaticGameData data) {
    return _migrationFuture ??= RegionMigrationService.migrate(data).catchError(
      (Object e, StackTrace st) {
        debugPrint('[BOM][PostSync] 마이그레이션 실패: $e\n$st');
        throw e;
      },
    );
  }

  Widget _buildMigrationErrorScreen() {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '데이터 초기화에 실패했습니다.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '앱을 종료한 후 다시 실행해 주세요.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaticDataErrorScreen(Object error, StackTrace? stackTrace) {
    debugPrint('[BOM][PostSync] 정적 데이터 로딩 실패: $error\n$stackTrace');
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '데이터 로딩에 실패했습니다.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '네트워크 연결을 확인한 후 앱을 다시 실행해 주세요.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staticData = ref.watch(staticDataProvider);

    return staticData.when(
      data: (data) {
        final migrationFuture = _ensureMigrationStarted(data);
        return FutureBuilder<void>(
          future: migrationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const MaterialApp(
                home: Scaffold(body: Center(child: CircularProgressIndicator())),
              );
            }
            if (snapshot.hasError) {
              return _buildMigrationErrorScreen();
            }
            // 마이그레이션 완료 — userData 분기 진행
            final userData = ref.watch(userDataProvider);
            if (userData == null) {
              if (!_newGameInitiated) {
                _newGameInitiated = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  ref.read(userDataProvider.notifier).initializeNewGame();
                });
              }
              return const MaterialApp(
                home: Scaffold(body: Center(child: CircularProgressIndicator())),
              );
            }
            return const BandOfMercenariesApp();
          },
        );
      },
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, st) => _buildStaticDataErrorScreen(e, st),
    );
  }
}

