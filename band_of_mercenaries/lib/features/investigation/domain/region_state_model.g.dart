// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'region_state_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RegionStateAdapter extends TypeAdapter<RegionState> {
  @override
  final int typeId = 8;

  @override
  RegionState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RegionState(
      regionId: fields[0] as int,
      knowledge: fields[1] as int,
      triggeredDiscoveries: (fields[2] as List?)?.cast<String>(),
      sectorChanges: (fields[3] as Map?)?.cast<String, String>(),
      settlementTrust: fields[4] as int?,
      settlementTrustLevel: fields[5] as int?,
      lastEventCompletedAt: fields[6] as DateTime?,
      firstAcquiredMaterialIds: (fields[7] as List?)?.cast<String>(),
      dangerScore: fields[8] as int?,
      dangerLevel: fields[9] as int?,
      unlockedFlags: (fields[10] as List?)?.cast<String>(),
      questPoolCompletionCounts: (fields[11] as Map?)?.cast<String, int>(),
      infrastructureTier: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, RegionState obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.regionId)
      ..writeByte(1)
      ..write(obj.knowledge)
      ..writeByte(2)
      ..write(obj.triggeredDiscoveries)
      ..writeByte(3)
      ..write(obj.sectorChanges)
      ..writeByte(4)
      ..write(obj.settlementTrust)
      ..writeByte(5)
      ..write(obj.settlementTrustLevel)
      ..writeByte(6)
      ..write(obj.lastEventCompletedAt)
      ..writeByte(7)
      ..write(obj.firstAcquiredMaterialIds)
      ..writeByte(8)
      ..write(obj.dangerScore)
      ..writeByte(9)
      ..write(obj.dangerLevel)
      ..writeByte(10)
      ..write(obj.unlockedFlags)
      ..writeByte(11)
      ..write(obj.questPoolCompletionCounts)
      ..writeByte(12)
      ..write(obj.infrastructureTier);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegionStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
