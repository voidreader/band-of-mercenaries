// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_effect_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StatusEffectEventAdapter extends TypeAdapter<StatusEffectEvent> {
  @override
  final int typeId = 25;

  @override
  StatusEffectEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StatusEffectEvent(
      eventType: fields[0] as String,
      roundIndex: fields[1] as int,
      targetId: fields[2] as String,
      effectId: fields[3] as String,
      labelKey: fields[4] as String,
      endCause: fields[5] as String?,
      casterId: fields[6] as String?,
      intensity: fields[7] as double?,
      durationTurns: fields[8] as int?,
      stackResult: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, StatusEffectEvent obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.eventType)
      ..writeByte(1)
      ..write(obj.roundIndex)
      ..writeByte(2)
      ..write(obj.targetId)
      ..writeByte(3)
      ..write(obj.effectId)
      ..writeByte(4)
      ..write(obj.labelKey)
      ..writeByte(5)
      ..write(obj.endCause)
      ..writeByte(6)
      ..write(obj.casterId)
      ..writeByte(7)
      ..write(obj.intensity)
      ..writeByte(8)
      ..write(obj.durationTurns)
      ..writeByte(9)
      ..write(obj.stackResult);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatusEffectEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
