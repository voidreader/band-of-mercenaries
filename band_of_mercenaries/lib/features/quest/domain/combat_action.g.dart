// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combat_action.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CombatActionAdapter extends TypeAdapter<CombatAction> {
  @override
  final int typeId = 24;

  @override
  CombatAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CombatAction(
      actorId: fields[0] as String,
      targetIds: (fields[1] as List).cast<String>(),
      actionKind: fields[2] as String,
      skillId: fields[3] as String?,
      statusEffectId: fields[4] as String?,
      behaviorPattern: fields[5] as BehaviorPattern?,
      decisiveKeywordKey: fields[6] as String?,
      isComboCompression: fields[7] as bool,
      position: fields[8] as String,
      damage: fields[9] as int,
      isCrit: fields[10] as bool,
      isHit: fields[11] as bool,
      isEvaded: fields[12] as bool,
      isShielded: fields[13] as bool,
      isKill: fields[14] as bool,
      shieldMitigation: fields[15] as double,
      extraMeta: (fields[16] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, CombatAction obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.actorId)
      ..writeByte(1)
      ..write(obj.targetIds)
      ..writeByte(2)
      ..write(obj.actionKind)
      ..writeByte(3)
      ..write(obj.skillId)
      ..writeByte(4)
      ..write(obj.statusEffectId)
      ..writeByte(5)
      ..write(obj.behaviorPattern)
      ..writeByte(6)
      ..write(obj.decisiveKeywordKey)
      ..writeByte(7)
      ..write(obj.isComboCompression)
      ..writeByte(8)
      ..write(obj.position)
      ..writeByte(9)
      ..write(obj.damage)
      ..writeByte(10)
      ..write(obj.isCrit)
      ..writeByte(11)
      ..write(obj.isHit)
      ..writeByte(12)
      ..write(obj.isEvaded)
      ..writeByte(13)
      ..write(obj.isShielded)
      ..writeByte(14)
      ..write(obj.isKill)
      ..writeByte(15)
      ..write(obj.shieldMitigation)
      ..writeByte(16)
      ..write(obj.extraMeta);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CombatActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
