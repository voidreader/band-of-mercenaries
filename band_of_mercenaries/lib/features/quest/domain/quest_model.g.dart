// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActiveQuestAdapter extends TypeAdapter<ActiveQuest> {
  @override
  final int typeId = 4;

  @override
  ActiveQuest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActiveQuest(
      id: fields[0] as String,
      questPoolId: fields[1] as String,
      questTypeId: fields[2] as String,
      difficulty: fields[3] as int,
      region: fields[4] as int,
      questName: fields[10] as String,
      dispatchedMercIds: (fields[5] as List).cast<String>(),
      startTime: fields[6] as DateTime?,
      endTime: fields[7] as DateTime?,
      status: fields[8] as QuestStatus,
      result: fields[9] as QuestResult?,
    );
  }

  @override
  void write(BinaryWriter writer, ActiveQuest obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.questPoolId)
      ..writeByte(2)
      ..write(obj.questTypeId)
      ..writeByte(3)
      ..write(obj.difficulty)
      ..writeByte(4)
      ..write(obj.region)
      ..writeByte(5)
      ..write(obj.dispatchedMercIds)
      ..writeByte(6)
      ..write(obj.startTime)
      ..writeByte(7)
      ..write(obj.endTime)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.result)
      ..writeByte(10)
      ..write(obj.questName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveQuestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuestStatusAdapter extends TypeAdapter<QuestStatus> {
  @override
  final int typeId = 2;

  @override
  QuestStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return QuestStatus.pending;
      case 1:
        return QuestStatus.inProgress;
      case 2:
        return QuestStatus.completed;
      default:
        return QuestStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, QuestStatus obj) {
    switch (obj) {
      case QuestStatus.pending:
        writer.writeByte(0);
        break;
      case QuestStatus.inProgress:
        writer.writeByte(1);
        break;
      case QuestStatus.completed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuestResultAdapter extends TypeAdapter<QuestResult> {
  @override
  final int typeId = 3;

  @override
  QuestResult read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return QuestResult.greatSuccess;
      case 1:
        return QuestResult.success;
      case 2:
        return QuestResult.failure;
      case 3:
        return QuestResult.criticalFailure;
      default:
        return QuestResult.greatSuccess;
    }
  }

  @override
  void write(BinaryWriter writer, QuestResult obj) {
    switch (obj) {
      case QuestResult.greatSuccess:
        writer.writeByte(0);
        break;
      case QuestResult.success:
        writer.writeByte(1);
        break;
      case QuestResult.failure:
        writer.writeByte(2);
        break;
      case QuestResult.criticalFailure:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
