// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combat_status_effect.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CombatStatusEffectImpl _$$CombatStatusEffectImplFromJson(
        Map<String, dynamic> json) =>
    _$CombatStatusEffectImpl(
      id: json['id'] as String,
      kind: json['kind'] as String,
      displayLabel: json['display_label'] as String,
      defaultDurationTurns: (json['default_duration_turns'] as num).toInt(),
      defaultIntensity: (json['default_intensity'] as num).toDouble(),
      stackPolicy: $enumDecode(_$StackPolicyEnumMap, json['stack_policy']),
      hookTarget: (json['hook_target'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      applyMethod: $enumDecode(_$ApplyMethodEnumMap, json['apply_method']),
      description: json['description'] as String,
    );

Map<String, dynamic> _$$CombatStatusEffectImplToJson(
        _$CombatStatusEffectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'display_label': instance.displayLabel,
      'default_duration_turns': instance.defaultDurationTurns,
      'default_intensity': instance.defaultIntensity,
      'stack_policy': _$StackPolicyEnumMap[instance.stackPolicy]!,
      'hook_target': instance.hookTarget,
      'apply_method': _$ApplyMethodEnumMap[instance.applyMethod]!,
      'description': instance.description,
    };

const _$StackPolicyEnumMap = {
  StackPolicy.refresh: 'refresh',
  StackPolicy.stack: 'stack',
  StackPolicy.ignore: 'ignore',
};

const _$ApplyMethodEnumMap = {
  ApplyMethod.multiplicative: 'multiplicative',
  ApplyMethod.additive: 'additive',
  ApplyMethod.proportional: 'proportional',
  ApplyMethod.absolute: 'absolute',
  ApplyMethod.none: 'none',
};
