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
    );
  }

  @override
  void write(BinaryWriter writer, FactionState obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.factionId)
      ..writeByte(1)
      ..write(obj.clueRecords);
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
