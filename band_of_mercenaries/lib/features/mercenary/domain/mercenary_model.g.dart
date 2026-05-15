// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mercenary_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MercenaryAdapter extends TypeAdapter<Mercenary> {
  @override
  final int typeId = 1;

  @override
  Mercenary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Mercenary(
      id: fields[0] as String,
      name: fields[1] as String,
      jobId: fields[2] as String,
      traitId: fields[3] as String,
      str: fields[4] as int,
      intelligence: fields[5] as int,
      vit: fields[6] as int,
      agi: fields[7] as int,
      status: fields[8] as MercenaryStatus,
      tiredEndTime: fields[9] as DateTime?,
      injuryEndTime: fields[10] as DateTime?,
      isDispatched: fields[11] as bool,
      xp: fields[12] as int,
      level: fields[13] as int,
      stats: (fields[14] as Map?)?.cast<String, int>(),
      traitIds: (fields[15] as List?)?.cast<String>(),
      traitHistory: (fields[16] as List?)?.cast<String>(),
      deletedTraitIds: (fields[17] as List?)?.cast<String>(),
      legendaryDeathPreventionCooldownUntil: fields[18] as DateTime?,
      permanentStr: fields[19] as int,
      permanentIntelligence: fields[20] as int,
      permanentVit: fields[21] as int,
      permanentAgi: fields[22] as int,
      traitLearningBoostUntil: fields[23] as DateTime?,
      titleIds: (fields[24] as List?)?.cast<String>(),
      recruitedAt: fields[25] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Mercenary obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.jobId)
      ..writeByte(3)
      ..write(obj.traitId)
      ..writeByte(4)
      ..write(obj.str)
      ..writeByte(5)
      ..write(obj.intelligence)
      ..writeByte(6)
      ..write(obj.vit)
      ..writeByte(7)
      ..write(obj.agi)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.tiredEndTime)
      ..writeByte(10)
      ..write(obj.injuryEndTime)
      ..writeByte(11)
      ..write(obj.isDispatched)
      ..writeByte(12)
      ..write(obj.xp)
      ..writeByte(13)
      ..write(obj.level)
      ..writeByte(14)
      ..write(obj.stats)
      ..writeByte(15)
      ..write(obj.traitIds)
      ..writeByte(16)
      ..write(obj.traitHistory)
      ..writeByte(17)
      ..write(obj.deletedTraitIds)
      ..writeByte(18)
      ..write(obj.legendaryDeathPreventionCooldownUntil)
      ..writeByte(19)
      ..write(obj.permanentStr)
      ..writeByte(20)
      ..write(obj.permanentIntelligence)
      ..writeByte(21)
      ..write(obj.permanentVit)
      ..writeByte(22)
      ..write(obj.permanentAgi)
      ..writeByte(23)
      ..write(obj.traitLearningBoostUntil)
      ..writeByte(24)
      ..write(obj.titleIds)
      ..writeByte(25)
      ..write(obj.recruitedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MercenaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MercenaryStatusAdapter extends TypeAdapter<MercenaryStatus> {
  @override
  final int typeId = 0;

  @override
  MercenaryStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MercenaryStatus.normal;
      case 1:
        return MercenaryStatus.tired;
      case 2:
        return MercenaryStatus.injured;
      case 3:
        return MercenaryStatus.dead;
      default:
        return MercenaryStatus.normal;
    }
  }

  @override
  void write(BinaryWriter writer, MercenaryStatus obj) {
    switch (obj) {
      case MercenaryStatus.normal:
        writer.writeByte(0);
        break;
      case MercenaryStatus.tired:
        writer.writeByte(1);
        break;
      case MercenaryStatus.injured:
        writer.writeByte(2);
        break;
      case MercenaryStatus.dead:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MercenaryStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
