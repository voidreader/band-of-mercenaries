import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/achievement/domain/band_achievement_model.dart';
import 'package:band_of_mercenaries/features/achievement/domain/mercenary_snapshot_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/title/domain/flagship_mercenary_service.dart';

/// 테스트용 Mercenary 생성 helper — 필요한 필드만 오버라이드 가능.
Mercenary _merc({
  String id = 'test_id',
  String name = '테스트',
  int str = 10,
  int intelligence = 10,
  int vit = 10,
  int agi = 10,
  int level = 1,
  MercenaryStatus status = MercenaryStatus.normal,
  List<String>? titleIds,
  DateTime? recruitedAt,
}) {
  return Mercenary(
    id: id,
    name: name,
    jobId: 'farmer',
    traitId: 'strong',
    str: str,
    intelligence: intelligence,
    vit: vit,
    agi: agi,
    level: level,
    status: status,
    titleIds: titleIds,
    recruitedAt: recruitedAt,
  );
}

/// 테스트용 BandAchievement 생성 helper.
BandAchievement _achievement({
  required String mercId,
  String templateId = 'chain_some_chain',
}) {
  return BandAchievement(
    id: 'ach_$mercId',
    type: BandAchievementType.achievement,
    achievedAt: DateTime(2026),
    templateId: templateId,
    mercSnapshot: MercenarySnapshot(
      id: mercId,
      name: '용병',
      jobId: 'farmer',
      jobName: '농부',
      tier: 1,
    ),
  );
}

FlagshipMercenaryService _makeService({
  List<Mercenary> mercs = const [],
  List<BandAchievement> achievements = const [],
}) {
  return FlagshipMercenaryService(
    getMercenaries: () => mercs,
    getBandAchievements: () => achievements,
  );
}

void main() {
  group('FlagshipMercenaryService.selectAuto', () {
    test('1순위: titleIds 길이 차이 → 더 긴 쪽 선정', () {
      final a = _merc(id: 'a', titleIds: ['t1', 't2']);
      final b = _merc(id: 'b', titleIds: ['t1']);
      final service = _makeService(mercs: [b, a]);

      expect(service.selectAuto()?.id, 'a');
    });

    test('2순위: titleIds 동률 + 위업 카운트 차이 → 위업 많은 쪽 선정', () {
      final a = _merc(id: 'a', titleIds: ['t1']);
      final b = _merc(id: 'b', titleIds: ['t1']);
      final achievements = [
        _achievement(mercId: 'b'),
        _achievement(mercId: 'b'),
        _achievement(mercId: 'a'),
      ];
      final service = _makeService(mercs: [a, b], achievements: achievements);

      expect(service.selectAuto()?.id, 'b');
    });

    test('3순위: level 차이 → 레벨 높은 쪽 선정 (titleIds·위업 동률)', () {
      final a = _merc(id: 'a', level: 3, titleIds: ['t1']);
      final b = _merc(id: 'b', level: 5, titleIds: ['t1']);
      final service = _makeService(mercs: [a, b]);

      expect(service.selectAuto()?.id, 'b');
    });

    test('4순위: partyPower 차이 → 스탯 합산 높은 쪽 선정 (위 세 단계 동률)', () {
      // a: STR=10, INT=10, VIT=10, AGI=10 → power=10
      // b: STR=20, INT=20, VIT=20, AGI=20 → power=20
      final a = _merc(
        id: 'a',
        str: 10,
        intelligence: 10,
        vit: 10,
        agi: 10,
        level: 1,
        titleIds: [],
      );
      final b = _merc(
        id: 'b',
        str: 20,
        intelligence: 20,
        vit: 20,
        agi: 20,
        level: 1,
        titleIds: [],
      );
      final service = _makeService(mercs: [a, b]);

      expect(service.selectAuto()?.id, 'b');
    });

    test('5순위: recruitedAt 차이 → 이른 가입 우선 (위 네 단계 동률)', () {
      final earlier = _merc(
        id: 'early',
        recruitedAt: DateTime(2026, 1, 1),
      );
      final later = _merc(
        id: 'late',
        recruitedAt: DateTime(2026, 6, 1),
      );
      final service = _makeService(mercs: [later, earlier]);

      expect(service.selectAuto()?.id, 'early');
    });

    test('5순위: recruitedAt null은 DateTime(2000) fallback으로 최우선', () {
      final withNull = _merc(id: 'null_date', recruitedAt: null);
      final withDate = _merc(id: 'has_date', recruitedAt: DateTime(2026, 1, 1));
      final service = _makeService(mercs: [withDate, withNull]);

      // null = DateTime(2000)이 더 이르므로 우선
      expect(service.selectAuto()?.id, 'null_date');
    });

    test('dead 후보는 selectAuto 결과에서 제외', () {
      final alive = _merc(id: 'alive', status: MercenaryStatus.normal);
      final dead = _merc(
        id: 'dead',
        status: MercenaryStatus.dead,
        // titleIds 많아도 dead이면 제외
        titleIds: ['t1', 't2', 't3'],
      );
      final service = _makeService(mercs: [dead, alive]);

      expect(service.selectAuto()?.id, 'alive');
    });

    test('모든 후보가 dead이면 null 반환', () {
      final dead = _merc(id: 'dead', status: MercenaryStatus.dead);
      final service = _makeService(mercs: [dead]);

      expect(service.selectAuto(), isNull);
    });

    test('후보 없음 → null 반환', () {
      final service = _makeService(mercs: []);
      expect(service.selectAuto(), isNull);
    });
  });

  group('FlagshipMercenaryService.handleMercDeathOrRelease', () {
    test('현재 간판 id와 dead id 일치 → null 반환', () {
      final service = _makeService();
      final result = service.handleMercDeathOrRelease(
        'flagship_id',
        currentFlagshipMercId: 'flagship_id',
      );
      expect(result, isNull);
    });

    test('현재 간판 id와 dead id 불일치 → 기존 id 그대로 반환', () {
      final service = _makeService();
      final result = service.handleMercDeathOrRelease(
        'other_id',
        currentFlagshipMercId: 'flagship_id',
      );
      expect(result, 'flagship_id');
    });

    test('현재 간판 null + dead id → null 반환', () {
      final service = _makeService();
      final result = service.handleMercDeathOrRelease(
        'dead_id',
        currentFlagshipMercId: null,
      );
      expect(result, isNull);
    });
  });
}
