// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'difficulty.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DifficultyImpl _$$DifficultyImplFromJson(Map<String, dynamic> json) =>
    _$DifficultyImpl(
      level: (json['Level'] as num).toInt(),
      enemyPower: (json['EnemyPower'] as num).toInt(),
      rewardMultiplier: (json['RewardMultiplier'] as num).toDouble(),
      successPenalty: (json['SuccessPenalty'] as num).toDouble(),
      injuryRate: (json['InjuryRate'] as num).toDouble(),
      deathRate: (json['DeathRate'] as num).toDouble(),
      minDispatchCost: (json['MinDispatchCost'] as num).toInt(),
      maxDispatchCost: (json['MaxDispatchCost'] as num).toInt(),
    );

Map<String, dynamic> _$$DifficultyImplToJson(_$DifficultyImpl instance) =>
    <String, dynamic>{
      'Level': instance.level,
      'EnemyPower': instance.enemyPower,
      'RewardMultiplier': instance.rewardMultiplier,
      'SuccessPenalty': instance.successPenalty,
      'InjuryRate': instance.injuryRate,
      'DeathRate': instance.deathRate,
      'MinDispatchCost': instance.minDispatchCost,
      'MaxDispatchCost': instance.maxDispatchCost,
    };

_$DifficultyListImpl _$$DifficultyListImplFromJson(Map<String, dynamic> json) =>
    _$DifficultyListImpl(
      items: (json['Difficultys'] as List<dynamic>)
          .map((e) => Difficulty.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$DifficultyListImplToJson(
        _$DifficultyListImpl instance) =>
    <String, dynamic>{
      'Difficultys': instance.items,
    };
