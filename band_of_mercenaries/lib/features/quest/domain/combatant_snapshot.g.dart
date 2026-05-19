// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combatant_snapshot.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CombatantSnapshotAdapter extends TypeAdapter<CombatantSnapshot> {
  @override
  final int typeId = 26;

  @override
  CombatantSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CombatantSnapshot(
      mercId: fields[0] as String,
      name: fields[1] as String,
      jobId: fields[2] as String,
      tier: fields[3] as int,
      level: fields[4] as int,
      effectiveStr: fields[5] as int,
      effectiveInt: fields[6] as int,
      effectiveVit: fields[7] as int,
      effectiveAgi: fields[8] as int,
      titleIds: (fields[9] as List).cast<String>(),
      traitIds: (fields[10] as List).cast<String>(),
      equippedItemIds: (fields[11] as List).cast<String>(),
      role: fields[12] as String,
      positionRow: fields[13] as PositionRow,
      positionIndex: fields[14] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CombatantSnapshot obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.mercId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.jobId)
      ..writeByte(3)
      ..write(obj.tier)
      ..writeByte(4)
      ..write(obj.level)
      ..writeByte(5)
      ..write(obj.effectiveStr)
      ..writeByte(6)
      ..write(obj.effectiveInt)
      ..writeByte(7)
      ..write(obj.effectiveVit)
      ..writeByte(8)
      ..write(obj.effectiveAgi)
      ..writeByte(9)
      ..write(obj.titleIds)
      ..writeByte(10)
      ..write(obj.traitIds)
      ..writeByte(11)
      ..write(obj.equippedItemIds)
      ..writeByte(12)
      ..write(obj.role)
      ..writeByte(13)
      ..write(obj.positionRow)
      ..writeByte(14)
      ..write(obj.positionIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CombatantSnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
