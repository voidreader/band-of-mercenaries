// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'person_name.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PersonName _$PersonNameFromJson(Map<String, dynamic> json) {
  return _PersonName.fromJson(json);
}

/// @nodoc
mixin _$PersonName {
  @JsonKey(name: 'ID')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'Korean')
  String get korean => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PersonNameCopyWith<PersonName> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersonNameCopyWith<$Res> {
  factory $PersonNameCopyWith(
          PersonName value, $Res Function(PersonName) then) =
      _$PersonNameCopyWithImpl<$Res, PersonName>;
  @useResult
  $Res call(
      {@JsonKey(name: 'ID') int id, @JsonKey(name: 'Korean') String korean});
}

/// @nodoc
class _$PersonNameCopyWithImpl<$Res, $Val extends PersonName>
    implements $PersonNameCopyWith<$Res> {
  _$PersonNameCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? korean = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      korean: null == korean
          ? _value.korean
          : korean // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PersonNameImplCopyWith<$Res>
    implements $PersonNameCopyWith<$Res> {
  factory _$$PersonNameImplCopyWith(
          _$PersonNameImpl value, $Res Function(_$PersonNameImpl) then) =
      __$$PersonNameImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'ID') int id, @JsonKey(name: 'Korean') String korean});
}

/// @nodoc
class __$$PersonNameImplCopyWithImpl<$Res>
    extends _$PersonNameCopyWithImpl<$Res, _$PersonNameImpl>
    implements _$$PersonNameImplCopyWith<$Res> {
  __$$PersonNameImplCopyWithImpl(
      _$PersonNameImpl _value, $Res Function(_$PersonNameImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? korean = null,
  }) {
    return _then(_$PersonNameImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      korean: null == korean
          ? _value.korean
          : korean // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PersonNameImpl implements _PersonName {
  const _$PersonNameImpl(
      {@JsonKey(name: 'ID') required this.id,
      @JsonKey(name: 'Korean') required this.korean});

  factory _$PersonNameImpl.fromJson(Map<String, dynamic> json) =>
      _$$PersonNameImplFromJson(json);

  @override
  @JsonKey(name: 'ID')
  final int id;
  @override
  @JsonKey(name: 'Korean')
  final String korean;

  @override
  String toString() {
    return 'PersonName(id: $id, korean: $korean)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PersonNameImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.korean, korean) || other.korean == korean));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, korean);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PersonNameImplCopyWith<_$PersonNameImpl> get copyWith =>
      __$$PersonNameImplCopyWithImpl<_$PersonNameImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PersonNameImplToJson(
      this,
    );
  }
}

abstract class _PersonName implements PersonName {
  const factory _PersonName(
          {@JsonKey(name: 'ID') required final int id,
          @JsonKey(name: 'Korean') required final String korean}) =
      _$PersonNameImpl;

  factory _PersonName.fromJson(Map<String, dynamic> json) =
      _$PersonNameImpl.fromJson;

  @override
  @JsonKey(name: 'ID')
  int get id;
  @override
  @JsonKey(name: 'Korean')
  String get korean;
  @override
  @JsonKey(ignore: true)
  _$$PersonNameImplCopyWith<_$PersonNameImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PersonNameList _$PersonNameListFromJson(Map<String, dynamic> json) {
  return _PersonNameList.fromJson(json);
}

/// @nodoc
mixin _$PersonNameList {
  @JsonKey(name: 'PersonNames')
  List<PersonName> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PersonNameListCopyWith<PersonNameList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersonNameListCopyWith<$Res> {
  factory $PersonNameListCopyWith(
          PersonNameList value, $Res Function(PersonNameList) then) =
      _$PersonNameListCopyWithImpl<$Res, PersonNameList>;
  @useResult
  $Res call({@JsonKey(name: 'PersonNames') List<PersonName> items});
}

/// @nodoc
class _$PersonNameListCopyWithImpl<$Res, $Val extends PersonNameList>
    implements $PersonNameListCopyWith<$Res> {
  _$PersonNameListCopyWithImpl(this._value, this._then);

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
              as List<PersonName>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PersonNameListImplCopyWith<$Res>
    implements $PersonNameListCopyWith<$Res> {
  factory _$$PersonNameListImplCopyWith(_$PersonNameListImpl value,
          $Res Function(_$PersonNameListImpl) then) =
      __$$PersonNameListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'PersonNames') List<PersonName> items});
}

/// @nodoc
class __$$PersonNameListImplCopyWithImpl<$Res>
    extends _$PersonNameListCopyWithImpl<$Res, _$PersonNameListImpl>
    implements _$$PersonNameListImplCopyWith<$Res> {
  __$$PersonNameListImplCopyWithImpl(
      _$PersonNameListImpl _value, $Res Function(_$PersonNameListImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_$PersonNameListImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<PersonName>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PersonNameListImpl implements _PersonNameList {
  const _$PersonNameListImpl(
      {@JsonKey(name: 'PersonNames') required final List<PersonName> items})
      : _items = items;

  factory _$PersonNameListImpl.fromJson(Map<String, dynamic> json) =>
      _$$PersonNameListImplFromJson(json);

  final List<PersonName> _items;
  @override
  @JsonKey(name: 'PersonNames')
  List<PersonName> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'PersonNameList(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PersonNameListImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PersonNameListImplCopyWith<_$PersonNameListImpl> get copyWith =>
      __$$PersonNameListImplCopyWithImpl<_$PersonNameListImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PersonNameListImplToJson(
      this,
    );
  }
}

abstract class _PersonNameList implements PersonNameList {
  const factory _PersonNameList(
      {@JsonKey(name: 'PersonNames')
      required final List<PersonName> items}) = _$PersonNameListImpl;

  factory _PersonNameList.fromJson(Map<String, dynamic> json) =
      _$PersonNameListImpl.fromJson;

  @override
  @JsonKey(name: 'PersonNames')
  List<PersonName> get items;
  @override
  @JsonKey(ignore: true)
  _$$PersonNameListImplCopyWith<_$PersonNameListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
