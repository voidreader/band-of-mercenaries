// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityLogAdapter extends TypeAdapter<ActivityLog> {
  @override
  final int typeId = 7;

  @override
  ActivityLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityLog(
      timestamp: fields[0] as DateTime,
      message: fields[1] as String,
      type: fields[2] as ActivityLogType,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityLog obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActivityLogTypeAdapter extends TypeAdapter<ActivityLogType> {
  @override
  final int typeId = 6;

  @override
  ActivityLogType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActivityLogType.questResult;
      case 1:
        return ActivityLogType.mercenaryStatus;
      case 2:
        return ActivityLogType.movementComplete;
      case 3:
        return ActivityLogType.mercenaryRecruit;
      case 4:
        return ActivityLogType.mercenaryDismiss;
      case 5:
        return ActivityLogType.levelUp;
      case 6:
        return ActivityLogType.traitAcquired;
      case 7:
        return ActivityLogType.traitEvolved;
      case 8:
        return ActivityLogType.traitDeleted;
      case 9:
        return ActivityLogType.facilityUpgrade;
      case 10:
        return ActivityLogType.investigationSuccess;
      case 11:
        return ActivityLogType.investigationFailed;
      case 12:
        return ActivityLogType.discoveryFound;
      case 13:
        return ActivityLogType.reputationRankUp;
      case 14:
        return ActivityLogType.reputationRankDown;
      default:
        return ActivityLogType.questResult;
    }
  }

  @override
  void write(BinaryWriter writer, ActivityLogType obj) {
    switch (obj) {
      case ActivityLogType.questResult:
        writer.writeByte(0);
        break;
      case ActivityLogType.mercenaryStatus:
        writer.writeByte(1);
        break;
      case ActivityLogType.movementComplete:
        writer.writeByte(2);
        break;
      case ActivityLogType.mercenaryRecruit:
        writer.writeByte(3);
        break;
      case ActivityLogType.mercenaryDismiss:
        writer.writeByte(4);
        break;
      case ActivityLogType.levelUp:
        writer.writeByte(5);
        break;
      case ActivityLogType.traitAcquired:
        writer.writeByte(6);
        break;
      case ActivityLogType.traitEvolved:
        writer.writeByte(7);
        break;
      case ActivityLogType.traitDeleted:
        writer.writeByte(8);
        break;
      case ActivityLogType.facilityUpgrade:
        writer.writeByte(9);
        break;
      case ActivityLogType.investigationSuccess:
        writer.writeByte(10);
        break;
      case ActivityLogType.investigationFailed:
        writer.writeByte(11);
        break;
      case ActivityLogType.discoveryFound:
        writer.writeByte(12);
        break;
      case ActivityLogType.reputationRankUp:
        writer.writeByte(13);
        break;
      case ActivityLogType.reputationRankDown:
        writer.writeByte(14);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLogTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
