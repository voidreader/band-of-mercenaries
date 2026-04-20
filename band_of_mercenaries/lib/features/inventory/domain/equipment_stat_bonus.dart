import 'package:freezed_annotation/freezed_annotation.dart';

part 'equipment_stat_bonus.freezed.dart';

/// 개인 장비에서 파생되는 용병 스탯 보정값.
/// 모든 필드 기본값 0. 여러 장비의 보정을 합산할 때 `+` 연산자를 사용한다.
@freezed
class EquipmentStatBonus with _$EquipmentStatBonus {
  const factory EquipmentStatBonus({
    @Default(0) int str,
    @Default(0) int intelligence,
    @Default(0) int vit,
    @Default(0) int agi,
  }) = _EquipmentStatBonus;

  /// 모든 보정값이 0인 기본 인스턴스.
  static const EquipmentStatBonus zero = EquipmentStatBonus();
}

/// [EquipmentStatBonus] 합산 연산자.
extension EquipmentStatBonusOps on EquipmentStatBonus {
  /// 동일 타입끼리 필드별 합산한 새 인스턴스를 반환한다.
  EquipmentStatBonus operator +(EquipmentStatBonus other) {
    return EquipmentStatBonus(
      str: str + other.str,
      intelligence: intelligence + other.intelligence,
      vit: vit + other.vit,
      agi: agi + other.agi,
    );
  }
}
