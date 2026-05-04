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
    );
  }

  @override
  void write(BinaryWriter writer, RegionState obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.lastEventCompletedAt);
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
