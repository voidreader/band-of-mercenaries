// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hidden_stat_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HiddenStatData _$HiddenStatDataFromJson(Map<String, dynamic> json) {
  return _HiddenStatData.fromJson(json);
}

/// @nodoc
mixin _$HiddenStatData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'counter_key')
  String get counterKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'level_thresholds')
  List<int> get levelThresholds => throw _privateConstructorUsedError;
  @JsonKey(name: 'combat_effects_json')
  Map<String, dynamic> get combatEffectsJson =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'passive_effects_json')
  Map<String, dynamic>? get passiveEffectsJson =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'post_reward_effects_json')
  Map<String, dynamic>? get postRewardEffectsJson =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'icon_key')
  String get iconKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'narrative_hint')
  String? get narrativeHint => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HiddenStatDataCopyWith<HiddenStatData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HiddenStatDataCopyWith<$Res> {
  factory $HiddenStatDataCopyWith(
          HiddenStatData value, $Res Function(HiddenStatData) then) =
      _$HiddenStatDataCopyWithImpl<$Res, HiddenStatData>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      @JsonKey(name: 'counter_key') String counterKey,
      @JsonKey(name: 'level_thresholds') List<int> levelThresholds,
      @JsonKey(name: 'combat_effects_json')
      Map<String, dynamic> combatEffectsJson,
      @JsonKey(name: 'passive_effects_json')
      Map<String, dynamic>? passiveEffectsJson,
      @JsonKey(name: 'post_reward_effects_json')
      Map<String, dynamic>? postRewardEffectsJson,
      @JsonKey(name: 'icon_key') String iconKey,
      @JsonKey(name: 'narrative_hint') String? narrativeHint});
}

/// @nodoc
class _$HiddenStatDataCopyWithImpl<$Res, $Val extends HiddenStatData>
    implements $HiddenStatDataCopyWith<$Res> {
  _$HiddenStatDataCopyWithImpl(this._value, this._then);

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
    Object? counterKey = null,
    Object? levelThresholds = null,
    Object? combatEffectsJson = null,
    Object? passiveEffectsJson = freezed,
    Object? postRewardEffectsJson = freezed,
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
      counterKey: null == counterKey
          ? _value.counterKey
          : counterKey // ignore: cast_nullable_to_non_nullable
              as String,
      levelThresholds: null == levelThresholds
          ? _value.levelThresholds
          : levelThresholds // ignore: cast_nullable_to_non_nullable
              as List<int>,
      combatEffectsJson: null == combatEffectsJson
          ? _value.combatEffectsJson
          : combatEffectsJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      passiveEffectsJson: freezed == passiveEffectsJson
          ? _value.passiveEffectsJson
          : passiveEffectsJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      postRewardEffectsJson: freezed == postRewardEffectsJson
          ? _value.postRewardEffectsJson
          : postRewardEffectsJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
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
abstract class _$$HiddenStatDataImplCopyWith<$Res>
    implements $HiddenStatDataCopyWith<$Res> {
  factory _$$HiddenStatDataImplCopyWith(_$HiddenStatDataImpl value,
          $Res Function(_$HiddenStatDataImpl) then) =
      __$$HiddenStatDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      @JsonKey(name: 'counter_key') String counterKey,
      @JsonKey(name: 'level_thresholds') List<int> levelThresholds,
      @JsonKey(name: 'combat_effects_json')
      Map<String, dynamic> combatEffectsJson,
      @JsonKey(name: 'passive_effects_json')
      Map<String, dynamic>? passiveEffectsJson,
      @JsonKey(name: 'post_reward_effects_json')
      Map<String, dynamic>? postRewardEffectsJson,
      @JsonKey(name: 'icon_key') String iconKey,
      @JsonKey(name: 'narrative_hint') String? narrativeHint});
}

/// @nodoc
class __$$HiddenStatDataImplCopyWithImpl<$Res>
    extends _$HiddenStatDataCopyWithImpl<$Res, _$HiddenStatDataImpl>
    implements _$$HiddenStatDataImplCopyWith<$Res> {
  __$$HiddenStatDataImplCopyWithImpl(
      _$HiddenStatDataImpl _value, $Res Function(_$HiddenStatDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? counterKey = null,
    Object? levelThresholds = null,
    Object? combatEffectsJson = null,
    Object? passiveEffectsJson = freezed,
    Object? postRewardEffectsJson = freezed,
    Object? iconKey = null,
    Object? narrativeHint = freezed,
  }) {
    return _then(_$HiddenStatDataImpl(
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
      counterKey: null == counterKey
          ? _value.counterKey
          : counterKey // ignore: cast_nullable_to_non_nullable
              as String,
      levelThresholds: null == levelThresholds
          ? _value._levelThresholds
          : levelThresholds // ignore: cast_nullable_to_non_nullable
              as List<int>,
      combatEffectsJson: null == combatEffectsJson
          ? _value._combatEffectsJson
          : combatEffectsJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      passiveEffectsJson: freezed == passiveEffectsJson
          ? _value._passiveEffectsJson
          : passiveEffectsJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      postRewardEffectsJson: freezed == postRewardEffectsJson
          ? _value._postRewardEffectsJson
          : postRewardEffectsJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
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
class _$HiddenStatDataImpl implements _HiddenStatData {
  const _$HiddenStatDataImpl(
      {required this.id,
      required this.name,
      required this.description,
      @JsonKey(name: 'counter_key') required this.counterKey,
      @JsonKey(name: 'level_thresholds')
      required final List<int> levelThresholds,
      @JsonKey(name: 'combat_effects_json')
      required final Map<String, dynamic> combatEffectsJson,
      @JsonKey(name: 'passive_effects_json')
      final Map<String, dynamic>? passiveEffectsJson,
      @JsonKey(name: 'post_reward_effects_json')
      final Map<String, dynamic>? postRewardEffectsJson,
      @JsonKey(name: 'icon_key') this.iconKey = 'default',
      @JsonKey(name: 'narrative_hint') this.narrativeHint})
      : _levelThresholds = levelThresholds,
        _combatEffectsJson = combatEffectsJson,
        _passiveEffectsJson = passiveEffectsJson,
        _postRewardEffectsJson = postRewardEffectsJson;

  factory _$HiddenStatDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$HiddenStatDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  @JsonKey(name: 'counter_key')
  final String counterKey;
  final List<int> _levelThresholds;
  @override
  @JsonKey(name: 'level_thresholds')
  List<int> get levelThresholds {
    if (_levelThresholds is EqualUnmodifiableListView) return _levelThresholds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_levelThresholds);
  }

  final Map<String, dynamic> _combatEffectsJson;
  @override
  @JsonKey(name: 'combat_effects_json')
  Map<String, dynamic> get combatEffectsJson {
    if (_combatEffectsJson is EqualUnmodifiableMapView)
      return _combatEffectsJson;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_combatEffectsJson);
  }

  final Map<String, dynamic>? _passiveEffectsJson;
  @override
  @JsonKey(name: 'passive_effects_json')
  Map<String, dynamic>? get passiveEffectsJson {
    final value = _passiveEffectsJson;
    if (value == null) return null;
    if (_passiveEffectsJson is EqualUnmodifiableMapView)
      return _passiveEffectsJson;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, dynamic>? _postRewardEffectsJson;
  @override
  @JsonKey(name: 'post_reward_effects_json')
  Map<String, dynamic>? get postRewardEffectsJson {
    final value = _postRewardEffectsJson;
    if (value == null) return null;
    if (_postRewardEffectsJson is EqualUnmodifiableMapView)
      return _postRewardEffectsJson;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'icon_key')
  final String iconKey;
  @override
  @JsonKey(name: 'narrative_hint')
  final String? narrativeHint;

  @override
  String toString() {
    return 'HiddenStatData(id: $id, name: $name, description: $description, counterKey: $counterKey, levelThresholds: $levelThresholds, combatEffectsJson: $combatEffectsJson, passiveEffectsJson: $passiveEffectsJson, postRewardEffectsJson: $postRewardEffectsJson, iconKey: $iconKey, narrativeHint: $narrativeHint)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HiddenStatDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.counterKey, counterKey) ||
                other.counterKey == counterKey) &&
            const DeepCollectionEquality()
                .equals(other._levelThresholds, _levelThresholds) &&
            const DeepCollectionEquality()
                .equals(other._combatEffectsJson, _combatEffectsJson) &&
            const DeepCollectionEquality()
                .equals(other._passiveEffectsJson, _passiveEffectsJson) &&
            const DeepCollectionEquality()
                .equals(other._postRewardEffectsJson, _postRewardEffectsJson) &&
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
      counterKey,
      const DeepCollectionEquality().hash(_levelThresholds),
      const DeepCollectionEquality().hash(_combatEffectsJson),
      const DeepCollectionEquality().hash(_passiveEffectsJson),
      const DeepCollectionEquality().hash(_postRewardEffectsJson),
      iconKey,
      narrativeHint);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HiddenStatDataImplCopyWith<_$HiddenStatDataImpl> get copyWith =>
      __$$HiddenStatDataImplCopyWithImpl<_$HiddenStatDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HiddenStatDataImplToJson(
      this,
    );
  }
}

abstract class _HiddenStatData implements HiddenStatData {
  const factory _HiddenStatData(
          {required final String id,
          required final String name,
          required final String description,
          @JsonKey(name: 'counter_key') required final String counterKey,
          @JsonKey(name: 'level_thresholds')
          required final List<int> levelThresholds,
          @JsonKey(name: 'combat_effects_json')
          required final Map<String, dynamic> combatEffectsJson,
          @JsonKey(name: 'passive_effects_json')
          final Map<String, dynamic>? passiveEffectsJson,
          @JsonKey(name: 'post_reward_effects_json')
          final Map<String, dynamic>? postRewardEffectsJson,
          @JsonKey(name: 'icon_key') final String iconKey,
          @JsonKey(name: 'narrative_hint') final String? narrativeHint}) =
      _$HiddenStatDataImpl;

  factory _HiddenStatData.fromJson(Map<String, dynamic> json) =
      _$HiddenStatDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  @JsonKey(name: 'counter_key')
  String get counterKey;
  @override
  @JsonKey(name: 'level_thresholds')
  List<int> get levelThresholds;
  @override
  @JsonKey(name: 'combat_effects_json')
  Map<String, dynamic> get combatEffectsJson;
  @override
  @JsonKey(name: 'passive_effects_json')
  Map<String, dynamic>? get passiveEffectsJson;
  @override
  @JsonKey(name: 'post_reward_effects_json')
  Map<String, dynamic>? get postRewardEffectsJson;
  @override
  @JsonKey(name: 'icon_key')
  String get iconKey;
  @override
  @JsonKey(name: 'narrative_hint')
  String? get narrativeHint;
  @override
  @JsonKey(ignore: true)
  _$$HiddenStatDataImplCopyWith<_$HiddenStatDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
