// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'travel_choice_option_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TravelChoiceOptionData _$TravelChoiceOptionDataFromJson(
    Map<String, dynamic> json) {
  return _TravelChoiceOptionData.fromJson(json);
}

/// @nodoc
mixin _$TravelChoiceOptionData {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'event_id')
  String get eventId => throw _privateConstructorUsedError;
  @JsonKey(name: 'choice_index')
  int get choiceIndex => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  @JsonKey(name: 'visibility_expr')
  String? get visibilityExpr => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_level')
  String get riskLevel => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TravelChoiceOptionDataCopyWith<TravelChoiceOptionData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TravelChoiceOptionDataCopyWith<$Res> {
  factory $TravelChoiceOptionDataCopyWith(TravelChoiceOptionData value,
          $Res Function(TravelChoiceOptionData) then) =
      _$TravelChoiceOptionDataCopyWithImpl<$Res, TravelChoiceOptionData>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'event_id') String eventId,
      @JsonKey(name: 'choice_index') int choiceIndex,
      String label,
      @JsonKey(name: 'visibility_expr') String? visibilityExpr,
      String description,
      @JsonKey(name: 'risk_level') String riskLevel});
}

/// @nodoc
class _$TravelChoiceOptionDataCopyWithImpl<$Res,
        $Val extends TravelChoiceOptionData>
    implements $TravelChoiceOptionDataCopyWith<$Res> {
  _$TravelChoiceOptionDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? eventId = null,
    Object? choiceIndex = null,
    Object? label = null,
    Object? visibilityExpr = freezed,
    Object? description = null,
    Object? riskLevel = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      choiceIndex: null == choiceIndex
          ? _value.choiceIndex
          : choiceIndex // ignore: cast_nullable_to_non_nullable
              as int,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      visibilityExpr: freezed == visibilityExpr
          ? _value.visibilityExpr
          : visibilityExpr // ignore: cast_nullable_to_non_nullable
              as String?,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      riskLevel: null == riskLevel
          ? _value.riskLevel
          : riskLevel // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TravelChoiceOptionDataImplCopyWith<$Res>
    implements $TravelChoiceOptionDataCopyWith<$Res> {
  factory _$$TravelChoiceOptionDataImplCopyWith(
          _$TravelChoiceOptionDataImpl value,
          $Res Function(_$TravelChoiceOptionDataImpl) then) =
      __$$TravelChoiceOptionDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'event_id') String eventId,
      @JsonKey(name: 'choice_index') int choiceIndex,
      String label,
      @JsonKey(name: 'visibility_expr') String? visibilityExpr,
      String description,
      @JsonKey(name: 'risk_level') String riskLevel});
}

/// @nodoc
class __$$TravelChoiceOptionDataImplCopyWithImpl<$Res>
    extends _$TravelChoiceOptionDataCopyWithImpl<$Res,
        _$TravelChoiceOptionDataImpl>
    implements _$$TravelChoiceOptionDataImplCopyWith<$Res> {
  __$$TravelChoiceOptionDataImplCopyWithImpl(
      _$TravelChoiceOptionDataImpl _value,
      $Res Function(_$TravelChoiceOptionDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? eventId = null,
    Object? choiceIndex = null,
    Object? label = null,
    Object? visibilityExpr = freezed,
    Object? description = null,
    Object? riskLevel = null,
  }) {
    return _then(_$TravelChoiceOptionDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      choiceIndex: null == choiceIndex
          ? _value.choiceIndex
          : choiceIndex // ignore: cast_nullable_to_non_nullable
              as int,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      visibilityExpr: freezed == visibilityExpr
          ? _value.visibilityExpr
          : visibilityExpr // ignore: cast_nullable_to_non_nullable
              as String?,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      riskLevel: null == riskLevel
          ? _value.riskLevel
          : riskLevel // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TravelChoiceOptionDataImpl implements _TravelChoiceOptionData {
  const _$TravelChoiceOptionDataImpl(
      {required this.id,
      @JsonKey(name: 'event_id') required this.eventId,
      @JsonKey(name: 'choice_index') required this.choiceIndex,
      required this.label,
      @JsonKey(name: 'visibility_expr') this.visibilityExpr,
      required this.description,
      @JsonKey(name: 'risk_level') required this.riskLevel});

  factory _$TravelChoiceOptionDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$TravelChoiceOptionDataImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'event_id')
  final String eventId;
  @override
  @JsonKey(name: 'choice_index')
  final int choiceIndex;
  @override
  final String label;
  @override
  @JsonKey(name: 'visibility_expr')
  final String? visibilityExpr;
  @override
  final String description;
  @override
  @JsonKey(name: 'risk_level')
  final String riskLevel;

  @override
  String toString() {
    return 'TravelChoiceOptionData(id: $id, eventId: $eventId, choiceIndex: $choiceIndex, label: $label, visibilityExpr: $visibilityExpr, description: $description, riskLevel: $riskLevel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TravelChoiceOptionDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.choiceIndex, choiceIndex) ||
                other.choiceIndex == choiceIndex) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.visibilityExpr, visibilityExpr) ||
                other.visibilityExpr == visibilityExpr) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.riskLevel, riskLevel) ||
                other.riskLevel == riskLevel));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, eventId, choiceIndex, label,
      visibilityExpr, description, riskLevel);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TravelChoiceOptionDataImplCopyWith<_$TravelChoiceOptionDataImpl>
      get copyWith => __$$TravelChoiceOptionDataImplCopyWithImpl<
          _$TravelChoiceOptionDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TravelChoiceOptionDataImplToJson(
      this,
    );
  }
}

abstract class _TravelChoiceOptionData implements TravelChoiceOptionData {
  const factory _TravelChoiceOptionData(
          {required final String id,
          @JsonKey(name: 'event_id') required final String eventId,
          @JsonKey(name: 'choice_index') required final int choiceIndex,
          required final String label,
          @JsonKey(name: 'visibility_expr') final String? visibilityExpr,
          required final String description,
          @JsonKey(name: 'risk_level') required final String riskLevel}) =
      _$TravelChoiceOptionDataImpl;

  factory _TravelChoiceOptionData.fromJson(Map<String, dynamic> json) =
      _$TravelChoiceOptionDataImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'event_id')
  String get eventId;
  @override
  @JsonKey(name: 'choice_index')
  int get choiceIndex;
  @override
  String get label;
  @override
  @JsonKey(name: 'visibility_expr')
  String? get visibilityExpr;
  @override
  String get description;
  @override
  @JsonKey(name: 'risk_level')
  String get riskLevel;
  @override
  @JsonKey(ignore: true)
  _$$TravelChoiceOptionDataImplCopyWith<_$TravelChoiceOptionDataImpl>
      get copyWith => throw _privateConstructorUsedError;
}
