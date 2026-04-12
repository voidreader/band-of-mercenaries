// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'difficulty.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DifficultyImpl _$$DifficultyImplFromJson(Map<String, dynamic> json) =>
    _$DifficultyImpl(
      level: (json['level'] as num).toInt(),
      enemyPower: (json['enemy_power'] as num).toInt(),
      rewardMultiplier: (json['reward_multiplier'] as num).toDouble(),
      successPenalty: (json['success_penalty'] as num).toDouble(),
      injuryRate: (json['injury_rate'] as num).toDouble(),
      deathRate: (json['death_rate'] as num).toDouble(),
      minDispatchCost: (json['min_dispatch_cost'] as num).toInt(),
      maxDispatchCost: (json['max_dispatch_cost'] as num).toInt(),
    );

Map<String, dynamic> _$$DifficultyImplToJson(_$DifficultyImpl instance) =>
    <String, dynamic>{
      'level': instance.level,
      'enemy_power': instance.enemyPower,
      'reward_multiplier': instance.rewardMultiplier,
      'success_penalty': instance.successPenalty,
      'injury_rate': instance.injuryRate,
      'death_rate': instance.deathRate,
      'min_dispatch_cost': instance.minDispatchCost,
      'max_dispatch_cost': instance.maxDispatchCost,
    };
