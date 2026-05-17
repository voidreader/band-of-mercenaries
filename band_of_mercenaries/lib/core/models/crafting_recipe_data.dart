import 'package:freezed_annotation/freezed_annotation.dart';

part 'crafting_recipe_data.freezed.dart';
part 'crafting_recipe_data.g.dart';

/// 제작 레시피 정적 데이터 모델 (Supabase crafting_recipes 테이블과 1:1 대응).
@freezed
class CraftingRecipeData with _$CraftingRecipeData {
  const factory CraftingRecipeData({
    required String id,
    required String name,
    @Default('') String description,
    @JsonKey(name: 'result_item_id') required String resultItemId,
    @JsonKey(name: 'result_quantity') @Default(1) int resultQuantity,
    @JsonKey(name: 'inputs_json') required List<RecipeInput> inputs,
    @JsonKey(name: 'unlock_condition_json') RecipeUnlockCondition? unlockCondition,
    @JsonKey(name: 'craft_location_id') @Default('old_smithy') String craftLocationId,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _CraftingRecipeData;

  factory CraftingRecipeData.fromJson(Map<String, dynamic> json) =>
      _$CraftingRecipeDataFromJson(json);
}

/// 레시피 입력 재료 1종 (inputs_json 배열 원소).
@freezed
class RecipeInput with _$RecipeInput {
  const factory RecipeInput({
    @JsonKey(name: 'item_id') required String itemId,
    required int quantity,
  }) = _RecipeInput;

  factory RecipeInput.fromJson(Map<String, dynamic> json) =>
      _$RecipeInputFromJson(json);
}

/// 레시피 해금 조건 (unlock_condition_json — 3종 기존 + 4종 M7 신규 필드로 단순 매핑).
@freezed
class RecipeUnlockCondition with _$RecipeUnlockCondition {
  const factory RecipeUnlockCondition({
    @JsonKey(name: 'trust_level') int? trustLevel,
    @JsonKey(name: 'chain_step') ChainStepCondition? chainStep,
    @JsonKey(name: 'first_acquired_item') String? firstAcquiredItem,
    // M7 페이즈 4 #4 신규 type 분기 필드
    String? type,   // 'regionFlag' / 'infrastructureTier' / 'all' / 'any'
    String? flag,
    int? value,
    List<RecipeUnlockCondition>? conditions,
  }) = _RecipeUnlockCondition;

  factory RecipeUnlockCondition.fromJson(Map<String, dynamic> json) =>
      _$RecipeUnlockConditionFromJson(json);
}

/// 체인 단계 완료 조건 (chain_step 객체).
@freezed
class ChainStepCondition with _$ChainStepCondition {
  const factory ChainStepCondition({
    @JsonKey(name: 'chain_id') required String chainId,
    required int step,
  }) = _ChainStepCondition;

  factory ChainStepCondition.fromJson(Map<String, dynamic> json) =>
      _$ChainStepConditionFromJson(json);
}
