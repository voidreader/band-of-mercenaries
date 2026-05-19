// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combat_report_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CombatReportAdapter extends TypeAdapter<CombatReport> {
  @override
  final int typeId = 21;

  @override
  CombatReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CombatReport(
      summary: fields[0] as String,
      details: (fields[1] as List).cast<String>(),
      seed: fields[2] as int,
      protagonistMercId: fields[3] as String?,
      featuredMercIds: (fields[4] as List).cast<String>(),
      toneTags: (fields[5] as List).cast<String>(),
      createdAt: fields[6] as DateTime,
      templateIds: (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CombatReport obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.summary)
      ..writeByte(1)
      ..write(obj.details)
      ..writeByte(2)
      ..write(obj.seed)
      ..writeByte(3)
      ..write(obj.protagonistMercId)
      ..writeByte(4)
      ..write(obj.featuredMercIds)
      ..writeByte(5)
      ..write(obj.toneTags)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.templateIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CombatReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
