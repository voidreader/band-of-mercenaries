// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rank.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Rank _$RankFromJson(Map<String, dynamic> json) {
  return _Rank.fromJson(json);
}

/// @nodoc
mixin _$Rank {
  String get grade => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'required_reputation')
  int get requiredReputation => throw _privateConstructorUsedError;
  @JsonKey(name: 'unlock_tier')
  int get unlockTier => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RankCopyWith<Rank> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RankCopyWith<$Res> {
  factory $RankCopyWith(Rank value, $Res Function(Rank) then) =
      _$RankCopyWithImpl<$Res, Rank>;
  @useResult
  $Res call(
      {String grade,
      String name,
      @JsonKey(name: 'required_reputation') int requiredReputation,
      @JsonKey(name: 'unlock_tier') int unlockTier});
}

/// @nodoc
class _$RankCopyWithImpl<$Res, $Val extends Rank>
    implements $RankCopyWith<$Res> {
  _$RankCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? grade = null,
    Object? name = null,
    Object? requiredReputation = null,
    Object? unlockTier = null,
  }) {
    return _then(_value.copyWith(
      grade: null == grade
          ? _value.grade
          : grade // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      requiredReputation: null == requiredReputation
          ? _value.requiredReputation
          : requiredReputation // ignore: cast_nullable_to_non_nullable
              as int,
      unlockTier: null == unlockTier
          ? _value.unlockTier
          : unlockTier // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RankImplCopyWith<$Res> implements $RankCopyWith<$Res> {
  factory _$$RankImplCopyWith(
          _$RankImpl value, $Res Function(_$RankImpl) then) =
      __$$RankImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String grade,
      String name,
      @JsonKey(name: 'required_reputation') int requiredReputation,
      @JsonKey(name: 'unlock_tier') int unlockTier});
}

/// @nodoc
class __$$RankImplCopyWithImpl<$Res>
    extends _$RankCopyWithImpl<$Res, _$RankImpl>
    implements _$$RankImplCopyWith<$Res> {
  __$$RankImplCopyWithImpl(_$RankImpl _value, $Res Function(_$RankImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? grade = null,
    Object? name = null,
    Object? requiredReputation = null,
    Object? unlockTier = null,
  }) {
    return _then(_$RankImpl(
      grade: null == grade
          ? _value.grade
          : grade // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      requiredReputation: null == requiredReputation
          ? _value.requiredReputation
          : requiredReputation // ignore: cast_nullable_to_non_nullable
              as int,
      unlockTier: null == unlockTier
          ? _value.unlockTier
          : unlockTier // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RankImpl implements _Rank {
  const _$RankImpl(
      {required this.grade,
      required this.name,
      @JsonKey(name: 'required_reputation') required this.requiredReputation,
      @JsonKey(name: 'unlock_tier') required this.unlockTier});

  factory _$RankImpl.fromJson(Map<String, dynamic> json) =>
      _$$RankImplFromJson(json);

  @override
  final String grade;
  @override
  final String name;
  @override
  @JsonKey(name: 'required_reputation')
  final int requiredReputation;
  @override
  @JsonKey(name: 'unlock_tier')
  final int unlockTier;

  @override
  String toString() {
    return 'Rank(grade: $grade, name: $name, requiredReputation: $requiredReputation, unlockTier: $unlockTier)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RankImpl &&
            (identical(other.grade, grade) || other.grade == grade) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.requiredReputation, requiredReputation) ||
                other.requiredReputation == requiredReputation) &&
            (identical(other.unlockTier, unlockTier) ||
                other.unlockTier == unlockTier));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, grade, name, requiredReputation, unlockTier);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RankImplCopyWith<_$RankImpl> get copyWith =>
      __$$RankImplCopyWithImpl<_$RankImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RankImplToJson(
      this,
    );
  }
}

abstract class _Rank implements Rank {
  const factory _Rank(
          {required final String grade,
          required final String name,
          @JsonKey(name: 'required_reputation')
          required final int requiredReputation,
          @JsonKey(name: 'unlock_tier') required final int unlockTier}) =
      _$RankImpl;

  factory _Rank.fromJson(Map<String, dynamic> json) = _$RankImpl.fromJson;

  @override
  String get grade;
  @override
  String get name;
  @override
  @JsonKey(name: 'required_reputation')
  int get requiredReputation;
  @override
  @JsonKey(name: 'unlock_tier')
  int get unlockTier;
  @override
  @JsonKey(ignore: true)
  _$$RankImplCopyWith<_$RankImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RankList _$RankListFromJson(Map<String, dynamic> json) {
  return _RankList.fromJson(json);
}

/// @nodoc
mixin _$RankList {
  @JsonKey(name: 'Ranks')
  List<Rank> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RankListCopyWith<RankList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RankListCopyWith<$Res> {
  factory $RankListCopyWith(RankList value, $Res Function(RankList) then) =
      _$RankListCopyWithImpl<$Res, RankList>;
  @useResult
  $Res call({@JsonKey(name: 'Ranks') List<Rank> items});
}

/// @nodoc
class _$RankListCopyWithImpl<$Res, $Val extends RankList>
    implements $RankListCopyWith<$Res> {
  _$RankListCopyWithImpl(this._value, this._then);

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
              as List<Rank>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RankListImplCopyWith<$Res>
    implements $RankListCopyWith<$Res> {
  factory _$$RankListImplCopyWith(
          _$RankListImpl value, $Res Function(_$RankListImpl) then) =
      __$$RankListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'Ranks') List<Rank> items});
}

/// @nodoc
class __$$RankListImplCopyWithImpl<$Res>
    extends _$RankListCopyWithImpl<$Res, _$RankListImpl>
    implements _$$RankListImplCopyWith<$Res> {
  __$$RankListImplCopyWithImpl(
      _$RankListImpl _value, $Res Function(_$RankListImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_$RankListImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<Rank>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RankListImpl implements _RankList {
  const _$RankListImpl(
      {@JsonKey(name: 'Ranks') required final List<Rank> items})
      : _items = items;

  factory _$RankListImpl.fromJson(Map<String, dynamic> json) =>
      _$$RankListImplFromJson(json);

  final List<Rank> _items;
  @override
  @JsonKey(name: 'Ranks')
  List<Rank> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'RankList(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RankListImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RankListImplCopyWith<_$RankListImpl> get copyWith =>
      __$$RankListImplCopyWithImpl<_$RankListImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RankListImplToJson(
      this,
    );
  }
}

abstract class _RankList implements RankList {
  const factory _RankList(
          {@JsonKey(name: 'Ranks') required final List<Rank> items}) =
      _$RankListImpl;

  factory _RankList.fromJson(Map<String, dynamic> json) =
      _$RankListImpl.fromJson;

  @override
  @JsonKey(name: 'Ranks')
  List<Rank> get items;
  @override
  @JsonKey(ignore: true)
  _$$RankListImplCopyWith<_$RankListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
