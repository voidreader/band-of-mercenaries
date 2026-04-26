// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'travel_choice_event_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TravelChoiceEventData _$TravelChoiceEventDataFromJson(
    Map<String, dynamic> json) {
  return _TravelChoiceEventData.fromJson(json);
}

/// @nodoc
mixin _$TravelChoiceEventData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get situation => throw _privateConstructorUsedError;
  @JsonKey(name: 'min_tier')
  int get minTier => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_tier')
  int get maxTier => throw _privateConstructorUsedError;
  int get weight => throw _privateConstructorUsedError;
  @JsonKey(name: 'preferred_traits')
  String? get preferredTraits => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TravelChoiceEventDataCopyWith<TravelChoiceEventData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TravelChoiceEventDataCopyWith<$Res> {
  factory $TravelChoiceEventDataCopyWith(TravelChoiceEventData value,
          $Res Function(TravelChoiceEventData) then) =
      _$TravelChoiceEventDataCopyWithImpl<$Res, TravelChoiceEventData>;
  @useResult
  $Res call(
      {String id,
      String name,
      String category,
      String situation,
      @JsonKey(name: 'min_tier') int minTier,
      @JsonKey(name: 'max_tier') int maxTier,
      int weight,
      @JsonKey(name: 'preferred_traits') String? preferredTraits});
}

/// @nodoc
class _$TravelChoiceEventDataCopyWithImpl<$Res,
        $Val extends TravelChoiceEventData>
    implements $TravelChoiceEventDataCopyWith<$Res> {
  _$TravelChoiceEventDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? situation = null,
    Object? minTier = null,
    Object? maxTier = null,
    Object? weight = null,
    Object? preferredTraits = freezed,
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
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      situation: null == situation
          ? _value.situation
          : situation // ignore: cast_nullable_to_non_nullable
              as String,
      minTier: null == minTier
          ? _value.minTier
          : minTier // ignore: cast_nullable_to_non_nullable
              as int,
      maxTier: null == maxTier
          ? _value.maxTier
          : maxTier // ignore: cast_nullable_to_non_nullable
              as int,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
      preferredTraits: freezed == preferredTraits
          ? _value.preferredTraits
          : preferredTraits // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TravelChoiceEventDataImplCopyWith<$Res>
    implements $TravelChoiceEventDataCopyWith<$Res> {
  factory _$$TravelChoiceEventDataImplCopyWith(
          _$TravelChoiceEventDataImpl value,
          $Res Function(_$TravelChoiceEventDataImpl) then) =
      __$$TravelChoiceEventDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String category,
      String situation,
      @JsonKey(name: 'min_tier') int minTier,
      @JsonKey(name: 'max_tier') int maxTier,
      int weight,
      @JsonKey(name: 'preferred_traits') String? preferredTraits});
}

/// @nodoc
class __$$TravelChoiceEventDataImplCopyWithImpl<$Res>
    extends _$TravelChoiceEventDataCopyWithImpl<$Res,
        _$TravelChoiceEventDataImpl>
    implements _$$TravelChoiceEventDataImplCopyWith<$Res> {
  __$$TravelChoiceEventDataImplCopyWithImpl(_$TravelChoiceEventDataImpl _value,
      $Res Function(_$TravelChoiceEventDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? situation = null,
    Object? minTier = null,
    Object? maxTier = null,
    Object? weight = null,
    Object? preferredTraits = freezed,
  }) {
    return _then(_$TravelChoiceEventDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      situation: null == situation
          ? _value.situation
          : situation // ignore: cast_nullable_to_non_nullable
              as String,
      minTier: null == minTier
          ? _value.minTier
          : minTier // ignore: cast_nullable_to_non_nullable
              as int,
      maxTier: null == maxTier
          ? _value.maxTier
          : maxTier // ignore: cast_nullable_to_non_nullable
              as int,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
      preferredTraits: freezed == preferredTraits
          ? _value.preferredTraits
          : preferredTraits // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TravelChoiceEventDataImpl implements _TravelChoiceEventData {
  const _$TravelChoiceEventDataImpl(
      {required this.id,
      required this.name,
      required this.category,
      required this.situation,
      @JsonKey(name: 'min_tier') required this.minTier,
      @JsonKey(name: 'max_tier') required this.maxTier,
      this.weight = 1,
      @JsonKey(name: 'preferred_traits') this.preferredTraits});

  factory _$TravelChoiceEventDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$TravelChoiceEventDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String category;
  @override
  final String situation;
  @override
  @JsonKey(name: 'min_tier')
  final int minTier;
  @override
  @JsonKey(name: 'max_tier')
  final int maxTier;
  @override
  @JsonKey()
  final int weight;
  @override
  @JsonKey(name: 'preferred_traits')
  final String? preferredTraits;

  @override
  String toString() {
    return 'TravelChoiceEventData(id: $id, name: $name, category: $category, situation: $situation, minTier: $minTier, maxTier: $maxTier, weight: $weight, preferredTraits: $preferredTraits)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TravelChoiceEventDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.situation, situation) ||
                other.situation == situation) &&
            (identical(other.minTier, minTier) || other.minTier == minTier) &&
            (identical(other.maxTier, maxTier) || other.maxTier == maxTier) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.preferredTraits, preferredTraits) ||
                other.preferredTraits == preferredTraits));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, category, situation,
      minTier, maxTier, weight, preferredTraits);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TravelChoiceEventDataImplCopyWith<_$TravelChoiceEventDataImpl>
      get copyWith => __$$TravelChoiceEventDataImplCopyWithImpl<
          _$TravelChoiceEventDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TravelChoiceEventDataImplToJson(
      this,
    );
  }
}

abstract class _TravelChoiceEventData implements TravelChoiceEventData {
  const factory _TravelChoiceEventData(
          {required final String id,
          required final String name,
          required final String category,
          required final String situation,
          @JsonKey(name: 'min_tier') required final int minTier,
          @JsonKey(name: 'max_tier') required final int maxTier,
          final int weight,
          @JsonKey(name: 'preferred_traits') final String? preferredTraits}) =
      _$TravelChoiceEventDataImpl;

  factory _TravelChoiceEventData.fromJson(Map<String, dynamic> json) =
      _$TravelChoiceEventDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get category;
  @override
  String get situation;
  @override
  @JsonKey(name: 'min_tier')
  int get minTier;
  @override
  @JsonKey(name: 'max_tier')
  int get maxTier;
  @override
  int get weight;
  @override
  @JsonKey(name: 'preferred_traits')
  String? get preferredTraits;
  @override
  @JsonKey(ignore: true)
  _$$TravelChoiceEventDataImplCopyWith<_$TravelChoiceEventDataImpl>
      get copyWith => throw _privateConstructorUsedError;
}
