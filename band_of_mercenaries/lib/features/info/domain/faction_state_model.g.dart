// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faction_state_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FactionClueRecordAdapter extends TypeAdapter<FactionClueRecord> {
  @override
  final int typeId = 10;

  @override
  FactionClueRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FactionClueRecord(
      factionId: fields[0] as String,
      regionId: fields[1] as int,
      discoveryId: fields[2] as String,
      foundAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FactionClueRecord obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.factionId)
      ..writeByte(1)
      ..write(obj.regionId)
      ..writeByte(2)
      ..write(obj.discoveryId)
      ..writeByte(3)
      ..write(obj.foundAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FactionClueRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FactionStateAdapter extends TypeAdapter<FactionState> {
  @override
  final int typeId = 9;

  @override
  FactionState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FactionState(
      factionId: fields[0] as String,
      clueRecords: (fields[1] as List?)?.cast<FactionClueRecord>(),
      reputation: fields[2] as int?,
      joined: fields[3] as bool?,
      joinedAt: fields[4] as DateTime?,
      facilityLevels: (fields[5] as Map?)?.cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, FactionState obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.factionId)
      ..writeByte(1)
      ..write(obj.clueRecords)
      ..writeByte(2)
      ..write(obj.reputation)
      ..writeByte(3)
      ..write(obj.joined)
      ..writeByte(4)
      ..write(obj.joinedAt)
      ..writeByte(5)
      ..write(obj.facilityLevels);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FactionStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
