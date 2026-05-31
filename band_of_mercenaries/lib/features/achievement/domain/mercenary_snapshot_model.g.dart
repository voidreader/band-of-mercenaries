// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mercenary_snapshot_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MercenarySnapshotAdapter extends TypeAdapter<MercenarySnapshot> {
  @override
  final int typeId = 18;

  @override
  MercenarySnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MercenarySnapshot(
      id: fields[0] as String,
      name: fields[1] as String,
      jobId: fields[2] as String,
      jobName: fields[3] as String,
      tier: fields[4] as int,
      titleIds: (fields[5] as List).cast<String>(),
      hiddenStats: (fields[6] as Map).cast<String, int>(),
      battleMemories: (fields[7] as List).cast<BattleMemoryEntry>(),
    );
  }

  @override
  void write(BinaryWriter writer, MercenarySnapshot obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.jobId)
      ..writeByte(3)
      ..write(obj.jobName)
      ..writeByte(4)
      ..write(obj.tier)
      ..writeByte(5)
      ..write(obj.titleIds)
      ..writeByte(6)
      ..write(obj.hiddenStats)
      ..writeByte(7)
      ..write(obj.battleMemories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MercenarySnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
