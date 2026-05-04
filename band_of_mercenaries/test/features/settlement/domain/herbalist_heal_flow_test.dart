import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/features/mercenary/data/mercenary_repository.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

void main() {
  late Directory tempDir;
  late MercenaryRepository repo;
  late Box<Mercenary> box;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('heal_flow_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MercenaryStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MercenaryAdapter());
    }
    box = await Hive.openBox<Mercenary>(HiveInitializer.mercenaryBoxName);
    repo = MercenaryRepository();
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk(HiveInitializer.mercenaryBoxName);
    tempDir.deleteSync(recursive: true);
  });

  test('부상 용병 → healInstant → status normal + injuryEndTime null', () async {
    final merc = Mercenary(
      id: 'test_merc_1',
      name: '테스트 용병',
      jobId: 'warrior_1',
      traitId: '',
      str: 10,
      intelligence: 5,
      vit: 8,
      agi: 6,
      status: MercenaryStatus.injured,
      injuryEndTime: DateTime.now().add(const Duration(minutes: 30)),
    );
    await box.add(merc);

    await repo.healInstant('test_merc_1');

    final updated = box.values.firstWhere((m) => m.id == 'test_merc_1');
    expect(updated.status, MercenaryStatus.normal);
    expect(updated.injuryEndTime, null);
    expect(updated.tiredEndTime, null);
  });

  test('피로 용병 → healInstant → status normal + tiredEndTime null', () async {
    final merc = Mercenary(
      id: 'test_merc_2',
      name: '피로 용병',
      jobId: 'warrior_1',
      traitId: '',
      str: 10,
      intelligence: 5,
      vit: 8,
      agi: 6,
      status: MercenaryStatus.tired,
      tiredEndTime: DateTime.now().add(const Duration(minutes: 5)),
    );
    await box.add(merc);

    await repo.healInstant('test_merc_2');

    final updated = box.values.firstWhere((m) => m.id == 'test_merc_2');
    expect(updated.status, MercenaryStatus.normal);
    expect(updated.tiredEndTime, null);
    expect(updated.injuryEndTime, null);
  });

  test('존재하지 않는 mercId → StateError throw', () async {
    expect(
      () async => await repo.healInstant('non_existent_merc'),
      throwsA(isA<StateError>()),
    );
  });
}
