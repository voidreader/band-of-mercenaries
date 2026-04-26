// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'persisted_dialog_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PersistedDialogEntryAdapter extends TypeAdapter<PersistedDialogEntry> {
  @override
  final int typeId = 15;

  @override
  PersistedDialogEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PersistedDialogEntry(
      id: fields[0] as String,
      priority: fields[1] as int,
      dialogType: fields[2] as String,
      payloadJson: fields[3] as String,
      enqueuedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PersistedDialogEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.priority)
      ..writeByte(2)
      ..write(obj.dialogType)
      ..writeByte(3)
      ..write(obj.payloadJson)
      ..writeByte(4)
      ..write(obj.enqueuedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersistedDialogEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
