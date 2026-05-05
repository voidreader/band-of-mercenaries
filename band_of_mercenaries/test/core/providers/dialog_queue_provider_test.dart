import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/dialog_queue_persistence.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/models/dialog_request.dart';
import 'package:band_of_mercenaries/core/models/persisted_dialog_entry.dart';
import 'package:band_of_mercenaries/core/providers/dialog_queue_provider.dart';

void main() {
  late Directory tempDir;
  late Box<PersistedDialogEntry> box;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('dialog_queue_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(PersistedDialogEntryAdapter());
    }
    box = await Hive.openBox<PersistedDialogEntry>(
      HiveInitializer.dialogQueueBoxName,
    );
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk(HiveInitializer.dialogQueueBoxName);
    tempDir.deleteSync(recursive: true);
  });

  group('DialogQueueNotifier', () {
    test('앱 시작 시 24시간 이내의 등록된 다이얼로그를 큐로 복원한다', () async {
      await box.add(
        PersistedDialogEntry(
          id: 'rankUp_A',
          priority: DialogPriority.critical.index,
          dialogType: DialogTypeRegistry.rankUp,
          payloadJson: '{"toGrade":"A"}',
          enqueuedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );

      final notifier = DialogQueueNotifier(DialogQueuePersistence(box));
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state, hasLength(1));
      expect(notifier.state.first.id, 'rankUp_A');
      expect(notifier.state.first.dialogType, DialogTypeRegistry.rankUp);
      expect(notifier.state.first.payload, {'toGrade': 'A'});
    });
  });
}
