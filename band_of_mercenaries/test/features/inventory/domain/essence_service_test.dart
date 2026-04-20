import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/features/inventory/domain/essence_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

/// 테스트용 정수(essence) ItemData 생성 헬퍼.
/// category=consumable, effect_json = {permanent_stat_gain: {statKey: gain}}
ItemData _makeEssence({
  required int tier,
  required String statKey,
  int? gainOverride,
  String? category,
}) {
  final gain = gainOverride ?? EssenceService.tierGainTable[tier]!;
  return ItemData(
    id: 'essence_${statKey}_t$tier',
    name: 'Test Essence T$tier',
    description: '',
    flavorText: '',
    category: category ?? 'consumable',
    slot: 'essence_$statKey',
    tier: tier,
    effectJson: {
      'permanent_stat_gain': {statKey: gain},
    },
  );
}

/// 테스트용 Mercenary 생성 헬퍼.
/// 기본 level 1, 피로 없음(normal), permanent* 파라미터 지정 가능.
Mercenary _makeMerc({
  String statKey = 'str',
  int baseStat = 20,
  int permanent = 0,
  int level = 1,
}) {
  return Mercenary(
    id: 'test-merc',
    name: 'Test',
    jobId: 'job1',
    traitId: '',
    // statKey에 따라 해당 축에만 baseStat 배정, 나머지는 0
    str: statKey == 'str' ? baseStat : 0,
    intelligence: statKey == 'intelligence' ? baseStat : 0,
    vit: statKey == 'vit' ? baseStat : 0,
    agi: statKey == 'agi' ? baseStat : 0,
    level: level,
    permanentStr: statKey == 'str' ? permanent : 0,
    permanentIntelligence: statKey == 'intelligence' ? permanent : 0,
    permanentVit: statKey == 'vit' ? permanent : 0,
    permanentAgi: statKey == 'agi' ? permanent : 0,
  );
}

void main() {
  group('EssenceService.resolve', () {
    test('category != consumable이면 null 반환', () {
      // personal_equipment 카테고리는 정수 아이템이 아님
      final item = _makeEssence(
        tier: 1,
        statKey: 'str',
        category: 'personal_equipment',
      );
      expect(EssenceService.resolve(item), isNull);
    });

    test('effect_json.permanent_stat_gain 누락 시 null', () {
      final item = ItemData(
        id: 'bad',
        name: 'x',
        description: '',
        flavorText: '',
        category: 'consumable',
        slot: 'essence_str',
        tier: 1,
        effectJson: {}, // permanent_stat_gain 키 없음
      );
      expect(EssenceService.resolve(item), isNull);
    });

    test('statKey가 허용 집합(str/intelligence/vit/agi) 아니면 null', () {
      final item = ItemData(
        id: 'bad',
        name: 'x',
        description: '',
        flavorText: '',
        category: 'consumable',
        slot: 'essence_unknown',
        tier: 1,
        effectJson: {
          'permanent_stat_gain': {'unknown': 1},
        },
      );
      expect(EssenceService.resolve(item), isNull);
    });

    test('정상 데이터 → EssenceDescriptor 반환 (tier 3, str, gain=4)', () {
      final item = _makeEssence(tier: 3, statKey: 'str');
      final desc = EssenceService.resolve(item);
      expect(desc, isNotNull);
      expect(desc!.statKey, 'str');
      expect(desc.gain, 4); // tier 3 → +4
      expect(desc.tier, 3);
    });

    test('모든 4축 × 5티어 매트릭스 정상 파싱', () {
      // str/intelligence/vit/agi × tier 1~5 = 20가지 조합 모두 검증
      for (final statKey in ['str', 'intelligence', 'vit', 'agi']) {
        for (var tier = 1; tier <= 5; tier++) {
          final desc =
              EssenceService.resolve(_makeEssence(tier: tier, statKey: statKey));
          expect(desc, isNotNull,
              reason: '$statKey T$tier 파싱 실패');
          expect(desc!.statKey, statKey);
          expect(desc.gain, EssenceService.tierGainTable[tier]);
        }
      }
    });
  });

  group('EssenceService.preview', () {
    test('잔량 충분 → warningLevel == normal', () {
      // T3 cap = 40, permanent = 0, T1 gain = +1 → 사용 후 1, 잔량 39 > 1 → normal
      final m = _makeMerc(permanent: 0);
      final essence = _makeEssence(tier: 1, statKey: 'str'); // +1
      final p = EssenceService.preview(
        mercenary: m,
        essence: essence,
        mercenaryTier: 3,
      );
      expect(p.appliedGain, 1);
      expect(p.lossAmount, 0);
      expect(p.warningLevel, EssencePreviewLevel.normal);
    });

    test('잔량 < gain → warningLevel == approaching (손실은 없지만 다음 사용 위험)', () {
      // T3 cap = 40, permanent = 33, T3 gain = +4
      // 사용 후 newPermanent = 37, remainingAfter = 3, gain = 4 → 3 < 4 → approaching
      final m = _makeMerc(permanent: 33);
      final essence = _makeEssence(tier: 3, statKey: 'str'); // +4
      final p = EssenceService.preview(
        mercenary: m,
        essence: essence,
        mercenaryTier: 3,
      );
      expect(p.appliedGain, 4);
      expect(p.lossAmount, 0);
      expect(p.warningLevel, EssencePreviewLevel.approaching);
    });

    test('상한 초과 → overflow + lossAmount > 0', () {
      // T3 cap = 40, permanent = 38, T3 gain = +4 → appliedGain=2, loss=2
      final m = _makeMerc(permanent: 38);
      final essence = _makeEssence(tier: 3, statKey: 'str'); // +4
      final p = EssenceService.preview(
        mercenary: m,
        essence: essence,
        mercenaryTier: 3,
      );
      expect(p.appliedGain, 2);
      expect(p.lossAmount, 2);
      expect(p.warningLevel, EssencePreviewLevel.overflow);
    });

    test('이미 상한 완전 도달 → appliedGain == 0 + overflow', () {
      // T3 cap = 40, permanent = 40 → 잔량 0 → appliedGain=0, loss=4
      final m = _makeMerc(permanent: 40);
      final essence = _makeEssence(tier: 3, statKey: 'str'); // +4
      final p = EssenceService.preview(
        mercenary: m,
        essence: essence,
        mercenaryTier: 3,
      );
      expect(p.appliedGain, 0);
      expect(p.lossAmount, 4);
      expect(p.warningLevel, EssencePreviewLevel.overflow);
    });

    test('티어별 상한 검증 — T1 cap 10', () {
      // T1 cap = 10, permanent = 9, T1 gain = +1 → 사용 후 10, lossAmount=0
      final m = _makeMerc(permanent: 9);
      final essence = _makeEssence(tier: 1, statKey: 'str'); // +1
      final p = EssenceService.preview(
        mercenary: m,
        essence: essence,
        mercenaryTier: 1,
      );
      expect(p.cap, 10);
      expect(p.appliedGain, 1);
      expect(p.lossAmount, 0);
    });

    test('티어별 상한 검증 — T5 cap 120, 부분 손실', () {
      // T5 cap = 120, permanent = 110, T5 gain = +11
      // appliedGain = min(11, 120-110) = min(11, 10) = 10, lossAmount = 1
      final m = _makeMerc(permanent: 110);
      final essence = _makeEssence(tier: 5, statKey: 'str'); // +11
      final p = EssenceService.preview(
        mercenary: m,
        essence: essence,
        mercenaryTier: 5,
      );
      expect(p.cap, 120);
      expect(p.appliedGain, 10);
      expect(p.lossAmount, 1);
    });

    test('effectiveBefore/After 계산 — Lv5 용병 str=25, permanent 0 → +4 적용', () {
      // _levelBonus = (5-1)*0.1 = 0.4
      // effectiveBefore = (25+0) * 1.4 = 35
      // effectiveAfter = (25+0+4) * 1.4 = 29*1.4 = 40.6 → round → 41
      final m = _makeMerc(baseStat: 25, permanent: 0, level: 5);
      final essence = _makeEssence(tier: 3, statKey: 'str'); // +4
      final p = EssenceService.preview(
        mercenary: m,
        essence: essence,
        mercenaryTier: 3,
      );
      expect(p.effectiveBefore, 35);
      expect(p.effectiveAfter, 41);
    });

    test('각 stat 축 독립성 — str permanent가 있어도 intelligence 적용에 영향 없음', () {
      // str permanent = 5인 용병에 intelligence 정수 적용
      // intelligence permanent = 0이어야 하고 appliedGain = 2 (T2 gain)
      final m = _makeMerc(statKey: 'str', permanent: 5);
      final essence = _makeEssence(tier: 2, statKey: 'intelligence'); // +2
      final p = EssenceService.preview(
        mercenary: m,
        essence: essence,
        mercenaryTier: 3, // T3 용병 기준 cap = 40
      );
      expect(p.statKey, 'intelligence');
      expect(p.currentPermanent, 0); // intelligence permanent는 0
      expect(p.appliedGain, 2);
    });
  });
}
