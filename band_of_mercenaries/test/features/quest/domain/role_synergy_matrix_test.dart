import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/role_synergy_matrix.dart';

void main() {
  group('RoleSynergyMatrix.singleBonus', () {
    test('warrior는 raid에서 +8', () {
      expect(RoleSynergyMatrix.singleBonus('warrior', 'raid'), 8.0);
    });
    test('mage는 raid에서 -2', () {
      expect(RoleSynergyMatrix.singleBonus('mage', 'raid'), -2.0);
    });
    test('support는 escort에서 +8', () {
      expect(RoleSynergyMatrix.singleBonus('support', 'escort'), 8.0);
    });
    test('specialist는 모든 유형에서 +2', () {
      expect(RoleSynergyMatrix.singleBonus('specialist', 'raid'), 2.0);
      expect(RoleSynergyMatrix.singleBonus('specialist', 'hunt'), 2.0);
      expect(RoleSynergyMatrix.singleBonus('specialist', 'escort'), 2.0);
      expect(RoleSynergyMatrix.singleBonus('specialist', 'explore'), 2.0);
    });
    test('알 수 없는 role은 specialist로 fallback', () {
      expect(RoleSynergyMatrix.singleBonus('unknown_role', 'raid'), 2.0);
      expect(RoleSynergyMatrix.singleBonus('', 'explore'), 2.0);
    });
    test('알 수 없는 quest_type은 0', () {
      expect(RoleSynergyMatrix.singleBonus('warrior', 'unknown_type'), 0.0);
    });
  });

  group('RoleSynergyMatrix.partyAverageBonus', () {
    test('빈 파티는 0.0', () {
      expect(
        RoleSynergyMatrix.partyAverageBonus(
          partyRoles: const [],
          questTypeId: 'raid',
        ),
        0.0,
      );
    });
    test('warrior 2인 파티 raid → +8', () {
      expect(
        RoleSynergyMatrix.partyAverageBonus(
          partyRoles: const ['warrior', 'warrior'],
          questTypeId: 'raid',
        ),
        8.0,
      );
    });
    test('warrior+mage 파티 raid → 평균 +3 ((8+-2)/2)', () {
      expect(
        RoleSynergyMatrix.partyAverageBonus(
          partyRoles: const ['warrior', 'mage'],
          questTypeId: 'raid',
        ),
        3.0,
      );
    });
    test('warrior+rogue+rogue 파티 raid → 평균 6.0 ((8+5+5)/3)', () {
      expect(
        RoleSynergyMatrix.partyAverageBonus(
          partyRoles: const ['warrior', 'rogue', 'rogue'],
          questTypeId: 'raid',
        ),
        6.0,
      );
    });
    test('알 수 없는 role은 specialist로 fallback하여 평균 계산', () {
      // warrior(8) + unknown→specialist(2) → (8+2)/2 = 5.0
      expect(
        RoleSynergyMatrix.partyAverageBonus(
          partyRoles: const ['warrior', 'unknown'],
          questTypeId: 'raid',
        ),
        5.0,
      );
    });
    test('클램프 ±10 확인 (실제 매트릭스 값으로는 +8이 최대지만 이론적으로)', () {
      // 모든 매트릭스 값이 ±8 이하이므로 평균이 ±10을 넘는 실제 조합은 없음.
      // 다만 singleBonus 자체는 ±8 범위이므로 평균도 항상 [-10, 10] 범위 안에 있다.
      final result = RoleSynergyMatrix.partyAverageBonus(
        partyRoles: const ['warrior'],
        questTypeId: 'raid',
      );
      expect(result, inInclusiveRange(-10.0, 10.0));
    });
  });

  group('RoleSynergyMatrix.topRolesForQuest', () {
    test('raid 상위 2개는 warrior(8), rogue(5)', () {
      final result = RoleSynergyMatrix.topRolesForQuest('raid', n: 2);
      expect(result.length, 2);
      expect(result[0].key, 'warrior');
      expect(result[0].value, 8.0);
      expect(result[1].key, 'rogue');
      expect(result[1].value, 5.0);
    });
    test('hunt 상위 2개는 ranger(8), warrior(5)', () {
      final result = RoleSynergyMatrix.topRolesForQuest('hunt', n: 2);
      expect(result[0].key, 'ranger');
      expect(result[0].value, 8.0);
      expect(result[1].key, 'warrior');
      expect(result[1].value, 5.0);
    });
    test('escort 상위 2개는 support(8), mage(3)/warrior(3) 중 하나', () {
      // support(8), warrior(3), mage(3), ranger(2), specialist(2), rogue(0)
      // 동률이 있을 때는 매트릭스 선언 순서 보장 (warrior가 mage보다 먼저 선언됨)
      final result = RoleSynergyMatrix.topRolesForQuest('escort', n: 2);
      expect(result[0].key, 'support');
      expect(result[0].value, 8.0);
      expect(result[1].key, 'warrior'); // 동률 시 선언 순서
      expect(result[1].value, 3.0);
    });
    test('explore 상위 2개는 mage(8), rogue(5)', () {
      final result = RoleSynergyMatrix.topRolesForQuest('explore', n: 2);
      expect(result[0].key, 'mage');
      expect(result[0].value, 8.0);
      expect(result[1].key, 'rogue');
      expect(result[1].value, 5.0);
    });
    test('n=3 요청 시 3개 반환', () {
      final result = RoleSynergyMatrix.topRolesForQuest('raid', n: 3);
      expect(result.length, 3);
    });
  });
}
