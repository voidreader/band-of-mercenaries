// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data.dart';

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
      reputation: fields[10] as int,
      facilities: (fields[11] as Map?)?.cast<String, int>(),
      constructionFacilityId: fields[12] as String?,
      constructionStartTime: fields[13] as DateTime?,
      constructionEndTime: fields[14] as DateTime?,
      investigatingMercId: fields[15] as String?,
      investigationEndTime: fields[16] as DateTime?,
      investigationRegionId: fields[17] as int?,
      bannerItemId: fields[18] as String?,
      artifactItemIds: (fields[19] as List?)?.cast<String>(),
      completedChains: (fields[20] as List?)?.cast<String>(),
      choiceEventId: fields[21] as String?,
      herbalistCooldownEndTime: fields[22] as DateTime?,
      lastSmithyRepairAt: fields[23] as DateTime?,
      flagshipMercId: fields[24] as String?,
      lastDispatchProtagonistMercId: fields[25] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserData obj) {
    writer
      ..writeByte(26)
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
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.reputation)
      ..writeByte(11)
      ..write(obj.facilities)
      ..writeByte(12)
      ..write(obj.constructionFacilityId)
      ..writeByte(13)
      ..write(obj.constructionStartTime)
      ..writeByte(14)
      ..write(obj.constructionEndTime)
      ..writeByte(15)
      ..write(obj.investigatingMercId)
      ..writeByte(16)
      ..write(obj.investigationEndTime)
      ..writeByte(17)
      ..write(obj.investigationRegionId)
      ..writeByte(18)
      ..write(obj.bannerItemId)
      ..writeByte(19)
      ..write(obj.artifactItemIds)
      ..writeByte(20)
      ..write(obj.completedChains)
      ..writeByte(21)
      ..write(obj.choiceEventId)
      ..writeByte(22)
      ..write(obj.herbalistCooldownEndTime)
      ..writeByte(23)
      ..write(obj.lastSmithyRepairAt)
      ..writeByte(24)
      ..write(obj.flagshipMercId)
      ..writeByte(25)
      ..write(obj.lastDispatchProtagonistMercId);
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
