// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enemy_snapshot.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EnemySnapshotAdapter extends TypeAdapter<EnemySnapshot> {
  @override
  final int typeId = 27;

  @override
  EnemySnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EnemySnapshot(
      archetypeId: fields[0] as String,
      instanceId: fields[1] as String,
      name: fields[2] as String,
      role: fields[3] as String,
      tier: fields[4] as int,
      str: fields[5] as int,
      int_: fields[6] as int,
      vit: fields[7] as int,
      agi: fields[8] as int,
      hp: fields[9] as int,
      attack: fields[10] as int,
      defense: fields[11] as int,
      skillIds: (fields[12] as List).cast<String>(),
      behaviorPattern: fields[13] as BehaviorPattern,
      factionTag: fields[14] as String?,
      positionRow: fields[15] as PositionRow,
      positionIndex: fields[16] as int,
      formationGroupId: fields[17] as String,
      enemyKeywordKey: fields[18] as String?,
      flagBattleFuryUsed: fields[19] as bool,
      flagSummonUsed: fields[20] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EnemySnapshot obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.archetypeId)
      ..writeByte(1)
      ..write(obj.instanceId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.tier)
      ..writeByte(5)
      ..write(obj.str)
      ..writeByte(6)
      ..write(obj.int_)
      ..writeByte(7)
      ..write(obj.vit)
      ..writeByte(8)
      ..write(obj.agi)
      ..writeByte(9)
      ..write(obj.hp)
      ..writeByte(10)
      ..write(obj.attack)
      ..writeByte(11)
      ..write(obj.defense)
      ..writeByte(12)
      ..write(obj.skillIds)
      ..writeByte(13)
      ..write(obj.behaviorPattern)
      ..writeByte(14)
      ..write(obj.factionTag)
      ..writeByte(15)
      ..write(obj.positionRow)
      ..writeByte(16)
      ..write(obj.positionIndex)
      ..writeByte(17)
      ..write(obj.formationGroupId)
      ..writeByte(18)
      ..write(obj.enemyKeywordKey)
      ..writeByte(19)
      ..write(obj.flagBattleFuryUsed)
      ..writeByte(20)
      ..write(obj.flagSummonUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnemySnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
