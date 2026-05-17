// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'region_state_effect.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CumulativeEffectImpl _$$CumulativeEffectImplFromJson(
        Map<String, dynamic> json) =>
    _$CumulativeEffectImpl(
      deltaPerCompletion: (json['delta_per_completion'] as num).toInt(),
      capPerThreshold: (json['cap_per_threshold'] as num).toInt(),
      thresholdFlag: json['threshold_flag'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$CumulativeEffectImplToJson(
        _$CumulativeEffectImpl instance) =>
    <String, dynamic>{
      'delta_per_completion': instance.deltaPerCompletion,
      'cap_per_threshold': instance.capPerThreshold,
      'threshold_flag': instance.thresholdFlag,
      'runtimeType': instance.$type,
    };

_$OneshotEffectImpl _$$OneshotEffectImplFromJson(Map<String, dynamic> json) =>
    _$OneshotEffectImpl(
      delta: (json['delta'] as num).toInt(),
      flag: json['flag'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$OneshotEffectImplToJson(_$OneshotEffectImpl instance) =>
    <String, dynamic>{
      'delta': instance.delta,
      'flag': instance.flag,
      'runtimeType': instance.$type,
    };
