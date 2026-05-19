// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combat_simulation_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CombatSimulationResultAdapter
    extends TypeAdapter<CombatSimulationResult> {
  @override
  final int typeId = 22;

  @override
  CombatSimulationResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CombatSimulationResult(
      questResult: fields[0] as QuestResult,
      turns: (fields[1] as List).cast<CombatTurn>(),
      protagonistMercId: fields[2] as String?,
      featuredMercIds: (fields[3] as List).cast<String>(),
      injuredMercIds: (fields[4] as List).cast<String>(),
      deceasedMercIds: (fields[5] as List).cast<String>(),
      objectiveProgress: fields[6] as double,
      exitCondition: fields[7] as CombatExitCondition,
      statusEffectHistory: (fields[8] as List).cast<StatusEffectEvent>(),
      seed: fields[9] as int,
      toneTags: (fields[10] as List).cast<String>(),
      combatantSnapshots: (fields[11] as List).cast<CombatantSnapshot>(),
      enemySnapshots: (fields[12] as List).cast<EnemySnapshot>(),
    );
  }

  @override
  void write(BinaryWriter writer, CombatSimulationResult obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.questResult)
      ..writeByte(1)
      ..write(obj.turns)
      ..writeByte(2)
      ..write(obj.protagonistMercId)
      ..writeByte(3)
      ..write(obj.featuredMercIds)
      ..writeByte(4)
      ..write(obj.injuredMercIds)
      ..writeByte(5)
      ..write(obj.deceasedMercIds)
      ..writeByte(6)
      ..write(obj.objectiveProgress)
      ..writeByte(7)
      ..write(obj.exitCondition)
      ..writeByte(8)
      ..write(obj.statusEffectHistory)
      ..writeByte(9)
      ..write(obj.seed)
      ..writeByte(10)
      ..write(obj.toneTags)
      ..writeByte(11)
      ..write(obj.combatantSnapshots)
      ..writeByte(12)
      ..write(obj.enemySnapshots);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CombatSimulationResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
