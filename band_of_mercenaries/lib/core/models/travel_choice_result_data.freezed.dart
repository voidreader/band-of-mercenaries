// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'travel_choice_result_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TravelChoiceResultData _$TravelChoiceResultDataFromJson(
    Map<String, dynamic> json) {
  return _TravelChoiceResultData.fromJson(json);
}

/// @nodoc
mixin _$TravelChoiceResultData {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'option_id')
  String get optionId => throw _privateConstructorUsedError;
  @JsonKey(name: 'result_index')
  int get resultIndex => throw _privateConstructorUsedError;
  double get probability => throw _privateConstructorUsedError;
  @JsonKey(name: 'conditional_expr')
  String? get conditionalExpr => throw _privateConstructorUsedError;
  String get narrative => throw _privateConstructorUsedError;
  @JsonKey(name: 'effect_type')
  String get effectType => throw _privateConstructorUsedError;
  @JsonKey(name: 'effect_magnitude')
  double get effectMagnitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'effect_target')
  String? get effectTarget => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TravelChoiceResultDataCopyWith<TravelChoiceResultData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TravelChoiceResultDataCopyWith<$Res> {
  factory $TravelChoiceResultDataCopyWith(TravelChoiceResultData value,
          $Res Function(TravelChoiceResultData) then) =
      _$TravelChoiceResultDataCopyWithImpl<$Res, TravelChoiceResultData>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'option_id') String optionId,
      @JsonKey(name: 'result_index') int resultIndex,
      double probability,
      @JsonKey(name: 'conditional_expr') String? conditionalExpr,
      String narrative,
      @JsonKey(name: 'effect_type') String effectType,
      @JsonKey(name: 'effect_magnitude') double effectMagnitude,
      @JsonKey(name: 'effect_target') String? effectTarget});
}

/// @nodoc
class _$TravelChoiceResultDataCopyWithImpl<$Res,
        $Val extends TravelChoiceResultData>
    implements $TravelChoiceResultDataCopyWith<$Res> {
  _$TravelChoiceResultDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? optionId = null,
    Object? resultIndex = null,
    Object? probability = null,
    Object? conditionalExpr = freezed,
    Object? narrative = null,
    Object? effectType = null,
    Object? effectMagnitude = null,
    Object? effectTarget = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      optionId: null == optionId
          ? _value.optionId
          : optionId // ignore: cast_nullable_to_non_nullable
              as String,
      resultIndex: null == resultIndex
          ? _value.resultIndex
          : resultIndex // ignore: cast_nullable_to_non_nullable
              as int,
      probability: null == probability
          ? _value.probability
          : probability // ignore: cast_nullable_to_non_nullable
              as double,
      conditionalExpr: freezed == conditionalExpr
          ? _value.conditionalExpr
          : conditionalExpr // ignore: cast_nullable_to_non_nullable
              as String?,
      narrative: null == narrative
          ? _value.narrative
          : narrative // ignore: cast_nullable_to_non_nullable
              as String,
      effectType: null == effectType
          ? _value.effectType
          : effectType // ignore: cast_nullable_to_non_nullable
              as String,
      effectMagnitude: null == effectMagnitude
          ? _value.effectMagnitude
          : effectMagnitude // ignore: cast_nullable_to_non_nullable
              as double,
      effectTarget: freezed == effectTarget
          ? _value.effectTarget
          : effectTarget // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TravelChoiceResultDataImplCopyWith<$Res>
    implements $TravelChoiceResultDataCopyWith<$Res> {
  factory _$$TravelChoiceResultDataImplCopyWith(
          _$TravelChoiceResultDataImpl value,
          $Res Function(_$TravelChoiceResultDataImpl) then) =
      __$$TravelChoiceResultDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'option_id') String optionId,
      @JsonKey(name: 'result_index') int resultIndex,
      double probability,
      @JsonKey(name: 'conditional_expr') String? conditionalExpr,
      String narrative,
      @JsonKey(name: 'effect_type') String effectType,
      @JsonKey(name: 'effect_magnitude') double effectMagnitude,
      @JsonKey(name: 'effect_target') String? effectTarget});
}

/// @nodoc
class __$$TravelChoiceResultDataImplCopyWithImpl<$Res>
    extends _$TravelChoiceResultDataCopyWithImpl<$Res,
        _$TravelChoiceResultDataImpl>
    implements _$$TravelChoiceResultDataImplCopyWith<$Res> {
  __$$TravelChoiceResultDataImplCopyWithImpl(
      _$TravelChoiceResultDataImpl _value,
      $Res Function(_$TravelChoiceResultDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? optionId = null,
    Object? resultIndex = null,
    Object? probability = null,
    Object? conditionalExpr = freezed,
    Object? narrative = null,
    Object? effectType = null,
    Object? effectMagnitude = null,
    Object? effectTarget = freezed,
  }) {
    return _then(_$TravelChoiceResultDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      optionId: null == optionId
          ? _value.optionId
          : optionId // ignore: cast_nullable_to_non_nullable
              as String,
      resultIndex: null == resultIndex
          ? _value.resultIndex
          : resultIndex // ignore: cast_nullable_to_non_nullable
              as int,
      probability: null == probability
          ? _value.probability
          : probability // ignore: cast_nullable_to_non_nullable
              as double,
      conditionalExpr: freezed == conditionalExpr
          ? _value.conditionalExpr
          : conditionalExpr // ignore: cast_nullable_to_non_nullable
              as String?,
      narrative: null == narrative
          ? _value.narrative
          : narrative // ignore: cast_nullable_to_non_nullable
              as String,
      effectType: null == effectType
          ? _value.effectType
          : effectType // ignore: cast_nullable_to_non_nullable
              as String,
      effectMagnitude: null == effectMagnitude
          ? _value.effectMagnitude
          : effectMagnitude // ignore: cast_nullable_to_non_nullable
              as double,
      effectTarget: freezed == effectTarget
          ? _value.effectTarget
          : effectTarget // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TravelChoiceResultDataImpl implements _TravelChoiceResultData {
  const _$TravelChoiceResultDataImpl(
      {required this.id,
      @JsonKey(name: 'option_id') required this.optionId,
      @JsonKey(name: 'result_index') required this.resultIndex,
      required this.probability,
      @JsonKey(name: 'conditional_expr') this.conditionalExpr,
      required this.narrative,
      @JsonKey(name: 'effect_type') required this.effectType,
      @JsonKey(name: 'effect_magnitude') this.effectMagnitude = 0.0,
      @JsonKey(name: 'effect_target') this.effectTarget});

  factory _$TravelChoiceResultDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$TravelChoiceResultDataImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'option_id')
  final String optionId;
  @override
  @JsonKey(name: 'result_index')
  final int resultIndex;
  @override
  final double probability;
  @override
  @JsonKey(name: 'conditional_expr')
  final String? conditionalExpr;
  @override
  final String narrative;
  @override
  @JsonKey(name: 'effect_type')
  final String effectType;
  @override
  @JsonKey(name: 'effect_magnitude')
  final double effectMagnitude;
  @override
  @JsonKey(name: 'effect_target')
  final String? effectTarget;

  @override
  String toString() {
    return 'TravelChoiceResultData(id: $id, optionId: $optionId, resultIndex: $resultIndex, probability: $probability, conditionalExpr: $conditionalExpr, narrative: $narrative, effectType: $effectType, effectMagnitude: $effectMagnitude, effectTarget: $effectTarget)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TravelChoiceResultDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.optionId, optionId) ||
                other.optionId == optionId) &&
            (identical(other.resultIndex, resultIndex) ||
                other.resultIndex == resultIndex) &&
            (identical(other.probability, probability) ||
                other.probability == probability) &&
            (identical(other.conditionalExpr, conditionalExpr) ||
                other.conditionalExpr == conditionalExpr) &&
            (identical(other.narrative, narrative) ||
                other.narrative == narrative) &&
            (identical(other.effectType, effectType) ||
                other.effectType == effectType) &&
            (identical(other.effectMagnitude, effectMagnitude) ||
                other.effectMagnitude == effectMagnitude) &&
            (identical(other.effectTarget, effectTarget) ||
                other.effectTarget == effectTarget));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      optionId,
      resultIndex,
      probability,
      conditionalExpr,
      narrative,
      effectType,
      effectMagnitude,
      effectTarget);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TravelChoiceResultDataImplCopyWith<_$TravelChoiceResultDataImpl>
      get copyWith => __$$TravelChoiceResultDataImplCopyWithImpl<
          _$TravelChoiceResultDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TravelChoiceResultDataImplToJson(
      this,
    );
  }
}

abstract class _TravelChoiceResultData implements TravelChoiceResultData {
  const factory _TravelChoiceResultData(
          {required final String id,
          @JsonKey(name: 'option_id') required final String optionId,
          @JsonKey(name: 'result_index') required final int resultIndex,
          required final double probability,
          @JsonKey(name: 'conditional_expr') final String? conditionalExpr,
          required final String narrative,
          @JsonKey(name: 'effect_type') required final String effectType,
          @JsonKey(name: 'effect_magnitude') final double effectMagnitude,
          @JsonKey(name: 'effect_target') final String? effectTarget}) =
      _$TravelChoiceResultDataImpl;

  factory _TravelChoiceResultData.fromJson(Map<String, dynamic> json) =
      _$TravelChoiceResultDataImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'option_id')
  String get optionId;
  @override
  @JsonKey(name: 'result_index')
  int get resultIndex;
  @override
  double get probability;
  @override
  @JsonKey(name: 'conditional_expr')
  String? get conditionalExpr;
  @override
  String get narrative;
  @override
  @JsonKey(name: 'effect_type')
  String get effectType;
  @override
  @JsonKey(name: 'effect_magnitude')
  double get effectMagnitude;
  @override
  @JsonKey(name: 'effect_target')
  String? get effectTarget;
  @override
  @JsonKey(ignore: true)
  _$$TravelChoiceResultDataImplCopyWith<_$TravelChoiceResultDataImpl>
      get copyWith => throw _privateConstructorUsedError;
}
