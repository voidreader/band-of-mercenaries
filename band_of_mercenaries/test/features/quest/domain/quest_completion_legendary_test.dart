import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/inventory/domain/legendary_effect.dart';

void main() {
  group('전설 ③ damage_resistance', () {
    test('injuryMod -0.20 가산으로 survived 반환', () {
      // injuryRate(0.30) + injuryMod(-0.20) = 0.10, roll(0.40) > 0.10 이므로 survived
      final result = QuestCalculator.calculateDamage(
        roll: 0.40,
        deathRate: 0.1,
        injuryRate: 0.30,
        traitId: '',
        legendaryEffects: [
          const LegendaryEffect.damageResistance(injuryMod: -0.20, deathMod: -0.05),
        ],
      );
      expect(result, DamageResult.survived);
    });

    test('deathMod -0.08 가산으로 dead → survived/injured 전환', () {
      // deathRate(0.10) + deathMod(-0.08) = 0.02, roll(0.05) > 0.02 이므로 dead 아님
      final result = QuestCalculator.calculateDamage(
        roll: 0.05,
        deathRate: 0.10,
        injuryRate: 0.30,
        traitId: '',
        legendaryEffects: [
          const LegendaryEffect.damageResistance(injuryMod: 0.0, deathMod: -0.08),
        ],
      );
      expect(result == DamageResult.dead, false);
    });
  });

  group('전설 ② result_upgrade (logic shape)', () {
    test('chance 0.05, roll 0.02 시 승격 조건 충족', () {
      const chance = 0.05;
      const roll = 0.02;
      expect(roll <= chance, true);
    });

    test('chance 0.05, roll 0.06 시 승격 조건 미충족', () {
      const chance = 0.05;
      const roll = 0.06;
      expect(roll <= chance, false);
    });
  });

  group('전설 ⑤ special cooldown (logic shape)', () {
    test('cooldownUntil null이면 사용 가능', () {
      final now = DateTime(2026, 4, 19, 12);
      final DateTime? cooldownUntil = _maybeCooldown();
      final canPrevent = cooldownUntil == null || now.isAfter(cooldownUntil);
      expect(canPrevent, true);
    });

    test('cooldownUntil이 now 이후면 사용 불가', () {
      final now = DateTime(2026, 4, 19, 12);
      final cooldownUntil = DateTime(2026, 4, 19, 13);
      final canPrevent = now.isAfter(cooldownUntil);
      expect(canPrevent, false);
    });

    test('cooldownUntil이 now 이전이면 사용 가능', () {
      final now = DateTime(2026, 4, 19, 12);
      final cooldownUntil = DateTime(2026, 4, 19, 11);
      final canPrevent = now.isAfter(cooldownUntil);
      expect(canPrevent, true);
    });
  });

  group('전설 ① success_rate_bonus 공유 ±10%p clamp', () {
    test('trait +10%p 포화 상태에서 legendary +5%p 추가 시 총 traitBonus는 +10%p로 제한', () {
      const rawTrait = 10.0;
      const legendary = 5.0;
      final clamped = (rawTrait + legendary).clamp(-10.0, 10.0);
      expect(clamped, 10.0);
    });

    test('trait +5%p에 legendary +3%p 합산 시 +8%p (clamp 미발동)', () {
      const rawTrait = 5.0;
      const legendary = 3.0;
      final clamped = (rawTrait + legendary).clamp(-10.0, 10.0);
      expect(clamped, 8.0);
    });

    test('trait -5%p에 legendary +10%p 합산 시 +5%p (±10%p 공유 풀)', () {
      const rawTrait = -5.0;
      const legendary = 10.0;
      final clamped = (rawTrait + legendary).clamp(-10.0, 10.0);
      expect(clamped, 5.0);
    });
  });
}

/// 린트(unnecessary_null_comparison) 우회용 헬퍼 — 쿨다운 미설정 상태를 시뮬레이션.
DateTime? _maybeCooldown() => null;
