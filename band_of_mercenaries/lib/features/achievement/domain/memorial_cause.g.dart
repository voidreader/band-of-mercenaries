// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memorial_cause.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemorialCauseAdapter extends TypeAdapter<MemorialCause> {
  @override
  final int typeId = 19;

  @override
  MemorialCause read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MemorialCause.diedQuest;
      case 1:
        return MemorialCause.diedEvent;
      case 2:
        return MemorialCause.released;
      default:
        return MemorialCause.diedQuest;
    }
  }

  @override
  void write(BinaryWriter writer, MemorialCause obj) {
    switch (obj) {
      case MemorialCause.diedQuest:
        writer.writeByte(0);
        break;
      case MemorialCause.diedEvent:
        writer.writeByte(1);
        break;
      case MemorialCause.released:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemorialCauseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
