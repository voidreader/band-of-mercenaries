import 'package:freezed_annotation/freezed_annotation.dart';

import 'equipment_stat_bonus.dart';
import 'legendary_effect.dart';

part 'personal_equipment_effect.freezed.dart';

/// 개인 장비 1개를 파싱한 결과: 스탯 보정 + 전설 유니크 효과.
@freezed
class PersonalEquipmentEffect with _$PersonalEquipmentEffect {
  const factory PersonalEquipmentEffect({
    required EquipmentStatBonus statBonus,
    LegendaryEffect? legendary,
  }) = _PersonalEquipmentEffect;

  /// 효과가 없는 빈 인스턴스.
  static PersonalEquipmentEffect get zero => const PersonalEquipmentEffect(
        statBonus: EquipmentStatBonus(),
        legendary: null,
      );
}
