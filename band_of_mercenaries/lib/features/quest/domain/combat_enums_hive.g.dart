// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combat_enums_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CombatExitConditionAdapter extends TypeAdapter<CombatExitCondition> {
  @override
  final int typeId = 28;

  @override
  CombatExitCondition read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CombatExitCondition.aPartyWiped;
      case 1:
        return CombatExitCondition.bEnemyWiped;
      case 2:
        return CombatExitCondition.cObjectiveAchieved;
      case 3:
        return CombatExitCondition.dRoundLimit;
      case 4:
        return CombatExitCondition.eFlee;
      case 5:
        return CombatExitCondition.fEscortDead;
      default:
        return CombatExitCondition.aPartyWiped;
    }
  }

  @override
  void write(BinaryWriter writer, CombatExitCondition obj) {
    switch (obj) {
      case CombatExitCondition.aPartyWiped:
        writer.writeByte(0);
        break;
      case CombatExitCondition.bEnemyWiped:
        writer.writeByte(1);
        break;
      case CombatExitCondition.cObjectiveAchieved:
        writer.writeByte(2);
        break;
      case CombatExitCondition.dRoundLimit:
        writer.writeByte(3);
        break;
      case CombatExitCondition.eFlee:
        writer.writeByte(4);
        break;
      case CombatExitCondition.fEscortDead:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CombatExitConditionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BehaviorPatternAdapter extends TypeAdapter<BehaviorPattern> {
  @override
  final int typeId = 29;

  @override
  BehaviorPattern read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BehaviorPattern.aggressive;
      case 1:
        return BehaviorPattern.opportunist;
      case 2:
        return BehaviorPattern.caster;
      case 3:
        return BehaviorPattern.supporter;
      case 4:
        return BehaviorPattern.defender;
      case 5:
        return BehaviorPattern.berserker;
      default:
        return BehaviorPattern.aggressive;
    }
  }

  @override
  void write(BinaryWriter writer, BehaviorPattern obj) {
    switch (obj) {
      case BehaviorPattern.aggressive:
        writer.writeByte(0);
        break;
      case BehaviorPattern.opportunist:
        writer.writeByte(1);
        break;
      case BehaviorPattern.caster:
        writer.writeByte(2);
        break;
      case BehaviorPattern.supporter:
        writer.writeByte(3);
        break;
      case BehaviorPattern.defender:
        writer.writeByte(4);
        break;
      case BehaviorPattern.berserker:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BehaviorPatternAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PositionRowAdapter extends TypeAdapter<PositionRow> {
  @override
  final int typeId = 30;

  @override
  PositionRow read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PositionRow.front;
      case 1:
        return PositionRow.middle;
      case 2:
        return PositionRow.back;
      default:
        return PositionRow.front;
    }
  }

  @override
  void write(BinaryWriter writer, PositionRow obj) {
    switch (obj) {
      case PositionRow.front:
        writer.writeByte(0);
        break;
      case PositionRow.middle:
        writer.writeByte(1);
        break;
      case PositionRow.back:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PositionRowAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
