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
      schemaVersion: fields[8] as int?,
      combatantSnapshots: (fields[9] as List?)?.cast<CombatantSnapshot>(),
      turns: (fields[10] as List?)?.cast<CombatTurn>(),
      exitCondition: fields[11] as CombatExitCondition?,
      objectiveProgress: fields[12] as double?,
      enemySnapshots: (fields[13] as List?)?.cast<EnemySnapshot>(),
      statusEffectHistory: (fields[14] as List?)?.cast<StatusEffectEvent>(),
    );
  }

  @override
  void write(BinaryWriter writer, CombatReport obj) {
    writer
      ..writeByte(15)
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
      ..write(obj.templateIds)
      ..writeByte(8)
      ..write(obj.schemaVersion)
      ..writeByte(9)
      ..write(obj.combatantSnapshots)
      ..writeByte(10)
      ..write(obj.turns)
      ..writeByte(11)
      ..write(obj.exitCondition)
      ..writeByte(12)
      ..write(obj.objectiveProgress)
      ..writeByte(13)
      ..write(obj.enemySnapshots)
      ..writeByte(14)
      ..write(obj.statusEffectHistory);
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
