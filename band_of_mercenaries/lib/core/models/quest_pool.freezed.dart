// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quest_pool.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QuestPool _$QuestPoolFromJson(Map<String, dynamic> json) {
  return _QuestPool.fromJson(json);
}

/// @nodoc
mixin _$QuestPool {
  @JsonKey(name: 'ID')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'Name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'Type')
  double get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'Difficulty')
  double get difficulty => throw _privateConstructorUsedError;
  @JsonKey(name: 'MinRegionDiff')
  double get minRegionDiff => throw _privateConstructorUsedError;
  @JsonKey(name: 'MaxRegionDiff')
  double get maxRegionDiff => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QuestPoolCopyWith<QuestPool> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestPoolCopyWith<$Res> {
  factory $QuestPoolCopyWith(QuestPool value, $Res Function(QuestPool) then) =
      _$QuestPoolCopyWithImpl<$Res, QuestPool>;
  @useResult
  $Res call(
      {@JsonKey(name: 'ID') String id,
      @JsonKey(name: 'Name') String name,
      @JsonKey(name: 'Type') double type,
      @JsonKey(name: 'Difficulty') double difficulty,
      @JsonKey(name: 'MinRegionDiff') double minRegionDiff,
      @JsonKey(name: 'MaxRegionDiff') double maxRegionDiff});
}

/// @nodoc
class _$QuestPoolCopyWithImpl<$Res, $Val extends QuestPool>
    implements $QuestPoolCopyWith<$Res> {
  _$QuestPoolCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? difficulty = null,
    Object? minRegionDiff = null,
    Object? maxRegionDiff = null,
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
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as double,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as double,
      minRegionDiff: null == minRegionDiff
          ? _value.minRegionDiff
          : minRegionDiff // ignore: cast_nullable_to_non_nullable
              as double,
      maxRegionDiff: null == maxRegionDiff
          ? _value.maxRegionDiff
          : maxRegionDiff // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuestPoolImplCopyWith<$Res>
    implements $QuestPoolCopyWith<$Res> {
  factory _$$QuestPoolImplCopyWith(
          _$QuestPoolImpl value, $Res Function(_$QuestPoolImpl) then) =
      __$$QuestPoolImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'ID') String id,
      @JsonKey(name: 'Name') String name,
      @JsonKey(name: 'Type') double type,
      @JsonKey(name: 'Difficulty') double difficulty,
      @JsonKey(name: 'MinRegionDiff') double minRegionDiff,
      @JsonKey(name: 'MaxRegionDiff') double maxRegionDiff});
}

/// @nodoc
class __$$QuestPoolImplCopyWithImpl<$Res>
    extends _$QuestPoolCopyWithImpl<$Res, _$QuestPoolImpl>
    implements _$$QuestPoolImplCopyWith<$Res> {
  __$$QuestPoolImplCopyWithImpl(
      _$QuestPoolImpl _value, $Res Function(_$QuestPoolImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? difficulty = null,
    Object? minRegionDiff = null,
    Object? maxRegionDiff = null,
  }) {
    return _then(_$QuestPoolImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as double,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as double,
      minRegionDiff: null == minRegionDiff
          ? _value.minRegionDiff
          : minRegionDiff // ignore: cast_nullable_to_non_nullable
              as double,
      maxRegionDiff: null == maxRegionDiff
          ? _value.maxRegionDiff
          : maxRegionDiff // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuestPoolImpl implements _QuestPool {
  const _$QuestPoolImpl(
      {@JsonKey(name: 'ID') required this.id,
      @JsonKey(name: 'Name') required this.name,
      @JsonKey(name: 'Type') required this.type,
      @JsonKey(name: 'Difficulty') required this.difficulty,
      @JsonKey(name: 'MinRegionDiff') required this.minRegionDiff,
      @JsonKey(name: 'MaxRegionDiff') required this.maxRegionDiff});

  factory _$QuestPoolImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestPoolImplFromJson(json);

  @override
  @JsonKey(name: 'ID')
  final String id;
  @override
  @JsonKey(name: 'Name')
  final String name;
  @override
  @JsonKey(name: 'Type')
  final double type;
  @override
  @JsonKey(name: 'Difficulty')
  final double difficulty;
  @override
  @JsonKey(name: 'MinRegionDiff')
  final double minRegionDiff;
  @override
  @JsonKey(name: 'MaxRegionDiff')
  final double maxRegionDiff;

  @override
  String toString() {
    return 'QuestPool(id: $id, name: $name, type: $type, difficulty: $difficulty, minRegionDiff: $minRegionDiff, maxRegionDiff: $maxRegionDiff)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestPoolImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.minRegionDiff, minRegionDiff) ||
                other.minRegionDiff == minRegionDiff) &&
            (identical(other.maxRegionDiff, maxRegionDiff) ||
                other.maxRegionDiff == maxRegionDiff));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, type, difficulty, minRegionDiff, maxRegionDiff);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestPoolImplCopyWith<_$QuestPoolImpl> get copyWith =>
      __$$QuestPoolImplCopyWithImpl<_$QuestPoolImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestPoolImplToJson(
      this,
    );
  }
}

abstract class _QuestPool implements QuestPool {
  const factory _QuestPool(
      {@JsonKey(name: 'ID') required final String id,
      @JsonKey(name: 'Name') required final String name,
      @JsonKey(name: 'Type') required final double type,
      @JsonKey(name: 'Difficulty') required final double difficulty,
      @JsonKey(name: 'MinRegionDiff') required final double minRegionDiff,
      @JsonKey(name: 'MaxRegionDiff')
      required final double maxRegionDiff}) = _$QuestPoolImpl;

  factory _QuestPool.fromJson(Map<String, dynamic> json) =
      _$QuestPoolImpl.fromJson;

  @override
  @JsonKey(name: 'ID')
  String get id;
  @override
  @JsonKey(name: 'Name')
  String get name;
  @override
  @JsonKey(name: 'Type')
  double get type;
  @override
  @JsonKey(name: 'Difficulty')
  double get difficulty;
  @override
  @JsonKey(name: 'MinRegionDiff')
  double get minRegionDiff;
  @override
  @JsonKey(name: 'MaxRegionDiff')
  double get maxRegionDiff;
  @override
  @JsonKey(ignore: true)
  _$$QuestPoolImplCopyWith<_$QuestPoolImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

QuestPoolList _$QuestPoolListFromJson(Map<String, dynamic> json) {
  return _QuestPoolList.fromJson(json);
}

/// @nodoc
mixin _$QuestPoolList {
  @JsonKey(name: 'QuestPools')
  List<QuestPool> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QuestPoolListCopyWith<QuestPoolList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestPoolListCopyWith<$Res> {
  factory $QuestPoolListCopyWith(
          QuestPoolList value, $Res Function(QuestPoolList) then) =
      _$QuestPoolListCopyWithImpl<$Res, QuestPoolList>;
  @useResult
  $Res call({@JsonKey(name: 'QuestPools') List<QuestPool> items});
}

/// @nodoc
class _$QuestPoolListCopyWithImpl<$Res, $Val extends QuestPoolList>
    implements $QuestPoolListCopyWith<$Res> {
  _$QuestPoolListCopyWithImpl(this._value, this._then);

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
              as List<QuestPool>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuestPoolListImplCopyWith<$Res>
    implements $QuestPoolListCopyWith<$Res> {
  factory _$$QuestPoolListImplCopyWith(
          _$QuestPoolListImpl value, $Res Function(_$QuestPoolListImpl) then) =
      __$$QuestPoolListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'QuestPools') List<QuestPool> items});
}

/// @nodoc
class __$$QuestPoolListImplCopyWithImpl<$Res>
    extends _$QuestPoolListCopyWithImpl<$Res, _$QuestPoolListImpl>
    implements _$$QuestPoolListImplCopyWith<$Res> {
  __$$QuestPoolListImplCopyWithImpl(
      _$QuestPoolListImpl _value, $Res Function(_$QuestPoolListImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_$QuestPoolListImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<QuestPool>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuestPoolListImpl implements _QuestPoolList {
  const _$QuestPoolListImpl(
      {@JsonKey(name: 'QuestPools') required final List<QuestPool> items})
      : _items = items;

  factory _$QuestPoolListImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestPoolListImplFromJson(json);

  final List<QuestPool> _items;
  @override
  @JsonKey(name: 'QuestPools')
  List<QuestPool> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'QuestPoolList(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestPoolListImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestPoolListImplCopyWith<_$QuestPoolListImpl> get copyWith =>
      __$$QuestPoolListImplCopyWithImpl<_$QuestPoolListImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestPoolListImplToJson(
      this,
    );
  }
}

abstract class _QuestPoolList implements QuestPoolList {
  const factory _QuestPoolList(
          {@JsonKey(name: 'QuestPools') required final List<QuestPool> items}) =
      _$QuestPoolListImpl;

  factory _QuestPoolList.fromJson(Map<String, dynamic> json) =
      _$QuestPoolListImpl.fromJson;

  @override
  @JsonKey(name: 'QuestPools')
  List<QuestPool> get items;
  @override
  @JsonKey(ignore: true)
  _$$QuestPoolListImplCopyWith<_$QuestPoolListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
