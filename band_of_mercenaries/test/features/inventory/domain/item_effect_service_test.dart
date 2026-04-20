import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';
import 'package:band_of_mercenaries/features/inventory/domain/equipment_stat_bonus.dart';
import 'package:band_of_mercenaries/features/inventory/domain/legendary_effect.dart';
import 'package:band_of_mercenaries/features/inventory/domain/item_effect_service.dart';
import 'package:band_of_mercenaries/core/models/passive_effect.dart';

/// 테스트용 ItemData 생성 헬퍼.
ItemData _item(
  String id,
  String category,
  String slot,
  Map<String, dynamic> effect,
) =>
    ItemData(
      id: id,
      name: id,
      description: '',
      flavorText: '',
      category: category,
      slot: slot,
      tier: 3,
      effectJson: effect,
    );

/// 테스트용 InventoryItem 생성 헬퍼.
InventoryItem _inv(String id, String itemId, String? equippedTo) =>
    InventoryItem(
      id: id,
      itemId: itemId,
      quantity: 1,
      equippedTo: equippedTo,
      acquiredAt: DateTime(2026, 4, 19),
    );

void main() {
  group('resolvePersonalEquipment', () {
    test('STR weapon은 statBonus.str=15, legendary=null', () {
      final item = _item('w1', 'personal_equipment', 'weapon', {'str': 15});
      final effect = ItemEffectService.resolvePersonalEquipment(item);
      expect(effect.statBonus.str, 15);
      expect(effect.legendary, isNull);
    });

    test('category 불일치 시 zero 반환', () {
      final item = _item('x', 'guild_equipment', 'banner', {'str': 99});
      final effect = ItemEffectService.resolvePersonalEquipment(item);
      expect(effect.statBonus, EquipmentStatBonus.zero);
    });

    test('전설 ③ damage_resistance 파싱', () {
      final item = _item('leg1', 'personal_equipment', 'accessory', {
        'vit': 11,
        'legendary_effect': {
          'category': 'damage_resistance',
          'injury_rate_modifier': -0.10,
          'death_rate_modifier': -0.05,
        },
      });
      final effect = ItemEffectService.resolvePersonalEquipment(item);
      expect(effect.statBonus.vit, 11);
      expect(effect.legendary, isA<LegendaryDamageResistance>());
      final leg = effect.legendary as LegendaryDamageResistance;
      expect(leg.injuryMod, -0.10);
      expect(leg.deathMod, -0.05);
    });

    test('전설 ② result_upgrade 파싱', () {
      final item = _item('leg2', 'personal_equipment', 'weapon', {
        'str': 18,
        'legendary_effect': {
          'category': 'result_upgrade',
          'success_to_great_chance': 0.05,
        },
      });
      final leg = ItemEffectService.resolvePersonalEquipment(item).legendary;
      expect(leg, isA<LegendaryResultUpgrade>());
      expect((leg as LegendaryResultUpgrade).chance, 0.05);
    });

    test('전설 ④ reward_bonus 파싱', () {
      final item = _item('leg4', 'personal_equipment', 'accessory', {
        'agi': 11,
        'legendary_effect': {
          'category': 'reward_bonus',
          'gold_reward_multiplier': 0.10,
        },
      });
      final leg = ItemEffectService.resolvePersonalEquipment(item).legendary;
      expect(leg, isA<LegendaryRewardBonus>());
      expect((leg as LegendaryRewardBonus).multiplier, 0.10);
    });

    test('전설 ⑤ special 파싱', () {
      final item = _item('leg5', 'personal_equipment', 'accessory', {
        'vit': 11,
        'legendary_effect': {
          'category': 'special',
          'death_prevention_count': 1,
          'cooldown_hours': 24,
        },
      });
      final leg = ItemEffectService.resolvePersonalEquipment(item).legendary;
      expect(leg, isA<LegendarySpecial>());
      final s = leg as LegendarySpecial;
      expect(s.deathPreventionCount, 1);
      expect(s.cooldownHours, 24);
    });

    test('전설 ① success_rate_bonus raid 키 파싱', () {
      final item = _item('leg1', 'personal_equipment', 'weapon', {
        'str': 18,
        'legendary_effect': {
          'category': 'success_rate_bonus',
          'raid_success_rate': 0.05,
        },
      });
      final leg = ItemEffectService.resolvePersonalEquipment(item).legendary;
      expect(leg, isA<LegendarySuccessRateBonus>());
      final s = leg as LegendarySuccessRateBonus;
      expect(s.questType, 'raid');
      expect(s.value, 0.05);
    });

    test('effectJson 비어있으면 zero 반환', () {
      final item = _item('empty', 'personal_equipment', 'weapon', {});
      final effect = ItemEffectService.resolvePersonalEquipment(item);
      expect(effect.statBonus, EquipmentStatBonus.zero);
      expect(effect.legendary, isNull);
    });

    test('복수 스탯 키(str+vit) 모두 파싱', () {
      final item = _item(
        'multi',
        'personal_equipment',
        'armor',
        {'str': 5, 'vit': 10, 'agi': 3},
      );
      final bonus = ItemEffectService.resolvePersonalEquipment(item).statBonus;
      expect(bonus.str, 5);
      expect(bonus.vit, 10);
      expect(bonus.agi, 3);
      expect(bonus.intelligence, 0);
    });
  });

  group('resolveGuildEquipment', () {
    test('깃발 복합 효과 → 2개 PassiveEffect', () {
      final item = _item('banner', 'guild_equipment', 'banner', {
        'reputation_gain_modifier': 0.05,
        'gold_reward_multiplier': 0.02,
      });
      final effects = ItemEffectService.resolveGuildEquipment(item);
      expect(effects.length, 2);
      expect(
        effects.whereType<ReputationGainModifierEffect>().first.value,
        0.05,
      );
      expect(
        effects.whereType<QuestRewardMultiplierEffect>().first.value,
        0.02,
      );
    });

    test('injury_rate_modifier 단일 키', () {
      final item = _item('shield', 'guild_equipment', 'artifact', {
        'injury_rate_modifier': -0.07,
      });
      final effects = ItemEffectService.resolveGuildEquipment(item);
      expect(effects.length, 1);
      expect(effects.first, isA<InjuryRateModifierEffect>());
      expect((effects.first as InjuryRateModifierEffect).value, -0.07);
    });

    test('recruit_high_tier_chance → RecruitmentTierBoostEffect(tierMin:4, tierMax:5)', () {
      final item = _item('horn', 'guild_equipment', 'artifact', {
        'recruit_high_tier_chance': 0.02,
      });
      final effects = ItemEffectService.resolveGuildEquipment(item);
      expect(effects.length, 1);
      expect(effects.first, isA<RecruitmentTierBoostEffect>());
      final e = effects.first as RecruitmentTierBoostEffect;
      expect(e.tierMin, 4);
      expect(e.tierMax, 5);
      expect(e.value, 0.02);
    });

    test('category 불일치 시 빈 리스트 반환', () {
      final item =
          _item('sword', 'personal_equipment', 'weapon', {'str': 10});
      final effects = ItemEffectService.resolveGuildEquipment(item);
      expect(effects, isEmpty);
    });

    test('알 수 없는 키는 무시(fail-soft)', () {
      final item = _item('weird', 'guild_equipment', 'artifact', {
        'unknown_key': 99.0,
        'gold_reward_multiplier': 0.03,
      });
      final effects = ItemEffectService.resolveGuildEquipment(item);
      // unknown_key는 무시하고 유효 키 1개만 반환.
      expect(effects.length, 1);
      expect(effects.first, isA<QuestRewardMultiplierEffect>());
    });
  });

  group('aggregateMercenaryEquipment', () {
    test('동일 mercId 아이템 2개 합산', () {
      final items = [
        _item('w1', 'personal_equipment', 'weapon', {'str': 15}),
        _item('a1', 'personal_equipment', 'armor', {'vit': 15}),
      ];
      final inv = [
        _inv('i1', 'w1', 'merc-1'),
        _inv('i2', 'a1', 'merc-1'),
        _inv('i3', 'w1', 'merc-2'), // 다른 용병 — 합산 제외.
      ];
      final bonus = ItemEffectService.aggregateMercenaryEquipment(
        mercenaryId: 'merc-1',
        inventory: inv,
        items: items,
      );
      expect(bonus.str, 15);
      expect(bonus.vit, 15);
    });

    test('해당 용병의 아이템이 없으면 zero 반환', () {
      final items = [
        _item('w1', 'personal_equipment', 'weapon', {'str': 10}),
      ];
      final inv = [
        _inv('i1', 'w1', 'merc-99'), // 다른 용병.
      ];
      final bonus = ItemEffectService.aggregateMercenaryEquipment(
        mercenaryId: 'merc-1',
        inventory: inv,
        items: items,
      );
      expect(bonus, EquipmentStatBonus.zero);
    });

    test('itemId 미존재 아이템은 skip', () {
      final items = <ItemData>[]; // items 목록 비어있음.
      final inv = [_inv('i1', 'nonexistent', 'merc-1')];
      final bonus = ItemEffectService.aggregateMercenaryEquipment(
        mercenaryId: 'merc-1',
        inventory: inv,
        items: items,
      );
      expect(bonus, EquipmentStatBonus.zero);
    });
  });

  group('collectLegendaryEffects', () {
    test('전설 아이템 1개 수집', () {
      final items = [
        _item('leg', 'personal_equipment', 'weapon', {
          'str': 18,
          'legendary_effect': {
            'category': 'result_upgrade',
            'success_to_great_chance': 0.05,
          },
        }),
      ];
      final inv = [_inv('i1', 'leg', 'merc-1')];
      final legendaries = ItemEffectService.collectLegendaryEffects(
        mercenaryId: 'merc-1',
        inventory: inv,
        items: items,
      );
      expect(legendaries.length, 1);
      expect(legendaries.first, isA<LegendaryResultUpgrade>());
    });

    test('legendary 없는 아이템은 결과에 포함되지 않음', () {
      final items = [
        _item('plain', 'personal_equipment', 'armor', {'vit': 12}),
      ];
      final inv = [_inv('i1', 'plain', 'merc-1')];
      final legendaries = ItemEffectService.collectLegendaryEffects(
        mercenaryId: 'merc-1',
        inventory: inv,
        items: items,
      );
      expect(legendaries, isEmpty);
    });
  });

  group('collectGuildPassiveEffects', () {
    test('banner + artifacts 순차 수집', () {
      final items = [
        _item('banner', 'guild_equipment', 'banner', {
          'reputation_gain_modifier': 0.05,
        }),
        _item('scale', 'guild_equipment', 'artifact', {
          'gold_reward_multiplier': 0.03,
        }),
      ];
      final effects = ItemEffectService.collectGuildPassiveEffects(
        bannerItemId: 'banner',
        artifactItemIds: ['scale'],
        items: items,
      );
      expect(effects.length, 2);
    });

    test('banner null 시 artifacts만 수집', () {
      final items = [
        _item('horn', 'guild_equipment', 'artifact', {
          'recruit_high_tier_chance': 0.02,
        }),
      ];
      final effects = ItemEffectService.collectGuildPassiveEffects(
        bannerItemId: null,
        artifactItemIds: ['horn'],
        items: items,
      );
      expect(effects.length, 1);
      expect(effects.first, isA<RecruitmentTierBoostEffect>());
    });

    test('존재하지 않는 id는 skip', () {
      final items = <ItemData>[];
      final effects = ItemEffectService.collectGuildPassiveEffects(
        bannerItemId: 'missing_banner',
        artifactItemIds: ['missing_artifact'],
        items: items,
      );
      expect(effects, isEmpty);
    });

    test('artifacts 2개 모두 수집', () {
      final items = [
        _item('art1', 'guild_equipment', 'artifact', {
          'injury_rate_modifier': -0.05,
        }),
        _item('art2', 'guild_equipment', 'artifact', {
          'gold_reward_multiplier': 0.03,
        }),
      ];
      final effects = ItemEffectService.collectGuildPassiveEffects(
        bannerItemId: null,
        artifactItemIds: ['art1', 'art2'],
        items: items,
      );
      expect(effects.length, 2);
      expect(effects.whereType<InjuryRateModifierEffect>().length, 1);
      expect(effects.whereType<QuestRewardMultiplierEffect>().length, 1);
    });
  });
}
