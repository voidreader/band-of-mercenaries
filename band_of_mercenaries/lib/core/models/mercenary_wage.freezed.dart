// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mercenary_wage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MercenaryWage _$MercenaryWageFromJson(Map<String, dynamic> json) {
  return _MercenaryWage.fromJson(json);
}

/// @nodoc
mixin _$MercenaryWage {
  int get tier => throw _privateConstructorUsedError;
  int get wage => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MercenaryWageCopyWith<MercenaryWage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MercenaryWageCopyWith<$Res> {
  factory $MercenaryWageCopyWith(
          MercenaryWage value, $Res Function(MercenaryWage) then) =
      _$MercenaryWageCopyWithImpl<$Res, MercenaryWage>;
  @useResult
  $Res call({int tier, int wage});
}

/// @nodoc
class _$MercenaryWageCopyWithImpl<$Res, $Val extends MercenaryWage>
    implements $MercenaryWageCopyWith<$Res> {
  _$MercenaryWageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tier = null,
    Object? wage = null,
  }) {
    return _then(_value.copyWith(
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as int,
      wage: null == wage
          ? _value.wage
          : wage // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MercenaryWageImplCopyWith<$Res>
    implements $MercenaryWageCopyWith<$Res> {
  factory _$$MercenaryWageImplCopyWith(
          _$MercenaryWageImpl value, $Res Function(_$MercenaryWageImpl) then) =
      __$$MercenaryWageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int tier, int wage});
}

/// @nodoc
class __$$MercenaryWageImplCopyWithImpl<$Res>
    extends _$MercenaryWageCopyWithImpl<$Res, _$MercenaryWageImpl>
    implements _$$MercenaryWageImplCopyWith<$Res> {
  __$$MercenaryWageImplCopyWithImpl(
      _$MercenaryWageImpl _value, $Res Function(_$MercenaryWageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tier = null,
    Object? wage = null,
  }) {
    return _then(_$MercenaryWageImpl(
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as int,
      wage: null == wage
          ? _value.wage
          : wage // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MercenaryWageImpl implements _MercenaryWage {
  const _$MercenaryWageImpl({required this.tier, required this.wage});

  factory _$MercenaryWageImpl.fromJson(Map<String, dynamic> json) =>
      _$$MercenaryWageImplFromJson(json);

  @override
  final int tier;
  @override
  final int wage;

  @override
  String toString() {
    return 'MercenaryWage(tier: $tier, wage: $wage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MercenaryWageImpl &&
            (identical(other.tier, tier) || other.tier == tier) &&
            (identical(other.wage, wage) || other.wage == wage));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, tier, wage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MercenaryWageImplCopyWith<_$MercenaryWageImpl> get copyWith =>
      __$$MercenaryWageImplCopyWithImpl<_$MercenaryWageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MercenaryWageImplToJson(
      this,
    );
  }
}

abstract class _MercenaryWage implements MercenaryWage {
  const factory _MercenaryWage(
      {required final int tier, required final int wage}) = _$MercenaryWageImpl;

  factory _MercenaryWage.fromJson(Map<String, dynamic> json) =
      _$MercenaryWageImpl.fromJson;

  @override
  int get tier;
  @override
  int get wage;
  @override
  @JsonKey(ignore: true)
  _$$MercenaryWageImplCopyWith<_$MercenaryWageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MercenaryWageList _$MercenaryWageListFromJson(Map<String, dynamic> json) {
  return _MercenaryWageList.fromJson(json);
}

/// @nodoc
mixin _$MercenaryWageList {
  @JsonKey(name: 'MercenaryWages')
  List<MercenaryWage> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MercenaryWageListCopyWith<MercenaryWageList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MercenaryWageListCopyWith<$Res> {
  factory $MercenaryWageListCopyWith(
          MercenaryWageList value, $Res Function(MercenaryWageList) then) =
      _$MercenaryWageListCopyWithImpl<$Res, MercenaryWageList>;
  @useResult
  $Res call({@JsonKey(name: 'MercenaryWages') List<MercenaryWage> items});
}

/// @nodoc
class _$MercenaryWageListCopyWithImpl<$Res, $Val extends MercenaryWageList>
    implements $MercenaryWageListCopyWith<$Res> {
  _$MercenaryWageListCopyWithImpl(this._value, this._then);

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
              as List<MercenaryWage>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MercenaryWageListImplCopyWith<$Res>
    implements $MercenaryWageListCopyWith<$Res> {
  factory _$$MercenaryWageListImplCopyWith(_$MercenaryWageListImpl value,
          $Res Function(_$MercenaryWageListImpl) then) =
      __$$MercenaryWageListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'MercenaryWages') List<MercenaryWage> items});
}

/// @nodoc
class __$$MercenaryWageListImplCopyWithImpl<$Res>
    extends _$MercenaryWageListCopyWithImpl<$Res, _$MercenaryWageListImpl>
    implements _$$MercenaryWageListImplCopyWith<$Res> {
  __$$MercenaryWageListImplCopyWithImpl(_$MercenaryWageListImpl _value,
      $Res Function(_$MercenaryWageListImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_$MercenaryWageListImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MercenaryWage>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MercenaryWageListImpl implements _MercenaryWageList {
  const _$MercenaryWageListImpl(
      {@JsonKey(name: 'MercenaryWages')
      required final List<MercenaryWage> items})
      : _items = items;

  factory _$MercenaryWageListImpl.fromJson(Map<String, dynamic> json) =>
      _$$MercenaryWageListImplFromJson(json);

  final List<MercenaryWage> _items;
  @override
  @JsonKey(name: 'MercenaryWages')
  List<MercenaryWage> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'MercenaryWageList(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MercenaryWageListImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MercenaryWageListImplCopyWith<_$MercenaryWageListImpl> get copyWith =>
      __$$MercenaryWageListImplCopyWithImpl<_$MercenaryWageListImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MercenaryWageListImplToJson(
      this,
    );
  }
}

abstract class _MercenaryWageList implements MercenaryWageList {
  const factory _MercenaryWageList(
      {@JsonKey(name: 'MercenaryWages')
      required final List<MercenaryWage> items}) = _$MercenaryWageListImpl;

  factory _MercenaryWageList.fromJson(Map<String, dynamic> json) =
      _$MercenaryWageListImpl.fromJson;

  @override
  @JsonKey(name: 'MercenaryWages')
  List<MercenaryWage> get items;
  @override
  @JsonKey(ignore: true)
  _$$MercenaryWageListImplCopyWith<_$MercenaryWageListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
