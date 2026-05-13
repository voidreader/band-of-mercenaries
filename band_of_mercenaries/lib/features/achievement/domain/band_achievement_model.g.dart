// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'band_achievement_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BandAchievementAdapter extends TypeAdapter<BandAchievement> {
  @override
  final int typeId = 16;

  @override
  BandAchievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BandAchievement(
      id: fields[0] as String,
      type: fields[1] as BandAchievementType,
      achievedAt: fields[2] as DateTime,
      templateId: fields[3] as String,
      mercSnapshot: fields[4] as MercenarySnapshot?,
      regionId: fields[5] as int?,
      payload: (fields[6] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, BandAchievement obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.achievedAt)
      ..writeByte(3)
      ..write(obj.templateId)
      ..writeByte(4)
      ..write(obj.mercSnapshot)
      ..writeByte(5)
      ..write(obj.regionId)
      ..writeByte(6)
      ..write(obj.payload);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BandAchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BandAchievementTypeAdapter extends TypeAdapter<BandAchievementType> {
  @override
  final int typeId = 17;

  @override
  BandAchievementType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BandAchievementType.achievement;
      case 1:
        return BandAchievementType.memorial;
      default:
        return BandAchievementType.achievement;
    }
  }

  @override
  void write(BinaryWriter writer, BandAchievementType obj) {
    switch (obj) {
      case BandAchievementType.achievement:
        writer.writeByte(0);
        break;
      case BandAchievementType.memorial:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BandAchievementTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
