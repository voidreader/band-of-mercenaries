// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movement_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserDataAdapter extends TypeAdapter<UserData> {
  @override
  final int typeId = 5;

  @override
  UserData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserData(
      gold: fields[0] as int,
      continent: fields[1] as int,
      region: fields[2] as int,
      sector: fields[3] as int,
      isMoving: fields[4] as bool,
      moveTargetRegion: fields[5] as int?,
      moveTargetSector: fields[6] as int?,
      moveEndTime: fields[7] as DateTime?,
      lastFreeRecruit: fields[8] as DateTime,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserData obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.gold)
      ..writeByte(1)
      ..write(obj.continent)
      ..writeByte(2)
      ..write(obj.region)
      ..writeByte(3)
      ..write(obj.sector)
      ..writeByte(4)
      ..write(obj.isMoving)
      ..writeByte(5)
      ..write(obj.moveTargetRegion)
      ..writeByte(6)
      ..write(obj.moveTargetSector)
      ..writeByte(7)
      ..write(obj.moveEndTime)
      ..writeByte(8)
      ..write(obj.lastFreeRecruit)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
