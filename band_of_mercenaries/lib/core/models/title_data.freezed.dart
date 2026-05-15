// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'title_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TitleData _$TitleDataFromJson(Map<String, dynamic> json) {
  return _TitleData.fromJson(json);
}

/// @nodoc
mixin _$TitleData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'hook_type')
  String get hookType => throw _privateConstructorUsedError;
  @JsonKey(name: 'hook_condition')
  Map<String, dynamic> get hookCondition => throw _privateConstructorUsedError;
  @JsonKey(name: 'effect_json')
  Map<String, dynamic> get effectJson => throw _privateConstructorUsedError;
  @JsonKey(name: 'icon_key')
  String get iconKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'narrative_hint')
  String? get narrativeHint => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TitleDataCopyWith<TitleData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TitleDataCopyWith<$Res> {
  factory $TitleDataCopyWith(TitleData value, $Res Function(TitleData) then) =
      _$TitleDataCopyWithImpl<$Res, TitleData>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      @JsonKey(name: 'hook_type') String hookType,
      @JsonKey(name: 'hook_condition') Map<String, dynamic> hookCondition,
      @JsonKey(name: 'effect_json') Map<String, dynamic> effectJson,
      @JsonKey(name: 'icon_key') String iconKey,
      @JsonKey(name: 'narrative_hint') String? narrativeHint});
}

/// @nodoc
class _$TitleDataCopyWithImpl<$Res, $Val extends TitleData>
    implements $TitleDataCopyWith<$Res> {
  _$TitleDataCopyWithImpl(this._value, this._then);

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
    Object? hookType = null,
    Object? hookCondition = null,
    Object? effectJson = null,
    Object? iconKey = null,
    Object? narrativeHint = freezed,
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
      hookType: null == hookType
          ? _value.hookType
          : hookType // ignore: cast_nullable_to_non_nullable
              as String,
      hookCondition: null == hookCondition
          ? _value.hookCondition
          : hookCondition // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      effectJson: null == effectJson
          ? _value.effectJson
          : effectJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      iconKey: null == iconKey
          ? _value.iconKey
          : iconKey // ignore: cast_nullable_to_non_nullable
              as String,
      narrativeHint: freezed == narrativeHint
          ? _value.narrativeHint
          : narrativeHint // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TitleDataImplCopyWith<$Res>
    implements $TitleDataCopyWith<$Res> {
  factory _$$TitleDataImplCopyWith(
          _$TitleDataImpl value, $Res Function(_$TitleDataImpl) then) =
      __$$TitleDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      @JsonKey(name: 'hook_type') String hookType,
      @JsonKey(name: 'hook_condition') Map<String, dynamic> hookCondition,
      @JsonKey(name: 'effect_json') Map<String, dynamic> effectJson,
      @JsonKey(name: 'icon_key') String iconKey,
      @JsonKey(name: 'narrative_hint') String? narrativeHint});
}

/// @nodoc
class __$$TitleDataImplCopyWithImpl<$Res>
    extends _$TitleDataCopyWithImpl<$Res, _$TitleDataImpl>
    implements _$$TitleDataImplCopyWith<$Res> {
  __$$TitleDataImplCopyWithImpl(
      _$TitleDataImpl _value, $Res Function(_$TitleDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? hookType = null,
    Object? hookCondition = null,
    Object? effectJson = null,
    Object? iconKey = null,
    Object? narrativeHint = freezed,
  }) {
    return _then(_$TitleDataImpl(
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
      hookType: null == hookType
          ? _value.hookType
          : hookType // ignore: cast_nullable_to_non_nullable
              as String,
      hookCondition: null == hookCondition
          ? _value._hookCondition
          : hookCondition // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      effectJson: null == effectJson
          ? _value._effectJson
          : effectJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      iconKey: null == iconKey
          ? _value.iconKey
          : iconKey // ignore: cast_nullable_to_non_nullable
              as String,
      narrativeHint: freezed == narrativeHint
          ? _value.narrativeHint
          : narrativeHint // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TitleDataImpl implements _TitleData {
  const _$TitleDataImpl(
      {required this.id,
      required this.name,
      required this.description,
      @JsonKey(name: 'hook_type') required this.hookType,
      @JsonKey(name: 'hook_condition')
      final Map<String, dynamic> hookCondition = const {},
      @JsonKey(name: 'effect_json')
      final Map<String, dynamic> effectJson = const {},
      @JsonKey(name: 'icon_key') this.iconKey = 'default',
      @JsonKey(name: 'narrative_hint') this.narrativeHint})
      : _hookCondition = hookCondition,
        _effectJson = effectJson;

  factory _$TitleDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$TitleDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  @JsonKey(name: 'hook_type')
  final String hookType;
  final Map<String, dynamic> _hookCondition;
  @override
  @JsonKey(name: 'hook_condition')
  Map<String, dynamic> get hookCondition {
    if (_hookCondition is EqualUnmodifiableMapView) return _hookCondition;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_hookCondition);
  }

  final Map<String, dynamic> _effectJson;
  @override
  @JsonKey(name: 'effect_json')
  Map<String, dynamic> get effectJson {
    if (_effectJson is EqualUnmodifiableMapView) return _effectJson;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_effectJson);
  }

  @override
  @JsonKey(name: 'icon_key')
  final String iconKey;
  @override
  @JsonKey(name: 'narrative_hint')
  final String? narrativeHint;

  @override
  String toString() {
    return 'TitleData(id: $id, name: $name, description: $description, hookType: $hookType, hookCondition: $hookCondition, effectJson: $effectJson, iconKey: $iconKey, narrativeHint: $narrativeHint)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TitleDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.hookType, hookType) ||
                other.hookType == hookType) &&
            const DeepCollectionEquality()
                .equals(other._hookCondition, _hookCondition) &&
            const DeepCollectionEquality()
                .equals(other._effectJson, _effectJson) &&
            (identical(other.iconKey, iconKey) || other.iconKey == iconKey) &&
            (identical(other.narrativeHint, narrativeHint) ||
                other.narrativeHint == narrativeHint));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      hookType,
      const DeepCollectionEquality().hash(_hookCondition),
      const DeepCollectionEquality().hash(_effectJson),
      iconKey,
      narrativeHint);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TitleDataImplCopyWith<_$TitleDataImpl> get copyWith =>
      __$$TitleDataImplCopyWithImpl<_$TitleDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TitleDataImplToJson(
      this,
    );
  }
}

abstract class _TitleData implements TitleData {
  const factory _TitleData(
      {required final String id,
      required final String name,
      required final String description,
      @JsonKey(name: 'hook_type') required final String hookType,
      @JsonKey(name: 'hook_condition') final Map<String, dynamic> hookCondition,
      @JsonKey(name: 'effect_json') final Map<String, dynamic> effectJson,
      @JsonKey(name: 'icon_key') final String iconKey,
      @JsonKey(name: 'narrative_hint')
      final String? narrativeHint}) = _$TitleDataImpl;

  factory _TitleData.fromJson(Map<String, dynamic> json) =
      _$TitleDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  @JsonKey(name: 'hook_type')
  String get hookType;
  @override
  @JsonKey(name: 'hook_condition')
  Map<String, dynamic> get hookCondition;
  @override
  @JsonKey(name: 'effect_json')
  Map<String, dynamic> get effectJson;
  @override
  @JsonKey(name: 'icon_key')
  String get iconKey;
  @override
  @JsonKey(name: 'narrative_hint')
  String? get narrativeHint;
  @override
  @JsonKey(ignore: true)
  _$$TitleDataImplCopyWith<_$TitleDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
