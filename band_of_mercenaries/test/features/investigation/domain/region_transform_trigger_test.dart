import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';

void main() {
  group('RegionState.sectorChanges', () {
    test('기본값이 빈 맵이다', () {
      final state = RegionState(regionId: 1);
      expect(state.sectorChanges, isEmpty);
    });

    test('섹터 변형 키는 string 형식이다', () {
      final state = RegionState(regionId: 1);
      state.sectorChanges['3'] = 'village';
      expect(state.sectorChanges['3'], equals('village'));
      expect(state.sectorChanges[3.toString()], equals('village'));
    });

    test('1섹터 제약: sectorChanges가 이미 있으면 추가 변형 불가 조건을 만족한다', () {
      // RegionStateRepository.applyTransform의 리전당 1섹터 제약 로직:
      // sectorChanges.isNotEmpty이면 false를 반환한다.
      final state = RegionState(regionId: 1);
      state.sectorChanges['3'] = 'village';

      // 이미 변형된 리전은 추가 변형 불가 (sectorChanges.isNotEmpty)
      expect(state.sectorChanges.isNotEmpty, isTrue);
    });

    test('중복 섹터 변형 차단: 동일 key에 이미 값이 있으면 containsKey가 true이다', () {
      // RegionStateRepository.applyTransform이 동일 key에 값 있으면 false 반환하는
      // 조건을 모델 레벨에서 검증한다.
      final state = RegionState(regionId: 1);
      state.sectorChanges['3'] = 'village';

      expect(state.sectorChanges.containsKey('3'), isTrue);
    });

    test('village 타입이 정상 저장된다', () {
      final state = RegionState(regionId: 5);
      state.sectorChanges['0'] = 'village';
      expect(state.sectorChanges['0'], equals('village'));
    });

    test('ruins 타입이 정상 저장된다', () {
      final state = RegionState(regionId: 5);
      state.sectorChanges['7'] = 'ruins';
      expect(state.sectorChanges['7'], equals('ruins'));
    });

    test('hidden 타입이 정상 저장된다', () {
      final state = RegionState(regionId: 5);
      state.sectorChanges['9'] = 'hidden';
      expect(state.sectorChanges['9'], equals('hidden'));
    });

    test('섹터 인덱스 0~9 범위 키를 모두 사용할 수 있다', () {
      for (int i = 0; i <= 9; i++) {
        // 1섹터 제약을 우회하기 위해 매번 새 state를 생성하고 단일 키만 테스트
        final s = RegionState(regionId: i);
        s.sectorChanges[i.toString()] = 'village';
        expect(s.sectorChanges.containsKey(i.toString()), isTrue);
      }
    });

    test('빈 sectorChanges로 생성하면 isNotEmpty가 false이다', () {
      final state = RegionState(regionId: 10, sectorChanges: {});
      expect(state.sectorChanges.isNotEmpty, isFalse);
    });

    test('초기값으로 sectorChanges를 지정하면 그대로 보존된다', () {
      final initial = {'2': 'ruins', '5': 'village'};
      final state = RegionState(regionId: 3, sectorChanges: Map.from(initial));
      expect(state.sectorChanges['2'], equals('ruins'));
      expect(state.sectorChanges['5'], equals('village'));
    });

    test('위험도 decay 마지막 체크 시각은 모델에 보존된다', () {
      final checkedAt = DateTime(2026, 5, 18, 12);
      final state = RegionState(
        regionId: 3,
        lastDangerDecayCheckedAt: checkedAt,
      );

      expect(state.lastDangerDecayCheckedAt, checkedAt);
    });
  });
}
