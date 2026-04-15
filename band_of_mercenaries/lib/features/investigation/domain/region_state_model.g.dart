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
    );
  }

  @override
  void write(BinaryWriter writer, RegionState obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.regionId)
      ..writeByte(1)
      ..write(obj.knowledge)
      ..writeByte(2)
      ..write(obj.triggeredDiscoveries);
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
