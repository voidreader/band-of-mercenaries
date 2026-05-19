import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_shop_daily_entry.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';

void main() {
  late Directory tempDir;
  late Box<FactionState> box;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('faction_state_repo_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(FactionStateAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(FactionClueRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(FactionShopDailyEntryAdapter());
    }
    box = await Hive.openBox<FactionState>(HiveInitializer.factionStateBoxName);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk(HiveInitializer.factionStateBoxName);
    tempDir.deleteSync(recursive: true);
  });

  group('FactionStateRepository.recordShopPurchase', () {
    test('daily 재고가 리스톡 시각을 지나면 구매 카운트를 1부터 다시 기록한다', () async {
      final repository = FactionStateRepository();
      await box.add(
        FactionState(
          factionId: 'faction_merchants_alliance',
          shopDailyPurchases: {
            'm8a_mer_sealed_contract': FactionShopDailyEntry(
              count: 2,
              restockAt: DateTime.now().subtract(const Duration(minutes: 1)),
            ),
          },
        ),
      );

      await repository.recordShopPurchase(
        factionId: 'faction_merchants_alliance',
        itemId: 'm8a_mer_sealed_contract',
        isDaily: true,
        restockAfter: const Duration(hours: 24),
      );

      final state = repository.getState('faction_merchants_alliance')!;
      final entry =
          state.effectiveShopDailyPurchases['m8a_mer_sealed_contract']!;
      expect(entry.count, 1);
      expect(entry.restockAt, isNotNull);
      expect(entry.restockAt!.isAfter(DateTime.now()), isTrue);
    });
  });
}
