// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crafting_recipe_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CraftingRecipeDataImpl _$$CraftingRecipeDataImplFromJson(
        Map<String, dynamic> json) =>
    _$CraftingRecipeDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      resultItemId: json['result_item_id'] as String,
      resultQuantity: (json['result_quantity'] as num?)?.toInt() ?? 1,
      inputs: (json['inputs_json'] as List<dynamic>)
          .map((e) => RecipeInput.fromJson(e as Map<String, dynamic>))
          .toList(),
      unlockCondition: json['unlock_condition_json'] == null
          ? null
          : RecipeUnlockCondition.fromJson(
              json['unlock_condition_json'] as Map<String, dynamic>),
      craftLocationId: json['craft_location_id'] as String? ?? 'old_smithy',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$CraftingRecipeDataImplToJson(
        _$CraftingRecipeDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'result_item_id': instance.resultItemId,
      'result_quantity': instance.resultQuantity,
      'inputs_json': instance.inputs,
      'unlock_condition_json': instance.unlockCondition,
      'craft_location_id': instance.craftLocationId,
      'sort_order': instance.sortOrder,
      'created_at': instance.createdAt?.toIso8601String(),
    };

_$RecipeInputImpl _$$RecipeInputImplFromJson(Map<String, dynamic> json) =>
    _$RecipeInputImpl(
      itemId: json['item_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$$RecipeInputImplToJson(_$RecipeInputImpl instance) =>
    <String, dynamic>{
      'item_id': instance.itemId,
      'quantity': instance.quantity,
    };

_$RecipeUnlockConditionImpl _$$RecipeUnlockConditionImplFromJson(
        Map<String, dynamic> json) =>
    _$RecipeUnlockConditionImpl(
      trustLevel: (json['trust_level'] as num?)?.toInt(),
      chainStep: json['chain_step'] == null
          ? null
          : ChainStepCondition.fromJson(
              json['chain_step'] as Map<String, dynamic>),
      firstAcquiredItem: json['first_acquired_item'] as String?,
      type: json['type'] as String?,
      flag: json['flag'] as String?,
      value: (json['value'] as num?)?.toInt(),
      factionId: _readFactionId(json, 'factionId') as String?,
      minReputation:
          (_readMinReputation(json, 'minReputation') as num?)?.toInt(),
      conditions: (json['conditions'] as List<dynamic>?)
          ?.map(
              (e) => RecipeUnlockCondition.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$RecipeUnlockConditionImplToJson(
        _$RecipeUnlockConditionImpl instance) =>
    <String, dynamic>{
      'trust_level': instance.trustLevel,
      'chain_step': instance.chainStep,
      'first_acquired_item': instance.firstAcquiredItem,
      'type': instance.type,
      'flag': instance.flag,
      'value': instance.value,
      'factionId': instance.factionId,
      'minReputation': instance.minReputation,
      'conditions': instance.conditions,
    };

_$ChainStepConditionImpl _$$ChainStepConditionImplFromJson(
        Map<String, dynamic> json) =>
    _$ChainStepConditionImpl(
      chainId: json['chain_id'] as String,
      step: (json['step'] as num).toInt(),
    );

Map<String, dynamic> _$$ChainStepConditionImplToJson(
        _$ChainStepConditionImpl instance) =>
    <String, dynamic>{
      'chain_id': instance.chainId,
      'step': instance.step,
    };
