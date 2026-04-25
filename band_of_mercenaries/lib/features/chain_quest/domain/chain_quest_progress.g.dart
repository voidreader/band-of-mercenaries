// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chain_quest_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChainQuestProgressAdapter extends TypeAdapter<ChainQuestProgress> {
  @override
  final int typeId = 13;

  @override
  ChainQuestProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChainQuestProgress(
      chainId: fields[0] as String,
      currentStep: fields[1] as int,
      status: fields[2] as ChainQuestStatus,
      startedAt: fields[3] as DateTime,
      completedAt: fields[4] as DateTime?,
      protagonistMercId: fields[5] as String?,
      currentStepAvailableAt: fields[6] as DateTime?,
      stepFailureCount: fields[7] as int,
      lastActivityAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ChainQuestProgress obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.chainId)
      ..writeByte(1)
      ..write(obj.currentStep)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.startedAt)
      ..writeByte(4)
      ..write(obj.completedAt)
      ..writeByte(5)
      ..write(obj.protagonistMercId)
      ..writeByte(6)
      ..write(obj.currentStepAvailableAt)
      ..writeByte(7)
      ..write(obj.stepFailureCount)
      ..writeByte(8)
      ..write(obj.lastActivityAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChainQuestProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChainQuestStatusAdapter extends TypeAdapter<ChainQuestStatus> {
  @override
  final int typeId = 14;

  @override
  ChainQuestStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChainQuestStatus.active;
      case 1:
        return ChainQuestStatus.completed;
      case 2:
        return ChainQuestStatus.dormant;
      default:
        return ChainQuestStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, ChainQuestStatus obj) {
    switch (obj) {
      case ChainQuestStatus.active:
        writer.writeByte(0);
        break;
      case ChainQuestStatus.completed:
        writer.writeByte(1);
        break;
      case ChainQuestStatus.dormant:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChainQuestStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
