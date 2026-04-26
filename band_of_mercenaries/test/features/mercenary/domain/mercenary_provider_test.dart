import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/evolution_choice.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/trait_evolution_service.dart';

void main() {
  group('EvolutionChoice (Task 2 회귀 테스트)', () {
    test('isSingle=true 시 single.fromKey/toKey 그대로 사용', () {
      const candidate = SingleEvolutionCandidate('old', 'new');
      final choice = EvolutionChoice.fromSingle(candidate);
      expect(choice.isSingle, isTrue);
      expect(choice.single?.fromKey, equals('old'));
      expect(choice.single?.toKey, equals('new'));
      expect(choice.combo, isNull);
    });

    test('isSingle=false 시 combo.trait1Key/trait2Key/resultKey 그대로 사용', () {
      const candidate = ComboEvolutionCandidate('a', 'b', 'c');
      final choice = EvolutionChoice.fromCombo(candidate);
      expect(choice.isSingle, isFalse);
      expect(choice.combo?.trait1Key, equals('a'));
      expect(choice.combo?.trait2Key, equals('b'));
      expect(choice.combo?.resultKey, equals('c'));
      expect(choice.single, isNull);
    });
  });
}
