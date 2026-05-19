// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combat_turn.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CombatTurnAdapter extends TypeAdapter<CombatTurn> {
  @override
  final int typeId = 23;

  @override
  CombatTurn read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CombatTurn(
      roundIndex: fields[0] as int,
      phase: fields[1] as String,
      actions: (fields[2] as List).cast<CombatAction>(),
      exitConditionsTriggered: (fields[3] as List).cast<String>(),
      hpRemainingByCombatant: (fields[4] as Map?)?.cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, CombatTurn obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.roundIndex)
      ..writeByte(1)
      ..write(obj.phase)
      ..writeByte(2)
      ..write(obj.actions)
      ..writeByte(3)
      ..write(obj.exitConditionsTriggered)
      ..writeByte(4)
      ..write(obj.hpRemainingByCombatant);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CombatTurnAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
