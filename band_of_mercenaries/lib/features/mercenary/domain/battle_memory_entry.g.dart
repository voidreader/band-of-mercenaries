// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battle_memory_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BattleMemoryEntryAdapter extends TypeAdapter<BattleMemoryEntry> {
  @override
  final int typeId = 31;

  @override
  BattleMemoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BattleMemoryEntry(
      mercId: fields[0] as String,
      entryType: fields[1] as String,
      sourceEventId: fields[2] as String,
      timestamp: fields[3] as DateTime,
      templateKey: fields[4] as String?,
      templateData: (fields[5] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, BattleMemoryEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.mercId)
      ..writeByte(1)
      ..write(obj.entryType)
      ..writeByte(2)
      ..write(obj.sourceEventId)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.templateKey)
      ..writeByte(5)
      ..write(obj.templateData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BattleMemoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
