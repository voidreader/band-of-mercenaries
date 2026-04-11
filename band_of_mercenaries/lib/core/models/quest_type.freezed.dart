// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quest_type.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QuestType _$QuestTypeFromJson(Map<String, dynamic> json) {
  return _QuestType.fromJson(json);
}

/// @nodoc
mixin _$QuestType {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_reward')
  int get baseReward => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_duration')
  int get baseDuration => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_factor')
  double get riskFactor => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QuestTypeCopyWith<QuestType> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestTypeCopyWith<$Res> {
  factory $QuestTypeCopyWith(QuestType value, $Res Function(QuestType) then) =
      _$QuestTypeCopyWithImpl<$Res, QuestType>;
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(name: 'base_reward') int baseReward,
      @JsonKey(name: 'base_duration') int baseDuration,
      @JsonKey(name: 'risk_factor') double riskFactor});
}

/// @nodoc
class _$QuestTypeCopyWithImpl<$Res, $Val extends QuestType>
    implements $QuestTypeCopyWith<$Res> {
  _$QuestTypeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? baseReward = null,
    Object? baseDuration = null,
    Object? riskFactor = null,
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
      baseReward: null == baseReward
          ? _value.baseReward
          : baseReward // ignore: cast_nullable_to_non_nullable
              as int,
      baseDuration: null == baseDuration
          ? _value.baseDuration
          : baseDuration // ignore: cast_nullable_to_non_nullable
              as int,
      riskFactor: null == riskFactor
          ? _value.riskFactor
          : riskFactor // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuestTypeImplCopyWith<$Res>
    implements $QuestTypeCopyWith<$Res> {
  factory _$$QuestTypeImplCopyWith(
          _$QuestTypeImpl value, $Res Function(_$QuestTypeImpl) then) =
      __$$QuestTypeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(name: 'base_reward') int baseReward,
      @JsonKey(name: 'base_duration') int baseDuration,
      @JsonKey(name: 'risk_factor') double riskFactor});
}

/// @nodoc
class __$$QuestTypeImplCopyWithImpl<$Res>
    extends _$QuestTypeCopyWithImpl<$Res, _$QuestTypeImpl>
    implements _$$QuestTypeImplCopyWith<$Res> {
  __$$QuestTypeImplCopyWithImpl(
      _$QuestTypeImpl _value, $Res Function(_$QuestTypeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? baseReward = null,
    Object? baseDuration = null,
    Object? riskFactor = null,
  }) {
    return _then(_$QuestTypeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      baseReward: null == baseReward
          ? _value.baseReward
          : baseReward // ignore: cast_nullable_to_non_nullable
              as int,
      baseDuration: null == baseDuration
          ? _value.baseDuration
          : baseDuration // ignore: cast_nullable_to_non_nullable
              as int,
      riskFactor: null == riskFactor
          ? _value.riskFactor
          : riskFactor // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuestTypeImpl implements _QuestType {
  const _$QuestTypeImpl(
      {required this.id,
      required this.name,
      @JsonKey(name: 'base_reward') required this.baseReward,
      @JsonKey(name: 'base_duration') required this.baseDuration,
      @JsonKey(name: 'risk_factor') required this.riskFactor});

  factory _$QuestTypeImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestTypeImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey(name: 'base_reward')
  final int baseReward;
  @override
  @JsonKey(name: 'base_duration')
  final int baseDuration;
  @override
  @JsonKey(name: 'risk_factor')
  final double riskFactor;

  @override
  String toString() {
    return 'QuestType(id: $id, name: $name, baseReward: $baseReward, baseDuration: $baseDuration, riskFactor: $riskFactor)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestTypeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.baseReward, baseReward) ||
                other.baseReward == baseReward) &&
            (identical(other.baseDuration, baseDuration) ||
                other.baseDuration == baseDuration) &&
            (identical(other.riskFactor, riskFactor) ||
                other.riskFactor == riskFactor));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, baseReward, baseDuration, riskFactor);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestTypeImplCopyWith<_$QuestTypeImpl> get copyWith =>
      __$$QuestTypeImplCopyWithImpl<_$QuestTypeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestTypeImplToJson(
      this,
    );
  }
}

abstract class _QuestType implements QuestType {
  const factory _QuestType(
          {required final String id,
          required final String name,
          @JsonKey(name: 'base_reward') required final int baseReward,
          @JsonKey(name: 'base_duration') required final int baseDuration,
          @JsonKey(name: 'risk_factor') required final double riskFactor}) =
      _$QuestTypeImpl;

  factory _QuestType.fromJson(Map<String, dynamic> json) =
      _$QuestTypeImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'base_reward')
  int get baseReward;
  @override
  @JsonKey(name: 'base_duration')
  int get baseDuration;
  @override
  @JsonKey(name: 'risk_factor')
  double get riskFactor;
  @override
  @JsonKey(ignore: true)
  _$$QuestTypeImplCopyWith<_$QuestTypeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

QuestTypeList _$QuestTypeListFromJson(Map<String, dynamic> json) {
  return _QuestTypeList.fromJson(json);
}

/// @nodoc
mixin _$QuestTypeList {
  @JsonKey(name: 'QuestTypes')
  List<QuestType> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QuestTypeListCopyWith<QuestTypeList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestTypeListCopyWith<$Res> {
  factory $QuestTypeListCopyWith(
          QuestTypeList value, $Res Function(QuestTypeList) then) =
      _$QuestTypeListCopyWithImpl<$Res, QuestTypeList>;
  @useResult
  $Res call({@JsonKey(name: 'QuestTypes') List<QuestType> items});
}

/// @nodoc
class _$QuestTypeListCopyWithImpl<$Res, $Val extends QuestTypeList>
    implements $QuestTypeListCopyWith<$Res> {
  _$QuestTypeListCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<QuestType>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuestTypeListImplCopyWith<$Res>
    implements $QuestTypeListCopyWith<$Res> {
  factory _$$QuestTypeListImplCopyWith(
          _$QuestTypeListImpl value, $Res Function(_$QuestTypeListImpl) then) =
      __$$QuestTypeListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'QuestTypes') List<QuestType> items});
}

/// @nodoc
class __$$QuestTypeListImplCopyWithImpl<$Res>
    extends _$QuestTypeListCopyWithImpl<$Res, _$QuestTypeListImpl>
    implements _$$QuestTypeListImplCopyWith<$Res> {
  __$$QuestTypeListImplCopyWithImpl(
      _$QuestTypeListImpl _value, $Res Function(_$QuestTypeListImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_$QuestTypeListImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<QuestType>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuestTypeListImpl implements _QuestTypeList {
  const _$QuestTypeListImpl(
      {@JsonKey(name: 'QuestTypes') required final List<QuestType> items})
      : _items = items;

  factory _$QuestTypeListImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestTypeListImplFromJson(json);

  final List<QuestType> _items;
  @override
  @JsonKey(name: 'QuestTypes')
  List<QuestType> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'QuestTypeList(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestTypeListImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestTypeListImplCopyWith<_$QuestTypeListImpl> get copyWith =>
      __$$QuestTypeListImplCopyWithImpl<_$QuestTypeListImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestTypeListImplToJson(
      this,
    );
  }
}

abstract class _QuestTypeList implements QuestTypeList {
  const factory _QuestTypeList(
          {@JsonKey(name: 'QuestTypes') required final List<QuestType> items}) =
      _$QuestTypeListImpl;

  factory _QuestTypeList.fromJson(Map<String, dynamic> json) =
      _$QuestTypeListImpl.fromJson;

  @override
  @JsonKey(name: 'QuestTypes')
  List<QuestType> get items;
  @override
  @JsonKey(ignore: true)
  _$$QuestTypeListImplCopyWith<_$QuestTypeListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
