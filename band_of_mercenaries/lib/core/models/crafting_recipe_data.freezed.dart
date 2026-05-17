// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'crafting_recipe_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CraftingRecipeData _$CraftingRecipeDataFromJson(Map<String, dynamic> json) {
  return _CraftingRecipeData.fromJson(json);
}

/// @nodoc
mixin _$CraftingRecipeData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'result_item_id')
  String get resultItemId => throw _privateConstructorUsedError;
  @JsonKey(name: 'result_quantity')
  int get resultQuantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'inputs_json')
  List<RecipeInput> get inputs => throw _privateConstructorUsedError;
  @JsonKey(name: 'unlock_condition_json')
  RecipeUnlockCondition? get unlockCondition =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'craft_location_id')
  String get craftLocationId => throw _privateConstructorUsedError;
  @JsonKey(name: 'sort_order')
  int get sortOrder => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CraftingRecipeDataCopyWith<CraftingRecipeData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CraftingRecipeDataCopyWith<$Res> {
  factory $CraftingRecipeDataCopyWith(
          CraftingRecipeData value, $Res Function(CraftingRecipeData) then) =
      _$CraftingRecipeDataCopyWithImpl<$Res, CraftingRecipeData>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      @JsonKey(name: 'result_item_id') String resultItemId,
      @JsonKey(name: 'result_quantity') int resultQuantity,
      @JsonKey(name: 'inputs_json') List<RecipeInput> inputs,
      @JsonKey(name: 'unlock_condition_json')
      RecipeUnlockCondition? unlockCondition,
      @JsonKey(name: 'craft_location_id') String craftLocationId,
      @JsonKey(name: 'sort_order') int sortOrder,
      @JsonKey(name: 'created_at') DateTime? createdAt});

  $RecipeUnlockConditionCopyWith<$Res>? get unlockCondition;
}

/// @nodoc
class _$CraftingRecipeDataCopyWithImpl<$Res, $Val extends CraftingRecipeData>
    implements $CraftingRecipeDataCopyWith<$Res> {
  _$CraftingRecipeDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? resultItemId = null,
    Object? resultQuantity = null,
    Object? inputs = null,
    Object? unlockCondition = freezed,
    Object? craftLocationId = null,
    Object? sortOrder = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      resultItemId: null == resultItemId
          ? _value.resultItemId
          : resultItemId // ignore: cast_nullable_to_non_nullable
              as String,
      resultQuantity: null == resultQuantity
          ? _value.resultQuantity
          : resultQuantity // ignore: cast_nullable_to_non_nullable
              as int,
      inputs: null == inputs
          ? _value.inputs
          : inputs // ignore: cast_nullable_to_non_nullable
              as List<RecipeInput>,
      unlockCondition: freezed == unlockCondition
          ? _value.unlockCondition
          : unlockCondition // ignore: cast_nullable_to_non_nullable
              as RecipeUnlockCondition?,
      craftLocationId: null == craftLocationId
          ? _value.craftLocationId
          : craftLocationId // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $RecipeUnlockConditionCopyWith<$Res>? get unlockCondition {
    if (_value.unlockCondition == null) {
      return null;
    }

    return $RecipeUnlockConditionCopyWith<$Res>(_value.unlockCondition!,
        (value) {
      return _then(_value.copyWith(unlockCondition: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CraftingRecipeDataImplCopyWith<$Res>
    implements $CraftingRecipeDataCopyWith<$Res> {
  factory _$$CraftingRecipeDataImplCopyWith(_$CraftingRecipeDataImpl value,
          $Res Function(_$CraftingRecipeDataImpl) then) =
      __$$CraftingRecipeDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      @JsonKey(name: 'result_item_id') String resultItemId,
      @JsonKey(name: 'result_quantity') int resultQuantity,
      @JsonKey(name: 'inputs_json') List<RecipeInput> inputs,
      @JsonKey(name: 'unlock_condition_json')
      RecipeUnlockCondition? unlockCondition,
      @JsonKey(name: 'craft_location_id') String craftLocationId,
      @JsonKey(name: 'sort_order') int sortOrder,
      @JsonKey(name: 'created_at') DateTime? createdAt});

  @override
  $RecipeUnlockConditionCopyWith<$Res>? get unlockCondition;
}

/// @nodoc
class __$$CraftingRecipeDataImplCopyWithImpl<$Res>
    extends _$CraftingRecipeDataCopyWithImpl<$Res, _$CraftingRecipeDataImpl>
    implements _$$CraftingRecipeDataImplCopyWith<$Res> {
  __$$CraftingRecipeDataImplCopyWithImpl(_$CraftingRecipeDataImpl _value,
      $Res Function(_$CraftingRecipeDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? resultItemId = null,
    Object? resultQuantity = null,
    Object? inputs = null,
    Object? unlockCondition = freezed,
    Object? craftLocationId = null,
    Object? sortOrder = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$CraftingRecipeDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      resultItemId: null == resultItemId
          ? _value.resultItemId
          : resultItemId // ignore: cast_nullable_to_non_nullable
              as String,
      resultQuantity: null == resultQuantity
          ? _value.resultQuantity
          : resultQuantity // ignore: cast_nullable_to_non_nullable
              as int,
      inputs: null == inputs
          ? _value._inputs
          : inputs // ignore: cast_nullable_to_non_nullable
              as List<RecipeInput>,
      unlockCondition: freezed == unlockCondition
          ? _value.unlockCondition
          : unlockCondition // ignore: cast_nullable_to_non_nullable
              as RecipeUnlockCondition?,
      craftLocationId: null == craftLocationId
          ? _value.craftLocationId
          : craftLocationId // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CraftingRecipeDataImpl implements _CraftingRecipeData {
  const _$CraftingRecipeDataImpl(
      {required this.id,
      required this.name,
      this.description = '',
      @JsonKey(name: 'result_item_id') required this.resultItemId,
      @JsonKey(name: 'result_quantity') this.resultQuantity = 1,
      @JsonKey(name: 'inputs_json') required final List<RecipeInput> inputs,
      @JsonKey(name: 'unlock_condition_json') this.unlockCondition,
      @JsonKey(name: 'craft_location_id') this.craftLocationId = 'old_smithy',
      @JsonKey(name: 'sort_order') this.sortOrder = 0,
      @JsonKey(name: 'created_at') this.createdAt})
      : _inputs = inputs;

  factory _$CraftingRecipeDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$CraftingRecipeDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey(name: 'result_item_id')
  final String resultItemId;
  @override
  @JsonKey(name: 'result_quantity')
  final int resultQuantity;
  final List<RecipeInput> _inputs;
  @override
  @JsonKey(name: 'inputs_json')
  List<RecipeInput> get inputs {
    if (_inputs is EqualUnmodifiableListView) return _inputs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_inputs);
  }

  @override
  @JsonKey(name: 'unlock_condition_json')
  final RecipeUnlockCondition? unlockCondition;
  @override
  @JsonKey(name: 'craft_location_id')
  final String craftLocationId;
  @override
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'CraftingRecipeData(id: $id, name: $name, description: $description, resultItemId: $resultItemId, resultQuantity: $resultQuantity, inputs: $inputs, unlockCondition: $unlockCondition, craftLocationId: $craftLocationId, sortOrder: $sortOrder, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CraftingRecipeDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.resultItemId, resultItemId) ||
                other.resultItemId == resultItemId) &&
            (identical(other.resultQuantity, resultQuantity) ||
                other.resultQuantity == resultQuantity) &&
            const DeepCollectionEquality().equals(other._inputs, _inputs) &&
            (identical(other.unlockCondition, unlockCondition) ||
                other.unlockCondition == unlockCondition) &&
            (identical(other.craftLocationId, craftLocationId) ||
                other.craftLocationId == craftLocationId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      resultItemId,
      resultQuantity,
      const DeepCollectionEquality().hash(_inputs),
      unlockCondition,
      craftLocationId,
      sortOrder,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CraftingRecipeDataImplCopyWith<_$CraftingRecipeDataImpl> get copyWith =>
      __$$CraftingRecipeDataImplCopyWithImpl<_$CraftingRecipeDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CraftingRecipeDataImplToJson(
      this,
    );
  }
}

abstract class _CraftingRecipeData implements CraftingRecipeData {
  const factory _CraftingRecipeData(
          {required final String id,
          required final String name,
          final String description,
          @JsonKey(name: 'result_item_id') required final String resultItemId,
          @JsonKey(name: 'result_quantity') final int resultQuantity,
          @JsonKey(name: 'inputs_json') required final List<RecipeInput> inputs,
          @JsonKey(name: 'unlock_condition_json')
          final RecipeUnlockCondition? unlockCondition,
          @JsonKey(name: 'craft_location_id') final String craftLocationId,
          @JsonKey(name: 'sort_order') final int sortOrder,
          @JsonKey(name: 'created_at') final DateTime? createdAt}) =
      _$CraftingRecipeDataImpl;

  factory _CraftingRecipeData.fromJson(Map<String, dynamic> json) =
      _$CraftingRecipeDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  @JsonKey(name: 'result_item_id')
  String get resultItemId;
  @override
  @JsonKey(name: 'result_quantity')
  int get resultQuantity;
  @override
  @JsonKey(name: 'inputs_json')
  List<RecipeInput> get inputs;
  @override
  @JsonKey(name: 'unlock_condition_json')
  RecipeUnlockCondition? get unlockCondition;
  @override
  @JsonKey(name: 'craft_location_id')
  String get craftLocationId;
  @override
  @JsonKey(name: 'sort_order')
  int get sortOrder;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$CraftingRecipeDataImplCopyWith<_$CraftingRecipeDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecipeInput _$RecipeInputFromJson(Map<String, dynamic> json) {
  return _RecipeInput.fromJson(json);
}

/// @nodoc
mixin _$RecipeInput {
  @JsonKey(name: 'item_id')
  String get itemId => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RecipeInputCopyWith<RecipeInput> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipeInputCopyWith<$Res> {
  factory $RecipeInputCopyWith(
          RecipeInput value, $Res Function(RecipeInput) then) =
      _$RecipeInputCopyWithImpl<$Res, RecipeInput>;
  @useResult
  $Res call({@JsonKey(name: 'item_id') String itemId, int quantity});
}

/// @nodoc
class _$RecipeInputCopyWithImpl<$Res, $Val extends RecipeInput>
    implements $RecipeInputCopyWith<$Res> {
  _$RecipeInputCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? quantity = null,
  }) {
    return _then(_value.copyWith(
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecipeInputImplCopyWith<$Res>
    implements $RecipeInputCopyWith<$Res> {
  factory _$$RecipeInputImplCopyWith(
          _$RecipeInputImpl value, $Res Function(_$RecipeInputImpl) then) =
      __$$RecipeInputImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'item_id') String itemId, int quantity});
}

/// @nodoc
class __$$RecipeInputImplCopyWithImpl<$Res>
    extends _$RecipeInputCopyWithImpl<$Res, _$RecipeInputImpl>
    implements _$$RecipeInputImplCopyWith<$Res> {
  __$$RecipeInputImplCopyWithImpl(
      _$RecipeInputImpl _value, $Res Function(_$RecipeInputImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? quantity = null,
  }) {
    return _then(_$RecipeInputImpl(
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeInputImpl implements _RecipeInput {
  const _$RecipeInputImpl(
      {@JsonKey(name: 'item_id') required this.itemId, required this.quantity});

  factory _$RecipeInputImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeInputImplFromJson(json);

  @override
  @JsonKey(name: 'item_id')
  final String itemId;
  @override
  final int quantity;

  @override
  String toString() {
    return 'RecipeInput(itemId: $itemId, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeInputImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, itemId, quantity);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeInputImplCopyWith<_$RecipeInputImpl> get copyWith =>
      __$$RecipeInputImplCopyWithImpl<_$RecipeInputImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeInputImplToJson(
      this,
    );
  }
}

abstract class _RecipeInput implements RecipeInput {
  const factory _RecipeInput(
      {@JsonKey(name: 'item_id') required final String itemId,
      required final int quantity}) = _$RecipeInputImpl;

  factory _RecipeInput.fromJson(Map<String, dynamic> json) =
      _$RecipeInputImpl.fromJson;

  @override
  @JsonKey(name: 'item_id')
  String get itemId;
  @override
  int get quantity;
  @override
  @JsonKey(ignore: true)
  _$$RecipeInputImplCopyWith<_$RecipeInputImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecipeUnlockCondition _$RecipeUnlockConditionFromJson(
    Map<String, dynamic> json) {
  return _RecipeUnlockCondition.fromJson(json);
}

/// @nodoc
mixin _$RecipeUnlockCondition {
  @JsonKey(name: 'trust_level')
  int? get trustLevel => throw _privateConstructorUsedError;
  @JsonKey(name: 'chain_step')
  ChainStepCondition? get chainStep => throw _privateConstructorUsedError;
  @JsonKey(name: 'first_acquired_item')
  String? get firstAcquiredItem =>
      throw _privateConstructorUsedError; // M7 페이즈 4 #4 신규 type 분기 필드
  String? get type =>
      throw _privateConstructorUsedError; // 'regionFlag' / 'infrastructureTier' / 'all' / 'any'
  String? get flag => throw _privateConstructorUsedError;
  int? get value => throw _privateConstructorUsedError;
  List<RecipeUnlockCondition>? get conditions =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RecipeUnlockConditionCopyWith<RecipeUnlockCondition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipeUnlockConditionCopyWith<$Res> {
  factory $RecipeUnlockConditionCopyWith(RecipeUnlockCondition value,
          $Res Function(RecipeUnlockCondition) then) =
      _$RecipeUnlockConditionCopyWithImpl<$Res, RecipeUnlockCondition>;
  @useResult
  $Res call(
      {@JsonKey(name: 'trust_level') int? trustLevel,
      @JsonKey(name: 'chain_step') ChainStepCondition? chainStep,
      @JsonKey(name: 'first_acquired_item') String? firstAcquiredItem,
      String? type,
      String? flag,
      int? value,
      List<RecipeUnlockCondition>? conditions});

  $ChainStepConditionCopyWith<$Res>? get chainStep;
}

/// @nodoc
class _$RecipeUnlockConditionCopyWithImpl<$Res,
        $Val extends RecipeUnlockCondition>
    implements $RecipeUnlockConditionCopyWith<$Res> {
  _$RecipeUnlockConditionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? trustLevel = freezed,
    Object? chainStep = freezed,
    Object? firstAcquiredItem = freezed,
    Object? type = freezed,
    Object? flag = freezed,
    Object? value = freezed,
    Object? conditions = freezed,
  }) {
    return _then(_value.copyWith(
      trustLevel: freezed == trustLevel
          ? _value.trustLevel
          : trustLevel // ignore: cast_nullable_to_non_nullable
              as int?,
      chainStep: freezed == chainStep
          ? _value.chainStep
          : chainStep // ignore: cast_nullable_to_non_nullable
              as ChainStepCondition?,
      firstAcquiredItem: freezed == firstAcquiredItem
          ? _value.firstAcquiredItem
          : firstAcquiredItem // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      flag: freezed == flag
          ? _value.flag
          : flag // ignore: cast_nullable_to_non_nullable
              as String?,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as int?,
      conditions: freezed == conditions
          ? _value.conditions
          : conditions // ignore: cast_nullable_to_non_nullable
              as List<RecipeUnlockCondition>?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ChainStepConditionCopyWith<$Res>? get chainStep {
    if (_value.chainStep == null) {
      return null;
    }

    return $ChainStepConditionCopyWith<$Res>(_value.chainStep!, (value) {
      return _then(_value.copyWith(chainStep: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RecipeUnlockConditionImplCopyWith<$Res>
    implements $RecipeUnlockConditionCopyWith<$Res> {
  factory _$$RecipeUnlockConditionImplCopyWith(
          _$RecipeUnlockConditionImpl value,
          $Res Function(_$RecipeUnlockConditionImpl) then) =
      __$$RecipeUnlockConditionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'trust_level') int? trustLevel,
      @JsonKey(name: 'chain_step') ChainStepCondition? chainStep,
      @JsonKey(name: 'first_acquired_item') String? firstAcquiredItem,
      String? type,
      String? flag,
      int? value,
      List<RecipeUnlockCondition>? conditions});

  @override
  $ChainStepConditionCopyWith<$Res>? get chainStep;
}

/// @nodoc
class __$$RecipeUnlockConditionImplCopyWithImpl<$Res>
    extends _$RecipeUnlockConditionCopyWithImpl<$Res,
        _$RecipeUnlockConditionImpl>
    implements _$$RecipeUnlockConditionImplCopyWith<$Res> {
  __$$RecipeUnlockConditionImplCopyWithImpl(_$RecipeUnlockConditionImpl _value,
      $Res Function(_$RecipeUnlockConditionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? trustLevel = freezed,
    Object? chainStep = freezed,
    Object? firstAcquiredItem = freezed,
    Object? type = freezed,
    Object? flag = freezed,
    Object? value = freezed,
    Object? conditions = freezed,
  }) {
    return _then(_$RecipeUnlockConditionImpl(
      trustLevel: freezed == trustLevel
          ? _value.trustLevel
          : trustLevel // ignore: cast_nullable_to_non_nullable
              as int?,
      chainStep: freezed == chainStep
          ? _value.chainStep
          : chainStep // ignore: cast_nullable_to_non_nullable
              as ChainStepCondition?,
      firstAcquiredItem: freezed == firstAcquiredItem
          ? _value.firstAcquiredItem
          : firstAcquiredItem // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      flag: freezed == flag
          ? _value.flag
          : flag // ignore: cast_nullable_to_non_nullable
              as String?,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as int?,
      conditions: freezed == conditions
          ? _value._conditions
          : conditions // ignore: cast_nullable_to_non_nullable
              as List<RecipeUnlockCondition>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeUnlockConditionImpl implements _RecipeUnlockCondition {
  const _$RecipeUnlockConditionImpl(
      {@JsonKey(name: 'trust_level') this.trustLevel,
      @JsonKey(name: 'chain_step') this.chainStep,
      @JsonKey(name: 'first_acquired_item') this.firstAcquiredItem,
      this.type,
      this.flag,
      this.value,
      final List<RecipeUnlockCondition>? conditions})
      : _conditions = conditions;

  factory _$RecipeUnlockConditionImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeUnlockConditionImplFromJson(json);

  @override
  @JsonKey(name: 'trust_level')
  final int? trustLevel;
  @override
  @JsonKey(name: 'chain_step')
  final ChainStepCondition? chainStep;
  @override
  @JsonKey(name: 'first_acquired_item')
  final String? firstAcquiredItem;
// M7 페이즈 4 #4 신규 type 분기 필드
  @override
  final String? type;
// 'regionFlag' / 'infrastructureTier' / 'all' / 'any'
  @override
  final String? flag;
  @override
  final int? value;
  final List<RecipeUnlockCondition>? _conditions;
  @override
  List<RecipeUnlockCondition>? get conditions {
    final value = _conditions;
    if (value == null) return null;
    if (_conditions is EqualUnmodifiableListView) return _conditions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'RecipeUnlockCondition(trustLevel: $trustLevel, chainStep: $chainStep, firstAcquiredItem: $firstAcquiredItem, type: $type, flag: $flag, value: $value, conditions: $conditions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeUnlockConditionImpl &&
            (identical(other.trustLevel, trustLevel) ||
                other.trustLevel == trustLevel) &&
            (identical(other.chainStep, chainStep) ||
                other.chainStep == chainStep) &&
            (identical(other.firstAcquiredItem, firstAcquiredItem) ||
                other.firstAcquiredItem == firstAcquiredItem) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.flag, flag) || other.flag == flag) &&
            (identical(other.value, value) || other.value == value) &&
            const DeepCollectionEquality()
                .equals(other._conditions, _conditions));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      trustLevel,
      chainStep,
      firstAcquiredItem,
      type,
      flag,
      value,
      const DeepCollectionEquality().hash(_conditions));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeUnlockConditionImplCopyWith<_$RecipeUnlockConditionImpl>
      get copyWith => __$$RecipeUnlockConditionImplCopyWithImpl<
          _$RecipeUnlockConditionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeUnlockConditionImplToJson(
      this,
    );
  }
}

abstract class _RecipeUnlockCondition implements RecipeUnlockCondition {
  const factory _RecipeUnlockCondition(
          {@JsonKey(name: 'trust_level') final int? trustLevel,
          @JsonKey(name: 'chain_step') final ChainStepCondition? chainStep,
          @JsonKey(name: 'first_acquired_item') final String? firstAcquiredItem,
          final String? type,
          final String? flag,
          final int? value,
          final List<RecipeUnlockCondition>? conditions}) =
      _$RecipeUnlockConditionImpl;

  factory _RecipeUnlockCondition.fromJson(Map<String, dynamic> json) =
      _$RecipeUnlockConditionImpl.fromJson;

  @override
  @JsonKey(name: 'trust_level')
  int? get trustLevel;
  @override
  @JsonKey(name: 'chain_step')
  ChainStepCondition? get chainStep;
  @override
  @JsonKey(name: 'first_acquired_item')
  String? get firstAcquiredItem;
  @override // M7 페이즈 4 #4 신규 type 분기 필드
  String? get type;
  @override // 'regionFlag' / 'infrastructureTier' / 'all' / 'any'
  String? get flag;
  @override
  int? get value;
  @override
  List<RecipeUnlockCondition>? get conditions;
  @override
  @JsonKey(ignore: true)
  _$$RecipeUnlockConditionImplCopyWith<_$RecipeUnlockConditionImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ChainStepCondition _$ChainStepConditionFromJson(Map<String, dynamic> json) {
  return _ChainStepCondition.fromJson(json);
}

/// @nodoc
mixin _$ChainStepCondition {
  @JsonKey(name: 'chain_id')
  String get chainId => throw _privateConstructorUsedError;
  int get step => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChainStepConditionCopyWith<ChainStepCondition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChainStepConditionCopyWith<$Res> {
  factory $ChainStepConditionCopyWith(
          ChainStepCondition value, $Res Function(ChainStepCondition) then) =
      _$ChainStepConditionCopyWithImpl<$Res, ChainStepCondition>;
  @useResult
  $Res call({@JsonKey(name: 'chain_id') String chainId, int step});
}

/// @nodoc
class _$ChainStepConditionCopyWithImpl<$Res, $Val extends ChainStepCondition>
    implements $ChainStepConditionCopyWith<$Res> {
  _$ChainStepConditionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chainId = null,
    Object? step = null,
  }) {
    return _then(_value.copyWith(
      chainId: null == chainId
          ? _value.chainId
          : chainId // ignore: cast_nullable_to_non_nullable
              as String,
      step: null == step
          ? _value.step
          : step // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChainStepConditionImplCopyWith<$Res>
    implements $ChainStepConditionCopyWith<$Res> {
  factory _$$ChainStepConditionImplCopyWith(_$ChainStepConditionImpl value,
          $Res Function(_$ChainStepConditionImpl) then) =
      __$$ChainStepConditionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'chain_id') String chainId, int step});
}

/// @nodoc
class __$$ChainStepConditionImplCopyWithImpl<$Res>
    extends _$ChainStepConditionCopyWithImpl<$Res, _$ChainStepConditionImpl>
    implements _$$ChainStepConditionImplCopyWith<$Res> {
  __$$ChainStepConditionImplCopyWithImpl(_$ChainStepConditionImpl _value,
      $Res Function(_$ChainStepConditionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chainId = null,
    Object? step = null,
  }) {
    return _then(_$ChainStepConditionImpl(
      chainId: null == chainId
          ? _value.chainId
          : chainId // ignore: cast_nullable_to_non_nullable
              as String,
      step: null == step
          ? _value.step
          : step // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChainStepConditionImpl implements _ChainStepCondition {
  const _$ChainStepConditionImpl(
      {@JsonKey(name: 'chain_id') required this.chainId, required this.step});

  factory _$ChainStepConditionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChainStepConditionImplFromJson(json);

  @override
  @JsonKey(name: 'chain_id')
  final String chainId;
  @override
  final int step;

  @override
  String toString() {
    return 'ChainStepCondition(chainId: $chainId, step: $step)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChainStepConditionImpl &&
            (identical(other.chainId, chainId) || other.chainId == chainId) &&
            (identical(other.step, step) || other.step == step));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, chainId, step);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChainStepConditionImplCopyWith<_$ChainStepConditionImpl> get copyWith =>
      __$$ChainStepConditionImplCopyWithImpl<_$ChainStepConditionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChainStepConditionImplToJson(
      this,
    );
  }
}

abstract class _ChainStepCondition implements ChainStepCondition {
  const factory _ChainStepCondition(
      {@JsonKey(name: 'chain_id') required final String chainId,
      required final int step}) = _$ChainStepConditionImpl;

  factory _ChainStepCondition.fromJson(Map<String, dynamic> json) =
      _$ChainStepConditionImpl.fromJson;

  @override
  @JsonKey(name: 'chain_id')
  String get chainId;
  @override
  int get step;
  @override
  @JsonKey(ignore: true)
  _$$ChainStepConditionImplCopyWith<_$ChainStepConditionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
